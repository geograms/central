#!/bin/bash

# Geogram Relay Server Runner
# Builds and runs the relay server

set -e

PORT=${1:-45679}

echo "Geogram Relay Server"
echo "===================="
echo ""

# Check if JAR exists
if [ ! -f "target/geogram-relay-1.0.0.jar" ]; then
    echo "JAR not found. Building..."
    mvn clean package -q
    echo "Build complete!"
    echo ""
fi

echo "Starting Geogram Relay Server on port $PORT..."
echo "Press Ctrl+C to stop"
echo ""

java -jar target/geogram-relay-1.0.0.jar "$PORT"
