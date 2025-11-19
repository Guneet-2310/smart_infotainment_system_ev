# EV Smart Screen - Backend Server

## Overview

This is the Python backend server for the EV Smart Screen infotainment system. It provides real-time telemetry data and command handling for the Flutter frontend, with support for both development (Windows) and production (Raspberry Pi) environments.

## Features

- **WebSocket Server**: Real-time bidirectional communication with Flutter frontend
- **Cross-Platform**: Runs on Windows (mock data) and Raspberry Pi (real hardware)
- **Hardware Support**: DHT11 sensor, CAN bus, GPS, Bluetooth
- **Cloud Connectivity**: MQTT integration for remote monitoring
- **Security**: Input validation and TLS/SSL support
- **Logging**: Comprehensive logging for debugging and monitoring

## System Requirements

### Windows (Development)
- Python 3.8 or higher
- Windows 10/11

### Raspberry Pi (Production)
- Raspberry Pi 3/4/5
- Raspberry Pi OS (64-bit Debian Trixie or later)
- Python 3.9 or higher
- DHT11 sensor connected to GPIO4
- CAN bus interface (optional)
- GPS module (optional)

## Installation

### 1. Install Python Dependencies

#### On Windows:
```bash
cd backend
pip install -r requirements.txt
```

**Note**: Some Raspberry Pi-specific packages will fail to install on Windows. This is expected and won't affect functionality.

#### On Raspberry Pi:
```bash
cd backend
pip3 install -r requirements.txt
```

### 2. Enable Hardware Interfaces (Raspberry Pi Only)

#### Enable I2C and SPI:
```bash
sudo raspi-config
# Navigate to: Interface Options → I2C → Enable
# Navigate to: Interface Options → SPI → Enable
```

#### Enable CAN Bus (if using):
```bash
# Add to /boot/config.txt:
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25
dtoverlay=spi-bcm2835

# Reboot
sudo reboot

# Bring up CAN interface
sudo ip link set can0 up type can bitrate 500000
```

#### Install System Dependencies:
```bash
# For DHT11 sensor
sudo apt-get update
sudo apt-get install -y python3-pip python3-dev libgpiod2

# For CAN bus
sudo apt-get install -y can-utils

# For Bluetooth (optional)
sudo apt-get install -y bluez python3-bluez
```

## Configuration

### 1. Edit Configuration File

Open `backend/config.py` and configure:

#### Maps API Key (Required for Maps functionality):
```python
MAPS_API_KEY = 'YOUR_GOOGLE_MAPS_API_KEY_HERE'
```

**How to get Google Maps API Key:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable "Maps JavaScript API" and "Directions API"
4. Create credentials → API Key
5. Copy the API key to `config.py`

#### MQTT Cloud Connection (Optional):
```python
MQTT_ENABLED = True
MQTT_BROKER = 'your-mqtt-broker.com'
MQTT_PORT = 1883
MQTT_USERNAME = 'your_username'
MQTT_PASSWORD = 'your_password'
```

**Popular MQTT Brokers:**
- AWS IoT Core
- Azure IoT Hub
- HiveMQ Cloud
- CloudMQTT
- Mosquitto (self-hosted)

#### TLS/SSL Certificates (Production):
```python
MQTT_USE_TLS = True
MQTT_CA_CERT = '/path/to/ca.crt'
MQTT_CLIENT_CERT = '/path/to/client.crt'
MQTT_CLIENT_KEY = '/path/to/client.key'
```

### 2. Hardware Configuration (Raspberry Pi)

#### DHT11 Sensor Wiring:
```
DHT11 Pin 1 (VCC)  → Raspberry Pi 3.3V (Pin 1)
DHT11 Pin 2 (DATA) → Raspberry Pi GPIO4 (Pin 7)
DHT11 Pin 3 (NC)   → Not connected
DHT11 Pin 4 (GND)  → Raspberry Pi GND (Pin 6)
```

**Note**: Add a 10kΩ pull-up resistor between DATA and VCC for stable readings.

