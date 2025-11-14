# I2P API Specification

## Overview

This document specifies the API changes required to support I2P connectivity in Geogram. All existing endpoints remain backwards compatible, with I2P information added as optional fields.

## Profile API

### GET /api/profile

Returns the profile information for the device hosting the API, now including I2P destination.

**Endpoint**: `GET http://{host}:45678/api/profile`

**I2P Endpoint**: `GET http://{i2p-destination}/api/profile`

#### Response (Updated)

```json
{
  "npub": "npub1...",
  "nickname": "Alice",
  "callsign": "KN4CK",
  "description": "Off-grid communications enthusiast",
  "profilePicture": "/api/profile-picture",
  "preferredColor": "#FF6B6B",
  "i2p": {
    "destination": "ukeu3k5oycgaauneqgtnvselmt4yemvoilkln7jpvamvfx7dnkdq.b32.i2p",
    "enabled": true,
    "ready": true,
    "lastSeen": 1699564800000
  }
}
```

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `npub` | string | Yes | Nostr public key (npub1...) |
| `nickname` | string | Yes | User-chosen display name |
| `callsign` | string | Yes | Amateur radio callsign |
| `description` | string | Yes | User profile description |
| `profilePicture` | string | Yes | URL path to profile picture |
| `preferredColor` | string | Yes | Hex color code for user avatar |
| `i2p` | object | **NEW** | I2P connectivity information |
| `i2p.destination` | string | **NEW** | Base32 I2P address (.b32.i2p) |
| `i2p.enabled` | boolean | **NEW** | Whether I2P is enabled by user |
| `i2p.ready` | boolean | **NEW** | Whether I2P tunnels are ready |
| `i2p.lastSeen` | number | **NEW** | Unix timestamp of last I2P update |

#### Behavior

1. **I2P destination generation**: If device doesn't have an I2P destination yet, one is automatically generated when this endpoint is first called
2. **Destination persistence**: I2P destination is saved to `/data/data/offgrid.geogram/files/i2p/destination.dat`
3. **Backwards compatibility**: Clients not supporting I2P can ignore the `i2p` field
4. **Enabled vs Ready**:
   - `enabled`: User preference (Settings → I2P → Enable I2P)
   - `ready`: Tunnels are established and accepting connections
   - Device may have `enabled: true, ready: false` if tunnels are still initializing

#### Example Requests

**Via WiFi**:
```bash
curl http://192.168.1.100:45678/api/profile
```

**Via I2P** (future):
```bash
curl http://ukeu3k5oycgaauneqgtnvselmt4yemvoilkln7jpvamvfx7dnkdq.b32.i2p/api/profile
```

#### Example Responses

**I2P Enabled and Ready**:
```json
{
  "npub": "npub1abc123...",
  "nickname": "Alice",
  "callsign": "KN4CK",
  "description": "Mesh network enthusiast",
  "profilePicture": "/api/profile-picture",
  "preferredColor": "#FF6B6B",
  "i2p": {
    "destination": "ukeu3k5oycgaauneqgtnvselmt4yemvoilkln7jpvamvfx7dnkdq.b32.i2p",
    "enabled": true,
    "ready": true,
    "lastSeen": 1699564800000
  }
}
```

**I2P Enabled but Not Ready** (tunnels initializing):
```json
{
  "npub": "npub1abc123...",
  "nickname": "Bob",
  "callsign": "W1AW",
  "description": "Emergency communications operator",
  "profilePicture": "/api/profile-picture",
  "preferredColor": "#4CAF50",
  "i2p": {
    "destination": "xyz789abcdefghijklmnopqrstuvwxyz0123456789abc.b32.i2p",
    "enabled": true,
    "ready": false,
    "lastSeen": 1699564800000
  }
}
```

**I2P Disabled**:
```json
{
  "npub": "npub1abc123...",
  "nickname": "Charlie",
  "callsign": "VE3CC",
  "description": "Local WiFi only",
  "profilePicture": "/api/profile-picture",
  "preferredColor": "#2196F3",
  "i2p": {
    "destination": "abc123xyz789abcdefghijklmnopqrstuvwxyz012345.b32.i2p",
    "enabled": false,
    "ready": false,
    "lastSeen": 1699564800000
  }
}
```

