# Message Integrity Verification

## Overview

Every relay message MUST be verified to ensure it hasn't been tampered with during transmission or storage. Geogram uses NOSTR's Schnorr signature scheme adapted for markdown message format to guarantee message authenticity and integrity.

## NOSTR-Compatible Signature Verification

### Canonical Serialization for Signing

Before signing or verifying, the message must be serialized into a canonical form. Only specific fields are included in the signature to allow relay nodes to update routing metadata without invalidating signatures.

**Signed Fields (in order)**:
1. `version`
2. `id`
3. `type`
4. `from-npub`
5. `to-npub`
6. `timestamp`
7. `expires`
8. `ttl`
9. `priority`
10. `receipts`
11. `encrypted`
12. `attachment-count` (if present)
13. `attachment-total-size` (if present)
14. `content-hash` (SHA-256 of encrypted content section)

**NOT Signed (mutable by relays)**:
- `relay-path` (updated by each relay)
- `relay-count` (updated by each relay)
- `signature` (the signature itself)

## Signature Computation

### Step 1: Compute Content Hash

```python
import hashlib

# Extract encrypted content section
content = extract_between_markers(message, "# ENCRYPTED_CONTENT_START", "# ENCRYPTED_CONTENT_END")
content_hash = hashlib.sha256(content.encode('utf-8')).hexdigest()
```

### Step 2: Build Canonical String

Concatenate signed fields with newlines:

```python
canonical = [
    message['version'],
    message['id'],
    message['type'],
    message['from-npub'],
    message['to-npub'],
    message['timestamp'],
    message['expires'],
    str(message['ttl']),
    message['priority'],
    message['receipts'],
    str(message['encrypted']).lower(),  # 'true' or 'false'
    content_hash
]

# Add optional fields if present
if 'attachment-count' in message:
    canonical.append(str(message['attachment-count']))
if 'attachment-total-size' in message:
    canonical.append(str(message['attachment-total-size']))

canonical_string = '\n'.join(canonical)
```

**Example canonical string**:
```
1.0
msg_2025110922001_abc123
relay-message
npub1sender123...
npub1receiver456...
2025-11-09T22:00:01Z
2025-11-16T22:00:01Z
604800
normal
delivery,read
true
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

### Step 3: Sign with Schnorr

```python
import hashlib
from schnorr import sign  # NOSTR-compatible schnorr lib

# Hash the canonical string
message_hash = hashlib.sha256(canonical_string.encode('utf-8')).digest()

# Sign with sender's nsec (private key)
signature = sign(message_hash, sender_nsec)

# Encode signature as hex
signature_hex = signature.hex()
```

### Step 4: Add Signature to Message

The `signature` field in the message header contains the hex-encoded Schnorr signature.

## Signature Verification

Every device receiving a message (relay or destination) MUST verify the signature before accepting it.

### Step 1: Extract Message Fields

Parse the markdown message and extract all signed fields.

### Step 2: Rebuild Canonical String

Use the exact same process as signing to rebuild the canonical string from the received message fields.

### Step 3: Verify Schnorr Signature

```python
import hashlib
from schnorr import verify  # NOSTR-compatible schnorr lib

# Parse signature from message
signature_bytes = bytes.fromhex(message['signature'])

# Rebuild canonical string (same as signing)
canonical_string = build_canonical_string(message)

# Hash the canonical string
message_hash = hashlib.sha256(canonical_string.encode('utf-8')).digest()

# Extract sender's public key (npub)
sender_pubkey = decode_npub(message['from-npub'])

# Verify signature
is_valid = verify(message_hash, sender_pubkey, signature_bytes)

if not is_valid:
    reject_message(message, reason="Invalid signature")
```

### Step 4: Verify Content Hash

Even if signature is valid, verify content wasn't swapped:

```python
# Extract content from message
content = extract_between_markers(message, "# ENCRYPTED_CONTENT_START", "# ENCRYPTED_CONTENT_END")

# Compute hash
actual_hash = hashlib.sha256(content.encode('utf-8')).hexdigest()

# Compare with signed hash
if actual_hash != content_hash_from_canonical:
    reject_message(message, reason="Content hash mismatch")
