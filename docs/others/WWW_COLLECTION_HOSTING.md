# WWW Collection Hosting via Relay

## Overview

The geogram-relay now supports hosting static websites from device's www collections via direct callsign URLs.

## How It Works

1. Device (e.g., X114CC) connects to relay via WebSocket
2. Device has a "www" type collection with HTML/CSS/JS files
3. Users can access `http://relay-ip:8080/X114CC` to view the website
4. Relay bridges HTTP requests to WebSocket and back

## Setup Instructions

### 1. Start the Relay

```bash
cd /home/brito/code/geogram/geogram-relay

# Rebuild after code changes
mvn clean package

# Start the relay
./run-relay.sh
# Or for local testing:
./launch-relay-local.sh
```

### 2. Connect a Device

The device must connect via WebSocket and register with the relay. The geogram-desktop app should do this automatically when you configure a relay.

**Check device is connected:**
```bash
curl http://localhost:8080/relay/status | jq
```

Expected output:
```json
{
  "connected_devices": 1,
  "devices": [
    {
      "callsign": "X114CC",
      "uptime_seconds": 123,
      "idle_seconds": 5,
      "connected_at": "2025-11-20T12:34:56Z"
    }
  ]
}
```

### 3. Create a WWW Collection on the Device

Using geogram-desktop:
1. Go to Collections tab
2. Click "Create"
3. Select type "Website" (www)
4. Add your HTML files to the www collection
5. Make sure there's an `index.html` file

### 4. Access the Website

```bash
# Access the device's website
curl http://localhost:8080/X114CC

# Or open in browser
firefox http://localhost:8080/X114CC
```

## Testing

Run the test script:
```bash
./test-www-hosting.sh X114CC
```

This will:
- Check relay status
- Check device connection
- Try to access the www collection
- Show relay logs

## Troubleshooting

### Error: "Device not connected"

**Cause:** Device is not registered with the relay

**Check:**
```bash
# List all connected devices
curl http://localhost:8080/relay/status
```

**Solutions:**
1. Ensure geogram-desktop is running
2. Check that relay is configured in the desktop app (Settings > Relays)
3. Verify desktop app shows "Connected" status for the relay
4. Check relay logs for connection errors

### Device shows in status but still get "Device not connected"

**Possible causes:**

1. **Case mismatch**: Callsign must be uppercase (code converts to uppercase)
2. **Different connection method**: Device might be using HELLO message instead of REGISTER
3. **Storage mismatch**: Check `devices.get(callsign)` in RelayServer

**Debug:**
Check relay logs after making a request to see:
```
WWW collection request for callsign: X114CC
Callsign validation against pattern '...': true
Device lookup for X114CC: NOT FOUND
Device X114CC not found. Connected devices (1):
  - X114CC
```

If you see the callsign listed but still "NOT FOUND", there's a storage issue.

### No www collection or empty response

**Cause:** Device doesn't have a www collection or it's empty

**Solutions:**
1. Create a "Website" type collection in geogram-desktop
2. Add an `index.html` file
3. Verify files are in: `~/Documents/geogram/collections/www/`

### 404 Not Found

**Cause:** Callsign doesn't match validation pattern

**Check config.json:**
```json
"callsignPattern": "^[A-Za-z0-9]{3,10}(-[A-Za-z0-9]{1,3})?$"
```

This pattern allows:
- 3-10 alphanumeric characters
- Optional suffix with dash (e.g., X114CC-1)

## API Endpoints

### Serve WWW Collection

```
GET /{callsign}
GET /{callsign}/
GET /{callsign}/{path}
```

**Examples:**
```bash
# Serves /collections/www/index.html from device
curl http://localhost:8080/X114CC

# Serves /collections/www/about.html from device
curl http://localhost:8080/X114CC/about.html

# Serves /collections/www/css/style.css from device
curl http://localhost:8080/X114CC/css/style.css
```

### Device Info (for debugging)

```bash
# Check if device is connected
curl http://localhost:8080/device/X114CC

# List all connected devices
curl http://localhost:8080/relay/status
```

## Implementation Details

### Route Priority

Routes are registered in this order:
1. `/relay/status` - Status API
2. `/search` - Collection search
3. `/device/{callsign}` - Device info
4. `/device/{callsign}/*` - Device proxy
5. **`/{callsign}` - WWW collection hosting** ← New feature
6. `/` - Root status

### Callsign Validation

To avoid conflicts with API routes, callsigns are validated:

**Reserved words (rejected):**
- `relay`
- `search`
- `device`
- `api`

**Pattern matching:**
Must match the configured `callsignPattern` in config.json

### Request Flow

```
User Browser
   ↓
   GET /X114CC
   ↓
Relay Server
   ↓
   Validate callsign (isValidCallsign)
   ↓
   Lookup device (devices.get("X114CC"))
   ↓
   Forward via WebSocket: GET /collections/www/index.html
   ↓
Device (geogram-desktop)
   ↓
   Read ~/Documents/geogram/collections/www/index.html
   ↓
   Send HTTP_RESPONSE via WebSocket
   ↓
Relay Server
   ↓
   Forward response to browser
   ↓
User Browser (receives HTML)
```

## Known Issues

1. **Device Registration Method**: If device uses HELLO message (Nostr-style) instead of REGISTER message, it might be stored under npub key instead of callsign
   - **Fix**: Check RelayServer.java handleHello() method to ensure device is stored under callsign

2. **Case Sensitivity**: Although code converts to uppercase, check that storage and retrieval both use uppercase

## Log Files

Check relay logs for debugging:
```bash
tail -f logs/geogram-relay.log
```

Look for:
```
WWW collection request for callsign: X114CC
Callsign validation against pattern '^[A-Za-z0-9]{3,10}(-[A-Za-z0-9]{1,3})?$': true
Device lookup for X114CC: FOUND
```
