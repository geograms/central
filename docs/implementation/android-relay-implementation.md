# Android Relay Implementation

**Version**: 1.0
**Last Updated**: 2025-11-10
**Status**: Design

---

## Overview

This document specifies the implementation of the Geogram relay system for Android, enabling store-and-forward message delivery through Bluetooth mesh networking.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Data Models](#data-models)
3. [Storage Layer](#storage-layer)
4. [BLE Synchronization](#ble-synchronization)
5. [Settings Integration](#settings-integration)
6. [Garbage Collection](#garbage-collection)
7. [Implementation Phases](#implementation-phases)

---

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────┐
│         RelayFragment (UI)              │
├─────────────────────────────────────────┤
│         RelaySettingsManager            │
├─────────────────────────────────────────┤
│         RelayMessageManager             │
│  ┌────────────┐  ┌─────────────────┐   │
│  │ RelayStore │  │ RelayMessageSync│   │
│  └────────────┘  └─────────────────┘   │
├─────────────────────────────────────────┤
│         RelayGarbageCollector           │
├─────────────────────────────────────────┤
│         BLE Transport Layer             │
└─────────────────────────────────────────┘
```

### Key Components

**1. RelayMessage.java**
- Data model for relay messages
- Parsing markdown format
- Message ID generation (NOSTR-style)
- Signature verification

**2. RelayStorage.java**
- File-based message storage
- Directory structure: `relay/inbox/`, `relay/outbox/`, `relay/sent/`
- Message indexing and search
- Disk space management

**3. RelayMessageSync.java**
- BLE message synchronization protocol
- Inventory exchange
- Gap analysis
- Message transfer

**4. RelaySettings.java**
- Settings persistence (SharedPreferences)
- Relay enable/disable state
- Disk space allocation
- Message type filtering

**5. RelayGarbageCollector.java**
- Periodic cleanup of expired messages
- TTL enforcement
- Disk space reclamation
- Low-priority message pruning

---

## Data Models

### RelayMessage.java

```java
package offgrid.geogram.relay;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class RelayMessage {

    // Message metadata
    private String id;              // SHA-256 hex (64 chars)
    private String fromCallsign;
    private String toCallsign;
    private long timestamp;         // Unix timestamp (seconds)
    private String content;         // Message body

    // Message fields
    private String type;            // private, broadcast, emergency, etc.
    private String priority;        // urgent, normal, low
    private long ttl;               // Time-to-live (seconds)
    private String signature;       // Cryptographic signature

    // NOSTR fields
    private String fromNpub;
    private String toNpub;

    // Relay metadata
    private List<String> relayPath; // List of relay nodes
    private String location;        // Geographic coordinates
    private int hopCount;

    // Attachments
    private List<RelayAttachment> attachments;

    // Additional metadata
    private Map<String, String> customFields;

    // Storage metadata (not part of message format)
    private long receivedAt;        // When this relay received it
    private String receivedVia;     // bluetooth, internet, lora, etc.
    private boolean delivered;      // Has it been delivered to destination?

    /**
     * Parse a relay message from markdown format.
     */
    public static RelayMessage parseMarkdown(String markdown) {
        // Implementation based on relay-protocol.md format
        // Parse header, content, metadata fields, attachments
    }

    /**
     * Serialize message to markdown format.
     */
    public String toMarkdown() {
        // Generate markdown following relay-protocol.md
    }

    /**
     * Generate NOSTR-style message ID.
     */
    public static String generateMessageId(String fromNpub, String toNpub,
                                           long timestamp, String content) {
        // Implementation from relay-protocol.md
        // [0, pubkey, created_at, kind, tags, content]
    }

    /**
     * Check if message has expired based on TTL.
     */
    public boolean isExpired() {
        long now = System.currentTimeMillis() / 1000;
        return (timestamp + ttl) < now;
    }

    /**
     * Check if this relay should accept/forward this message.
     */
    public boolean shouldAccept(RelaySettings settings) {
        // Check message type against accepted types
        // Check total size against limits
        // Check if already expired
    }

    /**
     * Get total message size (content + attachments).
     */
    public long getTotalSize() {
        long size = content.length();
        for (RelayAttachment att : attachments) {
            size += att.getSize();
        }
        return size;
    }
}
```

### RelayAttachment.java

```java
package offgrid.geogram.relay;

public class RelayAttachment {
    private String mimeType;        // image/jpeg, audio/mp3, etc.
    private String filename;
    private long size;              // Bytes
    private String encoding;        // Always "base64"
    private String checksum;        // sha256:hex
    private byte[] data;            // Decoded binary data

    /**
     * Verify checksum matches data.
     */
    public boolean verifyChecksum() {
        // SHA-256 hash of data should match checksum field
    }

    /**
     * Get data as base64 string for markdown serialization.
     */
    public String getBase64Data() {
        return Base64.encodeToString(data, Base64.NO_WRAP);
    }
}
```

### RelaySettings.java

```java
package offgrid.geogram.relay;

import android.content.Context;
import android.content.SharedPreferences;

public class RelaySettings {
    private static final String PREFS_NAME = "relay_settings";
    private static final String KEY_ENABLED = "relay_enabled";
    private static final String KEY_DISK_SPACE_MB = "disk_space_mb";
    private static final String KEY_AUTO_ACCEPT = "auto_accept";
    private static final String KEY_MESSAGE_TYPES = "message_types";

    private Context context;
    private SharedPreferences prefs;

    public RelaySettings(Context context) {
        this.context = context;
        this.prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    public boolean isRelayEnabled() {
        return prefs.getBoolean(KEY_ENABLED, false);
    }

    public void setRelayEnabled(boolean enabled) {
        prefs.edit().putBoolean(KEY_ENABLED, enabled).apply();
    }

    public int getDiskSpaceLimitMB() {
        return prefs.getInt(KEY_DISK_SPACE_MB, 1024); // Default 1GB
    }

    public void setDiskSpaceLimitMB(int mb) {
        prefs.edit().putInt(KEY_DISK_SPACE_MB, mb).apply();
    }

    public boolean isAutoAcceptEnabled() {
        return prefs.getBoolean(KEY_AUTO_ACCEPT, false);
    }

    public void setAutoAcceptEnabled(boolean enabled) {
        prefs.edit().putBoolean(KEY_AUTO_ACCEPT, enabled).apply();
    }

    public String getAcceptedMessageTypes() {
        // "text_only", "text_and_images", "everything"
        return prefs.getString(KEY_MESSAGE_TYPES, "text_only");
    }

    public void setAcceptedMessageTypes(String types) {
        prefs.edit().putString(KEY_MESSAGE_TYPES, types).apply();
    }
}
```

---

## Storage Layer

### Directory Structure

Messages are stored in the app's internal storage:

```
/data/data/offgrid.geogram/files/relay/
├── inbox/              # Messages for this device (to deliver)
│   ├── message1.md
│   ├── message2.md
│   └── ...
├── outbox/             # Messages to relay (not yet delivered)
│   ├── message3.md
│   ├── message4.md
│   └── ...
├── sent/               # Delivered messages (archive)
│   ├── message5.md
│   └── ...
└── index.json          # Message index for fast lookup
```

### RelayStorage.java

```java
package offgrid.geogram.relay;

import android.content.Context;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.List;

public class RelayStorage {

    private Context context;
    private File relayDir;
    private File inboxDir;
    private File outboxDir;
    private File sentDir;

    public RelayStorage(Context context) {
        this.context = context;

        // Initialize directories
        relayDir = new File(context.getFilesDir(), "relay");
        inboxDir = new File(relayDir, "inbox");
        outboxDir = new File(relayDir, "outbox");
        sentDir = new File(relayDir, "sent");

        createDirectories();
    }

    private void createDirectories() {
        relayDir.mkdirs();
        inboxDir.mkdirs();
        outboxDir.mkdirs();
        sentDir.mkdirs();
    }

    /**
     * Store a new relay message.
     */
    public void storeMessage(RelayMessage message, MessageLocation location) {
        File targetDir = getDirectoryForLocation(location);
        String filename = message.getId() + ".md";
        File file = new File(targetDir, filename);

        try (FileWriter writer = new FileWriter(file)) {
            writer.write(message.toMarkdown());
        } catch (IOException e) {
            Log.e("RelayStorage", "Failed to store message: " + e.getMessage());
        }
    }

    /**
     * Load a message by ID.
     */
    public RelayMessage loadMessage(String messageId) {
        // Check inbox, outbox, sent directories
        for (File dir : new File[]{inboxDir, outboxDir, sentDir}) {
            File file = new File(dir, messageId + ".md");
            if (file.exists()) {
                try {
                    String markdown = new String(Files.readAllBytes(file.toPath()));
                    return RelayMessage.parseMarkdown(markdown);
                } catch (IOException e) {
                    Log.e("RelayStorage", "Failed to load message: " + e.getMessage());
                }
            }
        }
        return null;
    }

    /**
     * Get all messages in inbox.
     */
    public List<RelayMessage> getInboxMessages() {
        return loadMessagesFromDirectory(inboxDir);
    }

    /**
     * Get all messages in outbox.
     */
    public List<RelayMessage> getOutboxMessages() {
        return loadMessagesFromDirectory(outboxDir);
    }

    /**
     * Move message to sent folder (after delivery).
     */
    public void markAsDelivered(String messageId) {
        // Move from inbox/outbox to sent
        File inboxFile = new File(inboxDir, messageId + ".md");
        File outboxFile = new File(outboxDir, messageId + ".md");
        File sentFile = new File(sentDir, messageId + ".md");

        if (inboxFile.exists()) {
            inboxFile.renameTo(sentFile);
        } else if (outboxFile.exists()) {
            outboxFile.renameTo(sentFile);
        }
    }

    /**
     * Delete a message.
     */
    public void deleteMessage(String messageId) {
        new File(inboxDir, messageId + ".md").delete();
        new File(outboxDir, messageId + ".md").delete();
        new File(sentDir, messageId + ".md").delete();
    }

    /**
     * Get total disk space used by relay messages.
     */
    public long getTotalDiskUsageBytes() {
        return getDirSize(relayDir);
    }

    /**
     * Check if message already exists.
     */
    public boolean messageExists(String messageId) {
        return new File(inboxDir, messageId + ".md").exists() ||
               new File(outboxDir, messageId + ".md").exists() ||
               new File(sentDir, messageId + ".md").exists();
    }

    private List<RelayMessage> loadMessagesFromDirectory(File dir) {
        List<RelayMessage> messages = new ArrayList<>();
        File[] files = dir.listFiles((d, name) -> name.endsWith(".md"));

        if (files != null) {
            for (File file : files) {
                try {
                    String markdown = new String(Files.readAllBytes(file.toPath()));
                    RelayMessage msg = RelayMessage.parseMarkdown(markdown);
                    messages.add(msg);
                } catch (IOException e) {
                    Log.e("RelayStorage", "Failed to load: " + file.getName());
                }
            }
        }

        return messages;
    }

    private long getDirSize(File dir) {
        long size = 0;
        File[] files = dir.listFiles();
        if (files != null) {
            for (File file : files) {
                if (file.isDirectory()) {
                    size += getDirSize(file);
                } else {
                    size += file.length();
                }
            }
        }
        return size;
    }

    private File getDirectoryForLocation(MessageLocation location) {
        switch (location) {
            case INBOX:
                return inboxDir;
            case OUTBOX:
                return outboxDir;
            case SENT:
                return sentDir;
            default:
                return outboxDir;
        }
    }

    public enum MessageLocation {
        INBOX,   // Messages for this device
        OUTBOX,  // Messages to relay
        SENT     // Delivered messages
    }
}
```

---

## BLE Synchronization

### Protocol Overview

When two relay-enabled devices come into BLE range:

1. **Handshake**: Establish connection
2. **Inventory Exchange**: Share list of message IDs
3. **Gap Analysis**: Identify missing messages
4. **Transfer**: Send missing messages
5. **Acknowledgment**: Confirm receipt

### RelayMessageSync.java

```java
package offgrid.geogram.relay;

import android.bluetooth.BluetoothDevice;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

public class RelayMessageSync {

    private RelayStorage storage;
    private RelaySettings settings;

    public RelayMessageSync(RelayStorage storage, RelaySettings settings) {
        this.storage = storage;
        this.settings = settings;
    }

    /**
     * Start sync with a nearby relay device.
     */
    public void syncWithDevice(BluetoothDevice device) {
        if (!settings.isRelayEnabled()) {
            return; // Relay disabled
        }

        // 1. Exchange inventory
        List<String> ourMessageIds = getAllMessageIds();
        List<String> theirMessageIds = requestInventory(device);

        // 2. Gap analysis
        List<String> messagesToSend = findMissingMessages(theirMessageIds, ourMessageIds);
        List<String> messagesToReceive = findMissingMessages(ourMessageIds, theirMessageIds);

        // 3. Send missing messages to them
        for (String msgId : messagesToSend) {
            RelayMessage msg = storage.loadMessage(msgId);
            if (msg != null && !msg.isExpired()) {
                sendMessage(device, msg);
            }
        }

        // 4. Receive missing messages from them
        for (String msgId : messagesToReceive) {
            RelayMessage msg = receiveMessage(device, msgId);
            if (msg != null && msg.shouldAccept(settings)) {
                storeReceivedMessage(msg);
            }
        }
    }

    /**
     * Get list of all message IDs we're carrying.
     */
    private List<String> getAllMessageIds() {
        List<String> ids = new ArrayList<>();

        // Inbox messages
        for (RelayMessage msg : storage.getInboxMessages()) {
            ids.add(msg.getId());
        }

        // Outbox messages
        for (RelayMessage msg : storage.getOutboxMessages()) {
            ids.add(msg.getId());
        }

        return ids;
    }

    /**
     * Request inventory from remote device.
     */
    private List<String> requestInventory(BluetoothDevice device) {
        // Send BLE command: REQUEST_INVENTORY
        // Receive response: List of message IDs
        // TODO: Implement BLE protocol
        return new ArrayList<>();
    }

    /**
     * Find messages in list1 that are NOT in list2.
     */
    private List<String> findMissingMessages(List<String> list1, List<String> list2) {
        List<String> missing = new ArrayList<>();
        Set<String> set2 = new HashSet<>(list2);

        for (String id : list1) {
            if (!set2.contains(id)) {
                missing.add(id);
            }
        }

        return missing;
    }

    /**
     * Send a message to remote device via BLE.
     */
    private void sendMessage(BluetoothDevice device, RelayMessage message) {
        // Serialize message to markdown
        String markdown = message.toMarkdown();

        // Send via BLE
        // TODO: Implement BLE transfer protocol
        // Handle large messages (chunking if needed)
    }

    /**
     * Receive a message from remote device.
     */
    private RelayMessage receiveMessage(BluetoothDevice device, String messageId) {
        // Request message by ID from remote
        // Receive markdown content
        // Parse and return
        // TODO: Implement BLE receive protocol
        return null;
    }

    /**
     * Store a received message in appropriate location.
     */
    private void storeReceivedMessage(RelayMessage message) {
        // Check if message is for us
        String ourCallsign = getUserCallsign();

        if (message.getToCallsign().equals(ourCallsign)) {
            // Message for us - store in inbox
            storage.storeMessage(message, RelayStorage.MessageLocation.INBOX);
            notifyUserOfNewMessage(message);
        } else {
            // Message to relay - store in outbox
            storage.storeMessage(message, RelayStorage.MessageLocation.OUTBOX);
        }
    }

    private String getUserCallsign() {
        // Get from settings
        return ""; // TODO
    }

    private void notifyUserOfNewMessage(RelayMessage message) {
        // Show notification
        // TODO: Implement notification
    }
}
```

---

## Settings Integration

### Update RelayFragment.java

```java
public class RelayFragment extends Fragment {

    private RelaySettings relaySettings;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ...) {
        // ... existing code ...

        relaySettings = new RelaySettings(requireContext());

        // Load current settings
        switchEnable.setChecked(relaySettings.isRelayEnabled());
        int diskSpaceMB = relaySettings.getDiskSpaceLimitMB();
        seekBarDiskSpace.setProgress(findDiskSpaceIndex(diskSpaceMB));
        switchAutoAccept.setChecked(relaySettings.isAutoAcceptEnabled());

        // Save on change
        switchEnable.setOnCheckedChangeListener((buttonView, isChecked) -> {
            relaySettings.setRelayEnabled(isChecked);
            if (isChecked) {
                startRelayService();
            } else {
                stopRelayService();
            }
        });

        seekBarDiskSpace.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                updateDiskSpaceText(progress);
                int valueMB = DISK_SPACE_VALUES_MB[progress];
                relaySettings.setDiskSpaceLimitMB(valueMB);
            }
            // ...
        });

        switchAutoAccept.setOnCheckedChangeListener((buttonView, isChecked) -> {
            relaySettings.setAutoAcceptEnabled(isChecked);
        });

        spinnerMessageTypes.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                String[] types = {"text_only", "text_and_images", "everything"};
                relaySettings.setAcceptedMessageTypes(types[position]);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });

        return view;
    }

    private void startRelayService() {
        // Start background service for relay operations
        // TODO: Implement RelayService
    }

    private void stopRelayService() {
        // Stop relay service
    }
}
```

---

## Garbage Collection

### RelayGarbageCollector.java

```java
package offgrid.geogram.relay;

import java.util.List;

public class RelayGarbageCollector {

    private RelayStorage storage;
    private RelaySettings settings;

    public RelayGarbageCollector(RelayStorage storage, RelaySettings settings) {
        this.storage = storage;
        this.settings = settings;
    }

    /**
     * Run garbage collection (should be called periodically).
     */
    public void runGarbageCollection() {
        // 1. Delete expired messages
        deleteExpiredMessages();

        // 2. Check disk space
        long usedBytes = storage.getTotalDiskUsageBytes();
        long limitBytes = settings.getDiskSpaceLimitMB() * 1024L * 1024L;

        if (usedBytes > limitBytes) {
            // 3. Delete old low-priority messages
            deleteLowPriorityMessages(usedBytes - limitBytes);
        }
    }

    private void deleteExpiredMessages() {
        List<RelayMessage> inbox = storage.getInboxMessages();
        List<RelayMessage> outbox = storage.getOutboxMessages();

        for (RelayMessage msg : inbox) {
            if (msg.isExpired()) {
                storage.deleteMessage(msg.getId());
            }
        }

        for (RelayMessage msg : outbox) {
            if (msg.isExpired()) {
                storage.deleteMessage(msg.getId());
            }
        }
    }

    private void deleteLowPriorityMessages(long bytesToFree) {
        // Load all messages, sort by priority/age
        // Delete oldest low-priority messages until enough space freed
    }
}
```

---

## Implementation Phases

### Phase 1: Core Data Models & Storage (Week 1)
- [ ] Implement RelayMessage.java
- [ ] Implement RelayAttachment.java
- [ ] Implement RelayStorage.java
- [ ] Implement RelaySettings.java
- [ ] Unit tests for parsing/serialization

### Phase 2: Settings Integration (Week 1)
- [ ] Update RelayFragment.java with settings persistence
- [ ] Add background service for relay operations
- [ ] Test settings UI

### Phase 3: BLE Sync Protocol (Week 2)
- [ ] Implement RelayMessageSync.java
- [ ] BLE inventory exchange protocol
- [ ] Message transfer protocol
- [ ] Test with two devices

### Phase 4: Garbage Collection (Week 2)
- [ ] Implement RelayGarbageCollector.java
- [ ] Periodic cleanup scheduler
- [ ] Disk space monitoring

### Phase 5: UI & Notifications (Week 3)
- [ ] Inbox message list UI
- [ ] Message detail view
- [ ] New message notifications
- [ ] Delivery status indicators

### Phase 6: Testing & Polish (Week 3)
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] Battery usage optimization
- [ ] Documentation

---

## Testing Strategy

### Unit Tests
- Message parsing/serialization
- Message ID generation
- TTL expiration logic
- Disk space calculations

### Integration Tests
- BLE message exchange
- Storage operations
- Settings persistence
- Garbage collection

### Field Tests
- Multi-device relay chains
- Large message handling
- Battery impact
- Storage limits

---

**License**: Apache-2.0
**Copyright**: 2025 Geogram Contributors
