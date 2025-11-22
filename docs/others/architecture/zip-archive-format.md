# Geogram ZIP Archive Format

**Version**: 1.0
**Status**: Implemented in geogram-server
**Last Updated**: 2025-11-10

---

## Overview

Geogram uses **ZIP archives as portable, self-contained data bundles** for storing structured content with associated files. This pattern enables:

- ✅ **Single-file portability** - Everything bundled together
- ✅ **Standard format** - Compatible with any ZIP tool
- ✅ **Hierarchical organization** - Folders and files within
- ✅ **Easy backup/transfer** - Single file to copy/share
- ✅ **Random access** - Read/write individual files without full extraction
- ✅ **Compression** - Automatic size reduction

---

## 🎯 Use Cases

### Current Implementation

**User Profiles** (geogram-server)
- Profile metadata (JSON)
- Avatar images
- Chat conversations
- Custom user content
- Module configurations

### Planned Implementations

**Message Groups**
- Conversation transcript (markdown)
- Shared images, videos, files
- Receipts and signatures
- Thread metadata

**Relay Message Archives**
- Batch of relay messages
- Attached media files
- Delivery receipts
- Routing metadata

**Data Export/Import**
- User data export
- Settings backup
- Content migration between devices

---

## 📦 Archive Structure Pattern

### General Pattern

```
<IDENTIFIER>.zip/
├── metadata.json           # Core metadata (REQUIRED)
├── index.md               # Human-readable overview (RECOMMENDED)
├── assets/                # Media and binary files
│   ├── image001.jpg
│   ├── video001.mp4
│   └── document.pdf
├── content/               # Primary content files
│   ├── YYYY-MM-DD.md     # Date-based content
│   └── conversation.md    # Main content
├── receipts/              # Signatures and receipts
│   ├── delivery.sig
│   └── read.sig
└── modules/               # Optional modules/extensions
    └── custom/
        └── data.json
```

### Design Principles

1. **Required Metadata** - Always include a root metadata file (JSON format)
2. **Flat When Possible** - Use folders only when needed for organization
3. **Standard Extensions** - Use conventional file extensions (.jpg, .md, .json)
4. **Date-Based Sharding** - Use YYYY/YYYY-MM-DD for time-series data
5. **Human Readable** - Include .md or .txt files for inspection
6. **Security Files** - Store signatures and ownership proofs

---

## 🏛️ Implementation: User Profiles

### Reference Implementation

**Location**: `geogram-server/src/main/java/geogram/database/CallSignDatabase.java`

**Technology**: Java NIO Zip FileSystem (ZipFS)

### Directory Structure on Disk

User profiles are **sharded by first two characters** of callsign:

```
profiles/
├── A/
│   ├── B/
│   │   ├── ABC123.zip
│   │   └── ABCDEF.zip
│   └── C/
│       └── AC1234.zip
├── C/
│   └── R/
│       ├── CR7BBQ.zip
│       └── CR9XYZ.zip
└── X/
    └── 1/
        └── X135AS.zip
```

**Sharding Algorithm**:
- First char → Top-level directory
- Second char → Second-level directory
- Callsign.zip → File

**Benefits**:
- Reduces directory size (max ~1,300 subdirs instead of millions of files)
- Faster filesystem operations
- Easier backup/sync strategies

### Inside Each Profile ZIP

```
CR7BBQ.zip/
├── profile.json              # Profile metadata (REQUIRED)
├── owner.pub                 # Owner's public key (hex, REQUIRED)
├── avatar.png                # Profile picture (optional)
├── index.md                  # Homepage content (optional)
├── config.json               # Module configuration (optional)
├── contacts.json             # Contacts list (optional)
├── comments.txt              # User comments (optional)
├── messages/                 # 1:1 conversations
│   ├── ALICE-chat.md
│   ├── BOB-chat.md
│   └── CHARLIE-chat.md
├── chat/                     # Public chat module
│   ├── config.json
│   └── 2025/
│       ├── 2025-11-09-chat.md
│       ├── 2025-11-10-chat.md
│       └── 2025-11-11-chat.md
├── blog/                     # Blog module
│   ├── config.json
│   └── posts/
│       ├── 2025-11-01-hello-world.md
│       └── 2025-11-05-update.md
└── custom_folder/            # User-created folders
    └── notes.txt
```

