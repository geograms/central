# Metadata Specification

This document defines the metadata standards and best practices for Geogram Collections.

## Overview

Collection metadata serves multiple purposes:
- **Discovery**: Help users find relevant collections
- **Organization**: Categorize and tag collections
- **Attribution**: Credit creators and define usage rights
- **Analytics**: Track engagement and usage patterns
- **Quality**: Signal content quality and appropriateness

## Metadata Categories

### 1. Core Metadata (Required)

Defined in `collection.collection` object:

#### id
- **Type**: String (Nostr npub)
- **Required**: Yes
- **Description**: Unique collection identifier
- **Format**: Bech32-encoded Nostr public key
- **Example**: `"npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3z0qwe"`
- **Validation**: Must be valid npub format (63 characters, starts with "npub1")

#### title
- **Type**: String
- **Required**: Yes
- **Max Length**: 100 characters
- **Description**: Human-readable collection name
- **Guidelines**:
  - Be descriptive and specific
  - Avoid generic titles like "My Collection"
  - Use title case for proper nouns
  - Don't include version numbers (use tags instead)
- **Examples**:
  - Good: "Linux Kernel Documentation 6.5"
  - Bad: "docs", "stuff", "Collection 1"

#### description
- **Type**: String
- **Required**: Yes (can be empty)
- **Max Length**: 1000 characters
- **Description**: Detailed collection description
- **Guidelines**:
  - Explain what the collection contains
  - Describe the purpose or use case
  - Mention key features or highlights
  - Use plain text (no HTML/Markdown)
- **Example**:
```
Comprehensive documentation for the Linux Kernel version 6.5,
including API references, driver documentation, and kernel
development guides. Updated November 2025.
```

#### created
- **Type**: String (ISO 8601)
- **Required**: Yes
- **Format**: `YYYY-MM-DDTHH:mm:ssZ` (UTC)
- **Description**: Collection creation timestamp
- **Guidelines**:
  - Always use UTC timezone
  - Include full timestamp with seconds
  - Don't update this field after creation
- **Example**: `"2025-11-16T10:30:00Z"`

#### updated
- **Type**: String (ISO 8601)
- **Required**: Yes
- **Format**: `YYYY-MM-DDTHH:mm:ssZ` (UTC)
- **Description**: Last modification timestamp
- **Guidelines**:
  - Update when files are added/removed
  - Update when metadata changes
  - Update when security settings change
  - Don't update for stat changes only
- **Example**: `"2025-11-16T15:45:00Z"`

#### signature
- **Type**: String (hex)
- **Required**: No (future feature)
- **Description**: Nostr signature of collection metadata
- **Format**: Hex-encoded Schnorr signature
- **Purpose**: Verify authenticity and prevent tampering
- **Example**: `"a1b2c3d4e5f6..."`

### 2. Statistics (Computed)

Defined in `statistics` object:

#### files_count
- **Type**: Number
- **Description**: Total number of files (excluding folders)
- **Computation**: Count all items where `type = "file"`
- **Update**: When files are added/removed

#### folders_count
- **Type**: Number
- **Description**: Total number of folders
- **Computation**: Count all items where `type = "directory"`
- **Update**: When folders are created/removed

#### total_size
- **Type**: Number (bytes)
- **Description**: Combined size of all files
- **Computation**: Sum of all file sizes
- **Display**: Format as human-readable (KB, MB, GB, etc.)
- **Update**: When files are added/removed/modified

#### likes
- **Type**: Number
- **Description**: Number of likes
- **Default**: 0
- **Update**: When user likes collection (future)

#### dislikes
- **Type**: Number
- **Description**: Number of dislikes
- **Default**: 0
- **Update**: When user dislikes collection (future)

#### comments
- **Type**: Number
- **Description**: Number of comments
- **Default**: 0
- **Update**: When user posts comment (future)

#### ratings
- **Type**: Object
- **Fields**:
  - `average` (Number): Average rating (0.0-5.0)
  - `count` (Number): Number of ratings
- **Description**: User ratings (star ratings)
- **Computation**: `average = sum(ratings) / count`
- **Update**: When user submits rating (future)

#### downloads
- **Type**: Number
- **Description**: Number of downloads/accesses
- **Default**: 0
- **Update**: When collection is downloaded (future)

#### last_computed
- **Type**: String (ISO 8601)
- **Description**: When statistics were last calculated
- **Update**: When statistics are recomputed

### 3. Views (Engagement)

Defined in `views` object:

#### total
- **Type**: Number
- **Description**: Total view count
- **Counting**: Increment each time collection is opened
- **Note**: Includes repeat views from same user

#### unique
- **Type**: Number
- **Description**: Unique viewer count
- **Counting**: Count distinct users (by npub) who viewed
- **Note**: Requires user tracking (privacy consideration)

#### tags
- **Type**: Array
- **Description**: View tracking tags (future feature)
- **Example**: `["mobile", "desktop", "web"]`

