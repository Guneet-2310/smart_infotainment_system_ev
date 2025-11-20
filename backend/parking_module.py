"""Parking and Cabin Environment Module

Provides unified access to:
- Ultrasonic distance (rear proximity)
- PIR motion detection (rear movement)
- Reverse gear button state
- DHT11 temperature & humidity (cabin / ambient)

Design Goals:
- Safe operation on Raspberry Pi with real sensors
- Graceful mock/fallback on non-RPi platforms (Windows dev)
- Lightweight synchronous read each telemetry cycle (1 Hz)
- Clear warning level derivation for proximity

Warning Levels (distance_cm):
  <=10 cm  -> high
  <=20 cm  -> medium
  <=30 cm  -> low
  >30 or None -> clear

Reverse logic:
  reverse_engaged == True when button GPIO high (Pi) or mock toggle simulation (desktop)

Mock Behavior (non-Pi):
  - Temperature: 22–28 C slowly varying
  - Humidity: 40–60 %
  - Distance cycles through ranges to showcase warnings
  - Motion detected randomly ~15% chance when reverse engaged

"""
from __future__ import annotations
import random
import time
from typing import Dict, Any, Optional, Tuple

try:
    import platform
    IS_RPI = platform.machine().startswith('arm') or platform.machine().startswith('aarch')
except Exception:
    IS_RPI = False

