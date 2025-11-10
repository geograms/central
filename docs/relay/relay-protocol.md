# Geogram Relay Protocol Specification

## Overview

This document specifies the operational protocol for Geogram relay nodes, including message types, storage management, relay synchronization, geographic routing, and payment mechanisms.

## Message Format

Relay messages use the **Chat Message Format** for consistency with the Java server implementation. Messages are stored as markdown files using this structured syntax:

### Basic Structure

```markdown
# Message Group Title

> YYYY-MM-DD HH:MM_SS -- SENDER-CALLSIGN
Message content here.
Can span multiple lines with markdown formatting.

--> to: RECIPIENT-CALLSIGN
--> id: d4f2a8b1c3e5f7a9b2d4e6f8a0c2e4f6a8b0c2e4f6a8b0c2e4f6a8b0c2e4f6a8
--> type: private
--> priority: normal
--> ttl: 604800
--> signature: a7f3b9e1d2c4f6a8b0e2d4f6a8c0b2e4f6a8b0c2e4f6a8b0c2e4f6a8b0c2e4
```

### Format Elements

**Message Header**:
- `> YYYY-MM-DD HH:MM_SS -- SENDER-CALLSIGN`
- Timestamp format: `YYYY-MM-DD` (date), `HH:MM_SS` (time with underscore)
- Sender identified by callsign

**Message Content**:
- Follows the header (can be multi-line)
- Supports full markdown formatting
- Blank lines preserved

**Metadata Fields** (prefix `-->`):
- `to` - Recipient callsign or "ANY" for broadcast
- `id` - Unique message ID (64-char hex SHA-256)
- `type` - Message type (private, broadcast, news, group, emergency, commercial)
- `priority` - Priority level (urgent, normal, low)
- `ttl` - Time-to-live in seconds
- `relay-path` - List of relay nodes that forwarded this message
- `location` - Geographic coordinates
- `signature` - Cryptographic signature (64-char hex)
- Additional custom fields as needed

**Example with Reactions**:
```markdown
> 2025-11-09 22:05_30 -- BOB-W6ABC
Thanks for the update!

--> to: ALICE-K5XYZ
--> id: f3d8a2b1c4e5...
--> type: private
--> icon_like: CHARLIE, DAVE
--> signature: b4e7c9...
```

**Example with Attachments**:
```markdown
> 2025-11-09 22:10_15 -- ALICE-K5XYZ
Here are the photos from today's hike.

--> to: BOB-W6ABC
--> id: a8b7c6d5e4f3...
--> type: private
--> attachment-count: 2
--> attachment-total-size: 524288
--> signature: c9d8e7f6...

## ATTACHMENT: 1
- mime-type: image/jpeg
- filename: sunset.jpg
- size: 245678
- encoding: base64
- checksum: sha256:a1b2c3d4e5f6...

# ATTACHMENT_DATA_START
/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgIC...
# ATTACHMENT_DATA_END

## ATTACHMENT: 2
- mime-type: image/jpeg
- filename: landscape.jpg
- size: 278610
- encoding: base64
- checksum: sha256:b7c8d9e0f1g2...

# ATTACHMENT_DATA_START
/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgIC...
# ATTACHMENT_DATA_END
```

## Message ID Generation (NOSTR-Style)

### Unique Message Identifier

Each relay message MUST have a globally unique ID generated using NOSTR-style event ID calculation:

**Algorithm**:
```python
import hashlib
import json

def generate_message_id(from_npub, to_npub, timestamp, content):
    """
    Generate unique message ID using NOSTR event ID method.

    Format: [0, pubkey, created_at, kind, tags, content]
    Where:
      - 0: Reserved for future use
      - pubkey: Sender's public key (hex, not npub)
      - created_at: Unix timestamp (integer seconds)
      - kind: Message kind (relay-message = 30078)
      - tags: [["p", recipient_pubkey], ["t", "relay"]]
      - content: Message content (encrypted or plaintext)
    """

    # Decode npub to hex pubkey
    from_pubkey_hex = decode_npub_to_hex(from_npub)
    to_pubkey_hex = decode_npub_to_hex(to_npub)

    # Create serialization array
    event_data = [
        0,
        from_pubkey_hex,
        timestamp,  # Unix timestamp (integer seconds)
        30078,      # Kind for relay messages
        [
            ["p", to_pubkey_hex],
            ["t", "relay"]
        ],
        content     # Full message content
    ]

    # Serialize to JSON (compact, no whitespace)
    json_str = json.dumps(event_data, separators=(',', ':'), ensure_ascii=False)

    # SHA-256 hash
    message_id = hashlib.sha256(json_str.encode('utf-8')).hexdigest()

    return message_id
```

**Message ID Format**:
- **Length**: 64 characters (hex string)
- **Example**: `7f3b8c9d2e1a5f6c8b4d3e9a7c5b1f2d4e8a6c3b9f7d5e2a8c6b4f1d3e9a7c5b`

**Properties**:
- **Globally unique**: Collision probability negligible (2^256 space)
- **Deterministic**: Same inputs always produce same ID
- **Content-bound**: Changes to content invalidate ID
- **Timestamp-bound**: Prevents replay attacks
- **NOSTR-compatible**: Uses standard NOSTR event ID calculation

### Collision Handling

If a relay receives a message with an ID already in storage:
1. **Reject as duplicate**: Do not store or forward
2. **Log rejection**: Record duplicate attempt with timestamp
3. **Do not process**: Ignore all subsequent processing
4. **No error response**: Silent rejection (prevents amplification attacks)

**Exception**: If the duplicate has a valid deletion request, process the deletion.

## Message Types

Messages are categorized by type to enable filtering, prioritization, and routing decisions.

### Type Taxonomy

**Message Type Field**:
```markdown
type: <message-type>
```

**Standard Types**:

| Type | Code | Description | Example Use Case |
|------|------|-------------|------------------|
| **private** | `private` | Direct person-to-person message | "Meet at the park at 3pm" |
| **broadcast** | `broadcast` | Public announcement to all | "Emergency: shelter in place" |
| **news** | `news` | News article or bulletin | "Weather update: storm approaching" |
| **group** | `group` | Group conversation message | Team coordination, family chat |
| **emergency** | `emergency` | Emergency alert | Disaster warning, medical emergency |
| **commercial** | `commercial` | Business/advertisement | Product listing, service offer |
| **relay-receipt** | `relay-receipt` | Delivery/read receipt | Confirmation of message delivery |
| **payment-receipt** | `payment-receipt` | Payment confirmation receipt | Proof of payment for delivery service |

### Message Type Filtering

Relays and users can configure which message types to accept:

**Relay Configuration**:
```json
{
  "accepted-types": ["private", "broadcast", "news", "emergency"],
  "rejected-types": ["commercial"],
  "size-limits": {
    "private": 1048576,      // 1 MB
    "broadcast": 10240,      // 10 KB
    "news": 102400,          // 100 KB
    "commercial": 5120       // 5 KB
  }
}
```

**User Configuration** (via Relay settings panel):
- **Only text**: Reject messages with attachments
- **Text and images**: Accept text + image attachments
- **Everything**: Accept all message types and attachments

## Attachment Format

### Attachment Metadata

Each attachment in a relay message includes:

```markdown
## ATTACHMENT: <index>

- mime-type: image/jpeg
- filename: photo_2025-11-09.jpg
- size: 524288
- encoding: base64
- checksum: sha256:a1b2c3d4e5f6...

# ATTACHMENT_DATA_START
/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcG...
(base64-encoded binary data)
# ATTACHMENT_DATA_END
```

**Fields**:
- `mime-type`: IANA MIME type (e.g., `image/jpeg`, `audio/mpeg`, `video/mp4`)
- `filename`: Original filename for reconstruction
- `size`: File size in bytes
- `encoding`: Always `base64` for binary data
- `checksum`: SHA-256 hash of **decoded binary data** (format: `sha256:<hex>`)

### Supported Attachment Types

**Accepted MIME types**:
- **Images**: `image/jpeg`, `image/png`, `image/gif`, `image/webp`
- **Audio**: `audio/mpeg`, `audio/ogg`, `audio/wav`, `audio/aac`
- `video/mp4`, `video/webm`, `video/quicktime`

**Size Limits**:
- **Maximum per attachment**: 1 MB (1,048,576 bytes)
- **Maximum total per message**: 1 MB (sum of all attachments)
- **Maximum attachment count**: 10 per message

### Attachment Example