#### CAN Bus Wiring (if using MCP2515):
```
MCP2515 VCC  → Raspberry Pi 5V
MCP2515 GND  → Raspberry Pi GND
MCP2515 SCK  → Raspberry Pi GPIO11 (SPI0 SCLK)
MCP2515 MOSI → Raspberry Pi GPIO10 (SPI0 MOSI)
MCP2515 MISO → Raspberry Pi GPIO9 (SPI0 MISO)
MCP2515 CS   → Raspberry Pi GPIO8 (SPI0 CE0)
MCP2515 INT  → Raspberry Pi GPIO25
```

## Running the Server

### On Windows (Development):
```bash
cd backend
python main.py
```

### On Raspberry Pi (Production):
```bash
cd backend
python3 main.py
```

### Run as Background Service (Raspberry Pi):

Create systemd service file:
```bash
sudo nano /etc/systemd/system/ev-backend.service
```

Add the following content:
```ini
[Unit]
Description=EV Smart Screen Backend Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/ev_smart_screen/backend
ExecStart=/usr/bin/python3 /home/pi/ev_smart_screen/backend/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable ev-backend.service
sudo systemctl start ev-backend.service

# Check status
sudo systemctl status ev-backend.service

# View logs
sudo journalctl -u ev-backend.service -f
```

## Testing the Server

### 1. Check Server Status

When the server starts, you should see:
```
2025-01-XX XX:XX:XX - __main__ - INFO - ============================================================
2025-01-XX XX:XX:XX - __main__ - INFO - EV Smart Screen - Backend Server
2025-01-XX XX:XX:XX - __main__ - INFO - Phase 1 Prototype
2025-01-XX XX:XX:XX - __main__ - INFO - ============================================================
2025-01-XX XX:XX:XX - __main__ - INFO - Platform: Windows AMD64
2025-01-XX XX:XX:XX - __main__ - INFO - Python: 3.11.0
2025-01-XX XX:XX:XX - __main__ - INFO - Running on Raspberry Pi: False
2025-01-XX XX:XX:XX - __main__ - INFO - Hardware Available: False
2025-01-XX XX:XX:XX - __main__ - INFO - ============================================================
2025-01-XX XX:XX:XX - __main__ - INFO - WebSocket server started on ws://0.0.0.0:8765
```

### 2. Test WebSocket Connection

Use a WebSocket client tool or browser console:

```javascript
// In browser console
const ws = new WebSocket('ws://localhost:8765');

ws.onopen = () => {
    console.log('Connected to backend');
};

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log('Received:', data);
};

// Send a command
ws.send(JSON.stringify({
    action: 'play_music'
}));
```

### 3. Test with Flutter App

1. Start the backend server
2. Update Flutter app to connect to backend:
   - Windows: `ws://localhost:8765`
   - Raspberry Pi: `ws://[PI_IP_ADDRESS]:8765`
3. Run the Flutter app
4. Check backend logs for connection messages

## API Reference

### WebSocket Connection

**URL**: `ws://[HOST]:8765`

### Telemetry Data (Server → Client)

The server broadcasts telemetry data every 1 second:

```json
{
  "type": "telemetry",
  "timestamp": "2025-01-15T10:30:45.123456",
  "ambient_temp": 25.3,
  "humidity": 55.2,
  "cabin_temp": 22.3,
  "speed": 88.5,
  "range_km": 320,
  "battery_soc": 75.2,
  "battery_voltage": 400.5,
  "battery_current": -25.3,
  "battery_soh": 98.5,
  "motor_rpm": 3500,
  "motor_temp": 85.2,
  "power_kw": 45.3,
  "efficiency_score": 8.2,
  "wheel_speed": 40,
  "gps": {
    "latitude": 28.4251,
    "longitude": 77.0435,
    "altitude": 238.5,
    "satellites": 10,
    "speed_gps": 88.2
  },
  "tire_pressure": {
    "front_left": 35.2,
    "front_right": 35.1,
    "rear_left": 34.9,
    "rear_right": 35.0
  },
  "battery_cells": {
    "block_a": 28.5,
    "block_b": 29.1,
    "block_c": 29.0
  },
  "connectivity": {
    "wifi": true,
    "bluetooth": false,
    "can_bus": false
  },
  "media": {
    "connected": false,
    "device_name": "No Device",
    "track_title": "No Track Playing",
    "track_artist": "Unknown Artist",
    "duration": 0,
    "position": 0,
    "is_playing": false
  },
  "settings": {
    "charge_limit": 80,
    "regen_level": "standard",
    "drive_mode": "eco",
    "brightness": 60,
    "light_theme": false,
    "predictions_on": true,
    "twin_mode": "3d"
  }
}
```

