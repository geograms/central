#!/bin/bash
# Test www collection hosting feature

RELAY_URL="http://localhost:8080"
CALLSIGN=${1:-X114CC}

echo "================================"
echo "Testing www collection hosting"
echo "================================"
echo ""

# Test 1: Check relay status
echo "1. Checking relay status..."
echo "GET $RELAY_URL/relay/status"
echo "---"
curl -s "$RELAY_URL/relay/status" | python3 -m json.tool 2>/dev/null || echo "Failed to get relay status"
echo ""
echo ""

# Test 2: Check device info
echo "2. Checking device $CALLSIGN info..."
echo "GET $RELAY_URL/device/$CALLSIGN"
echo "---"
curl -s "$RELAY_URL/device/$CALLSIGN" | python3 -m json.tool 2>/dev/null || echo "Failed to get device info"
echo ""
echo ""

# Test 3: Try to access www collection
echo "3. Accessing www collection..."
echo "GET $RELAY_URL/$CALLSIGN"
echo "---"
response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$RELAY_URL/$CALLSIGN")
http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d: -f2)
body=$(echo "$response" | sed '/HTTP_CODE/d')

echo "HTTP Status: $http_code"
echo "Response:"
echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
echo ""
echo ""

# Test 4: Check logs
echo "4. Recent relay logs (last 20 lines):"
echo "---"
if [ -f "logs/geogram-relay.log" ]; then
    tail -20 logs/geogram-relay.log
else
    echo "Log file not found at logs/geogram-relay.log"
fi
echo ""
echo ""

echo "================================"
echo "Test complete"
echo "================================"
