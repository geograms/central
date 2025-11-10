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

### Solution: Message Type Selector

**Recommended Approach**: Add a message type button in the compose UI that lets users explicitly choose which network(s) to send each message on.

#### How It Works

Users explicitly choose which network(s) to send each message on using a **Message Type button** in the compose UI.

**Compose UI Layout:**

```
┌─────────────────────────────────────────┐
│ ← Conversation                         │
├─────────────────────────────────────────┤
│                                         │
│ [Previous messages displayed here]      │
│                                         │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│ ┌───────┐  ┌──────────────────────┐    │
│ │  📡   │  │ Type a message...    │ 📤 │
│ │  ▼   │  │                      │    │
│ └───────┘  └──────────────────────┘    │
│   Type         Input Field        Send │
└─────────────────────────────────────────┘
```

**Message Type Button (📡 with dropdown arrow):**

When tapped, shows a multi-select dialog:

```
┌─────────────────────────────────────┐
│ Select Message Delivery             │
├─────────────────────────────────────┤
│                                     │
│ [✓] BLE (Bluetooth Mesh)            │
│     Send to nearby devices          │
│                                     │
│ [ ] Meshtastic LoRa                 │
│     Send to LoRa mesh (slow)        │
│                                     │
│ [✓] Internet (NOSTR)                │
│     Send via internet relays        │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ Selected: BLE, Internet             │
│                                     │
│ [Cancel]              [Apply]       │
└─────────────────────────────────────┘
```

**Default Selection:**
- BLE: ✓ Enabled (primary mesh network)
- Meshtastic: ✗ Disabled (must explicitly enable)
- Internet: ✓ Enabled (when available)

**Button Indicator:**
The button icon changes based on selected networks:

| Selection | Icon | Color | Tooltip |
|-----------|------|-------|---------|
| BLE only | 📲 | Blue | "BLE mesh" |
| BLE + Internet | 🌐 | Green | "BLE + Internet" |
| BLE + Meshtastic | 📡 | Orange | "BLE + LoRa" |
| All three | 🌍 | Purple | "All networks" |
| Meshtastic only | 📻 | Red | "LoRa only (slow!)" |

#### User Experience Flow

**Scenario 1: Normal BLE/Internet message (default)**

1. Open any conversation
2. Type message: "I can see you on the map"
3. Message type button shows: 🌐 (BLE + Internet)
4. Tap Send
5. Message sent via BLE mesh and NOSTR relays

**Scenario 2: Adding Meshtastic to a message**

1. Open any conversation
2. Tap message type button 📡
3. Select: [✓] BLE, [✓] Meshtastic, [✓] Internet
4. Button changes to: 🌍 (All networks)
5. Type message: "Anyone near the summit?"
6. Tap Send
7. Message sent on all three networks:
   - BLE: Immediate delivery to nearby devices
   - Internet: Immediate NOSTR relay
   - Meshtastic: Queued for LoRa (with rate limiting)

**Scenario 3: Meshtastic-only message (rare)**

1. Open any conversation
2. Tap message type button
3. Uncheck BLE and Internet, check only Meshtastic
4. Button changes to: 📻 (LoRa only) with warning icon
5. Type message: "Testing LoRa range"
6. Tap Send
7. Message sent ONLY to Meshtastic LoRa network
8. Warning toast: "⚠️ Slow delivery - LoRa only (no BLE/Internet)"

#### Implementation: Message Delivery Flags

Each message will have delivery flags indicating which networks to send on:

```java
package offgrid.geogram.core;

public class Message {
    // Delivery network flags (bitmask)
    public static final int NETWORK_BLE = 1 << 0;        // 0001 = BLE mesh
    public static final int NETWORK_INTERNET = 1 << 1;   // 0010 = NOSTR/Internet
    public static final int NETWORK_MESHTASTIC = 1 << 2; // 0100 = Meshtastic LoRa

    // Default: BLE + Internet
    public static final int NETWORKS_DEFAULT = NETWORK_BLE | NETWORK_INTERNET;

    private int deliveryNetworks = NETWORKS_DEFAULT;

    /**
     * Set which networks this message should be delivered on.
     */
    public void setDeliveryNetworks(int networks) {
        this.deliveryNetworks = networks;
    }

    /**
     * Check if message should be sent on a specific network.
     */
    public boolean shouldSendOn(int network) {
        return (deliveryNetworks & network) != 0;
    }

    /**
     * Enable a delivery network.
     */
    public void enableNetwork(int network) {
        deliveryNetworks |= network;
    }

    /**
     * Disable a delivery network.
     */
    public void disableNetwork(int network) {
        deliveryNetworks &= ~network;
    }
}
```