```

## Verification Failure Handling

If signature verification fails:

1. **Reject message immediately** - Do not store or forward
2. **Log verification failure** with message ID and sender npub
3. **Increment tamper counter** for sender (reputation system)
4. **Notify user** if tampering detected on important message
5. **Do NOT propagate** invalid messages to other relays

## BLE Protocol Integrity

### Single-Packet Commands (≤20 bytes)

Single-packet commands include CRC8 checksum for integrity verification.

**Format**:
```
Offset | Length | Field           | Description
-------|--------|-----------------|---------------------------
0      | 1      | Command Type    | 0x01=ACK, 0x02=NACK, etc.
1-18   | 18     | Payload         | Command-specific data
19     | 1      | CRC8            | Checksum of bytes 0-18
```

**CRC8 Calculation** (polynomial 0x07):
```python
def crc8(data):
    crc = 0
    for byte in data:
        crc ^= byte
        for _ in range(8):
            if crc & 0x80:
                crc = (crc << 1) ^ 0x07
            else:
                crc <<= 1
            crc &= 0xFF
    return crc
```

**Verification**:
```python
def verify_single_packet(packet):
    if len(packet) != 20:
        return False

    payload = packet[0:19]
    received_crc = packet[19]
    calculated_crc = crc8(payload)

    return received_crc == calculated_crc
```

### Multi-Packet Messages (>20 bytes)

Larger messages use CRC32 for entire payload integrity.

**Header Packet Format**:
```
Offset | Length | Field           | Description
-------|--------|-----------------|---------------------------
0      | 1      | Command         | 0x10=MULTI_START
1      | 4      | Total Size      | Total payload size (bytes)
2      | 2      | Packet Count    | Number of data packets
7      | 4      | CRC32           | Checksum of full payload
11     | 8      | Message ID      | Unique message identifier
19     | 1      | CRC8            | Header checksum
```

**Data Packet Format**:
```
Offset | Length | Field           | Description
-------|--------|-----------------|---------------------------
0      | 1      | Command         | 0x11=MULTI_DATA
1      | 2      | Sequence Num    | Packet number (0-based)
3      | 16     | Payload Chunk   | 16 bytes of message data
19     | 1      | CRC8            | Packet checksum
```

**CRC32 Calculation**:
```python
import zlib

def crc32(data):
    return zlib.crc32(data) & 0xFFFFFFFF
```

**Multi-Packet Verification Flow**:
```python
def verify_multi_packet_message(header, data_packets):
    # 1. Verify header packet CRC8
    if not verify_single_packet(header):
        return False, "Header CRC8 failed"

    # 2. Extract header fields
    total_size = int.from_bytes(header[1:5], 'little')
    packet_count = int.from_bytes(header[5:7], 'little')
    expected_crc32 = int.from_bytes(header[7:11], 'little')

    # 3. Verify all data packets received
    if len(data_packets) != packet_count:
        return False, f"Missing packets: {packet_count - len(data_packets)}"

    # 4. Verify each data packet CRC8
    for packet in data_packets:
        if not verify_single_packet(packet):
            return False, "Data packet CRC8 failed"

    # 5. Reassemble payload
    payload = bytearray()
    for seq_num in range(packet_count):
        packet = data_packets[seq_num]
        chunk = packet[3:19]
        payload.extend(chunk)

    # Trim to actual size
    payload = payload[:total_size]

    # 6. Verify payload CRC32
    actual_crc32 = crc32(payload)
    if actual_crc32 != expected_crc32:
        return False, "Payload CRC32 mismatch"

    return True, payload
