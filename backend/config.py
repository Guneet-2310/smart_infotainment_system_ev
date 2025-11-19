"""
Configuration file for EV Smart Screen Backend
Edit this file to customize server settings
"""

# ============================================================================
# SERVER CONFIGURATION
# ============================================================================

# WebSocket Server
WEBSOCKET_HOST = '0.0.0.0'  # Listen on all interfaces
WEBSOCKET_PORT = 8765       # Default WebSocket port

# ============================================================================
# MQTT CLOUD CONFIGURATION
# ============================================================================

# MQTT Broker Settings
MQTT_ENABLED = False  # Set to True to enable cloud connectivity
MQTT_BROKER = 'a4c3893e49ad47d0844abfbc591f0f22.s1.eu.hivemq.cloud'  # Your HiveMQ Cloud URL
MQTT_PORT = 8883  # TLS port (MUST be 8883 for HiveMQ Cloud)
MQTT_USE_TLS = True  # Set to True for secure connection

# MQTT Authentication (if required)
MQTT_USERNAME = "guneet"  # Set your username or None
MQTT_PASSWORD = "Guneet@2025"  # Set your password or None

# MQTT Topics
MQTT_TOPIC_TELEMETRY = 'ev/telemetry'
MQTT_TOPIC_COMMANDS = 'ev/commands/#'

# TLS/SSL Certificate Paths (OPTIONAL - Not needed for HiveMQ Cloud free tier)
# HiveMQ Cloud uses username/password authentication, not certificates
# Only configure these for enterprise MQTT brokers that require client certificates
MQTT_CA_CERT = None  # Not needed for HiveMQ Cloud
MQTT_CLIENT_CERT = None  # Not needed for HiveMQ Cloud
MQTT_CLIENT_KEY = None  # Not needed for HiveMQ Cloud

# ============================================================================
# HARDWARE CONFIGURATION
# ============================================================================

# DHT11 Sensor
DHT11_GPIO_PIN = 4  # BCM GPIO pin number (default: GPIO4)

# CAN Bus
CAN_INTERFACE = 'can0'  # CAN interface name
CAN_BITRATE = 500000    # CAN bus bitrate (500 kbps standard)

# GPS Module
GPS_SERIAL_PORT = '/dev/ttyUSB0'  # GPS module serial port
GPS_BAUDRATE = 9600               # GPS module baud rate

# ============================================================================
# MAPS API CONFIGURATION
# ============================================================================

# Maps API Configuration
MAPS_API_PROVIDER = 'mapbox'  # Using Mapbox (free tier: 50k loads/month)

# Mapbox API (FREE and works on Linux/Pi OS)
MAPBOX_API_KEY = 'sk.eyJ1IjoiZ3VuZWV0MjMiLCJhIjoiY21odmtydjZ0MDNqcjJyczZhMXdhNHNpMyJ9.sHv3GJEK08yb08QnNTTiZg'

# Google Maps API (OPTIONAL - Not needed, Mapbox is better and free)
MAPS_API_KEY = None  # Not using Google Maps

# ============================================================================
# BLUETOOTH CONFIGURATION
# ============================================================================

# Bluetooth Device Settings
BLUETOOTH_DEVICE_NAME = 'EV-Smart-Screen'
BLUETOOTH_AUTO_CONNECT = True  # Auto-connect to last paired device

# ============================================================================
# TELEMETRY CONFIGURATION
# ============================================================================

# Telemetry broadcast interval (seconds)
TELEMETRY_INTERVAL = 1.0  # Send updates every 1 second

# Data retention
TELEMETRY_HISTORY_SIZE = 300  # Keep last 5 minutes (300 seconds)

# ============================================================================
# LOGGING CONFIGURATION
# ============================================================================

# Log level: DEBUG, INFO, WARNING, ERROR, CRITICAL
LOG_LEVEL = 'INFO'

# Log file (None for console only)
LOG_FILE = None  # Set to 'backend.log' to enable file logging

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

# WebSocket authentication (future feature)
WEBSOCKET_AUTH_ENABLED = False
WEBSOCKET_AUTH_TOKEN = None

# Command rate limiting
COMMAND_RATE_LIMIT = 10  # Max commands per second per client

# ============================================================================
# DEFAULT VEHICLE SETTINGS
# ============================================================================

DEFAULT_SETTINGS = {
    'charge_limit': 80,
    'regen_level': 'standard',
    'drive_mode': 'eco',
    'brightness': 60,
    'light_theme': False,
    'predictions_on': True,
    'twin_mode': '3d'
}

# ============================================================================
# MOCK DATA CONFIGURATION (for testing on Windows)
# ============================================================================

# Mock data ranges
MOCK_SPEED_RANGE = (0, 120)  # km/h
MOCK_BATTERY_SOC_RANGE = (60, 95)  # percentage
MOCK_TEMP_RANGE = (20, 30)  # Celsius
MOCK_HUMIDITY_RANGE = (40, 60)  # percentage