```markdown
> 2025-11-09 21:45_30 -- ALICE-K5XYZ
Bob, here are the photos from today's event.

--> to: BOB-W6ABC
--> id: 7f3b8c9d2e1a5f6c8b4d3e9a7c5b1f2d4e8a6c3b9f7d5e2a8c6b4f1d3e9a7c5b
--> type: private
--> from-npub: npub1alice...
--> to-npub: npub1bob...
--> attachment-count: 2
--> attachment-total-size: 768000
--> encrypted: true
--> signature: abc123...

## ATTACHMENT: 0
- mime-type: image/jpeg
- filename: sunrise.jpg
- size: 524288
- encoding: base64
- checksum: sha256:a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6...

# ATTACHMENT_DATA_START
/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcG...
# ATTACHMENT_DATA_END

## ATTACHMENT: 1
- mime-type: image/jpeg
- filename: sunset.jpg
- size: 243712
- encoding: base64
- checksum: sha256:b7c8d9e0f1g2h3i4j5k6l7m8n9o0p1q2r3s4t5u6v7w8x9y0z1a2...

# ATTACHMENT_DATA_START
/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAwUDAwMDAwYEBAMFBwYHBwcG...
# ATTACHMENT_DATA_END
```

### Attachment Verification

Recipients MUST verify each attachment:

```python
import hashlib
import base64

def verify_attachment(attachment):
    """Verify attachment checksum"""

    # Decode base64 data
    binary_data = base64.b64decode(attachment['data'])

    # Calculate SHA-256
    calculated_hash = hashlib.sha256(binary_data).hexdigest()

    # Extract expected hash
    checksum = attachment['checksum']  # "sha256:a1b2c3..."
    expected_hash = checksum.split(':', 1)[1]

    # Verify
    if calculated_hash != expected_hash:
        raise ValueError("Attachment checksum mismatch - corrupted or tampered")

    # Verify size
    if len(binary_data) != attachment['size']:
        raise ValueError("Attachment size mismatch")

    return binary_data
```

## Storage Management

### Storage Capacity

Relays configure storage limits via settings panel:
- **Minimum**: 100 MB
- **Maximum**: 10 GB
- **Logarithmic steps**: 100, 150, 200, 300, 500, 750, 1024, 1536, 2048, ..., 10240 MB

### Message File Format

Messages are stored as individual `.md` (markdown) files, one file per message group. This format enables:
- Easy archiving (zip files containing millions of messages)
- Human-readable message browsing
- Simple filtering and sorting by filename
- Platform-independent storage

**Filename Format**:
```
<callsign>_<YYYY-MM-DD>_<HH-MM>_<priority>_<sig6>.md
```

**Components**:
- `<callsign>`: Sender's callsign (sanitized, alphanumeric + hyphens only)
- `<YYYY-MM-DD>`: Date of first message (UTC)
- `<HH-MM>`: Time of first message in 24-hour format (UTC)
- `<priority>`: Priority level (`emergency`, `urgent`, `normal`, `low`, `bulk`)
- `<sig6>`: Last 6 characters of message signature (hex)

**Examples**:
```
ALICE-K5XYZ_2025-11-09_22-00_normal_a7c5b1.md
BOB-N7ABC_2025-11-09_22-05_urgent_3e9a7c.md
RELAY-K9ZZZ_2025-11-09_22-10_emergency_f2d4e8.md
CHARLIE-W5LMN_2025-11-09_22-15_low_6c3b9f.md
```

**Filename Generation**:
```python
import re
from datetime import datetime

def generate_message_filename(from_callsign, timestamp, priority, signature):
    """
    Generate standardized message filename

    Args:
        from_callsign: Sender's callsign
        timestamp: Unix timestamp (integer seconds) or datetime object
        priority: Message priority level
        signature: Message signature (hex string)

    Returns:
        Filename string in format: callsign_YYYY-MM-DD_HH-MM_priority_sig6.md
    """
    # Sanitize callsign: alphanumeric + hyphens only
    safe_callsign = re.sub(r'[^a-zA-Z0-9\-]', '', from_callsign)

    # Convert timestamp to datetime (UTC)
    if isinstance(timestamp, int) or isinstance(timestamp, float):
        dt = datetime.utcfromtimestamp(timestamp)
    elif isinstance(timestamp, datetime):
        dt = timestamp
    else:
        raise ValueError("timestamp must be int, float, or datetime")

    # Format date and time
    date_str = dt.strftime('%Y-%m-%d')  # YYYY-MM-DD
    time_str = dt.strftime('%H-%M')     # HH-MM

    # Validate priority
    valid_priorities = ['emergency', 'urgent', 'normal', 'low', 'bulk']
    if priority not in valid_priorities:
        priority = 'normal'

    # Extract last 6 characters of signature (hex)
    sig6 = signature[-6:] if len(signature) >= 6 else signature.ljust(6, '0')

    # Format filename
    filename = f"{safe_callsign}_{date_str}_{time_str}_{priority}_{sig6}.md"

    return filename
```

**Example Usage**:
```python
from datetime import datetime

# Message metadata
from_callsign = "ALICE-K5XYZ"
timestamp = 1699564801  # Unix timestamp: 2023-11-09 22:00:01 UTC
priority = "normal"
signature = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7c5b1"

# Generate filename
filename = generate_message_filename(from_callsign, timestamp, priority, signature)
# Result: "ALICE-K5XYZ_2023-11-09_22-00_normal_a7c5b1.md"

# Alternative: using datetime object
dt = datetime(2025, 11, 9, 22, 0, 1)
filename = generate_message_filename(from_callsign, dt, priority, signature)
# Result: "ALICE-K5XYZ_2025-11-09_22-00_normal_a7c5b1.md"

# Save message to file
with open(f"relay-storage/messages/{filename}", 'w') as f:
    f.write(message_markdown_content)
```

**File Organization**:
```
relay-storage/
├── messages/
│   ├── ALICE-K5XYZ_2025-11-09_22-00_normal_a7c5b1.md
│   ├── BOB-N7ABC_2025-11-09_22-05_urgent_3e9a7c.md
│   ├── CHARLIE-W5LMN_2025-11-09_22-10_emergency_f2d4e8.md
│   └── ...
├── archive/
│   ├── 2025-11/
│   │   ├── messages-2025-11-01.zip
│   │   ├── messages-2025-11-02.zip
│   │   └── ...
│   └── 2025-10/
│       └── ...
└── indices/
    ├── by-priority.idx
    ├── by-timestamp.idx
    └── by-grid.idx
```

**Archiving**:

Messages can be archived periodically into zip files:

```bash
# Archive messages from November 1st, 2025
cd relay-storage/messages
zip ../archive/2025-11/messages-2025-11-01.zip *_2025-11-01_*_*_*.md

# Archive entire month of October 2025
zip ../archive/2025-10/messages-2025-10.zip *_2025-10-*_*_*_*.md

# Clean archived messages
rm *_2025-11-01_*_*_*.md
rm *_2025-10-*_*_*_*.md
```

**Filtering by Filename**:

```bash
# Find all emergency messages
ls relay-storage/messages/*_*_*_emergency_*.md

# Find all messages from ALICE
ls relay-storage/messages/ALICE-*_*_*_*_*.md

# Find all messages from November 9th, 2025
ls relay-storage/messages/*_2025-11-09_*_*_*.md

# Find messages between 22:00 and 23:00 on November 9th
ls relay-storage/messages/*_2025-11-09_22-*_*_*.md

# Find urgent and emergency messages
ls relay-storage/messages/*_*_*_{urgent,emergency}_*.md

# Find all messages from November 2025
ls relay-storage/messages/*_2025-11-*_*_*_*.md

# Find messages from specific hour across all dates
ls relay-storage/messages/*_*_14-*_*_*.md  # All 14:00-14:59 messages
```

**Benefits**:
- **Human-readable**: Timestamps are immediately understandable (2025-11-09_22-00)
- **Archivable**: Compress millions of messages into zip archives by date
- **Portable**: Copy/move message files across devices easily
- **Browsable**: Open and read messages in any text editor
- **Filterable**: Use standard shell tools (ls, grep) to find messages by date/time
- **Sortable**: Lexicographic sort gives chronological order
- **Resilient**: No database corruption issues
- **Date-based organization**: Easy to archive by day, month, or year
- **Time-range queries**: Simple wildcard patterns for time filtering

### Purge Algorithm

When storage reaches capacity, relays delete messages in this priority order:

**Priority 1: Stale Messages**
```python
def find_stale_messages(storage, current_time):
    """
    Stale = expired TTL or past expiration date
    """
    stale = []
    for msg in storage:
        if msg['expires'] < current_time:
            stale.append(msg)
        elif (current_time - msg['timestamp']) > msg['ttl']:
            stale.append(msg)
    return stale
```

**Priority 2: Delivered Messages (Old)**
```python
def find_old_delivered_messages(storage, current_time, age_threshold_months=3):
    """
    Delivered messages older than threshold (default 3 months)
    with no recent updates
    """
    threshold_seconds = age_threshold_months * 30 * 24 * 60 * 60
    old_delivered = []

    for msg in storage:
        # Check if delivered (has delivery receipt)
        if has_delivery_receipt(msg):
            delivery_time = get_delivery_timestamp(msg)
            age = current_time - delivery_time

            # No updates in 3+ months
            last_update = get_last_update_timestamp(msg)
            if age > threshold_seconds and (current_time - last_update) > threshold_seconds:
                old_delivered.append(msg)

    return old_delivered
```