#### UI Component: MessageTypeButton.java

```java
package offgrid.geogram.ui;

import android.content.Context;
import android.widget.ImageButton;
import androidx.appcompat.app.AlertDialog;
import offgrid.geogram.core.Message;

public class MessageTypeButton extends ImageButton {

    private int selectedNetworks = Message.NETWORKS_DEFAULT;
    private OnNetworkSelectionChangedListener listener;

    public interface OnNetworkSelectionChangedListener {
        void onChanged(int networks);
    }

    public MessageTypeButton(Context context) {
        super(context);
        updateIcon();
        setOnClickListener(v -> showNetworkSelector());
    }

    private void showNetworkSelector() {
        boolean[] selections = {
            (selectedNetworks & Message.NETWORK_BLE) != 0,
            (selectedNetworks & Message.NETWORK_MESHTASTIC) != 0,
            (selectedNetworks & Message.NETWORK_INTERNET) != 0
        };

        String[] options = {
            "BLE (Bluetooth Mesh)\nSend to nearby devices",
            "Meshtastic LoRa\nSend to LoRa mesh (slow)",
            "Internet (NOSTR)\nSend via internet relays"
        };

        new AlertDialog.Builder(getContext())
            .setTitle("Select Message Delivery")
            .setMultiChoiceItems(options, selections, (dialog, which, isChecked) -> {
                selections[which] = isChecked;
            })
            .setPositiveButton("Apply", (dialog, which) -> {
                // Build network bitmask from selections
                int networks = 0;
                if (selections[0]) networks |= Message.NETWORK_BLE;
                if (selections[1]) networks |= Message.NETWORK_MESHTASTIC;
                if (selections[2]) networks |= Message.NETWORK_INTERNET;

                // Validate: at least one network must be selected
                if (networks == 0) {
                    Toast.makeText(getContext(),
                        "At least one network must be selected",
                        Toast.LENGTH_SHORT).show();
                    return;
                }

                // Warn if Meshtastic only
                if (networks == Message.NETWORK_MESHTASTIC) {
                    Toast.makeText(getContext(),
                        "⚠️ Slow delivery - LoRa only (no BLE/Internet)",
                        Toast.LENGTH_LONG).show();
                }

                selectedNetworks = networks;
                updateIcon();
                if (listener != null) {
                    listener.onChanged(networks);
                }
            })
            .setNegativeButton("Cancel", null)
            .show();
    }

    private void updateIcon() {
        // Update icon and color based on selected networks
        if (selectedNetworks == Message.NETWORK_BLE) {
            setImageResource(R.drawable.ic_bluetooth);
            setColorFilter(0xFF42A5F5); // Blue
        } else if (selectedNetworks == (Message.NETWORK_BLE | Message.NETWORK_INTERNET)) {
            setImageResource(R.drawable.ic_network);
            setColorFilter(0xFF66BB6A); // Green
        } else if ((selectedNetworks & Message.NETWORK_MESHTASTIC) != 0) {
            if (selectedNetworks == (Message.NETWORK_BLE | Message.NETWORK_MESHTASTIC | Message.NETWORK_INTERNET)) {
                setImageResource(R.drawable.ic_network_all);
                setColorFilter(0xFF9C27B0); // Purple - all three
            } else {
                setImageResource(R.drawable.ic_lora);
                setColorFilter(0xFFFF9800); // Orange - includes LoRa
            }
        }
    }

    public void setOnNetworkSelectionChangedListener(OnNetworkSelectionChangedListener listener) {
        this.listener = listener;
    }

    public int getSelectedNetworks() {
        return selectedNetworks;
    }
}
```

#### Updated ConversationChatFragment.java