```

### Packet Loss Recovery

When packets are lost during BLE transmission, the receiver can request retransmission.

**NACK (Negative Acknowledgment) Format**:
```
Offset | Length | Field           | Description
-------|--------|-----------------|---------------------------
0      | 1      | Command         | 0x02=NACK
1      | 8      | Message ID      | Which message has missing packets
9      | 1      | Missing Count   | Number of missing packets
10-17  | 8      | Missing List    | Sequence numbers (up to 8)
18     | 1      | Reserved        | 0x00
19     | 1      | CRC8            | Checksum
```

**Recovery Process**:
1. Receiver detects missing packets (gaps in sequence numbers)
2. Sends NACK with list of missing sequence numbers
3. Sender retransmits only the missing packets
4. Receiver verifies and reassembles complete message

**Example**:
```python
def request_missing_packets(message_id, received_packets, expected_count):
    """Generate NACK for missing packets"""
    received_seq = set(p[1:3] for p in received_packets)
    expected_seq = set(range(expected_count))
    missing_seq = expected_seq - received_seq

    if not missing_seq:
        return None  # All packets received

    # Build NACK packet
    nack = bytearray(20)
    nack[0] = 0x02  # NACK command
    nack[1:9] = message_id
    nack[9] = min(len(missing_seq), 8)

    # Add up to 8 missing sequence numbers
    for i, seq in enumerate(sorted(missing_seq)[:8]):
        nack[10 + i] = seq

    # CRC8
    nack[19] = crc8(nack[0:19])

    return bytes(nack)
```

## Command Messages

Command messages are special messages appended to the message group to track routing, deletions, and other metadata changes.

### Relay Stamp Command

Each relay that handles a message appends a stamp command to track the relay path. This operates on a **best-effort basis** - relays may go offline, be replaced, or be skipped entirely.

**Format**:
```markdown
## COMMAND: RELAY_STAMP

- relay-npub: npub1relay123...
- relay-callsign: RELAY-K5ABC
- timestamp: 2025-11-09T22:15:30Z
- latitude: 40.7128
- longitude: -74.0060
- hop-number: 3
- signature: abc123def456...
```

**Signature Computation**:
```python
stamp_data = f"{message_id}\n{relay_npub}\n{timestamp}\n{latitude}\n{longitude}\n{hop_number}"
stamp_hash = hashlib.sha256(stamp_data.encode('utf-8')).digest()
signature = schnorr_sign(relay_nsec, stamp_hash)
```

**Purpose**:
1. **Chain of custody**: Track which relays handled the message
2. **Location tracking**: Build database of relay locations over time
3. **Reputation system**: Identify reliable vs unreliable relays
4. **Network mapping**: Understand relay network topology

**Complete Message Lifecycle Example**:

This example shows a complete message journey from sender to destination and back with delivery/read receipts.

**Step 1: Original Message (Sender creates and signs)**
```markdown
---
version: 1.0
id: msg_2025110922001_abc123
type: relay-message
from-npub: npub1sender123abc456def789...
from-callsign: ALICE-K5XYZ
to-npub: npub1receiver456xyz789abc123...
to-callsign: BOB-N7ABC
timestamp: 2025-11-09T22:00:01Z
expires: 2025-11-16T22:00:01Z
ttl: 604800
priority: normal
receipts: delivery,read
encrypted: true
signature: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6...
---

# ENCRYPTED_CONTENT_START
U2FsdGVkX1+Jj5K9vN2Pk8Qw3Rt7Yx6Zv4Bu1Cm0Dn9...
(AES-256-CBC encrypted content using NIP-04)
Base64 encoded ciphertext of: "Hi Bob, meet me at the park tomorrow at 3pm"
# ENCRYPTED_CONTENT_END
```

**Step 2: Relay A receives and stamps**
```markdown
---
version: 1.0
id: msg_2025110922001_abc123
type: relay-message
from-npub: npub1sender123abc456def789...
from-callsign: ALICE-K5XYZ
to-npub: npub1receiver456xyz789abc123...
to-callsign: BOB-N7ABC
timestamp: 2025-11-09T22:00:01Z
expires: 2025-11-16T22:00:01Z
ttl: 604800
priority: normal
receipts: delivery,read
encrypted: true
signature: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6...
---