**Priority 3: Oldest Undelivered Messages**
```python
def find_oldest_undelivered(storage, current_time):
    """
    Undelivered messages sorted by age (oldest first)
    """
    undelivered = []
    for msg in storage:
        if not has_delivery_receipt(msg):
            undelivered.append((msg['timestamp'], msg))

    # Sort by timestamp (oldest first)
    undelivered.sort(key=lambda x: x[0])
    return [msg for _, msg in undelivered]
```

**Purge Execution**:
```python
def purge_to_target_size(storage, target_size_bytes, current_size_bytes):
    """
    Delete messages until storage is below target
    """
    bytes_to_free = current_size_bytes - target_size_bytes
    freed = 0

    # Step 1: Delete stale messages
    stale = find_stale_messages(storage, time.time())
    for msg in stale:
        freed += delete_message(storage, msg['id'])
        if freed >= bytes_to_free:
            return

    # Step 2: Delete old delivered messages
    old_delivered = find_old_delivered_messages(storage, time.time(), age_threshold_months=3)
    for msg in old_delivered:
        freed += delete_message(storage, msg['id'])
        if freed >= bytes_to_free:
            return

    # Step 3: Delete oldest undelivered (least likely to be delivered)
    oldest = find_oldest_undelivered(storage, time.time())
    for msg in oldest:
        freed += delete_message(storage, msg['id'])
        if freed >= bytes_to_free:
            return
```

### Spam Protection

**Rate Limiting**:

Relays enforce per-sender daily message limits:

```python
class SpamProtection:
    def __init__(self):
        self.daily_limit = 5000  # Messages per sender per day
        self.sender_counts = {}  # {npub: [(timestamp, count), ...]}
        self.admin_override = False  # Admin can disable limits

    def check_rate_limit(self, from_npub, current_time):
        """
        Check if sender exceeded daily limit
        Returns: (allowed: bool, current_count: int, limit: int)
        """
        if self.admin_override:
            return (True, 0, self.daily_limit)

        # Clean old entries (older than 24 hours)
        cutoff = current_time - (24 * 60 * 60)
        if from_npub in self.sender_counts:
            self.sender_counts[from_npub] = [
                (ts, cnt) for ts, cnt in self.sender_counts[from_npub]
                if ts > cutoff
            ]

        # Count messages in last 24 hours
        count = sum(cnt for _, cnt in self.sender_counts.get(from_npub, []))

        if count >= self.daily_limit:
            return (False, count, self.daily_limit)

        # Record this message
        if from_npub not in self.sender_counts:
            self.sender_counts[from_npub] = []
        self.sender_counts[from_npub].append((current_time, 1))

        return (True, count + 1, self.daily_limit)
```

**Spam Detection Heuristics**:

```python
def is_likely_spam(message):
    """
    Heuristic spam detection
    """
    spam_indicators = 0

    # Check 1: Excessive recipients (mass broadcast)
    if message.get('recipient-count', 1) > 100:
        spam_indicators += 1

    # Check 2: Commercial type without payment
    if message.get('type') == 'commercial' and not message.get('paid-delivery'):
        spam_indicators += 1

    # Check 3: Very low priority
    if message.get('priority') == 'bulk':
        spam_indicators += 1

    # Check 4: Duplicate content (content hash seen recently)
    content_hash = message.get('content-hash')
    if content_hash and is_recent_duplicate_content(content_hash):
        spam_indicators += 1

    # Threshold: 2 or more indicators = likely spam
    return spam_indicators >= 2
```

**Admin Override**:

Relay administrators can disable spam protection via settings:
```json
{
  "spam-protection": {
    "enabled": true,
    "daily-limit-per-sender": 5000,
    "admin-override": false
  }
}
```

## First Arrival, First Receipt

### Duplicate Message Handling

When a message arrives via multiple relay paths:

**Scenario**: Message `msg_abc123` arrives via Relay A and Relay B to destination.

```python
def handle_incoming_message(message, relay_source):
    """
    Process incoming relay message with First Arrival, First Receipt logic
    """
    msg_id = message['id']

    # Check if already received
    existing = storage.get_message(msg_id)

    if existing:
        # Already received - reject duplicate
        log_duplicate_rejection(msg_id, relay_source)
        return "DUPLICATE_REJECTED"

    # Verify signature
    if not verify_message_signature(message):
        log_verification_failure(msg_id, message['from-npub'])
        return "SIGNATURE_INVALID"

    # First arrival - accept and store
    storage.store_message(message)

    # Generate delivery receipt (if requested)
    if 'delivery' in message.get('receipts', ''):
        receipt = generate_delivery_receipt(message, relay_source)
        queue_receipt_for_return(receipt)

    return "ACCEPTED"
```

### Delivery Receipt as Proof

**First Successful Delivery**:

Only the relay that successfully delivered the message first can provide the authentic delivery receipt:

```markdown
> 2025-11-09 22:25_47 -- BOB-W6ABC
Receipt: Message delivered successfully.

--> to: ALICE-K5XYZ
--> id: receipt_7f3b8c9d...
--> type: relay-receipt
--> from-npub: npub1bob...
--> to-npub: npub1alice...
--> original-message-id: 7f3b8c9d2e1a5f6c8b4d3e9a7c5b1f2d4e8a6c3b9f7d5e2a8c6b4f1d3e9a7c5b
--> delivery-timestamp: 2025-11-09T22:25:47Z
--> delivered-by: npub1relayC...
--> delivered-by-callsign: RELAY-N0QST
--> forward-path: [npub1relayA..., npub1relayB..., npub1relayC...]
--> hop-count: 3
--> signature: bob_delivery_receipt_sig...
```

**Key Properties**:
- **Signature**: Signed by recipient's nsec (only recipient can generate)
- **delivered-by**: The relay that completed delivery
- **forward-path**: Complete chain of relay npubs
- **Unforgeable**: Relay carriers cannot claim false delivery (wrong signature)

**Verification**:
```python
def verify_delivery_receipt(receipt, original_message):
    """
    Verify delivery receipt is authentic
    """
    # Check recipient signature
    recipient_npub = original_message['to-npub']
    if receipt['from-npub'] != recipient_npub:
        return False, "Receipt not from intended recipient"

    # Verify Schnorr signature
    receipt_data = f"DELIVERED\n{receipt['original-message-id']}\n{receipt['timestamp']}"
    receipt_hash = hashlib.sha256(receipt_data.encode('utf-8')).digest()

    pubkey = decode_npub(recipient_npub)
    if not schnorr_verify(receipt_hash, pubkey, bytes.fromhex(receipt['signature'])):
        return False, "Invalid receipt signature"

    return True, "Receipt authentic"
```

**Competing Claims**:

If multiple relays claim first delivery:
- Only the receipt with the recipient's valid signature proves delivery
- Relay carriers cannot forge recipient signatures
- First authentic receipt timestamp determines first delivery
- Subsequent receipts are duplicates (recipient accepted message only once)

## Relay Discovery and Synchronization

### Discovery Handshake

When two relay-enabled devices come within BLE range:

**Step 1: Beacon Advertising**

Both devices advertise relay capability via BLE beacon:

```
Offset | Length | Field           | Value
-------|--------|-----------------|---------------------------
0      | 2      | Magic           | 0x47 0x45 ("GE")
2      | 6      | Device ID       | Short device identifier
8      | 1      | Device Type     | 0x03 = Relay node
9      | 1      | Flags           | Bit 0: Relay enabled (1)
10     | 4      | Message Count   | Number of messages in storage
14     | 4      | Storage Free    | Free storage in KB
18     | 2      | CRC16           | Checksum
```

**Step 2: Handshake Initiation**

Device A sends handshake request:

```
>RELAY_HELLO:<NPUB>:<GRID>:<MSG_COUNT>
```

Example:
```
>RELAY_HELLO:npub1alice...:5M0K9P3R:4523
```

Fields:
- `NPUB`: Relay's NOSTR public key
- `GRID`: Current geographic grid code (8 chars, see Geographic Routing)
- `MSG_COUNT`: Number of messages in storage

**Step 3: Handshake Response**

Device B responds:

```
>RELAY_ACK:<NPUB>:<GRID>:<MSG_COUNT>
```

**Step 4: Capabilities Exchange**

Both devices exchange relay capabilities:

```
>RELAY_CAPS:<ACCEPTED_TYPES>:<GRID_RADIUS>:<MAX_SIZE>
```

Example:
```
>RELAY_CAPS:private,broadcast,news,emergency:50:1024
```

Fields:
- `ACCEPTED_TYPES`: Comma-separated message types
- `GRID_RADIUS`: Radius in grid cells for geographic filtering
- `MAX_SIZE`: Maximum message size in KB

### Inventory Exchange

**Step 5: Inventory Request**

Device A requests message inventory from Device B:

```
>RELAY_INV_REQ:<GRID_FILTER>:<TYPE_FILTER>:<LIMIT>
```

