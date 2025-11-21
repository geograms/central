#!/bin/bash

# Test script for Collections API with remote device control
# This script tests the new API endpoints on Tank2 (192.168.178.28)

TANK2_IP="192.168.178.28"
TANK2_PORT="45678"
BASE_URL="http://${TANK2_IP}:${TANK2_PORT}"

echo "======================================"
echo "Collections API Test Script"
echo "Testing Tank2 at $BASE_URL"
echo "======================================"
echo

# Helper function to make requests with nice formatting
function api_call() {
    local METHOD=$1
    local ENDPOINT=$2
    local DATA=$3
    local DESCRIPTION=$4

    echo "[$METHOD] $ENDPOINT"
    echo "Description: $DESCRIPTION"
    echo "---"

    if [ "$METHOD" = "GET" ]; then
        curl -s "$BASE_URL$ENDPOINT" | jq '.' || echo "Failed to parse JSON"
    else
        curl -s -X "$METHOD" -H "Content-Type: application/json" -d "$DATA" "$BASE_URL$ENDPOINT" | jq '.' || echo "Failed to parse JSON"
    fi

    echo
    echo "======================================"
    echo
}

# Test 1: Check if Tank2 is online
echo "Test 1: Ping Tank2"
api_call "GET" "/api/ping" "" "Check if Tank2 is responding"

# Test 2: Get Tank2's collections (local collections on Tank2)
echo "Test 2: List local collections on Tank2"
api_call "GET" "/api/collections" "" "Get all collections stored on Tank2"

# Test 3: Get nearby devices detected by Tank2
echo "Test 3: List nearby devices detected by Tank2"
api_call "GET" "/api/devices/nearby?limit=10" "" "Get devices spotted via BLE by Tank2"

# For the following tests, you need to know the device ID of another phone
# If you have another phone connected, replace DEVICE_ID below

echo "======================================"
echo "Remote Control Tests"
echo "======================================"
echo
echo "For the following tests, you need:"
echo "1. Another Android phone connected to Tank2 via Bluetooth"
echo "2. The device ID or IP of that phone"
echo
echo "Example device IDs you might use:"
echo "  - Callsign like 'X1SQYS' (if connected via BLE)"
echo "  - IP address like '192.168.178.29' (if on WiFi)"
echo
read -p "Enter device ID of the remote phone (or press Enter to skip): " DEVICE_ID

if [ -z "$DEVICE_ID" ]; then
    echo "Skipping remote control tests"
    echo
    echo "======================================"
    echo "Download Progress Tests"
    echo "======================================"
else
    echo

    # Test 4: List collections on the remote device
    echo "Test 4: List collections on remote device $DEVICE_ID"
    REMOTE_IP=""
    if [[ $DEVICE_ID =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        REMOTE_IP="$DEVICE_ID"
    fi

    if [ -n "$REMOTE_IP" ]; then
        DATA="{\"deviceId\":\"$DEVICE_ID\",\"remoteIp\":\"$REMOTE_IP\"}"
    else
        DATA="{\"deviceId\":\"$DEVICE_ID\"}"
    fi

    COLLECTIONS_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$DATA" "$BASE_URL/api/remote/list-collections")
    echo "$COLLECTIONS_RESPONSE" | jq '.'

    # Extract first collection ID for next test
    COLLECTION_ID=$(echo "$COLLECTIONS_RESPONSE" | jq -r '.collections[0].id // empty')

    echo
    echo "======================================"
    echo

    if [ -n "$COLLECTION_ID" ]; then
        # Test 5: List files in the remote collection
        echo "Test 5: List files in collection $COLLECTION_ID on remote device"
        if [ -n "$REMOTE_IP" ]; then
            DATA="{\"deviceId\":\"$DEVICE_ID\",\"remoteIp\":\"$REMOTE_IP\",\"collectionId\":\"$COLLECTION_ID\"}"
        else
            DATA="{\"deviceId\":\"$DEVICE_ID\",\"collectionId\":\"$COLLECTION_ID\"}"
        fi

        FILES_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$DATA" "$BASE_URL/api/remote/list-files")
        echo "$FILES_RESPONSE" | jq '.'

        # Extract first file path
        FILE_PATH=$(echo "$FILES_RESPONSE" | jq -r '.files[] | select(.type=="file") | .path' | head -1)
        FILE_SIZE=$(echo "$FILES_RESPONSE" | jq -r '.files[] | select(.type=="file") | .size' | head -1)

        echo
        echo "======================================"
        echo

        if [ -n "$FILE_PATH" ]; then
            # Test 6: Trigger download of the file
            echo "Test 6: Download file $FILE_PATH from remote collection"
            if [ -n "$REMOTE_IP" ]; then
                DATA="{\"deviceId\":\"$DEVICE_ID\",\"remoteIp\":\"$REMOTE_IP\",\"collectionId\":\"$COLLECTION_ID\",\"filePath\":\"$FILE_PATH\",\"fileSize\":$FILE_SIZE}"
            else
                DATA="{\"deviceId\":\"$DEVICE_ID\",\"collectionId\":\"$COLLECTION_ID\",\"filePath\":\"$FILE_PATH\",\"fileSize\":$FILE_SIZE}"
            fi

            DOWNLOAD_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$DATA" "$BASE_URL/api/remote/download-file")
            echo "$DOWNLOAD_RESPONSE" | jq '.'

            FILE_ID=$(echo "$DOWNLOAD_RESPONSE" | jq -r '.fileId // empty')

            echo
            echo "======================================"
            echo

            if [ -n "$FILE_ID" ]; then
                # Test 7: Monitor download progress
                echo "Test 7: Monitor download progress"
                echo "Polling download status every 2 seconds for 30 seconds..."
                echo

                for i in {1..15}; do
                    ENCODED_FILE_ID=$(echo -n "$FILE_ID" | jq -sRr @uri)
                    PROGRESS=$(curl -s "$BASE_URL/api/downloads/$ENCODED_FILE_ID")

                    STATUS=$(echo "$PROGRESS" | jq -r '.download.percentComplete // 0')
                    COMPLETED=$(echo "$PROGRESS" | jq -r '.download.completed // false')
                    FAILED=$(echo "$PROGRESS" | jq -r '.download.failed // false')
                    SPEED=$(echo "$PROGRESS" | jq -r '.download.speed // "N/A"')
                    PROGRESS_TEXT=$(echo "$PROGRESS" | jq -r '.download.progress // "N/A"')

                    echo "[$i] Progress: $STATUS% ($PROGRESS_TEXT) @ $SPEED"

                    if [ "$COMPLETED" = "true" ]; then
                        echo "✓ Download completed!"
                        break
                    fi

                    if [ "$FAILED" = "true" ]; then
                        ERROR=$(echo "$PROGRESS" | jq -r '.download.errorMessage // "Unknown error"')
                        echo "✗ Download failed: $ERROR"
                        break
                    fi

                    sleep 2
                done

                echo
                echo "======================================"
                echo
            fi
        else
            echo "No files found in the collection"
            echo
            echo "======================================"
            echo
        fi
    else
        echo "No collections found on remote device"
        echo
        echo "======================================"
        echo
    fi
fi

# Test 8: Check all active downloads
echo "Test 8: List all active downloads on Tank2"
api_call "GET" "/api/downloads" "" "Get status of all downloads"

echo "======================================"
echo "Tests completed!"
echo "======================================"