### Key Files

#### 1. profile.json (Required)

**Purpose**: Core profile metadata
**Format**: Pretty-printed JSON

```json
{
  "callsign": "CR7BBQ",
  "name": "Example User",
  "npub": "npub1abc...",
  "description": "Ham radio enthusiast",
  "hasProfilePic": true,
  "messagesArchived": 42,
  "lastUpdated": 1699564801,
  "firstTimeSeen": 1699500000,
  "profileType": "individual",
  "profileVisibility": "public",
  "profilesAssociated": ["RELAY1", "RELAY2"]
}
```

**Required Fields**:
- `callsign` (string)
- Version indicator (varies by implementation)

#### 2. owner.pub (Security)

**Purpose**: Cryptographic ownership proof
**Format**: Hex-encoded public key (lowercase, no prefix)

```
d4f2a8b1c3e5f7a9b2d4e6f8a0c2e4f6a8b0c2e4f6a8b0c2e4f6a8b0c2e4f6a8
```

**Rules**:
- First-come, first-served ownership
- Used to verify Nostr signatures (NIP-01, NIP-98)
- Immutable after creation

#### 3. avatar.{png,jpg,webp,gif}

**Purpose**: Profile picture
**Format**: Image file (extension based on MIME type)
**Size**: Recommended ≤ 500KB

#### 4. config.json (Module Configuration)

**Purpose**: Module-level settings
**Format**: JSON

```json
{
  "owner": "CR7BBQ",
  "name": "Public Chat",
  "description": "Community discussion",
  "moduleType": "chat",
  "visibility": "public",
  "readonly": false,
  "moderators": ["CR7BBQ", "ADMIN"],
  "members": ["*"]
}
```

#### 5. Chat Message Format

**File**: `messages/CALLSIGN-chat.md` or `chat/YYYY/YYYY-MM-DD-chat.md`
**Format**: Custom markdown with structured syntax

```markdown
# CR7BBQ: Public chat

> 2025-11-10 14:30_15 -- ALICE
Hello everyone!

> 2025-11-10 14:32_08 -- BOB
Hey Alice, welcome!

> 2025-11-10 14:35_42 -- ALICE
Thanks! Glad to be here.
--> icon_like: BOB, CHARLIE

> 2025-11-10 14:40_00 -- CHARLIE
--> Poll: Meeting time?
[1] Morning (9am)
[2] Afternoon (2pm)
[3] Evening (7pm)
--> votes: ALICE=2; BOB=1; DAVE=2
--> deadline: 18:00_00
```

**Syntax Elements**:
- `> YYYY-MM-DD HH:MM_SS -- AUTHOR` - Message header
- `-->` - Metadata/action prefix
- `icon_like: USER1, USER2` - Reactions
- `Poll:` - Poll question
- `[N]` - Poll options
- `votes:` - Vote tracking
- `deadline:` - Poll deadline

---

## 💻 Implementation Details

### Java Implementation (geogram-server)

#### Opening a ZIP Archive

```java
// Method 1: Session-based (recommended for multiple operations)
try (CallSignDatabase.ProfileSession session = database.open("CR7BBQ")) {
    Path root = session.root();

    // Read files
    Path profileJson = root.resolve("profile.json");
    String content = Files.readString(profileJson, UTF_8);

    // Write files
    Path newFile = root.resolve("notes.txt");
    Files.writeString(newFile, "My notes", UTF_8);

} // Auto-closes and saves changes

// Method 2: Single operation
database.writeFileOnce("CR7BBQ", "profile.json", jsonBytes);
byte[] data = database.readFileOnce("CR7BBQ", "avatar.png");
```

#### Creating a ZIP Archive

```java
// Configure environment
Map<String, String> env = new HashMap<>();
env.put("create", "true");  // Create if doesn't exist

// Open as filesystem
URI uri = URI.create("jar:" + zipPath.toUri());
try (FileSystem fs = FileSystems.newFileSystem(uri, env)) {
    Path root = fs.getPath("/");

    // Create directory structure
    Path messagesDir = root.resolve("messages");
    Files.createDirectories(messagesDir);

    // Write files
    Path profileJson = root.resolve("profile.json");
    Files.write(profileJson, jsonBytes, StandardOpenOption.CREATE);

} // Closing FileSystem commits changes
```

#### Security: Path Traversal Prevention

