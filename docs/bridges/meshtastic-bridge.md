# Meshtastic Bridge

**Version**: 1.0
**Last Updated**: 2025-11-10
**Status**: Design

---

## Overview

The Meshtastic Bridge connects Geogram's Bluetooth mesh network to Meshtastic's LoRa mesh network via MQTT, enabling communication between Geogram users and Meshtastic device owners.

**Meshtastic** is a long-range, low-power mesh radio platform using LoRa hardware. It provides a public MQTT bridge at `mqtt.meshtastic.org` that allows internet-connected devices to communicate with LoRa mesh networks.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Message Translation](#message-translation)
3. [Identity Mapping](#identity-mapping)
4. [Implementation Details](#implementation-details)
5. [Configuration](#configuration)
6. [Rate Limiting](#rate-limiting)
7. [Testing](#testing)

---

## Architecture

### Deployment Models

The Meshtastic bridge can be deployed in two complementary ways:

#### 1. Client Bridge (Primary - Android App)

```
Meshtastic Device
    ↓ (LoRa radio)
Meshtastic Node with MQTT
    ↓ (MQTT/TLS)
mqtt.meshtastic.org
    ↓ (MQTT/TLS)
Geogram Android App
    ↓ (BLE mesh)
Other Geogram Devices
```

**Advantages:**
- Decentralized - runs on user's device
- No infrastructure needed
- User controls connection
- Privacy - messages not logged elsewhere
- Can relay via Geogram BLE mesh when offline

**Files Involved:**
- `app/src/main/java/offgrid/geogram/bridges/MeshtasticBridge.java` (new)
- `app/src/main/java/offgrid/geogram/bridges/MeshtasticMessageTranslator.java` (new)
- `app/src/main/java/offgrid/geogram/bridges/MeshtasticIdentityMapper.java` (new)

#### 2. Server Bridge (Secondary - geogram-server)

```
Meshtastic MQTT Network
    ↓ (MQTT)
geogram-server (Bridge Service)
    ↓ (NOSTR WebSocket)
NOSTR Relays
    ↓ (NOSTR WebSocket)
Geogram Clients (Android, Web)
```

**Advantages:**
- Persistent 24/7 connection
- Community-wide service
- Historical message archive
- Works even when no Android user is online

**Files Involved:**
- `geogram-server/src/main/java/geogram/bridges/MeshtasticBridgeService.java` (new)

---

## Meshtastic Protocol Basics

### MQTT Topics

Meshtastic uses hierarchical MQTT topics:

```
msh/REGION/2/e/CHANNEL_NAME/!NODE_ID
│   │      │ │ │            │
│   │      │ │ │            └─ Node sending (hex ID with !)
│   │      │ │ └─ Channel name (e.g., LongFast)
│   │      │ └─ Encryption type (e=encrypted, c=clear)
│   │      └─ Protocol version (2)
│   └─ Geographic region (US, EU, etc.)
└─ Meshtastic prefix
```

**Examples:**
- `msh/US/2/e/LongFast/!a1b2c3d4` - US region, encrypted LongFast channel
- `msh/EU/2/c/ShortSlow/!e5f6a7b8` - EU region, cleartext ShortSlow channel

### Message Types

Meshtastic Protocol Buffers define several message types:

| PortNum | Type | Description | Geogram Mapping |
|---------|------|-------------|-----------------|
| 1 | TEXT_MESSAGE_APP | Plain text messages | Chat message |
| 3 | POSITION_APP | GPS coordinates | Location update |
| 4 | NODEINFO_APP | Device information | Device announcement |
| 5 | ROUTING_APP | Network routing | (Internal only) |
| 67 | TELEMETRY_APP | Battery, sensors | Status update |

### Encryption

- **AES-128** with Pre-Shared Key (PSK)
- Default channels have known PSKs (e.g., "AQ4FCzwKkoPQF2BL..." for LongFast)
- Custom channels use user-defined PSK
- Bridge must decrypt to translate messages

### Node Addressing

- **Node ID**: 32-bit integer (e.g., `0xa1b2c3d4`)
- **Display Format**: Hex with `!` prefix (e.g., `!a1b2c3d4`)
- **Broadcast**: `0xffffffff` (all nodes)

---

## Message Translation

### Meshtastic → Geogram

#### Text Message

**Meshtastic Protobuf:**
```protobuf
portnum: TEXT_MESSAGE_APP
payload: "Hello from LoRa!"
from: 0xa1b2c3d4
to: 0xffffffff
channel: 1
hop_limit: 3
```

**Translated to Geogram Markdown:**
```markdown
> 2025-11-10 09:45_00 -- MESH-A1B2C3D4
Hello from LoRa!

--> to: broadcast
--> id: mesh_msg_2025111009450000_a1b2c3d4
--> from-meshtastic-node: !a1b2c3d4
--> meshtastic-channel: LongFast
--> via: meshtastic-mqtt
--> hop-limit: 3
--> received-via: internet
```

**Conversation Group:**
- All Meshtastic messages appear in special group: "Meshtastic: [CHANNEL_NAME]"
- Group icon: 📡
- Group metadata includes channel info

#### Position Message

**Meshtastic Protobuf:**
```protobuf
portnum: POSITION_APP
payload: {
  latitude_i: 407128000  // fixed-point (divide by 1e7)
  longitude_i: -740060000
  altitude: 10
  time: 1699603500
}
from: 0xa1b2c3d4
```

**Translated to Geogram Markdown:**
```markdown
> 2025-11-10 09:45_00 -- MESH-A1B2C3D4
📍 Location Update

--> latitude: 40.7128
--> longitude: -74.0060
--> altitude: 10
--> from-meshtastic-node: !a1b2c3d4
--> position-time: 2025-11-10T09:45:00Z
--> via: meshtastic-mqtt
```

**Display in App:**
- Shows as location pin on map (if available)
- Text representation with coordinates
- Link to open in maps app

#### Node Info

**Meshtastic Protobuf:**
```protobuf
portnum: NODEINFO_APP
payload: {
  num: 0xa1b2c3d4
  user: {
    id: "!a1b2c3d4"
    long_name: "Alice's Radio"
    short_name: "ALI"
    hw_model: TBEAM
  }
}
```

**Translated to Geogram:**
```markdown
> 2025-11-10 09:45_00 -- MESH-A1B2C3D4
Device: Alice's Radio (ALI)
Hardware: TBEAM

--> from-meshtastic-node: !a1b2c3d4
--> device-name: Alice's Radio
--> device-short: ALI
--> hardware: TBEAM
--> via: meshtastic-mqtt
```

**Effect:**
- Updates identity mapping database
- Shows device name in future messages
- Displays in "Devices" list

### Geogram → Meshtastic

#### Text Message

**Geogram Markdown:**
```markdown
> 2025-11-10 09:50_00 -- CR7BBQ
Hey, received your message!

--> to: MESH-A1B2C3D4
--> id: geo_msg_2025111009500000_cr7bbq
```

**Translated to Meshtastic Protobuf:**
```protobuf
portnum: TEXT_MESSAGE_APP
payload: "Hey, received your message!"
from: <bridge-node-id>  // Bridge's Meshtastic ID
to: 0xa1b2c3d4          // Mapped from MESH-A1B2C3D4
channel: 1
hop_limit: 3
want_ack: false
```

**Published to MQTT:**
- Topic: `msh/US/2/e/LongFast/<bridge-node-id>`
- Payload: Encrypted protobuf

#### Broadcast Message

**Geogram Markdown:**
```markdown
> 2025-11-10 09:50_00 -- CR7BBQ
Anyone near the summit?

--> to: broadcast
```

**Translated to Meshtastic:**
```protobuf
to: 0xffffffff  // Broadcast to all nodes
```

#### Size Constraints

Meshtastic has a **237-byte maximum payload**. Handle oversized messages:

1. **Truncate with indicator:**
```
Message too long for LoRa. Truncated.

Original message: "This is a very long message that exceeds the 237 byte limit and needs to be truncated..." → "This is a very long message that exceeds the 237 byte limit and needs to be truncated...[+120 bytes]"
```

2. **Reject with error:**
```
❌ Message too long for Meshtastic (450 bytes, max 237)
```

3. **Split into multiple messages:**
```
[1/3] First part of the message...
[2/3] Second part of the message...
[3/3] Final part of the message.
```

**Recommended:** Option 1 (truncate) for simplicity.

---

## Identity Mapping

### Meshtastic Node ID → Geogram Callsign

**Format:**
```
!a1b2c3d4 → MESH-A1B2C3D4
```

**Rules:**
- Prefix: `MESH-`
- Node ID in uppercase hex (without `!`)
- Always 8 hex characters (pad with zeros if needed)
- Consistent mapping (same node ID → same callsign)

**Database Table:**
```sql
CREATE TABLE meshtastic_identity_map (
    node_id INTEGER PRIMARY KEY,        -- 0xa1b2c3d4
    callsign TEXT NOT NULL UNIQUE,      -- MESH-A1B2C3D4
    long_name TEXT,                      -- Alice's Radio
    short_name TEXT,                     -- ALI
    hardware_model TEXT,                 -- TBEAM
    last_seen TIMESTAMP,
    first_seen TIMESTAMP
);
```

**Implementation:**
```java
public class MeshtasticIdentityMapper {

    public String nodeIdToCallsign(int nodeId) {
        String hex = String.format("%08X", nodeId);
        return "MESH-" + hex;
    }

    public int callsignToNodeId(String callsign) {
        if (!callsign.startsWith("MESH-")) {
            throw new IllegalArgumentException("Not a Meshtastic callsign");
        }
        String hex = callsign.substring(5); // Remove "MESH-"
        return (int) Long.parseLong(hex, 16);
    }

    public void updateNodeInfo(int nodeId, String longName,
                               String shortName, String hwModel) {
        // Update database with node information
        // This enriches future message displays
    }
}
```

### Virtual NOSTR Identities (Optional)

For full NOSTR integration, each Meshtastic node can have a virtual keypair:

```java
// Generate deterministic keypair from node ID
byte[] seed = Sha256.hash(("meshtastic-node-" + nodeId).getBytes());
KeyPair keyPair = KeyPair.fromSeed(seed);

String npub = keyPair.getPublicKey().toBech32("npub");
// npub1meshtastic...
```

**Benefits:**
- Messages can be signed with virtual identity
- NOSTR relay compatibility
- Consistent identity across bridges

**Drawbacks:**
- Additional complexity
- Keys not controlled by Meshtastic device owner

**Recommendation:** Start without virtual NOSTR keys, add later if needed.

---

## Implementation Details

### Android App Implementation

#### MeshtasticBridge.java

**Responsibilities:**
- Manage MQTT connection to `mqtt.meshtastic.org`
- Subscribe to configured channels
- Publish outbound messages
- Handle reconnection

**Key Methods:**
```java
public class MeshtasticBridge {
    private MqttClient mqttClient;
    private MeshtasticMessageTranslator translator;
    private MeshtasticIdentityMapper identityMapper;

    public void connect(String server, String channel, byte[] psk) {
        // Connect to MQTT broker
        // Subscribe to msh/REGION/2/e/CHANNEL/#
    }

    public void onMessageArrived(String topic, MqttMessage message) {
        // Decrypt Meshtastic message
        // Translate to Geogram format
        // Add to "Meshtastic: [CHANNEL]" conversation
    }

    public void sendToMeshtastic(GeogramMessage message) {
        // Translate Geogram message to Meshtastic protobuf
        // Encrypt with PSK
        // Publish to MQTT
    }

    public void disconnect() {
        // Clean disconnect
    }
}
```

#### MeshtasticMessageTranslator.java

**Responsibilities:**
- Convert Meshtastic protobuf to Geogram markdown
- Convert Geogram markdown to Meshtastic protobuf
- Handle message size constraints
- Map message types

**Key Methods:**
```java
public class MeshtasticMessageTranslator {

    public GeogramMessage translateFromMeshtastic(
            MeshPacket packet, ChannelInfo channel) {
        // Decode protobuf
        // Map node ID to callsign
        // Create Geogram markdown message
        // Add metadata fields
    }

    public MeshPacket translateToMeshtastic(
            GeogramMessage message, ChannelInfo channel) {
        // Extract message content
        // Map callsign to node ID
        // Encode as protobuf
        // Apply size limits
    }
}
```

#### Dependencies

Add to `app/build.gradle.kts`:
```kotlin
dependencies {
    // MQTT client
    implementation("org.eclipse.paho:org.eclipse.paho.client.mqttv3:1.2.5")
    implementation("org.eclipse.paho:org.eclipse.paho.android.service:1.1.1")

    // Protocol Buffers
    implementation("com.google.protobuf:protobuf-javalite:3.21.12")

    // Meshtastic protobuf definitions
    implementation("com.geeksville.mesh:meshtastic-protos:2.2.0") // Check latest
}
```

### Server Implementation (Optional)

#### MeshtasticBridgeService.java

**Responsibilities:**
- Persistent MQTT connection
- Translate messages to NOSTR events
- Publish to configured NOSTR relays
- Store historical messages

**Key Components:**
```java
public class MeshtasticBridgeService {
    private MqttClient mqttClient;
    private NostrRelayConnection nostrRelay;

    public void start(Config config) {
        // Connect to MQTT
        // Connect to NOSTR relays
        // Start message translation loop
    }

    private void handleMeshtasticMessage(MeshPacket packet) {
        // Translate to NOSTR event
        // Publish to relays
        // Archive in database
    }

    private void handleNostrEvent(NostrEvent event) {
        // Check if from Geogram user
        // Translate to Meshtastic
        // Publish to MQTT
    }
}
```

**Configuration** (config.json):
```json
{
  "meshtastic-bridge": {
    "enabled": true,
    "mqtt-server": "mqtt.meshtastic.org",
    "mqtt-port": 1883,
    "channels": [
      {
        "name": "LongFast",
        "region": "US",
        "psk": "AQ4FCzwKkoPQF2BL...",
        "nostr-topic": "meshtastic-longfast"
      }
    ]
  }
}
```

---

## Configuration

### Automatic Region Detection

Geogram automatically detects which Meshtastic region to use based on the user's GPS location, eliminating the need for manual region selection.

#### Region Boundaries

Meshtastic regions are defined by geographic boundaries:

| Region | Name | Latitude Range | Longitude Range |
|--------|------|----------------|-----------------|
| **US** | United States | 24.4° to 49.4° N | -125.0° to -66.9° W |
| **EU** | Europe | 36.0° to 71.0° N | -10.0° to 40.0° E |
| **ANZ** | Australia/NZ | -47.0° to -10.0° S | 113.0° to 179.0° E |
| **CN** | China | 18.0° to 54.0° N | 73.0° to 135.0° E |
| **JP** | Japan | 24.0° to 46.0° N | 123.0° to 146.0° E |
| **IN** | India | 8.0° to 35.0° N | 68.0° to 97.0° E |
| **TW** | Taiwan | 21.9° to 25.3° N | 120.0° to 122.0° E |
| **KR** | South Korea | 33.0° to 39.0° N | 124.0° to 132.0° E |
| **TH** | Thailand | 5.6° to 20.5° N | 97.3° to 105.6° E |
| **NZ** | New Zealand | -47.3° to -34.4° S | 166.4° to 178.6° E |
| **MY** | Malaysia | 0.9° to 7.4° N | 99.6° to 119.3° E |

**Note**: Meshtastic regions follow radio frequency regulations (LoRa ISM bands), so boundaries align with regulatory zones.

#### Implementation: MeshtasticRegionDetector.java

```java
package offgrid.geogram.bridges;

import android.location.Location;
import java.util.ArrayList;
import java.util.List;

public class MeshtasticRegionDetector {

    private static class RegionBounds {
        final String code;
        final String name;
        final double minLat;
        final double maxLat;
        final double minLon;
        final double maxLon;

        RegionBounds(String code, String name, double minLat, double maxLat,
                     double minLon, double maxLon) {
            this.code = code;
            this.name = name;
            this.minLat = minLat;
            this.maxLat = maxLat;
            this.minLon = minLon;
            this.maxLon = maxLon;
        }

        boolean contains(double lat, double lon) {
            return lat >= minLat && lat <= maxLat &&
                   lon >= minLon && lon <= maxLon;
        }
    }

    private static final RegionBounds[] REGIONS = {
        // North America
        new RegionBounds("US", "United States", 24.4, 49.4, -125.0, -66.9),

        // Europe
        new RegionBounds("EU", "Europe", 36.0, 71.0, -10.0, 40.0),

        // Australia & New Zealand (combined region)
        new RegionBounds("ANZ", "Australia/NZ", -47.0, -10.0, 113.0, 179.0),

        // Asia
        new RegionBounds("CN", "China", 18.0, 54.0, 73.0, 135.0),
        new RegionBounds("JP", "Japan", 24.0, 46.0, 123.0, 146.0),
        new RegionBounds("IN", "India", 8.0, 35.0, 68.0, 97.0),
        new RegionBounds("TW", "Taiwan", 21.9, 25.3, 120.0, 122.0),
        new RegionBounds("KR", "South Korea", 33.0, 39.0, 124.0, 132.0),
        new RegionBounds("TH", "Thailand", 5.6, 20.5, 97.3, 105.6),
        new RegionBounds("MY", "Malaysia", 0.9, 7.4, 99.6, 119.3),

        // Note: New Zealand is covered by ANZ region above
    };

    /**
     * Detect Meshtastic region based on GPS coordinates.
     *
     * @param location User's current location
     * @return Region code (e.g., "US", "EU") or null if no match
     */
    public static String detectRegion(Location location) {
        if (location == null) {
            return null;
        }
        return detectRegion(location.getLatitude(), location.getLongitude());
    }

    /**
     * Detect Meshtastic region based on latitude/longitude.
     *
     * @param latitude Latitude in degrees
     * @param longitude Longitude in degrees
     * @return Region code (e.g., "US", "EU") or null if no match
     */
    public static String detectRegion(double latitude, double longitude) {
        for (RegionBounds region : REGIONS) {
            if (region.contains(latitude, longitude)) {
                return region.code;
            }
        }
        return null; // No matching region (e.g., ocean, Antarctica)
    }

    /**
     * Get all regions that include the given coordinates.
     * Useful for border areas where multiple regions might apply.
     *
     * @param latitude Latitude in degrees
     * @param longitude Longitude in degrees
     * @return List of matching region codes
     */
    public static List<String> detectAllRegions(double latitude, double longitude) {
        List<String> matches = new ArrayList<>();
        for (RegionBounds region : REGIONS) {
            if (region.contains(latitude, longitude)) {
                matches.add(region.code);
            }
        }
        return matches;
    }

    /**
     * Get human-readable region name.
     *
     * @param regionCode Region code (e.g., "US")
     * @return Region name (e.g., "United States") or null if unknown
     */
    public static String getRegionName(String regionCode) {
        for (RegionBounds region : REGIONS) {
            if (region.code.equals(regionCode)) {
                return region.name;
            }
        }
        return null;
    }

    /**
     * Check if coordinates are in a border area (within 100km of multiple regions).
     * This can be used to suggest multi-region subscriptions.
     *
     * @param latitude Latitude in degrees
     * @param longitude Longitude in degrees
     * @return True if near a border
     */
    public static boolean isNearBorder(double latitude, double longitude) {
        // Check if within ~100km of region boundary
        // (approximately 1 degree = 111km at equator)
        final double BORDER_MARGIN = 0.9; // degrees (~100km)

        int nearbyCount = 0;
        for (RegionBounds region : REGIONS) {
            // Expand bounds by margin
            double minLat = region.minLat - BORDER_MARGIN;
            double maxLat = region.maxLat + BORDER_MARGIN;
            double minLon = region.minLon - BORDER_MARGIN;
            double maxLon = region.maxLon + BORDER_MARGIN;

            if (latitude >= minLat && latitude <= maxLat &&
                longitude >= minLon && longitude <= maxLon) {
                nearbyCount++;
            }
        }

        return nearbyCount > 1;
    }
}
```

#### Usage in Settings UI

```java
public class MeshtasticBridgeFragment extends Fragment {

    private void initializeRegionSelection() {
        Spinner regionSpinner = view.findViewById(R.id.regionSpinner);

        // Try to auto-detect region
        Location lastLocation = locationManager.getLastKnownLocation();
        if (lastLocation != null) {
            String detectedRegion = MeshtasticRegionDetector.detectRegion(lastLocation);

            if (detectedRegion != null) {
                // Auto-select detected region
                regionSpinner.setSelection(getRegionIndex(detectedRegion));

                // Show confirmation toast
                String regionName = MeshtasticRegionDetector.getRegionName(detectedRegion);
                Toast.makeText(getContext(),
                    "Detected region: " + regionName,
                    Toast.LENGTH_SHORT).show();

                // Check if near border
                if (MeshtasticRegionDetector.isNearBorder(
                        lastLocation.getLatitude(),
                        lastLocation.getLongitude())) {
                    showBorderWarning();
                }
            } else {
                // No region detected (ocean, Antarctica, etc.)
                showManualSelectionDialog();
            }
        } else {
            // No GPS location available
            // Fall back to manual selection or use default (US)
            regionSpinner.setSelection(getRegionIndex("US"));
        }
    }

    private void showBorderWarning() {
        // Suggest subscribing to multiple regions
        new AlertDialog.Builder(getContext())
            .setTitle("Near Region Border")
            .setMessage("You're near a regional border. Consider subscribing to multiple regions for better coverage.")
            .setPositiveButton("OK", null)
            .show();
    }
}
```

### Android Settings UI

**New Fragment:** `MeshtasticBridgeFragment.java`

**Settings Screen Layout:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Meshtastic Bridge

[✓] Enable Meshtastic Bridge

MQTT Server
┌────────────────────────────────┐
│ mqtt.meshtastic.org            │
└────────────────────────────────┘

Region
┌────────────────────────────────┐
│ US (Auto-detected)          ▼  │
└────────────────────────────────┘
📍 Detected from GPS location
Options: US, EU, ANZ, CN, JP, etc.
[Manual Override]

Channel Name
┌────────────────────────────────┐
│ LongFast                       │
└────────────────────────────────┘
Popular: LongFast, LongSlow, MediumFast

Encryption Key (PSK)
┌────────────────────────────────┐
│ AQ4FCzwKkoPQF2BL...         👁 │
└────────────────────────────────┘

┌────────────────────────────────┐
│      [Test Connection]         │
└────────────────────────────────┘

Status: ● Connected (12 nodes visible)

[Advanced Settings ▼]
  [ ] Auto-reconnect
  [ ] Relay messages via BLE mesh
  [ ] Show position updates
  Message rate limit: 5/min
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Default Channels:**

Pre-configure common public channels:
```java
public static final MeshtasticChannel[] DEFAULT_CHANNELS = {
    new MeshtasticChannel("LongFast", "AQ4FCzwKkoPQF2BL..."),
    new MeshtasticChannel("LongSlow", "AQ4FCzwKkoPQF2BL..."),
    new MeshtasticChannel("MediumFast", "AQ4FCzwKkoPQF2BL..."),
    // Users can add custom channels
};
```

### SharedPreferences Storage

```java
SharedPreferences prefs = getSharedPreferences("MeshtasticBridge", MODE_PRIVATE);

boolean enabled = prefs.getBoolean("enabled", false);
String server = prefs.getString("server", "mqtt.meshtastic.org");
String region = prefs.getString("region", "US");
String channel = prefs.getString("channel", "LongFast");
String psk = prefs.getString("psk", "");
```

---

## Rate Limiting

### LoRa Constraints

Meshtastic on LoRa is **extremely slow** compared to BLE:

| Parameter | LoRa (LongFast) | Geogram BLE |
|-----------|-----------------|-------------|
| Bandwidth | ~1-5 kbps | ~100-1000 kbps |
| Latency | 1-10 seconds | 10-100ms |
| Max messages | 1-5 per minute | Hundreds per minute |

### Rate Limiter Implementation

```java
public class MeshtasticRateLimiter {
    private final int maxMessagesPerMinute;
    private final Queue<Long> messageTimes;

    public MeshtasticRateLimiter(int maxMessagesPerMinute) {
        this.maxMessagesPerMinute = maxMessagesPerMinute;
        this.messageTimes = new LinkedList<>();
    }

    public boolean canSendMessage() {
        long now = System.currentTimeMillis();

        // Remove messages older than 1 minute
        while (!messageTimes.isEmpty() &&
               now - messageTimes.peek() > 60000) {
            messageTimes.poll();
        }

        return messageTimes.size() < maxMessagesPerMinute;
    }

    public void recordMessage() {
        messageTimes.offer(System.currentTimeMillis());
    }

    public int getQueueDepth() {
        return messageTimes.size();
    }
}
```

### User Feedback

When rate limited, show toast or notification:

```
⏱️ Meshtastic rate limit reached (5/min)
Message queued, will send in 45 seconds
```

Queue display in conversation:
```
💬 Your message
   ⏱️ Waiting to send... (2 messages ahead)
```

---

## Testing

### Unit Tests

**Test Message Translation:**
```java
@Test
public void testTextMessageTranslation() {
    MeshPacket packet = createTestPacket(
        TEXT_MESSAGE_APP,
        "Hello from LoRa!",
        0xa1b2c3d4
    );

    GeogramMessage message = translator.translateFromMeshtastic(packet);

    assertEquals("MESH-A1B2C3D4", message.getAuthor());
    assertEquals("Hello from LoRa!", message.getContent());
    assertEquals("meshtastic-mqtt", message.getMetadata("via"));
}

@Test
public void testPositionMessageTranslation() {
    MeshPacket packet = createPositionPacket(40.7128, -74.0060, 10);

    GeogramMessage message = translator.translateFromMeshtastic(packet);

    assertEquals(40.7128, message.getMetadata("latitude"));
    assertEquals(-74.0060, message.getMetadata("longitude"));
}
```

**Test Identity Mapping:**
```java
@Test
public void testNodeIdToCallsign() {
    MeshtasticIdentityMapper mapper = new MeshtasticIdentityMapper();

    String callsign = mapper.nodeIdToCallsign(0xa1b2c3d4);
    assertEquals("MESH-A1B2C3D4", callsign);

    int nodeId = mapper.callsignToNodeId("MESH-A1B2C3D4");
    assertEquals(0xa1b2c3d4, nodeId);
}
```

**Test Rate Limiting:**
```java
@Test
public void testRateLimiter() {
    MeshtasticRateLimiter limiter = new MeshtasticRateLimiter(5);

    // Should allow first 5 messages
    for (int i = 0; i < 5; i++) {
        assertTrue(limiter.canSendMessage());
        limiter.recordMessage();
    }

    // Should block 6th message
    assertFalse(limiter.canSendMessage());
}
```

### Integration Tests

**Test MQTT Connection:**
```java
@Test
public void testMqttConnection() {
    MeshtasticBridge bridge = new MeshtasticBridge();

    bridge.connect("mqtt.meshtastic.org", "LongFast", TEST_PSK);

    assertTrue(bridge.isConnected());

    bridge.disconnect();
}
```

**Test Message Send/Receive:**
```java
@Test
public void testMessageRoundTrip() {
    // Send from Geogram
    GeogramMessage outbound = new GeogramMessage(
        "CR7BBQ",
        "Test message",
        "MESH-A1B2C3D4"
    );
    bridge.sendToMeshtastic(outbound);

    // Wait for MQTT delivery
    Thread.sleep(2000);

    // Verify received on other side
    // (requires test Meshtastic node or simulator)
}
```

### Field Testing

**Checklist:**
- [ ] Connect to `mqtt.meshtastic.org`
- [ ] Subscribe to LongFast channel
- [ ] Receive messages from real Meshtastic nodes
- [ ] Send message to Meshtastic node
- [ ] Verify message appears on Meshtastic device
- [ ] Test with different regions (US, EU, etc.)
- [ ] Test position updates display correctly
- [ ] Test node info updates identity mapping
- [ ] Test rate limiting with rapid messages
- [ ] Test reconnection after network loss

---

## Monitoring & Diagnostics

### Bridge Status Display

Show in app UI:

```
Meshtastic Bridge Status

Connection: ● Connected
Server: mqtt.meshtastic.org
Channel: LongFast (US)
Nodes Visible: 12
Last Message: 2 minutes ago

Messages Today:
  Received: 47
  Sent: 12
  Queued: 2

[View Logs] [Disconnect]
```

### Debug Logging

Log key events:
```
[Meshtastic] Connected to mqtt.meshtastic.org
[Meshtastic] Subscribed to msh/US/2/e/LongFast/#
[Meshtastic] Message received from !a1b2c3d4
[Meshtastic] Translated to MESH-A1B2C3D4: "Hello from LoRa!"
[Meshtastic] Rate limit: 3/5 messages used
[Meshtastic] Queued message (2 ahead)
[Meshtastic] Sent message to !a1b2c3d4
```

### Error Handling

Common errors and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| Connection refused | Wrong server | Check server address |
| Authentication failed | Wrong credentials | Not needed for public MQTT |
| Subscription failed | Invalid topic | Verify channel name |
| Decrypt failed | Wrong PSK | Check encryption key |
| Message too large | Size limit exceeded | Truncate or reject |
| Rate limit exceeded | Too many messages | Queue and retry |

---

## Security Considerations

### MQTT Connection

- **Unencrypted MQTT**: `mqtt.meshtastic.org:1883` (no TLS)
- **Encrypted MQTT**: `mqtt.meshtastic.org:8883` (TLS)
- **Recommendation**: Use TLS (port 8883) when available

### PSK Storage

- Store PSK encrypted in Android KeyStore
- Don't log PSK in plaintext
- Allow user to view (with confirmation)

```java
// Store encrypted PSK
KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
// ... encrypt and store PSK
```

### Message Validation

- Verify message signatures (if Meshtastic adds this)
- Reject malformed messages
- Rate limit per node ID (prevent spam)

### Privacy

- Bridge operator can see decrypted messages
- For Android bridge: User controls, messages stay local
- For server bridge: Trust required in operator

---

## Future Enhancements

### Phase 2 Features

1. **Direct LoRa Support**
   - Meshtastic device connected to Android via Bluetooth Serial
   - No MQTT needed
   - Full offline operation

2. **Channel Discovery**
   - Scan for active channels
   - Show signal strength
   - Suggest channels based on location

3. **Mesh Visualization**
   - Display Meshtastic node map
   - Show relay paths
   - Network health metrics

4. **Advanced Filtering**
   - Ignore specific nodes
   - Priority routing
   - Message type filters

5. **Store-and-Forward**
   - Cache messages when offline
   - Send when MQTT connection restored
   - Sync with other bridges

---

## References

- **Meshtastic Documentation**: https://meshtastic.org/docs
- **Meshtastic Protobuf**: https://buf.build/meshtastic/protobufs
- **MQTT Public Server**: https://meshtastic.org/docs/software/mqtt
- **Default Channels**: https://meshtastic.org/docs/configuration/radio/channels
- **Eclipse Paho**: https://www.eclipse.org/paho/

---

**License**: Apache-2.0
**Copyright**: 2025 Geogram Contributors