# ENCRYPTED_CONTENT_START
U2FsdGVkX1+Jj5K9vN2Pk8Qw3Rt7Yx6Zv4Bu1Cm0Dn9...
# ENCRYPTED_CONTENT_END

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayA111222333444555...
- relay-callsign: RELAY-K5ABC
- timestamp: 2025-11-09T22:05:00Z
- latitude: 40.7128
- longitude: -74.0060
- hop-number: 1
- signature: relayA_stamp_sig_xyz123...
```

**Step 3: Relay B receives and stamps**
```markdown
---
version: 1.0
id: msg_2025110922001_abc123
type: relay-message
from-npub: npub1sender123abc456def789...
from-callsign: ALICE-K5XYZ
to-npub: npub1receiver456xyz789abc123...
to-callsign: BOB-N7ABC
timestamp: 2025-11-09T22:00:01Z
expires: 2025-11-16T22:00:01Z
ttl: 604800
priority: normal
receipts: delivery,read
encrypted: true
signature: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6...
---

# ENCRYPTED_CONTENT_START
U2FsdGVkX1+Jj5K9vN2Pk8Qw3Rt7Yx6Zv4Bu1Cm0Dn9...
# ENCRYPTED_CONTENT_END

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayA111222333444555...
- relay-callsign: RELAY-K5ABC
- timestamp: 2025-11-09T22:05:00Z
- latitude: 40.7128
- longitude: -74.0060
- hop-number: 1
- signature: relayA_stamp_sig_xyz123...

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayB666777888999000...
- relay-callsign: RELAY-K7XYZ
- timestamp: 2025-11-09T22:10:15Z
- latitude: 40.7580
- longitude: -73.9855
- hop-number: 2
- signature: relayB_stamp_sig_abc456...
```

**Step 4: Relay C delivers to destination and stamps**
```markdown
---
version: 1.0
id: msg_2025110922001_abc123
type: relay-message
from-npub: npub1sender123abc456def789...
from-callsign: ALICE-K5XYZ
to-npub: npub1receiver456xyz789abc123...
to-callsign: BOB-N7ABC
timestamp: 2025-11-09T22:00:01Z
expires: 2025-11-16T22:00:01Z
ttl: 604800
priority: normal
receipts: delivery,read
encrypted: true
signature: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6...
---

# ENCRYPTED_CONTENT_START
U2FsdGVkX1+Jj5K9vN2Pk8Qw3Rt7Yx6Zv4Bu1Cm0Dn9...
# ENCRYPTED_CONTENT_END

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayA111222333444555...
- relay-callsign: RELAY-K5ABC
- timestamp: 2025-11-09T22:05:00Z
- latitude: 40.7128
- longitude: -74.0060
- hop-number: 1
- signature: relayA_stamp_sig_xyz123...

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayB666777888999000...
- relay-callsign: RELAY-K7XYZ
- timestamp: 2025-11-09T22:10:15Z
- latitude: 40.7580
- longitude: -73.9855
- hop-number: 2
- signature: relayB_stamp_sig_abc456...

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayC333444555666777...
- relay-callsign: RELAY-N0QST
- timestamp: 2025-11-09T22:25:45Z
- latitude: 40.7489
- longitude: -73.9680
- hop-number: 3
- action: delivered_to_destination
- signature: relayC_stamp_sig_def789...

## COMMAND: DELIVERY_RECEIPT
- from-npub: npub1receiver456xyz789abc123...
- from-callsign: BOB-N7ABC
- timestamp: 2025-11-09T22:25:47Z
- delivered-at: 2025-11-09T22:25:47Z
- received-from: npub1relayC333444555666777...
- hop-count: 3
- signature: bob_delivery_receipt_sig_ghi012...
```

**Step 5: Destination reads message**
```markdown
---
version: 1.0
id: msg_2025110922001_abc123
type: relay-message
from-npub: npub1sender123abc456def789...
from-callsign: ALICE-K5XYZ
to-npub: npub1receiver456xyz789abc123...
to-callsign: BOB-N7ABC
timestamp: 2025-11-09T22:00:01Z
expires: 2025-11-16T22:00:01Z
ttl: 604800
priority: normal
receipts: delivery,read
encrypted: true
signature: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6...
---