**Low Battery (I2P Auto-Disabled)**:
```json
{
  "npub": "npub1abc123...",
  "nickname": "Dave",
  "callsign": "G4EFG",
  "description": "Solar powered station",
  "profilePicture": "/api/profile-picture",
  "preferredColor": "#FFC107",
  "i2p": {
    "destination": "def456ghi789jklmnopqrstuvwxyz0123456789abcde.b32.i2p",
    "enabled": false,
    "ready": false,
    "lastSeen": 1699560000000
  }
}
```

## Collections API

### GET /api/collections

Returns list of collections accessible to the requesting device, with permission checks for both WiFi and I2P connections.

**Endpoint**: `GET http://{host}:45678/api/collections`

**I2P Endpoint**: `GET http://{i2p-destination}/api/collections`

#### Permission Validation

The server must identify the requesting device and validate permissions:

**WiFi Requests**:
1. Extract request IP address: `String requestIp = req.ip();`
2. Map IP to Device: `Device device = findDeviceByIp(requestIp);`
3. Get device npub: `String npub = device.getProfileNpub();`
4. Check collection access: `hasCollectionAccess(collection.getSecurity(), npub);`

**I2P Requests** (future):
1. Extract I2P destination: `String i2pDest = req.attribute("i2p_destination");`
2. Map I2P destination to Device: `Device device = findDeviceByI2PDest(i2pDest);`
3. Get device npub: `String npub = device.getProfileNpub();`
4. Check collection access: `hasCollectionAccess(collection.getSecurity(), npub);`

#### Response Format

Response format remains unchanged. Collections are filtered based on requesting device's permissions.

```json
[
  {
    "npub": "npub1abc123...",
    "title": "Emergency Maps",
    "description": "Offline maps for disaster response",
    "fileCount": 42,
    "totalSize": 125829120,
    "thumbnail": "/api/collections/npub1abc123.../thumbnail/map_preview.jpg",
    "isFavorite": true
  },
  {
    "npub": "npub1xyz789...",
    "title": "Medical References",
    "description": "Field medicine guides",
    "fileCount": 15,
    "totalSize": 52428800,
    "thumbnail": null,
    "isFavorite": false
  }
]
```

#### Permission Rules

| Visibility | WiFi Access | I2P Access | Notes |
|-----------|-------------|------------|-------|
| PUBLIC | Anyone | Anyone | No authentication required |
| PRIVATE | Owner only | Owner only | Only the collection creator |
| GROUP | Whitelisted npubs | Whitelisted npubs | Must be in `permissions.whitelisted_users` |

#### Implementation Details

**Server-side permission check** (applies to both WiFi and I2P):

```java
private boolean hasCollectionAccess(CollectionSecurity security, String requestingNpub) {
    // PUBLIC: Always accessible
    if (security.getVisibility() == Visibility.PUBLIC) {
        return true;
    }

    // PRIVATE: Only owner (handled elsewhere)
    if (security.getVisibility() == Visibility.PRIVATE) {
        return false; // Caller must check ownership separately
    }

    // GROUP: Check whitelist
    if (security.getVisibility() == Visibility.GROUP) {
        if (requestingNpub != null && !requestingNpub.isEmpty()) {
            List<String> whitelist = security.getWhitelistedUsers();
            return whitelist != null && whitelist.contains(requestingNpub);
        }
    }

    return false;
}
```

**Identifying WiFi requestor**:

```java
private Device findDeviceByIp(String requestIp) {
    TreeSet<Device> devices = DeviceManager.getInstance().getDevicesSpotted();
    WiFiDiscoveryService wifiService = WiFiDiscoveryService.getInstance(context);

    for (Device device : devices) {
        String deviceIp = wifiService.getDeviceIp(device.ID);
        if (deviceIp != null && deviceIp.equals(requestIp)) {
            return device;
        }
    }
    return null;
}
```

**Identifying I2P requestor** (future implementation):

```java
private Device findDeviceByI2PDest(String i2pDestination) {
    TreeSet<Device> devices = DeviceManager.getInstance().getDevicesSpotted();

    for (Device device : devices) {
        String deviceI2P = device.getI2PDestination();
        if (deviceI2P != null && deviceI2P.equals(i2pDestination)) {
            return device;
        }
    }
    return null;
}
```