Example:
```
>RELAY_INV_REQ:5M0K*:private,emergency:100
```

Fields:
- `GRID_FILTER`: Geographic filter (wildcards supported)
  - `5M0K*`: All messages in grids starting with "5M0K"
  - `*`: All grids (no filter)
- `TYPE_FILTER`: Message types requested
- `LIMIT`: Maximum messages to list

**Step 6: Inventory Response**

Device B responds with message list:

```
>RELAY_INV:<MSG_ID>:<SIZE>:<PRIORITY>:<GRID>
```

Multiple inventory packets sent (one per message):

```
>RELAY_INV:7f3b8c9d...:45678:normal:5M0K9P3R
>RELAY_INV:8a4c7d2f...:12345:urgent:5M0K9P4S
>RELAY_INV:3f9e6b1a...:98765:normal:5M0L8O2Q
```

**Step 7: Sync Request**

Device A requests specific messages:

```
>RELAY_SYNC:<MSG_ID_LIST>
```

Example:
```
>RELAY_SYNC:7f3b8c9d...,3f9e6b1a...
```

Comma-separated list of message IDs (up to 10 per request).

**Step 8: Message Transfer**

Device B transmits requested messages using multi-packet BLE protocol (see message-ble.md).

Messages transferred in priority order:
1. **emergency** priority
2. **urgent** priority
3. **normal** priority
4. **low** priority

Within same priority, oldest messages first (FIFO).

## Relay Message Selection Criteria

When a relay carrier discovers another relay, it must decide which messages to pick up based on configurable criteria. This section documents the decision-making process from the carrier's perspective.

### Relay Carrier Profile

Each relay carrier maintains a profile defining its message selection preferences:

```json
{
  "relay-carrier-id": "npub1carrier123...",
  "relay-callsign": "CARRIER-K9XYZ",
  "selection-criteria": {
    "grid-targets": ["5M0K*", "5M1L*", "5M2M*"],
    "grid-radius": 20,
    "accepted-types": ["private", "emergency", "news"],
    "rejected-types": ["commercial"],
    "min-priority": "normal",
    "max-message-size": 524288,
    "max-total-pickup": 104857600,
    "time-range": {
      "min-age-hours": 0,
      "max-age-hours": 168
    },
    "payment-filter": {
      "require-payment": false,
      "min-payment-amount": 0,
      "accepted-currencies": ["sats", "xmr", "usd"]
    }
  },
  "current-storage": {
    "used-bytes": 45678901,
    "available-bytes": 54321099,
    "message-count": 4523
  },
  "routing-preferences": {
    "prefer-paid-deliveries": true,
    "prefer-emergency": true,
    "avoid-commercial": true
  }
}
```

### Selection Criteria Breakdown

#### 1. Geographic Filtering

**Grid Targets**:
```json
"grid-targets": ["5M0K*", "5M1L*", "5M2M*"]
```

Specifies which geographic grids the carrier is interested in:
- Exact match: `"5M0K9P3R"` (specific 8-character grid)
- Wildcard prefix: `"5M0K*"` (all grids starting with 5M0K)
- Wildcard: `"*"` (all grids, no geographic filter)

**Grid Radius**:
```json
"grid-radius": 20
```

Accept messages within N grid cells of target grids (using Chebyshev distance).

**Example**:
```python
def matches_grid_criteria(message, carrier_profile):
    """
    Check if message destination matches carrier's grid criteria
    """
    dest_grid = message.get('destination-grid')
    if not dest_grid:
        return False  # No destination grid = reject

    grid_targets = carrier_profile['selection-criteria']['grid-targets']
    grid_radius = carrier_profile['selection-criteria']['grid-radius']

    # Check if any target matches
    for target in grid_targets:
        if target == '*':
            return True  # Accept all grids

        # Wildcard match
        if target.endswith('*'):
            prefix = target[:-1]
            if dest_grid.startswith(prefix):
                return True

        # Exact match with radius
        if is_within_radius(dest_grid, target, grid_radius):
            return True

    return False
```

#### 2. Message Type Filtering

**Accepted Types**:
```json
"accepted-types": ["private", "emergency", "news"]
```

Only pick up messages of these types.

**Rejected Types**:
```json
"rejected-types": ["commercial"]
```

Explicitly reject these types (takes precedence over accepted).

**Example**:
```python
def matches_type_criteria(message, carrier_profile):
    """
    Check if message type is acceptable
    """
    msg_type = message.get('type', 'private')
    criteria = carrier_profile['selection-criteria']

    # Check rejection list first
    if msg_type in criteria.get('rejected-types', []):
        return False

    # Check acceptance list
    if msg_type in criteria.get('accepted-types', []):
        return True

    # If accepted-types is empty, accept all (except rejected)
    if not criteria.get('accepted-types'):
        return True

    return False
```

#### 3. Priority Filtering

**Minimum Priority**:
```json
"min-priority": "normal"
```

Only accept messages at or above this priority level.

**Priority Hierarchy**:
```
emergency > urgent > normal > low > bulk
```

**Example**:
```python
def matches_priority_criteria(message, carrier_profile):
    """
    Check if message priority meets minimum threshold
    """
    priority_levels = {
        'emergency': 5,
        'urgent': 4,
        'normal': 3,
        'low': 2,
        'bulk': 1
    }

    msg_priority = message.get('priority', 'normal')
    min_priority = carrier_profile['selection-criteria'].get('min-priority', 'normal')

    msg_level = priority_levels.get(msg_priority, 3)
    min_level = priority_levels.get(min_priority, 3)

    return msg_level >= min_level
```

#### 4. Size Filtering

**Maximum Message Size**:
```json
"max-message-size": 524288  // 512 KB
```

Reject messages larger than this threshold.

**Maximum Total Pickup**:
```json
"max-total-pickup": 104857600  // 100 MB
```

Stop picking up messages once this total size is reached in current sync session.

**Example**:
```python
def matches_size_criteria(message, carrier_profile, current_pickup_size):
    """
    Check if message size is acceptable
    """
    msg_size = message.get('size', 0)
    max_msg_size = carrier_profile['selection-criteria']['max-message-size']
    max_total = carrier_profile['selection-criteria']['max-total-pickup']

    # Check individual message size
    if msg_size > max_msg_size:
        return False, "Message too large"

    # Check total pickup size
    if current_pickup_size + msg_size > max_total:
        return False, "Pickup quota exceeded"

    return True, "Size acceptable"
```

#### 5. Time Range Filtering

**Message Age Constraints**:
```json
"time-range": {
  "min-age-hours": 0,      // Don't accept messages newer than this
  "max-age-hours": 168     // Don't accept messages older than 7 days
}
```

**Example**:
```python
import time

def matches_time_criteria(message, carrier_profile):
    """
    Check if message age is within acceptable range
    """
    msg_timestamp = message.get('timestamp')
    current_time = time.time()

    age_seconds = current_time - msg_timestamp
    age_hours = age_seconds / 3600

    time_range = carrier_profile['selection-criteria'].get('time-range', {})
    min_age = time_range.get('min-age-hours', 0)
    max_age = time_range.get('max-age-hours', 168)

    if age_hours < min_age:
        return False, "Message too new"

    if age_hours > max_age:
        return False, "Message too old"

    return True, "Age acceptable"
```

#### 6. Payment Filtering

**Payment Requirements**:
```json
"payment-filter": {
  "require-payment": true,           // Only accept paid deliveries
  "min-payment-amount": 5000,        // Minimum payment threshold
  "accepted-currencies": ["sats", "xmr", "usd"]
}
```

**Example**:
```python
def matches_payment_criteria(message, carrier_profile):
    """
    Check if message meets payment requirements
    """
    payment_filter = carrier_profile['selection-criteria'].get('payment-filter', {})

    # Check if payment required
    if payment_filter.get('require-payment', False):
        if not message.get('paid-delivery', False):
            return False, "Payment required but not offered"

        # Check currency
        msg_currency = message.get('payment-currency')
        accepted_currencies = payment_filter.get('accepted-currencies', [])
        if msg_currency not in accepted_currencies:
            return False, f"Currency {msg_currency} not accepted"

        # Check amount
        msg_amount = message.get('payment-amount', 0)
        min_amount = payment_filter.get('min-payment-amount', 0)
        if msg_amount < min_amount:
            return False, f"Payment amount too low: {msg_amount} < {min_amount}"

    return True, "Payment acceptable"
```

### Complete Message Selection Algorithm