# ENCRYPTED_CONTENT_START
U2FsdGVkX1+Jj5K9vN2Pk8Qw3Rt7Yx6Zv4Bu1Cm0Dn9...
# ENCRYPTED_CONTENT_END

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayA111222333444555...
- relay-callsign: RELAY-K5ABC
- timestamp: 2025-11-09T22:05:00Z
- latitude: 40.7128
- longitude: -74.0060
- hop-number: 1
- signature: relayA_stamp_sig_xyz123...

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayB666777888999000...
- relay-callsign: RELAY-K7XYZ
- timestamp: 2025-11-09T22:10:15Z
- latitude: 40.7580
- longitude: -73.9855
- hop-number: 2
- signature: relayB_stamp_sig_abc456...

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayC333444555666777...
- relay-callsign: RELAY-N0QST
- timestamp: 2025-11-09T22:25:45Z
- latitude: 40.7489
- longitude: -73.9680
- hop-number: 3
- action: delivered_to_destination
- signature: relayC_stamp_sig_def789...

## COMMAND: DELIVERY_RECEIPT
- from-npub: npub1receiver456xyz789abc123...
- from-callsign: BOB-N7ABC
- timestamp: 2025-11-09T22:25:47Z
- delivered-at: 2025-11-09T22:25:47Z
- received-from: npub1relayC333444555666777...
- hop-count: 3
- signature: bob_delivery_receipt_sig_ghi012...

## COMMAND: READ_RECEIPT
- from-npub: npub1receiver456xyz789abc123...
- from-callsign: BOB-N7ABC
- timestamp: 2025-11-09T22:30:12Z
- read-at: 2025-11-09T22:30:12Z
- signature: bob_read_receipt_sig_jkl345...
```

**Step 6: Receipt travels back through relay network to sender**

The delivery and read receipts travel back through the relay network (possibly different relays) to reach the original sender.

```markdown
---
version: 1.0
id: receipt_msg_2025110922001_abc123
type: relay-receipt
from-npub: npub1receiver456xyz789abc123...
from-callsign: BOB-N7ABC
to-npub: npub1sender123abc456def789...
to-callsign: ALICE-K5XYZ
original-message-id: msg_2025110922001_abc123
timestamp: 2025-11-09T22:30:15Z
expires: 2025-11-16T22:30:15Z
ttl: 604800
priority: high
encrypted: false
signature: receipt_message_sig_mno678...
---

# RECEIPT_CONTENT_START
delivery-timestamp: 2025-11-09T22:25:47Z
read-timestamp: 2025-11-09T22:30:12Z
hop-count-forward: 3
forward-path: RELAY-K5ABC → RELAY-K7XYZ → RELAY-N0QST → BOB-N7ABC
# RECEIPT_CONTENT_END

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayD888999000111222...
- relay-callsign: RELAY-W5LMN
- timestamp: 2025-11-09T22:35:00Z
- latitude: 40.7450
- longitude: -73.9750
- hop-number: 1
- direction: return_path
- signature: relayD_stamp_sig_pqr901...

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayE222333444555666...
- relay-callsign: RELAY-K4TUV
- timestamp: 2025-11-09T22:42:30Z
- latitude: 40.7300
- longitude: -74.0100
- hop-number: 2
- direction: return_path
- signature: relayE_stamp_sig_stu234...

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayF555666777888999...
- relay-callsign: RELAY-N9WXY
- timestamp: 2025-11-09T22:50:15Z
- latitude: 40.7150
- longitude: -74.0200
- hop-number: 3
- direction: return_path
- action: delivered_to_sender
- signature: relayF_stamp_sig_vwx567...
```

**Summary of Complete Journey**:
1. Alice sends message at 22:00:01
2. Relay A stamps at 22:05:00 (5 min later)
3. Relay B stamps at 22:10:15 (10 min later)
4. Relay C delivers to Bob at 22:25:45 (25 min later)
5. Bob's device generates delivery receipt at 22:25:47 (2 sec after delivery)
6. Bob reads message at 22:30:12 (4.5 min after delivery)
7. Receipt begins return journey at 22:30:15
8. Relay D stamps return at 22:35:00 (5 min later)
9. Relay E stamps return at 22:42:30 (7.5 min later)
10. Relay F delivers receipt to Alice at 22:50:15 (8 min later)

**Total time**: ~50 minutes for complete round trip with 6 relay hops
**Forward path**: 3 relays, 25 minutes
**Return path**: 3 relays, 20 minutes

### Deletion Request Command

Both the **sender** and **destination user** can request message deletion. Deletion requests are authenticated using NOSTR signatures.

**Format**:
```markdown
## COMMAND: DELETE_REQUEST