### GET /api/collections/:npub/files

Returns list of files in a specific collection, with permission validation.

**Endpoint**: `GET http://{host}:45678/api/collections/{npub}/files`

**I2P Endpoint**: `GET http://{i2p-destination}/api/collections/{npub}/files`

#### Permission Validation

Same as `/api/collections` endpoint - must validate requesting device has access to collection.

#### Response Format

```json
[
  {
    "name": "emergency_contacts.pdf",
    "size": 2048576,
    "path": "/storage/collections/emergency_maps/emergency_contacts.pdf",
    "downloadUrl": "/api/collections/npub1abc123.../file/emergency_contacts.pdf"
  },
  {
    "name": "local_map.jpg",
    "size": 5242880,
    "path": "/storage/collections/emergency_maps/local_map.jpg",
    "downloadUrl": "/api/collections/npub1abc123.../file/local_map.jpg"
  }
]
```

### GET /api/collections/:npub/file/*

Downloads a specific file from a collection, with permission validation.

**Endpoint**: `GET http://{host}:45678/api/collections/{npub}/file/{filename}`

**I2P Endpoint**: `GET http://{i2p-destination}/api/collections/{npub}/file/{filename}`

#### Permission Validation

Same as other collection endpoints - must validate access before serving file.

#### Response

Returns file contents with appropriate `Content-Type` header.

**Example**:
```bash
# Via WiFi
curl http://192.168.1.100:45678/api/collections/npub1abc123.../file/map.jpg \
  --output map.jpg

# Via I2P (future)
curl http://ukeu3k5o...dnkdq.b32.i2p/api/collections/npub1abc123.../file/map.jpg \
  --output map.jpg
```

### GET /api/collections/:npub/thumbnail/*

Returns thumbnail image for a file in a collection, with permission validation.

**Endpoint**: `GET http://{host}:45678/api/collections/{npub}/thumbnail/{filename}`

**I2P Endpoint**: `GET http://{i2p-destination}/api/collections/{npub}/thumbnail/{filename}`

#### Permission Validation

Same as other collection endpoints - must validate access before serving thumbnail.

#### Response

Returns thumbnail image (typically JPEG, 200x200px) with `Content-Type: image/jpeg` header.

## I2P-Specific Considerations

### Connection Source Detection

Server must detect whether request came via WiFi or I2P:

```java
get("/api/collections", (req, res) -> {
    String connectionSource = req.attribute("connection_source"); // "wifi" or "i2p"

    String requestingNpub = null;

    if ("wifi".equals(connectionSource)) {
        String requestIp = req.ip();
        Device device = findDeviceByIp(requestIp);
        requestingNpub = device != null ? device.getProfileNpub() : null;
    } else if ("i2p".equals(connectionSource)) {
        String i2pDest = req.attribute("i2p_destination");
        Device device = findDeviceByI2PDest(i2pDest);
        requestingNpub = device != null ? device.getProfileNpub() : null;
    }

    // Proceed with permission checks...
});
```

### Timeout Considerations

I2P connections have higher latency than WiFi:

| Operation | WiFi Timeout | I2P Timeout | Notes |
|-----------|--------------|-------------|-------|
| HTTP GET /api/profile | 5 seconds | 30 seconds | I2P tunnel establishment |
| HTTP GET /api/collections | 5 seconds | 30 seconds | Collection list is small |
| File download (1 MB) | 10 seconds | 90 seconds | Bandwidth limited by I2P |
| File download (10 MB) | 30 seconds | 300 seconds | Very slow over I2P |
| Thumbnail load | 5 seconds | 20 seconds | Small images ~50KB |

**Client-side timeout handling**:

```java
// For WiFi
HttpClient wifiClient = HttpClient.newBuilder()
    .connectTimeout(Duration.ofSeconds(5))
    .build();

// For I2P
HttpClient i2pClient = HttpClient.newBuilder()
    .connectTimeout(Duration.ofSeconds(30))
    .build();
```

### Error Responses

#### I2P Not Ready

When I2P is enabled but tunnels not ready:

```json
{
  "error": "I2P not ready",
  "message": "I2P tunnels are still initializing. Please try again in 30-60 seconds.",
  "i2p": {
    "enabled": true,
    "ready": false,
    "destination": "ukeu3k5o...dnkdq.b32.i2p"
  }
}
```