### 4. Tags (Categorization)

Defined in `tags` array:

- **Type**: Array of Strings
- **Description**: Categorization and search tags
- **Guidelines**:
  - Use lowercase
  - Use hyphens for multi-word tags
  - Be specific but not overly granular
  - Include relevant technology names
  - Include content type tags
  - Limit to 5-10 tags
- **Examples**:
```json
[
  "documentation",
  "linux",
  "kernel",
  "programming",
  "c-language",
  "open-source"
]
```

**Common Tag Categories**:

**Content Type**:
- `documentation`, `tutorial`, `reference`, `guide`
- `media`, `audio`, `video`, `images`, `photos`
- `software`, `tools`, `utilities`, `libraries`
- `data`, `dataset`, `research`, `academic`
- `books`, `ebooks`, `articles`, `papers`

**Technology**:
- `linux`, `windows`, `macos`, `android`, `ios`
- `javascript`, `python`, `java`, `c`, `rust`
- `web`, `mobile`, `desktop`, `embedded`

**Topic**:
- `programming`, `design`, `art`, `music`, `science`
- `history`, `geography`, `education`, `entertainment`

**License/Access**:
- `open-source`, `creative-commons`, `public-domain`
- `free`, `paid`, `subscription`

### 5. Extended Metadata

Defined in `metadata` object:

#### category
- **Type**: String (enum)
- **Required**: No
- **Default**: `"general"`
- **Values**:
  - `general`: General purpose
  - `media`: Audio, video, images
  - `documents`: Documents, PDFs, text
  - `software`: Software packages, apps
  - `data`: Datasets, research data
  - `education`: Educational materials
  - `entertainment`: Games, entertainment
  - `archive`: Historical archives
- **Description**: Primary category for collection
- **Guidelines**: Choose the most specific category

#### language
- **Type**: String (ISO 639-1)
- **Required**: No
- **Default**: `"en"`
- **Description**: Primary language of content
- **Format**: Two-letter language code
- **Examples**: `"en"` (English), `"es"` (Spanish), `"zh"` (Chinese)
- **Multi-language**: Use `"mul"` for multiple languages

#### license
- **Type**: String
- **Required**: No
- **Description**: License for collection content
- **Format**: SPDX license identifier (preferred) or custom text
- **Examples**:
  - `"MIT"`
  - `"GPL-3.0"`
  - `"CC-BY-4.0"`
  - `"CC-BY-SA-4.0"`
  - `"CC0-1.0"` (public domain)
  - `"Apache-2.0"`
  - `"Custom license - see LICENSE.txt"`
- **Guidelines**:
  - Use SPDX identifiers when possible
  - Be specific about version (e.g., GPL-3.0, not just GPL)
  - Reference license file if custom

#### copyright
- **Type**: String
- **Required**: No
- **Max Length**: 500 characters
- **Description**: Copyright notice
- **Format**: Free text
- **Examples**:
  - `"Copyright (c) 2025 John Doe"`
  - `"Copyright (c) 2020-2025 Acme Corporation"`
  - `"Public domain - no copyright"`
- **Guidelines**:
  - Include year(s)
  - Include copyright holder name
  - Use standard copyright symbol or (c)

#### website
- **Type**: String (URL)
- **Required**: No
- **Description**: Related website URL
- **Format**: Valid HTTP/HTTPS URL
- **Examples**:
  - `"https://example.com"`
  - `"https://github.com/user/repo"`
- **Guidelines**:
  - Use HTTPS when available
  - Link to official/authoritative source
  - Can be project homepage, repo, or related site

#### contact
- **Type**: Object
- **Required**: No
- **Fields**:
  - `email` (String): Contact email address
  - `nostr` (String): Contact Nostr npub
- **Description**: Contact information for collection owner
- **Examples**:
```json
{
  "email": "author@example.com",
  "nostr": "npub1xyz..."
}
```
- **Guidelines**:
  - Provide at least one contact method
  - Nostr npub preferred for decentralization
  - Email for broader compatibility

#### donation_address
- **Type**: String
- **Required**: No
- **Description**: Bitcoin/Lightning address for donations
- **Format**: Bitcoin address or Lightning address
- **Examples**:
  - `"bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"`
  - `"lnbc1..."`
  - `"user@getalby.com"` (Lightning address)
- **Guidelines**:
  - Use SegWit (bc1) addresses for Bitcoin
  - Lightning addresses preferred for micropayments

#### attribution
- **Type**: String
- **Required**: No
- **Max Length**: 500 characters
- **Description**: Attribution text for content
- **Format**: Free text
- **Examples**:
  - `"Created by John Doe"`
  - `"Based on work by Jane Smith (CC-BY-4.0)"`
  - `"Photos by Unsplash contributors"`
- **Guidelines**:
  - Credit all significant contributors
  - Reference source if derived work
  - Include license of original if applicable

