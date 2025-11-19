# Configuration Migration Guide

## What Changed

All relay server settings have been moved from hardcoded constants to a `config.json` file.

### Before (Hardcoded)
```java
private static final int WEBSOCKET_PORT = 45679;
private static final long HTTP_REQUEST_TIMEOUT = 30;
private static final long IDLE_TIMEOUT = 300;
```

### After (Configurable)
```json
{
  "port": 45679,
  "httpRequestTimeout": 30,
  "idleDeviceTimeout": 300
}
```

## Benefits

✅ **No Recompilation** - Change settings without rebuilding
✅ **Environment-Specific** - Different configs for dev/staging/prod
✅ **Runtime Flexibility** - Adjust limits and timeouts on the fly
✅ **Centralized** - All settings in one place
✅ **Validated** - Config validated on startup
✅ **Auto-Generated** - Default config created automatically

## Migration Steps

### 1. Update Your Deployment

**Old Way:**
```bash
# Settings were hardcoded
java -jar geogram-relay.jar [port]
```

**New Way:**
```bash
# Settings in config.json
java -jar geogram-relay-1.0.0.jar
```

### 2. Create config.json (Optional)

The server creates `config.json` automatically on first run with defaults. 

To customize before first run, create `config.json`:
```json
{
  "port": 45679,
  "host": "0.0.0.0",
  "httpRequestTimeout": 30,
  "idleDeviceTimeout": 300,
  "cleanupInterval": 300,
  "maxConnectedDevices": 1000,
  "maxPendingRequests": 10000,
  "callsignPattern": "^[A-Za-z0-9]{3,10}(-[A-Za-z0-9]{1,3})?$",
  "enableCors": false,
  "corsAllowedOrigins": "*",
  "enableRateLimiting": false,
  "maxRequestsPerMinute": 60
}
```

### 3. Environment-Specific Configs

**Development:**
```json
{
  "port": 45679,
  "enableLogging": true,
  "enableCors": true,
  "maxConnectedDevices": 10
}
```

**Production:**
```json
{
  "port": 45679,
  "enableLogging": false,
  "enableCors": false,
  "maxConnectedDevices": 1000,
  "httpRequestTimeout": 60
}
```

## Configuration Location

⚠️ **Important:** `config.json` must be in the **working directory** where you run the JAR.

```bash
# If you run from /opt/relay:
cd /opt/relay
java -jar geogram-relay-1.0.0.jar
# config.json should be in /opt/relay/

# If you run with absolute path:
cd /home/user
java -jar /opt/relay/geogram-relay-1.0.0.jar
# config.json should be in /home/user/
```

## Backwards Compatibility

✅ **Port Override:** Command-line port argument still works
```bash
java -jar geogram-relay-1.0.0.jar 8080
# Overrides port from config.json
```

✅ **Defaults:** All settings have sensible defaults
- Server works out-of-box without manual configuration

## Common Configurations

### High Capacity
```json
{
  "port": 45679,
  "maxConnectedDevices": 10000,
  "maxPendingRequests": 50000,
  "httpRequestTimeout": 120,
  "idleDeviceTimeout": 1800
}
```

### Low Latency
```json
{
  "port": 45679,
  "httpRequestTimeout": 10,
  "idleDeviceTimeout": 60,
  "cleanupInterval": 60
}
```

### Web Dashboard
```json
{
  "port": 45679,
  "enableCors": true,
  "corsAllowedOrigins": "http://localhost:3000,https://dashboard.example.com"
}
```

### Testing/Development
```json
{
  "port": 45679,
  "enableLogging": true,
  "enableCors": true,
  "corsAllowedOrigins": "*",
  "maxConnectedDevices": 10,
  "httpRequestTimeout": 5
}
```

## Validation

Config is validated on startup. Invalid values cause server to exit:

```
[ERROR] Invalid port: 99999 (must be 1-65535)
[ERROR] Invalid configuration, exiting
```

## All Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| port | number | 45679 | Server port |
| host | string | "0.0.0.0" | Bind address |
| enableLogging | boolean | true | Enable logging |
| httpRequestTimeout | number | 30 | HTTP timeout (seconds) |
| idleDeviceTimeout | number | 300 | Idle timeout (seconds) |
| cleanupInterval | number | 300 | Cleanup interval (seconds) |
| maxConnectedDevices | number | 1000 | Max devices |
| maxPendingRequests | number | 10000 | Max pending requests |
| callsignPattern | string | regex | Callsign validation |
| enableCors | boolean | false | Enable CORS |
| corsAllowedOrigins | string | "*" | CORS origins |
| enableRateLimiting | boolean | false | Enable rate limiting |
| maxRequestsPerMinute | number | 60 | Rate limit |

## Troubleshooting

### Config Not Found
```
[INFO] Configuration file config.json not found, creating default
[INFO] Configuration saved to config.json
```
✅ This is normal on first run

### Config Invalid
```
[ERROR] Failed to load configuration from config.json: ...
[INFO] Using default configuration
```
❌ Check JSON syntax (commas, quotes, brackets)

### Settings Not Applied
Make sure:
1. ✅ Config file in working directory
2. ✅ Valid JSON format
3. ✅ Server restarted after changes
4. ✅ No command-line overrides

---

**Migration Completed:** 2025-11-19
**Version:** 1.0.0