HTTP Status: `503 Service Unavailable`

#### I2P Disabled

When I2P is disabled by user or battery:

```json
{
  "error": "I2P disabled",
  "message": "I2P is currently disabled. Enable in Settings → I2P.",
  "i2p": {
    "enabled": false,
    "ready": false,
    "destination": "ukeu3k5o...dnkdq.b32.i2p"
  }
}
```

HTTP Status: `503 Service Unavailable`

#### Access Denied via I2P

When requesting device not in GROUP whitelist:

```json
{
  "error": "Access denied",
  "message": "You do not have permission to access this collection",
  "collection": {
    "npub": "npub1abc123...",
    "visibility": "GROUP"
  }
}
```

HTTP Status: `403 Forbidden`

### Security Considerations

#### Preventing I2P Destination Spoofing

**Problem**: Attacker creates new I2P destination and claims to be a whitelisted device.

**Mitigation Strategy**:

1. **Trust on First Use (TOFU)**: First I2P destination received for a npub is trusted
   ```java
   if (device.getI2PDestination() == null) {
       device.setI2PDestination(receivedDestination);
   } else if (!device.getI2PDestination().equals(receivedDestination)) {
       Log.w("Security", "I2P destination changed for device " + device.ID);
       // Show warning to user, require local WiFi confirmation
   }
   ```

2. **Local Confirmation Required**: I2P destination changes must be confirmed via local WiFi connection

3. **Nostr Signature Verification** (future): Require Nostr event signature proving ownership of npub
   ```json
   {
     "npub": "npub1abc123...",
     "i2p": {
       "destination": "ukeu3k5o...dnkdq.b32.i2p"
     },
     "signature": "sig1...", // Nostr signature of i2p.destination
     "timestamp": 1699564800000
   }
   ```

#### Rate Limiting

Prevent brute-force scanning of I2P addresses:

```java
// Rate limit: Max 10 requests per minute per I2P destination
Map<String, RateLimiter> rateLimiters = new ConcurrentHashMap<>();

before("/api/*", (req, res) -> {
    String i2pDest = req.attribute("i2p_destination");
    if (i2pDest != null) {
        RateLimiter limiter = rateLimiters.computeIfAbsent(
            i2pDest,
            k -> RateLimiter.create(10.0 / 60.0) // 10 per minute
        );

        if (!limiter.tryAcquire()) {
            res.status(429); // Too Many Requests
            halt(429, createErrorResponse("Rate limit exceeded"));
        }
    }
});
```

#### Request Logging

Log all I2P requests for audit purposes:

```java
after("/api/*", (req, res) -> {
    String i2pDest = req.attribute("i2p_destination");
    if (i2pDest != null) {
        Log.i("I2P_Audit",
            "Request: " + req.requestMethod() + " " + req.pathInfo() +
            " from " + i2pDest.substring(0, 12) + "..." +
            " status " + res.status()
        );
    }
});
```

## Testing

### Test Cases

#### TC1: Profile Fetch via WiFi

```bash
# Request
curl http://192.168.1.100:45678/api/profile

# Expected Response
{
  "npub": "npub1...",
  "nickname": "Alice",
  "i2p": {
    "destination": "ukeu3k5o...dnkdq.b32.i2p",
    "enabled": true,
    "ready": true
  }
}
```

#### TC2: Profile Fetch via I2P (future)

```bash
# Request
curl http://ukeu3k5o...dnkdq.b32.i2p/api/profile

# Expected Response
{
  "npub": "npub1...",
  "nickname": "Bob",
  "i2p": {
    "destination": "xyz789abc...jkl.b32.i2p",
    "enabled": true,
    "ready": true
  }
}
```

#### TC3: Collections Access - PUBLIC via I2P

```bash
# Setup
Collection visibility: PUBLIC

# Request (via I2P)
curl http://ukeu3k5o...dnkdq.b32.i2p/api/collections

# Expected Response
[
  {
    "npub": "npub1abc123...",
    "title": "Public Maps",
    "visibility": "PUBLIC"
  }
]
```

#### TC4: Collections Access - GROUP via I2P (Allowed)

