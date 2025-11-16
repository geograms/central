# Collection Distribution Format

## Overview

Collections are distributed as **ZIP archive files** for easy sharing, storage, and integrity verification. This format enables single-file distribution while maintaining the ability to extract and browse the collection as a regular folder structure.

## File Extension

Collections use one of two file extensions:
- **`.collection.zip`** - Full, descriptive format
- **`.colz`** - Short form (optional, for brevity)

Both are standard ZIP archives using DEFLATE compression.

## File Naming Convention

**Format**: `collection-name-v{version}.collection.zip`

**Examples**:
- `classic-scifi-books-v1.0.0.collection.zip`
- `linux-utilities-v2.3.1.colz`
- `retro-games-2025-11-16.collection.zip`

**Guidelines**:
- Use URL-safe characters (lowercase letters, numbers, hyphens, underscores)
- No spaces or special characters
- Include version number or date for tracking
- Keep names reasonably short but descriptive

## ZIP Archive Structure

### File Order

Files are ordered in the ZIP for optimal access:

1. **collection.json** - First (fast metadata access)
2. **tree.json** - Second (file manifest)
3. **log.txt** - Third (change history)
4. **feed.rss** - Fourth (update feed)
5. **Thumbnails** - Next (quick preview)
6. **Content files** - Sorted alphabetically

This ordering allows clients to quickly access metadata without extracting the entire archive.

### Compression Settings

**Text Files** (JSON, TXT, MD, etc.):
- Compression: DEFLATE with level 9 (maximum)
- Significant size reduction

**Already-Compressed Files** (JPG, PNG, MP4, ZIP, etc.):
- Compression: Store mode (no compression)
- Avoids wasted CPU cycles

**Configuration**:
```
Compression level: 6-9 recommended for balance
- Level 6: Faster compression, moderate ratio
- Level 9: Maximum compression, slower
```

### ZIP64 Support

**When to use**:
- Collections larger than 4GB
- More than 65,535 files
- Required for large media collections

**Compatibility**:
- Supported by all modern ZIP tools
- Broad compatibility across platforms

### Archive Metadata

**ZIP Comment Field**:
```
Collection ID: npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3z0qwe
Version: 1.0.0
```

**Extra Fields**:
- Can store collection ID for fast lookup
- No sensitive data (unencrypted)

## Working with Collection Archives

### Creating a Collection Archive

**From collection folder**:
```bash
# Create with proper ordering
zip -9 -r collection-name-v1.0.0.collection.zip collection-folder/ \
    -i collection.json tree.json log.txt feed.rss "*.png" "*"

# Or use short form
zip -9 -r collection-name.colz collection-folder/
```

**With optimal compression**:
```bash
# Store mode for compressed files
zip -9 -r collection.colz collection-folder/ -n .jpg:.png:.mp4:.zip:.gz
```

### Extracting a Collection

**Full extraction**:
```bash
# Extract to directory
unzip collection-name.colz -d ./collections/

# Extract to current directory
unzip collection-name.colz
```

**Partial extraction** (metadata only):
```bash
# Extract only metadata files
unzip collection-name.colz collection.json tree.json log.txt

# Quick metadata view (no extraction)
unzip -p collection-name.colz collection.json | jq .
```

### Listing Contents

```bash
# List all files
unzip -l collection-name.colz

# List with details
unzip -lv collection-name.colz
```

### Verifying Integrity

**ZIP integrity**:
```bash
# Test ZIP archive
unzip -t collection-name.colz

# Verify with CRC
zip -T collection-name.colz
```

**Collection hash**:
```bash
# Compute SHA256 of entire archive
sha256sum collection-name.colz

# Compare with published hash (from NOSTR event)
echo "expected-hash  collection-name.colz" | sha256sum -c
```

## Storage Modes

### Compressed Form (Recommended for Distribution)

**Advantages**:
- Single file (easy to share, copy, backup)
- Smaller size (compressed)
- Integrity verification (single hash)
- CDN-friendly (easy caching)
- Torrent-friendly (single file seeding)

**Use Cases**:
- Publishing collections
- Backup and archival
- Network transfer
- IPFS/Bittorrent distribution

### Extracted Form (Recommended for Use)

**Advantages**:
- Direct file access (no extraction needed)
- Faster browsing
- Easy editing and modification
- System file managers work natively

**Use Cases**:
- Active collections (frequently accessed)
- Editing and curation
- Local browsing

### Dual Storage (Recommended)

Maintain both forms:
- **Compressed**: For backup and distribution
- **Extracted**: For daily use

When collection is updated:
1. Modify extracted version
2. Re-compress to new .colz file
3. Publish new version

## Distribution Methods

### HTTP Download

**Simple hosting**:
```
https://example.com/collections/collection-name-v1.0.0.collection.zip
```

**With CDN**:
```
https://cdn.example.com/collections/collection-name.colz
```

**Advantages**:
- Simple setup
- HTTP range requests (resume downloads)
- Standard web caching
- Easy to mirror

### IPFS

