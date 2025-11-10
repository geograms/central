# Global Geo Chat with Bridge Integration

**Version**: 1.0
**Last Updated**: 2025-11-10
**Status**: Design

---

## Overview

The Global Geo Chat provides a unified view of all nearby mesh network activity, aggregating messages from multiple sources (BLE, LoRa, NOSTR, relays) into a single geographic conversation thread.

Users see messages from nearby devices regardless of the underlying protocol, creating complete situational awareness of local communication activity.

---

## Table of Contents

1. [Concept](#concept)
2. [User Experience](#user-experience)
3. [Architecture](#architecture)
4. [Geographic Filtering](#geographic-filtering)
5. [Message Aggregation](#message-aggregation)
6. [Implementation Details](#implementation-details)
7. [Privacy & Security](#privacy--security)
8. [Testing](#testing)

---

## Concept

### The Problem

Current state (without geo chat integration):
- BLE messages appear in one place
- Meshtastic messages in separate conversation
- NOSTR messages elsewhere
- User must monitor multiple views
- Geographic context is lost

### The Solution

**Unified Global Geo Chat:**
```
┌─────────────────────────────────────┐
│   Global Geo Chat (5km radius)     │
├─────────────────────────────────────┤
│                                     │
│ 📡 MESH-A1B2 (LoRa)      1.2km     │
│    "Anyone near summit?"            │
│    2 min ago                        │
│                                     │
│ 💬 CR7BBQ (BLE)          0.5km     │
│    "Yes, 500m from top"             │
│    1 min ago                        │
│                                     │
│ 🌐 X135AS (Internet)     0.3km     │
│    "Heading up now"                 │
│    Just now                         │
│                                     │
│ 📡 MESH-C5D6 (LoRa)      3.1km     │
│    📍 40.7128, -74.0060             │
│    5 min ago                        │
│                                     │
└─────────────────────────────────────┘
```

**Key Features:**
- ✅ Single unified view of nearby activity
- ✅ Multiple protocols (BLE, LoRa, NOSTR, relay)
- ✅ Geographic filtering (1-50km radius)
- ✅ Distance indicators for each message
- ✅ Source indicators (emoji icons)
- ✅ Real-time updates

---

## User Experience

### Main Chat Interface

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Global Geo Chat

📍 Showing 12 messages within 5km
[All sources ▼]  [5km ▼]  [🗺️ Map]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📡 MESH-A1B2C3D4 (via LoRa)           1.2km NE
   Anyone near the summit?
   2 minutes ago
   [Reply] [Show on map] [⋮]

💬 CR7BBQ (via BLE)                    0.5km N
   Yes, about 500m from the top
   1 minute ago
   [Reply] [Show on map] [⋮]

📍 MESH-C5D6E7F8 (via LoRa)           3.1km SW
   Location update
   40.7128, -74.0060 • 250m altitude
   5 minutes ago
   [Show on map] [⋮]

🌐 X135AS (via Internet)               0.3km W
   Heading up now, should be there in 10 min
   Just now
   [Reply] [⋮]

📡 MESH-B3C4D5E6 (via LoRa)           4.8km SE
   Weather looks good, clear skies
   10 minutes ago
   [Reply] [Show on map] [⋮]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────────────────────────────────────────┐
│ Type a message...                           │
└─────────────────────────────────────────────┘
[Send to: All nearby ▼]  [📎]  [Send]
```

### Source Indicators

Visual indicators show message origin:

| Icon | Source | Color | Description |
|------|--------|-------|-------------|
| 💬 | BLE | Blue | Direct Bluetooth connection |
| 📡 | LoRa | Orange | Meshtastic LoRa network |
| 🌐 | Internet | Green | NOSTR/Internet |
| 🔁 | Relay | Purple | Store-and-forward relay |
| 📻 | APRS | Red | Amateur radio (future) |

### Filter Controls

**Source Filter:**
```
[All sources ▼]
  ✓ All sources
  ─────────────
  □ BLE only
  □ LoRa only
  □ Internet only
  □ Relay only
```

**Radius Filter:**
```
[5km ▼]
  ○ 1 km
  ● 5 km
  ○ 10 km
  ○ 25 km
  ○ 50 km
  ─────────────
  Custom...
```

**Message Type Filter:**
```
[Message Types ▼]
  ✓ Text messages
  ✓ Location updates
  □ Device announcements
  □ Telemetry data
```

### Map View Integration

```
┌─────────────────────────────────┐
│         [Map View]              │
│                                 │
│    📍 You (40.7128, -74.0060)   │
│                                 │
│    💬 0.5km N                   │
│       CR7BBQ                    │
│                                 │
│    📡 1.2km NE                  │
│       MESH-A1B2                 │
│                                 │
│    📡 3.1km SW                  │
│       MESH-C5D6                 │
│                                 │
│    🌐 0.3km W                   │
│       X135AS                    │
│                                 │
└─────────────────────────────────┘

[🗨️ Chat View]  [🗺️ Map View]

Tap marker to see message
Long-press to open conversation
```

### Message Context Menu

```
Long-press on any message:

┌──────────────────────────┐
│ Reply                    │
│ Reply privately          │
│ Show on map              │
│ Get directions           │
│ Copy message             │
│ Copy coordinates         │
│ View sender info         │
│ Block sender             │
│ Report spam              │
└──────────────────────────┘
```

### Settings Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Settings → Global Geo Chat

[✓] Enable Global Geo Chat

Message Sources
  [✓] BLE devices
  [✓] Meshtastic (LoRa)
  [✓] Internet (NOSTR)
  [✓] Relay messages
  [ ] APRS (when available)

Default Radius
  ┌────────────────────────┐
  │ 5 km                ▼  │
  └────────────────────────┘

Default Sort Order
  ● By time (newest first)
  ○ By distance (closest first)

Display Options
  [✓] Show distance
  [✓] Show direction (N/S/E/W)
  [✓] Show timestamps
  [✓] Show source icons
  [ ] Show exact coordinates

Privacy
  [✓] Share my location in geo chat
  [ ] Anonymous mode (receive only)
  [✓] Show my messages to nearby users

Notifications
  [ ] Notify for all messages
  [✓] Notify for mentions only
  [ ] Notify for nearby emergencies

Advanced
  Max messages to display: 100
  Message age limit: 1 hour
  Auto-refresh interval: 30 seconds

[Save Settings]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Architecture

### Component Diagram

```
┌────────────────────────────────────────────────────┐
│                 Geogram Android App                │
├────────────────────────────────────────────────────┤
│                                                    │
│  ┌──────────────────────────────────────────┐    │
│  │       Global Geo Chat Fragment           │    │
│  │  (UI - displays unified message list)    │    │
│  └──────────────────┬───────────────────────┘    │
│                     │                             │
│  ┌──────────────────▼───────────────────────┐    │
│  │       GeoChatAggregator                  │    │
│  │  - Combines messages from all sources    │    │
│  │  - Applies geographic filtering          │    │
│  │  - Sorts and deduplicates                │    │
│  └──┬───────┬────────┬────────┬────────────┘    │
│     │       │        │        │                  │
│  ┌──▼──┐ ┌─▼───┐ ┌─▼────┐ ┌─▼─────┐           │
│  │ BLE │ │LoRa │ │NOSTR │ │ Relay │           │
│  │Data │ │Data │ │Data  │ │ Data  │           │
│  │Base │ │Base │ │Base  │ │ Base  │           │
│  └─────┘ └─────┘ └──────┘ └───────┘           │
│     ▲       ▲        ▲         ▲                │
│     │       │        │         │                │
│  ┌──┴──┐ ┌─┴────────┴──┐   ┌──┴─────┐         │
│  │ BLE │ │ Meshtastic  │   │ Relay  │         │
│  │Recv │ │   Bridge    │   │ Service│         │
│  └─────┘ └─────────────┘   └────────┘         │
│                                                    │
└────────────────────────────────────────────────────┘
```

### Data Flow

```
External Message Source (BLE/LoRa/NOSTR)
    ↓
Protocol-Specific Receiver
    ↓
Message Translator (to common format)
    ↓
Geographic Enrichment (add location, distance)
    ↓
Database Storage (geo_chat_messages table)
    ↓
GeoChatAggregator (filter, sort, combine)
    ↓
LiveData/Observable Stream
    ↓
UI Update (RecyclerView adapter)
    ↓
User sees message in Global Geo Chat
```

### Common Message Format

All messages normalized to common structure:

```java
public class GeoChatMessage {
    // Identity
    private String id;                  // Unique message ID
    private String author;              // Callsign or identity
    private String authorType;          // "geogram", "meshtastic", "aprs"

    // Content
    private String content;             // Message text
    private MessageType type;           // TEXT, LOCATION, NODEINFO, etc.

    // Geographic
    private Double latitude;            // Decimal degrees
    private Double longitude;           // Decimal degrees
    private Integer altitude;           // Meters
    private String geocode4;            // Grid code for filtering

    // Metadata
    private long timestamp;             // Unix timestamp (ms)
    private MessageSource source;       // BLE, LORA, INTERNET, RELAY
    private Integer distanceMeters;     // Cached distance from user
    private String direction;           // N, NE, E, SE, S, SW, W, NW

    // Optional
    private String replyToId;           // For threading
    private Map<String, String> extra;  // Protocol-specific data
}

public enum MessageSource {
    BLE("💬", "BLE", Color.BLUE),
    LORA("📡", "LoRa", Color.ORANGE),
    INTERNET("🌐", "Internet", Color.GREEN),
    RELAY("🔁", "Relay", Color.PURPLE),
    APRS("📻", "APRS", Color.RED);

    private final String icon;
    private final String label;
    private final int color;
}

public enum MessageType {
    TEXT,           // Chat message
    LOCATION,       // Position update
    NODEINFO,       // Device announcement
    TELEMETRY,      // Sensor data
    EMERGENCY       // SOS/Alert
}
```

---

## Geographic Filtering

### Distance Calculation

**Haversine Formula Implementation:**

```java
public class DistanceCalculator {

    private static final int EARTH_RADIUS_METERS = 6371000;

    /**
     * Calculate distance between two points using Haversine formula.
     *
     * @return Distance in meters
     */
    public static int calculateDistance(
            double lat1, double lon1,
            double lat2, double lon2) {

        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(Math.toRadians(lat1)) *
                   Math.cos(Math.toRadians(lat2)) *
                   Math.sin(dLon / 2) * Math.sin(dLon / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return (int) (EARTH_RADIUS_METERS * c);
    }

    /**
     * Calculate cardinal direction from point A to point B.
     *
     * @return Direction: N, NE, E, SE, S, SW, W, NW
     */
    public static String calculateDirection(
            double lat1, double lon1,
            double lat2, double lon2) {

        double dLon = Math.toRadians(lon2 - lon1);
        double lat1Rad = Math.toRadians(lat1);
        double lat2Rad = Math.toRadians(lat2);

        double y = Math.sin(dLon) * Math.cos(lat2Rad);
        double x = Math.cos(lat1Rad) * Math.sin(lat2Rad) -
                   Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(dLon);

        double bearingRad = Math.atan2(y, x);
        double bearingDeg = (Math.toDegrees(bearingRad) + 360) % 360;

        // Convert bearing to cardinal direction
        String[] directions = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"};
        int index = (int) Math.round(bearingDeg / 45) % 8;
        return directions[index];
    }
}
```

### GeoCode4 Grid Filtering

**Fast geographic filtering using grid codes:**

```java
public class GeoCode4Filter {

    /**
     * Check if a message is within radius using GeoCode4 grids.
     * This is faster than calculating exact distance for every message.
     */
    public static boolean isWithinRadius(
            String userGrid,
            String messageGrid,
            int radiusKm) {

        // Quick check: same grid = definitely within radius
        if (userGrid.equals(messageGrid)) {
            return true;
        }

        // Check if grids are adjacent
        // Each GeoCode4 character represents a quadrant subdivision
        int commonPrefixLength = getCommonPrefixLength(userGrid, messageGrid);

        // Approximate grid size at each level
        // Level 0: ~10,000 km
        // Level 1: ~5,000 km
        // Level 2: ~2,500 km
        // Level 3: ~1,250 km
        // Level 4: ~625 km
        // Level 5: ~312 km
        // Level 6: ~156 km
        // Level 7: ~78 km
        // Level 8: ~39 km

        double[] gridSizes = {10000, 5000, 2500, 1250, 625, 312, 156, 78, 39};

        if (commonPrefixLength < gridSizes.length) {
            double maxDistance = gridSizes[commonPrefixLength];
            return radiusKm >= maxDistance;
        }

        // If very close (common prefix >= 6), likely within radius
        return commonPrefixLength >= 6;
    }

    private static int getCommonPrefixLength(String a, String b) {
        int minLength = Math.min(a.length(), b.length());
        for (int i = 0; i < minLength; i++) {
            if (a.charAt(i) != b.charAt(i)) {
                return i;
            }
        }
        return minLength;
    }
}
```

### Two-Stage Filtering Strategy

**Optimize performance with coarse + fine filtering:**

```java
public List<GeoChatMessage> getMessagesInRadius(
        Location userLocation,
        int radiusKm,
        int maxMessages) {

    String userGrid = GeoCode4.encode(
        userLocation.getLatitude(),
        userLocation.getLongitude()
    );

    // Stage 1: Coarse filter using GeoCode4 (database query)
    List<GeoChatMessage> candidates = database.query(
        "SELECT * FROM geo_chat_messages " +
        "WHERE geocode4 LIKE ? " +
        "ORDER BY timestamp DESC " +
        "LIMIT ?",
        userGrid.substring(0, 6) + "%",  // Grid prefix
        maxMessages * 2  // Get extra for fine filtering
    );

    // Stage 2: Fine filter with exact distance calculation
    List<GeoChatMessage> results = new ArrayList<>();

    for (GeoChatMessage msg : candidates) {
        if (msg.getLatitude() != null && msg.getLongitude() != null) {
            int distance = DistanceCalculator.calculateDistance(
                userLocation.getLatitude(),
                userLocation.getLongitude(),
                msg.getLatitude(),
                msg.getLongitude()
            );

            if (distance <= radiusKm * 1000) {
                msg.setDistanceMeters(distance);
                msg.setDirection(DistanceCalculator.calculateDirection(
                    userLocation.getLatitude(),
                    userLocation.getLongitude(),
                    msg.getLatitude(),
                    msg.getLongitude()
                ));
                results.add(msg);
            }
        }

        if (results.size() >= maxMessages) {
            break;
        }
    }

    return results;
}
```

---

## Message Aggregation

### GeoChatAggregator Class

```java
public class GeoChatAggregator {

    private final BleMessageRepository bleRepo;
    private final MeshtasticMessageRepository meshRepo;
    private final NostrMessageRepository nostrRepo;
    private final RelayMessageRepository relayRepo;

    private final LocationProvider locationProvider;
    private final GeoChatDatabase database;

    /**
     * Get unified message stream with real-time updates.
     */
    public LiveData<List<GeoChatMessage>> getGeoChatMessages(
            int radiusKm,
            Set<MessageSource> sources,
            Set<MessageType> types) {

        // Combine LiveData from all sources
        MediatorLiveData<List<GeoChatMessage>> combined = new MediatorLiveData<>();

        // Add BLE source
        if (sources.contains(MessageSource.BLE)) {
            LiveData<List<GeoChatMessage>> bleMessages =
                bleRepo.getMessagesLiveData();
            combined.addSource(bleMessages, messages ->
                updateCombinedMessages(combined, radiusKm, sources, types)
            );
        }

        // Add Meshtastic source
        if (sources.contains(MessageSource.LORA)) {
            LiveData<List<GeoChatMessage>> meshMessages =
                meshRepo.getMessagesLiveData();
            combined.addSource(meshMessages, messages ->
                updateCombinedMessages(combined, radiusKm, sources, types)
            );
        }

        // Add NOSTR source
        if (sources.contains(MessageSource.INTERNET)) {
            LiveData<List<GeoChatMessage>> nostrMessages =
                nostrRepo.getMessagesLiveData();
            combined.addSource(nostrMessages, messages ->
                updateCombinedMessages(combined, radiusKm, sources, types)
            );
        }

        // Add Relay source
        if (sources.contains(MessageSource.RELAY)) {
            LiveData<List<GeoChatMessage>> relayMessages =
                relayRepo.getMessagesLiveData();
            combined.addSource(relayMessages, messages ->
                updateCombinedMessages(combined, radiusKm, sources, types)
            );
        }

        // Also listen to location changes
        combined.addSource(locationProvider.getLocationLiveData(),
            location -> updateCombinedMessages(combined, radiusKm, sources, types)
        );

        return combined;
    }

    private void updateCombinedMessages(
            MediatorLiveData<List<GeoChatMessage>> combined,
            int radiusKm,
            Set<MessageSource> sources,
            Set<MessageType> types) {

        Location userLocation = locationProvider.getCurrentLocation();
        if (userLocation == null) {
            combined.setValue(Collections.emptyList());
            return;
        }

        List<GeoChatMessage> allMessages = new ArrayList<>();

        // Collect from all sources
        if (sources.contains(MessageSource.BLE)) {
            allMessages.addAll(bleRepo.getMessages());
        }
        if (sources.contains(MessageSource.LORA)) {
            allMessages.addAll(meshRepo.getMessages());
        }
        if (sources.contains(MessageSource.INTERNET)) {
            allMessages.addAll(nostrRepo.getMessages());
        }
        if (sources.contains(MessageSource.RELAY)) {
            allMessages.addAll(relayRepo.getMessages());
        }

        // Filter by geographic proximity
        List<GeoChatMessage> nearbyMessages = allMessages.stream()
            .filter(msg -> msg.getLatitude() != null && msg.getLongitude() != null)
            .filter(msg -> types.contains(msg.getType()))
            .map(msg -> enrichWithDistance(msg, userLocation))
            .filter(msg -> msg.getDistanceMeters() <= radiusKm * 1000)
            .sorted(Comparator.comparing(GeoChatMessage::getTimestamp).reversed())
            .limit(100)
            .collect(Collectors.toList());

        combined.setValue(nearbyMessages);
    }

    private GeoChatMessage enrichWithDistance(
            GeoChatMessage msg,
            Location userLocation) {

        int distance = DistanceCalculator.calculateDistance(
            userLocation.getLatitude(),
            userLocation.getLongitude(),
            msg.getLatitude(),
            msg.getLongitude()
        );

        String direction = DistanceCalculator.calculateDirection(
            userLocation.getLatitude(),
            userLocation.getLongitude(),
            msg.getLatitude(),
            msg.getLongitude()
        );

        msg.setDistanceMeters(distance);
        msg.setDirection(direction);

        return msg;
    }
}
```

### Message Deduplication

**Handle same message from multiple sources:**

```java
public class MessageDeduplicator {

    /**
     * Remove duplicate messages that arrived via different protocols.
     *
     * Example: Same message from Meshtastic MQTT and direct LoRa
     */
    public static List<GeoChatMessage> deduplicate(
            List<GeoChatMessage> messages) {

        Map<String, GeoChatMessage> uniqueMessages = new LinkedHashMap<>();

        for (GeoChatMessage msg : messages) {
            String key = createDeduplicationKey(msg);

            if (!uniqueMessages.containsKey(key)) {
                uniqueMessages.put(key, msg);
            } else {
                // Keep the one with preferred source
                GeoChatMessage existing = uniqueMessages.get(key);
                if (isPreferredSource(msg.getSource(), existing.getSource())) {
                    uniqueMessages.put(key, msg);
                }
            }
        }

        return new ArrayList<>(uniqueMessages.values());
    }

    private static String createDeduplicationKey(GeoChatMessage msg) {
        // Combine author, timestamp, and content hash
        String contentHash = String.valueOf(msg.getContent().hashCode());
        return msg.getAuthor() + "_" + msg.getTimestamp() + "_" + contentHash;
    }

    private static boolean isPreferredSource(
            MessageSource newSource,
            MessageSource existingSource) {

        // Preference order: BLE > LORA > INTERNET > RELAY
        int[] priority = {
            MessageSource.BLE.ordinal(),
            MessageSource.LORA.ordinal(),
            MessageSource.INTERNET.ordinal(),
            MessageSource.RELAY.ordinal()
        };

        int newPriority = Arrays.asList(priority).indexOf(newSource.ordinal());
        int existingPriority = Arrays.asList(priority).indexOf(existingSource.ordinal());

        return newPriority < existingPriority;
    }
}
```

---

## Implementation Details

### Database Schema

```sql
-- Unified geo chat messages table
CREATE TABLE geo_chat_messages (
    id TEXT PRIMARY KEY,
    author TEXT NOT NULL,
    author_type TEXT NOT NULL,           -- 'geogram', 'meshtastic', 'aprs'
    content TEXT NOT NULL,
    message_type TEXT NOT NULL,          -- 'TEXT', 'LOCATION', 'NODEINFO', etc.
    source TEXT NOT NULL,                -- 'BLE', 'LORA', 'INTERNET', 'RELAY'
    timestamp INTEGER NOT NULL,

    -- Geographic data
    latitude REAL,
    longitude REAL,
    altitude INTEGER,
    geocode4 TEXT,
    distance_meters INTEGER,             -- Cached, recalculated on location change
    direction TEXT,                      -- N, NE, E, SE, S, SW, W, NW

    -- Optional metadata
    reply_to_id TEXT,
    extra_data TEXT,                     -- JSON for protocol-specific fields

    -- Housekeeping
    created_at INTEGER NOT NULL,
    expires_at INTEGER,

    FOREIGN KEY (reply_to_id) REFERENCES geo_chat_messages(id)
);

-- Indexes for fast geographic queries
CREATE INDEX idx_geochat_geocode4_time
    ON geo_chat_messages(geocode4, timestamp DESC);

CREATE INDEX idx_geochat_source_time
    ON geo_chat_messages(source, timestamp DESC);

CREATE INDEX idx_geochat_distance
    ON geo_chat_messages(distance_meters, timestamp DESC);

CREATE INDEX idx_geochat_expires
    ON geo_chat_messages(expires_at);

-- View for quickly getting nearby messages
CREATE VIEW v_recent_geo_messages AS
SELECT
    *,
    CASE
        WHEN distance_meters < 100 THEN 'Very close'
        WHEN distance_meters < 1000 THEN 'Nearby'
        WHEN distance_meters < 5000 THEN 'Within 5km'
        ELSE 'Distant'
    END AS proximity_label
FROM geo_chat_messages
WHERE timestamp > (strftime('%s', 'now') - 3600) * 1000  -- Last hour
ORDER BY timestamp DESC
LIMIT 100;
```

### Message Insertion Pipeline

```java
public class GeoChatMessageInserter {

    private final GeoChatDatabase database;
    private final LocationProvider locationProvider;

    /**
     * Insert message from BLE source.
     */
    public void insertBleMessage(BleMessage bleMessage) {
        GeoChatMessage geoMessage = convertBleToGeoChatMessage(bleMessage);
        insertMessage(geoMessage);
    }

    /**
     * Insert message from Meshtastic source.
     */
    public void insertMeshtasticMessage(MeshtasticMessage meshMessage) {
        GeoChatMessage geoMessage = convertMeshtasticToGeoChatMessage(meshMessage);
        insertMessage(geoMessage);
    }

    /**
     * Insert message from NOSTR source.
     */
    public void insertNostrMessage(NostrEvent nostrEvent) {
        GeoChatMessage geoMessage = convertNostrToGeoChatMessage(nostrEvent);
        insertMessage(geoMessage);
    }

    /**
     * Common insertion logic.
     */
    private void insertMessage(GeoChatMessage message) {
        // Enrich with current user location for distance calculation
        Location userLocation = locationProvider.getCurrentLocation();
        if (userLocation != null &&
            message.getLatitude() != null &&
            message.getLongitude() != null) {

            int distance = DistanceCalculator.calculateDistance(
                userLocation.getLatitude(),
                userLocation.getLongitude(),
                message.getLatitude(),
                message.getLongitude()
            );

            String direction = DistanceCalculator.calculateDirection(
                userLocation.getLatitude(),
                userLocation.getLongitude(),
                message.getLatitude(),
                message.getLongitude()
            );

            message.setDistanceMeters(distance);
            message.setDirection(direction);
        }

        // Generate GeoCode4 for fast filtering
        if (message.getLatitude() != null && message.getLongitude() != null) {
            String geocode = GeoCode4.encode(
                message.getLatitude(),
                message.getLongitude()
            );
            message.setGeocode4(geocode);
        }

        // Insert into database
        database.insert(message);

        // Trigger UI update via LiveData
        notifyMessageAdded(message);
    }

    private GeoChatMessage convertMeshtasticToGeoChatMessage(
            MeshtasticMessage meshMessage) {

        GeoChatMessage geoMessage = new GeoChatMessage();

        // Identity
        geoMessage.setId("mesh_" + meshMessage.getPacketId());
        geoMessage.setAuthor(
            MeshtasticIdentityMapper.nodeIdToCallsign(meshMessage.getFromNode())
        );
        geoMessage.setAuthorType("meshtastic");

        // Content
        geoMessage.setContent(meshMessage.getText());
        geoMessage.setType(
            meshMessage.getPortNum() == TEXT_MESSAGE_APP
                ? MessageType.TEXT
                : MessageType.LOCATION
        );

        // Geographic (if available)
        if (meshMessage.hasPosition()) {
            geoMessage.setLatitude(meshMessage.getLatitude());
            geoMessage.setLongitude(meshMessage.getLongitude());
            geoMessage.setAltitude(meshMessage.getAltitude());
        }

        // Metadata
        geoMessage.setTimestamp(meshMessage.getRxTime() * 1000);
        geoMessage.setSource(MessageSource.LORA);

        // Extra data (protocol-specific)
        Map<String, String> extra = new HashMap<>();
        extra.put("node_id", meshMessage.getFromNode().toString());
        extra.put("hop_limit", String.valueOf(meshMessage.getHopLimit()));
        extra.put("channel", meshMessage.getChannelName());
        geoMessage.setExtra(extra);

        return geoMessage;
    }
}
```

### UI Implementation (Fragment)

```java
public class GeoChatFragment extends Fragment {

    private GeoChatViewModel viewModel;
    private GeoChatAdapter adapter;
    private RecyclerView recyclerView;

    @Override
    public View onCreateView(LayoutInflater inflater,
                            ViewGroup container,
                            Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_geochat, container, false);

        recyclerView = view.findViewById(R.id.messageRecyclerView);
        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

        adapter = new GeoChatAdapter(this::onMessageClick, this::onMessageLongClick);
        recyclerView.setAdapter(adapter);

        // Setup filters
        Spinner sourceFilter = view.findViewById(R.id.sourceFilter);
        Spinner radiusFilter = view.findViewById(R.id.radiusFilter);

        sourceFilter.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view,
                                      int position, long id) {
                updateSourceFilter(position);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });

        radiusFilter.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view,
                                      int position, long id) {
                updateRadiusFilter(position);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });

        return view;
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        viewModel = new ViewModelProvider(this).get(GeoChatViewModel.class);

        // Observe message stream
        viewModel.getMessages().observe(getViewLifecycleOwner(), messages -> {
            adapter.submitList(messages);
            updateMessageCount(messages.size());
        });

        // Observe location updates
        viewModel.getUserLocation().observe(getViewLifecycleOwner(), location -> {
            updateLocationIndicator(location);
        });
    }

    private void onMessageClick(GeoChatMessage message) {
        // Open message details or conversation
        if (message.getType() == MessageType.LOCATION) {
            showOnMap(message);
        } else {
            openConversation(message.getAuthor());
        }
    }

    private void onMessageLongClick(GeoChatMessage message) {
        // Show context menu
        showMessageContextMenu(message);
    }

    private void updateSourceFilter(int position) {
        Set<MessageSource> sources = new HashSet<>();

        switch (position) {
            case 0: // All
                sources.addAll(Arrays.asList(MessageSource.values()));
                break;
            case 1: // BLE only
                sources.add(MessageSource.BLE);
                break;
            case 2: // LoRa only
                sources.add(MessageSource.LORA);
                break;
            case 3: // Internet only
                sources.add(MessageSource.INTERNET);
                break;
            case 4: // Relay only
                sources.add(MessageSource.RELAY);
                break;
        }

        viewModel.setSourceFilter(sources);
    }

    private void updateRadiusFilter(int position) {
        int[] radii = {1, 5, 10, 25, 50}; // km
        viewModel.setRadiusFilter(radii[position]);
    }
}
```

### RecyclerView Adapter

```java
public class GeoChatAdapter extends ListAdapter<GeoChatMessage, GeoChatViewHolder> {

    private final OnMessageClickListener clickListener;
    private final OnMessageLongClickListener longClickListener;

    @Override
    public void onBindViewHolder(@NonNull GeoChatViewHolder holder, int position) {
        GeoChatMessage message = getItem(position);

        // Source icon
        holder.sourceIcon.setText(message.getSource().getIcon());
        holder.sourceIcon.setTextColor(message.getSource().getColor());

        // Author
        holder.authorText.setText(message.getAuthor());

        // Content
        if (message.getType() == MessageType.LOCATION) {
            holder.contentText.setText(
                String.format("📍 Location: %.4f, %.4f",
                    message.getLatitude(),
                    message.getLongitude())
            );
        } else {
            holder.contentText.setText(message.getContent());
        }

        // Distance and direction
        if (message.getDistanceMeters() != null) {
            String distanceText = formatDistance(message.getDistanceMeters());
            String direction = message.getDirection();
            holder.distanceText.setText(distanceText + " " + direction);
        }

        // Timestamp
        holder.timestampText.setText(formatTimestamp(message.getTimestamp()));

        // Source label
        holder.sourceLabel.setText("via " + message.getSource().getLabel());

        // Click listeners
        holder.itemView.setOnClickListener(v ->
            clickListener.onMessageClick(message)
        );

        holder.itemView.setOnLongClickListener(v -> {
            longClickListener.onMessageLongClick(message);
            return true;
        });
    }

    private String formatDistance(int meters) {
        if (meters < 1000) {
            return meters + "m";
        } else {
            return String.format("%.1fkm", meters / 1000.0);
        }
    }

    private String formatTimestamp(long timestamp) {
        long now = System.currentTimeMillis();
        long diff = now - timestamp;

        if (diff < 60000) {
            return "Just now";
        } else if (diff < 3600000) {
            return (diff / 60000) + " min ago";
        } else if (diff < 86400000) {
            return (diff / 3600000) + " hr ago";
        } else {
            return new SimpleDateFormat("MMM d, HH:mm", Locale.getDefault())
                .format(new Date(timestamp));
        }
    }
}
```

---

## Privacy & Security

### Location Sharing Controls

**User consent required:**

```java
public class GeoChatPrivacyManager {

    private final SharedPreferences prefs;

    public boolean isLocationSharingEnabled() {
        return prefs.getBoolean("geochat_share_location", false);
    }

    public void setLocationSharing(boolean enabled) {
        if (enabled) {
            // Show consent dialog
            showLocationSharingConsentDialog();
        } else {
            prefs.edit().putBoolean("geochat_share_location", false).apply();
        }
    }

    private void showLocationSharingConsentDialog() {
        new AlertDialog.Builder(context)
            .setTitle("Share Your Location?")
            .setMessage(
                "Enabling this will share your approximate location with " +
                "nearby Geogram users in the Global Geo Chat.\n\n" +
                "Your precise GPS coordinates are NOT shared. Only nearby " +
                "users within the same geographic grid can see your messages."
            )
            .setPositiveButton("Enable", (dialog, which) -> {
                prefs.edit().putBoolean("geochat_share_location", true).apply();
            })
            .setNegativeButton("Cancel", null)
            .show();
    }
}
```

### Anonymous Mode

**Receive messages without sharing location:**

```java
public class GeoChatAnonymousMode {

    public boolean isAnonymousModeEnabled() {
        return prefs.getBoolean("geochat_anonymous_mode", false);
    }

    public void sendMessage(String content) {
        if (isAnonymousModeEnabled()) {
            // Don't include location in message
            GeoChatMessage message = new GeoChatMessage();
            message.setContent(content);
            message.setLatitude(null);  // No location
            message.setLongitude(null);
            // Message won't appear in geo chat for others
            // (since it has no geographic context)
        } else {
            // Normal send with location
            sendMessageWithLocation(content);
        }
    }
}
```

### Location Precision Control

**Don't share exact GPS coordinates:**

```java
public class LocationObfuscator {

    /**
     * Reduce precision to grid level (not exact GPS).
     */
    public static Location obfuscateLocation(Location precise) {
        // Round to ~100m precision (4 decimal places)
        double lat = Math.round(precise.getLatitude() * 10000.0) / 10000.0;
        double lon = Math.round(precise.getLongitude() * 10000.0) / 10000.0;

        Location obfuscated = new Location(precise);
        obfuscated.setLatitude(lat);
        obfuscated.setLongitude(lon);

        return obfuscated;
    }

    /**
     * Or use GeoCode4 grid center instead of actual position.
     */
    public static Location gridCenterLocation(Location precise) {
        String grid = GeoCode4.encode(
            precise.getLatitude(),
            precise.getLongitude()
        );

        // Decode grid back to center coordinates
        return GeoCode4.decode(grid);
    }
}
```

### Message Expiration

**Auto-delete old messages:**

```java
public class GeoChatCleanupService {

    /**
     * Remove messages older than configured age.
     */
    @Scheduled(fixedRate = 3600000) // Run every hour
    public void cleanupExpiredMessages() {
        long maxAge = prefs.getLong("geochat_message_max_age",
            3600000); // Default 1 hour

        long cutoff = System.currentTimeMillis() - maxAge;

        database.delete(
            "DELETE FROM geo_chat_messages WHERE timestamp < ?",
            cutoff
        );

        Log.i(TAG, "Cleaned up geo chat messages older than " +
            (maxAge / 3600000) + " hours");
    }
}
```

---

## Testing

### Unit Tests

```java
@Test
public void testDistanceCalculation() {
    // New York to Los Angeles
    double lat1 = 40.7128;
    double lon1 = -74.0060;
    double lat2 = 34.0522;
    double lon2 = -118.2437;

    int distance = DistanceCalculator.calculateDistance(lat1, lon1, lat2, lon2);

    // Should be approximately 3,944 km
    assertTrue(distance > 3900000 && distance < 4000000);
}

@Test
public void testDirectionCalculation() {
    // North
    String direction = DistanceCalculator.calculateDirection(
        40.0, -74.0,
        41.0, -74.0
    );
    assertEquals("N", direction);

    // Southeast
    direction = DistanceCalculator.calculateDirection(
        40.0, -74.0,
        39.5, -73.5
    );
    assertEquals("SE", direction);
}

@Test
public void testGeoCode4Filtering() {
    String userGrid = "RY1A-IUZS";
    String nearbyGrid = "RY1A-IUZT";  // Adjacent
    String farGrid = "RY2B-JVAU";      // Different area

    assertTrue(GeoCode4Filter.isWithinRadius(userGrid, nearbyGrid, 50));
    assertFalse(GeoCode4Filter.isWithinRadius(userGrid, farGrid, 10));
}

@Test
public void testMessageAggregation() {
    GeoChatAggregator aggregator = new GeoChatAggregator();

    // Mock location
    Location userLocation = new Location("");
    userLocation.setLatitude(40.7128);
    userLocation.setLongitude(-74.0060);

    // Get messages within 5km
    List<GeoChatMessage> messages = aggregator.getMessagesInRadius(
        userLocation,
        5,  // 5km radius
        100 // max 100 messages
    );

    // All messages should be within 5km
    for (GeoChatMessage msg : messages) {
        assertTrue(msg.getDistanceMeters() <= 5000);
    }
}

@Test
public void testMessageDeduplication() {
    List<GeoChatMessage> messages = Arrays.asList(
        createMessage("id1", "CR7BBQ", "Hello", MessageSource.BLE),
        createMessage("id1", "CR7BBQ", "Hello", MessageSource.LORA),  // Duplicate
        createMessage("id2", "X135AS", "Hi", MessageSource.BLE)
    );

    List<GeoChatMessage> deduplicated = MessageDeduplicator.deduplicate(messages);

    assertEquals(2, deduplicated.size());
    // Should keep BLE version (higher priority)
    assertEquals(MessageSource.BLE,
        deduplicated.stream()
            .filter(m -> m.getAuthor().equals("CR7BBQ"))
            .findFirst()
            .get()
            .getSource()
    );
}
```

### Integration Tests

```java
@Test
public void testMeshtasticToGeoChatIntegration() {
    // Simulate Meshtastic message arrival
    MeshtasticMessage meshMessage = new MeshtasticMessage();
    meshMessage.setFromNode(0xa1b2c3d4);
    meshMessage.setText("Test from LoRa");
    meshMessage.setLatitude(40.7128);
    meshMessage.setLongitude(-74.0060);
    meshMessage.setRxTime(System.currentTimeMillis() / 1000);

    // Insert via bridge
    inserter.insertMeshtasticMessage(meshMessage);

    // Verify appears in geo chat
    List<GeoChatMessage> messages = aggregator.getMessagesInRadius(
        testLocation,
        10,
        100
    );

    assertTrue(messages.stream()
        .anyMatch(m -> m.getAuthor().equals("MESH-A1B2C3D4") &&
                      m.getContent().equals("Test from LoRa"))
    );
}
```

### Field Testing Checklist

- [ ] BLE messages appear in geo chat
- [ ] Meshtastic messages appear in geo chat
- [ ] NOSTR messages appear in geo chat
- [ ] Relay messages appear in geo chat
- [ ] Distance calculations are accurate
- [ ] Direction indicators are correct
- [ ] Messages sorted correctly (by time/distance)
- [ ] Geographic filtering works (1km, 5km, 10km, etc.)
- [ ] Source filtering works (BLE only, LoRa only, etc.)
- [ ] Message type filtering works
- [ ] Map view shows correct locations
- [ ] Real-time updates work (new messages appear)
- [ ] Location changes trigger distance recalculation
- [ ] Privacy mode works (anonymous, no location sharing)
- [ ] Message expiration works (old messages removed)
- [ ] Deduplication works (no duplicate messages)
- [ ] Performance is acceptable with 100+ messages
- [ ] Battery impact is reasonable

---

## Performance Optimization

### Caching Strategy

```java
public class GeoChatCache {

    private final LruCache<String, List<GeoChatMessage>> cache;

    public GeoChatCache() {
        // 10MB cache
        int cacheSize = 10 * 1024 * 1024;
        cache = new LruCache<>(cacheSize);
    }

    public List<GeoChatMessage> getCachedMessages(String cacheKey) {
        return cache.get(cacheKey);
    }

    public void cacheMessages(String cacheKey, List<GeoChatMessage> messages) {
        cache.put(cacheKey, messages);
    }

    private String createCacheKey(Location location, int radiusKm) {
        String grid = GeoCode4.encode(location.getLatitude(), location.getLongitude());
        return grid + "_" + radiusKm;
    }
}
```

### Database Optimization

```sql
-- Materialized view for frequently accessed data
CREATE TABLE geo_chat_cache AS
SELECT
    m.*,
    COUNT(*) OVER (PARTITION BY geocode4) as nearby_count
FROM geo_chat_messages m
WHERE timestamp > (strftime('%s', 'now') - 3600) * 1000;

-- Refresh periodically
DELETE FROM geo_chat_cache;
INSERT INTO geo_chat_cache SELECT ...;
```

### Pagination

```java
public class GeoChatPagination {

    private static final int PAGE_SIZE = 20;

    public List<GeoChatMessage> getPage(int pageNumber, int radiusKm) {
        int offset = pageNumber * PAGE_SIZE;

        return database.query(
            "SELECT * FROM geo_chat_messages " +
            "WHERE geocode4 LIKE ? " +
            "ORDER BY timestamp DESC " +
            "LIMIT ? OFFSET ?",
            userGrid + "%",
            PAGE_SIZE,
            offset
        );
    }
}
```

---

## Future Enhancements

### Phase 2 Features

1. **Message Threading**
   - Reply to specific messages
   - Show conversation threads
   - Collapse/expand threads

2. **Rich Media**
   - Location shares with maps
   - Photos (via relay)
   - Voice messages (compressed)

3. **Enhanced Filtering**
   - Keyword search
   - Author filter
   - Date range filter
   - Message importance (emergency, normal, low)

4. **Analytics Dashboard**
   - Mesh network health
   - Message flow visualization
   - Coverage maps
   - Node activity graphs

5. **Emergency Mode**
   - SOS broadcast
   - Priority routing
   - Wider radius
   - Alert notifications

---

**License**: Apache-2.0
**Copyright**: 2025 Geogram Contributors
