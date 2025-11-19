#!/usr/bin/env python3
"""
EV Smart Screen - Backend Server
Phase 1 Prototype

This backend provides real-time telemetry data and command handling for the
Flutter EV infotainment frontend. It supports both Windows (mock data) and
Raspberry Pi (real hardware) environments.

Author: Guneet Chawla
Email: guneet.chawla.22cse@bmu.edu.in
Institution: BML Munjal University
Copyright © 2025 BML Munjal University. All rights reserved.
"""

import asyncio
import json
import logging
import platform
import random
import time
from datetime import datetime
from typing import Dict, Set, Any, Optional
import websockets

# Platform detection
IS_RPI = platform.machine().startswith('arm') or platform.machine().startswith('aarch')
IS_WINDOWS = platform.system() == 'Windows'

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================================================
# HARDWARE ABSTRACTION LAYER
# ============================================================================

if IS_RPI:
    logger.info("Running on Raspberry Pi - Loading real hardware drivers")
    try:
        import board
        import adafruit_dht
        # import can  # CAN bus - commented out for now
        # import gpiod  # GPIO - uncomment when needed
        HARDWARE_AVAILABLE = True
    except ImportError as e:
        logger.error(f"Failed to import hardware libraries: {e}")
        HARDWARE_AVAILABLE = False
else:
    logger.info("Running on Windows/Desktop - Using mock hardware")
    HARDWARE_AVAILABLE = False


class DHT11Sensor:
    """DHT11 Temperature and Humidity Sensor Interface"""
    
    def __init__(self):
        if IS_RPI and HARDWARE_AVAILABLE:
            try:
                # DHT11 connected to GPIO pin 4 (BCM numbering)
                self.sensor = adafruit_dht.DHT11(board.D4)
                logger.info("DHT11 sensor initialized on GPIO4")
            except Exception as e:
                logger.error(f"Failed to initialize DHT11 sensor: {e}")
                self.sensor = None
        else:
            self.sensor = None
            logger.info("DHT11 sensor: Using mock data")
    
    def read(self) -> Dict[str, Optional[float]]:
        """Read temperature and humidity from sensor"""
        if self.sensor:
            try:
                temperature = self.sensor.temperature
                humidity = self.sensor.humidity
                if temperature is not None and humidity is not None:
                    return {
                        'temperature': round(temperature, 1),
                        'humidity': round(humidity, 1)
                    }
                else:
                    logger.warning("DHT11 sensor returned None values")
                    return {'temperature': None, 'humidity': None}
            except RuntimeError as e:
                # DHT sensors can occasionally fail to read
                logger.warning(f"Failed to read DHT11 sensor: {e}")
                return {'temperature': None, 'humidity': None}
        else:
            # Mock data for testing
            return {
                'temperature': round(random.uniform(20.0, 30.0), 1),
                'humidity': round(random.uniform(40.0, 60.0), 1)
            }


class CANBusInterface:
    """CAN Bus Interface for Vehicle Data (Currently using mock data)"""
    
    def __init__(self):
        # CAN bus functionality commented out for now
        # Will be implemented when CAN hardware is available
        self.bus = None
        self.connected = False
        logger.info("CAN bus: Using mock data (CAN hardware not available)")
    
    def read_vehicle_data(self) -> Dict[str, Any]:
        """Read vehicle telemetry (currently returns mock data)"""
        # When CAN bus is available, implement real CAN message parsing here
        return self._generate_mock_vehicle_data()
    
    def _generate_mock_vehicle_data(self) -> Dict[str, Any]:
        """Generate realistic mock vehicle data"""
        return {
            'speed': round(random.uniform(0, 120), 1),
            'battery_soc': round(random.uniform(60, 95), 1),
            'battery_voltage': round(random.uniform(380, 420), 1),
            'battery_current': round(random.uniform(-50, 50), 1),
            'motor_rpm': round(random.uniform(0, 8000), 0),
            'motor_temp': round(random.uniform(60, 95), 1),
            'range_km': round(random.uniform(250, 350), 0),
            'power_kw': round(random.uniform(0, 100), 1),
        }