- requester-npub: npub1sender123...
- requester-role: sender  # or "destination"
- timestamp: 2025-11-09T23:00:00Z
- reason: user_requested
- signature: deletion_signature...
```

**Signature Computation**:
```python
delete_data = f"DELETE\n{message_id}\n{requester_npub}\n{timestamp}"
delete_hash = hashlib.sha256(delete_data.encode('utf-8')).digest()
signature = schnorr_sign(requester_nsec, delete_hash)
```

**Verification**:
```python
def verify_deletion_request(message, delete_cmd):
    """Verify deletion request is from authorized party"""
    requester_npub = delete_cmd['requester-npub']
    signature = delete_cmd['signature']

    # Check if requester is sender or destination
    if requester_npub != message['from-npub'] and requester_npub != message['to-npub']:
        return False, "Requester not authorized"

    # Verify signature
    delete_data = f"DELETE\n{message['id']}\n{requester_npub}\n{delete_cmd['timestamp']}"
    delete_hash = hashlib.sha256(delete_data.encode('utf-8')).digest()

    pubkey = decode_npub(requester_npub)
    if not schnorr_verify(delete_hash, pubkey, bytes.fromhex(signature)):
        return False, "Invalid deletion signature"

    return True, "Deletion authorized"
```

**Deletion Propagation**:
1. User creates deletion request command with nsec signature
2. Deletion request appended to message group
3. Relays forward deletion request to other relays
4. Each relay verifies signature before deleting
5. Message removed from relay storage after verification

**Example Deletion Flow (Destination requests deletion)**:
```markdown
## COMMAND: DELETE_REQUEST
- requester-npub: npub1receiver456...
- requester-role: destination
- timestamp: 2025-11-09T23:00:00Z
- reason: user_requested
- signature: delete_sig_receiver...

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayC...
- relay-callsign: RELAY-K9ZZZ
- timestamp: 2025-11-09T23:05:00Z
- latitude: 40.7500
- longitude: -73.9900
- hop-number: 1
- action: deleted
- signature: deletion_processed_sig...
```

**Example Deletion Flow (Sender requests deletion)**:
```markdown
## COMMAND: DELETE_REQUEST
- requester-npub: npub1sender123...
- requester-role: sender
- timestamp: 2025-11-09T23:15:00Z
- reason: message_recalled
- signature: delete_sig_sender...