```java
/**
 * Safely resolve a path within the ZIP, preventing directory traversal
 */
public static Path safeResolve(Path root, String relativePath) {
    Path resolved = root.resolve(relativePath).normalize();

    // Ensure resolved path is still within root
    if (!resolved.startsWith(root)) {
        throw new SecurityException("Path traversal attempt: " + relativePath);
    }

    return resolved;
}

// Usage
Path safe = safeResolve(root, userSuppliedPath);
```

### Performance Optimizations

#### 1. Session Caching

```java
// Keep filesystem open across multiple operations
private final Map<String, FileSystem> fsCache = new ConcurrentHashMap<>();
private final int maxOpenSessions = 100;

public ProfileSession open(String callsign) {
    FileSystem fs = fsCache.computeIfAbsent(callsign, this::openFilesystem);
    return new ProfileSession(fs, callsign);
}
```

**Benefits**:
- Reduces open/close overhead
- Enables connection pooling
- LRU eviction for memory management

#### 2. Direct Modification

```java
// NO temp file - modify ZIP directly
env.put("create", "true");
// Do NOT use: env.put("useTempFile", "true");
```

**Trade-offs**:
- **Faster**: No copy to temp, then rename
- **Risk**: Corruption if JVM crashes during write
- **Mitigation**: Use write-ahead logging or backup strategies

#### 3. Read-Only Access

```java
// Open in read-only mode for faster access
Map<String, String> env = new HashMap<>();
// Do not set "create" = no write capability
URI uri = URI.create("jar:" + zipPath.toUri());
try (FileSystem fs = FileSystems.newFileSystem(uri, env)) {
    // Read operations only
}
```

---

## 🔐 Security Considerations

### 1. Ownership Verification

```java
// Check ownership before allowing updates
Path ownerPubFile = root.resolve("owner.pub");
if (Files.exists(ownerPubFile)) {
    String existingOwner = Files.readString(ownerPubFile, UTF_8).trim();

    // Verify signature matches owner
    if (!verifyNostrSignature(request, existingOwner)) {
        throw new UnauthorizedException("Invalid signature");
    }
}
```

### 2. Nostr Signature Verification (NIP-98)

**HTTP Auth Header**:
```
Authorization: Nostr <base64-encoded-event>
```

**Event Structure**:
```json
{
  "kind": 27235,
  "created_at": 1699564801,
  "tags": [
    ["u", "https://server.com/profile/CR7BBQ"],
    ["method", "POST"]
  ],
  "content": "",
  "pubkey": "d4f2a8...",
  "sig": "a7f3b9..."
}
```

**Validation**:
- Verify signature matches pubkey
- Check timestamp within ±5 minutes (replay protection)
- Validate URL and method match request
- Ensure pubkey matches owner.pub

### 3. Path Traversal Protection

**Blocked Patterns**:
- `../` - Parent directory access
- `/` prefix - Absolute paths
- `\` - Windows path separators
- Symlinks outside ZIP

**Implementation**:
```java
Path normalized = root.resolve(userPath).normalize();
if (!normalized.startsWith(root)) {
    throw new SecurityException("Invalid path");
}
```

---

## 📋 Pattern: Message Group Archives

### Proposed Structure

```
MSG_<message-id-hash>.zip/
├── metadata.json              # Message group metadata
├── conversation.md            # Full conversation transcript
├── participants.json          # List of participants
├── attachments/               # Shared files
│   ├── photo_001.jpg
│   ├── photo_002.jpg
│   ├── video_001.mp4
│   └── document.pdf
├── receipts/                  # Delivery/read receipts
│   ├── delivery_ALICE.sig
│   ├── delivery_BOB.sig
│   ├── read_ALICE.sig
│   └── read_BOB.sig
└── relay-stamps/              # Relay path tracking
    ├── RELAY-A.sig
    ├── RELAY-B.sig
    └── RELAY-C.sig
```

### metadata.json

```json
{
  "version": 1,
  "message_id": "d4f2a8b1c3e5f7a9b2d4e6f8a0c2e4f6a8b0c2e4f6a8b0c2e4f6a8b0c2e4f6a8",
  "type": "group",
  "created": 1699564801,
  "updated": 1699565000,
  "participants": ["ALICE", "BOB", "CHARLIE"],
  "message_count": 42,
  "attachments_count": 5,
  "total_size_bytes": 2458670,
  "priority": "normal",
  "expires": 1700169601
}
```

### conversation.md

```markdown
# Group Conversation: Weekend Plans