class GPSModule:
    """GPS Module Interface"""
    
    def __init__(self):
        if IS_RPI and HARDWARE_AVAILABLE:
            # Initialize GPS module (e.g., via serial port)
            # This is a placeholder for future implementation
            logger.info("GPS module: Real hardware not yet implemented")
            self.available = False
        else:
            self.available = False
            logger.info("GPS module: Using mock data")
        
        # Base coordinates (BMU location - Gurgaon, India)
        self.base_lat = 28.4595
        self.base_lon = 77.0266
        
        # Simulate movement along a route
        self.current_lat = self.base_lat
        self.current_lon = self.base_lon
        self.movement_step = 0
        self.route_points = [
            (28.4595, 77.0266),  # Start point
            (28.4605, 77.0276),  # Move northeast
            (28.4615, 77.0286),  # Continue northeast
            (28.4625, 77.0296),  # Continue northeast
            (28.4635, 77.0306),  # Continue northeast
            (28.4645, 77.0316),  # End point
        ]
    
    def read(self) -> Dict[str, Any]:
        """Read GPS coordinates with simulated movement"""
        if self.available:
            # Read from actual GPS module
            pass
        
        # Simulate movement along route
        point_index = (self.movement_step // 10) % len(self.route_points)
        target_lat, target_lon = self.route_points[point_index]
        
        # Smooth interpolation to target
        self.current_lat += (target_lat - self.current_lat) * 0.1
        self.current_lon += (target_lon - self.current_lon) * 0.1
        
        self.movement_step += 1
        
        # Add small random variation for realism
        lat_with_noise = self.current_lat + random.uniform(-0.0001, 0.0001)
        lon_with_noise = self.current_lon + random.uniform(-0.0001, 0.0001)
        
        return {
            'latitude': round(lat_with_noise, 6),
            'longitude': round(lon_with_noise, 6),
            'heading': round((self.movement_step * 2) % 360, 1),  # Rotating heading
            'altitude': round(random.uniform(230, 250), 1),
            'satellites': random.randint(8, 12),
            'speed_gps': round(random.uniform(0, 100), 1)
        }


# ============================================================================
# BLUETOOTH MEDIA CONTROL
# ============================================================================

class BluetoothMediaController:
    """Bluetooth Media Control Interface"""
    
    def __init__(self):
        self.connected = False
        self.device_name = "No Device"
        self.current_track = {
            'title': 'No Track Playing',
            'artist': 'Unknown Artist',
            'duration': 180,  # 3 minutes in seconds
            'position': 0,
            'is_playing': False
        }
        
        if IS_RPI:
            # Initialize Bluetooth on Raspberry Pi
            # This would use BlueZ D-Bus API or similar
            logger.info("Bluetooth: Real implementation pending")
        else:
            logger.info("Bluetooth: Using mock data")
    
    def connect_device(self, device_address: str) -> bool:
        """Connect to a Bluetooth device"""
        logger.info(f"Attempting to connect to Bluetooth device: {device_address}")
        # Actual Bluetooth connection logic here
        self.connected = True
        self.device_name = "Mock Phone"
        return True
    
    def play(self):
        """Play media"""
        logger.info("Media command: PLAY")
        self.current_track['is_playing'] = True
    
    def pause(self):
        """Pause media"""
        logger.info("Media command: PAUSE")
        self.current_track['is_playing'] = False
    
    def next_track(self):
        """Skip to next track"""
        logger.info("Media command: NEXT")
        self.current_track['position'] = 0
        self.current_track['title'] = f"Track {random.randint(1, 100)}"
    
    def previous_track(self):
        """Go to previous track"""
        logger.info("Media command: PREVIOUS")
        self.current_track['position'] = 0
        self.current_track['title'] = f"Track {random.randint(1, 100)}"
    
    def set_volume(self, volume: float):
        """Set volume (0.0 to 1.0)"""
        logger.info(f"Media command: SET_VOLUME to {volume}")
    
    def get_status(self) -> Dict[str, Any]:
        """Get current media status"""
        # Update position if playing
        if self.current_track['is_playing']:
            self.current_track['position'] = min(
                self.current_track['position'] + 1,
                self.current_track['duration']
            )
        
        return {
            'connected': self.connected,
            'device_name': self.device_name,
            'track_title': self.current_track['title'],
            'track_artist': self.current_track['artist'],
            'duration': self.current_track['duration'],
            'position': self.current_track['position'],
            'is_playing': self.current_track['is_playing']
        }


# ============================================================================
# MQTT CLOUD INTEGRATION
# ============================================================================

class MQTTCloudClient:
    """MQTT Client for Cloud Connectivity"""
    
    def __init__(self):
        self.connected = False
        self.client = None
        
        try:
            import paho.mqtt.client as mqtt
            self.mqtt = mqtt
            logger.info("MQTT library loaded successfully")
        except ImportError:
            logger.warning("paho-mqtt not installed. Cloud features disabled.")
            self.mqtt = None
    
    def connect(self, broker: str, port: int = 1883, use_tls: bool = False):
        """Connect to MQTT broker"""
        if not self.mqtt:
            logger.error("MQTT library not available")
            return False
        
        try:
            self.client = self.mqtt.Client()
            
            # Set callbacks
            self.client.on_connect = self._on_connect
            self.client.on_disconnect = self._on_disconnect
            self.client.on_message = self._on_message
            
            # Configure TLS/SSL for production
            if use_tls:
                # TODO: Configure TLS certificates for production
                # self.client.tls_set(
                #     ca_certs="/path/to/ca.crt",
                #     certfile="/path/to/client.crt",
                #     keyfile="/path/to/client.key"
                # )
                logger.warning("TLS requested but not configured. Using insecure connection.")
            
            # Connect to broker
            self.client.connect(broker, port, keepalive=60)
            self.client.loop_start()
            
            logger.info(f"Connecting to MQTT broker: {broker}:{port}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to connect to MQTT broker: {e}")
            return False
    
    def _on_connect(self, client, userdata, flags, rc):
        """Callback when connected to MQTT broker"""
        if rc == 0:
            self.connected = True
            logger.info("Connected to MQTT broker successfully")
            # Subscribe to command topics
            client.subscribe("ev/commands/#")
        else:
            logger.error(f"Failed to connect to MQTT broker. Return code: {rc}")
    
    def _on_disconnect(self, client, userdata, rc):
        """Callback when disconnected from MQTT broker"""
        self.connected = False
        logger.warning(f"Disconnected from MQTT broker. Return code: {rc}")
    
    def _on_message(self, client, userdata, msg):
        """Callback when message received from MQTT broker"""
        logger.info(f"MQTT message received: {msg.topic} - {msg.payload.decode()}")
    
    def publish_telemetry(self, data: Dict[str, Any]):
        """Publish telemetry data to cloud"""
        if self.client and self.connected:
            try:
                payload = json.dumps(data)
                self.client.publish("ev/telemetry", payload, qos=1)
            except Exception as e:
                logger.warning(f"Failed to publish telemetry: {e}")
    
    def disconnect(self):
        """Disconnect from MQTT broker"""
        if self.client:
            self.client.loop_stop()
            self.client.disconnect()
            logger.info("Disconnected from MQTT broker")


# ============================================================================
# MAIN BACKEND SERVER
# ============================================================================

class EVBackendServer:
    """Main EV Infotainment Backend Server"""
    
    def __init__(self):
        # Hardware interfaces
        self.dht_sensor = DHT11Sensor()
        self.can_bus = CANBusInterface()
        self.gps = GPSModule()
        self.bluetooth = BluetoothMediaController()
        self.mqtt = MQTTCloudClient()
        
        # Connected WebSocket clients
        self.clients: Set = set()
        
        # Server state
        self.running = False
        
        # Settings state (from Flutter UI)
        self.settings = {
            'charge_limit': 80,
            'regen_level': 'standard',
            'drive_mode': 'eco',
            'brightness': 60,
            'light_theme': False,
            'predictions_on': True,
            'twin_mode': '3d'
        }
        
        # Tire pressure data
        self.tire_pressure = {
            'front_left': 35.2,
            'front_right': 35.1,
            'rear_left': 34.9,
            'rear_right': 35.0
        }
        
        # Battery cell temperatures
        self.battery_cells = {
            'block_a': 28.5,
            'block_b': 29.1,
            'block_c': 29.0
        }
        
        # Valid commands for security
        self.VALID_COMMANDS = {
            'play_music', 'pause_music', 'next_track', 'previous_track',
            'set_volume', 'set_charge_limit', 'set_regen_level',
            'set_drive_mode', 'set_brightness', 'set_theme',
            'toggle_predictions', 'set_twin_mode', 'connect_bluetooth'
        }
        
        logger.info("EV Backend Server initialized")
    
    async def start(self, host: str = '0.0.0.0', port: int = 8765):
        """Start the WebSocket server"""
        self.running = True
        
        # Start MQTT connection (optional)
        # self.mqtt.connect('broker.example.com', 1883, use_tls=False)
        
        logger.info(f"WebSocket server starting on ws://{host}:{port}")
        
        async with websockets.serve(self.handle_client, host, port):
            logger.info(f"WebSocket server started on ws://{host}:{port}")
            
            # Start telemetry broadcast task
            telemetry_task = asyncio.create_task(self.broadcast_telemetry())
            
            # Keep server running
            try:
                await asyncio.Future()  # Run forever
            except KeyboardInterrupt:
                logger.info("Server shutdown requested")
            finally:
                self.running = False
                telemetry_task.cancel()
                self.mqtt.disconnect()
    
    async def handle_client(self, websocket):
        """Handle new WebSocket client connection"""
        self.clients.add(websocket)
        client_addr = websocket.remote_address
        logger.info(f"Flutter client connected: {client_addr}")
        
        try:
            # Send initial connection confirmation
            await websocket.send(json.dumps({
                'type': 'connection',
                'status': 'connected',
                'message': 'Connected to EV Backend Server'
            }))
            
            # Listen for commands from client
            async for message in websocket:
                await self.handle_command(websocket, message)
                
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"Flutter client disconnected: {client_addr}")
        except Exception as e:
            logger.error(f"Error handling client {client_addr}: {e}")
        finally:
            self.clients.discard(websocket)
    
    async def handle_command(self, websocket, message: str):
        """Handle incoming command from Flutter client"""
        try:
            data = json.loads(message)
            action = data.get('action')
            
            # Input sanitization - validate action
            if not action or action not in self.VALID_COMMANDS:
                logger.warning(f"Invalid or unknown action received: {action}")
                await websocket.send(json.dumps({
                    'type': 'error',
                    'message': f'Invalid action: {action}'
                }))
                return
            
            logger.info(f"Command received: {action}")
            
            # Execute command
            response = await self.execute_command(action, data)
            
            # Send response
            await websocket.send(json.dumps(response))
            
        except json.JSONDecodeError:
            logger.error("Received invalid JSON from client")
            await websocket.send(json.dumps({
                'type': 'error',
                'message': 'Invalid JSON format'
            }))
        except Exception as e:
            logger.error(f"Error handling command: {e}")
            await websocket.send(json.dumps({
                'type': 'error',
                'message': str(e)
            }))
    
    async def execute_command(self, action: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a validated command"""
        
        # Media controls
        if action == 'play_music':
            self.bluetooth.play()
            return {'type': 'response', 'action': action, 'status': 'success'}
        
        elif action == 'pause_music':
            self.bluetooth.pause()
            return {'type': 'response', 'action': action, 'status': 'success'}
        
        elif action == 'next_track':
            self.bluetooth.next_track()
            return {'type': 'response', 'action': action, 'status': 'success'}
        
        elif action == 'previous_track':
            self.bluetooth.previous_track()
            return {'type': 'response', 'action': action, 'status': 'success'}
        
        elif action == 'set_volume':
            volume = data.get('volume', 0.5)
            self.bluetooth.set_volume(volume)
            return {'type': 'response', 'action': action, 'status': 'success'}
        
        # Vehicle settings
        elif action == 'set_charge_limit':
            limit = data.get('value', 80)
            self.settings['charge_limit'] = limit
            logger.info(f"Charge limit set to {limit}%")
            return {'type': 'response', 'action': action, 'status': 'success', 'value': limit}
        
        elif action == 'set_regen_level':
            level = data.get('value', 'standard')
            self.settings['regen_level'] = level
            logger.info(f"Regen level set to {level}")
            return {'type': 'response', 'action': action, 'status': 'success', 'value': level}
        
        elif action == 'set_drive_mode':
            mode = data.get('value', 'eco')
            self.settings['drive_mode'] = mode
            logger.info(f"Drive mode set to {mode}")
            return {'type': 'response', 'action': action, 'status': 'success', 'value': mode}
        
        # Infotainment settings
        elif action == 'set_brightness':
            brightness = data.get('value', 60)
            self.settings['brightness'] = brightness
            logger.info(f"Brightness set to {brightness}%")
            return {'type': 'response', 'action': action, 'status': 'success', 'value': brightness}
        
        elif action == 'set_theme':
            light_theme = data.get('value', False)
            self.settings['light_theme'] = light_theme
            logger.info(f"Theme set to {'light' if light_theme else 'dark'}")
            return {'type': 'response', 'action': action, 'status': 'success', 'value': light_theme}
        
        # Digital Twin settings
        elif action == 'toggle_predictions':
            predictions = data.get('value', True)
            self.settings['predictions_on'] = predictions
            logger.info(f"Predictions {'enabled' if predictions else 'disabled'}")
            return {'type': 'response', 'action': action, 'status': 'success', 'value': predictions}
        
        elif action == 'set_twin_mode':
            mode = data.get('value', '3d')
            self.settings['twin_mode'] = mode
            logger.info(f"Twin mode set to {mode}")
            return {'type': 'response', 'action': action, 'status': 'success', 'value': mode}
        
        # Bluetooth connection
        elif action == 'connect_bluetooth':
            device_address = data.get('device_address', '')
            success = self.bluetooth.connect_device(device_address)
            return {'type': 'response', 'action': action, 'status': 'success' if success else 'failed'}
        
        else:
            return {'type': 'response', 'action': action, 'status': 'unknown'}
    
    async def broadcast_telemetry(self):
        """Broadcast telemetry data to all connected clients"""
        logger.info("Telemetry broadcast task started")
        
        while self.running:
            try:
                # Gather all telemetry data
                telemetry = self.collect_telemetry()
                
                # Broadcast to all connected clients
                if self.clients:
                    message = json.dumps(telemetry)
                    await asyncio.gather(
                        *[client.send(message) for client in self.clients],
                        return_exceptions=True
                    )
                
                # Publish to MQTT cloud (if connected)
                if self.mqtt.connected:
                    self.mqtt.publish_telemetry(telemetry)
                
                # Wait 1 second before next broadcast
                await asyncio.sleep(1.0)
                
            except Exception as e:
                logger.error(f"Error in telemetry broadcast: {e}")
                await asyncio.sleep(1.0)
    
    def collect_telemetry(self) -> Dict[str, Any]:
        """Collect all telemetry data from sensors and systems"""
        
        # Read DHT11 sensor
        dht_data = self.dht_sensor.read()
        
        # Read vehicle data from CAN bus (currently mock)
        vehicle_data = self.can_bus.read_vehicle_data()
        
        # Read GPS data
        gps_data = self.gps.read()
        
        # Get Bluetooth media status
        media_status = self.bluetooth.get_status()
        
        # Compile complete telemetry packet
        telemetry = {
            'type': 'telemetry',
            'timestamp': datetime.now().isoformat(),
            
            # Environmental sensors
            'ambient_temp': dht_data['temperature'],
            'humidity': dht_data['humidity'],
            'cabin_temp': dht_data['temperature'] - 3 if dht_data['temperature'] else None,  # Mock cabin temp
            
            # Vehicle dynamics
            'speed': vehicle_data['speed'],
            'range_km': vehicle_data['range_km'],
            
            # Battery system
            'battery_soc': vehicle_data['battery_soc'],
            'battery_voltage': vehicle_data['battery_voltage'],
            'battery_current': vehicle_data['battery_current'],
            'battery_soh': round(random.uniform(95, 99), 1),  # State of Health
            
            # Motor system
            'motor_rpm': vehicle_data['motor_rpm'],
            'motor_temp': vehicle_data['motor_temp'],
            'power_kw': vehicle_data['power_kw'],
            
            # Efficiency metrics
            'efficiency_score': round(random.uniform(7.0, 9.5), 1),
            'wheel_speed': round(random.uniform(0, 50), 0),
            
            # GPS data
            'gps': {
                'latitude': gps_data['latitude'],
                'longitude': gps_data['longitude'],
                'altitude': gps_data['altitude'],
                'satellites': gps_data['satellites'],
                'speed_gps': gps_data['speed_gps']
            },
            
            # Tire pressure
            'tire_pressure': self.tire_pressure,
            
            # Battery cells
            'battery_cells': self.battery_cells,
            
            # Connectivity status
            'connectivity': {
                'wifi': random.choice([True, False]),
                'bluetooth': self.bluetooth.connected,
                'can_bus': self.can_bus.connected
            },
            
            # Media player
            'media': media_status,
            
            # Settings
            'settings': self.settings
        }
        
        return telemetry


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

async def main():
    """Main entry point"""
    logger.info("=" * 60)
    logger.info("EV Smart Screen - Backend Server")
    logger.info("Phase 1 Prototype")
    logger.info("=" * 60)
    logger.info(f"Platform: {platform.system()} {platform.machine()}")
    logger.info(f"Python: {platform.python_version()}")
    logger.info(f"Running on Raspberry Pi: {IS_RPI}")
    logger.info(f"Hardware Available: {HARDWARE_AVAILABLE}")
    logger.info("=" * 60)
    
    # Create and start server
    server = EVBackendServer()
    await server.start(host='0.0.0.0', port=8765)


if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