class ParkingAndCabinModule:
    def __init__(self):
        self._last_mock_tick = time.time()
        self._mock_phase = 0
        self._using_real = False
        # DHT11 cached values to avoid over-sampling (Adafruit lib requires ~2s between reads)
        self._dht_last_read_ts: float = 0.0
        self._dht_cached_temp: Optional[float] = None
        self._dht_cached_hum: Optional[float] = None

        if IS_RPI:
            try:
                import RPi.GPIO as GPIO  # type: ignore
                import adafruit_dht      # type: ignore
                import board             # type: ignore

                self.GPIO = GPIO
                self.board = board
                self.GPIO.setmode(self.GPIO.BCM)
                self.GPIO.setwarnings(False)

                # Pin map (BCM)
                self.TRIG = 5
                self.ECHO = 6
                self.BUTTON = 22  # reverse gear
                self.PIR = 27
                # Physical DHT11 wiring pin (using D17 as per tested working script)
                self.DHT_PIN = board.D17

                self.GPIO.setup(self.TRIG, self.GPIO.OUT)
                self.GPIO.setup(self.ECHO, self.GPIO.IN)
                self.GPIO.setup(self.BUTTON, self.GPIO.IN, pull_up_down=self.GPIO.PUD_DOWN)
                self.GPIO.setup(self.PIR, self.GPIO.IN)

                self.dht = adafruit_dht.DHT11(self.DHT_PIN)
                self._using_real = True
                print("✓ Parking module initialized with real sensors")
            except Exception as e:
                # Fallback to mock if any import/init fails
                print(f"⚠ Failed to initialize real sensors: {e}")
                print("→ Using mock sensors for parking module")
                self._using_real = False
                self.GPIO = None
        else:
            print("→ Non-Pi platform detected, using mock sensors")
            self.GPIO = None

    # ---------------- Real sensor helpers -----------------
    def _read_ultrasonic(self) -> Optional[float]:
        if not self._using_real:
            return None
        try:
            GPIO = self.GPIO
            GPIO.output(self.TRIG, False)
            time.sleep(0.0002)
            GPIO.output(self.TRIG, True)
            time.sleep(0.00001)
            GPIO.output(self.TRIG, False)
            start = time.time()
            timeout = start + 0.02  # 20 ms safety
            while GPIO.input(self.ECHO) == 0 and time.time() < timeout:
                start = time.time()
            end = time.time()
            timeout2 = end + 0.04  # 40 ms max echo
            while GPIO.input(self.ECHO) == 1 and time.time() < timeout2:
                end = time.time()
            duration = end - start
            distance = duration * 17150
            if distance <= 0 or distance > 500:  # filter improbable
                return None
            return round(distance, 1)
        except Exception as e:
            # Sensor fault - return None instead of crashing
            print(f"⚠ Ultrasonic sensor error: {e}")
            return None

    def _read_dht(self) -> Tuple[Optional[float], Optional[float]]:
        """Return (temperature, humidity) with caching & retry.

        The Adafruit DHT library can intermittently fail; also it requires
        at least ~2 seconds between successful reads. We therefore:
          - Serve cached values if last read < 2.5s ago.
          - Attempt up to 3 fresh reads when stale.
          - On repeated failure keep prior cached values (do not overwrite
            with None unless we never had a good sample).
        """
        if not self._using_real:
            return (self._dht_cached_temp, self._dht_cached_hum)

        now = time.time()
        # If cache is fresh, return it directly
        if now - self._dht_last_read_ts < 2.5 and self._dht_cached_temp is not None and self._dht_cached_hum is not None:
            return (self._dht_cached_temp, self._dht_cached_hum)

        attempt = 0
        fresh_temp: Optional[float] = None
        fresh_hum: Optional[float] = None
        while attempt < 3:
            try:
                temp = self.dht.temperature
                hum = self.dht.humidity
                if temp is not None and hum is not None:
                    fresh_temp = float(temp)
                    fresh_hum = float(hum)
                    break
            except Exception as e:
                print(f"⚠ DHT11 sensor read attempt {attempt+1} failed: {e}")
            attempt += 1
            time.sleep(0.4)  # short backoff between retries

        if fresh_temp is not None and fresh_hum is not None:
            self._dht_cached_temp = round(fresh_temp, 1)
            self._dht_cached_hum = round(fresh_hum, 1)
            self._dht_last_read_ts = now
        else:
            # Keep old cached values; if none existed return (None, None)
            print("⚠ Using cached/None DHT values after retries")
        return (self._dht_cached_temp, self._dht_cached_hum)

    def _read_gpio_bool(self, pin: int) -> bool:
        if not self._using_real:
            return False
        try:
            return self.GPIO.input(pin) == 1
        except Exception as e:
            # GPIO read fault - return False instead of crashing
            print(f"⚠ GPIO pin {pin} read error: {e}")
            return False

    # ---------------- Mock generators -----------------
    def _mock_temperature(self) -> float:
        base = 24.0 + (time.time() % 300) / 300 * 4.0  # slow drift 24-28
        noise = random.uniform(-0.5, 0.5)
        return round(base + noise, 1)

    def _mock_humidity(self) -> float:
        base = 50.0 + (time.time() % 180) / 180 * 8.0  # 50-58 gradual
        noise = random.uniform(-2, 2)
        return round(base + noise, 1)

    def _mock_distance(self) -> Optional[float]:
        # Cycle phases: clear -> low -> medium -> high
        # FAST TESTING MODE: 5 seconds per phase instead of 8
        if time.time() - self._last_mock_tick > 5:
            self._mock_phase = (self._mock_phase + 1) % 4
            self._last_mock_tick = time.time()
        if self._mock_phase == 0:
            return random.uniform(35, 55)  # clear
        if self._mock_phase == 1:
            return random.uniform(22, 30)  # low
        if self._mock_phase == 2:
            return random.uniform(12, 19)  # medium
        return random.uniform(5, 9)       # high

    def _mock_reverse(self) -> bool:
        # Simulate reverse engaged ~40% of the time in medium/high phases
        return self._mock_phase in (2, 3)

    def _mock_motion(self, reverse_engaged: bool) -> bool:
        if not reverse_engaged:
            return False
        return random.random() < 0.15

    # ---------------- Derivation logic -----------------
    @staticmethod
    def _derive_warning(distance: Optional[float]) -> Optional[str]:
        if distance is None:
            return None
        if distance <= 10:
            return 'high'
        if distance <= 20:
            return 'medium'
        if distance <= 30:
            return 'low'
        return 'clear'

    # ---------------- Public read -----------------
    def read(self) -> Dict[str, Any]:
        try:
            if self._using_real:
                reverse_engaged = self._read_gpio_bool(self.BUTTON)
                motion = self._read_gpio_bool(self.PIR)
                distance = self._read_ultrasonic() if reverse_engaged else None
                temp, hum = self._read_dht()
            else:
                reverse_engaged = self._mock_reverse()
                motion = self._mock_motion(reverse_engaged)
                distance = self._mock_distance() if reverse_engaged else None
                temp = self._mock_temperature()
                hum = self._mock_humidity()

            warning = self._derive_warning(distance if reverse_engaged else None)

            return {
                'reverse_engaged': reverse_engaged,
                'motion_detected': motion,
                'distance_cm': distance if reverse_engaged else None,
                'proximity_warning': warning if reverse_engaged else None,
                'temperature_c': temp,
                'humidity_pct': hum,
            }
        except Exception as e:
            # Critical failure - return safe defaults
            print(f"⚠ Parking module critical error: {e}")
            return {
                'reverse_engaged': False,
                'motion_detected': False,
                'distance_cm': None,
                'proximity_warning': None,
                'temperature_c': None,
                'humidity_pct': None,
            }

    def dispose(self):
        if self._using_real and self.GPIO:
            try:
                self.GPIO.cleanup()
            except Exception as e:
                print(f"⚠ GPIO cleanup error: {e}")

