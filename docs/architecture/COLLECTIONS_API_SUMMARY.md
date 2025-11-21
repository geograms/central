# Collections API - Remote Browsing and Download Progress

## Summary

Added comprehensive API endpoints for remote control of collection browsing and file downloads between Android devices via Bluetooth/WiFi, plus download progress tracking.

## What Was Added

### 1. Download Progress Tracking (`DownloadProgress.java`)

New utility class that tracks download progress for all file transfers:

**Location:** `geogram-android/app/src/main/java/offgrid/geogram/util/DownloadProgress.java`

**Features:**
- Tracks download progress (bytes downloaded, percentage, speed)
- Calculates estimated time remaining
- Thread-safe (uses ConcurrentHashMap)
- Stores status for each download by fileId

**Status Information:**
- `fileId`: Unique identifier for the download
- `fileName`: Name of the file being downloaded
- `totalBytes`: Total file size
- `downloadedBytes`: Bytes downloaded so far
- `percentComplete`: Download percentage (0-100)
- `completed`: Whether download finished successfully
- `failed`: Whether download failed
- `errorMessage`: Error details if failed
- `bytesPerSecond`: Current download speed
- Formatted strings for progress display

### 2. New API Endpoints

All endpoints added to `SimpleSparkServer.java` on port **45678**.

#### Download Progress Endpoints

**GET /api/downloads**
- Lists all active/recent downloads
- Returns array with progress for each download
- Response includes: fileId, fileName, percentComplete, speed, etc.

**GET /api/downloads/:fileId**
- Get progress for a specific download
- fileId should be URL-encoded (format: `collectionId/filePath`)
- Returns detailed status including speed and ETA

#### Remote Control Endpoints

These endpoints allow you to control Tank2 from your computer to interact with other phones via Bluetooth:

**POST /api/remote/list-collections**
- Tell Tank2 to list collections on another device
- Body: `{"deviceId": "X15RJ0"}` or `{"deviceId": "X15RJ0", "remoteIp": "192.168.178.29"}`
- Response: Array of collections on the remote device
- Uses P2PHttpClient to route through WiFi/BLE/Relay as needed

**POST /api/remote/list-files**
- Tell Tank2 to list files in a remote collection
- Body: `{"deviceId": "X15RJ0", "collectionId": "npub1...", "path": ""}`
- Response: Array of files/folders in the collection
- Optional `path` parameter to browse subdirectories

**POST /api/remote/download-file**
- Tell Tank2 to download a file from a remote device
- Body: `{"deviceId": "X15RJ0", "collectionId": "npub1...", "filePath": "photo.jpg", "fileSize": 229061}`
- Starts download in background
- Returns immediately with HTTP 202 Accepted and a fileId
- Use /api/downloads/:fileId to monitor progress

### 3. Updated CollectionBrowserFragment

**Location:** `geogram-android/app/src/main/java/offgrid/geogram/fragments/CollectionBrowserFragment.java`

**Changes:**
- Integrated DownloadProgress tracking when downloading remote files
- Updates progress every 8KB chunk
- Logs progress every 100KB for debugging
- Marks downloads as completed or failed appropriately

## Usage Example

### Automated Testing from Computer

```bash
#!/bin/bash
TANK2="192.168.178.28:45678"

# 1. Check what devices Tank2 can see
curl http://$TANK2/api/devices/nearby

# 2. Tell Tank2 to list collections on device X15RJ0
curl -X POST http://$TANK2/api/remote/list-collections \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"X15RJ0"}'

# 3. Tell Tank2 to list files in a collection
curl -X POST http://$TANK2/api/remote/list-files \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"X15RJ0","collectionId":"npub1..."}'

# 4. Tell Tank2 to download a file
curl -X POST http://$TANK2/api/remote/download-file \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId":"X15RJ0",
    "collectionId":"npub1...",
    "filePath":"photo.jpg",
    "fileSize":229061
  }'

# Response: {"success":true,"fileId":"npub1.../photo.jpg"}

# 5. Monitor download progress
FILE_ID="npub1.../photo.jpg"  # URL encode this
curl http://$TANK2/api/downloads/$FILE_ID

# Response includes:
# {
#   "success": true,
#   "download": {
#     "percentComplete": 45,
#     "speed": "125.3 KB/s",
#     "progress": "102 KB / 223 KB",
#     "estimatedTimeRemainingMs": 968,
#     "completed": false
#   }
# }
```

### Polling for Download Progress

```bash
# Poll every 2 seconds until complete
while true; do
  STATUS=$(curl -s http://$TANK2/api/downloads/$FILE_ID | jq -r '.download.percentComplete')
  echo "Progress: $STATUS%"

  if [ "$STATUS" = "100" ]; then
    echo "Download complete!"
    break
  fi

  sleep 2
done
```

## Testing

A comprehensive test script has been created: `test-collections-api.sh`

Run it with:
```bash
./test-collections-api.sh
```

The script will:
1. Test if Tank2 is online
2. List collections on Tank2
3. List nearby devices Tank2 can see
4. Prompt for a remote device ID
5. List collections on the remote device
6. List files in a remote collection
7. Trigger a download
8. Monitor download progress until complete

## Device Communication Flow

```
Your Computer (WiFi) ←HTTP→ Tank2 (WiFi + BLE) ←BLE→ Other Phone (BLE)
                              ↓
                        P2PHttpClient decides:
                        - WiFi if both on same network
                        - Relay if available
                        - BLE GATT for Bluetooth
```

When you call `/api/remote/list-collections` on Tank2:
1. Tank2's SimpleSparkServer receives the HTTP request from your computer
2. Server creates a P2PHttpClient
3. P2PHttpClient checks connectivity and chooses best route (WiFi/Relay/BLE)
4. Request is sent to the other phone via chosen transport
5. Other phone's SimpleSparkServer responds with its collections
6. Response is relayed back through P2PHttpClient
7. Tank2 returns response to your computer

## File Download with Progress

When you call `/api/remote/download-file`:
1. Tank2 starts the download in a background thread
2. Returns immediately (HTTP 202) with a fileId
3. Download happens chunk-by-chunk (8KB buffers)
4. Progress is updated after each chunk
5. Status is stored in DownloadProgress singleton
6. You can poll `/api/downloads/:fileId` to see progress
7. When complete, `completed: true` is set

## Next Steps

1. Build the APK with the new code
2. Install on Tank2
3. Connect another Android phone via Bluetooth to Tank2
4. Run `test-collections-api.sh` to verify all endpoints work
5. Test file downloads and monitor progress

## Notes

- The existing `/api/collections/*` endpoints remain unchanged
- All remote control is via new `/api/remote/*` endpoints
- Download tracking works for both UI-initiated and API-initiated downloads
- Progress tracking is thread-safe and works across multiple concurrent downloads
- Tank2 must be on WiFi (192.168.178.28:45678) for HTTP API access from computer
- Other phone can be Bluetooth-only (will use BLE GATT for communication)