**Add collection**:
```bash
ipfs add collection-name.colz
# Returns: QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

**Access via gateway**:
```
https://ipfs.io/ipfs/QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

**Advantages**:
- Content-addressed (CID)
- Decentralized storage
- Automatic deduplication
- Persistent availability

### Bittorrent

**Create torrent**:
```bash
transmission-create -o collection-name.torrent collection-name.colz
```

**Magnet link**:
```
magnet:?xt=urn:btih:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX&dn=collection-name.colz
```

**Advantages**:
- Distributed bandwidth
- Resilient to server failures
- Faster for popular collections
- Community seeding

### NOSTR Integration

**Collection announcement event**:
```json
{
  "kind": 30000,
  "content": {
    "collection_id": "npub1...",
    "title": "My Collection",
    "version": "1.0.0",
    "tree_hash": "sha256:...",
    "archive_hash": "sha256:...",
    "download_hints": [
      "https://example.com/collection.colz",
      "ipfs://QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "magnet:?xt=urn:btih:XXXXXXXXXX"
    ]
  }
}
```

## Synchronization Strategies

### Full Sync

**Process**:
1. Download entire .colz file
2. Verify SHA256 hash
3. Extract to local folder

**Best for**:
- Small/medium collections (< 100MB)
- First-time downloads
- Complete integrity verification

### Incremental Sync

**Process**:
1. Check collection's `tree.json` root_hash
2. Compare with local version
3. Download new .colz only if different

**Best for**:
- Regular updates
- Bandwidth conservation
- Version tracking

### Differential Sync (Advanced)

**Using rsync-style binary diffs**:
```bash
# Generate binary diff
bsdiff old-collection.colz new-collection.colz collection.patch

# Apply patch
bspatch old-collection.colz new-collection.colz collection.patch
```

**Best for**:
- Large collections (>1GB)
- Frequent small updates
- Bandwidth-constrained environments

### Smart Sync (Selective Download)

**Process**:
1. Download collection.json and tree.json only
2. Show user available content
3. User selects desired files
4. Extract only selected files from ZIP

**ZIP partial extraction**:
```bash
# Extract specific files
unzip collection.colz "books/sci-fi/*" -d ./my-collection/
```

**Best for**:
- Very large collections
- Limited storage
- Selective interest

## Performance Optimization

### Lazy Loading

Don't extract entire archive upfront:
1. Keep .colz file
2. Extract metadata files only
3. Extract content files on-demand

### Caching

**Metadata cache**:
- Cache collection.json in memory
- Cache tree.json index in database
- Avoid repeated ZIP access

**Content cache**:
- Cache recently accessed files
- LRU eviction policy
- Configurable cache size

### Streaming

**ZIP streaming** (future):
- Read files directly from ZIP without full extraction
- Useful for media playback
- Reduces disk usage

## Migration Between Formats

### Folder → ZIP Archive

```bash
# Create archive from folder
cd /path/to/collection-folder
zip -9 -r ../collection-name.colz .

# Verify
unzip -t ../collection-name.colz
```

### ZIP Archive → Folder

```bash
# Extract archive
unzip collection-name.colz -d /path/to/collection-folder

# Verify structure
ls -la /path/to/collection-folder
```

### Maintaining Both

**Workflow**:
1. Work with extracted folder
2. When ready to publish:
   ```bash
   # Update metadata
   ./update-tree-json.sh

   # Create ZIP
   zip -9 -r collection-v1.1.0.colz collection-folder/

   # Compute hash
   sha256sum collection-v1.1.0.colz

   # Publish
   cp collection-v1.1.0.colz /var/www/collections/
   ```

## Compatibility Notes

### Android Implementation

**Current status**: The Android app uses extracted folder format

**Compatibility**:
- Can extract .colz files
- Works with folder structure
- May not create .colz files yet (uses folders)

**Migration path**:
- Phase 1: Support reading .colz files
- Phase 2: Support creating .colz files
- Phase 3: Dual mode (compressed + extracted)

### Cross-Platform

**ZIP compatibility**:
- Windows: Native support (Explorer)
- macOS: Native support (Finder)
- Linux: All distros (unzip, file-roller, ark, etc.)
- Android: Multiple apps (ZArchiver, etc.)
- iOS: Native support (Files app)

## Best Practices

### For Collection Creators

1. **Always create .colz files** for distribution
2. **Include version in filename**
3. **Compute and publish SHA256 hash**
4. **Provide multiple download options** (HTTP, IPFS, torrent)
5. **Keep old versions** for rollback capability

### For Collection Users

1. **Verify archive integrity** after download
2. **Extract to dedicated folder** (don't clutter)
3. **Keep .colz file** as backup
4. **Check for updates** regularly
5. **Seed torrents** if using Bittorrent

### For Developers

1. **Support both .colz and extracted formats**
2. **Implement lazy loading** for large collections
3. **Cache metadata** for performance
4. **Use ZIP64** for large collections
5. **Validate structure** after extraction

## Related Documentation

- [File Formats](file-formats.md) - Metadata file specifications
- [Architecture](architecture.md) - System design
- [User Guide](user-guide.md) - User instructions
