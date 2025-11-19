# Geogram Relay Status API

## Overview

The Geogram Relay exposes an HTTP status API at the root endpoint (`/`) that provides comprehensive information about the relay server, including uptime, location, connected devices, and server description.

## Endpoint

```
GET http://relay-server:port/
```

For local testing:
```
GET http://localhost:8080/
```

## Response Format

The API returns a JSON object with the following structure:

```json
{
  "service": "Geogram Relay Server",
  "version": "1.0.0",
  "status": "online",
  "description": "Geogram relay server for amateur radio operations",

  "uptime_seconds": 9,
  "uptime_formatted": "9s",
  "current_time": 1763547369513,
  "current_time_iso": "2025-11-19T10:16:09.513714071Z",
  "port": 8080,

  "connected_devices": 0,
  "max_devices": 1000,
  "devices": [],

  "location": {
    "latitude": 49.683,
    "longitude": 8.6219,
    "city": "Bensheim",
    "region": "Hesse",
    "country": "Germany",
    "country_code": "DE",
    "timezone": "Europe/Berlin",
    "ip": "178.202.105.29",
    "isp": "Vodafone"
  }
}
```

## Fields Description

### Server Information
- **service**: Always "Geogram Relay Server"
- **version**: Current version of the relay software
- **status**: Current status (typically "online")
- **description**: User-configurable server description (set in config.json)
- **port**: Port the relay is listening on

### Time Information
- **uptime_seconds**: Server uptime in seconds since start
- **uptime_formatted**: Human-readable uptime (e.g., "2d 5h 23m 15s")
- **current_time**: Current server timestamp in milliseconds (Unix epoch)
- **current_time_iso**: Current server time in ISO 8601 format

### Device Information
- **connected_devices**: Number of currently connected devices
- **max_devices**: Maximum number of devices that can connect
- **devices**: Array of connected device objects, each containing:
  - **callsign**: Amateur radio callsign of the device
  - **uptime_seconds**: How long the device has been connected
  - **idle_seconds**: How long since the device's last activity
  - **connected_at**: Timestamp when device connected

### Location Information
- **latitude**: Server latitude coordinates
- **longitude**: Server longitude coordinates
- **city**: City where server is located
- **region**: Region/state where server is located
- **country**: Country where server is located
- **country_code**: ISO country code (e.g., "DE", "US")
- **timezone**: Server timezone (e.g., "Europe/Berlin")
- **ip**: Public IP address of the server
- **isp**: Internet Service Provider

## Configuration

The server description and location information can be configured in `config.json`:

```json
{
  "serverDescription": "My custom relay description",
  "latitude": 49.683,
  "longitude": 8.6219,
  "city": "Bensheim",
  "region": "Hesse",
  "country": "Germany",
  "countryCode": "DE"
}
```

## Example Usage

### Using curl
```bash
curl http://localhost:8080/
```

### Using wget
```bash
wget -qO- http://localhost:8080/
```

### Using Python
```python
import requests
response = requests.get('http://localhost:8080/')
status = response.json()
print(f"Relay uptime: {status['uptime_formatted']}")
print(f"Connected devices: {status['connected_devices']}")
print(f"Location: {status['location']['city']}, {status['location']['country']}")
```

### Using JavaScript/Fetch
```javascript
fetch('http://localhost:8080/')
  .then(response => response.json())
  .then(status => {
    console.log(`Relay: ${status.service} v${status.version}`);
    console.log(`Uptime: ${status.uptime_formatted}`);
    console.log(`Devices: ${status.connected_devices}/${status.max_devices}`);
    console.log(`Location: ${status.location.city}, ${status.location.country}`);
  });
```

## Use Cases

1. **Service Discovery**: Desktop/mobile apps can query this endpoint to discover relay capabilities and location
2. **Health Monitoring**: Monitor relay uptime and status
3. **Device Management**: See which devices are currently connected
4. **Load Balancing**: Choose relays based on number of connected devices
5. **Geographic Selection**: Select nearest relay based on coordinates
6. **Debugging**: Verify server configuration and connectivity

## Related Endpoints

- `GET /relay/status` - Similar endpoint with device list (legacy)
- `GET /device/{callsign}` - Check if specific device is connected
- `WS /` - WebSocket endpoint for device connections
