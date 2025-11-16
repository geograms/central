# Implementation Status

This document tracks the implementation status of collection features across different platforms and compares the specification with actual implementations.

## Specification vs. Implementation

### Full Specification (from recovered documentation)

The complete collection specification includes:

#### Distribution Format
- ✓ ZIP archive format (`.colz` or `.collection.zip`)
- ✓ Ordered file structure (metadata first)
- ✓ Compression optimization
- ✓ ZIP64 support for large collections

#### Core Files
- ✓ `collection.json` - Collection metadata
- ✓ `tree.json` - File manifest with hashes
- ✓ `log.txt` - Change history
- ✓ `feed.rss` - RSS/Atom feed for updates

#### Metadata Features
- ✓ Multiple authors with roles (owner, admin, contributor)
- ✓ Lightning address for donations
- ✓ Social media fields (Twitter, Mastodon, GitHub, Matrix)
- ✓ NOSTR relay hints
- ✓ NOSTR event_id
- ✓ allowed_contributors list (separate from whitelisted_users)
- ✓ Rich per-file metadata

#### Hash Algorithms
- ✓ SHA-1 (required)
- ✓ TLSH (required for fuzzy matching)
- ✓ SHA-256 (recommended)
- ✓ MD5 (optional, legacy)

#### Advanced Features
- ✓ Nested sub-collections
- ✓ File submission workflow (PENDING/APPROVED/REJECTED)
- ✓ Detailed change logging
- ✓ RSS/Atom feed generation
- ✓ Per-file author attribution
- ✓ Per-file timestamps (added/modified)

---

## Android Implementation Status

### Current Implementation (as of 2025-11-16)

The Android app (`geogram-android`) implements a subset of the full specification:

#### Implemented ✓

**Core Features**:
- ✓ Collection creation and management
- ✓ Folder-based storage (extracted format)
- ✓ Collection browsing and file access
- ✓ Remote collection access via P2P
- ✓ Nostr key pair generation (npub/nsec)
- ✓ Collection ownership tracking
- ✓ Favorites management

**Files**:
- ✓ `collection.js` (JavaScript-embedded JSON)
- ✓ `extra/security.json` (Security configuration)
- ✓ `extra/tree-data.js` (File index with SHA1 hashes)

**Security**:
- ✓ Visibility levels (public, private, password, group)
- ✓ Permissions (public_read, submissions, interactions)
- ✓ Whitelisted users
- ✓ Blocked users
- ✓ Content warnings
- ✓ Age restrictions

**Features**:
- ✓ File/folder addition and removal
- ✓ Collection rescan
- ✓ Torrent generation
- ✓ P2P HTTP API for remote access
- ✓ Search within collections

#### Partially Implemented ⚠️

**File Format**:
- ⚠️ Uses `tree-data.js` instead of `tree.json`
- ⚠️ Only SHA-1 hashes (no TLSH, SHA-256)
- ⚠️ JavaScript-embedded format (`window.TREE_DATA = ...`)
- ⚠️ No per-file author or timestamp tracking

**Metadata**:
- ⚠️ Single owner only (no multiple authors with roles)
- ⚠️ Basic metadata fields only
- ⚠️ No social media fields
- ⚠️ No Lightning address
- ⚠️ No NOSTR relay hints or event_id

#### Not Implemented ✗

**Distribution**:
- ✗ ZIP archive creation (`.colz` files)
- ✗ ZIP archive extraction
- ✗ Archive compression/decompression

**Advanced Files**:
- ✗ `log.txt` changelog
- ✗ `feed.rss` update feed

**Advanced Features**:
- ✗ Nested sub-collections
- ✗ File submission workflow (PENDING/APPROVED/REJECTED)
- ✗ allowed_contributors (separate from whitelisted_users)
- ✗ TLSH fuzzy hashing
- ✗ Multi-author collaboration
- ✗ RSS feed generation
- ✗ Detailed change history

**Hash Algorithms**:
- ✗ TLSH hashes
- ✗ SHA-256 hashes
- ✗ Root hash for entire collection

---

## File Format Differences

### collection.js vs collection.json

**Specification** (`collection.json`):
```json
{
  "version": "1.0",
  "collection": {
    "id": "npub1...",
    "title": "Example",
    ...
  },
  "authors": [
    {
      "npub": "npub1...",
      "role": "owner",
      "joined": "2025-11-16T10:00:00Z"
    }
  ],
  "metadata": {
    "lightning_address": "user@getalby.com",
    "social": {
      "twitter": "user",
      "github": "user"
    }
  },
  "nostr": {
    "relay_hints": ["wss://relay.example.com"],
    "event_id": "..."
  }
}
```

**Android Implementation** (`collection.js`):
```javascript
window.COLLECTION_DATA = {
  "version": "1.0",
  "collection": {
    "id": "npub1...",
    "title": "Example",
    ...
  },
  // No authors array
  // No lightning_address
  // No social fields
  // No nostr section
  "metadata": {
    "category": "general",
    "language": "en",
    ...
  }
}
```

### tree.json vs tree-data.js

