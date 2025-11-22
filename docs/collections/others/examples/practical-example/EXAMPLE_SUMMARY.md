# Practical Example Summary

## What This Example Demonstrates

This is a **complete, realistic example** of a Geogram collection that demonstrates all the key features of the collection specification.

## Files Created

### Complete File List

```
practical-example/
├── README.md                    # Overview and usage guide
├── EXAMPLE_SUMMARY.md          # This file
├── collection.js                # Collection metadata with full details
├── log.txt                      # Complete change history
├── feed.rss                     # RSS feed with updates
├── extra/
│   ├── security.json           # Public collection, allows submissions
│   └── tree-data.js            # Complete file manifest with SHA-1 & TLSH
└── books/
    └── asimov/
        ├── README.md           # Isaac Asimov biography
        └── foundation.md       # Full sample book in markdown
```

## Key Features Demonstrated

### 1. Folder Structure ✓
- **Multiple levels**: Root → books → asimov → files
- **Organized by author**: Logical categorization
- **Mixed file types**: Markdown books, images, metadata

### 2. Complete Metadata ✓
**collection.js** includes:
- Full collection information (title, description, dates)
- Detailed statistics (downloads, ratings, views)
- Complete tags (11 tags for discoverability)
- Rich metadata (license, contact, donation address)

### 3. Two Hash Algorithms ✓
**extra/tree-data.js** includes:
- **SHA-1** hashes for all files (required)
- **TLSH** hashes for fuzzy matching (required)
- Per-file metadata (title, description, custom fields)

### 4. Change History ✓
**log.txt** demonstrates:
- Initial collection creation
- File additions (ADDED action)
- Community submissions (SUBMISSION → APPROVED)
- Contributors being added (CONTRIBUTOR_ADDED)
- Permission changes (PERMISSION_CHANGED)
- Metadata updates (UPDATED)

### 5. RSS Feed ✓
**feed.rss** shows:
- Collection creation announcement
- Version updates (v1.0.0 → v1.1.0 → v1.2.0)
- Community submission announcements
- Download links (enclosures)
- Rich HTML descriptions

### 6. Security Configuration ✓
**extra/security.json** demonstrates:
- Public visibility
- Submission workflow enabled (with approval)
- User interaction permissions (comments, likes, ratings)
- No age restrictions (appropriate for PG content)

### 7. Markdown Books ✓
**books/asimov/foundation.md** shows:
- Proper markdown structure
- Book metadata (author, year, series)
- Synopsis and chapters
- Author information
- Themes and legacy

### 8. Author Documentation ✓
**books/asimov/README.md** includes:
- Biography
- Complete works list
- Books in this collection
- Writing style analysis
- Influence and awards

## Realistic Details

### Realistic File Sizes
- **foundation.md**: 524 KB (typical for a novel)
- **README.md**: 3.4 KB
- **Cover images**: ~90 KB each
- **Total collection**: ~2.5 MB

### Realistic Hashes
All hashes follow proper format:
- **SHA-1**: 40 hex characters
- **TLSH**: 70+ character fuzzy hash
- Unique for each file