```python
def select_messages_from_relay(source_relay, carrier_profile):
    """
    Complete algorithm for selecting messages to pick up from another relay

    Returns: List of message IDs to request for transfer
    """
    selected_messages = []
    total_size = 0
    max_total = carrier_profile['selection-criteria']['max-total-pickup']

    # Step 1: Request inventory from source relay
    inventory = request_inventory_from_relay(
        source_relay,
        grid_filter=carrier_profile['selection-criteria']['grid-targets'],
        type_filter=carrier_profile['selection-criteria']['accepted-types'],
        limit=1000  # Request up to 1000 message summaries
    )

    # Step 2: Apply all selection criteria
    for msg_summary in inventory:
        # Check if already have this message
        if already_have_message(msg_summary['id']):
            log_debug(f"Already have message {msg_summary['id']}, skipping")
            continue

        # Apply filters
        if not matches_grid_criteria(msg_summary, carrier_profile):
            log_debug(f"Message {msg_summary['id']} rejected: grid mismatch")
            continue

        if not matches_type_criteria(msg_summary, carrier_profile):
            log_debug(f"Message {msg_summary['id']} rejected: type not accepted")
            continue

        if not matches_priority_criteria(msg_summary, carrier_profile):
            log_debug(f"Message {msg_summary['id']} rejected: priority too low")
            continue

        size_ok, size_reason = matches_size_criteria(msg_summary, carrier_profile, total_size)
        if not size_ok:
            if "quota exceeded" in size_reason:
                log_info(f"Pickup quota reached at {total_size} bytes")
                break  # Stop picking up messages
            else:
                log_debug(f"Message {msg_summary['id']} rejected: {size_reason}")
                continue

        time_ok, time_reason = matches_time_criteria(msg_summary, carrier_profile)
        if not time_ok:
            log_debug(f"Message {msg_summary['id']} rejected: {time_reason}")
            continue

        payment_ok, payment_reason = matches_payment_criteria(msg_summary, carrier_profile)
        if not payment_ok:
            log_debug(f"Message {msg_summary['id']} rejected: {payment_reason}")
            continue

        # All criteria passed - select this message
        selected_messages.append(msg_summary['id'])
        total_size += msg_summary['size']
        log_info(f"Selected message {msg_summary['id']}: {msg_summary['size']} bytes")

    # Step 3: Prioritize selected messages
    prioritized = prioritize_selected_messages(selected_messages, inventory, carrier_profile)

    log_info(f"Selected {len(prioritized)} messages, total size: {total_size} bytes")

    return prioritized


def prioritize_selected_messages(selected_ids, inventory, carrier_profile):
    """
    Sort selected messages by carrier preferences
    """
    preferences = carrier_profile.get('routing-preferences', {})

    # Build list of (message_id, score) tuples
    scored_messages = []
    for msg_id in selected_ids:
        msg = next(m for m in inventory if m['id'] == msg_id)
        score = calculate_message_score(msg, preferences)
        scored_messages.append((msg_id, score))

    # Sort by score (descending)
    scored_messages.sort(key=lambda x: x[1], reverse=True)

    return [msg_id for msg_id, _ in scored_messages]


def calculate_message_score(message, preferences):
    """
    Calculate priority score for message based on carrier preferences
    """
    score = 0

    # Priority scoring
    priority_scores = {
        'emergency': 1000,
        'urgent': 500,
        'normal': 100,
        'low': 50,
        'bulk': 10
    }
    score += priority_scores.get(message.get('priority', 'normal'), 100)

    # Paid delivery bonus
    if preferences.get('prefer-paid-deliveries', False) and message.get('paid-delivery', False):
        payment_amount = message.get('payment-amount', 0)
        score += payment_amount  # Higher payment = higher score

    # Emergency preference bonus
    if preferences.get('prefer-emergency', True) and message.get('priority') == 'emergency':
        score += 2000

    # Commercial penalty
    if preferences.get('avoid-commercial', True) and message.get('type') == 'commercial':
        score -= 500

    # Age penalty (older messages get lower score)
    age_hours = (time.time() - message.get('timestamp', 0)) / 3600
    age_penalty = int(age_hours / 24)  # 1 point penalty per day
    score -= age_penalty

    return score
```

### Relay Discovery and Selection Workflow

**Complete workflow from carrier perspective:**

```
1. Relay Carrier scans BLE and detects another relay
   ↓
2. Reads relay beacon (message count, storage free)
   ↓
3. Initiates handshake: RELAY_HELLO
   ↓
4. Receives handshake response: RELAY_ACK
   ↓
5. Exchanges capabilities: RELAY_CAPS
   ↓
6. Requests inventory with filters: RELAY_INV_REQ
   ↓
7. Receives inventory list: RELAY_INV (multiple packets)
   ↓
8. Applies selection criteria to filter messages
   ↓
9. Prioritizes selected messages by preference scoring
   ↓
10. Requests top N messages: RELAY_SYNC
   ↓
11. Receives messages via multi-packet BLE transfer
   ↓
12. Verifies signatures and stores accepted messages
   ↓
13. Updates carrier statistics and continues scanning
```

### Example Scenarios

#### Scenario 1: Professional Courier (NYC → Boston Route)

**Carrier Profile**:
```json
{
  "relay-callsign": "COURIER-PRO",
  "selection-criteria": {
    "grid-targets": ["5M1L*"],        // Boston area only
    "grid-radius": 30,
    "accepted-types": ["private", "commercial", "emergency"],
    "min-priority": "normal",
    "max-message-size": 1048576,      // 1 MB
    "max-total-pickup": 524288000,    // 500 MB
    "payment-filter": {
      "require-payment": true,
      "min-payment-amount": 1000,     // Minimum 1000 sats per delivery
      "accepted-currencies": ["sats", "xmr"]
    }
  },
  "routing-preferences": {
    "prefer-paid-deliveries": true,
    "prefer-emergency": true
  }
}
```

**Selection Result**:
- Picks up only paid deliveries to Boston area
- Minimum 1000 sats payment
- Prefers emergency messages (higher score)
- Can carry up to 500 MB per trip

#### Scenario 2: Emergency Services Relay

**Carrier Profile**:
```json
{
  "relay-callsign": "EMERGENCY-RELAY-01",
  "selection-criteria": {
    "grid-targets": ["*"],              // All destinations
    "accepted-types": ["emergency"],    // Emergency only
    "min-priority": "emergency",
    "max-message-size": 10485760,       // 10 MB
    "max-total-pickup": 1073741824,     // 1 GB
    "time-range": {
      "max-age-hours": 24               // Only fresh emergencies
    },
    "payment-filter": {
      "require-payment": false          // Free emergency service
    }
  },
  "routing-preferences": {
    "prefer-emergency": true,
    "prefer-paid-deliveries": false
  }
}
```

**Selection Result**:
- Only emergency messages
- Any destination
- Recent messages only (<24 hours)
- No payment required
- Large capacity for emergencies

#### Scenario 3: Community News Relay

**Carrier Profile**:
```json
{
  "relay-callsign": "NEWS-RELAY-COMMUNITY",
  "selection-criteria": {
    "grid-targets": ["5M0K*", "5M0L*"], // NYC metro area
    "grid-radius": 50,
    "accepted-types": ["news", "broadcast"],
    "rejected-types": ["commercial"],
    "min-priority": "low",              // Accept all priorities
    "max-message-size": 204800,         // 200 KB (text/images only)
    "max-total-pickup": 52428800,       // 50 MB
    "time-range": {
      "max-age-hours": 72               // 3-day old news acceptable
    }
  },
  "routing-preferences": {
    "prefer-paid-deliveries": false,
    "avoid-commercial": true
  }
}
```

**Selection Result**:
- News and public broadcasts only
- NYC metro area
- No commercial messages
- Small messages (articles, not videos)
- Free community service

#### Scenario 4: Opportunistic General Relay

**Carrier Profile**:
```json
{
  "relay-callsign": "RELAY-GENERAL-K5XYZ",
  "selection-criteria": {
    "grid-targets": ["*"],              // Anywhere
    "accepted-types": [],               // All types (empty = accept all)
    "rejected-types": ["commercial"],   // Except commercial
    "min-priority": "low",
    "max-message-size": 524288,         // 512 KB
    "max-total-pickup": 104857600,      // 100 MB
    "time-range": {
      "max-age-hours": 168              // 1 week
    }
  },
  "routing-preferences": {
    "prefer-paid-deliveries": true,     // Prefer paid, but accept free
    "prefer-emergency": true
  }
}
```

**Selection Result**:
- Accept most messages
- Prioritize paid and emergency
- General community service
- Moderate capacity

### Runtime Configuration Updates

Carriers can update their selection criteria during operation:

**Via BLE Command**:
```
>RELAY_UPDATE_CRITERIA:<JSON_BASE64>
```

**Example**:
```python
import base64
import json

# Update criteria
new_criteria = {
    "grid-targets": ["5M2M*"],  # Switch to Philadelphia
    "min-priority": "urgent"     # Raise priority threshold
}

# Encode as base64
json_str = json.dumps(new_criteria)
encoded = base64.b64encode(json_str.encode('utf-8')).decode('utf-8')

# Send command
send_ble_command(f">RELAY_UPDATE_CRITERIA:{encoded}")
```

### Statistics and Reporting

Carriers track selection statistics:

```json
{
  "selection-stats": {
    "total-relays-discovered": 45,
    "total-inventories-reviewed": 45,
    "total-messages-considered": 12450,
    "total-messages-selected": 567,
    "total-messages-transferred": 545,
    "total-bytes-transferred": 98765432,
    "rejection-reasons": {
      "grid-mismatch": 8234,
      "type-rejected": 1245,
      "priority-too-low": 1023,
      "size-too-large": 234,
      "age-too-old": 567,
      "quota-exceeded": 22,
      "payment-insufficient": 340,
      "already-have": 240
    },
    "avg-selection-time-ms": 45,
    "last-sync-timestamp": 1699564801
  }
}
```

These statistics help carriers optimize their selection criteria over time.

### Sync Optimization

**Bloom Filter Optimization**:

For large message stores, use Bloom filters to reduce inventory exchange:

```python
import mmh3  # MurmurHash3

class BloomFilter:
    def __init__(self, size=1024, hash_count=3):
        self.size = size
        self.hash_count = hash_count
        self.bits = bytearray(size)

    def add(self, msg_id):
        for i in range(self.hash_count):
            pos = mmh3.hash(msg_id, i) % (self.size * 8)
            byte_idx = pos // 8
            bit_idx = pos % 8
            self.bits[byte_idx] |= (1 << bit_idx)

    def contains(self, msg_id):
        for i in range(self.hash_count):
            pos = mmh3.hash(msg_id, i) % (self.size * 8)
            byte_idx = pos // 8
            bit_idx = pos % 8
            if not (self.bits[byte_idx] & (1 << bit_idx)):
                return False
        return True
```

**Bloom filter exchange**:
```
>RELAY_BLOOM:<BASE64_ENCODED_FILTER>
```

Relays can quickly check which messages the other device likely has.

## Geographic Grid Routing

### Grid System

Geogram uses a 4-character base-36 geocode per axis:

**Format**: `LLLL-LLLL` or `LLLLLLLL` (8 characters total)
- First 4 chars: Latitude code
- Last 4 chars: Longitude code

**Example**: `5M0K-9P3R` or `5M0K9P3R`

**Resolution**:
- Latitude cell: ~11.93 meters
- Longitude cell: ~23.86 meters (at equator)
- Total cells: 1,679,616 per axis (36^4)

**Grid Code Examples**:
```
0000-0000 = South Pole, Antimeridian
5M0K-9P3R = New York City area
ZZZZ-ZZZZ = North Pole, Antimeridian
```

### Message Grid Assignment

Each relay message includes destination grid:

```markdown
> 2025-11-09 22:00_00 -- ALICE-K5XYZ
Message content here.

--> to: BOB-W6ABC
--> destination-grid: 5M0K9P3R
--> destination-grid-radius: 5
```

Fields:
- `destination-grid`: Target geographic area (8-char code)
- `destination-grid-radius`: Delivery radius in grid cells

**Radius Calculation**:
```python
def is_within_radius(destination_grid, current_grid, radius_cells):
    """
    Check if current grid is within radius of destination
    """
    dest_lat_code = destination_grid[0:4]
    dest_lon_code = destination_grid[4:8]
    curr_lat_code = current_grid[0:4]
    curr_lon_code = current_grid[4:8]

    # Decode to indices
    dest_lat_idx = grid_code_to_index(dest_lat_code)
    dest_lon_idx = grid_code_to_index(dest_lon_code)
    curr_lat_idx = grid_code_to_index(curr_lat_code)
    curr_lon_idx = grid_code_to_index(curr_lon_code)

    # Calculate grid distance (Chebyshev distance)
    lat_dist = abs(dest_lat_idx - curr_lat_idx)
    lon_dist = abs(dest_lon_idx - curr_lon_idx)

    max_dist = max(lat_dist, lon_dist)

    return max_dist <= radius_cells
```

### Relay Carrier Grid Filtering

Relay carriers specify which grids they're interested in:

**Wildcard Patterns**:
```
5M0K*    # All grids starting with 5M0K (New York region)
5M0K9P*  # Finer grid subset
*        # All grids (no filter)
```

**Multiple Grid Targets**:
```json
{
  "grid-targets": [
    "5M0K9P3R",  // NYC
    "5M1L8O4Q",  // Boston
    "5M2M7N5P"   // Philadelphia
  ],
  "grid-radius": 10  // Accept messages within 10 cells of targets
}
```

**Runtime Configuration**:

Relay carriers can update grid preferences during operation:

```
>RELAY_SET_GRIDS:5M0K*,5M1L*:15
```

Sets accepted grids to `5M0K*` and `5M1L*` with radius 15 cells.

### Grid-Based Routing Strategy

**Scenario**: Relay carrier traveling from NYC to Boston

**Step 1**: Carrier configures target grids:
```json
{
  "grid-targets": ["5M0K*", "5M1L*"],
  "grid-radius": 20
}
```

**Step 2**: At NYC, carrier syncs with local relays:
```
>RELAY_INV_REQ:5M1L*:*:500
```

Requests all messages destined for Boston area (5M1L*).

**Step 3**: Carrier accepts ~4500 messages for Boston

**Step 4**: Carrier travels to Boston

**Step 5**: At Boston, carrier syncs with local relays:
```
>RELAY_INV_REQ:5M0K*:*:500
```

Requests all messages destined for NYC area (5M0K*).

**Step 6**: Carrier delivers Boston-bound messages, picks up NYC-bound messages

**No Wrong-Direction Penalty**:
- Relays don't reject messages going "wrong direction"
- Relay admin decides which messages to accept/deliver
- Carrier may hold messages indefinitely until traveling to destination
- Carrier may discard messages if not profitable/practical to deliver

### Grid Organization for Large Stores

Relays can optionally organize storage by grid subdirectories for efficient filtering:

```
relay-storage/
├── messages/
│   ├── grid-5M0K/           # NYC area messages
│   │   ├── ALICE-K5XYZ_2025-11-09_22-00_normal_a7c5b1.md
│   │   ├── BOB-N7ABC_2025-11-09_22-05_urgent_3e9a7c.md
│   │   └── ...
│   ├── grid-5M1L/           # Boston area messages
│   │   ├── CHARLIE-W5LMN_2025-11-09_22-10_emergency_f2d4e8.md
│   │   └── ...
│   ├── grid-5M2M/           # Philadelphia area messages
│   │   └── ...
│   └── grid-unknown/        # Messages without grid assignment
│       └── ...
└── indices/
    ├── grid-index.txt       # Grid → filename mapping
    ├── by-priority.txt      # Priority index
    └── by-timestamp.txt     # Timestamp index
```

**Simple Text-Based Index** (`grid-index.txt`):
```
5M0K9P3R|ALICE-K5XYZ_2025-11-09_22-00_normal_a7c5b1.md|45678|normal
5M0K9P4S|BOB-N7ABC_2025-11-09_22-05_urgent_3e9a7c.md|12345|urgent
5M1L8O4Q|CHARLIE-W5LMN_2025-11-09_22-10_emergency_f2d4e8.md|98765|emergency
```

**Queries Using grep/awk**:
```bash
# Find all NYC area messages (grid 5M0K*)
grep "^5M0K" relay-storage/indices/grid-index.txt | cut -d'|' -f2

# Find urgent and emergency messages in NYC area
grep "^5M0K" relay-storage/indices/grid-index.txt | \
  awk -F'|' '$4 ~ /urgent|emergency/ {print $2}'

# Count messages per grid
cut -d'|' -f1 relay-storage/indices/grid-index.txt | \
  cut -c1-4 | sort | uniq -c
```

**Alternative: SQLite Index** (optional, for complex queries):
```sql
-- Create index database
CREATE TABLE message_index (
    filename TEXT PRIMARY KEY,
    destination_grid TEXT,
    message_size INTEGER,
    priority TEXT,
    timestamp INTEGER,
    expires INTEGER,
    message_type TEXT
);

CREATE INDEX idx_grid ON message_index(destination_grid);
CREATE INDEX idx_priority ON message_index(priority, timestamp);
CREATE INDEX idx_expires ON message_index(expires);

-- Query example
SELECT filename, message_size, priority
FROM message_index
WHERE destination_grid LIKE '5M0K%'
  AND message_type IN ('private', 'emergency')
  AND expires > strftime('%s', 'now')
ORDER BY
  CASE priority
    WHEN 'emergency' THEN 0
    WHEN 'urgent' THEN 1
    WHEN 'normal' THEN 2
    WHEN 'low' THEN 3
    ELSE 4
  END,
  timestamp ASC
LIMIT 100;
```

**Index Maintenance**:
- Regenerate indices after adding/removing messages
- Indices are optional - filenames alone provide basic filtering
- Use full index for complex queries, skip for simple relay operations

## Payment Protocol

### Paid Delivery Field

Messages can optionally offer payment for successful delivery:

```markdown
> 2025-11-09 22:00_00 -- ALICE-K5XYZ
Urgent message - paid delivery.

--> to: BOB-W6ABC
--> paid-delivery: true
--> payment-amount: 1000
--> payment-currency: sats
--> payment-recipient: delivery-relay
--> payment-conditions: delivery-receipt
```