```java
// In ConversationChatFragment.java

private MessageTypeButton btnMessageType;
private int currentDeliveryNetworks = Message.NETWORKS_DEFAULT;

@Override
public View onCreateView(@NonNull LayoutInflater inflater, ...) {
    View view = inflater.inflate(R.layout.fragment_conversation_chat, container, false);

    // ... existing code ...

    btnMessageType = view.findViewById(R.id.btn_message_type);
    btnMessageType.setOnNetworkSelectionChangedListener(networks -> {
        currentDeliveryNetworks = networks;
    });

    btnSend.setOnClickListener(v -> {
        String message = messageInput.getText().toString().trim();
        if (!message.isEmpty()) {
            sendMessage(message, currentDeliveryNetworks);
            messageInput.setText("");
        }
    });

    return view;
}

private void sendMessage(String messageText, int deliveryNetworks) {
    // Create message with delivery flags
    Message message = new Message();
    message.setContent(messageText);
    message.setDeliveryNetworks(deliveryNetworks);

    // Send on each selected network
    if (message.shouldSendOn(Message.NETWORK_BLE)) {
        sendViaBLE(message);
    }
    if (message.shouldSendOn(Message.NETWORK_INTERNET)) {
        sendViaInternet(message);
    }
    if (message.shouldSendOn(Message.NETWORK_MESHTASTIC)) {
        sendViaMeshtastic(message);
    }
}
```

#### Database Schema for Messages

```sql
-- Add delivery_networks column to messages table
ALTER TABLE messages ADD COLUMN delivery_networks INTEGER DEFAULT 3;
-- Default 3 = 0011 binary = BLE + Internet

-- Add delivery_status column to track per-network status
ALTER TABLE messages ADD COLUMN delivery_status TEXT;
-- JSON: {"ble": "sent", "internet": "sent", "meshtastic": "queued"}
```

### Updated Layout XML

#### fragment_conversation_chat.xml

Add message type button to the compose area:

```xml
<!-- Message input area -->
<LinearLayout
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="horizontal"
    android:padding="8dp"
    android:background="#252525">

    <!-- Message Type Button (NEW) -->
    <offgrid.geogram.ui.MessageTypeButton
        android:id="@+id/btn_message_type"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:src="@drawable/ic_network"
        android:tint="@color/white"
        android:background="?attr/selectableItemBackgroundBorderless"
        android:contentDescription="Select delivery networks"
        android:layout_marginEnd="4dp" />

    <!-- Message Input Field -->
    <EditText
        android:id="@+id/message_input"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:hint="Type a message..."
        android:textColor="@color/white"
        android:textColorHint="#888888"
        android:background="@drawable/input_background"
        android:padding="12dp"
        android:maxLines="4"
        android:inputType="textMultiLine|textCapSentences" />

    <!-- Send Button -->
    <ImageButton
        android:id="@+id/btn_send"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:src="@drawable/ic_send"
        android:tint="@color/white"
        android:background="?attr/selectableItemBackgroundBorderless"
        android:contentDescription="Send message"
        android:layout_marginStart="8dp" />

</LinearLayout>
```

### Mode Dropdown Integration

**Note**: The user mentioned a "Mode dropdown" where Meshtastic types should be added. This likely refers to a message mode selector somewhere in the app UI.

If there's an existing Mode dropdown (location TBD), add these Meshtastic-specific modes:

```
Message Mode:
┌─────────────────────────────────┐
│ Normal                       ▼  │
├─────────────────────────────────┤
│ Normal (BLE + Internet)         │
│ Broadcast                       │
│ Emergency                       │
│ ─────────────────────────────   │
│ Meshtastic: LongFast (US)       │
│ Meshtastic: LongSlow (US)       │
│ Meshtastic: MediumFast (US)     │
└─────────────────────────────────┘
```

When a Meshtastic mode is selected:
- Message type button automatically enables `NETWORK_MESHTASTIC`
- Mode dropdown shows current Meshtastic channel
- Can still modify delivery networks via message type button
- Meshtastic mode persists until user changes it

**Integration:**

```java
// When Mode dropdown changes to Meshtastic mode
public void onModeSelected(String mode) {
    if (mode.startsWith("Meshtastic:")) {
        // Extract channel name
        String channel = mode.substring("Meshtastic: ".length());

        // Enable Meshtastic network
        btnMessageType.enableNetwork(Message.NETWORK_MESHTASTIC);

        // Set active Meshtastic channel
        MeshtasticBridge.getInstance().setActiveChannel(channel);
    }
}
```

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
