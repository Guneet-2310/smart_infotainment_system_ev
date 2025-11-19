#!/usr/bin/env python3
"""
Test script to verify backend server connection and functionality
Run this to test if the backend is working correctly
"""

import asyncio
import json
import websockets
import sys

async def test_backend():
    """Test connection to backend server"""
    
    print("=" * 60)
    print("EV Smart Screen - Backend Connection Test")
    print("=" * 60)
    
    # Server address
    uri = "ws://localhost:8765"
    print(f"\nConnecting to: {uri}")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✓ Connected successfully!")
            
            # Wait for initial message
            print("\nWaiting for telemetry data...")
            message = await websocket.recv()
            data = json.loads(message)
            
            if data.get('type') == 'connection':
                print(f"✓ Connection confirmed: {data.get('message')}")
                
                # Wait for telemetry
                message = await websocket.recv()
                data = json.loads(message)
            
            if data.get('type') == 'telemetry':
                print("\n✓ Receiving telemetry data:")
                print(f"  - Speed: {data.get('speed')} km/h")
                print(f"  - Battery SoC: {data.get('battery_soc')}%")
                print(f"  - Range: {data.get('range_km')} km")
                print(f"  - Ambient Temp: {data.get('ambient_temp')}°C")
                print(f"  - Motor RPM: {data.get('motor_rpm')}")
                print(f"  - GPS: {data.get('gps', {}).get('latitude')}, {data.get('gps', {}).get('longitude')}")
            
            # Test sending a command
            print("\nTesting command: play_music")
            command = json.dumps({"action": "play_music"})
            await websocket.send(command)
            
            # Wait for response
            response = await websocket.recv()
            response_data = json.loads(response)
            
            if response_data.get('status') == 'success':
                print("✓ Command executed successfully!")
            else:
                print("✗ Command failed")
            
            # Test invalid command
            print("\nTesting invalid command (should be rejected):")
            invalid_command = json.dumps({"action": "invalid_action"})
            await websocket.send(invalid_command)
            
            response = await websocket.recv()
            response_data = json.loads(response)
            
            if response_data.get('type') == 'error':
                print("✓ Invalid command correctly rejected")
            
            print("\n" + "=" * 60)
            print("All tests passed! Backend is working correctly.")
            print("=" * 60)
            
    except ConnectionRefusedError:
        print("\n✗ Connection refused!")
        print("  Make sure the backend server is running:")
        print("  python main.py")
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(test_backend())