**Fields**:
- `paid-delivery`: Boolean flag indicating paid delivery
- `payment-amount`: Numeric amount (interpretation depends on currency)
- `payment-currency`: Open field for future flexibility
  - Examples: `sats` (Bitcoin satoshis), `usd`, `eur`, `tokens`, `credits`
- `payment-recipient`: Who receives payment
  - `delivery-relay`: Relay that completes delivery
  - `sender`: Sender pays upfront (relay fee model)
  - `recipient`: Recipient pays on receipt
- `payment-conditions`: When payment is due
  - `delivery-receipt`: Payment upon delivery receipt
  - `read-receipt`: Payment upon read receipt
  - `timestamp`: Payment after time delay

### Payment Claim Verification

**Scenario**: Relay carrier claims payment for delivering message.

**Step 1**: Sender creates paid message:
```markdown
> 2025-11-09 22:00_00 -- ALICE-K5XYZ
Important contract document - paid delivery.

--> to: BOB-W6ABC
--> id: 7f3b8c9d2e1a5f6c...
--> from-npub: npub1alice...
--> to-npub: npub1bob...
--> paid-delivery: true
--> payment-amount: 5000
--> payment-currency: sats
--> payment-recipient: delivery-relay
--> payment-conditions: delivery-receipt
--> signature: alice_msg_sig...
```

**Step 2**: Relay C delivers message to Bob

**Step 3**: Bob generates delivery receipt (signed):
```markdown
> 2025-11-09 22:30_15 -- BOB-W6ABC
Receipt: Message delivered.

--> to: ALICE-K5XYZ
--> id: receipt_7f3b8c9d...
--> type: relay-receipt
--> from-npub: npub1bob...
--> original-message-id: 7f3b8c9d2e1a5f6c...
--> delivered-by: npub1relayC...
--> forward-path: [npub1relayA..., npub1relayB..., npub1relayC...]
--> signature: bob_receipt_sig...
```

**Step 4**: Relay C returns receipt to Alice

**Step 5**: Alice verifies receipt chain:
```python
def verify_payment_claim(original_message, delivery_receipt):
    """
    Verify relay's claim for payment
    """
    # 1. Verify receipt signature (from recipient)
    if not verify_receipt_signature(delivery_receipt, original_message['to-npub']):
        return False, "Invalid receipt signature"

    # 2. Verify message ID matches
    if delivery_receipt['original-message-id'] != original_message['id']:
        return False, "Message ID mismatch"

    # 3. Verify delivered-by relay is in forward path
    delivered_by = delivery_receipt['delivered-by']
    forward_path = delivery_receipt['forward-path']

    if delivered_by not in forward_path:
        return False, "Delivered-by relay not in forward path"

    # 4. Verify delivered-by is the last relay in path
    if forward_path[-1] != delivered_by:
        return False, "Delivered-by must be last relay in chain"

    # 5. All verification passed - payment authorized
    return True, "Payment claim valid"
```

**Step 6**: Alice pays Relay C (via Lightning, on-chain, or other method)

**Step 7**: Relay C generates payment receipt:

```markdown
> 2025-11-09 23:15_30 -- RELAY-C
Payment receipt for message delivery service.

--> to: ALICE-K5XYZ
--> id: payment_receipt_7f3b8c9d...
--> type: payment-receipt
--> from-npub: npub1relayC...
--> to-npub: npub1alice...
--> original-message-id: 7f3b8c9d2e1a5f6c...
--> payment-received: true
--> payment-amount: 5000
--> payment-currency: sats
--> payment-timestamp: 2025-11-09T23:15:30Z
--> payment-proof: lntx_abc123def456...
--> payment-method: lightning
--> transaction-id: lntx_abc123def456...
--> delivery-receipt-id: receipt_7f3b8c9d...
--> signature: relayC_payment_receipt_sig...
```

This payment receipt serves as **proof of payment** for the message delivery service and completes the paid relay transaction cycle.

### Standard Payment Methods

To enable sorting, filtering, and categorization, use these standardized `payment-method` values:

| Method | Code | Description | Typical Currencies |
|--------|------|-------------|-------------------|
| **Lightning Network** | `lightning` | Bitcoin Lightning Network | sats, btc |
| **Bitcoin On-Chain** | `bitcoin-onchain` | Bitcoin blockchain transactions | sats, btc |
| **Monero** | `monero` | Monero cryptocurrency | xmr |
| **Ethereum** | `ethereum` | Ethereum blockchain | eth, tokens |
| **PayPal** | `paypal` | PayPal online payment | usd, eur, etc. |
| **Bank Transfer** | `bank-transfer` | Traditional banking | usd, eur, etc. |
| **Cash** | `cash` | Physical cash payment | Any fiat |
| **Barter** | `barter` | Trade of goods/services | N/A |
| **Other** | `other` | Custom/unspecified method | Any |

### Payment Currency Examples

**Bitcoin Lightning**:
```markdown
paid-delivery: true
payment-amount: 5000
payment-currency: sats
payment-method: lightning
payment-invoice: lnbc5000n1...
```

**Monero**:
```markdown
paid-delivery: true
payment-amount: 0.05
payment-currency: xmr
payment-method: monero
payment-address: 4AdUndXHHZ6cfufTMvppY6JwXNouMBzSkbLYfpAV5Usx...
```

**Bitcoin On-Chain**:
```markdown
paid-delivery: true
payment-amount: 50000
payment-currency: sats
payment-method: bitcoin-onchain
payment-address: bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
```

**Fiat Currency**:
```markdown
paid-delivery: true
payment-amount: 2.50
payment-currency: usd
payment-method: paypal
payment-account: relay-carrier@example.com
```

**Ethereum Token**:
```markdown
paid-delivery: true
payment-amount: 100
payment-currency: usdc
payment-method: ethereum
payment-contract: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
```

**Barter Agreement**:
```markdown
paid-delivery: true
payment-amount: 1
payment-currency: favor
payment-method: barter
payment-note: "I'll deliver your message if you help me move next weekend"
```

**Custom Method**:
```markdown
paid-delivery: true
payment-amount: 50
payment-currency: local-credits
payment-method: other
payment-note: "Community exchange credits"
```

### Payment Incentive Model

**Use Cases**:

1. **Remote Area Delivery**:
   - Message to remote hiking trail: 50,000 sats
   - Carrier hikes to location, delivers message
   - Returns with delivery receipt, claims payment

2. **Urgent Delivery**:
   - Emergency message: 10,000 sats
   - Carrier prioritizes delivery
   - Faster delivery = higher payment

3. **Long-Distance Relay**:
   - NYC → Alaska: 100,000 sats
   - Carrier traveling that route accepts message
   - Covers travel costs, earns profit

4. **Commercial Courier**:
   - Professional relay carriers advertise routes
   - Accept paid messages along their routes
   - Build reputation for reliable delivery

**No Payment Method Specified**:

The protocol does NOT define:
- How payments are executed
- Which currencies are acceptable
- Payment verification methods
- Dispute resolution

These are left open for future flexibility and adaptation to evolving payment technologies.

## Priority and Transmission Ordering

### Priority Levels

Messages have priority field for routing/transmission ordering:

| Priority | Code | Description | Use Case |
|----------|------|-------------|----------|
| **emergency** | `emergency` | Life-threatening situations | Medical emergency, disaster |
| **urgent** | `urgent` | Time-sensitive important | Meeting reminder, deadline |
| **normal** | `normal` | Standard messages | General conversation |
| **low** | `low` | Non-urgent | News updates, announcements |
| **bulk** | `bulk` | Mass distribution | Advertisements, newsletters |

### Transmission Priority

When relays sync, messages are transferred in priority order:

```python
def prioritize_message_transfer(message_list):
    """
    Sort messages by priority for transmission
    """
    priority_order = {
        'emergency': 0,
        'urgent': 1,
        'normal': 2,
        'low': 3,
        'bulk': 4
    }

    # Sort by priority, then by timestamp (oldest first)
    sorted_messages = sorted(
        message_list,
        key=lambda msg: (
            priority_order.get(msg['priority'], 2),
            msg['timestamp']
        )
    )

    return sorted_messages
```

**Transmission Example**:
```
1. emergency message (timestamp: 1000)
2. emergency message (timestamp: 1200)
3. urgent message (timestamp: 900)
4. urgent message (timestamp: 1100)
5. normal message (timestamp: 800)
6. normal message (timestamp: 1300)
```

### Priority Does NOT Bypass Storage Limits

**Important**: Priority affects transmission order but NOT storage capacity:

- **Urgent messages**: Transmitted first, but count against storage limit
- **No special treatment**: Emergency messages deleted when storage full (following purge algorithm)
- **Fair storage**: All messages treated equally for storage purposes

**Rationale**: Prevents abuse where senders mark all messages as "urgent" to bypass limits.

## Error Handling

### Error Response Matrix

