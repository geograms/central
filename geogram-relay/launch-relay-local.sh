#!/bin/bash

# Launch local Geogram relay for testing
# This script starts the relay on localhost:8080

cd "$(dirname "$0")"

echo "=================================================="
echo "  Geogram Relay - Local Development Server"
echo "=================================================="
echo ""
echo "Starting relay on ws://localhost:8080"
echo "Press Ctrl+C to stop"
echo ""

# Build if needed
if [ ! -f "target/geogram-relay-1.0.0.jar" ]; then
    echo "Building relay..."
    mvn clean package -q
    if [ $? -ne 0 ]; then
        echo "Build failed!"
        exit 1
    fi
    echo "Build complete!"
    echo ""
fi

# Start relay
java -jar target/geogram-relay-1.0.0.jar