```bash
# Setup
Collection visibility: GROUP
Whitelist: ["npub1requester..."]
Requester npub: npub1requester...

# Request (via I2P)
curl http://ukeu3k5o...dnkdq.b32.i2p/api/collections

# Expected Response
[
  {
    "npub": "npub1abc123...",
    "title": "Team Documents",
    "visibility": "GROUP"
  }
]
```

#### TC5: Collections Access - GROUP via I2P (Denied)

```bash
# Setup
Collection visibility: GROUP
Whitelist: ["npub1alice...", "npub1bob..."]
Requester npub: npub1charlie...

# Request (via I2P)
curl http://ukeu3k5o...dnkdq.b32.i2p/api/collections/npub1abc123.../files

# Expected Response
HTTP 403 Forbidden
{
  "error": "Access denied",
  "message": "You do not have permission to access this collection"
}
```

#### TC6: I2P Destination Generation

```bash
# First request to /api/profile (no destination exists)
curl http://192.168.1.100:45678/api/profile

# Expected: New I2P destination generated and returned

# Second request
curl http://192.168.1.100:45678/api/profile

# Expected: Same I2P destination returned (persisted)
```

#### TC7: Battery Auto-Disable

```bash
# Simulate battery drop to 8%
adb shell dumpsys battery set level 8

# Request profile
curl http://192.168.1.100:45678/api/profile

# Expected Response
{
  "i2p": {
    "destination": "ukeu3k5o...dnkdq.b32.i2p",
    "enabled": false,  // Auto-disabled due to low battery
    "ready": false
  }
}
```

### Integration Tests

Test suite should verify:

1. ✓ I2P destination auto-generation on first /api/profile call
2. ✓ I2P destination persistence across app restarts
3. ✓ Profile caching includes I2P destination
4. ✓ Device list shows I2P badges when I2P available
5. ✓ Collections accessible via I2P for PUBLIC collections
6. ✓ Collections accessible via I2P for GROUP members
7. ✓ Collections blocked via I2P for non-GROUP members
8. ✓ File downloads work via I2P
9. ✓ Thumbnails load via I2P
10. ✓ Battery auto-disable at 10%
11. ✓ Battery auto-enable at 15%
12. ✓ Connection fallback: WiFi → I2P → BLE

## Backwards Compatibility

All API changes are backwards compatible:

1. **Existing clients**: Can ignore `i2p` field in profile response
2. **Old servers**: Clients should handle missing `i2p` field gracefully
3. **Permission model**: Unchanged - GROUP permissions work identically via WiFi and I2P
4. **Response formats**: No breaking changes to existing fields

**Example client-side handling**:

```java
// Safe parsing that handles missing I2P field
JsonObject profile = JsonParser.parseString(response).getAsJsonObject();

String npub = profile.get("npub").getAsString();
String nickname = profile.get("nickname").getAsString();

// NEW: Safely extract I2P info (may be null)
String i2pDest = null;
boolean i2pEnabled = false;

if (profile.has("i2p")) {
    JsonObject i2pInfo = profile.getAsJsonObject("i2p");
    i2pDest = i2pInfo.has("destination") ?
        i2pInfo.get("destination").getAsString() : null;
    i2pEnabled = i2pInfo.has("enabled") ?
        i2pInfo.get("enabled").getAsBoolean() : false;
}
```

## Migration Guide

### For Existing Deployments

1. **Update server** to return I2P information in `/api/profile`
2. **Update clients** to cache I2P destinations
3. **Enable I2P** in Settings (users can opt-in)
4. **Test locally** via WiFi before relying on I2P

### Deployment Checklist

- [ ] Server updated to include I2P in profile API
- [ ] I2P destination generation working
- [ ] I2P destination persisted to storage
- [ ] Profile cache updated to store I2P info
- [ ] Device list shows I2P badges
- [ ] Collections API permission checks work for I2P
- [ ] File downloads work via I2P
- [ ] Thumbnails load via I2P
- [ ] Battery management functional
- [ ] Settings UI for I2P configuration
- [ ] Connection Manager implements fallback logic
- [ ] Testing completed on 2+ devices

---

**Document Version**: 1.0
**Last Updated**: 2025-11-14
**Author**: Geogram Development Team
**Status**: Specification Phase
