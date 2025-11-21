# News Format Specification

**Version**: 1.0
**Last Updated**: 2025-01-21
**Status**: Active

## Table of Contents

1. [Overview](#overview)
2. [File Organization](#file-organization)
3. [News Item Format](#news-item-format)
4. [Metadata Field Types](#metadata-field-types)
5. [Location Support](#location-support)
6. [Classification System](#classification-system)
7. [Expiry and Temporal Features](#expiry-and-temporal-features)
8. [Reactions and Engagement](#reactions-and-engagement)
9. [Comments](#comments)
10. [File Attachments](#file-attachments)
11. [NOSTR Integration](#nostr-integration)
12. [Complete Examples](#complete-examples)
13. [Parsing Implementation](#parsing-implementation)
14. [File Operations](#file-operations)
15. [Validation Rules](#validation-rules)
16. [Best Practices](#best-practices)
17. [Security Considerations](#security-considerations)
18. [Related Documentation](#related-documentation)
19. [Change Log](#change-log)

---

## Overview

The News collection type provides a standardized format for publishing short, location-aware news items and alerts. Designed for rapid information dissemination, news items are:

- **Brief**: Limited to 500 characters for quick consumption
- **Authenticated**: Cryptographically signed with NOSTR keys for verified authorship
- **Location-Aware**: Optional geographic coordinates with configurable radius
- **Classified**: Urgency levels (normal, urgent, danger) for prioritization
- **Temporal**: Optional expiry dates for time-sensitive information
- **Engaging**: Support for likes and comments from readers

### Key Features

- Individual markdown files organized by year
- Geographic targeting with coordinates and radius
- Three-tier classification system (normal, urgent, danger)
- Automatic expiry for time-sensitive alerts
- Cryptographic signature verification via NOSTR
- Inline reactions (likes) and threaded comments
- File attachments with SHA1-based naming
- Chronological organization for news timeline

### Use Cases

- Breaking news alerts
- Local community announcements
- Emergency notifications with geographic scope
- Weather warnings and public safety alerts
- Event announcements with location context
- Neighborhood updates and notices
- Time-sensitive information with expiry

---

## File Organization

News items are organized chronologically by year in individual markdown files.

### Directory Structure

```
news/
├── 2024/
│   ├── 2024-01-15_power-outage-alert.md
│   ├── 2024-03-22_community-meeting.md
│   ├── 2024-07-04_festival-announcement.md
│   └── files/
│       ├── a3f8d9e2b1c4...7f6e_outage-map.png
│       └── b8e3c1a9d7f2...4a1b_meeting-flyer.jpg
├── 2025/
│   ├── 2025-01-01_new-year-message.md
│   ├── 2025-01-10_weather-warning.md
│   ├── 2025-01-15_road-closure.md
│   └── files/
│       └── c9d4e8b2a3f1...5e7c_closure-map.png
└── README.md
```

### Naming Conventions

#### News Item Files

**Pattern**: `YYYY-MM-DD_sanitized-title.md`

**Rules**:
- Date prefix uses ISO 8601 format (YYYY-MM-DD)
- Underscore separates date from title
- Title is lowercase with hyphens replacing spaces
- Only alphanumeric characters and hyphens in title
- Maximum 50 characters for title portion
- `.md` extension for Markdown format

**Examples**:
- `2025-01-15_breaking-news-alert.md`
- `2025-03-20_community-update.md`
- `2025-06-01_weather-warning.md`

#### Year Subdirectories

- Format: `YYYY/` (four-digit year)
- One directory per year
- Create directories as needed when first item published
- Empty years may be omitted

#### Files Subdirectory

- Location: `news/YYYY/files/`
- One per year, sibling to news items
- Contains all file attachments for that year's news
- Uses SHA1-based naming (see File Attachments section)

---

## News Item Format

Each news item is a markdown file with structured metadata and content.

### Basic Structure

```markdown
# HEADLINE: Short Descriptive Title

AUTHOR: CALLSIGN
PUBLISHED: YYYY-MM-DD HH:MM:SS
CLASSIFICATION: normal
--> npub: npub1...
--> tags: tag1,tag2,tag3

News content goes here. Maximum 500 characters.

Lead with the most important information first.

--> signature: hex_signature_value
```

### Required Fields

1. **HEADLINE**: The news title (first line, must start with `# HEADLINE:`)
2. **AUTHOR**: Author's callsign
3. **PUBLISHED**: Publication timestamp
4. **CLASSIFICATION**: Urgency level (normal, urgent, danger)
5. **npub**: NOSTR public key for identity verification
6. **Content**: The news text (after blank line, max 500 chars)
7. **signature**: Cryptographic signature (MUST be last metadata line)

### Optional Fields

- **LOCATION**: Geographic coordinates (latitude,longitude)
- **ADDRESS**: Human-readable location description
- **RADIUS**: Applicable radius in kilometers (requires LOCATION)
- **EXPIRY**: Expiration date/time for time-sensitive news
- **tags**: Comma-separated topic tags
- **SOURCE**: Original source attribution
- **file**: Attached media files

### Field Ordering

1. Headline (first line)
2. AUTHOR
3. PUBLISHED
4. CLASSIFICATION
5. LOCATION (if applicable)
6. ADDRESS (if applicable)
7. RADIUS (if applicable)
8. EXPIRY (if applicable)
9. SOURCE (if applicable)
10. Tags metadata line
11. npub metadata line
12. Content (after blank line)
13. File attachments (if any)
14. signature metadata line (MUST be last)
15. Comments (if any, after signature)

---

## Metadata Field Types

### HEADLINE

- **Format**: `# HEADLINE: Title Text Here`
- **Location**: First line of file
- **Required**: Yes
- **Constraints**:
  - Must start with `# HEADLINE: ` (note space after colon)
  - Maximum 100 characters for title portion
  - Should be concise and descriptive
- **Example**: `# HEADLINE: Power Outage Affecting Downtown Area`

### AUTHOR

- **Format**: `AUTHOR: CALLSIGN`
- **Location**: Second line
- **Required**: Yes
- **Constraints**:
  - Callsign must be alphanumeric, 3-20 characters
  - Uppercase recommended for consistency
- **Example**: `AUTHOR: NEWS_DESK`

### PUBLISHED

- **Format**: `PUBLISHED: YYYY-MM-DD HH:MM:SS`
- **Location**: After AUTHOR
- **Required**: Yes
- **Constraints**:
  - ISO 8601 date format
  - 24-hour time format
  - Seconds precision
  - Timezone should be UTC or explicitly stated
- **Example**: `PUBLISHED: 2025-01-15 14:30:00`

### CLASSIFICATION

- **Format**: `CLASSIFICATION: level`
- **Location**: After PUBLISHED
- **Required**: Yes
- **Constraints**:
  - Must be one of: `normal`, `urgent`, `danger`
  - Lowercase only
  - Default: `normal` if not specified
- **Values**:
  - `normal`: Standard news item, no special urgency
  - `urgent`: Time-sensitive, requires attention
  - `danger`: Safety-critical, immediate action may be required
- **Example**: `CLASSIFICATION: urgent`

### LOCATION

- **Format**: `LOCATION: latitude,longitude`
- **Location**: After CLASSIFICATION
- **Required**: No (optional)
- **Constraints**:
  - Decimal degrees format
  - Latitude: -90 to +90
  - Longitude: -180 to +180
  - Precision: up to 6 decimal places
  - Comma-separated, no spaces
- **Example**: `LOCATION: 37.774929,-122.419418`

### ADDRESS

- **Format**: `ADDRESS: Human-readable location`
- **Location**: After LOCATION (if present)
- **Required**: No (optional)
- **Constraints**:
  - Free-form text
  - Maximum 200 characters
  - Should be specific and recognizable
- **Example**: `ADDRESS: Downtown San Francisco, Market Street`

### RADIUS

- **Format**: `RADIUS: number_km`
- **Location**: After ADDRESS/LOCATION
- **Required**: No (requires LOCATION if used)
- **Constraints**:
  - Numeric value in kilometers
  - Minimum: 0.1 km (100 meters)
  - Maximum: 100 km
  - Up to 1 decimal place
  - Cannot be used without LOCATION
- **Example**: `RADIUS: 5.0`
- **Interpretation**: News item is relevant within this radius of LOCATION

### EXPIRY

- **Format**: `EXPIRY: YYYY-MM-DD HH:MM:SS`
- **Location**: After RADIUS/LOCATION fields
- **Required**: No (optional)
- **Constraints**:
  - Same format as PUBLISHED
  - Must be future date (after PUBLISHED)
  - After expiry, item should be considered archived
- **Example**: `EXPIRY: 2025-01-16 18:00:00`
- **Use Case**: Time-sensitive alerts, event announcements

### SOURCE

- **Format**: `SOURCE: Source Name or URL`
- **Location**: After temporal fields
- **Required**: No (optional)
- **Constraints**:
  - Maximum 150 characters
  - Can be organization name or URL
  - Use for attribution of external content
- **Example**: `SOURCE: National Weather Service`

### tags (metadata line)

- **Format**: `--> tags: tag1,tag2,tag3`
- **Location**: Before npub, after content section begins
- **Required**: No (optional)
- **Constraints**:
  - Comma-separated list
  - No spaces between tags
  - Lowercase recommended
  - Maximum 10 tags
  - Each tag maximum 20 characters
- **Example**: `--> tags: weather,emergency,safety`

### npub (metadata line)

- **Format**: `--> npub: npub1...`
- **Location**: After tags (or before content if no tags)
- **Required**: Yes
- **Constraints**:
  - NOSTR public key in npub format
  - Starts with `npub1`
  - Bech32-encoded
  - 63 characters total
- **Example**: `--> npub: npub1qqqsyqcyq5rqwzqfpte9wrm7x9hhj23f9s8h5rwwqsyqcyq5rqwzqfp`
- **Purpose**: Cryptographic identity verification

### signature (metadata line)

- **Format**: `--> signature: hex_signature`
- **Location**: MUST be last metadata line before comments
- **Required**: Yes
- **Constraints**:
  - Hexadecimal string
  - 128 characters (64 bytes)
  - Generated using NOSTR signing algorithm
  - Signs hash of all content above this line
- **Example**: `--> signature: 3e8d94f1a2b6c3d5e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0`
- **Critical**: MUST be verified before trusting news content

### icon_like (metadata line)

- **Format**: `--> icon_like: USER1,USER2,USER3`
- **Location**: After signature, before comments
- **Required**: No (optional)
- **Constraints**:
  - Comma-separated list of callsigns
  - Users who "liked" this news item
  - Added/updated by system, not author
- **Example**: `--> icon_like: ALPHA1,BRAVO2,CR7BBQ`

### file (metadata line)

- **Format**: `--> file: {sha1_hash}_{filename}`
- **Location**: In content section, can be multiple
- **Required**: No (optional)
- **Constraints**:
  - SHA1 hash (40 hex chars) + underscore + original filename
  - File must exist in `files/` subdirectory for that year
  - Multiple files supported (one per line)
- **Example**: `--> file: a3f8d9e2b1c4f5e6d7a8b9c0d1e2f3a4b5c6d7e8_map.png`

---

## Location Support

### Geographic Targeting

News items can specify a geographic location and radius to indicate relevance to specific areas.

#### Components

1. **LOCATION**: Precise coordinates (latitude, longitude)
2. **ADDRESS**: Human-readable description
3. **RADIUS**: Applicable area in kilometers

#### When to Use

- Emergency alerts for specific areas
- Local event announcements
- Weather warnings
- Road closures or traffic alerts
- Neighborhood-specific news
- Safety alerts with geographic scope

#### Example Use Case

```
LOCATION: 37.774929,-122.419418
ADDRESS: Downtown San Francisco, Market Street
RADIUS: 2.5
```

**Interpretation**: This news is relevant within 2.5 km of the specified coordinates (approximately downtown San Francisco area).

#### Distance Calculation

Implementations should use the Haversine formula or similar spherical distance calculation to determine if a user is within the specified radius.

**Basic algorithm**:
1. Get user's current location (lat/lon)
2. Calculate distance to news LOCATION
3. If distance ≤ RADIUS, news is geographically relevant
4. Display prominently if within radius

#### Privacy Considerations

- LOCATION is always author's choice to publish
- Users' locations should never be exposed
- Distance calculations done locally on user device
- RADIUS defines public visibility scope, not privacy boundary

---

## Classification System

News items use a three-tier classification system to indicate urgency and priority.

### Classification Levels

#### 1. normal (Default)

- **Use Case**: Standard news items, general announcements
- **Priority**: Regular/low
- **Visual Treatment**: Standard display
- **User Action**: Read when convenient
- **Examples**:
  - Community updates
  - Event announcements
  - General news items
  - Non-urgent information

#### 2. urgent

- **Use Case**: Time-sensitive information requiring attention
- **Priority**: High
- **Visual Treatment**: Highlighted, bold, or colored differently
- **User Action**: Read soon, may require response
- **Examples**:
  - Weather warnings
  - School closures
  - Traffic alerts
  - Service outages
  - Time-limited opportunities

#### 3. danger

- **Use Case**: Safety-critical alerts requiring immediate awareness
- **Priority**: Critical/highest
- **Visual Treatment**: Strong visual indicators (red, flashing, prominent)
- **User Action**: Read immediately, take action if applicable
- **Examples**:
  - Severe weather warnings (tornado, hurricane)
  - Public safety threats
  - Evacuation notices
  - Hazardous material incidents
  - Missing person alerts (Amber alerts)
  - Active emergency situations

### Classification Guidelines

#### For Publishers

- **Don't Over-Classify**: Use `normal` as default, reserve `urgent` and `danger` for appropriate situations
- **Consider Impact**: Would delay in reading cause harm or significant inconvenience?
- **Time Sensitivity**: If content becomes irrelevant quickly, consider `urgent` or `danger` with EXPIRY
- **Geographic Scope**: Use LOCATION + RADIUS to limit danger/urgent alerts to affected areas
- **Err on Side of Caution**: When in doubt about safety, prefer higher classification

#### For Implementations

- **Visual Hierarchy**: Clear visual distinction between levels
- **Notification Priority**: `danger` may warrant push notifications, `normal` may not
- **Sound/Vibration**: Consider audio alerts for `danger` classification
- **Do Not Disturb**: Respect user preferences, but consider overriding for `danger` in emergency
- **Archive Treatment**: Expired `danger` items should be clearly marked as no longer active

---

## Expiry and Temporal Features

### Expiry Mechanism

News items can specify an EXPIRY timestamp after which they are considered outdated.

#### Format

```
EXPIRY: 2025-01-16 18:00:00
```

#### Behavior

1. **Before Expiry**: Display normally according to classification
2. **After Expiry**:
   - Move to archived/expired section
   - Visual indicator (grayed out, "EXPIRED" badge)
   - Lower priority in listings
   - Exclude from "active news" count
   - Still searchable and readable

#### Use Cases

- Event announcements (expire after event time)
- Time-limited offers or opportunities
- Weather alerts (expire when weather passes)
- Road closures (expire when reopened)
- Temporary service disruptions

#### Example

```
# HEADLINE: Road Closure on Main Street

AUTHOR: PUBLIC_WORKS
PUBLISHED: 2025-01-15 08:00:00
CLASSIFICATION: urgent
LOCATION: 37.774929,-122.419418
ADDRESS: Main Street between 1st and 5th Avenue
RADIUS: 1.0
EXPIRY: 2025-01-15 18:00:00

Main Street will be closed for repaving from 8 AM to 6 PM today. Please use alternative routes.

--> signature: ...
```

**Result**: After 18:00 on 2025-01-15, this alert automatically becomes archived.

### Temporal Best Practices

1. **Always Set EXPIRY for Time-Bounded Events**: Don't leave outdated alerts active
2. **Be Generous with Expiry Time**: Add buffer to avoid premature expiration
3. **Consider Timezones**: Use UTC or be explicit about timezone
4. **Update if Needed**: If situation extends, edit EXPIRY (requires new signature)
5. **Don't Rely on Manual Deletion**: EXPIRY ensures automatic archival

---

## Reactions and Engagement

### Likes

News items support inline "like" reactions from readers.

#### Format

```
--> icon_like: CALLSIGN1,CALLSIGN2,CALLSIGN3
```

#### Location

- After signature
- Before comments
- Updated by system when users like/unlike

#### Behavior

- User clicks "like" button → their callsign added to list
- User unlikes → their callsign removed
- Order: chronological (first liker first)
- Deduplicated: each callsign appears once

#### Example

```
--> signature: 3e8d94f1a2b6c3d5...
--> icon_like: ALPHA1,BRAVO2,CR7BBQ,DELTA4
```

**Interpretation**: Four users (ALPHA1, BRAVO2, CR7BBQ, DELTA4) have liked this news item.

### Future Reaction Types

The format supports additional reaction types following the same pattern:

```
--> icon_bookmark: USER1,USER2
--> icon_share: USER3,USER4
```

---

## Comments

Comments allow readers to discuss and respond to news items.

### Comment Format

Comments are appended to the news file after all metadata, using the standard format:

```
> YYYY-MM-DD HH:MM:SS -- CALLSIGN
Comment text goes here.
Can span multiple lines.
--> npub: npub1...
--> signature: hex_signature
```

### Comment Structure

1. **Header Line**: `>` + space + timestamp + ` -- ` + callsign
2. **Content**: One or more lines of comment text
3. **npub**: (optional) Commenter's NOSTR public key
4. **signature**: (optional) Signature of comment, MUST be last line if present

### Comment Ordering

- Chronological order (oldest first)
- Flat structure (no nested replies)
- Each comment is independent

### Complete Example with Comments

```
# HEADLINE: Community Meeting Tomorrow

AUTHOR: MAYOR_OFFICE
PUBLISHED: 2025-01-15 10:00:00
CLASSIFICATION: normal
LOCATION: 37.774929,-122.419418
ADDRESS: City Hall, Main Chamber
--> npub: npub1mayor...
--> tags: community,meeting

Join us tomorrow at 7 PM for the monthly community meeting. Topics include park renovations and traffic improvements.

--> signature: abc123def456...
--> icon_like: ALPHA1,BRAVO2

> 2025-01-15 11:30:00 -- ALPHA1
Will there be a virtual option for those who can't attend in person?
--> npub: npub1alpha...
--> signature: fed987cba654...

> 2025-01-15 12:15:00 -- MAYOR_OFFICE
Yes, we'll have a Zoom link posted on the city website by tomorrow morning.
--> npub: npub1mayor...
--> signature: 789abc123def...

> 2025-01-15 13:45:00 -- BRAVO2
Looking forward to the park discussion. Thanks for organizing!
--> npub: npub1bravo...
--> signature: 456def789abc...
```

### Comment Best Practices

1. **Keep On Topic**: Comments should relate to the news item
2. **Sign Important Responses**: Official responses should always be signed
3. **Moderate as Needed**: Inappropriate comments can be removed (requires collection management permissions)
4. **Respect Thread**: Read existing comments before posting
5. **Be Constructive**: Focus on discussion, not arguments

---

## File Attachments

News items can include file attachments such as images, maps, or documents.

### Storage Location

Files are stored in the `files/` subdirectory within each year:

```
news/
└── 2025/
    ├── 2025-01-15_weather-warning.md
    └── files/
        └── a3f8d9e2b1c4f5e6d7a8b9c0d1e2f3a4b5c6d7e8_radar-map.png
```

### File Naming

**Pattern**: `{sha1_hash}_{original_filename}`

**Components**:
1. **SHA1 Hash**: 40 hexadecimal characters
2. **Underscore**: Separator
3. **Original Filename**: Preserved for human readability

**Example**: `a3f8d9e2b1c4f5e6d7a8b9c0d1e2f3a4b5c6d7e8_radar-map.png`

### SHA1 Hash Calculation

The SHA1 hash is calculated from the file's binary content:

```
sha1_hash = SHA1(file_binary_content)
```

This provides:
- Content-addressable storage (same file = same hash)
- Deduplication (identical files across news items share storage)
- Integrity verification (hash confirms file hasn't been modified)

### Referencing Files in News Items

Use the `--> file:` metadata line:

```
--> file: a3f8d9e2b1c4f5e6d7a8b9c0d1e2f3a4b5c6d7e8_radar-map.png
```

Multiple files:

```
--> file: a3f8d9e2...e8_map.png
--> file: b8e3c1a9...1b_photo.jpg
--> file: c9d4e8b2...7c_document.pdf
```

### Supported File Types

Common file types for news attachments:

- **Images**: .jpg, .jpeg, .png, .gif, .webp
- **Documents**: .pdf
- **Data**: .json, .csv
- **Video**: .mp4, .webm (use judiciously, large files)

### File Size Considerations

- Recommended maximum: 5 MB per file
- Total attachments per news item: 20 MB recommended
- Large files impact sync performance
- Consider linking to external hosting for large media

### Example with Attachments

```
# HEADLINE: Severe Weather Warning

AUTHOR: WEATHER_SERVICE
PUBLISHED: 2025-01-15 14:00:00
CLASSIFICATION: danger
LOCATION: 37.774929,-122.419418
RADIUS: 50.0
EXPIRY: 2025-01-16 02:00:00
--> npub: npub1weather...

Severe thunderstorm warning in effect until 2 AM tomorrow. Heavy rain, strong winds, and possible flooding expected. Stay indoors and avoid travel.

--> file: a3f8d9e2b1c4f5e6d7a8b9c0d1e2f3a4b5c6d7e8_radar-map.png
--> file: b8e3c1a9d7f2e3c4b5a6d7e8f9a0b1c2d3e4f1a2_forecast.png
--> signature: 3e8d94f1a2b6...
```

---

## NOSTR Integration

News items use NOSTR (Notes and Other Stuff Transmitted by Relays) cryptographic protocol for identity and authenticity verification.

### Why NOSTR for News?

- **Verifiable Authorship**: Prove who published the news
- **Tamper Detection**: Any modification breaks the signature
- **Decentralized Identity**: No central authority needed
- **Trust Network**: Users can verify trusted news sources
- **Non-Repudiation**: Authors cannot deny publishing signed content

### Key Components

#### 1. npub (Public Key)

- **Format**: `npub1...` (63 characters, bech32-encoded)
- **Purpose**: Author's public identity
- **Location**: `--> npub:` metadata line
- **Uniqueness**: Each author has a unique npub

#### 2. nsec (Private Key)

- **Format**: `nsec1...` (63 characters, bech32-encoded)
- **Purpose**: Used to sign content (NEVER share or publish)
- **Storage**: Keep secure, like a password
- **Usage**: Only for signing, never transmitted

#### 3. Signature

- **Format**: Hexadecimal string (128 characters)
- **Purpose**: Proves content was signed by npub's corresponding nsec
- **Location**: `--> signature:` metadata line (MUST be last metadata)
- **Algorithm**: Schnorr signature on SHA-256 hash of content

### Signing Process

#### Content to Sign

The signature covers all content from the beginning of the file up to (but not including) the signature line itself.

**Example**:

```
# HEADLINE: Breaking News Alert

AUTHOR: NEWS_DESK
PUBLISHED: 2025-01-15 14:30:00
CLASSIFICATION: urgent
--> npub: npub1newsdesk...

This is the news content that will be signed.

--> signature: [SIGNATURE GOES HERE]
```

**Signed Content** (everything before `-->  signature:`):

```
# HEADLINE: Breaking News Alert

AUTHOR: NEWS_DESK
PUBLISHED: 2025-01-15 14:30:00
CLASSIFICATION: urgent
--> npub: npub1newsdesk...

This is the news content that will be signed.

```

#### Signing Algorithm

```
1. Extract all content before the signature line
2. Normalize line endings to \n (LF)
3. Calculate SHA-256 hash of content
4. Sign hash using nsec (private key) with Schnorr signature
5. Convert signature to hexadecimal string
6. Add as `--> signature: hex_value` (MUST be last metadata line)
```

#### Pseudocode

```python
def sign_news_item(content, nsec):
    # Find signature line position
    sig_line_index = content.find('\n--> signature:')
    if sig_line_index == -1:
        # No signature line yet, sign entire content
        to_sign = content
    else:
        # Sign everything before signature line
        to_sign = content[:sig_line_index + 1]  # Include final newline

    # Normalize line endings
    normalized = to_sign.replace('\r\n', '\n')

    # Hash content
    hash = sha256(normalized.encode('utf-8'))

    # Sign with private key
    signature = schnorr_sign(hash, nsec)

    # Convert to hex
    sig_hex = signature.hex()

    return sig_hex
```

### Verification Process

Readers and applications MUST verify signatures before trusting news content.

#### Verification Algorithm

```
1. Extract npub (public key)
2. Extract signature (last metadata line)
3. Extract content to verify (everything before signature line)
4. Normalize line endings to \n
5. Calculate SHA-256 hash
6. Verify signature using npub and hash
7. If valid: content is authentic
8. If invalid: content has been tampered with or signature is fake
```

#### Pseudocode

```python
def verify_news_item(content):
    # Extract npub
    npub_match = re.search(r'--> npub: (npub1[a-z0-9]{58})', content)
    if not npub_match:
        return False, "No npub found"
    npub = npub_match.group(1)

    # Extract signature (must be last metadata line)
    sig_match = re.search(r'--> signature: ([a-f0-9]{128})', content)
    if not sig_match:
        return False, "No signature found"
    signature_hex = sig_match.group(1)

    # Get content before signature
    sig_line_pos = content.find('\n--> signature:')
    to_verify = content[:sig_line_pos + 1]

    # Normalize
    normalized = to_verify.replace('\r\n', '\n')

    # Hash
    hash = sha256(normalized.encode('utf-8'))

    # Verify
    signature = bytes.fromhex(signature_hex)
    is_valid = schnorr_verify(hash, signature, npub)

    if is_valid:
        return True, "Signature valid"
    else:
        return False, "Signature invalid - content may be tampered"
```

### Key Management

#### Generating Keys

Use NOSTR-compatible tools to generate key pairs:

```bash
# Example using nostr-tools or similar
nostr-keygen generate

# Output:
# Private key (nsec): nsec1qqqsyqcyq5rqwzqf...  (KEEP SECRET)
# Public key (npub): npub1qqqsyqcyq5rqwzqf...  (SHARE PUBLICLY)
```

#### Storing Keys Securely

- **Private Key (nsec)**:
  - Never commit to version control
  - Store in secure keychain or password manager
  - Encrypt at rest
  - Limit access to authorized publishers only

- **Public Key (npub)**:
  - Publish freely
  - Include in all signed content
  - Share with readers for verification

#### Key Rotation

If a private key is compromised:

1. Generate new key pair
2. Publish announcement with OLD key about switch
3. Begin using NEW key for future news
4. Old news remains verifiable with old key
5. Users learn to trust new npub

### Trust and Reputation

#### Building Trust

- **Consistent Signing**: Always sign all news items
- **Verification**: Encourage readers to verify signatures
- **Key Stability**: Don't change keys frequently without reason
- **Transparency**: Publish npub prominently, allow verification

#### Reputation Systems

Implementations can build trust layers:

- **Trust Lists**: Users maintain lists of trusted npubs
- **Verification Badges**: UI shows verification status
- **Historical Accuracy**: Track source reliability over time
- **Community Vouching**: Web of trust between verified sources

---

## Complete Examples

### Example 1: Simple News Item

```markdown
# HEADLINE: Community Farmers Market This Saturday

AUTHOR: COMMUNITY_CENTER
PUBLISHED: 2025-01-15 09:00:00
CLASSIFICATION: normal
--> npub: npub1qqqsyqcyq5rqwzqfpte9wrm7x9hhj23f9s8h5rwwqsyqcyq5rqwzqfp
--> tags: community,market,local

Join us this Saturday from 8 AM to 2 PM for the weekly farmers market at Community Center. Fresh local produce, artisan goods, and live music!

--> signature: 3e8d94f1a2b6c3d5e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0
```

### Example 2: Urgent Weather Alert with Location

```markdown
# HEADLINE: Flash Flood Warning

AUTHOR: WEATHER_SERVICE
PUBLISHED: 2025-01-15 14:30:00
CLASSIFICATION: urgent
LOCATION: 37.774929,-122.419418
ADDRESS: San Francisco Bay Area
RADIUS: 25.0
EXPIRY: 2025-01-15 23:00:00
SOURCE: National Weather Service
--> npub: npub1weathersvckqqsyqcyq5rqwzqfpte9wrm7x9hhj23f9s8h5rwwqsyqcyqfp
--> tags: weather,flooding,emergency

Flash flood warning in effect until 11 PM tonight. Heavy rainfall expected. Avoid low-lying areas and do not attempt to cross flooded roads. Stay informed and follow emergency updates.

--> file: a3f8d9e2b1c4f5e6d7a8b9c0d1e2f3a4b5c6d7e8_radar-image.png
--> signature: f1e2d3c4b5a6978869504a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2
```

### Example 3: Danger Alert with Comments

```markdown
# HEADLINE: Gas Leak - Evacuation Notice

AUTHOR: FIRE_DEPT
PUBLISHED: 2025-01-15 16:45:00
CLASSIFICATION: danger
LOCATION: 37.780000,-122.425000
ADDRESS: 500 Block of Oak Street
RADIUS: 0.5
EXPIRY: 2025-01-15 20:00:00
--> npub: npub1firedeptqqqsyqcyq5rqwzqfpte9wrm7x9hhj23f9s8h5rwwqsyqcyqfp
--> tags: emergency,evacuation,safety

Gas leak reported at 500 Oak Street. Residents within 500 meters must evacuate immediately. Emergency crews on scene. Shelter available at Community Center (600 Main St). Call 911 if assistance needed.

--> signature: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2
--> icon_like: ALPHA1,BRAVO2,CR7BBQ

> 2025-01-15 17:00:00 -- COMMUNITY_CENTER
Shelter is open and ready to receive evacuees. Hot drinks and blankets available.
--> npub: npub1commcenterqqqsyqcyq5rqwzqfpte9wrm7x9hhj23f9s8h5rwwqsyqfp
--> signature: c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4

> 2025-01-15 17:15:00 -- ALPHA1
Thank you for the quick response. We're at the shelter now and appreciate the support.
--> npub: npub1alpha1qqqsyqcyq5rqwzqfpte9wrm7x9hhj23f9s8h5rwwqsyqcyqfp
--> signature: d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6
```

### Example 4: Event Announcement with Expiry

```markdown
# HEADLINE: City Council Special Session

AUTHOR: CITY_CLERK
PUBLISHED: 2025-01-14 10:00:00
CLASSIFICATION: normal
LOCATION: 37.774929,-122.419418
ADDRESS: City Hall, 400 Van Ness Avenue
EXPIRY: 2025-01-16 19:00:00
--> npub: npub1cityclerkqqsyqcyq5rqwzqfpte9wrm7x9hhj23f9s8h5rwwqsyqcyqfp
--> tags: government,meeting,public

Special City Council session on Thursday, January 16 at 6 PM to discuss the proposed budget amendments. Public comments welcome. Agenda available on city website. Virtual attendance via Zoom link.

--> file: b8e3c1a9d7f2e3c4b5a6d7e8f9a0b1c2d3e4f1a2_agenda.pdf
--> signature: e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8
```

### Example 5: Road Closure with Multiple Attachments

```markdown
# HEADLINE: Main Street Bridge Closure

AUTHOR: PUBLIC_WORKS
PUBLISHED: 2025-01-15 07:00:00
CLASSIFICATION: urgent
LOCATION: 37.785000,-122.430000
ADDRESS: Main Street Bridge at River Road
RADIUS: 5.0
EXPIRY: 2025-01-20 18:00:00
--> npub: npub1pubworksqqqsyqcyq5rqwzqfpte9wrm7x9hhj23f9s8h5rwwqsyqcyqfp
--> tags: traffic,construction,infrastructure

Main Street Bridge closed for emergency repairs Jan 15-20. Detour via River Road and Highway 101. See attached maps for alternate routes. Expect 15-20 minute delays during peak hours. Thank you for patience.

--> file: c9d4e8b2a3f1e5c7d9b0a1e2f3c4d5e6f7a8b9c0_detour-map.png
--> file: d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9_bridge-photo.jpg
--> signature: f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0
--> icon_like: DELTA4,ECHO5,FOXTROT6

> 2025-01-15 08:30:00 -- DELTA4
What about bicycle access? Is there a pedestrian detour?
--> npub: npub1delta4qqqsyqcyq5rqwzqfpte9wrm7x9hhj23f9s8h5rwwqsyqcyqfp
--> signature: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2

> 2025-01-15 09:15:00 -- PUBLIC_WORKS
Yes, pedestrian/bicycle path remains open on the north side of the bridge during repairs.
--> npub: npub1pubworksqqqsyqcyq5rqwzqfpte9wrm7x9hhj23f9s8h5rwwqsyqcyqfp
--> signature: b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4
```

### Example 6: Source Attribution

```markdown
# HEADLINE: New Study on Local Air Quality Released

AUTHOR: ENV_AGENCY
PUBLISHED: 2025-01-15 11:00:00
CLASSIFICATION: normal
LOCATION: 37.774929,-122.419418
ADDRESS: San Francisco Bay Area
RADIUS: 50.0
SOURCE: EPA Air Quality Research Division
--> npub: npub1envagencyqqsyqcyq5rqwzqfpte9wrm7x9hhj23f9s8h5rwwqsyqcyqfp
--> tags: environment,health,research

EPA releases comprehensive air quality study for the Bay Area. Results show improvement in particulate matter levels over past 5 years. Full report available at epa.gov/bayarea-air-quality

--> file: e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0_summary-report.pdf
--> signature: c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6
```

---

## Parsing Implementation

### Parsing Algorithm

Step-by-step process for parsing a news item file:

```
1. READ file contents into string
2. VERIFY file is not empty
3. PARSE headline (first line)
   - Must start with "# HEADLINE: "
   - Extract title portion
4. PARSE structured fields (lines 2+)
   - AUTHOR: extract callsign
   - PUBLISHED: extract and validate timestamp
   - CLASSIFICATION: extract and validate level
   - LOCATION: optional, extract and validate coordinates
   - ADDRESS: optional, extract text
   - RADIUS: optional, extract and validate number
   - EXPIRY: optional, extract and validate timestamp
   - SOURCE: optional, extract text
5. FIND metadata section start
   - Look for lines starting with "--> "
   - Extract tags, npub before content
6. EXTRACT content
   - Text between structured fields and metadata lines
   - Trim whitespace
   - Validate length ≤ 500 characters
7. PARSE metadata lines
   - tags: split comma-separated list
   - npub: extract and validate format
   - file: extract attachments (can be multiple)
   - signature: extract hex string (MUST be last metadata)
8. PARSE reactions
   - icon_like: split comma-separated callsigns
9. PARSE comments
   - Find lines starting with "> "
   - Extract timestamp, callsign, content
   - Extract comment metadata (npub, signature)
10. VERIFY signature
    - Calculate hash of content before signature line
    - Verify signature matches npub
11. RETURN structured data object
```

### Pseudocode

```python
def parse_news_item(file_path):
    # Read file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if not content:
        raise ParseError("Empty file")

    lines = content.split('\n')
    news_item = {}

    # Parse headline (line 0)
    if not lines[0].startswith('# HEADLINE: '):
        raise ParseError("Missing headline")
    news_item['headline'] = lines[0][12:].strip()

    # Parse structured fields
    i = 1
    while i < len(lines):
        line = lines[i].strip()

        if line.startswith('AUTHOR: '):
            news_item['author'] = line[8:].strip()
        elif line.startswith('PUBLISHED: '):
            news_item['published'] = parse_timestamp(line[11:].strip())
        elif line.startswith('CLASSIFICATION: '):
            news_item['classification'] = line[16:].strip()
            validate_classification(news_item['classification'])
        elif line.startswith('LOCATION: '):
            news_item['location'] = parse_coordinates(line[10:].strip())
        elif line.startswith('ADDRESS: '):
            news_item['address'] = line[9:].strip()
        elif line.startswith('RADIUS: '):
            news_item['radius'] = float(line[8:].strip())
            validate_radius(news_item['radius'])
        elif line.startswith('EXPIRY: '):
            news_item['expiry'] = parse_timestamp(line[8:].strip())
        elif line.startswith('SOURCE: '):
            news_item['source'] = line[8:].strip()
        elif line.startswith('--> ') or line == '':
            # End of structured fields
            break

        i += 1

    # Extract content (between structured fields and metadata)
    content_start = i
    content_lines = []
    while i < len(lines):
        line = lines[i]
        if line.startswith('--> '):
            break
        content_lines.append(line)
        i += 1

    news_item['content'] = '\n'.join(content_lines).strip()

    # Validate content length
    if len(news_item['content']) > 500:
        raise ParseError(f"Content exceeds 500 chars: {len(news_item['content'])}")

    # Parse metadata lines
    news_item['tags'] = []
    news_item['files'] = []

    while i < len(lines):
        line = lines[i].strip()

        if line.startswith('--> tags: '):
            news_item['tags'] = line[10:].split(',')
        elif line.startswith('--> npub: '):
            news_item['npub'] = line[10:].strip()
            validate_npub(news_item['npub'])
        elif line.startswith('--> file: '):
            news_item['files'].append(line[10:].strip())
        elif line.startswith('--> signature: '):
            news_item['signature'] = line[15:].strip()
            break  # Signature must be last metadata
        elif line.startswith('--> icon_like: '):
            news_item['likes'] = line[15:].split(',')
        elif line.startswith('> '):
            # Start of comments
            break

        i += 1

    # Parse comments
    news_item['comments'] = parse_comments(lines[i:])

    # Verify signature
    if not verify_signature(content, news_item['npub'], news_item['signature']):
        raise SignatureError("Invalid signature")

    return news_item


def parse_timestamp(ts_str):
    # Parse "YYYY-MM-DD HH:MM:SS"
    return datetime.strptime(ts_str, '%Y-%m-%d %H:%M:%S')


def parse_coordinates(coord_str):
    # Parse "lat,lon"
    parts = coord_str.split(',')
    if len(parts) != 2:
        raise ParseError("Invalid coordinates format")
    lat = float(parts[0])
    lon = float(parts[1])
    if not (-90 <= lat <= 90):
        raise ParseError(f"Invalid latitude: {lat}")
    if not (-180 <= lon <= 180):
        raise ParseError(f"Invalid longitude: {lon}")
    return (lat, lon)


def validate_classification(classification):
    valid = ['normal', 'urgent', 'danger']
    if classification not in valid:
        raise ParseError(f"Invalid classification: {classification}")


def validate_radius(radius):
    if not (0.1 <= radius <= 100):
        raise ParseError(f"Radius must be 0.1-100 km: {radius}")


def validate_npub(npub):
    if not npub.startswith('npub1'):
        raise ParseError("npub must start with 'npub1'")
    if len(npub) != 63:
        raise ParseError(f"npub must be 63 characters: {len(npub)}")


def parse_comments(lines):
    comments = []
    i = 0

    while i < len(lines):
        line = lines[i]

        if line.startswith('> '):
            # Comment header: > TIMESTAMP -- CALLSIGN
            header = line[2:].strip()
            parts = header.split(' -- ')
            if len(parts) != 2:
                i += 1
                continue

            timestamp = parse_timestamp(parts[0])
            callsign = parts[1]

            # Collect comment content
            i += 1
            content_lines = []
            comment_npub = None
            comment_sig = None

            while i < len(lines):
                line = lines[i]

                if line.startswith('> '):
                    # Next comment
                    break
                elif line.startswith('--> npub: '):
                    comment_npub = line[10:].strip()
                elif line.startswith('--> signature: '):
                    comment_sig = line[15:].strip()
                    i += 1
                    break
                else:
                    content_lines.append(line)

                i += 1

            comments.append({
                'timestamp': timestamp,
                'author': callsign,
                'content': '\n'.join(content_lines).strip(),
                'npub': comment_npub,
                'signature': comment_sig
            })
        else:
            i += 1

    return comments
```

---

## File Operations

### Creating a News Item

**Steps**:

1. **Choose Title and Date**: Determine publication date and headline
2. **Generate Filename**: `YYYY-MM-DD_sanitized-title.md` in appropriate year directory
3. **Prepare Content**: Write news text (max 500 chars)
4. **Set Metadata**: Classification, location, expiry, etc.
5. **Add NOSTR Keys**: Include npub for identity
6. **Sign Content**: Generate signature using nsec
7. **Write File**: Save to news collection
8. **Add Attachments** (if any): Copy to `files/` with SHA1 naming, reference in content

**Example Command** (pseudocode):

```bash
news create \
  --title "Community Meeting Tomorrow" \
  --classification normal \
  --content "Join us tomorrow at 7 PM..." \
  --location "37.774929,-122.419418" \
  --radius 5.0 \
  --author MAYOR_OFFICE \
  --nsec nsec1... \
  --output news/2025/2025-01-15_community-meeting.md
```

### Reading News Items

**Query Patterns**:

```python
# Get all active (non-expired) news
active_news = get_news_items(filter_expired=True)

# Get news within radius of user location
nearby_news = get_news_items(
    user_location=(37.7749, -122.4194),
    max_distance_km=10
)

# Get urgent/danger items only
alerts = get_news_items(
    classifications=['urgent', 'danger']
)

# Get news with specific tags
tagged = get_news_items(tags=['emergency', 'weather'])

# Get news from specific author
author_news = get_news_items(author_npub='npub1...')
```

### Updating a News Item

**Considerations**:

- Editing content requires **new signature** (old signature becomes invalid)
- Preserve original PUBLISHED timestamp
- May add UPDATE field to show modification date
- Comments remain unchanged

**Steps**:

1. Read existing news item
2. Modify desired fields/content
3. Remove old signature
4. Generate new signature with nsec
5. Write updated file

**Note**: Some implementations may prefer creating new news items rather than editing, to preserve history.

### Deleting a News Item

**Options**:

1. **File Deletion**: Remove file entirely (loses history)
2. **Archival**: Move to `archived/` subdirectory
3. **Expiry**: Set EXPIRY to past date (soft deletion)

**Recommendation**: Use EXPIRY for soft deletion to maintain audit trail.

---

## Validation Rules

### Required Validations

When parsing or creating news items, implementations MUST verify:

- [x] First line starts with `# HEADLINE: ` followed by title (1-100 chars)
- [x] AUTHOR field present with valid callsign (3-20 alphanumeric chars)
- [x] PUBLISHED field present with valid timestamp format
- [x] CLASSIFICATION field present with value: `normal`, `urgent`, or `danger`
- [x] npub present and valid format (`npub1` prefix, 63 chars total)
- [x] Content present and ≤ 500 characters
- [x] signature present and valid format (128 hex chars)
- [x] signature is LAST metadata line before comments
- [x] Signature verification passes for npub and content

### Optional Field Validations

If present, these fields must be valid:

- [x] LOCATION: Valid latitude (-90 to +90) and longitude (-180 to +180)
- [x] ADDRESS: ≤ 200 characters
- [x] RADIUS: 0.1 to 100.0 km, requires LOCATION
- [x] EXPIRY: Valid timestamp, must be after PUBLISHED
- [x] SOURCE: ≤ 150 characters
- [x] tags: ≤ 10 tags, each ≤ 20 characters
- [x] file references: Files exist in `files/` subdirectory, valid SHA1 format

### Filename Validations

- [x] Located in `news/YYYY/` directory matching publication year
- [x] Format: `YYYY-MM-DD_title.md`
- [x] Date matches PUBLISHED field (at least the day)
- [x] Title portion: lowercase, hyphens only, 1-50 chars
- [x] `.md` extension

### Comment Validations

For each comment:

- [x] Starts with `> ` followed by timestamp and ` -- ` and callsign
- [x] Timestamp is valid format
- [x] Content is non-empty
- [x] If npub present, valid format
- [x] If signature present, it's last line of comment and valid

### Security Validations

- [x] Signature verification MUST pass before displaying as verified
- [x] npub matches signature (cryptographic verification)
- [x] No code injection in any text fields
- [x] File attachments scanned for malware (recommended)
- [x] RADIUS not used without LOCATION
- [x] EXPIRY is future date (if time-sensitive content)

### Validation Error Handling

**Fatal Errors** (reject file):
- Missing required fields
- Invalid signature
- Content exceeds 500 characters
- Invalid CLASSIFICATION value
- Malformed LOCATION coordinates

**Warnings** (accept with caveat):
- RADIUS without LOCATION (ignore RADIUS)
- EXPIRY in the past (treat as expired)
- Unrecognized metadata lines (ignore)
- Missing optional fields (defaults apply)

---

## Best Practices

### For News Publishers

#### Content Guidelines

1. **Be Concise**: 500 character limit forces clarity and brevity
2. **Lead with Key Info**: Most important details first (inverted pyramid style)
3. **Use Active Voice**: Direct and clear language
4. **Verify Before Publishing**: Check facts, especially for urgent/danger items
5. **Attribute Sources**: Use SOURCE field for external information
6. **Update When Needed**: Issue corrections if errors found

#### Classification Usage

1. **Default to Normal**: Most news should be `normal` classification
2. **Reserve Urgent**: Use for time-sensitive, actionable information
3. **Danger Sparingly**: Only for safety-critical alerts
4. **Don't Cry Wolf**: Over-classification reduces trust and attention

#### Location and Targeting

1. **Be Specific**: Precise coordinates for local issues
2. **Appropriate Radius**: Match affected area (0.5 km for block, 50 km for region)
3. **Include ADDRESS**: Human-readable location helps readers
4. **Privacy Respect**: Don't publish personal addresses without consent

#### Signing and Authentication

1. **Always Sign**: Never publish unsigned news
2. **Protect Private Key**: nsec is like a password - never share
3. **Consistent Identity**: Use same npub for your organization/role
4. **Verify Before Signing**: Signature implies endorsement

#### Expiry Management

1. **Set Expiry for Events**: Automatically archive event announcements
2. **Be Conservative**: Better to expire later than too early
3. **Update if Extended**: Change expiry if situation changes
4. **Don't Auto-Expire Critical Info**: Some safety info should remain archived, not deleted

### For Application Developers

#### Display and UX

1. **Visual Hierarchy**: Clear distinction between normal/urgent/danger
2. **Verification Indicators**: Show signature verification status prominently
3. **Expiry Handling**: Gray out or separate expired news
4. **Location Awareness**: Prioritize geographically relevant news
5. **Push Notifications**: Consider push for `danger` within user's radius

#### Performance

1. **Cache Signatures**: Verification is computationally expensive
2. **Index by Date**: Fast chronological queries
3. **Index by Location**: Spatial index for geographic queries
4. **Lazy Load Comments**: Don't load all comments initially
5. **Prefetch Images**: SHA1 allows content-addressable caching

#### Security

1. **Always Verify Signatures**: Never display unverified content as authentic
2. **Isolate Rendering**: Sanitize content to prevent XSS
3. **Rate Limit Creation**: Prevent spam
4. **Validate All Inputs**: Don't trust file contents
5. **Scan Attachments**: Malware check uploaded files

#### Error Handling

1. **Graceful Degradation**: Show what you can parse, skip invalid
2. **User Feedback**: Explain why verification failed
3. **Log Anomalies**: Track signature failures for abuse detection
4. **Fallback Mode**: Allow reading without verification (with warnings)

### For Collection Administrators

#### Moderation

1. **Establish Guidelines**: Clear rules for content
2. **Monitor Abuse**: Watch for spam, misinformation, harassment
3. **Preserve Evidence**: Archive (don't delete) problematic content
4. **Transparent Actions**: Document moderation decisions
5. **Appeal Process**: Allow authors to respond to removals

#### Organization

1. **Regular Cleanup**: Archive/delete very old news
2. **Year Directories**: Create as needed, one per year
3. **File Management**: Monitor `files/` directory size
4. **Deduplication**: Leverage SHA1 to avoid duplicate files
5. **Backup Strategy**: Regular backups of entire collection

#### Trust Building

1. **Verify Publishers**: Know who has publishing access
2. **Publish Trust List**: Share trusted npubs with community
3. **Transparency**: Document verification processes
4. **Community Engagement**: Encourage discussion via comments
5. **Reputation Tracking**: Monitor source reliability over time

---

## Security Considerations

### Cryptographic Security

#### Signature Verification

**Critical**: Always verify signatures before trusting content

**Threat**: Attacker modifies news content after publication
**Mitigation**: Signature verification fails, content rejected

**Threat**: Attacker publishes fake news with someone else's npub
**Mitigation**: Without corresponding nsec, cannot generate valid signature

**Threat**: Replay attack (re-publish old signed content)
**Mitigation**: Check PUBLISHED timestamp, context relevance

#### Key Management

**Threat**: Private key (nsec) compromised
**Mitigation**:
- Store nsec securely (encrypted, access-controlled)
- Rotate keys if compromise suspected
- Use hardware security modules (HSM) for high-value publishers

**Threat**: Phishing for private keys
**Mitigation**:
- Education: Never share nsec
- UI warnings: Flag suspicious key requests
- Two-factor authentication for key access

### Content Security

#### Input Validation

**Threat**: Code injection (XSS, script injection)
**Mitigation**:
- Sanitize all content before rendering
- Use content security policy (CSP)
- Escape special characters in HTML context

**Threat**: Malicious file attachments
**Mitigation**:
- Scan files for malware
- Restrict file types
- Sandbox file viewer
- Warn users before download

#### Content Integrity

**Threat**: Man-in-the-middle modification
**Mitigation**:
- Use HTTPS for transmission
- Verify signature after download
- Hash-based file verification (SHA1)

### Privacy and Location

#### Location Privacy

**Threat**: Author location tracking
**Mitigation**:
- LOCATION is author's choice to publish
- Authors can omit or fuzz coordinates
- Use landmarks instead of exact addresses

**Threat**: User location exposure
**Mitigation**:
- All location filtering done locally on device
- Never transmit user location to servers
- Use approximate location for queries (city-level)

#### Metadata Leakage

**Threat**: Identifying users via likes/comments
**Mitigation**:
- Callsigns provide pseudonymity
- Users can use multiple callsigns
- Warn users that engagement is public

### Availability and Abuse

#### Spam and Flooding

**Threat**: Massive news item creation (spam)
**Mitigation**:
- Rate limiting on creation
- Proof-of-work for publishing
- Moderation and filtering
- Reputation-based prioritization

#### Denial of Service

**Threat**: Very large content or files
**Mitigation**:
- Enforce 500 character content limit
- Enforce file size limits
- Bandwidth throttling
- Content delivery networks (CDN)

#### Misinformation

**Threat**: False or misleading news
**Mitigation**:
- Signature verification establishes authorship (not truth)
- Community flagging system
- Fact-checking integrations
- Source reputation scoring
- User-maintained trust lists

### Classification Abuse

**Threat**: Over-classification to gain attention
**Mitigation**:
- Monitoring and moderation
- User feedback on appropriateness
- Reputation penalties for mis-classification
- Community standards enforcement

**Threat**: Under-classification of critical info
**Mitigation**:
- Automated detection of keywords (e.g., "emergency", "danger")
- Suggest higher classification to authors
- Community can flag for re-classification

### Expiry and Temporal Attacks

**Threat**: Delayed delivery of time-sensitive alert
**Mitigation**:
- Timestamp verification
- Network latency monitoring
- Multi-path distribution
- Real-time sync mechanisms

**Threat**: Manipulating expiry to hide evidence
**Mitigation**:
- Archive expired content (don't delete)
- Audit logs of modifications
- Immutable append-only logs
- Blockchain-style chaining (advanced)

---

## Related Documentation

### Core Specifications

- [Collection Root Format](../root-format-specification.md) - Top-level collection structure
- [Metadata Specification](../metadata-specification.md) - Shared metadata standards
- [File Formats](../file-formats.md) - General file format guidelines
- [Security Model](../security-model.md) - Collection-wide security architecture

### Other Collection Types

- [Blog Format](./blog-format-specification.md) - Long-form articles (similar structure)
- [Events Format](./events-format-specification.md) - Event announcements (similar location features)
- [Forum Format](./forum-format-specification.md) - Discussion threads
- [Chat Format](./chat-format-specification.md) - Real-time messaging

### Integration Guides

- [NOSTR Integration](../nostr-integration.md) - Detailed NOSTR protocol implementation
- [P2P Distribution](../p2p-integration.md) - Peer-to-peer sync mechanisms
- [API Reference](../api-reference.md) - Programmatic access to collections

### Implementation Examples

- [Parser Examples](../examples/parsers/) - Sample code for parsing news items
- [UI Components](../examples/ui/) - Example user interface implementations
- [Signing Tools](../examples/signing/) - Key management and signing utilities

---

## Change Log

### Version 1.0 (2025-01-21)

**Status**: Initial Release

**Changes**:
- Initial news format specification
- Three-tier classification system (normal, urgent, danger)
- Location support with coordinates, address, and radius
- Expiry mechanism for time-sensitive content
- Character limit of 500 for content
- NOSTR integration for cryptographic signing
- Inline reactions (likes) support
- Comment system compatible with other collection types
- File attachments with SHA1-based naming
- Year-based chronological organization
- Comprehensive validation rules
- Security considerations and best practices

**Contributors**: Geogram Documentation Team

**Next Steps**:
- Gather community feedback
- Monitor real-world usage patterns
- Consider additional classification levels if needed
- Evaluate multi-language support requirements

---

**Document End**

For questions, feedback, or contributions to this specification, please contact the Geogram development team or open an issue in the project repository.
