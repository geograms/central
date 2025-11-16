# Classic Sci-Fi Books Collection - Practical Example

This directory contains a complete, practical example of a Geogram collection showcasing a curated library of classic science fiction books in markdown format.

## Collection Overview

**Title**: Classic Sci-Fi Books Collection
**Description**: A curated collection of classic science fiction literature from the golden age, including works by Asimov, Heinlein, Herbert, and Le Guin.
**Format**: Books converted to markdown for easy reading on any device
**Total Size**: ~2.5 MB
**Total Files**: 15 files (12 books + metadata files)

## Folder Structure

```
classic-scifi-books/
├── collection.js                # Collection metadata
├── log.txt                      # Change history
├── feed.rss                     # RSS feed for updates
├── README.md                    # This file
├── thumbnail.png                # Collection thumbnail (256x256)
├── extra/
│   ├── security.json           # Security settings
│   ├── tree-data.js            # File index with SHA-1 and TLSH hashes
│   └── collection_v1.0.0.torrent
├── books/
│   ├── asimov/
│   │   ├── README.md           # About Asimov
│   │   ├── foundation.md       # Foundation (1951)
│   │   ├── foundation-cover.jpg
│   │   ├── i-robot.md          # I, Robot (1950)
│   │   └── i-robot-cover.jpg
│   ├── heinlein/
│   │   ├── README.md           # About Heinlein
│   │   ├── stranger.md         # Stranger in a Strange Land (1961)
│   │   ├── stranger-cover.jpg
│   │   ├── moon.md             # The Moon is a Harsh Mistress (1966)
│   │   └── moon-cover.jpg
│   ├── herbert/
│   │   ├── README.md           # About Herbert
│   │   ├── dune.md             # Dune (1965)
│   │   └── dune-cover.jpg
│   └── le-guin/
│       ├── README.md           # About Le Guin
│       ├── left-hand.md        # The Left Hand of Darkness (1969)
│       └── left-hand-cover.jpg
└── guides/
    ├── how-to-read.md          # Tips for reading markdown books
    └── contributing.md         # How to contribute to collection
```

## Files Included

### Metadata Files (Required)
1. **collection.js** - Main collection metadata
2. **extra/tree-data.js** - Complete file manifest with SHA-1 and TLSH hashes
3. **extra/security.json** - Security configuration (public, allows submissions)
4. **log.txt** - Change history since creation
5. **feed.rss** - RSS feed for collection updates

### Content Files

#### Books (Markdown Format)
- **Isaac Asimov**
  - Foundation (1951) - Epic tale of galactic empire's fall
  - I, Robot (1950) - Collection of robot stories introducing Three Laws

- **Robert A. Heinlein**
  - Stranger in a Strange Land (1961) - Story of a human raised by Martians
  - The Moon is a Harsh Mistress (1966) - Lunar rebellion story

- **Frank Herbert**
  - Dune (1965) - Epic of desert planet Arrakis

- **Ursula K. Le Guin**
  - The Left Hand of Darkness (1969) - Gender and society on alien world

#### Supporting Files
- Author README files (biographical info and book summaries)
- Cover images (JPEG format, optimized)
- Reading guides
- Contributing guidelines

## Usage

### Viewing Books

Books are in markdown format and can be read with:
- Any text editor (VS Code, Sublime, Notepad++)
- Markdown viewers (Typora, Obsidian, Marktext)
- Web browsers with markdown extensions
- E-readers that support markdown
- Command line: `less books/asimov/foundation.md`

### Adding Books

This collection accepts community submissions:
1. Fork the collection (create your own copy)
2. Add new books in markdown format
3. Follow the folder structure (author/book.md)
4. Include cover image if available
5. Update author README with book info
6. Submit via NOSTR with file hash

### File Format

All books follow this markdown structure:

```markdown
# Book Title

**Author**: Author Name
**Published**: Year
**Genre**: Science Fiction

## Synopsis

Brief description...

## Chapter 1: Title

Content...

## Chapter 2: Title

Content...
```

## Hashes and Integrity

All files include:
- **SHA-1**: Standard hash for exact matching (required)
- **TLSH**: Fuzzy hash for finding similar versions (required)
- **SHA-256**: Enhanced security (optional, not in this example)

Verify integrity by comparing hashes in `extra/tree-data.js` with actual file hashes.

## Version History

- **v1.0.0** (2025-11-12): Initial release with 6 books
- **v1.1.0** (2025-11-13): Added Heinlein's "The Moon is a Harsh Mistress"
- **v1.2.0** (2025-11-15): Added Le Guin's "The Left Hand of Darkness"

See `log.txt` for detailed change history.

## Subscription

Subscribe to updates via:
- **RSS**: Add `feed.rss` to your RSS reader
- **NOSTR**: Follow npub1qvr3x8zjxyz9qwer... for announcements
- **Torrent**: Seed `extra/collection_v1.0.0.torrent` for distribution

## License

Books in this collection are in the **public domain** or used with permission.

Collection metadata licensed under **CC0-1.0** (public domain).

## Creator

**Curator**: npub1qvr3x8zjxyz9qwer...
**Contact**: scifi-curator@example.com
**Lightning**: curator@getalby.com
**GitHub**: github.com/scifi-curator

## Related Collections

- Modern Sci-Fi Collection (npub1xyz...)
- Fantasy Classics Collection (npub1abc...)
- Cyberpunk Collection (npub1def...)
