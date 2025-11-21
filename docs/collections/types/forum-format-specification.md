# Forum Format Specification

**Version**: 1.0
**Last Updated**: 2025-11-21
**Status**: Active

## Table of Contents

- [Overview](#overview)
- [File Organization](#file-organization)
- [Thread File Format](#thread-file-format)
- [Post Format](#post-format)
- [Metadata Field Types](#metadata-field-types)
- [NOSTR Integration](#nostr-integration)
- [Complete Thread Examples](#complete-thread-examples)
- [Full File Example](#full-file-example)
- [Parsing Implementation](#parsing-implementation)
- [File Operations](#file-operations)
- [Validation Rules](#validation-rules)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)
- [Related Documentation](#related-documentation)
- [Change Log](#change-log)

## Overview

This document specifies the text-based markdown format used for storing forum discussions in the Geogram system. Forum files use a human-readable plain text format with structured metadata support.

Forum posts can optionally be cryptographically signed using NOSTR-compatible signatures (Schnorr signatures on secp256k1 curve) to provide authenticity verification and message integrity.

## File Organization

### Directory Structure

```
forum/                          # Forum collection root
├── collection.js               # Collection metadata
├── extra/
│   ├── sections.json           # Section list and metadata
│   ├── security.json           # Admin/moderators by section
│   └── settings.json           # Forum settings
├── general/                    # Section folder
│   ├── config.json             # Section configuration
│   ├── thread-welcome.txt      # Thread file
│   ├── thread-rules.txt
│   └── files/                  # Attached files for this section
├── announcements/              # Another section
│   ├── config.json
│   ├── thread-updates.txt
│   └── files/
└── help/
    ├── config.json
    ├── thread-getting-started.txt
    └── files/
```

### File Naming Convention

#### Thread Files

- **Pattern**: `thread-{sanitized-title}.txt`
- **Alternative**: `{number}-{title}.txt` for ordered threads
- **Examples**:
  - `thread-welcome.txt`
  - `thread-how-to-use-collections.txt`
  - `001-introduction.txt`
- **Location**: Inside section folders

#### Section Folders

- **Pattern**: Lowercase, alphanumeric with hyphens
- **Examples**:
  - `general/`
  - `announcements/`
  - `help/`
  - `feature-requests/`

### Section Configuration File

Each section folder contains a `config.json`:

```json
{
  "id": "general",
  "name": "General Discussion",
  "description": "General topics and community discussion",
  "visibility": "PUBLIC",
  "readonly": false,
  "file_upload": true,
  "files_per_post": 3,
  "max_file_size": 10,
  "max_size_text": 5000,
  "moderators": [],
  "allow_new_threads": true,
  "threads_require_approval": false
}
```

### Sections Metadata File

The `extra/sections.json` file lists all sections:

```json
{
  "version": "1.0",
  "sections": [
    {
      "id": "announcements",
      "name": "Announcements",
      "folder": "announcements",
      "order": 1,
      "readonly": false
    },
    {
      "id": "general",
      "name": "General Discussion",
      "folder": "general",
      "order": 2,
      "readonly": false
    },
    {
      "id": "help",
      "name": "Help & Support",
      "folder": "help",
      "order": 3,
      "readonly": false
    }
  ]
}
```

## Thread File Format

### Basic Structure

A thread file contains:
1. Thread header (title, author, timestamp)
2. Original post content
3. Original post metadata
4. Reply posts (chronological order)

```
# THREAD: Thread Title

AUTHOR: OP_CALLSIGN
CREATED: YYYY-MM-DD HH:MM_ss
SECTION: section-id

Original post content goes here.
This is the first post that starts the discussion thread.
Can span multiple lines.

--> metadata_key: metadata_value
--> npub: npub1...
--> signature: hex_signature

> YYYY-MM-DD HH:MM_ss -- REPLIER_CALLSIGN
This is a reply to the thread.
Replies appear after the original post.
--> metadata_key: value

> YYYY-MM-DD HH:MM_ss -- ANOTHER_CALLSIGN
Another reply in chronological order.
```

### Thread Header Section

**Format**:
```
# THREAD: Thread Title

AUTHOR: CALLSIGN
CREATED: YYYY-MM-DD HH:MM_ss
SECTION: section-id
```

- **Thread Title**: Descriptive title (max 200 characters)
- **AUTHOR**: Original poster's callsign
- **CREATED**: Thread creation timestamp
- **SECTION**: Section identifier where thread belongs
- **Required**: Yes (first four lines of file)
- **Occurrence**: Once per file

**Example**:
```
# THREAD: How to create your first collection

AUTHOR: CR7BBQ
CREATED: 2025-11-21 14:30_45
SECTION: help
```

## Post Format

### Original Post (Thread Starter)

The original post appears immediately after the thread header:

```
# THREAD: Thread Title

AUTHOR: CR7BBQ
CREATED: 2025-11-21 14:30_45
SECTION: help

This is the original post content.
It can span multiple paragraphs.

And include blank lines.
--> file: screenshot.png
--> npub: npub1...
--> signature: abc123...
```

### Reply Posts

Reply posts follow the original post, using the same format as chat messages:

**Format**: `> YYYY-MM-DD HH:MM_ss -- CALLSIGN`

```
> 2025-11-21 15:15_23 -- ALPHA1
Thanks for posting this! Here's my answer...

This can also span multiple lines.
--> quote: 2025-11-21 14:30_45
--> file: diagram.png
```

- **Timestamp**: When reply was posted
- **CALLSIGN**: Reply author's callsign
- **Content**: Reply message body
- **Metadata**: Optional metadata fields

### Post Separator

Posts are separated by:
1. Blank line after metadata
2. Start of next post marker (`>`)

## Metadata Field Types

### Standard Metadata Fields

All metadata lines use the format: `--> key: value`

#### File Attachment

```
--> file: filename.ext
```

- **Purpose**: Reference to attached file
- **Location**: Files stored in section's `files/` folder
- **Max filename**: 100 characters
- **Multiple files**: Multiple `--> file:` lines allowed (up to `files_per_post` limit)

**Example**:
```
--> file: screenshot-2025-11-21.png
--> file: document.pdf
```

#### Location Metadata

```
--> lat: -38.123456
--> lon: -9.654321
```

- **Purpose**: GPS coordinates of poster
- **Format**: Decimal degrees
- **Precision**: 6 decimal places recommended

#### Quote Reference

```
--> quote: YYYY-MM-DD HH:MM_ss
```

- **Purpose**: Reference to another post in the thread by timestamp
- **Format**: Same timestamp format as post header
- **Validation**: Should exist in current thread file

**Example**:
```
--> quote: 2025-11-21 14:30_45
```

#### Reactions

```
--> icon_like: CR7BBQ, ALPHA1, BRAVO2
```

- **Purpose**: List of callsigns who reacted
- **Format**: Comma-separated callsigns
- **Types**: `icon_like`, `icon_thanks`, `icon_agree`, etc.

#### Poll

```
--> Poll: What feature should we add next?
--> votes: Option 1=CR7BBQ,ALPHA1; Option 2=BRAVO2; Option 3=CHARLIE3,DELTA4
--> deadline: 2025-11-30 23:59_59
```

- **Purpose**: Create poll in post
- **votes**: Semicolon-separated options with comma-separated voter callsigns
- **deadline**: Optional voting deadline

#### NOSTR Public Key

```
--> npub: npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpfj3q5
```

- **Purpose**: NOSTR public key of post author
- **Format**: Bech32-encoded npub (63 characters)
- **Placement**: **Must appear immediately before signature if present**

#### Cryptographic Signature

```
--> signature: 3044022047fd8f...a1b2c3
```

- **Purpose**: Cryptographic signature of post content
- **Format**: Hex-encoded Schnorr signature
- **Requirement**: **Must be the last metadata field**
- **Dependencies**: Requires `npub` field to verify

### Metadata Ordering Rules

1. **General metadata** can appear in any order
2. **npub field** must appear immediately before signature (if signing)
3. **signature field** must always be the last metadata field
4. **No metadata after signature**

**Correct Example**:
```
--> file: image.png
--> lat: -38.123456
--> lon: -9.654321
--> npub: npub1...
--> signature: abc123...
```

**Incorrect Example** (signature not last):
```
--> signature: abc123...
--> file: image.png   # WRONG - nothing after signature
```

## NOSTR Integration

### Signature Generation

When signing a forum post, the signature is created by:

1. **Construct the message text** to be signed:
   - Include everything from the post start marker through the last line before the signature metadata
   - For original posts: Header + content + all metadata except signature
   - For replies: Post marker + content + all metadata except signature

2. **Hash the message**:
   - Use SHA-256 to create a 32-byte hash
   - Input: UTF-8 encoded message text

3. **Sign the hash**:
   - Use Schnorr signature on secp256k1 curve
   - Sign with user's nsec (private key)
   - Output: 64-byte signature

4. **Encode signature**:
   - Convert to hexadecimal string
   - Add as last metadata field

### Signature Verification

To verify a signed post:

1. Extract npub and signature from metadata
2. Reconstruct message text (everything except signature line)
3. Hash with SHA-256
4. Verify signature using npub against hash
5. Signature valid = post authentic and unmodified

### Security Properties

- **Authentication**: Proves post authorship (not spoofed)
- **Integrity**: Detects any modification to post content or metadata
- **Non-repudiation**: Author cannot deny posting (signature proves it)
- **Optional**: Signing is optional, unsigned posts allowed

## Complete Thread Examples

### Simple Thread with Replies

```
# THREAD: Welcome to the forum!

AUTHOR: CR7BBQ
CREATED: 2025-11-21 10:00_00
SECTION: general

Welcome everyone to our new forum!
Feel free to introduce yourself here.

> 2025-11-21 10:15_30 -- ALPHA1
Thanks CR7BBQ! Happy to be here.
Looking forward to collaborating.

> 2025-11-21 10:45_12 -- BRAVO2
Hello everyone! Great to see this forum launch.
--> icon_like: CR7BBQ, ALPHA1

> 2025-11-21 11:20_00 -- CR7BBQ
Thanks for joining! Let's build something great together.
--> quote: 2025-11-21 10:45_12
```

### Thread with File Attachments

```
# THREAD: Collection creation tutorial

AUTHOR: CR7BBQ
CREATED: 2025-11-21 14:00_00
SECTION: help

Here's a step-by-step guide on creating your first collection.
Check the attached screenshots for visual guidance.
--> file: step1-create-button.png
--> file: step2-settings.png
--> file: step3-complete.png

> 2025-11-21 14:30_00 -- CHARLIE3
Very helpful tutorial! One question though...
How do I change the collection type?
--> quote: 2025-11-21 14:00_00

> 2025-11-21 14:45_00 -- CR7BBQ
Good question! You select it during creation.
Let me add another screenshot showing this.
--> file: collection-type-selection.png
--> quote: 2025-11-21 14:30_00
```

### Signed Thread with Poll

```
# THREAD: Vote: Next feature priority

AUTHOR: CR7BBQ
CREATED: 2025-11-21 16:00_00
SECTION: announcements

What should we prioritize for the next release?
Please vote below!
--> Poll: Choose the next feature to implement
--> votes: Forum system=CR7BBQ,ALPHA1,BRAVO2; Video support=CHARLIE3; Dark mode=DELTA4,ECHO5
--> deadline: 2025-11-30 23:59_59
--> npub: npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpfj3q5
--> signature: 304402204f1a2b3c...abc123def456

> 2025-11-21 16:15_00 -- ALPHA1
I voted for forum system - we really need this!
--> icon_like: CR7BBQ, BRAVO2
--> npub: npub1abc...xyz789
--> signature: 3044022053a2c...789xyz
```

## Full File Example

```
# THREAD: How do I sync collections between devices?

AUTHOR: DELTA4
CREATED: 2025-11-21 09:00_00
SECTION: help

I have collections on my desktop and want to sync them to my mobile device.
What's the best way to do this? Are there any automatic sync options?
--> lat: -38.736946
--> lon: -9.142685

> 2025-11-21 09:30_15 -- CR7BBQ
Great question! Currently you can sync manually via these methods:
1. Export/import collection folders
2. Use file sync services (Syncthing, etc.)
3. Share via relay network (coming soon)

I recommend Syncthing for now - works great for me.
--> quote: 2025-11-21 09:00_00

> 2025-11-21 10:00_45 -- ALPHA1
I second Syncthing recommendation!
Here's a quick setup guide I wrote.
--> file: syncthing-setup-guide.pdf
--> quote: 2025-11-21 09:30_15

> 2025-11-21 10:30_00 -- DELTA4
Thanks both! I'll try Syncthing.
One more question - does it work with the forum collections too?
--> icon_like: CR7BBQ, ALPHA1
--> quote: 2025-11-21 09:30_15

> 2025-11-21 11:00_00 -- CR7BBQ
Yes! All collection types work the same way.
Forum files are just text, so sync works perfectly.
--> quote: 2025-11-21 10:30_00
--> npub: npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpfj3q5
--> signature: 3044022047fd8f4b2c9a1e3d5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4abc123
```

## Parsing Implementation

### Thread File Parsing Algorithm

```
1. Read entire file content
2. Parse thread header (first 4 lines):
   - Line 1: Extract thread title from "# THREAD: {title}"
   - Line 2: Extract original author from "AUTHOR: {callsign}"
   - Line 3: Extract creation timestamp from "CREATED: {timestamp}"
   - Line 4: Extract section from "SECTION: {section-id}"
3. Parse original post:
   - Content from line 5 until first metadata line or post marker
   - Extract metadata lines starting with "-->"
4. Parse reply posts:
   - Split remaining content by "> 2" pattern (post markers start with year 2xxx)
   - For each section:
     a. Extract timestamp and author from header line
     b. Extract content (lines until metadata starts)
     c. Extract metadata (lines starting with "-->")
5. Return thread object with original post + replies array
```

### Post Parsing Pattern

```regex
Post Start: ^> (\d{4}-\d{2}-\d{2} \d{2}:\d{2}_\d{2}) -- (.+)$
Metadata Line: ^--> ([^:]+): (.+)$
Thread Header: ^# THREAD: (.+)$
```

### Metadata Extraction

```
For each metadata line:
1. Match pattern: "--> {key}: {value}"
2. Trim whitespace from key and value
3. Store in metadata dictionary
4. Special handling for:
   - "file": Store filename
   - "lat"/"lon": Parse as float
   - "votes": Parse poll votes structure
   - "signature": Mark as signed post
```

## File Operations

### Creating New Thread

1. Sanitize thread title to create filename
2. Generate thread header with metadata
3. Write original post content
4. Add metadata (including signature if enabled)
5. Save to section folder
6. Update section thread index

### Adding Reply to Thread

1. Read existing thread file
2. Parse to ensure valid structure
3. Append blank line separator
4. Add reply post marker with timestamp
5. Write reply content
6. Add reply metadata
7. Save updated file
8. Update thread last-reply timestamp

### Editing Post (Future)

Editing not supported in v1.0. Posts are immutable once created.
Future versions may support:
- Edit history tracking
- Edit metadata field
- Version control

### Deleting Post

Admin/moderator deletion:
1. Read thread file
2. Parse all posts
3. Remove target post from array
4. Reconstruct file without deleted post
5. Save updated file
6. Original post deletion = delete entire thread

## Validation Rules

### Thread File Validation

- Header must be exactly 4 lines
- Thread title: 1-200 characters
- Author callsign: 3-20 alphanumeric characters
- Created timestamp: Valid YYYY-MM-DD HH:MM_ss format
- Section ID: Must exist in sections.json
- At least one post (original post) required

### Post Validation

- Timestamp: Valid format, not in future
- Author: Non-empty callsign
- Content: Not empty (unless has attachments)
- Metadata keys: Alphanumeric with underscores
- Signature: Must be last metadata if present
- File references: Filenames max 100 chars

### Metadata Validation

- `file`: Filename must exist in section files/ folder
- `lat`/`lon`: Valid decimal degrees (-90 to 90, -180 to 180)
- `quote`: Referenced timestamp must exist in thread
- `npub`: Valid bech32 format (if present)
- `signature`: Valid hex string (if present)

## Best Practices

### Thread Creation

- Use descriptive, searchable titles
- Include relevant context in original post
- Add section tags/metadata for categorization
- Attach relevant files at thread start
- Sign important announcements

### Reply Posts

- Quote specific posts when replying to older messages
- Keep replies focused and on-topic
- Use reactions instead of "+1" posts
- Add files to support your points
- Sign posts with important information

### File Management

- Use descriptive filenames
- Keep attachments under size limit
- Don't upload duplicate files
- Clean up old/unused attachments
- Use standard file formats (PNG, PDF, etc.)

### Thread Organization

- One topic per thread
- Post in appropriate section
- Use search before creating duplicate threads
- Keep related discussions in same thread
- Archive old/resolved threads

## Security Considerations

### Threat Model

**Threats Addressed:**
- Post forgery/impersonation (via signatures)
- Content modification (via signatures)
- Unauthorized moderation actions (via security.json)

**Threats Not Addressed:**
- Denial of service (rate limiting needed)
- Spam flooding (moderation tools needed)
- Privacy/anonymity (metadata reveals identity)

### Access Control

**Read Access:**
- Public sections: Anyone can read
- Private sections: Members only (future)
- Encrypted sections: Key holders only (future)

**Write Access:**
- All users: Can create threads and reply
- Moderators: Can delete posts in their sections
- Admin: Can delete any post, manage moderators

**Moderation:**
- Defined in extra/security.json
- Per-section moderator lists
- Admin has full permissions

### File Upload Security

- Validate file extensions
- Scan for malware (recommended)
- Enforce size limits
- Store in isolated directory
- Serve with proper MIME types

## Related Documentation

- [Chat Format Specification](./chat-format-specification.md) - Similar message format for real-time chat
- [Collection API](./COLLECTIONS_API_SUMMARY.md) - Collection management and structure
- [NOSTR Protocol](https://github.com/nostr-protocol/nips) - Signature scheme basis

## Change Log

### Version 1.0 (2025-11-21)

**Initial specification including:**
- Thread file format with original post + replies
- Section-based organization
- NOSTR signature support
- Metadata field definitions
- Validation rules
- Security model

**Design decisions:**
- Threads stored as individual files (not daily aggregation)
- Sections as folders (not metadata)
- All replies in single file per thread (not separate files)
- Immutable posts (no editing in v1.0)
- Compatible with chat message format where possible

---

**End of Forum Format Specification v1.0**
