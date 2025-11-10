# Meshtastic Bridge Settings Design

**Version**: 1.0
**Last Updated**: 2025-11-10
**Status**: Design

---

## Overview

This document specifies the settings UI/UX for the Meshtastic bridge in the Geogram Android app, including where settings are located, what options are available, and how message filtering works to prevent overwhelming the slow LoRa network.

---

## Table of Contents

1. [Settings Location](#settings-location)
2. [Settings UI Design](#settings-ui-design)
3. [Message Filtering Strategy](#message-filtering-strategy)
4. [Implementation Details](#implementation-details)

---

## Settings Location

### Android App Settings Structure

The Meshtastic bridge settings should be located in the main settings screen as a dedicated section, not as a separate fragment or activity.

**Settings Menu Path:**
```
Main Menu → Settings → Bridges → Meshtastic
```

**Alternative Path (if no "Bridges" section yet):**
```
Main Menu → Settings → Meshtastic Bridge
```

### Settings Hierarchy

```
Settings (SettingsActivity.java)
│
├── Profile Settings
├── Network Settings
├── Privacy & Security
├── Notifications
│
├── BRIDGES
│   ├── Meshtastic Bridge
│   │   ├── Enable/Disable
│   │   ├── Connection Settings
│   │   ├── Message Filtering
│   │   └── Advanced Options
│   │
│   ├── APRS Bridge (future)
│   └── Briar Bridge (future)
│
└── About
```

### Files Affected

```
geogram-android/app/src/main/
├── java/offgrid/geogram/
│   ├── SettingsActivity.java (existing - add Meshtastic section)
│   ├── bridges/
│   │   ├── MeshtasticBridge.java (new)
│   │   ├── MeshtasticRegionDetector.java (new)
│   │   ├── MeshtasticMessageFilter.java (new)
│   │   └── MeshtasticIdentityMapper.java (new)
│   │
│   └── ui/settings/
│       └── MeshtasticSettingsPreference.java (new - PreferenceFragment)
│
└── res/
    ├── xml/
    │   ├── preferences.xml (existing - add Meshtastic preference screen)
    │   └── preferences_meshtastic.xml (new - Meshtastic-specific preferences)
    │
    └── values/
        └── strings.xml (add Meshtastic settings strings)
```

---

## Settings UI Design

### Main Settings Screen

The main Settings activity should show a "Meshtastic Bridge" preference that opens a dedicated settings screen:

```
┌─────────────────────────────────────────┐
│ Settings                         ← Back │
├─────────────────────────────────────────┤
│                                         │
│ Profile                              >  │
│ Network                              >  │
│ Privacy & Security                   >  │
│                                         │
│ ━━━ BRIDGES ━━━━━━━━━━━━━━━━━━━━       │
│                                         │
│ 📡 Meshtastic Bridge              >     │
│    Connect to LoRa mesh networks        │
│    Status: ● Connected (US/LongFast)    │
│                                         │
│ 📻 APRS Bridge (Coming Soon)         >  │
│                                         │
└─────────────────────────────────────────┘
```

### Meshtastic Settings Screen

When tapping "Meshtastic Bridge", open a dedicated screen:

```
┌─────────────────────────────────────────┐
│ Meshtastic Bridge                ← Back │
├─────────────────────────────────────────┤
│                                         │
│ [✓] Enable Meshtastic Bridge            │
│                                         │
│ ━━━ CONNECTION ━━━━━━━━━━━━━━━━         │
│                                         │
│ Status                                  │
│ ● Connected to mqtt.meshtastic.org      │
│ 12 nodes visible · Last msg 2 min ago   │
│                                         │
│ MQTT Server                             │
│ ┌─────────────────────────────────────┐ │
│ │ mqtt.meshtastic.org                 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Region                                  │
│ ┌─────────────────────────────────────┐ │
│ │ US (Auto-detected)               ▼  │ │
│ └─────────────────────────────────────┘ │
│ 📍 Based on your location               │
│ [Change Region Manually]                │
│                                         │
│ Channel Name                            │
│ ┌─────────────────────────────────────┐ │
│ │ LongFast                         ▼  │ │
│ └─────────────────────────────────────┘ │
│ Popular channels: LongFast, LongSlow    │
│                                         │
│ Encryption Key (PSK)                    │
│ ┌─────────────────────────────────────┐ │
│ │ AQ4FCzwKkoPQF2BL...           👁    │ │
│ └─────────────────────────────────────┘ │
│ Default key for LongFast channel        │
│                                         │
│ ━━━ MESSAGE FILTERING ━━━━━━━━━         │
│                                         │
│ How to send messages to Meshtastic:     │
│                                         │
│ ⦿ Dedicated conversation only           │
│   (Recommended - prevents flooding)     │
│                                         │
│   Messages sent in "Meshtastic:         │
│   LongFast" conversation are relayed    │
│   to LoRa. Other chats stay on BLE.     │
│                                         │
│ ○ Manual send button                    │
│   Long-press any message →              │
│   "Send to Meshtastic"                  │
│                                         │
│ ○ @mention triggering                   │
│   Type @MESH-A1B2C3D4 to send           │
│                                         │
│ ━━━ ADVANCED ━━━━━━━━━━━━━━━━━━         │
│                                         │
│ [✓] Auto-reconnect on disconnect        │
│ [✓] Show position updates in chat       │
│ [✓] Show node info updates              │
│ [ ] Subscribe to multiple regions       │
│                                         │
│ Rate Limit: 5 messages/minute           │
│ ┌─────────────────────────────────────┐ │
│ │ ──────●─────────────────────────    │ │
│ │ 1                               15  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │       [Test Connection]           │   │
│ └───────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │       [View Bridge Logs]          │   │
│ └───────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### preferences_meshtastic.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<PreferenceScreen xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto">

    <!-- Enable/Disable -->
    <SwitchPreferenceCompat
        android:key="meshtastic_enabled"
        android:title="Enable Meshtastic Bridge"
        android:defaultValue="false"
        android:summary="Connect to LoRa mesh networks via MQTT" />

    <!-- Connection Settings Category -->
    <PreferenceCategory
        android:title="CONNECTION"
        android:key="meshtastic_connection_category">

        <!-- Status (read-only, dynamically updated) -->
        <Preference
            android:key="meshtastic_status"
            android:title="Status"
            android:summary="Disconnected"
            android:selectable="false" />

        <!-- MQTT Server -->
        <EditTextPreference
            android:key="meshtastic_server"
            android:title="MQTT Server"
            android:defaultValue="mqtt.meshtastic.org"
            android:dependency="meshtastic_enabled" />

        <!-- Region -->
        <ListPreference
            android:key="meshtastic_region"
            android:title="Region"
            android:entries="@array/meshtastic_regions_display"
            android:entryValues="@array/meshtastic_regions_codes"
            android:defaultValue="US"
            android:dependency="meshtastic_enabled" />

        <!-- Region auto-detect button -->
        <Preference
            android:key="meshtastic_detect_region"
            android:title="Auto-detect Region"
            android:summary="📍 Based on your GPS location"
            android:dependency="meshtastic_enabled" />

        <!-- Channel -->
        <EditTextPreference
            android:key="meshtastic_channel"
            android:title="Channel Name"
            android:defaultValue="LongFast"
            android:dependency="meshtastic_enabled" />

        <!-- PSK -->
        <EditTextPreference
            android:key="meshtastic_psk"
            android:title="Encryption Key (PSK)"
            android:defaultValue=""
            android:inputType="textPassword"
            android:dependency="meshtastic_enabled" />

    </PreferenceCategory>

    <!-- Message Filtering Category -->
    <PreferenceCategory
        android:title="MESSAGE FILTERING"
        android:key="meshtastic_filtering_category">

        <ListPreference
            android:key="meshtastic_send_mode"
            android:title="How to send messages"
            android:entries="@array/meshtastic_send_modes_display"
            android:entryValues="@array/meshtastic_send_modes_values"
            android:defaultValue="dedicated_conversation"
            android:summary="Dedicated conversation only (recommended)"
            android:dependency="meshtastic_enabled" />

        <Preference
            android:key="meshtastic_send_mode_help"
            android:summary="Messages sent in 'Meshtastic: LongFast' conversation are relayed to LoRa. Other chats stay on BLE."
            android:selectable="false"
            android:dependency="meshtastic_enabled" />

    </PreferenceCategory>

    <!-- Advanced Settings Category -->
    <PreferenceCategory
        android:title="ADVANCED"
        android:key="meshtastic_advanced_category">

        <SwitchPreferenceCompat
            android:key="meshtastic_auto_reconnect"
            android:title="Auto-reconnect"
            android:defaultValue="true"
            android:dependency="meshtastic_enabled" />

        <SwitchPreferenceCompat
            android:key="meshtastic_show_position"
            android:title="Show position updates"
            android:defaultValue="true"
            android:dependency="meshtastic_enabled" />

        <SwitchPreferenceCompat
            android:key="meshtastic_show_nodeinfo"
            android:title="Show node info updates"
            android:defaultValue="true"
            android:dependency="meshtastic_enabled" />

        <SwitchPreferenceCompat
            android:key="meshtastic_multi_region"
            android:title="Subscribe to multiple regions"
            android:defaultValue="false"
            android:summary="Use when near region borders"
            android:dependency="meshtastic_enabled" />

        <SeekBarPreference
            android:key="meshtastic_rate_limit"
            android:title="Rate Limit (messages/minute)"
            android:defaultValue="5"
            android:max="15"
            app:min="1"
            android:dependency="meshtastic_enabled" />

        <!-- Test Connection Button -->
        <Preference
            android:key="meshtastic_test_connection"
            android:title="Test Connection"
            android:dependency="meshtastic_enabled" />

        <!-- View Logs Button -->
        <Preference
            android:key="meshtastic_view_logs"
            android:title="View Bridge Logs" />

    </PreferenceCategory>

</PreferenceScreen>
```

### strings.xml additions

```xml
<!-- Meshtastic Bridge Settings -->
<string name="meshtastic_bridge_title">Meshtastic Bridge</string>
<string name="meshtastic_bridge_summary">Connect to LoRa mesh networks</string>

<!-- Regions -->
<string-array name="meshtastic_regions_display">
    <item>US - United States</item>
    <item>EU - Europe</item>
    <item>ANZ - Australia/NZ</item>
    <item>CN - China</item>
    <item>JP - Japan</item>
    <item>IN - India</item>
    <item>TW - Taiwan</item>
    <item>KR - South Korea</item>
    <item>TH - Thailand</item>
    <item>MY - Malaysia</item>
</string-array>

<string-array name="meshtastic_regions_codes">
    <item>US</item>
    <item>EU</item>
    <item>ANZ</item>
    <item>CN</item>
    <item>JP</item>
    <item>IN</item>
    <item>TW</item>
    <item>KR</item>
    <item>TH</item>
    <item>MY</item>
</string-array>

<!-- Send Modes -->
<string-array name="meshtastic_send_modes_display">
    <item>Dedicated conversation only (Recommended)</item>
    <item>Manual send button (Long-press)</item>
    <item>@mention triggering</item>
</string-array>

<string-array name="meshtastic_send_modes_values">
    <item>dedicated_conversation</item>
    <item>manual_button</item>
    <item>mention_trigger</item>
</string-array>
```

---

## Message Filtering Strategy

### The Problem

**LoRa vs BLE Speed Comparison:**

| Protocol | Bandwidth | Latency | Max Messages/Min |
|----------|-----------|---------|------------------|
| Geogram BLE | ~100-1000 kbps | 10-100ms | **500-1000** |
| Meshtastic LoRa | ~1-5 kbps | 1-10 seconds | **1-5** |

**Risk**: If we relay all Geogram messages to Meshtastic, we would:
- Overwhelm the LoRa network (200x too fast)
- Violate duty cycle regulations (1% in EU)
- Create massive queues (messages delayed hours)
- Make the bridge unusable

### Solution: Dedicated Conversation Model

**Recommended Approach**: Messages are only sent to Meshtastic if they're typed in the special "Meshtastic: [CHANNEL]" conversation.

#### How It Works

1. **Incoming messages from Meshtastic**:
   - Appear in special conversation: "Meshtastic: LongFast"
   - Visible in conversations list with 📡 icon
   - Tagged with source: "via Meshtastic LoRa"

2. **Outgoing messages to Meshtastic**:
   - **Only** messages typed in "Meshtastic: LongFast" conversation are sent to LoRa
   - Messages in other conversations stay on BLE/NOSTR/relay networks
   - User explicitly chooses to "talk to Meshtastic users"

3. **Visual Separation**:
   ```
   Conversations List:

   📡 Meshtastic: LongFast
      Alice's Radio: Weather looking good
      2 min ago · 12 nodes

   💬 CR7BBQ (BLE)
      Hey, got your location
      5 min ago

   💬 Group: Hiking Team
      Meeting at trailhead
      10 min ago
   ```

#### User Experience Flow

**Scenario 1: User wants to send to Meshtastic**

1. Open conversations list
2. Tap "Meshtastic: LongFast"
3. Type message: "Anyone near the summit?"
4. Send
5. Message is relayed to LoRa network (with rate limiting)

**Scenario 2: User chatting with BLE peers**

1. Open conversations list
2. Tap "CR7BBQ (BLE)"
3. Type message: "I can see you on the map"
4. Send
5. Message sent via BLE only (NOT to Meshtastic)

#### Implementation: MeshtasticMessageFilter.java

```java
package offgrid.geogram.bridges;

import offgrid.geogram.core.Message;
import offgrid.geogram.core.Conversation;

public class MeshtasticMessageFilter {

    /**
     * Determines if a message should be sent to Meshtastic.
     *
     * @param message The message to check
     * @param conversation The conversation it's being sent in
     * @return true if should relay to Meshtastic
     */
    public static boolean shouldSendToMeshtastic(Message message,
                                                  Conversation conversation) {

        // Check send mode preference
        String sendMode = getSendModePreference();

        switch (sendMode) {
            case "dedicated_conversation":
                // Only send if in Meshtastic conversation
                return conversation.isMeshtasticBridge();

            case "manual_button":
                // Only send if explicitly marked
                return message.hasFlag(Message.FLAG_SEND_TO_MESHTASTIC);

            case "mention_trigger":
                // Send if message contains @MESH- mention
                return containsMeshtasticMention(message.getContent());

            default:
                return false;
        }
    }

    /**
     * Check if conversation is a Meshtastic bridge conversation.
     */
    public static boolean isMeshtasticConversation(Conversation conv) {
        return conv.getType() == Conversation.TYPE_MESHTASTIC_BRIDGE;
    }

    /**
     * Get the Meshtastic conversation for a channel.
     * Creates it if it doesn't exist.
     */
    public static Conversation getMeshtasticConversation(String channelName) {
        String conversationId = "meshtastic_" + channelName.toLowerCase();

        Conversation existing = conversationDao.findById(conversationId);
        if (existing != null) {
            return existing;
        }

        // Create new Meshtastic conversation
        Conversation conv = new Conversation();
        conv.setId(conversationId);
        conv.setName("Meshtastic: " + channelName);
        conv.setType(Conversation.TYPE_MESHTASTIC_BRIDGE);
        conv.setIcon("📡");
        conv.setDescription("LoRa mesh network");

        conversationDao.insert(conv);
        return conv;
    }

    /**
     * Check if message content contains a Meshtastic mention.
     */
    private static boolean containsMeshtasticMention(String content) {
        return content.contains("@MESH-");
    }

    private static String getSendModePreference() {
        SharedPreferences prefs = getSharedPreferences("MeshtasticBridge");
        return prefs.getString("send_mode", "dedicated_conversation");
    }
}
```

#### Database Schema for Conversations

```sql
-- Add conversation type for Meshtastic
ALTER TABLE conversations ADD COLUMN type TEXT DEFAULT 'direct';

-- Types:
-- 'direct' - 1:1 BLE/NOSTR chat
-- 'group' - Group conversation
-- 'broadcast' - Broadcast channel
-- 'meshtastic_bridge' - Meshtastic LoRa bridge
-- 'aprs_bridge' - APRS bridge (future)
```

### Alternative Filtering Options

If user selects different send modes:

#### Option 2: Manual Send Button

- User types message in any conversation
- Long-press message → "Send to Meshtastic"
- Dialog: "Send to which channel? [LongFast ▼]"
- Message added to queue with rate limiting

**Pros**: Maximum control, works from any conversation
**Cons**: Extra steps, easy to forget

#### Option 3: @mention Triggering

- User types: "Hey everyone @MESH-BROADCAST the weather is clearing up"
- Message sent on BLE normally
- Also queued for Meshtastic because of @MESH- mention
- @MESH-A1B2C3D4 for specific node, @MESH-BROADCAST for all

**Pros**: Inline with normal chat, familiar pattern
**Cons**: Can be accidentally triggered, clutters message content

### Rate Limiting Integration

Regardless of send mode, all outbound Meshtastic messages must be rate limited:

```java
public class MeshtasticBridge {
    private MeshtasticRateLimiter rateLimiter;
    private Queue<Message> outboundQueue;

    public void sendMessage(Message message) {
        if (rateLimiter.canSendMessage()) {
            // Send immediately
            publishToMQTT(message);
            rateLimiter.recordMessage();
        } else {
            // Queue for later
            outboundQueue.offer(message);
            notifyUserQueued(message, outboundQueue.size());
        }
    }

    private void notifyUserQueued(Message message, int queueDepth) {
        // Show in conversation:
        // "⏱️ Message queued for Meshtastic (2 ahead)"
    }
}
```

### Visual Indicators in Conversation

Messages sent to Meshtastic should show status:

```
Meshtastic: LongFast conversation:

┌─────────────────────────────────────┐
│ Alice's Radio (MESH-A1B2C3D4)       │
│ Weather looking good at summit      │
│ 📡 via LoRa · 5 min ago             │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ You (CR7BBQ)                        │
│ Great! Heading up now.              │
│ ✓ Sent to LoRa · Just now           │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ You (CR7BBQ)                        │
│ Is anyone else on the trail?        │
│ ⏱️ Queued for LoRa (2 ahead)        │
└─────────────────────────────────────┘
```

---

## Implementation Details

### Phase 1: Settings UI

1. Update `SettingsActivity.java` to include "Bridges" category
2. Create `preferences_meshtastic.xml` with all settings
3. Add strings to `strings.xml`
4. Implement auto-detect region button handler

### Phase 2: Message Filtering

1. Add `type` column to `conversations` table
2. Create `MeshtasticMessageFilter.java`
3. Auto-create "Meshtastic: [CHANNEL]" conversation when bridge enabled
4. Modify message send flow to check `shouldSendToMeshtastic()`

### Phase 3: Bridge Integration

1. Create `MeshtasticBridge.java` with MQTT connection
2. Implement rate limiter
3. Add outbound queue with visual indicators
4. Connect settings changes to bridge lifecycle

### Testing Checklist

- [ ] Settings screen displays correctly
- [ ] Auto-detect region works from GPS
- [ ] Manual region override works
- [ ] Dedicated conversation is auto-created
- [ ] Messages in Meshtastic conversation are queued for LoRa
- [ ] Messages in other conversations are NOT sent to LoRa
- [ ] Rate limiting prevents flooding
- [ ] Queue depth shown in UI
- [ ] Status indicators update correctly
- [ ] Bridge reconnects after network loss

---

## Open Questions

1. **Should we support multiple Meshtastic channels simultaneously?**
   - e.g., "Meshtastic: LongFast" AND "Meshtastic: ShortSlow"
   - Increases complexity but adds flexibility

2. **Should position updates from Geogram be auto-sent to Meshtastic?**
   - Useful for showing location on LoRa mesh
   - But uses precious bandwidth
   - Suggest: User setting (default: OFF)

3. **How to handle replies in Meshtastic conversation?**
   - LoRa doesn't have native threading
   - Could use text-based markers: "Re: [message]"

4. **Should we show LoRa signal strength / hop count?**
   - Meshtastic provides SNR and hop data
   - Could display in message metadata

---

**License**: Apache-2.0
**Copyright**: 2025 Geogram Contributors