| Error | Action | Response | Log | Reputation |
|-------|--------|----------|-----|------------|
| **Signature verification failed** | Reject, do not store | Silent rejection | Log sender npub, timestamp, message ID | Increment tamper counter |
| **Checksum mismatch** | Request retransmission | `>NACK-<MSG_ID>-<MISSING>` | Log packet loss | No penalty |
| **Malformed markdown** | Reject, do not store | `>REJECT-<MSG_ID>-MALFORMED` | Log sender npub | Increment error counter |
| **Duplicate message ID** | Reject, do not process | Silent rejection | Log duplicate attempt | No penalty |
| **Expired message** | Reject, do not store | `>REJECT-<MSG_ID>-EXPIRED` | Log expired attempt | No penalty |
| **Timestamp too far in future** | Accept with warning OR reject | `>ACCEPT-<MSG_ID>-FUTURE_TIMESTAMP` | Log timestamp anomaly | No penalty |
| **Timestamp too far in past** | Accept if not expired | `>ACCEPT-<MSG_ID>-OLD_TIMESTAMP` | Log timestamp anomaly | No penalty |
| **Storage full** | Reject OR purge then accept | `>REJECT-<MSG_ID>-STORAGE_FULL` | Log storage event | No penalty |
| **Rate limit exceeded** | Reject, do not store | `>REJECT-<MSG_ID>-RATE_LIMIT` | Log sender npub, count | Increment spam counter |
| **Type not accepted** | Reject, do not store | Silent rejection | Log type filter | No penalty |
| **Grid out of range** | Reject OR store for later | Admin decision | Log grid mismatch | No penalty |

### Signature Verification Failure

```python
def handle_signature_failure(message):
    """
    Message signature verification failed - possible tampering
    """
    # 1. Reject immediately
    storage.reject_message(message['id'])

    # 2. Log detailed info
    log_security_event(
        event="SIGNATURE_VERIFICATION_FAILED",
        message_id=message['id'],
        from_npub=message['from-npub'],
        timestamp=time.time(),
        reason="Schnorr signature invalid"
    )

    # 3. Increment sender reputation counter
    reputation.increment_tamper_count(message['from-npub'])

    # 4. Check if sender is repeat offender
    if reputation.get_tamper_count(message['from-npub']) > 10:
        # Block sender for 24 hours
        blocklist.add(message['from-npub'], duration_hours=24)
        log_security_event(
            event="SENDER_BLOCKED",
            from_npub=message['from-npub'],
            reason="Repeated signature failures"
        )

    # 5. No response to sender (silent rejection)
    return "REJECTED_SIGNATURE_INVALID"
```

### Timestamp Anomalies

**Future Timestamps**:

```python
def handle_future_timestamp(message, current_time):
    """
    Message timestamp is in the future
    """
    future_delta = message['timestamp'] - current_time

    # Define acceptable future threshold (e.g., 1 hour for clock skew)
    FUTURE_THRESHOLD = 60 * 60  # 1 hour

    if future_delta > FUTURE_THRESHOLD:
        # Too far in future - likely clock misconfiguration
        log_warning(
            event="FUTURE_TIMESTAMP",
            message_id=message['id'],
            delta_seconds=future_delta
        )

        # Admin configurable: accept with warning or reject
        if config.get('reject-future-timestamps', False):
            return "REJECTED_FUTURE_TIMESTAMP"
        else:
            # Accept but mark as suspicious
            message['_warnings'] = message.get('_warnings', [])
            message['_warnings'].append('FUTURE_TIMESTAMP')
            return "ACCEPTED_WITH_WARNING"

    # Within threshold - accept
    return "ACCEPTED"
```

**Past Timestamps**:

```python
def handle_past_timestamp(message, current_time):
    """
    Message timestamp is old
    """
    age = current_time - message['timestamp']

    # Check if message already expired
    if message['expires'] < current_time:
        return "REJECTED_EXPIRED"

    # Check TTL
    if age > message['ttl']:
        return "REJECTED_TTL_EXCEEDED"

    # Old but not expired - accept
    log_info(
        event="OLD_TIMESTAMP",
        message_id=message['id'],
        age_seconds=age
    )

    return "ACCEPTED"
```

### Malformed Messages

```python
def handle_malformed_message(message_raw, error):
    """
    Message failed to parse - malformed markdown
    """
    # Try to extract sender npub for logging
    sender = extract_sender_from_malformed(message_raw)

    log_error(
        event="MALFORMED_MESSAGE",
        sender=sender,
        error=str(error),
        raw_length=len(message_raw)
    )

    # Increment error counter
    if sender:
        reputation.increment_error_count(sender)

    # Optionally notify sender (if identifiable)
    if sender and config.get('send-error-notifications', True):
        send_rejection_notice(
            to=sender,
            reason="MALFORMED",
            details=f"Parse error: {error}"
        )

    return "REJECTED_MALFORMED"
```

## Multi-Copy Distribution

### Natural Distribution Model

Messages naturally create multiple copies as they propagate through relay network:

**No Artificial Duplication**:
- Relays do NOT create duplicate messages in their own storage
- Each relay stores at most ONE copy of each message ID
- Multiple copies exist across DIFFERENT relays

**Distribution Scenario**:

```
         Sender
         /  |  \
        /   |   \
     Relay  Relay  Relay
      A      B      C
     / \     |     / \
    /   \    |    /   \
 Relay  Relay Relay  Relay
   D      E    F      G
```

Sender broadcasts to Relays A, B, C → each stores one copy → each forwards to downstream relays → 7 copies total across network (one per relay).

### Carrier Selection

When multiple relay carriers sync with a relay:

```python
def distribute_to_carriers(message, available_carriers):
    """
    Distribute message to multiple carriers naturally
    """
    suitable_carriers = []

    for carrier in available_carriers:
        # Check if carrier accepts this message type
        if message['type'] not in carrier.accepted_types:
            continue

        # Check if carrier's grid targets include destination
        if not carrier.is_within_grid_targets(message['destination-grid']):
            continue

        # Check if carrier has storage space
        if carrier.storage_free < message['size']:
            continue

        suitable_carriers.append(carrier)

    # Transfer to all suitable carriers
    for carrier in suitable_carriers:
        transfer_message(message, carrier)
        log_info(
            event="MESSAGE_COPIED_TO_CARRIER",
            message_id=message['id'],
            carrier_npub=carrier.npub
        )

    return len(suitable_carriers)
```

**Result**: Message naturally distributed to multiple carriers heading in similar directions.

### Copy Limitation

To prevent exponential message explosion:

**Hop Count Field**:
```markdown
relay-count: 5
relay-hop-limit: 10
```

- `relay-count`: Current number of relay hops
- `relay-hop-limit`: Maximum hops before message stops propagating

**Hop Limit Enforcement**:
```python
def check_hop_limit(message):
    """
    Check if message exceeded hop limit
    """
    relay_count = message.get('relay-count', 0)
    hop_limit = message.get('relay-hop-limit', 10)

    if relay_count >= hop_limit:
        log_info(
            event="HOP_LIMIT_REACHED",
            message_id=message['id'],
            relay_count=relay_count
        )
        return False, "HOP_LIMIT_REACHED"

    return True, "HOP_LIMIT_OK"
```

**When accepting message**:
```python
def accept_relay_message(message):
    """
    Accept message from another relay
    """
    # Check hop limit
    can_accept, reason = check_hop_limit(message)
    if not can_accept:
        return "REJECTED_HOP_LIMIT"

    # Increment relay count
    message['relay-count'] = message.get('relay-count', 0) + 1

    # Store message
    storage.store_message(message)

    return "ACCEPTED"
```

**Default Hop Limit**: 10 relays (configurable per message)

---

**Version**: 1.2
**Last Updated**: 2025-11-09
**Related Documents**: message-integrity.md, message-ble.md, relay-functionality.md

## Document Changelog

### Version 1.2 (2025-11-09)
- **Added comprehensive Relay Message Selection Criteria section**
- Documented relay carrier profile structure with selection preferences
- Defined 6 selection criteria categories (geographic, type, priority, size, time, payment)
- Complete message selection algorithm with Python implementation
- 4 real-world carrier scenarios (courier, emergency, news, general)
- Message scoring and prioritization system
- Runtime configuration updates via BLE
- Selection statistics and reporting
- 13-step relay discovery and selection workflow

### Version 1.1 (2025-11-09)
- Added payment receipt message type and workflow
- Defined standard payment-method values (including Monero)
- Specified message file storage format with standardized filenames
- Added filename format: `<callsign>_<YYYY-MM-DD>_<HH-MM>_<priority>_<sig6>.md`
- Human-readable timestamps in filenames (UTC)
- Documented archiving strategy for millions of messages
- Added text-based and SQLite indexing options

### Version 1.0 (2025-11-09)
- Initial specification
- Message ID generation (NOSTR-style)
- Message types taxonomy
- Storage management and purge algorithm
- Relay synchronization protocol
- Geographic grid routing
- Payment protocol
- Priority and error handling