**Created**: 2025-11-09 22:00:01
**Participants**: ALICE, BOB, CHARLIE

> 2025-11-09 22:00_01 -- ALICE-K5XYZ
Hey everyone! Who's up for hiking this weekend?

--> to: GROUP-WEEKEND
--> type: group
--> attachment-count: 1
--> id: d4f2a8b1c3e5...
--> signature: a7f3b9...

> 2025-11-09 22:03_15 -- BOB-W6ABC
I'm in! Saturday works for me.

--> to: GROUP-WEEKEND
--> type: group
--> icon_like: CHARLIE
--> id: e5f6a8b0c2d4...
--> signature: b8c0d2...

> 2025-11-09 22:05_42 -- CHARLIE-N0QST
Saturday is perfect. What trail?

--> to: GROUP-WEEKEND
--> type: group
--> id: f7a9b2d4e6f8...
--> signature: c9d1e3...

> 2025-11-09 22:07_20 -- ALICE-K5XYZ
How about Mount Wilson? Weather looks good.

--> to: GROUP-WEEKEND
--> type: group
--> attachment-count: 1
--> id: a0c2e4f6a8b0...
--> signature: d0e2f4...

## ATTACHMENT: 1
- mime-type: application/pdf
- filename: trail-map.pdf
- size: 125440
- checksum: sha256:c9d8e7f6...

# ATTACHMENT_DATA_START
JVBERi0xLjQKJeLjz9MKMSAwIG9iago8PAovVHlwZSAvQ2F0YWxvZwov...
# ATTACHMENT_DATA_END

---

## Delivery Status

- **ALICE**: Local (sender)
- **BOB**: Delivered 22:01:30 (RELAY-B), Read 22:03:10
- **CHARLIE**: Delivered 22:02:15 (RELAY-C), Read 22:05:35

## Relay Path

1. ALICE → RELAY-A (22:00:15)
2. RELAY-A → RELAY-B (22:01:10)
3. RELAY-B → BOB (22:01:30)
4. RELAY-B → RELAY-C (22:01:45)
5. RELAY-C → CHARLIE (22:02:15)
```

---

## 📋 Pattern: Relay Message Archives

### Batch Archive Structure

```
RELAY_BATCH_<timestamp>.zip/
├── index.json                 # Batch metadata
├── messages/                  # Individual message files
│   ├── ALICE_2025-11-09_22-00_normal_a7c5b1.md
│   ├── BOB_2025-11-09_22-15_urgent_f3d8a2.md
│   └── CHARLIE_2025-11-09_22-30_normal_b4e7c9.md
├── attachments/               # Shared media
│   ├── a7c5b1/               # Organized by message sig
│   │   ├── image001.jpg
│   │   └── image002.jpg
│   └── f3d8a2/
│       └── video001.mp4
└── receipts/                  # Delivery receipts
    ├── delivery_a7c5b1.sig
    └── delivery_f3d8a2.sig
