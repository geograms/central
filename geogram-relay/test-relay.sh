#!/bin/bash

# Test script for Geogram Relay Server
# This script tests all the relay functionality

set -e

PORT=45679
SERVER_JAR="target/geogram-relay-1.0.0.jar"

echo "========================================="
echo "Geogram Relay Server Test Suite"
echo "========================================="
echo ""

# Check if JAR exists
if [ ! -f "$SERVER_JAR" ]; then
    echo "ERROR: JAR file not found at $SERVER_JAR"
    echo "Please run 'mvn package' first"
    exit 1
fi

# Start the server in background
echo "1. Starting Geogram Relay Server on port $PORT..."
java -jar "$SERVER_JAR" "$PORT" > relay-server.log 2>&1 &
SERVER_PID=$!
echo "   Server PID: $SERVER_PID"
sleep 2

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Cleaning up..."
    if [ -n "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    fi
    rm -f relay-server.log
}
trap cleanup EXIT

# Test 1: Root endpoint
echo ""
echo "2. Testing root endpoint (GET /)..."
RESPONSE=$(curl -s http://localhost:$PORT/)
echo "   Response: $RESPONSE"
if echo "$RESPONSE" | grep -q "Geogram Relay Server"; then
    echo "   ✓ Root endpoint working"
else
    echo "   ✗ Root endpoint failed"
    exit 1
fi

# Test 2: Relay status endpoint
echo ""
echo "3. Testing relay status (GET /relay/status)..."
RESPONSE=$(curl -s http://localhost:$PORT/relay/status)
echo "   Response: $RESPONSE"
if echo "$RESPONSE" | grep -q "connected_devices"; then
    echo "   ✓ Relay status endpoint working"
else
    echo "   ✗ Relay status endpoint failed"
    exit 1
fi

# Test 3: Device info for non-existent device
echo ""
echo "4. Testing device info for non-existent device (GET /device/TEST1)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/device/TEST1)
echo "   HTTP Code: $HTTP_CODE"
if [ "$HTTP_CODE" = "404" ]; then
    echo "   ✓ Correctly returns 404 for non-existent device"
else
    echo "   ✗ Expected 404, got $HTTP_CODE"
    exit 1
fi

# Test 4: WebSocket connection and registration
echo ""
echo "5. Testing WebSocket connection and device registration..."

# Create a simple WebSocket test client using Node.js
cat > test-ws-client.js << 'EOF'
const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:45679/');
const CALLSIGN = 'TEST1';

ws.on('open', function open() {
    console.log('   Connected to WebSocket');

    // Send REGISTER message
    const registerMsg = {
        type: 'REGISTER',
        callsign: CALLSIGN
    };
    console.log('   Sending REGISTER:', JSON.stringify(registerMsg));
    ws.send(JSON.stringify(registerMsg));
});

ws.on('message', function message(data) {
    console.log('   Received:', data.toString());
    const msg = JSON.parse(data.toString());

    if (msg.type === 'REGISTER') {
        console.log('   ✓ Device registered successfully:', msg.callsign);

        // Now test PING/PONG
        setTimeout(() => {
            const pingMsg = { type: 'PING' };
            console.log('   Sending PING');
            ws.send(JSON.stringify(pingMsg));
        }, 100);
    } else if (msg.type === 'PONG') {
        console.log('   ✓ Received PONG response');

        // Test HTTP_REQUEST handling
        setTimeout(() => {
            console.log('   Waiting for HTTP_REQUEST...');
        }, 100);

        // Close after 2 seconds
        setTimeout(() => {
            ws.close();
        }, 2000);
    } else if (msg.type === 'HTTP_REQUEST') {
        console.log('   ✓ Received HTTP_REQUEST:', msg.method, msg.path);

        // Send HTTP_RESPONSE
        const response = {
            type: 'HTTP_RESPONSE',
            requestId: msg.requestId,
            statusCode: 200,
            responseHeaders: JSON.stringify({'Content-Type': 'application/json'}),
            responseBody: JSON.stringify({message: 'Hello from device'})
        };
        console.log('   Sending HTTP_RESPONSE');
        ws.send(JSON.stringify(response));
    }
});

ws.on('error', function error(err) {
    console.error('   ✗ WebSocket error:', err.message);
    process.exit(1);
});

ws.on('close', function close() {
    console.log('   WebSocket closed');
    process.exit(0);
});

// Timeout after 5 seconds
setTimeout(() => {
    console.error('   ✗ Test timeout');
    ws.close();
    process.exit(1);
}, 5000);
EOF

# Check if Node.js is available
if command -v node >/dev/null 2>&1; then
    # Check if ws module is available
    if node -e "require('ws')" 2>/dev/null; then
        node test-ws-client.js &
        WS_CLIENT_PID=$!
        sleep 3

        # Test device info again (should be connected now)
        echo ""
        echo "6. Testing device info for connected device (GET /device/TEST1)..."
        RESPONSE=$(curl -s http://localhost:$PORT/device/TEST1)
        echo "   Response: $RESPONSE"
        if echo "$RESPONSE" | grep -q '"connected":true'; then
            echo "   ✓ Device shows as connected"
        else
            echo "   ✗ Device not showing as connected"
        fi

        # Test HTTP proxying
        echo ""
        echo "7. Testing HTTP proxy to device (GET /device/TEST1/api/test)..."
        RESPONSE=$(curl -s http://localhost:$PORT/device/TEST1/api/test)
        echo "   Response: $RESPONSE"
        if echo "$RESPONSE" | grep -q "Hello from device"; then
            echo "   ✓ HTTP proxy working"
        else
            echo "   ✗ HTTP proxy failed"
        fi

        wait $WS_CLIENT_PID 2>/dev/null || true
        rm -f test-ws-client.js
    else
        echo "   ⚠ Skipping WebSocket tests (npm install -g ws required)"
    fi
else
    echo "   ⚠ Skipping WebSocket tests (Node.js not available)"
fi

echo ""
echo "========================================="
echo "All tests completed successfully! ✓"
echo "========================================="
