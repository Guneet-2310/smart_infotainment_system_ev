# EV Smart Screen Backend - Setup Guide

## Quick Start

### Windows (Development)
1. Install Python 3.8+
2. `cd backend`
3. `pip install -r requirements.txt`
4. Edit `config.py` - Add your Google Maps API key
5. `python main.py`

### Raspberry Pi (Production)
1. Install Raspberry Pi OS (64-bit)
2. `cd backend`
3. `pip3 install -r requirements.txt`
4. Wire DHT11 sensor to GPIO4
5. Edit `config.py` - Add API keys
6. `python3 main.py`

## Manual Configuration Steps

### 1. Google Maps API Key (REQUIRED)

**Get API Key:**
- Go to https://console.cloud.google.com/
- Create project → Enable "Maps JavaScript API"
- Create credentials → API Key
- Copy key to `config.py`:
  ```python
  MAPS_API_KEY = 'YOUR_KEY_HERE'
  ```

### 2. MQTT Cloud (OPTIONAL)

**For AWS IoT Core:**
- Create Thing in AWS IoT Console
- Download certificates
- Update `config.py`:
  ```python
  MQTT_ENABLED = True
  MQTT_BROKER = 'xxxxx.iot.us-east-1.amazonaws.com'
  MQTT_PORT = 8883
  MQTT_USE_TLS = True
  MQTT_CA_CERT = '/path/to/AmazonRootCA1.pem'
  MQTT_CLIENT_CERT = '/path/to/certificate.pem.crt'
  MQTT_CLIENT_KEY = '/path/to/private.pem.key'
  ```

### 3. Raspberry Pi Hardware Setup

**Enable CAN Bus:**
```bash
sudo nano /boot/config.txt
# Add: dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25
sudo reboot
sudo ip link set can0 up type can bitrate 500000
```

**DHT11 Wiring:**
- VCC → Pin 1 (3.3V)
- DATA → Pin 7 (GPIO4)
- GND → Pin 6 (GND)
- Add 10kΩ resistor between VCC and DATA

## Testing

Start server and check logs for:
```
INFO - WebSocket server started on ws://0.0.0.0:8765
INFO - Flutter client connected
```

Connect Flutter app to `ws://[IP]:8765`
