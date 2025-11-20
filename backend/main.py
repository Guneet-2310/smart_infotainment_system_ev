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
import parking_module

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


## Removed standalone DHT11Sensor class.
## Rationale: We now use the unified DHT access inside parking_module.ParkingAndCabinModule
## to avoid double reads and checksum/buffer errors caused by over-sampling.


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
        try:
            # When CAN bus is available, implement real CAN message parsing here
            return self._generate_mock_vehicle_data()
        except Exception as e:
            logger.error(f"⚠ CAN bus read error: {e}")
            return {
                'speed': 0.0,
                'battery_soc': 0.0,
                'battery_voltage': 0.0,
                'battery_current': 0.0,
                'motor_rpm': 0,
                'motor_temp': 0.0,
                'range_km': 0.0,
                'power_kw': 0.0,
            }
    
    def _generate_mock_vehicle_data(self) -> Dict[str, Any]:
        """Generate realistic mock vehicle data"""
        try:
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
        except Exception as e:
            logger.error(f"⚠ Mock vehicle data generation error: {e}")
            return {
                'speed': 0.0,
                'battery_soc': 0.0,
                'battery_voltage': 0.0,
                'battery_current': 0.0,
                'motor_rpm': 0,
                'motor_temp': 0.0,
                'range_km': 0.0,
                'power_kw': 0.0,
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
        try:
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
        except Exception as e:
            logger.error(f"⚠ GPS module error: {e}")
            return {
                'latitude': self.base_lat,
                'longitude': self.base_lon,
                'heading': 0.0,
                'altitude': 240.0,
                'satellites': 0,
                'speed_gps': 0.0
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
        try:
            logger.info(f"Attempting to connect to Bluetooth device: {device_address}")
            # Actual Bluetooth connection logic here
            self.connected = True
            self.device_name = "Mock Phone"
            return True
        except Exception as e:
            logger.error(f"⚠ Bluetooth connection error: {e}")
            return False
    
    def play(self):
        """Play media"""
        try:
            logger.info("Media command: PLAY")
            self.current_track['is_playing'] = True
        except Exception as e:
            logger.error(f"⚠ Bluetooth play error: {e}")
    
    def pause(self):
        """Pause media"""
        try:
            logger.info("Media command: PAUSE")
            self.current_track['is_playing'] = False
        except Exception as e:
            logger.error(f"⚠ Bluetooth pause error: {e}")
    
    def next_track(self):
        """Skip to next track"""
        try:
            logger.info("Media command: NEXT")
            self.current_track['position'] = 0
            self.current_track['title'] = f"Track {random.randint(1, 100)}"
        except Exception as e:
            logger.error(f"⚠ Bluetooth next track error: {e}")
    
    def previous_track(self):
        """Go to previous track"""
        try:
            logger.info("Media command: PREVIOUS")
            self.current_track['position'] = 0
            self.current_track['title'] = f"Track {random.randint(1, 100)}"
        except Exception as e:
            logger.error(f"⚠ Bluetooth previous track error: {e}")
    
    def set_volume(self, volume: float):
        """Set volume (0.0 to 1.0)"""
        try:
            logger.info(f"Media command: SET_VOLUME to {volume}")
        except Exception as e:
            logger.error(f"⚠ Bluetooth volume error: {e}")
    
    def get_status(self) -> Dict[str, Any]:
        """Get current media status"""
        try:
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
        except Exception as e:
            logger.error(f"⚠ Bluetooth get status error: {e}")
            return {
                'connected': False,
                'device_name': 'Error',
                'track_title': 'No Track Playing',
                'track_artist': 'Unknown Artist',
                'duration': 0,
                'position': 0,
                'is_playing': False
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
            
        except ConnectionRefusedError as e:
            logger.error(f"⚠ MQTT broker connection refused: {e}")
            return False
        except TimeoutError as e:
            logger.error(f"⚠ MQTT broker connection timeout: {e}")
            return False
        except Exception as e:
            logger.error(f"⚠ Failed to connect to MQTT broker: {e}")
            return False
    
    def _on_connect(self, client, userdata, flags, rc):
        """Callback when connected to MQTT broker"""
        try:
            if rc == 0:
                self.connected = True
                logger.info("✓ Connected to MQTT broker successfully")
                # Subscribe to command topics
                client.subscribe("ev/commands/#")
            else:
                logger.error(f"⚠ Failed to connect to MQTT broker. Return code: {rc}")
        except Exception as e:
            logger.error(f"⚠ MQTT on_connect callback error: {e}")
    
    def _on_disconnect(self, client, userdata, rc):
        """Callback when disconnected from MQTT broker"""
        try:
            self.connected = False
            logger.warning(f"⚠ Disconnected from MQTT broker. Return code: {rc}")
        except Exception as e:
            logger.error(f"⚠ MQTT on_disconnect callback error: {e}")
    
    def _on_message(self, client, userdata, msg):
        """Callback when message received from MQTT broker"""
        try:
            logger.info(f"MQTT message received: {msg.topic} - {msg.payload.decode()}")
        except Exception as e:
            logger.error(f"⚠ MQTT on_message callback error: {e}")
    
    def publish_telemetry(self, data: Dict[str, Any]):
        """Publish telemetry data to cloud"""
        if self.client and self.connected:
            try:
                payload = json.dumps(data)
                self.client.publish("ev/telemetry", payload, qos=1)
            except TypeError as e:
                logger.error(f"⚠ MQTT publish serialization error: {e}")
            except ConnectionError as e:
                logger.error(f"⚠ MQTT publish connection error: {e}")
                self.connected = False
            except Exception as e:
                logger.warning(f"⚠ Failed to publish telemetry: {e}")
    
    def disconnect(self):
        """Disconnect from MQTT broker"""
        try:
            if self.client:
                self.client.loop_stop()
                self.client.disconnect()
                logger.info("✓ Disconnected from MQTT broker")
        except Exception as e:
            logger.error(f"⚠ MQTT disconnect error: {e}")


# ============================================================================
# MAIN BACKEND SERVER
# ============================================================================

class EVBackendServer:
    """Main EV Infotainment Backend Server"""
    
    def __init__(self):
        # Hardware interfaces (DHT handled inside parking_module to prevent duplicate sampling)
        self.can_bus = CANBusInterface()
        self.gps = GPSModule()
        self.bluetooth = BluetoothMediaController()
        self.mqtt = MQTTCloudClient()
        # Parking & cabin module (ultrasonic, motion, reverse, temp/humidity)
        self.parking_module = parking_module.ParkingAndCabinModule()
        
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
            'toggle_predictions', 'set_twin_mode', 'connect_bluetooth',
            'update_gps'  # Client GPS coordinate upload
        }
        
        logger.info("EV Backend Server initialized")
    
    async def start(self, host: str = '0.0.0.0', port: int = 8765):
        """Start the WebSocket server"""
        try:
            self.running = True
            
            # Start MQTT connection (optional)
            # self.mqtt.connect('broker.example.com', 1883, use_tls=False)
            
            logger.info(f"WebSocket server starting on ws://{host}:{port}")
            
            async with websockets.serve(self.handle_client, host, port):
                logger.info(f"✓ WebSocket server started on ws://{host}:{port}")
                
                # Start telemetry broadcast task
                telemetry_task = asyncio.create_task(self.broadcast_telemetry())
                
                # Keep server running
                try:
                    await asyncio.Future()  # Run forever
                except KeyboardInterrupt:
                    logger.info("✓ Server shutdown requested")
                finally:
                    self.running = False
                    telemetry_task.cancel()
                    self.mqtt.disconnect()
        except OSError as e:
            logger.error(f"⚠ WebSocket server failed to start (port may be in use): {e}")
            raise
        except Exception as e:
            logger.error(f"⚠ WebSocket server startup error: {e}")
            raise
    
    async def handle_client(self, websocket):
        """Handle new WebSocket client connection"""
        client_addr = None
        try:
            self.clients.add(websocket)
            client_addr = websocket.remote_address
            logger.info(f"✓ Flutter client connected: {client_addr}")
            
            # Send initial connection confirmation
            await websocket.send(json.dumps({
                'type': 'connection',
                'status': 'connected',
                'message': 'Connected to EV Backend Server'
            }))
            
            # Listen for commands from client
            async for message in websocket:
                await self.handle_command(websocket, message)
                
        except websockets.exceptions.ConnectionClosedOK:
            logger.info(f"✓ Flutter client disconnected normally: {client_addr}")
        except websockets.exceptions.ConnectionClosedError as e:
            logger.warning(f"⚠ Flutter client connection error: {client_addr} - {e}")
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"Flutter client disconnected: {client_addr}")
        except Exception as e:
            logger.error(f"⚠ Error handling client {client_addr}: {e}")
        finally:
            self.clients.discard(websocket)
    
    async def handle_command(self, websocket, message: str):
        """Handle incoming command from Flutter client"""
        try:
            data = json.loads(message)
            action = data.get('action')
            
            # Input sanitization - validate action
            if not action or action not in self.VALID_COMMANDS:
                logger.warning(f"⚠ Invalid or unknown action received: {action}")
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
            
        except json.JSONDecodeError as e:
            logger.error(f"⚠ Received invalid JSON from client: {e}")
            try:
                await websocket.send(json.dumps({
                    'type': 'error',
                    'message': 'Invalid JSON format'
                }))
            except:
                pass  # Client may be disconnected
        except websockets.exceptions.ConnectionClosed:
            logger.warning("⚠ Client disconnected during command handling")
        except Exception as e:
            logger.error(f"⚠ Error handling command: {e}")
            try:
                await websocket.send(json.dumps({
                    'type': 'error',
                    'message': str(e)
                }))
            except:
                pass  # Client may be disconnected
    
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
        
        # GPS coordinate from client (override backend GPS with client's real position)
        elif action == 'update_gps':
            lat = data.get('latitude')
            lon = data.get('longitude')
            source = data.get('source', 'unknown')
            if lat is not None and lon is not None:
                logger.info(f"Client GPS update: ({lat:.6f}, {lon:.6f}) from {source}")
                # Override backend GPS with client's more accurate position
                self.gps.current_lat = lat
                self.gps.current_lon = lon
                # Mark that we're using client GPS
                if not hasattr(self, '_using_client_gps'):
                    self._using_client_gps = True
                    logger.info("Switched to using client GPS coordinates")
            return {'type': 'response', 'action': action, 'status': 'success'}
        
        else:
            return {'type': 'response', 'action': action, 'status': 'unknown'}
    
    async def broadcast_telemetry(self):
        """Broadcast telemetry data to all connected clients"""
        logger.info("✓ Telemetry broadcast task started")
        
        while self.running:
            try:
                # Gather all telemetry data
                telemetry = self.collect_telemetry()
                
                # Broadcast to all connected clients
                if self.clients:
                    try:
                        message = json.dumps(telemetry)
                        results = await asyncio.gather(
                            *[client.send(message) for client in self.clients],
                            return_exceptions=True
                        )
                        # Remove failed clients
                        for i, result in enumerate(results):
                            if isinstance(result, Exception):
                                logger.warning(f"⚠ Failed to send to client: {result}")
                    except TypeError as e:
                        logger.error(f"⚠ Telemetry serialization error: {e}")
                    except Exception as e:
                        logger.error(f"⚠ Error broadcasting to clients: {e}")
                
                # Publish to MQTT cloud (if connected)
                try:
                    if self.mqtt.connected:
                        self.mqtt.publish_telemetry(telemetry)
                except Exception as e:
                    logger.warning(f"⚠ Error publishing to MQTT: {e}")
                
                # Wait 1 second before next broadcast
                await asyncio.sleep(1.0)
            except asyncio.CancelledError:
                logger.info("✓ Telemetry broadcast task cancelled")
                break
            except Exception as e:
                logger.error(f"⚠ Critical error in telemetry broadcast loop: {e}")
                await asyncio.sleep(1.0)  # Continue despite errors
    
    def collect_telemetry(self) -> Dict[str, Any]:
        """Collect all telemetry data from sensors and systems"""
        try:
            # Read parking module (includes DHT11 temp/humidity)
            try:
                parking_data = self.parking_module.read()
                dht_data = {
                    'temperature': parking_data.get('temperature_c'),
                    'humidity': parking_data.get('humidity_pct')
                }
            except Exception as e:
                logger.error(f"⚠ Error reading parking module: {e}")
                dht_data = {'temperature': None, 'humidity': None}
                parking_data = {
                    'reverse_engaged': False,
                    'motion_detected': False,
                    'distance_cm': None,
                    'proximity_warning': None,
                    'temperature_c': None,
                    'humidity_pct': None,
                }
            
            # Read vehicle data from CAN bus (currently mock)
            try:
                vehicle_data = self.can_bus.read_vehicle_data()
            except Exception as e:
                logger.error(f"⚠ Error reading CAN bus: {e}")
                vehicle_data = {
                    'speed': 0.0, 'battery_soc': 0.0, 'battery_voltage': 0.0,
                    'battery_current': 0.0, 'motor_rpm': 0, 'motor_temp': 0.0,
                    'range_km': 0.0, 'power_kw': 0.0
                }
            
            # Read GPS data
            try:
                gps_data = self.gps.read()
            except Exception as e:
                logger.error(f"⚠ Error reading GPS: {e}")
                gps_data = {
                    'latitude': 28.4595, 'longitude': 77.0266, 'heading': 0.0,
                    'altitude': 240.0, 'satellites': 0, 'speed_gps': 0.0
                }
            
            # Get Bluetooth media status
            try:
                media_status = self.bluetooth.get_status()
            except Exception as e:
                logger.error(f"⚠ Error reading Bluetooth status: {e}")
                media_status = {
                    'connected': False, 'device_name': 'Error',
                    'track_title': 'No Track Playing', 'track_artist': 'Unknown Artist',
                    'duration': 0, 'position': 0, 'is_playing': False
                }

            # Derive cabin environment from parking module (temperature/humidity)
            # Note: parking_data already read at the beginning of this function
            cabin_temp = parking_data.get('temperature_c')
            cabin_humidity = parking_data.get('humidity_pct')

            # Compile complete telemetry packet
            telemetry = {
                'type': 'telemetry',
                'timestamp': datetime.now().isoformat(),
            
            # Environmental sensors sourced from parking module unified DHT (cached)
            'ambient_temp': cabin_temp,
            'humidity': cabin_humidity,
            'cabin': {
                'temperature_c': cabin_temp if cabin_temp is not None else (dht_data['temperature'] - 2 if dht_data['temperature'] else None),
                'humidity_pct': cabin_humidity if cabin_humidity is not None else dht_data['humidity'],
            },
            
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
                'heading': gps_data.get('heading'),
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

            # Parking & reverse assist
            'parking': {
                'reverse_engaged': parking_data['reverse_engaged'],
                'motion_detected': parking_data['motion_detected'],
                'distance_cm': parking_data['distance_cm'],
                'proximity_warning': parking_data['proximity_warning'],
            },
            
                # Settings
                'settings': self.settings
            }
            
            return telemetry
        
        except Exception as e:
            logger.error(f"⚠ Critical error collecting telemetry: {e}")
            # Return minimal safe telemetry
            return {
                'type': 'telemetry',
                'timestamp': datetime.now().isoformat(),
                'ambient_temp': None,
                'humidity': None,
                'cabin': {'temperature_c': None, 'humidity_pct': None},
                'speed': 0.0,
                'range_km': 0.0,
                'battery_soc': 0.0,
                'battery_voltage': 0.0,
                'battery_current': 0.0,
                'battery_soh': 0.0,
                'motor_rpm': 0,
                'motor_temp': 0.0,
                'power_kw': 0.0,
                'efficiency_score': 0.0,
                'wheel_speed': 0.0,
                'gps': {'latitude': 28.4595, 'longitude': 77.0266, 'altitude': 240.0, 'heading': 0.0, 'satellites': 0, 'speed_gps': 0.0},
                'tire_pressure': {'front_left': 0, 'front_right': 0, 'rear_left': 0, 'rear_right': 0},
                'battery_cells': {'block_a': 0, 'block_b': 0, 'block_c': 0},
                'connectivity': {'wifi': False, 'bluetooth': False, 'can_bus': False},
                'media': {'connected': False, 'device_name': 'Error', 'track_title': 'No Track Playing', 'track_artist': 'Unknown Artist', 'duration': 0, 'position': 0, 'is_playing': False},
                'parking': {'reverse_engaged': False, 'motion_detected': False, 'distance_cm': None, 'proximity_warning': None},
                'settings': self.settings
            }


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

async def main():
    """Main entry point"""
    try:
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
        
    except KeyboardInterrupt:
        logger.info("\n✓ Server stopped by user")
    except OSError as e:
        logger.error(f"\n⚠ Server failed to start (port may be in use): {e}")
        logger.error("→ Try closing other instances or using a different port")
    except Exception as e:
        logger.error(f"\n⚠ Fatal error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
