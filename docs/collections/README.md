# Geogram Collections

## Overview

Collections are a core feature of Geogram that enable users to organize, share, and distribute files in a decentralized manner. Each collection is a self-contained package of files with metadata, security settings, and cryptographic identity based on Nostr protocol keys.

## What is a Collection?

A collection is:
- A **ZIP archive** (`.colz` or `.collection.zip`) containing files and metadata
- Can also be extracted as a folder for direct access
- Associated metadata (title, description, statistics, authors)
- Security and permission settings
- A unique Nostr public key (npub) identity
- Cryptographic hashes for integrity verification (SHA-1, TLSH, SHA-256)
- Change history tracking (log.txt)
- RSS/Atom feed for updates (feed.rss)
- Optional encryption and access controls
- Shareable via P2P networking, torrents, HTTP, and IPFS

## Key Features

### Decentralized Identity
- Each collection has a unique Nostr key pair (npub/nsec)
- Collections are identified by their public key (npub)
- Owner holds the private key (nsec) for administrative control

### Flexible Security
- **Public**: Open access for everyone
- **Private**: Owner-only access
- **Password**: Password-protected access (planned)
- **Group**: Whitelist-based access control

### Rich Metadata
- Title, description, and thumbnails
- Multiple authors with roles (owner, admin, contributor)
- Statistics (views, likes, downloads, ratings)
- Tags and categorization
- License and copyright information
- Contact information (email, Nostr, Matrix)
- Social media (Twitter, Mastodon, GitHub)
- Donation addresses (Bitcoin, Lightning Network)

### P2P Sharing
- Share collections over local networks
- Browse remote collections from connected devices
- Download individual files on-demand
- Torrent file generation for distribution

### User Interactions
- Favorite collections for quick access
- Comment, like, and rate collections
- Submit files to collections (with approval workflow)
- View statistics and analytics

## Use Cases

1. **Content Distribution**: Share documents, media, or software packages
2. **Collaborative Libraries**: Build shared knowledge bases with controlled submissions
3. **Offline Publishing**: Distribute content without internet connectivity
4. **Privacy-Preserving Sharing**: Share files with specific users via whitelists
5. **Archival**: Preserve and organize historical documents or media

## Quick Start

### Creating a Collection
1. Open Collections screen
2. Tap the "+" FAB button
3. Enter title and description
4. Select folder location (auto or custom)
5. Save to generate collection

### Browsing a Collection
1. Tap on a collection from the list
2. Navigate through folders like a file browser
3. Tap files to open with associated apps
4. Use search to find specific files

### Sharing a Collection
1. Open collection info screen
2. Copy the npub identifier to share
3. Generate torrent file for distribution
4. Or share over P2P network to nearby devices

## Documentation Structure

### Core Documentation
- **[Architecture](architecture.md)** - System design and components
- **[File Formats](file-formats.md)** - Metadata file specifications
- **[Security Model](security-model.md)** - Permissions and access control
- **[Metadata Specification](metadata-specification.md)** - Metadata standards

### Distribution & Updates
- **[Distribution Format](distribution-format.md)** - ZIP archive (.colz) format
- **[Changelog and Feeds](changelog-and-feeds.md)** - log.txt and feed.rss specifications

### Developer Resources
- **[API Reference](api-reference.md)** - Programming interfaces
- **[P2P Integration](p2p-integration.md)** - Remote access and sharing
- **[Implementation Status](IMPLEMENTATION_STATUS.md)** - Spec vs Android implementation

### User Resources
- **[User Guide](user-guide.md)** - Detailed user instructions
- **[Examples](examples/)** - Sample collection files
- **[Schemas](schemas/)** - JSON schemas for validation

## Technical Overview

### Distribution Format

**ZIP Archive** (Recommended):
```
collection-name-v1.0.0.colz  (or .collection.zip)
```

**Extracted Folder Structure**:
```
collection-name/
├── collection.json        # Main metadata (specification)
├── collection.js          # Main metadata (Android implementation)
├── tree.json              # File index with hashes (specification)
├── log.txt                # Change history log
├── feed.rss               # RSS/Atom update feed
├── extra/
│   ├── security.json      # Security settings
│   ├── tree-data.js       # File index (Android implementation)
│   └── *.torrent          # Torrent files
├── folder1/
│   └── file1.txt
└── file2.pdf
```

### Key Files
- **collection.json** / **collection.js**: Collection metadata
- **tree.json** / **tree-data.js**: Complete file tree with cryptographic hashes
- **security.json**: Security and permission configuration
- **log.txt**: Chronological change history
- **feed.rss**: RSS/Atom feed for updates
- **Collection archive**: Single `.colz` ZIP file for distribution

**Note**: The specification uses `.json` files while the Android implementation currently uses JavaScript-embedded formats (`.js`) and stores files in `extra/` folder. See [Implementation Status](IMPLEMENTATION_STATUS.md) for details.

### Integration Points
- **Nostr Protocol**: For cryptographic identity
- **P2P Networking**: For remote collection access
- **BitTorrent**: For file distribution
- **Android Storage**: For local file management

## Implementation Notes

### Specification vs. Android

This documentation describes the **full collection specification** which includes advanced features like ZIP archives, TLSH hashes, multiple authors, and RSS feeds.

The **Android implementation** currently supports a subset of these features, using folder-based storage and basic metadata. See [Implementation Status](IMPLEMENTATION_STATUS.md) for a detailed comparison and migration path.

**Key Differences**:
- Specification uses `.json` files, Android uses `.js` (JavaScript-embedded)
- Specification uses `tree.json`, Android uses `extra/tree-data.js`
- Specification supports ZIP archives (`.colz`), Android uses folders
- Specification requires TLSH hashes, Android only has SHA-1
- Specification supports multiple authors, Android has single owner
- Specification includes `log.txt` and `feed.rss`, Android doesn't yet

Both formats are compatible and collections can be migrated between them.

## Version

**Specification version**: 1.0
**Android implementation**: 0.9 (partial)

See [Implementation Status](IMPLEMENTATION_STATUS.md) for feature comparison.

## License

See project license for details.