```

### index.json

```json
{
  "version": 1,
  "batch_id": "BATCH_20251109_220000",
  "created": 1699564800,
  "relay_id": "RELAY-A",
  "message_count": 42,
  "storage_size_bytes": 15728640,
  "grid_targets": ["RY1A-IUZS", "RY1B-JVZT"],
  "priority_distribution": {
    "urgent": 3,
    "normal": 38,
    "low": 1
  },
  "messages": [
    {
      "id": "d4f2a8b1c3...",
      "from": "ALICE",
      "to": "BOB",
      "timestamp": 1699564801,
      "filename": "ALICE_2025-11-09_22-00_normal_a7c5b1.md",
      "size": 5420,
      "attachments": 2
    }
  ]
}
```

---

## 🔧 Best Practices

### 1. Naming Conventions

**ZIP Filenames**:
- Use identifiers, not random names: `CR7BBQ.zip` not `abc123.zip`
- Include timestamp for batches: `BATCH_20251109_220000.zip`
- Keep short (< 100 chars for filesystem compatibility)

**Internal Paths**:
- Use lowercase for consistency: `messages/` not `Messages/`
- Standard extensions: `.json`, `.md`, `.jpg`
- Date format: `YYYY-MM-DD` not `MM-DD-YYYY`

### 2. File Organization

**Flat is Better**:
- Root files: metadata, config, index
- One level of folders max when possible
- Folders only for categories or time-sharding

**Time-Based Sharding**:
```
YYYY/YYYY-MM-DD.md          # Good for daily content
YYYY-MM/YYYY-MM-DD.md       # Good for monthly archives
YYYY/MM/YYYY-MM-DD.md       # Avoid - harder to navigate
```

### 3. Metadata First

Always include root-level metadata file:
- Quick inspection without extraction
- Version tracking
- Content summary

### 4. Human-Readable Content

Include at least one text-based file:
- `README.md` - What this archive contains
- `index.md` - Navigation/table of contents
- `conversation.md` - Main content

Users can unzip and read without special tools.

### 5. Size Management

**Recommendations**:
- Keep archives < 100MB when possible
- Split large conversations into multiple zips
- Compress images before adding
- Use external references for very large files

**Example Split**:
```
conversation_2025-01.zip    # January messages
conversation_2025-02.zip    # February messages
conversation_2025-03.zip    # March messages
```

### 6. Atomic Updates

**Safe Pattern**:
```java
// 1. Write to temporary location
Path tempZip = Paths.get("/tmp/" + UUID.randomUUID() + ".zip");
writeZipContent(tempZip, content);

// 2. Atomic move to final location
Files.move(tempZip, finalZip, StandardCopyOption.ATOMIC_MOVE);
```

**Benefits**:
- Never corrupt existing archive
- All-or-nothing update
- Safe concurrent access

---

## 🧪 Testing & Validation

### Validation Checklist

- [ ] Contains required metadata file
- [ ] All paths are relative (no `/` prefix)
- [ ] No path traversal sequences (`../`)
- [ ] File extensions match content type
- [ ] JSON files are valid and pretty-printed
- [ ] Markdown files render correctly
- [ ] Archive size is reasonable
- [ ] All referenced attachments exist
- [ ] Signatures verify correctly

### Test Tools

**Command Line**:
```bash
# List contents
unzip -l archive.zip

# Validate structure
unzip -t archive.zip

# Extract and inspect
unzip archive.zip -d /tmp/test
cat /tmp/test/metadata.json | jq .
```

**Java Test**:
```java
@Test
public void testArchiveStructure() throws IOException {
    Path zip = Paths.get("test.zip");

    try (FileSystem fs = FileSystems.newFileSystem(zip)) {
        Path root = fs.getPath("/");

        // Verify required files
        assertTrue(Files.exists(root.resolve("metadata.json")));

        // Validate JSON
        String json = Files.readString(root.resolve("metadata.json"));
        JsonObject obj = JsonParser.parseString(json).getAsJsonObject();
        assertTrue(obj.has("version"));
    }
}
```

---

## 📚 References

### Implementation Code

- **CallSignDatabase.java**: Primary ZIP implementation with caching
- **CallSignDatabaseSingle.java**: Simple ZIP implementation (Java 7 compatible)
- **Names.java**: File naming constants
- **ProfileAPI.java**: HTTP API for profile access

### External Resources

- **Java NIO Zip FileSystem**: [Oracle Docs](https://docs.oracle.com/javase/8/docs/technotes/guides/io/fsp/zipfilesystemprovider.html)
- **NOSTR Protocol**: [nostr.com](https://nostr.com)
- **ZIP Format Spec**: [PKWARE](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT)

---

## 🚀 Future Enhancements

### Planned Features

1. **Encryption Support**
   - Encrypted ZIP archives (AES-256)
   - Per-file encryption
   - Key management integration

2. **Compression Options**
   - Configurable compression levels
   - Algorithm selection (DEFLATE, BZIP2, XZ)
   - Selective compression by file type

3. **Streaming Support**
   - Stream large files without loading into memory
   - Chunked transfer over HTTP
   - Progressive download

4. **Delta Updates**
   - Only update changed files
   - Incremental sync between devices
   - Conflict resolution

5. **Archive Splitting**
   - Automatic split for size limits
   - Multi-part archives (.z01, .z02, .zip)
   - Reassembly on read

---

**Version**: 1.0
**Status**: Design & Implementation Reference
**Maintained By**: Geogram Contributors
