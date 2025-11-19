#!/usr/bin/env python3
"""
WebSocket test client for Geogram Relay Server
Tests device registration, ping/pong, and HTTP proxying
"""

import asyncio
import websockets
import json
import sys
import requests
import time

async def test_relay_websocket():
    uri = "ws://localhost:45679/"
    callsign = "TEST1"

    print("Connecting to relay server...")
    async with websockets.connect(uri) as websocket:
        print("✓ Connected to WebSocket")

        # Test 1: Register device
        print("\n1. Testing device registration...")
        register_msg = {
            "type": "REGISTER",
            "callsign": callsign
        }
        await websocket.send(json.dumps(register_msg))
        print(f"   Sent REGISTER: {callsign}")

        response = await websocket.recv()
        msg = json.loads(response)
        print(f"   Received: {response}")

        if msg.get("type") == "REGISTER" and msg.get("callsign") == callsign.upper():
            print("   ✓ Device registered successfully")
        else:
            print("   ✗ Registration failed")
            return False

        # Test 2: PING/PONG
        print("\n2. Testing PING/PONG...")
        ping_msg = {"type": "PING"}
        await websocket.send(json.dumps(ping_msg))
        print("   Sent PING")

        response = await websocket.recv()
        msg = json.loads(response)
        print(f"   Received: {response}")

        if msg.get("type") == "PONG":
            print("   ✓ PONG received")
        else:
            print("   ✗ Expected PONG")
            return False

        # Test 3: Wait for HTTP_REQUEST
        print("\n3. Testing HTTP proxying...")
        print("   Device ready to receive HTTP requests")

        # Create a background task to handle HTTP requests
        async def handle_requests():
            while True:
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                    msg = json.loads(response)

                    if msg.get("type") == "HTTP_REQUEST":
                        print(f"   ✓ Received HTTP_REQUEST: {msg.get('method')} {msg.get('path')}")

                        # Send HTTP_RESPONSE
                        response_msg = {
                            "type": "HTTP_RESPONSE",
                            "requestId": msg.get("requestId"),
                            "statusCode": 200,
                            "responseHeaders": json.dumps({"Content-Type": "application/json"}),
                            "responseBody": json.dumps({"message": "Hello from Python device", "path": msg.get("path")})
                        }
                        await websocket.send(json.dumps(response_msg))
                        print("   ✓ Sent HTTP_RESPONSE")
                        break
                except asyncio.TimeoutError:
                    print("   ⚠ Timeout waiting for HTTP_REQUEST")
                    break

        # Run request handler in background
        handler_task = asyncio.create_task(handle_requests())

        # Give the server time to register the device
        await asyncio.sleep(0.5)

        # Make an HTTP request through the relay
        print("\n4. Making HTTP request through relay...")
        try:
            http_response = requests.get(f"http://localhost:45679/device/{callsign}/api/test", timeout=5)
            print(f"   HTTP Status: {http_response.status_code}")
            print(f"   HTTP Response: {http_response.text}")

            if http_response.status_code == 200:
                data = http_response.json()
                if data.get("message") == "Hello from Python device":
                    print("   ✓ HTTP proxy working correctly")
                else:
                    print("   ✗ Unexpected response content")
                    return False
            else:
                print("   ✗ HTTP request failed")
                return False
        except Exception as e:
            print(f"   ✗ HTTP request error: {e}")
            return False

        # Wait for handler to complete
        await handler_task

        print("\n✓ All WebSocket tests passed!")
        return True

def main():
    print("=========================================")
    print("Geogram Relay WebSocket Test")
    print("=========================================\n")

    # Check if server is running
    try:
        response = requests.get("http://localhost:45679/", timeout=2)
        if response.status_code == 200:
            print("✓ Relay server is running\n")
        else:
            print("✗ Relay server returned unexpected status")
            sys.exit(1)
    except requests.exceptions.RequestException:
        print("✗ Relay server is not running on port 45679")
        print("  Please start the server first: java -jar target/geogram-relay-1.0.0.jar")
        sys.exit(1)

    # Run WebSocket tests
    try:
        result = asyncio.run(test_relay_websocket())
        if result:
            print("\n=========================================")
            print("All tests completed successfully! ✓")
            print("=========================================")
            sys.exit(0)
        else:
            print("\n✗ Some tests failed")
            sys.exit(1)
    except Exception as e:
        print(f"\n✗ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
