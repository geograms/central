# Collection Changelog and Feed Specifications

This document describes the `log.txt` changelog and `feed.rss` feed files used in collections.

## log.txt - Collection Changelog

### Purpose

The `log.txt` file maintains a chronological record of all changes made to a collection. It provides:
- Transparency and accountability
- Audit trail for all modifications
- Attribution for contributions
- History for troubleshooting

### Location

`log.txt` is stored in the collection root directory.

### Format

Plain text file with one action per line:

```
[ISO8601-TIMESTAMP] ACTION target by npub... (details) [STATUS]
```

### Components

**Timestamp**: ISO 8601 format in UTC
- Format: `YYYY-MM-DDTHH:mm:ssZ`
- Example: `2025-11-16T14:30:00Z`

**Action**: Type of operation (see Action Types below)

**Target**: File path or resource affected

**Actor**: Nostr npub of person who performed the action

**Details**: Additional context (hashes, reasons, etc.)

**Status**: Optional status indicator (`[PENDING]`, `[APPROVED]`, `[REJECTED]`)

### Action Types

#### CREATED
Collection initialization.

```
[2025-11-12T10:00:00Z] CREATED collection by npub1xyz...
```

#### ADDED
File added to collection.

```
[2025-11-12T10:05:00Z] ADDED books/sci-fi/dune.epub by npub1xyz... (sha1: abc123def456..., size: 892KB)
```

#### UPDATED
File or configuration modified.

```
[2025-11-12T10:10:00Z] UPDATED collection.json by npub1xyz... (added tag: science-fiction)
[2025-11-13T09:00:00Z] UPDATED books/readme.md by npub1abc... (sha1: new_hash...)
```

#### REMOVED
File deleted from collection.

```
[2025-11-14T14:00:00Z] REMOVED books/old/deprecated.txt by npub1xyz... (reason: outdated content)
```

#### SUBMISSION
New file submitted by non-owner (pending approval).

```
[2025-11-13T09:00:00Z] SUBMISSION books/foundation.epub by npub2abc... (sha1: def456...) [PENDING]
```

#### APPROVED
Submission accepted by administrator.

```
[2025-11-13T09:30:00Z] APPROVED books/foundation.epub by npub1xyz... (submission by npub2abc...)
```

#### REJECTED
Submission denied by administrator.

```
[2025-11-16T10:00:00Z] REJECTED books/spam/ad.txt by npub1xyz... (submission by npub4bad..., reason: spam content)
```

#### CONTRIBUTOR_ADDED
New contributor granted access.

```
[2025-11-15T11:00:00Z] CONTRIBUTOR_ADDED npub3new... by npub1xyz... (role: contributor)
```

#### CONTRIBUTOR_REMOVED
Contributor access revoked.

```
[2025-11-20T08:00:00Z] CONTRIBUTOR_REMOVED npub3old... by npub1xyz... (reason: inactive)
```

#### PERMISSION_CHANGED
Permission settings modified.

```
[2025-11-18T13:00:00Z] PERMISSION_CHANGED allow_submissions=true by npub1xyz...
```

#### OWNER_ADDED
New owner added to collection.

```
[2025-11-25T10:00:00Z] OWNER_ADDED npub5new... by npub1xyz... (role: admin)
```

#### FORKED
Collection forked to create derivative.

```
[2025-12-01T09:00:00Z] FORKED to npub7fork... by npub6user... (reason: personal modifications)
```

### Complete Example

```
[2025-11-12T10:00:00Z] CREATED collection by npub1qvr3x8zjxyz9qwer...
[2025-11-12T10:05:00Z] ADDED books/asimov/foundation.epub by npub1qvr3x8zjxyz9qwer... (sha1: a1b2c3d4e5f6..., size: 892KB)
[2025-11-12T10:07:00Z] ADDED books/asimov/foundation-cover.jpg by npub1qvr3x8zjxyz9qwer... (sha1: f6e5d4c3b2a1..., size: 156KB)
[2025-11-12T10:10:00Z] UPDATED collection.json by npub1qvr3x8zjxyz9qwer... (added tags: sci-fi, classic, asimov)
[2025-11-12T10:15:00Z] ADDED books/heinlein/stranger.epub by npub1qvr3x8zjxyz9qwer... (sha1: 9876fedcba..., size: 1.2MB)
[2025-11-13T09:00:00Z] SUBMISSION books/herbert/dune.epub by npub2abc123... (sha1: def456789abc..., size: 1.5MB) [PENDING]
[2025-11-13T09:15:00Z] SUBMISSION books/clarke/2001.epub by npub3def456... (sha1: 123abc456def..., size: 756KB) [PENDING]
[2025-11-13T09:30:00Z] APPROVED books/herbert/dune.epub by npub1qvr3x8zjxyz9qwer... (submission by npub2abc123...)
[2025-11-13T09:30:00Z] ADDED books/herbert/dune.epub by npub2abc123... (sha1: def456789abc..., size: 1.5MB)
[2025-11-13T09:32:00Z] REJECTED books/clarke/2001.epub by npub1qvr3x8zjxyz9qwer... (submission by npub3def456..., reason: already have this book)
[2025-11-14T14:00:00Z] REMOVED books/old/test.txt by npub1qvr3x8zjxyz9qwer... (reason: test file)
[2025-11-15T11:00:00Z] CONTRIBUTOR_ADDED npub4contributor... by npub1qvr3x8zjxyz9qwer... (role: contributor)
[2025-11-16T08:00:00Z] PERMISSION_CHANGED allow_submissions=true by npub1qvr3x8zjxyz9qwer...
[2025-11-18T10:30:00Z] UPDATED collection.json by npub1qvr3x8zjxyz9qwer... (version bumped to 1.1.0)
```