### Realistic Timeline
**log.txt** shows realistic progression:
- **2025-11-12**: Initial creation with 5 books
- **2025-11-13**: Community submission + approval (Heinlein's Moon)
- **2025-11-15**: Second community submission (Le Guin)
- **2025-11-16**: Opened to community submissions

### Realistic Statistics
**collection.js** shows believable numbers:
- **1,543 downloads** over 4 days
- **4.8/5.0 rating** from 89 users
- **3,891 total views**, 756 unique
- **127 likes**, 3 dislikes, 45 comments

## How This Collection Would Work

### 1. Initial Creation (Nov 12)
```bash
# Curator creates collection
1. Creates folder structure
2. Adds Asimov, Heinlein, Herbert books
3. Generates collection.js
4. Generates extra/tree-data.js with hashes
5. Creates extra/security.json (public, read-only)
6. Publishes on NOSTR
```

### 2. First Community Submission (Nov 13)
```bash
# Community member submits Heinlein's Moon book
1. User formats book in markdown
2. Calculates SHA-1 and TLSH hashes
3. Sends submission via NOSTR to curator
4. Curator reviews and approves
5. Files added to collection
6. Contributor npub added to allowed list
7. log.txt updated
8. feed.rss updated
9. New version published
```

### 3. Opening to Public (Nov 16)
```bash
# Curator opens collection to submissions
1. Updates extra/security.json (allow_submissions: true)
2. Adds log entry
3. Posts announcement in feed.rss
4. Collection now accepts community contributions
```

## Usage Examples

### Browsing the Collection
```bash
# Extract collection
unzip classic-scifi-books-v1.2.0.colz -d classic-scifi/

# Read a book
cd classic-scifi/
less books/asimov/foundation.md
# or
markdown books/asimov/foundation.md | less
```

### Verifying Integrity
```bash
# Check SHA-1 hash
sha1sum books/asimov/foundation.md
# Compare with hash in extra/tree-data.js:
# 2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b

# Generate TLSH hash
tlsh -f books/asimov/foundation.md
# Compare with TLSH in extra/tree-data.js
```

### Subscribing to Updates
```bash
# Add to RSS reader
# URL: https://scifi-classics.example.com/classic-scifi-books/feed.rss

# Or if using local feed:
cp feed.rss ~/.newsboat/feeds/
```

### Submitting a Book
```markdown
Subject: Submission - Arthur C. Clarke's "2001: A Space Odyssey"

Collection: npub1qvr3x8zjxyz9qwertyu8xcvbnmasdfghjklzxcvbnmasdfghjklqwerty

Files:
1. books/clarke/2001.md
   - Size: 456789 bytes
   - SHA-1: abcdef123456789abcdef123456789abcdef1234
   - TLSH: T1ABCDEF123456789ABCDEF123456789ABCDEF123456789ABCDEF1234567

2. books/clarke/2001-cover.jpg
   - Size: 87654 bytes
   - SHA-1: 123456789abcdef123456789abcdef123456789a
   - TLSH: T1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF123456789

Description: Adding Arthur C. Clarke's masterpiece 2001: A Space Odyssey
to complete the collection's golden age representation.

Submitter: npub1submitter...
```

## What Makes This Example Realistic

### 1. Community Collaboration
- Shows how collections can accept contributions
- Demonstrates approval workflow
- Multiple contributors with different npubs
- Realistic submission timeline

### 2. Growth Over Time
- Version progression: 1.0.0 → 1.1.0 → 1.2.0
- Increasing file count and size
- Growing statistics (downloads, views, ratings)
- Evolving permissions (closed → open)

### 3. Complete Documentation
- Every file type represented
- Every required field filled
- Every hash algorithm included
- Every action type logged

### 4. Real-World Workflow
- Initial curated content
- Community discovers collection
- Community contributes
- Curator approves quality submissions
- Collection grows organically

### 5. Proper Formats
- Markdown books (portable, searchable)
- JPEG covers (universal compatibility)
- JSON metadata (standard format)
- RSS feed (standard protocol)

## Learning From This Example

### For Users
- See how collections are organized
- Understand the submission process
- Learn how to subscribe to updates
- See what good documentation looks like

### For Developers
- Reference implementation of all formats
- Example of proper hash generation
- Template for creating collections
- Understanding of file relationships

### For Curators
- Best practices for organization
- How to structure metadata
- Managing community contributions
- Maintaining quality standards

## Extending This Example

You can use this as a template for:

### Similar Collections
- **Modern Sci-Fi** (2000s-2020s authors)
- **Fantasy Classics** (Tolkien, Jordan, Pratchett)
- **Cyberpunk** (Gibson, Stephenson, Sterling)
- **Short Story Collections** (Best of Year anthologies)

### Different Content Types
- **Technical Documentation** (programming books)
- **Academic Papers** (research collections)
- **Historical Archives** (public domain texts)
- **Software Packages** (tools and utilities)

### Adaptations
- Different folder structures (by year, genre, topic)
- Different submission policies (closed, moderated, open)
- Different metadata emphasis (educational, archival, commercial)
- Different file formats (EPUB, PDF, etc.)

## Files You Can Copy

Feel free to use as templates:

1. **collection.js** - Structure and field examples
2. **extra/tree-data.js** - Hash format and metadata
3. **extra/security.json** - Permission configurations
4. **log.txt** - Action logging format
5. **feed.rss** - RSS structure and content
6. **books/asimov/README.md** - Author documentation template
7. **books/asimov/foundation.md** - Book markdown template

## Next Steps

To create your own collection:

1. **Copy this structure** as a starting point
2. **Replace content** with your files
3. **Update metadata** (title, description, tags)
4. **Generate hashes** for all files
5. **Create log.txt** starting with CREATED entry
6. **Set permissions** in extra/security.json
7. **Publish** via .colz archive or folder

## Questions?

See the main documentation:
- [User Guide](../../user-guide.md) - How to use collections
- [File Formats](../../file-formats.md) - Format specifications
- [Architecture](../../architecture.md) - System design

---

*This example demonstrates the complete Geogram Collections specification in action.*