## COMMAND: RELAY_STAMP
- relay-npub: npub1relayA...
- relay-callsign: RELAY-K5ABC
- timestamp: 2025-11-09T23:20:00Z
- latitude: 40.7128
- longitude: -74.0060
- hop-number: 1
- action: deleted
- signature: deletion_processed_sig_A...
```

**Authorization Logic**:
Both sender and destination are authorized to delete messages:
- **Sender** (`from-npub`): Can recall/delete messages they sent
- **Destination** (`to-npub`): Can delete messages sent to them
- **No one else**: Third parties cannot delete messages (signature verification fails)

This dual-authority model ensures:
1. Senders can recall messages before delivery (e.g., sent to wrong person)
2. Receivers can delete unwanted messages from relay network
3. Messages are protected from unauthorized deletion by third parties

## Relay Path Integrity (Best Effort)

The relay path operates on a **best-effort basis**. Relays may:
- Go offline mid-route
- Be replaced by alternative paths
- Skip certain hops entirely
- Take different routes for multi-copy distribution

Each relay that successfully handles a message adds a **RELAY_STAMP command** (documented above) containing:
- Relay identity (npub and callsign)
- Timestamp when message was received
- **Geographic coordinates** (latitude/longitude)
- Hop number in the chain
- Schnorr signature proving authenticity

This creates a "postcard stamping" effect - like physical mail being stamped at each post office.

**Location Database**:
Relays can extract location data from stamps to build a database of:
- Known relay nodes and their identities
- Last known locations of each relay
- Last time each relay was active (stamping messages)
- Common relay routes and paths

This information helps optimize future routing decisions.

## Complete Verification Flow Example

```python
def verify_relay_message(message):
    """
    Verify a relay message signature and content integrity.
    Returns: (is_valid, error_reason)
    """

    # 1. Extract signed fields
    try:
        version = message['version']
        msg_id = message['id']
        msg_type = message['type']
        from_npub = message['from-npub']
        to_npub = message['to-npub']
        timestamp = message['timestamp']
        expires = message['expires']
        ttl = message['ttl']
        priority = message['priority']
        receipts = message['receipts']
        encrypted = message['encrypted']
        signature_hex = message['signature']
    except KeyError as e:
        return (False, f"Missing required field: {e}")

    # 2. Extract and hash content
    content = extract_encrypted_content(message)
    if content is None:
        return (False, "Missing encrypted content section")

    content_hash = hashlib.sha256(content.encode('utf-8')).hexdigest()

    # 3. Build canonical string
    canonical_parts = [
        version, msg_id, msg_type, from_npub, to_npub,
        timestamp, expires, str(ttl), priority, receipts,
        str(encrypted).lower(), content_hash
    ]

    # Add optional fields
    if 'attachment-count' in message:
        canonical_parts.append(str(message['attachment-count']))
    if 'attachment-total-size' in message:
        canonical_parts.append(str(message['attachment-total-size']))

    canonical_string = '\n'.join(canonical_parts)

    # 4. Hash canonical string
    message_hash = hashlib.sha256(canonical_string.encode('utf-8')).digest()

    # 5. Decode signature and public key
    try:
        signature = bytes.fromhex(signature_hex)
        pubkey = decode_npub(from_npub)
    except Exception as e:
        return (False, f"Invalid signature or npub encoding: {e}")

    # 6. Verify Schnorr signature
    if not schnorr_verify(message_hash, pubkey, signature):
        return (False, "Signature verification failed - message tampered or forged")

    # 7. All checks passed
    return (True, None)

# Usage
is_valid, error = verify_relay_message(received_message)
if not is_valid:
    log_error(f"Message {received_message['id']} rejected: {error}")
    discard_message(received_message)
else:
    accept_message(received_message)
```

## Verification Performance

**Optimization strategies**:
- Cache verified message IDs to avoid re-verification
- Verify in background thread to avoid blocking BLE transfers
- Batch signature verifications for multiple messages
- Skip verification for messages from trusted relays (configurable, use with caution)

**Expected performance** (on mid-range Android device):
- Single message verification: ~5-10ms
- Batch of 100 messages: ~300-500ms
- Does not significantly impact relay throughput

## BLE Protocol Performance

**BLE Throughput**:
- Standard BLE: ~10-20 KB/sec
- BLE 4.2 with DLE (Data Length Extension): ~40-60 KB/sec
- BLE 5.0: ~100-200 KB/sec (if hardware supports it)

For relay messages (<1MB each), BLE provides adequate performance:
- 100 KB message: ~5-10 seconds transfer time
- 1 MB message: ~50-60 seconds transfer time

**Why BLE for Relay**:
1. **No pairing required**: Fully automated discovery and data transfer without user interaction
2. **Lower power consumption**: Important for battery life during relay operation
3. **Permission-based**: Only requires location permission (already granted for BLE scanning)
4. **Sufficient throughput**: Adequate for message relay (messages <1MB)
5. **Current implementation**: Geogram already uses BLE infrastructure

## Security Considerations

1. **Always verify before storing**: Never accept unverified messages into relay storage
2. **Re-verify on forward**: Even if previously verified, re-verify before forwarding to ensure local storage wasn't corrupted
3. **Time-bound signatures**: Reject messages with timestamps too far in past/future (>24 hours)
4. **Rate limiting**: Limit verification attempts per device to prevent DoS attacks
5. **Signature caching**: Cache verification results keyed by (message_id, signature) to speed up re-verification
6. **BLE packet verification**: Always verify CRC8/CRC32 before processing received packets
7. **NACK flood prevention**: Limit NACK retransmission requests to prevent DoS attacks

---

**Version**: 1.1
**Last Updated**: 2025-11-09