### Best Practices

**Do:**
- ✓ Append new entries (don't modify existing)
- ✓ Use UTC timezone
- ✓ Include relevant details (hashes, sizes, reasons)
- ✓ Be concise but descriptive
- ✓ Maintain chronological order

**Don't:**
- ✗ Delete or modify past entries
- ✗ Include sensitive information
- ✗ Use local timezones
- ✗ Omit required fields

### Parsing log.txt

**Python example**:
```python
import re
from datetime import datetime

def parse_log_entry(line):
    pattern = r'\[([^\]]+)\] (\w+) (.+?) by (npub\w+)(.*?)(?:\[(PENDING|APPROVED|REJECTED)\])?$'
    match = re.match(pattern, line)
    if match:
        return {
            'timestamp': datetime.fromisoformat(match.group(1).replace('Z', '+00:00')),
            'action': match.group(2),
            'target': match.group(3),
            'actor': match.group(4),
            'details': match.group(5).strip(),
            'status': match.group(6)
        }
    return None

with open('log.txt', 'r') as f:
    for line in f:
        entry = parse_log_entry(line)
        if entry:
            print(entry)
```

---

## feed.rss - Collection Update Feed

### Purpose

The `feed.rss` file provides an RSS/Atom feed for collection updates, enabling:
- Standard notification mechanism
- Universal RSS reader compatibility
- Update tracking without NOSTR
- Familiar subscription experience

### Location

`feed.rss` is stored in the collection root directory.

### Format

Supports both RSS 2.0 and Atom 1.0 formats.

### RSS 2.0 Example

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>Classic Sci-Fi Books Collection</title>
    <link>https://collections.example.com/classic-scifi-books</link>
    <description>A curated collection of classic science fiction literature</description>
    <language>en-us</language>
    <pubDate>Wed, 12 Nov 2025 10:00:00 GMT</pubDate>
    <lastBuildDate>Wed, 15 Nov 2025 14:30:00 GMT</lastBuildDate>
    <generator>Geogram Collection Manager v1.0</generator>

    <!-- Self-reference for feed discovery -->
    <atom:link href="https://collections.example.com/classic-scifi-books/feed.rss"
               rel="self" type="application/rss+xml" />

    <!-- Collection metadata -->
    <category>books</category>
    <category>sci-fi</category>
    <category>literature</category>

    <image>
      <url>https://collections.example.com/classic-scifi-books/thumbnail.png</url>
      <title>Classic Sci-Fi Books Collection</title>
      <link>https://collections.example.com/classic-scifi-books</link>
    </image>

    <!-- Update item -->
    <item>
      <title>Collection Updated to v1.2.0 - Added 5 New Books</title>
      <link>https://collections.example.com/classic-scifi-books</link>
      <description><![CDATA[
        Added 5 new classic sci-fi books to the collection:
        - Foundation and Empire by Isaac Asimov
        - The Left Hand of Darkness by Ursula K. Le Guin
        - Neuromancer by William Gibson
        - Do Androids Dream of Electric Sheep? by Philip K. Dick
        - The Stars My Destination by Alfred Bester

        Total collection size: 150 books
      ]]></description>
      <author>npub1qvr3x... (Collection Curator)</author>
      <pubDate>Wed, 15 Nov 2025 14:30:00 GMT</pubDate>
      <guid isPermaLink="false">classic-scifi-books:update:2025-11-15</guid>
      <enclosure url="https://collections.example.com/classic-scifi-books-v1.2.0.colz"
                 length="157286400"
                 type="application/zip" />
    </item>

    <!-- Content addition item -->
    <item>
      <title>New Book Added: The Moon is a Harsh Mistress</title>
      <link>https://collections.example.com/classic-scifi-books</link>
      <description><![CDATA[
        Added "The Moon is a Harsh Mistress" by Robert A. Heinlein.

        File: books/heinlein/moon-harsh-mistress.epub
        Size: 892 KB
        SHA-1: a3f8b9c1d2e3f4g5h6i7j8k9l0m1n2o3p4q5r6s7
      ]]></description>
      <author>npub1qvr3x... (Collection Curator)</author>
      <pubDate>Tue, 14 Nov 2025 09:15:00 GMT</pubDate>
      <guid isPermaLink="false">classic-scifi-books:addition:2025-11-14:moon</guid>
      <category>heinlein</category>
      <category>new-addition</category>
    </item>

    <!-- Creation announcement -->
    <item>
      <title>Collection Created: Classic Sci-Fi Books</title>
      <link>https://collections.example.com/classic-scifi-books</link>
      <description><![CDATA[
        Welcome to the Classic Sci-Fi Books collection! This curated collection features
        timeless science fiction literature from the golden age of sci-fi.

        Starting with 120 books from legendary authors like Asimov, Heinlein, Herbert, and more.

        Subscribe to this feed to receive notifications when new books are added!
      ]]></description>
      <author>npub1qvr3x... (Collection Curator)</author>
      <pubDate>Wed, 12 Nov 2025 10:00:00 GMT</pubDate>
      <guid isPermaLink="false">classic-scifi-books:created:2025-11-12</guid>
      <enclosure url="https://collections.example.com/classic-scifi-books-v1.0.0.colz"
                 length="145829120"
                 type="application/zip" />
    </item>
  </channel>
</rss>
```

### Atom 1.0 Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Classic Sci-Fi Books Collection</title>
  <link href="https://collections.example.com/classic-scifi-books"/>
  <link rel="self" href="https://collections.example.com/classic-scifi-books/feed.rss"/>
  <updated>2025-11-15T14:30:00Z</updated>
  <id>urn:uuid:classic-scifi-books</id>
  <subtitle>A curated collection of classic science fiction literature</subtitle>

  <author>
    <name>Collection Curator</name>
    <uri>nostr:npub1qvr3x8zjxyz9qwer...</uri>
  </author>

  <category term="books"/>
  <category term="sci-fi"/>
  <category term="literature"/>

  <entry>
    <title>Collection Updated to v1.2.0 - Added 5 New Books</title>
    <link href="https://collections.example.com/classic-scifi-books"/>
    <id>urn:uuid:classic-scifi-books:update:2025-11-15</id>
    <updated>2025-11-15T14:30:00Z</updated>
    <summary>Added 5 new classic sci-fi books: Foundation and Empire, The Left Hand of Darkness, and more.</summary>
    <content type="html"><![CDATA[
      <p>Added 5 new classic sci-fi books to the collection:</p>
      <ul>
        <li>Foundation and Empire by Isaac Asimov</li>
        <li>The Left Hand of Darkness by Ursula K. Le Guin</li>
        <li>Neuromancer by William Gibson</li>
        <li>Do Androids Dream of Electric Sheep? by Philip K. Dick</li>
        <li>The Stars My Destination by Alfred Bester</li>
      </ul>
      <p>Total collection size: 150 books</p>
    ]]></content>
  </entry>
</feed>
```

### Feed Content Guidelines

#### Channel/Feed Information

- **title**: Collection title (matches collection.json)
- **description/subtitle**: Collection description
- **link**: URL to collection or download page
- **category**: Tags from collection (for discoverability)
- **image**: Thumbnail/logo for visual identification

#### Item Types to Include

1. **Collection Updates**: New version releases
2. **Content Additions**: Individual files/items added
3. **Announcements**: News about the collection
4. **Changes**: Significant modifications or restructuring

#### Item Fields

- **title**: Clear, descriptive title of the update
- **description/content**: Detailed information about the change
- **pubDate/updated**: When the change occurred
- **author**: npub of the person who made the change
- **guid/id**: Unique identifier for this feed item
- **enclosure**: Link to download the collection ZIP (recommended)

#### Enclosure for Downloads

```xml
<enclosure url="https://example.com/collection-v1.2.0.colz"
           length="157286400"
           type="application/zip" />
```

- Include direct download link
- Specify file size in bytes
- Use `application/zip` MIME type

### NOSTR Integration

- Author field can reference npubs: `nostr:npub1...`
- Feed items can correspond to NOSTR events
- Clients can cross-reference feed updates with NOSTR announcements

### Updating the Feed

1. Add new `<item>` entries at the top when changes occur
2. Keep recent items (recommend 20-50 most recent)
3. Update `lastBuildDate`/`updated` timestamp
4. Maintain chronological order (newest first)

### Feed Discovery

- Include feed URL in `collection.json` metadata
- Use standard file name: `feed.rss` or `feed.xml`
- Support both RSS 2.0 and Atom 1.0 formats

### Benefits

- ✓ Universal compatibility with RSS readers
- ✓ Standard notification mechanism
- ✓ Works offline (feed included in collection)
- ✓ No dependency on NOSTR relays
- ✓ Familiar user experience for content subscriptions

## Integration with log.txt

The feed.rss can be automatically generated from log.txt:

**Conversion script** (conceptual):
```python
def generate_feed_from_log(log_file, collection_json):
    # Parse log entries
    entries = parse_log(log_file)

    # Convert to feed items (most recent first)
    feed_items = []
    for entry in reversed(entries[-50:]):  # Last 50 entries
        if entry['action'] in ['ADDED', 'UPDATED', 'CREATED']:
            feed_items.append(create_feed_item(entry, collection_json))

    # Generate RSS/Atom
    return generate_rss(feed_items, collection_json)
```

## Related Documentation

- [File Formats](file-formats.md) - Metadata file specifications
- [Metadata Specification](metadata-specification.md) - Metadata standards
- [User Guide](user-guide.md) - User instructions