**Specification** (`tree.json`):
```json
{
  "version": "1.0",
  "generated": "2025-11-16T10:00:00Z",
  "root_hash": "sha256-of-entire-tree",
  "tree": [
    {
      "path": "file.txt",
      "type": "file",
      "size": 1024,
      "hashes": {
        "sha1": "abc123...",
        "tlsh": "T1234...",
        "sha256": "def456..."
      },
      "added": "2025-11-16T10:00:00Z",
      "modified": "2025-11-16T10:00:00Z",
      "author": "npub1...",
      "metadata": {
        "title": "Example File",
        "description": "...",
        "tags": ["example"]
      }
    }
  ]
}
```

**Android Implementation** (`extra/tree-data.js`):
```javascript
window.TREE_DATA = [
  {
    "path": "file.txt",
    "name": "file.txt",
    "type": "file",
    "size": 1024,
    "mimeType": "text/plain",
    "hashes": {
      "sha1": "abc123..."  // Only SHA-1
    },
    "metadata": {
      "mime_type": "text/plain"
      // No title, description, tags, author, timestamps
    }
  }
]
```

---

## Migration Path

### Phase 1: Current State
- Android uses folder-based storage
- Basic metadata and SHA-1 hashes
- Works for local and P2P access

### Phase 2: Enhanced Metadata
- Add TLSH hashes
- Add per-file metadata (author, timestamps)
- Add multiple authors support
- Add social media and Lightning address fields
- Add NOSTR integration fields

### Phase 3: Changelog & Feeds
- Implement `log.txt` generation
- Implement `feed.rss` generation
- Track all changes automatically
- Generate feeds from changelog

### Phase 4: ZIP Archive Support
- Add `.colz` file extraction
- Add `.colz` file creation
- Support both folder and archive modes
- Implement compression optimization

### Phase 5: Advanced Features
- Nested sub-collections
- File submission workflow
- Multi-author collaboration
- Differential updates

---

## Compatibility Strategy

### Backward Compatibility

**Reading Collections**:
- Support both `tree.json` and `tree-data.js`
- Support both `collection.json` and `collection.js`
- Gracefully handle missing fields
- Default values for new features

**Creating Collections**:
- Generate both old and new formats during transition
- Prioritize new format for new collections
- Maintain old format for compatibility

### Forward Compatibility

**Version Field**:
```json
{
  "version": "1.0",  // Current spec version
  ...
}
```

- Clients check version before parsing
- Support multiple versions
- Migration tools for upgrading

### Feature Detection

```java
// Check if collection uses new format
boolean hasNewFormat = collectionHasFile("tree.json") ||
                       collectionHasFile("log.txt");

// Check if ZIP archive
boolean isArchive = collectionPath.endsWith(".colz") ||
                    collectionPath.endsWith(".collection.zip");

// Adapt behavior accordingly
if (isArchive) {
    extractArchive(collectionPath);
} else {
    loadFolderCollection(collectionPath);
}
```

---

## Recommendations

### For New Implementations

1. **Follow full specification** from the start
2. **Use ZIP archives** for distribution
3. **Implement all required hash algorithms** (SHA-1, TLSH, SHA-256)
4. **Generate log.txt and feed.rss** automatically
5. **Support multi-author collaboration**

### For Existing Android Implementation

1. **Short-term**: Add TLSH hashes and per-file metadata
2. **Medium-term**: Implement log.txt and feed.rss
3. **Long-term**: Add ZIP archive support
4. **Maintain backward compatibility** with existing collections

### For Users

1. **Current**: Collections work in folder format
2. **Future**: Will support both folder and ZIP formats
3. **Migration**: Old collections will be automatically upgraded
4. **No action needed**: Existing collections will continue to work

---

## Feature Comparison Table

| Feature | Specification | Android | Priority |
|---------|--------------|---------|----------|
| Collection creation | ✓ | ✓ | - |
| File browsing | ✓ | ✓ | - |
| SHA-1 hashes | ✓ | ✓ | - |
| TLSH hashes | ✓ | ✗ | High |
| SHA-256 hashes | ✓ | ✗ | Medium |
| ZIP archives | ✓ | ✗ | High |
| log.txt | ✓ | ✗ | Medium |
| feed.rss | ✓ | ✗ | Low |
| Multiple authors | ✓ | ✗ | Medium |
| Lightning address | ✓ | ✗ | Low |
| Social media fields | ✓ | ✗ | Low |
| NOSTR integration | ✓ | ✗ | Medium |
| Per-file metadata | ✓ | ✗ | High |
| Per-file timestamps | ✓ | ✗ | Medium |
| Nested collections | ✓ | ✗ | Low |
| Submission workflow | ✓ | ✗ | Medium |

---

## Testing Compatibility

### Test Collection

Create a test collection that uses both formats:

```
test-collection/
├── collection.json       # New format
├── collection.js         # Old format (for compatibility)
├── tree.json            # New format
├── extra/
│   └── tree-data.js     # Old format (for compatibility)
├── log.txt              # New format
├── feed.rss             # New format
└── test-file.txt
```

Both old and new clients should be able to read this collection.

---

## Related Documentation

- [File Formats](file-formats.md) - Complete file format specifications
- [Distribution Format](distribution-format.md) - ZIP archive details
- [Changelog and Feeds](changelog-and-feeds.md) - log.txt and feed.rss specs
- [Architecture](architecture.md) - Android implementation details