#### content_rating
- **Type**: String (enum)
- **Required**: No
- **Default**: `"G"`
- **Values**:
  - `G`: General audiences (all ages)
  - `PG`: Parental guidance suggested
  - `PG-13`: Parents strongly cautioned
  - `R`: Restricted (17+)
  - `NC-17`: Adults only (18+)
- **Description**: Content maturity rating (MPAA-style)
- **Guidelines**:
  - Rate conservatively when in doubt
  - Consider violence, language, sexual content, etc.
  - Supplement with content_warnings for specifics

#### mature_content
- **Type**: Boolean
- **Required**: No
- **Default**: `false`
- **Description**: Flag for mature/adult content
- **Guidelines**:
  - Set to `true` for adult content
  - Use with `content_rating` of R or NC-17
  - Combine with age_restriction in security.json

## Best Practices

### Metadata Quality

**Complete Metadata**:
- Fill in all relevant fields
- Don't leave descriptions empty
- Provide contact information
- Specify license clearly

**Accurate Metadata**:
- Title and description match content
- Tags are relevant and specific
- Statistics are up-to-date
- Timestamps are accurate

**Consistent Metadata**:
- Use standard formats (ISO 8601, SPDX, etc.)
- Follow naming conventions
- Use established tag vocabularies
- Maintain consistent style

### Discoverability

**Optimize for Search**:
- Use descriptive titles with keywords
- Write detailed descriptions
- Add relevant tags
- Include technology names

**Cross-Reference**:
- Link to related collections (future)
- Reference source materials
- Provide website URL
- Include contact information

### Legal Compliance

**Copyright**:
- Specify license clearly
- Credit original authors
- Don't claim others' work
- Respect license terms

**Privacy**:
- Don't include personal information without consent
- Be mindful of GDPR/privacy laws
- Allow opt-out for statistics
- Anonymize user data

**Content Regulations**:
- Set appropriate content_rating
- Use content_warnings
- Enable age_restriction if needed
- Comply with local laws

### Accessibility

**Internationalization**:
- Specify primary language
- Provide translations (future)
- Use universal formats
- Avoid region-specific references

**Clear Communication**:
- Write descriptions in plain language
- Avoid jargon when possible
- Define technical terms
- Use examples

## Metadata Updates

### When to Update

**Always Update**:
- Adding/removing files
- Changing collection structure
- Modifying security settings
- Changing title or description

**Optional Update**:
- Correcting typos
- Adding tags
- Updating contact info
- Refreshing statistics

**Never Update**:
- `created` timestamp
- `id` (npub)
- Historical statistics

### How to Update

**Manual Update**:
1. Edit `collection.js` with text editor
2. Update `updated` timestamp
3. Rescan collection in app
4. Verify changes

**Programmatic Update**:
```java
Collection collection = loadCollection(npub);
collection.setTitle("New Title");
collection.setUpdated(System.currentTimeMillis());
saveCollection(collection);
```

**Batch Update**:
- Update multiple fields together
- Regenerate tree-data.js if needed
- Sign metadata after changes (future)

## Validation

### Required Fields

Validate that all required fields are present:
- `version`
- `collection.id`
- `collection.title`
- `collection.description` (can be empty)
- `collection.created`
- `collection.updated`

### Format Validation

Check field formats:
- npub: Bech32, 63 chars, starts with "npub1"
- Timestamps: ISO 8601 format
- URLs: Valid HTTP/HTTPS
- Email: Valid email format
- License: Valid SPDX identifier (recommended)

### Consistency Checks

Verify internal consistency:
- `updated` >= `created`
- `statistics.files_count` matches actual file count
- `statistics.total_size` matches sum of file sizes
- Tags are lowercase and valid

### Schema Validation

Use JSON Schema for validation:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["version", "collection", "statistics", "views", "tags", "metadata"],
  ...
}
```

See [schemas/collection-schema.json](schemas/collection-schema.json) for full schema.

## Future Enhancements

### Planned Metadata Features

1. **Versioning**: Track collection version history
2. **Translations**: Multi-language metadata
3. **Rich Media**: Thumbnail images, preview videos
4. **Relationships**: Links to related collections
5. **Provenance**: Chain of custody tracking
6. **Quality Metrics**: Community-driven quality scores
7. **Search Metadata**: Optimized for search engines
8. **Semantic Metadata**: RDF/linked data support

### Metadata Extensions

Allow custom metadata namespaces:
```json
{
  "metadata": {
    "category": "software",
    "extensions": {
      "com.example": {
        "custom_field": "value"
      }
    }
  }
}
```

## Related Documentation

- [File Formats](file-formats.md) - Metadata file formats
- [Architecture](architecture.md) - How metadata is used
- [User Guide](user-guide.md) - Setting metadata in UI
- [Examples](examples/) - Example metadata files
- [Schemas](schemas/) - JSON schemas for validation
