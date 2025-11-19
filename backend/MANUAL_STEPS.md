# Manual Configuration Steps

## What You Need to Do

### 1. Install Python Dependencies ✓

**On Windows:**
```bash
cd backend
pip install -r requirements.txt
```

**On Raspberry Pi:**
```bash
cd backend
pip3 install -r requirements.txt
```

Some packages will fail on Windows (this is normal).

---

### 2. Configure API Keys 🔑

#### Google Maps API Key (REQUIRED for Maps)

**Steps:**
1. Go to https://console.cloud.google.com/
2. Create a new project (or select existing)
3. Click "Enable APIs and Services"
4. Search for and enable:
   - Maps JavaScript API
   - Directions API
   - Places API (optional)
5. Go to "Credentials" → "Create Credentials" → "API Key"
6. Copy the API key
7. Open `backend/config.py`
8. Replace:
   ```python
   MAPS_API_KEY = 'YOUR_GOOGLE_MAPS_API_KEY_HERE'
   ```
   with your actual key:
   ```python
   MAPS_API_KEY = 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
   ```

**Cost:** Free tier includes $200/month credit (sufficient for development)

---

### 3. MQTT Cloud Setup (OPTIONAL) ☁️

Only needed if you want remote monitoring/cloud features.

#### Option A: AWS IoT Core

1. Go to AWS IoT Console
2. Create a Thing
3. Download certificates (3 files)
4. Update `config.py`:
```python
MQTT_ENABLED = True
MQTT_BROKER = 'xxxxx-ats.iot.us-east-1.amazonaws.com'
MQTT_PORT = 8883
MQTT_USE_TLS = True
MQTT_CA_CERT = '/path/to/AmazonRootCA1.pem'
MQTT_CLIENT_CERT = '/path/to/certificate.pem.crt'
MQTT_CLIENT_KEY = '/path/to/private.pem.key'
```

#### Option B: HiveMQ Cloud (Easier)

1. Sign up at https://www.hivemq.com/mqtt-cloud-broker/
2. Create a free cluster
3. Note the connection details
4. Update `config.py`:
```python
MQTT_ENABLED = True
MQTT_BROKER = 'xxxxx.s1.eu.hivemq.cloud'
MQTT_PORT = 8883
MQTT_USERNAME = 'your_username'
MQTT_PASSWORD = 'your_password'
MQTT_USE_TLS = True
```

**Skip this if you don't need cloud features.**

---

### 4. Raspberry Pi Hardware Setup 🔧

#### A. DHT11 Sensor Wiring

**Required:**
- DHT11 sensor
- 10kΩ resistor
- Jumper wires

**Connections:**
```
DHT11 Pin 1 (VCC)  → Raspberry Pi Pin 1 (3.3V)
DHT11 Pin 2 (DATA) → Raspberry Pi Pin 7 (GPIO4)
DHT11 Pin 4 (GND)  → Raspberry Pi Pin 6 (GND)

Add 10kΩ resistor between Pin 1 and Pin 2 of DHT11
```

**Verify:**
```bash
python3 -c "from main import DHT11Sensor; s = DHT11Sensor(); print(s.read())"
```

#### B. Enable CAN Bus (OPTIONAL)

Only if you have a CAN bus interface (MCP2515).

**Edit boot config:**
```bash
sudo nano /boot/config.txt
```

**Add these lines:**
```
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25
dtoverlay=spi-bcm2835
```

**Reboot and enable:**
```bash
sudo reboot
sudo ip link set can0 up type can bitrate 500000
```

**Verify:**
```bash
ip link show can0
```

#### C. Enable I2C and SPI

```bash
sudo raspi-config
# Interface Options → I2C → Enable
# Interface Options → SPI → Enable
```

---

### 5. Test the Backend 🧪

**Start the server:**
```bash
cd backend
python main.py  # or python3 on Pi
```

**Expected output:**
```
INFO - WebSocket server started on ws://0.0.0.0:8765
INFO - Telemetry broadcast task started
```

**Test connection:**
```bash
# In another terminal
python test_connection.py
```

---

### 6. Connect Flutter App 📱

**Update Flutter app to connect to backend:**

Find the WebSocket connection code in Flutter and update:

**On Windows (same machine):**
```dart
final ws = WebSocket('ws://localhost:8765');
```

**On Raspberry Pi (from another device):**
```dart
final ws = WebSocket('ws://192.168.1.XXX:8765');
```

Replace `192.168.1.XXX` with your Pi's IP address:
```bash
# On Pi, run:
hostname -I
```

---

## Summary Checklist

- [ ] Install Python dependencies
- [ ] Add Google Maps API key to `config.py`
- [ ] (Optional) Configure MQTT cloud connection
- [ ] (Pi only) Wire DHT11 sensor to GPIO4
- [ ] (Pi only) Enable I2C and SPI interfaces
- [ ] (Optional) Enable CAN bus interface
- [ ] Test backend with `python main.py`
- [ ] Test connection with `python test_connection.py`
- [ ] Update Flutter app with backend IP address
- [ ] Run Flutter app and verify data flow

---

## Troubleshooting

**"Module not found" errors:**
```bash
pip install -r requirements.txt
```

**"Permission denied" on GPIO:**
```bash
sudo usermod -a -G gpio $USER
sudo reboot
```

**"DHT11 returns None":**
- Check wiring
- Add pull-up resistor
- Try multiple reads (sensor can be flaky)

**"Connection refused" from Flutter:**
- Check backend is running
- Verify IP address
- Check firewall settings

---

## Need Help?

**Email:** guneet.chawla.22cse@bmu.edu.in

**Common Issues:**
- Backend not starting → Check Python version (3.8+)
- No data from sensors → Check wiring and permissions
- Flutter can't connect → Verify IP address and port 8765