### Commands (Client → Server)

Send commands as JSON:

#### Media Controls:
```json
{"action": "play_music"}
{"action": "pause_music"}
{"action": "next_track"}
{"action": "previous_track"}
{"action": "set_volume", "volume": 0.7}
```

#### Vehicle Settings:
```json
{"action": "set_charge_limit", "value": 80}
{"action": "set_regen_level", "value": "standard"}
{"action": "set_drive_mode", "value": "eco"}
```

#### Infotainment Settings:
```json
{"action": "set_brightness", "value": 60}
{"action": "set_theme", "value": false}
```

#### Digital Twin Settings:
```json
{"action": "toggle_predictions", "value": true}
{"action": "set_twin_mode", "value": "3d"}
```

#### Bluetooth:
```json
{"action": "connect_bluetooth", "device_address": "XX:XX:XX:XX:XX:XX"}
```

### Command Response

```json
{
  "type": "response",
  "action": "play_music",
  "status": "success"
}
```

## Troubleshooting

### Issue: "Module 'websockets' not found"
**Solution**: Install dependencies
```bash
pip install -r requirements.txt
```

### Issue: "DHT11 sensor returned None values"
**Solution**: 
- Check wiring connections
- Add 10kΩ pull-up resistor
- Try reading multiple times (sensor can be unreliable)

### Issue: "CAN bus interface 'can0' not found"
**Solution**:
- Check CAN bus wiring
- Verify device tree overlay in `/boot/config.txt`
- Bring up interface: `sudo ip link set can0 up type can bitrate 500000`

### Issue: "Permission denied" on GPIO
**Solution**:
```bash
sudo usermod -a -G gpio $USER
sudo reboot
```

### Issue: WebSocket connection refused
**Solution**:
- Check if server is running
- Verify firewall settings
- On Pi, check IP address: `hostname -I`

### Issue: High CPU usage
**Solution**:
- Increase telemetry interval in `config.py`
- Reduce number of connected clients
- Check for infinite loops in logs

## Security Considerations

### Production Deployment:

1. **Enable TLS/SSL** for MQTT connections
2. **Use strong passwords** for MQTT authentication
3. **Implement WebSocket authentication** (future feature)
4. **Restrict network access** using firewall rules
5. **Keep software updated** regularly
6. **Monitor logs** for suspicious activity

### Firewall Configuration (Raspberry Pi):

```bash
# Install UFW
sudo apt-get install ufw

# Allow SSH
sudo ufw allow 22/tcp

# Allow WebSocket
sudo ufw allow 8765/tcp

# Enable firewall
sudo ufw enable
```

## Performance Optimization

### For Raspberry Pi:

1. **Overclock** (optional, increases performance):
```bash
# Add to /boot/config.txt
arm_freq=1800
over_voltage=6
```

2. **Disable unnecessary services**:
```bash
sudo systemctl disable bluetooth  # If not using Bluetooth
sudo systemctl disable cups        # If not using printing
```

3. **Use lightweight OS**: Raspberry Pi OS Lite (no desktop)

## Development Tips

### Enable Debug Logging:

In `config.py`:
```python
LOG_LEVEL = 'DEBUG'
LOG_FILE = 'backend.log'
```

### Test Individual Components:

```python
# Test DHT11 sensor
from main import DHT11Sensor
sensor = DHT11Sensor()
print(sensor.read())

# Test CAN bus
from main import CANBusInterface
can = CANBusInterface()
print(can.read_vehicle_data())
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly on both Windows and Raspberry Pi
4. Submit a pull request

## Support

For issues and questions:
- **Email**: prakharkumar.srivastava.22cse@bmu.edu.in
- **GitHub Issues**: Report bugs and request features

## License

Copyright © 2025 BML Munjal University. All rights reserved.

---

**Developer**: Guneet Chawla  
**Institution**: BML Munjal University  
**Version**: 1.0.0 (Phase 1 Prototype)
