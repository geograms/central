# Places Format Specification

**Version**: 1.0
**Last Updated**: 2025-11-21
**Status**: Active

## Table of Contents

- [Overview](#overview)
- [File Organization](#file-organization)
- [Coordinate-Based Organization](#coordinate-based-organization)
- [Place Format](#place-format)
- [Location Radius](#location-radius)
- [Photos and Media](#photos-and-media)
- [Contributor Organization](#contributor-organization)
- [Reactions System](#reactions-system)
- [Comments](#comments)
- [Subfolder Organization](#subfolder-organization)
- [File Management](#file-management)
- [Permissions and Roles](#permissions-and-roles)
- [Moderation System](#moderation-system)
- [NOSTR Integration](#nostr-integration)
- [Complete Examples](#complete-examples)
- [Parsing Implementation](#parsing-implementation)
- [File Operations](#file-operations)
- [Validation Rules](#validation-rules)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)
- [Related Documentation](#related-documentation)
- [Change Log](#change-log)

## Overview

This document specifies the text-based format used for storing places information in the Geogram system. The places collection type provides a platform for documenting locations around the globe with photos, descriptions, and community engagement through likes and comments.

Places combine geographic organization with features similar to events, but focused on permanent or semi-permanent locations rather than time-based activities.

### Key Features

- **Coordinate-Based Organization**: Places organized by geographic regions
- **Compact Naming**: Simple region format `38.7_-9.1/` for efficiency
- **Grid System**: Globe divided into ~30,000 regions for efficient organization
- **Dense Region Support**: Automatic numbered subfolders (001/, 002/) when region exceeds 10,000 places
- **Unlimited Scalability**: Virtually unlimited capacity in dense urban areas
- **Precise Location**: Each place has specific coordinates with configurable radius
- **Radius Range**: 10 meters to 1 kilometer coverage area
- **Unlimited Media**: Any number of photos, videos, and files
- **Photo Reactions**: Individual likes and comments on each photo
- **Place Reactions**: Likes and comments on the place itself
- **Contributor System**: Users can submit photos with attribution
- **Admin Moderation**: Admins can approve/reject/move contributor content
- **Subfolder Structure**: Optional subfolders for organizing content
- **Simple Text Format**: Plain text descriptions (no markdown)
- **NOSTR Integration**: Cryptographic signatures for authenticity

## File Organization

### Directory Structure

```
collection_name/
└── places/
    ├── 38.7_-9.1/                      # Region folder (1° precision)
    │   ├── 38.7223_-9.1393_cafe-landmark/
    │   │   ├── place.txt
    │   │   ├── photo1.jpg
    │   │   ├── photo2.jpg
    │   │   ├── exterior/
    │   │   │   ├── subfolder.txt
    │   │   │   ├── front-view.jpg
    │   │   │   └── side-view.jpg
    │   │   ├── contributors/
    │   │   │   ├── CR7BBQ/
    │   │   │   │   ├── contributor.txt
    │   │   │   │   ├── sunset-photo.jpg
    │   │   │   │   └── night-view.jpg
    │   │   │   └── X135AS/
    │   │   │       ├── contributor.txt
    │   │   │       └── drone-view.jpg
    │   │   └── .reactions/
    │   │       ├── place.txt
    │   │       ├── photo1.jpg.txt
    │   │       ├── photo2.jpg.txt
    │   │       ├── exterior.txt
    │   │       └── contributors/CR7BBQ.txt
    │   └── 38.7169_-9.1399_famous-tower/
    │       ├── place.txt
    │       ├── main-view.jpg
    │       └── .reactions/
    │           └── place.txt
    ├── 40.7_-74.0/                     # Another region
    │   └── 40.7128_-74.0060_central-park/
    │       ├── place.txt
    │       └── park-entrance.jpg
    └── 35.6_139.6/                     # Dense region example (Tokyo)
        ├── 001/                        # First 10,000 places
        │   ├── 35.6762_139.6503_tokyo-tower/
        │   │   └── place.txt
        │   └── 35.6895_139.6917_imperial-palace/
        │       └── place.txt
        └── 002/                        # Next 10,000 places
            └── 35.6812_139.7671_tokyo-skytree/
                └── place.txt
```

### Region Folder Naming

**Pattern**: `{LAT}_{LON}/`

**Coordinate Rounding**:
- Round latitude to 1 decimal place (e.g., 38.7223 → 38.7)
- Round longitude to 1 decimal place (e.g., -9.1393 → -9.1)
- This creates ~30,000 possible regions globally
- Each region covers approximately 130 km × 130 km at the equator

**Examples**:
```
38.7_-9.1/          # Lisbon area, Portugal
40.7_-74.0/         # New York City area, USA
51.5_-0.1/          # London area, UK
-33.8_151.2/        # Sydney area, Australia
35.6_139.6/         # Tokyo area, Japan
```

**Region Characteristics**:
- Approximately 1.04° latitude coverage
- Approximately 2.08° longitude coverage (at equator)
- Total regions: ~30,000 worldwide
- Each region size: ~130 km × 130 km (~17,000 km²)
- Automatic creation when first place added to region

### Dense Region Organization

For regions with many places (e.g., dense urban areas), the system uses numbered subfolders to maintain performance:

**Threshold**: 10,000 places per folder

**Structure**:
```
35.6_139.6/                 # Tokyo region (dense)
├── 001/                    # Places 1-10,000
│   ├── place1/
│   ├── place2/
│   └── ...
├── 002/                    # Places 10,001-20,000
│   ├── place10001/
│   └── ...
└── 003/                    # Places 20,001-30,000
    └── ...
```

**Subfolder Naming**:
- Format: `001/`, `002/`, `003/`, etc.
- Three-digit zero-padded numbers
- Sequential ordering
- Created automatically when threshold reached

**Migration Process**:
```
1. Region has < 10,000 places: Places directly in region folder
   38.7_-9.1/
   ├── place1/
   └── place2/

2. Region reaches 10,000 places: Create 001/ subfolder
   38.7_-9.1/
   └── 001/
       ├── place1/       # Moved from parent
       ├── place2/       # Moved from parent
       └── ...           # All 10,000 places

3. Region reaches 10,001+ places: Create 002/ subfolder
   38.7_-9.1/
   ├── 001/              # First 10,000 places
   └── 002/              # New places go here
       └── place10001/
```

**Benefits**:
- Simple structure for sparse regions (no subfolders needed)
- Scales to handle dense urban areas (millions of places possible)
- Maintains filesystem performance (max 10,000 items per folder)
- Predictable and algorithm-based organization

**Maximum Capacity**:
- Without subfolders: 10,000 places per region
- With subfolders: Virtually unlimited (999 × 10,000 = ~10 million places per region)
- Global theoretical maximum: ~30,000 regions × 10 million = 300 billion places

### Place Folder Naming

**Pattern**: `{LAT}_{LON}_{sanitized-name}/`

**Full Precision Coordinates**:
- Use full precision (6 decimal places recommended)
- Latitude: -90.0 to +90.0
- Longitude: -180.0 to +180.0

**Sanitization Rules**:
1. Convert name to lowercase
2. Replace spaces and underscores with single hyphens
3. Remove all non-alphanumeric characters (except hyphens)
4. Collapse multiple consecutive hyphens
5. Remove leading/trailing hyphens
6. Truncate to 50 characters
7. Prepend full coordinates

**Examples**:
```
Name: "Historic Café Landmark"
Coordinates: 38.7223, -9.1393
→ 38.7223_-9.1393_historic-cafe-landmark/

Name: "Central Park @ New York City"
Coordinates: 40.7128, -74.0060
→ 40.7128_-74.0060_central-park-new-york-city/

Name: "Tower Bridge"
Coordinates: 51.5055, -0.0754
→ 51.5055_-0.0754_tower-bridge/
```

### Special Directories

**`.reactions/` Directory**:
- Hidden directory (starts with dot)
- Contains reaction files for place and items
- One file per item that has likes/comments
- Filename matches target item with `.txt` suffix

**`.hidden/` Directory** (see Moderation System):
- Hidden directory for moderated content
- Contains files/comments hidden by moderators
- Not visible in standard UI

## Coordinate-Based Organization

### Grid System Overview

The places collection uses a two-level coordinate-based organization:

1. **Region Level**: Rounded coordinates (1 decimal place)
   - Purpose: Group nearby places into manageable folders
   - Limit: ~30,000 regions globally
   - Size: ~130 km × 130 km per region

2. **Place Level**: Full precision coordinates (6 decimals)
   - Purpose: Exact location identification
   - Precision: ~0.1 meters (at equator)
   - Unique: Each place has unique coordinates

### Coordinate Precision

**Region Coordinates** (1 decimal place):
```
Latitude:  38.7  (rounded from 38.7223)
Longitude: -9.1  (rounded from -9.1393)
Range: ±0.05° from center
Coverage: ~11 km × ~11 km (at mid-latitudes)
```

**Place Coordinates** (6 decimal places):
```
Latitude:  38.7223  (precise)
Longitude: -9.1393  (precise)
Precision: ~0.1 meters
```

### Finding a Place's Region

```
Given coordinates: 38.7223, -9.1393

1. Round latitude to 1 decimal: 38.7223 → 38.7
2. Round longitude to 1 decimal: -9.1393 → -9.1
3. Format region folder: 38.7_-9.1/
4. Check place count in region:
   - If < 10,000: Place folder goes directly in region folder
   - If ≥ 10,000: Place folder goes in appropriate numbered subfolder
5. Place created in: 38.7_-9.1/38.7223_-9.1393_cafe-landmark/
   or: 38.7_-9.1/001/38.7223_-9.1393_cafe-landmark/
```

### Region Distribution

**Global Coverage**:
- Latitude divisions: 180° / 1.04° ≈ 173 regions
- Longitude divisions: 360° / 2.08° ≈ 173 regions
- Total regions: 173 × 173 ≈ 30,000

**Region Examples by Continent**:
- Europe: ~1,500 regions
- Asia: ~9,000 regions
- Africa: ~6,000 regions
- North America: ~5,000 regions
- South America: ~3,500 regions
- Oceania: ~2,000 regions
- Antarctica: ~3,000 regions (mostly unpopulated)

### Benefits of Coordinate Organization

1. **Scalability**: Fixed number of regions (30,000 max)
2. **Geographic Clustering**: Nearby places grouped together
3. **Efficient Searching**: Navigate by coordinates directly
4. **No Hierarchy**: Flat structure within each region
5. **Global Coverage**: Works for any location on Earth
6. **Predictable**: Algorithm-based, no manual categorization

## Place Format

### Main Place File

Every place must have a `place.txt` file in the place folder root.

**Complete Structure**:
```
# PLACE: Place Name

CREATED: YYYY-MM-DD HH:MM_ss
AUTHOR: CALLSIGN
COORDINATES: lat,lon
RADIUS: meters
ADDRESS: Full Address (optional)
TYPE: category (optional)
ADMINS: npub1abc123..., npub1xyz789... (optional)
MODERATORS: npub1delta..., npub1echo... (optional)

Place description goes here.
Simple plain text format.
No markdown formatting.

Can include multiple paragraphs.
Each paragraph separated by blank line.

--> npub: npub1...
--> signature: hex_signature
```

### Header Section

1. **Title Line** (required)
   - **Format**: `# PLACE: <name>`
   - **Example**: `# PLACE: Historic Café Landmark`
   - **Constraints**: Any length, but truncated in folder name

2. **Blank Line** (required)
   - Separates title from metadata

3. **Created Timestamp** (required)
   - **Format**: `CREATED: YYYY-MM-DD HH:MM_ss`
   - **Example**: `CREATED: 2025-11-21 10:00_00`
   - **Note**: Underscore before seconds

4. **Author Line** (required)
   - **Format**: `AUTHOR: <callsign>`
   - **Example**: `AUTHOR: CR7BBQ`
   - **Constraints**: Alphanumeric callsign
   - **Note**: Author is automatically an admin

5. **Coordinates** (required)
   - **Format**: `COORDINATES: <lat>,<lon>`
   - **Example**: `COORDINATES: 38.7223,-9.1393`
   - **Constraints**: Valid lat,lon coordinates
   - **Precision**: Up to 6 decimal places recommended

6. **Radius** (required)
   - **Format**: `RADIUS: <meters>`
   - **Example**: `RADIUS: 50`
   - **Constraints**: 10 to 1000 meters
   - **Purpose**: Defines the area covered by this place

7. **Address** (optional)
   - **Format**: `ADDRESS: <full address>`
   - **Example**: `ADDRESS: 123 Main Street, Lisbon, Portugal`
   - **Purpose**: Human-readable location description

8. **Type** (optional)
   - **Format**: `TYPE: <category>`
   - **Examples**: `TYPE: restaurant`, `TYPE: monument`, `TYPE: park`
   - **Purpose**: Categorize place for filtering/searching

9. **Admins** (optional)
   - **Format**: `ADMINS: <npub1>, <npub2>, ...`
   - **Example**: `ADMINS: npub1abc123..., npub1xyz789...`
   - **Purpose**: Additional administrators for place
   - **Note**: Author is always admin, even if not listed

10. **Moderators** (optional)
    - **Format**: `MODERATORS: <npub1>, <npub2>, ...`
    - **Example**: `MODERATORS: npub1delta..., npub1echo...`
    - **Purpose**: Users who can moderate content

11. **Blank Line** (required)
    - Separates header from content

### Content Section

The content section contains the place description.

**Characteristics**:
- **Plain text only** (no markdown)
- Multiple paragraphs allowed
- Blank lines separate paragraphs
- Whitespace preserved
- No length limit (reasonable sizes recommended)

**Example**:
```
Historic café located in the heart of Lisbon.

Established in 1782, this café has served famous writers,
artists, and politicians throughout Portuguese history.

Notable features:
- Original Art Nouveau interior
- Hand-painted azulejo tiles
- Historic pastry recipes
- Outdoor terrace with city views

Open daily from 8 AM to midnight.
```

### Place Metadata

Metadata appears after content:

```
--> npub: npub1abc123...
--> signature: hex_signature_string...
```

- **npub**: NOSTR public key (optional)
- **signature**: NOSTR signature, must be last if present

## Location Radius

### Radius Purpose

The radius defines the geographic coverage area of the place:
- **Small radius** (10-50m): Specific building, monument, or feature
- **Medium radius** (50-250m): Complex of buildings, park area
- **Large radius** (250-1000m): Large park, campus, neighborhood feature

### Radius Constraints

**Minimum**: 10 meters
- Small features like statues, fountains
- Single buildings
- Specific landmarks

**Maximum**: 1000 meters (1 kilometer)
- Large parks
- Campus areas
- Neighborhood districts
- Mountain peaks with hiking areas

**Format**: Integer value in meters
```
RADIUS: 10      # Minimum
RADIUS: 50      # Small
RADIUS: 200     # Medium
RADIUS: 500     # Large
RADIUS: 1000    # Maximum
```

### Radius Use Cases

**10-50 meters**:
- Restaurants and cafes
- Shops and stores
- Monuments and statues
- Historic buildings
- Fountains
- Street art

**50-250 meters**:
- Small parks
- Shopping complexes
- Museum complexes
- University buildings
- Plazas and squares

**250-1000 meters**:
- Large parks
- Campuses
- Beaches
- Lakes
- Mountain summits
- Historic districts
- Natural features

### Radius Display

**UI Considerations**:
- Display circle on map with specified radius
- Show coverage area visually
- Help users understand geographic extent
- Use for proximity searches ("places near me")
- Filter overlapping places

## Photos and Media

### Photo Organization

Photos can be stored:
1. Directly in place folder (main photos)
2. In subfolders (organized by category)
3. In contributor folders (user submissions)

**Example**:
```
38.7223_-9.1393_cafe-landmark/
├── place.txt
├── main-entrance.jpg       # Main photos
├── interior.jpg
├── menu-board.jpg
├── exterior/               # Organized subfolder
│   ├── subfolder.txt
│   ├── front-view.jpg
│   ├── side-view.jpg
│   └── rooftop-view.jpg
└── contributors/           # User submissions
    └── CR7BBQ/
        ├── contributor.txt
        ├── sunset-photo.jpg
        └── night-view.jpg
```

### Supported Media Types

**Images**:
- JPG, JPEG, PNG, GIF, WebP, BMP
- Recommended: JPG for photos, PNG for graphics
- Any resolution (high resolution recommended)

**Videos**:
- MP4, AVI, MOV, WebM
- Recommended: MP4 for compatibility
- Short clips preferred (under 2 minutes)

**Documents**:
- PDF, TXT, MD
- Information brochures, maps, guides

### Individual Photo Reactions

Each photo can have its own likes and comments:

**Reaction File**: `.reactions/photo-name.jpg.txt`

**Format**:
```
LIKES: CR7BBQ, X135AS, BRAVO2

> 2025-11-21 14:00_00 -- CR7BBQ
Beautiful composition! Love the lighting.
--> npub: npub1abc...
--> signature: hex_sig

> 2025-11-21 15:30_00 -- X135AS
This angle really captures the architecture.
```

### Photo Metadata (Optional)

Photos can have associated metadata files:

**File**: `photo-name.jpg.txt` (in same directory)

```
PHOTOGRAPHER: CR7BBQ
TAKEN: 2025-11-21
CAMERA: Sony A7IV
SETTINGS: f/2.8, 1/250s, ISO 400
DESCRIPTION: View from the main entrance during golden hour
```

## Contributor Organization

### Overview

Places can have multiple contributors who share photos and information. Each contributor gets their own subfolder identified by their callsign, allowing clear attribution and organization of contributed content.

### Contributor Folder Structure

```
places/
└── lat_38.7_lon_-9.1/
    └── 38.7223_-9.1393_cafe-landmark/
        ├── place.txt
        ├── main-photo.jpg
        └── contributors/
            ├── CR7BBQ/
            │   ├── contributor.txt
            │   ├── interior-photo1.jpg
            │   ├── interior-photo2.jpg
            │   └── detail-shots/
            │       └── tile-detail.jpg
            ├── X135AS/
            │   ├── contributor.txt
            │   ├── aerial-view.jpg
            │   └── drone-video.mp4
            └── BRAVO2/
                └── night-photos/
                    ├── facade-lit.jpg
                    └── street-view.jpg
```

### Contributor Folder Location

**Base Path**: `contributors/CALLSIGN/`

**Characteristics**:
- All contributor folders under `contributors/` subdirectory
- Folder name matches contributor's callsign exactly
- Case-sensitive (CALLSIGN must match)
- One folder per contributor

### Contributor Metadata File

**Filename**: `contributor.txt` (inside contributor folder)

**Format**:
```
# CONTRIBUTOR: CR7BBQ

CREATED: 2025-11-21 14:00_00

My photos from multiple visits to this historic café.

Captured the interior details and the famous azulejo tiles.
Used Sony A7IV with 24-70mm lens.

--> npub: npub1abc123...
--> signature: hex_sig...
```

**Header**:
1. `# CONTRIBUTOR: <callsign>`
2. Blank line
3. `CREATED: YYYY-MM-DD HH:MM_ss`
4. Blank line
5. Description (optional, plain text)
6. Metadata (npub, signature)

**Purpose**:
- Describe contributor's submissions
- Add context (equipment, technique, visits, etc.)
- Optional - contributor folder can exist without it

### Admin Review Process

Contributors submit photos, but admins control final placement:

**Workflow**:
```
1. Contributor uploads photos to contributors/CALLSIGN/
2. Photos remain in contributor folder (visible but marked as "pending")
3. Admin reviews submitted photos
4. Admin has three options:
   a. Approve: Copy photo to main place folder or subfolder
   b. Reject: Delete photo from contributor folder
   c. Keep: Leave in contributor folder as community contribution
5. Original attribution preserved in photo metadata
```

**Admin Actions**:
- **Copy to main**: Photo becomes featured content (attribution preserved)
- **Copy to subfolder**: Organized into appropriate category
- **Keep in contributor folder**: Remains as community content
- **Delete**: Remove low-quality or inappropriate content

### Contributor Permissions

**Contributor Folder Owner**:
- Add/edit/delete files in their own folder
- Edit contributor.txt
- Cannot modify other contributors' folders
- Cannot modify main place content

**Place Admins**:
- Full access to all contributor folders
- Can copy/move photos to main place area
- Can delete inappropriate content
- Attribution to original photographer preserved

**Moderators**:
- Can hide files in contributor folders
- Cannot delete files permanently
- Cannot move files to main area

### Contributor Reactions

Reactions on contributor folders use the pattern:

**Reaction File**: `.reactions/contributors/CALLSIGN.txt`

**Example**:
```
LIKES: X135AS, BRAVO2, ALPHA1

> 2025-11-21 18:00_00 -- X135AS
Excellent photo series! Great eye for detail.
--> npub: npub1xyz...
--> signature: hex_sig

> 2025-11-21 20:00_00 -- BRAVO2
These interior shots are amazing!
```

## Reactions System

### Overview

The reactions system enables granular engagement with places and their content. Users can:
- Like the place itself
- Like individual photos/videos/files
- Like subfolders
- Like contributor folders
- Comment on any of the above

### Reactions Directory

**Location**: `<place-folder>/.reactions/`

**Purpose**: Stores all likes and comments for place and items

**Filename Pattern**: `<target-item>.txt`

**Examples**:
- Place reactions: `.reactions/place.txt`
- Photo reactions: `.reactions/photo1.jpg.txt`
- Subfolder reactions: `.reactions/exterior.txt`
- Contributor reactions: `.reactions/contributors/CR7BBQ.txt`

### Reaction File Format

```
LIKES: CALLSIGN1, CALLSIGN2, CALLSIGN3

> YYYY-MM-DD HH:MM_ss -- COMMENTER
Comment text here.
--> npub: npub1...
--> signature: hex_sig

> YYYY-MM-DD HH:MM_ss -- ANOTHER_USER
Another comment.
```

### Likes Section

**Format**: `LIKES: <callsign1>, <callsign2>, <callsign3>`

**Characteristics**:
- Comma-separated list of callsigns
- Each callsign can appear only once
- Order can be chronological or alphabetical
- Empty if no likes: `LIKES:` (with no callsigns)
- Optional: line can be omitted if no likes

**Example**:
```
LIKES: CR7BBQ, X135AS, BRAVO2, ALPHA1
```

### Comments Section

Comments follow the likes line and use the same format as other collection types:

```
> YYYY-MM-DD HH:MM_ss -- CALLSIGN
Comment content.
--> npub: npub1...
--> signature: hex_sig
```

### Reaction Targets

**Place Reactions** (`.reactions/place.txt`):
- Likes and comments on the place itself
- Most common reaction target

**Photo Reactions** (`.reactions/<filename>.txt`):
- Reactions specific to a photo or video
- Filename must match exactly (case-sensitive)
- Examples:
  - Photo: `.reactions/sunset.jpg.txt`
  - Video: `.reactions/tour.mp4.txt`

**Subfolder Reactions** (`.reactions/<subfolder-name>.txt`):
- Reactions on a subfolder as a whole
- Filename matches subfolder name
- Example: `.reactions/exterior.txt` for `exterior/` subfolder

**Contributor Reactions** (`.reactions/contributors/<callsign>.txt`):
- Reactions on contributor's folder
- Example: `.reactions/contributors/CR7BBQ.txt`

## Comments

### Comment Format

```
> YYYY-MM-DD HH:MM_ss -- CALLSIGN
Comment content here.
Can span multiple lines.
--> npub: npub1...
--> signature: hex_signature
```

### Comment Structure

1. **Header Line** (required)
   - **Format**: `> YYYY-MM-DD HH:MM_ss -- CALLSIGN`
   - **Example**: `> 2025-11-21 14:30_45 -- X135AS`
   - Starts with `>` followed by space

2. **Content** (required)
   - Plain text, multiple lines allowed
   - No formatting

3. **Metadata** (optional)
   - npub and signature only
   - Signature must be last if present

### Comment Locations

Comments are stored in reaction files:
- **Place comments**: `.reactions/place.txt`
- **Photo comments**: `.reactions/photo.jpg.txt`
- **Subfolder comments**: `.reactions/subfolder-name.txt`
- **Contributor comments**: `.reactions/contributors/CALLSIGN.txt`

### Comment Characteristics

- **Flat structure**: No nested replies
- **Chronological order**: Sorted by timestamp
- **Multiple targets**: Can comment on different items
- **Persistent**: Comments remain with item

## Subfolder Organization

### Subfolder Purpose

Subfolders organize related content within a place:
- Group photos by category (e.g., "exterior", "interior", "details")
- Separate different aspects (e.g., "day-photos", "night-photos")
- Organize by season (e.g., "spring", "summer", "autumn", "winter")
- Separate media types (e.g., "videos", "documents", "maps")

### Subfolder Structure

Each subfolder can contain:
- Media files (photos, videos)
- Documents (PDFs, text files)
- A `subfolder.txt` file describing the subfolder
- Nested subfolders (one level recommended)

### Subfolder Metadata File

**Filename**: `subfolder.txt`

**Format**:
```
# SUBFOLDER: Subfolder Title

CREATED: YYYY-MM-DD HH:MM_ss
AUTHOR: CALLSIGN

Description of this subfolder's contents.

Can include multiple paragraphs explaining
what's organized here.

--> npub: npub1...
--> signature: hex_sig...
```

**Characteristics**:
- Optional (subfolder can exist without metadata file)
- Allows description and attribution
- Can have reactions (likes/comments) via `.reactions/`
- Follows same format as place file but with `# SUBFOLDER:` header

## File Management

### Supported File Types

**Images**:
- JPG, JPEG, PNG, GIF, WebP, BMP, SVG
- Any size (reasonable limits recommended)

**Videos**:
- MP4, AVI, MOV, MKV, WebM
- Recommended: MP4 for compatibility

**Documents**:
- PDF, TXT, MD, DOC, DOCX

**Other**:
- Any file type can be stored in place folder

### File Organization

Files are stored directly in the place folder or subfolders:

```
38.7223_-9.1393_cafe-landmark/
├── place.txt
├── main-photo.jpg
├── menu.pdf
├── interior/
│   ├── subfolder.txt
│   ├── seating-area.jpg
│   ├── bar.jpg
│   └── ceiling-detail.jpg
└── exterior/
    ├── subfolder.txt
    ├── facade.jpg
    └── terrace.jpg
```

### File Naming

**Convention**: Original filenames preserved

**Best Practices**:
- Use descriptive names (e.g., `front-entrance.jpg` not `IMG_1234.jpg`)
- Avoid special characters in filenames
- Use lowercase for consistency
- Include descriptive keywords in filename

**Example Names**:
```
Good:
- historic-facade-morning-light.jpg
- interior-art-nouveau-ceiling.jpg
- azulejo-tile-detail.jpg

Avoid:
- IMG_0001.jpg
- Photo (1).jpg
- DSC_20251121_143045.jpg
```

## Permissions and Roles

### Overview

Places support three distinct roles with different permission levels: Admins, Moderators, and Contributors. This system enables collaborative place documentation while maintaining content quality.

### Roles

#### Place Author

The user who created the place (AUTHOR field).

**Permissions**:
- All admin permissions (author is implicit admin)
- Cannot be removed from admin list
- Can transfer ownership to another admin

#### Admins

Additional administrators listed in ADMINS field.

**Permissions**:
- Edit place.txt (name, description, metadata)
- Add/remove admins and moderators
- Create/delete subfolders
- Add/delete any files
- Delete entire place
- Permanently delete comments and content
- Manage contributor folders:
  - Copy contributor photos to main area
  - Delete inappropriate contributor content
  - Move contributor photos to subfolders
- Override moderation decisions

**Adding Admins**:
```
ADMINS: npub1abc123..., npub1xyz789..., npub1bravo...
```

#### Moderators

Users with moderation privileges listed in MODERATORS field.

**Permissions**:
- Hide comments (move to .hidden/)
- Hide files (move to .hidden/)
- Cannot delete content permanently
- Cannot edit place.txt
- Cannot manage roles
- Can view hidden content
- Can restore hidden content

**Adding Moderators**:
```
MODERATORS: npub1delta..., npub1echo..., npub1foxtrot...
```

#### Contributors

All other users who can access the place.

**Permissions**:
- View place and all content
- Create contributor folder for themselves
- Add files to their contributor folder
- Like place, files, and subfolders
- Comment on place, files, and subfolders
- Delete their own comments
- Edit/delete files in their contributor folder

### Permission Checks

Before any operation, verify user permissions:

```
1. Identify user's role (author, admin, moderator, contributor)
2. Check if action is allowed for that role
3. For destructive actions, require confirmation
4. Log action for audit trail
5. Execute operation
```

## Moderation System

### Overview

The moderation system allows moderators and admins to hide inappropriate content without permanently deleting it. Hidden content is moved to a `.hidden/` directory and can be restored by admins if needed.

### Hidden Content Directory

**Location**: `<place-folder>/.hidden/`

**Purpose**: Store content hidden by moderators

**Structure**:
```
.hidden/
├── comments/
│   ├── place_comment_20251121_143000_SPAMMER.txt
│   └── photo1_comment_20251121_150000_TROLL.txt
├── files/
│   ├── inappropriate-image.jpg
│   └── spam-document.pdf
└── moderation-log.txt
```

### Hiding vs Deleting

**Hiding (Moderators and Admins)**:
- Moves content to `.hidden/`
- Content not visible in UI
- Can be restored by admins
- Logged in moderation-log.txt
- Original metadata preserved

**Deleting (Admins Only)**:
- Permanently removes content
- Cannot be restored
- More severe action
- Used for illegal or harmful content

### Moderation Log

**File**: `.hidden/moderation-log.txt`

**Format**:
```
> 2025-11-21 16:00_00 -- DELTA4 (moderator)
ACTION: hide_comment
TARGET: place.txt
AUTHOR: SPAMMER
REASON: Spam advertising
CONTENT_PREVIEW: Buy my product! Visit...

> 2025-11-21 17:30_00 -- ECHO5 (moderator)
ACTION: hide_file
TARGET: inappropriate-image.jpg
REASON: Inappropriate content

> 2025-11-22 09:00_00 -- CR7BBQ (admin)
ACTION: restore_comment
TARGET: place.txt
AUTHOR: LEGITIMATE_USER
REASON: False positive, comment was fine
```

## NOSTR Integration

### NOSTR Keys

**npub (Public Key)**:
- Bech32-encoded public key
- Format: `npub1` followed by encoded data
- Purpose: Author identification, verification

**nsec (Private Key)**:
- Never stored in files
- Used for signing
- Kept secure in user's keystore

### Signature Format

**Place Signature**:
```
--> npub: npub1qqqqqqqq...
--> signature: 0123456789abcdef...
```

**Comment Signature**:
```
> 2025-11-21 14:30_45 -- CR7BBQ
Great place!
--> npub: npub1abc123...
--> signature: fedcba987654...
```

### Signature Verification

1. Extract npub and signature from metadata
2. Reconstruct signable message content
3. Verify Schnorr signature
4. Display verification badge in UI if valid

## Complete Examples

### Example 1: Simple Place

```
# PLACE: Historic Tower

CREATED: 2025-11-21 10:00_00
AUTHOR: CR7BBQ
COORDINATES: 38.7169,-9.1399
RADIUS: 100
ADDRESS: Praça do Comércio, Lisbon, Portugal
TYPE: monument

Historic tower built in the 16th century.

Famous landmark in Lisbon, offering panoramic views
of the city and the Tagus River.

Open to visitors daily from 9 AM to 7 PM.
Admission fee required.

--> npub: npub1abc123...
--> signature: 0123456789abcdef...
```

### Example 2: Place with Photos and Reactions

```
Place folder: places/38.7_-9.1/38.7223_-9.1393_historic-cafe/

Files:
- place.txt
- main-entrance.jpg
- interior-view.jpg
- azulejo-tiles.jpg
- .reactions/
  - place.txt
  - main-entrance.jpg.txt
  - interior-view.jpg.txt

=== place.txt ===
# PLACE: Historic Café Landmark

CREATED: 2025-11-21 09:00_00
AUTHOR: X135AS
COORDINATES: 38.7223,-9.1393
RADIUS: 50
ADDRESS: Rua Garrett 120, Chiado, Lisbon
TYPE: restaurant

Historic café established in 1782.

Famous for its Art Nouveau interior and hand-painted
azulejo tiles. This café has been a meeting place for
Portuguese writers, artists, and intellectuals for
over two centuries.

Specialties include traditional Portuguese pastries
and the famous "bica" espresso.

--> npub: npub1xyz789...
--> signature: abcd1234efgh5678...

=== .reactions/place.txt ===
LIKES: CR7BBQ, BRAVO2, ALPHA1, DELTA4

> 2025-11-21 12:30_00 -- CR7BBQ
Amazing historic place! The interior is stunning.
--> npub: npub1abc123...
--> signature: 111222333...

> 2025-11-21 14:00_00 -- BRAVO2
The pastries here are incredible. Must visit!

=== .reactions/main-entrance.jpg.txt ===
LIKES: CR7BBQ, X135AS, ALPHA1

> 2025-11-21 13:00_00 -- ALPHA1
Perfect capture of the Art Nouveau facade!
--> npub: npub1alpha...
--> signature: aaa111bbb...
```

### Example 3: Place with Contributors

```
Place folder: places/40.7_-74.0/40.7128_-74.0060_central-park/

Structure:
- place.txt
- main-entrance.jpg
- lake-view.jpg
- contributors/
  - CR7BBQ/
    - contributor.txt
    - spring-blossoms.jpg
    - autumn-colors.jpg
  - X135AS/
    - contributor.txt
    - aerial-view.jpg
    - drone-video.mp4
- .reactions/
  - place.txt
  - contributors/CR7BBQ.txt
  - contributors/X135AS.txt

=== place.txt ===
# PLACE: Central Park

CREATED: 2025-11-21 08:00_00
AUTHOR: CR7BBQ
COORDINATES: 40.7128,-74.0060
RADIUS: 1000
ADDRESS: Central Park, New York, NY 10022
TYPE: park

Iconic urban park in Manhattan, New York City.

Spanning 843 acres, Central Park is one of the most
visited urban parks in the United States. Features
include lakes, theaters, playgrounds, and meadows.

The park is a National Historic Landmark and offers
year-round activities for visitors.

--> npub: npub1abc123...
--> signature: aaa111bbb222...

=== contributors/CR7BBQ/contributor.txt ===
# CONTRIBUTOR: CR7BBQ

CREATED: 2025-11-21 12:00_00

Photos from my seasonal visits to Central Park.

Captured the beauty of spring blossoms and autumn foliage.
Canon EOS R5 with 24-105mm lens.

--> npub: npub1abc123...
--> signature: ccc333ddd444...

=== .reactions/place.txt ===
LIKES: X135AS, BRAVO2, ALPHA1, DELTA4, ECHO5

> 2025-11-21 15:00_00 -- X135AS
Love this place! Best park in NYC.
--> npub: npub1xyz789...
--> signature: eee555fff666...

> 2025-11-21 16:30_00 -- BRAVO2
Great for jogging and picnics!

=== .reactions/contributors/CR7BBQ.txt ===
LIKES: X135AS, BRAVO2

> 2025-11-21 18:00_00 -- X135AS
Beautiful seasonal photography! Love the composition.
--> npub: npub1xyz...
--> signature: ggg777hhh888...
```

### Example 4: Place with Subfolders

```
Place folder: places/51.5_-0.0/51.5055_-0.0754_tower-bridge/

Structure:
- place.txt
- overview.jpg
- exterior/
  - subfolder.txt
  - north-tower.jpg
  - south-tower.jpg
  - suspension-cables.jpg
- interior/
  - subfolder.txt
  - walkway.jpg
  - engine-room.jpg
  - exhibition.jpg
- .reactions/
  - place.txt
  - exterior.txt
  - exterior/north-tower.jpg.txt

=== place.txt ===
# PLACE: Tower Bridge

CREATED: 2025-11-21 10:00_00
AUTHOR: BRAVO2
COORDINATES: 51.5055,-0.0754
RADIUS: 200
ADDRESS: Tower Bridge Rd, London SE1 2UP, UK
TYPE: monument

Iconic combined bascule and suspension bridge in London.

Completed in 1894, Tower Bridge crosses the River Thames
close to the Tower of London. The bridge is one of London's
most famous landmarks.

Features include two towers, a high-level walkway with
glass floors, and the original Victorian engine rooms.

Open to visitors daily. Tickets required for tower access.

--> npub: npub1bravo...
--> signature: 999aaabbb000...

=== exterior/subfolder.txt ===
# SUBFOLDER: Exterior Views

CREATED: 2025-11-21 14:00_00
AUTHOR: BRAVO2

External photographs of Tower Bridge architecture.

Captured from multiple angles showing the iconic
Gothic towers and suspension system.

--> npub: npub1bravo...
--> signature: ccc333ddd444...

=== interior/subfolder.txt ===
# SUBFOLDER: Interior Features

CREATED: 2025-11-21 15:00_00
AUTHOR: BRAVO2

Internal features including the walkway and engine rooms.

Showcases the Victorian engineering and modern
glass floor walkway additions.

--> npub: npub1bravo...
--> signature: eee555fff666...

=== .reactions/place.txt ===
LIKES: CR7BBQ, X135AS, ALPHA1, DELTA4

> 2025-11-21 17:00_00 -- CR7BBQ
Stunning bridge! The engineering is impressive.
--> npub: npub1abc123...
--> signature: ggg777hhh888...

> 2025-11-21 18:30_00 -- X135AS
The glass floor walkway is a must-see experience!

=== .reactions/exterior.txt ===
LIKES: CR7BBQ, ALPHA1

> 2025-11-21 16:00_00 -- ALPHA1
Great collection of exterior shots!
```

## Parsing Implementation

### Place File Parsing

```
1. Read place.txt as UTF-8 text
2. Verify first line starts with "# PLACE: "
3. Extract name from first line
4. Parse header lines:
   - CREATED: timestamp
   - AUTHOR: callsign
   - COORDINATES: lat,lon
   - RADIUS: meters (10-1000)
   - ADDRESS: (optional)
   - TYPE: (optional)
   - ADMINS: (optional)
   - MODERATORS: (optional)
5. Find content start (after header blank line)
6. Parse content until metadata or EOF
7. Extract metadata (npub, signature)
8. Validate signature placement (must be last)
```

### Region Calculation

```
1. Extract coordinates from COORDINATES field
2. Round latitude to 1 decimal place
3. Round longitude to 1 decimal place
4. Format region folder: {LAT}_{LON}/
5. Check for numbered subfolders (001/, 002/, etc.)
6. Verify place folder is in correct region/subfolder
```

### Reaction File Parsing

```
1. Read .reactions/<item>.txt
2. Parse LIKES line (comma-separated callsigns)
3. Parse comments:
   - Extract timestamp and author from header
   - Read content lines
   - Parse metadata (npub, signature)
4. Associate with target item
```

### File Enumeration

```
1. List all files in place folder (exclude . files)
2. Identify subfolders
3. For each subfolder:
   - Check for subfolder.txt
   - List files in subfolder
   - Recursively enumerate nested subfolders
4. Build file tree structure
5. Cross-reference with .reactions/ for engagement data
```

## File Operations

### Creating a Place

```
1. Sanitize place name
2. Generate folder name: {lat}_{lon}_name/
3. Calculate region from coordinates (round to 1 decimal)
4. Create region directory if needed: {LAT}_{LON}/
5. Determine place location within region:
   a. Count existing places in region
   b. If count < 10,000: Place goes directly in region folder
   c. If count ≥ 10,000:
      - Calculate subfolder number: (count / 10,000) + 1
      - Format subfolder: 001/, 002/, etc.
      - Create subfolder if needed
   d. If migrating from flat to subfolder structure:
      - Create 001/ subfolder
      - Move all existing places to 001/
      - Create new place in appropriate subfolder
6. Create place folder: {LAT}_{LON}/{lat}_{lon}_name/
   or: {LAT}_{LON}/00X/{lat}_{lon}_name/
7. Create place.txt with header and content
8. Create .reactions/ directory
9. Set folder permissions (755)
```

**Example Migration**:
```
Initial structure (9,999 places):
38.7_-9.1/
├── place1/
├── place2/
└── place9999/

After 10,000th place added:
38.7_-9.1/
├── 001/                    # All previous places moved here
│   ├── place1/
│   ├── place2/
│   └── place9999/
└── 002/                    # New place
    └── place10000/
```

### Adding Files to Place

```
1. Verify place exists
2. Copy file(s) to place folder or subfolder
3. Preserve original filenames
4. Set file permissions (644)
5. Update UI/index with new files
```

### Creating Contributor Folder

```
1. Verify place exists
2. Create contributors/ folder if needed
3. Create contributors/CALLSIGN/ folder
4. Optionally create contributor.txt
5. Set folder permissions (755)
6. Update place index
```

### Admin Copying Contributor Photo

```
1. Verify user is admin
2. Select photo from contributors/CALLSIGN/
3. Copy to main place folder or subfolder
4. Preserve original filename
5. Add attribution metadata (optional)
6. Original remains in contributor folder
7. Update place index
```

### Adding a Like

```
1. Determine target (place, file, subfolder, or contributor)
2. Generate reaction filename: .reactions/<target>.txt
3. Read existing reaction file or create new
4. Parse LIKES line
5. Check if user already liked
6. If not, add callsign to LIKES list
7. Write updated reaction file
```

### Adding a Comment

```
1. Determine target item
2. Generate reaction filename
3. Read existing or create new
4. Append comment:
   - Header line with timestamp and author
   - Content lines
   - Metadata (npub, signature)
5. Write updated reaction file
```

### Deleting a Place

```
1. Verify user has permission (creator or admin)
2. Recursively delete place folder and all contents:
   - All files
   - All subfolders
   - contributors/ directory
   - .reactions/ directory
3. Update place index
4. Check if numbered subfolder is empty:
   - If empty, optionally delete subfolder
5. Check if region folder is empty:
   - If empty, optionally delete region
```

### Searching Places in Dense Regions

```
1. Calculate region from search coordinates
2. Check if region has numbered subfolders:
   a. If no subfolders: Search directly in region folder
   b. If subfolders exist: Search across all subfolders (001/, 002/, etc.)
3. For proximity searches:
   - Search primary region and neighboring regions
   - Consider radius overlap between regions
4. Build result list from all matching places
5. Sort by distance from search point
```

**Optimization**:
- Index place locations for faster searches
- Cache region/subfolder structure
- Pre-filter by bounding box before distance calculation

## Validation Rules

### Place Validation

- [x] First line must start with `# PLACE: `
- [x] Name must not be empty
- [x] CREATED line must have valid timestamp
- [x] AUTHOR line must have non-empty callsign
- [x] COORDINATES must be valid lat,lon
- [x] RADIUS must be integer 10-1000
- [x] Header must end with blank line
- [x] Signature must be last metadata if present
- [x] Folder name must match {lat}_{lon}_* pattern
- [x] Place folder must be in correct region folder
- [x] If in numbered subfolder, subfolder must match 001-999 pattern
- [x] Region folder must match {LAT}_{LON} pattern (1 decimal place)

### Coordinate Validation

**Full Precision (Place)**:
- Latitude: -90.0 to +90.0
- Longitude: -180.0 to +180.0
- Format: `lat,lon` (no spaces)
- Precision: Up to 6 decimal places

**Rounded (Region)**:
- Latitude: 1 decimal place
- Longitude: 1 decimal place
- Range: -90.0 to +90.0, -180.0 to +180.0

### Radius Validation

- Must be integer
- Minimum: 10 meters
- Maximum: 1000 meters
- Format: `RADIUS: <number>` (no units in value)

### Reaction File Validation

- Filename must match existing file/folder/place
- LIKES line format: `LIKES: callsign1, callsign2`
- No duplicate callsigns in LIKES list
- Comments must have valid timestamp
- Signature must be last if present

## Best Practices

### For Place Creators

1. **Accurate coordinates**: Use precise GPS coordinates
2. **Appropriate radius**: Match radius to actual place size
3. **Clear descriptions**: Write detailed, informative descriptions
4. **Quality photos**: Upload clear, well-composed images
5. **Organize content**: Use subfolders for large collections
6. **Complete address**: Include full address for easier finding
7. **Categorize**: Use TYPE field for filtering
8. **Sign places**: Use npub/signature for authenticity

### For Contributors

1. **Respect guidelines**: Follow place rules and theme
2. **Quality submissions**: Share your best photos
3. **Add context**: Use contributor.txt to describe your work
4. **Proper attribution**: Sign your contributions
5. **Organize**: Use subfolders in your contributor folder
6. **Engage**: Like and comment on others' work

### For Developers

1. **Validate input**: Check all coordinates and radius values
2. **Region calculation**: Ensure correct region placement
3. **Atomic operations**: Use temp files for updates
4. **Permission checks**: Verify user rights before operations
5. **Handle errors**: Gracefully handle missing/invalid files
6. **Optimize reads**: Cache place metadata, lazy-load files
7. **Index reactions**: Build indexes for performance
8. **Map integration**: Integrate with mapping services

### For Administrators

1. **Review contributions**: Regularly check contributor folders
2. **Curate content**: Promote best photos to main area
3. **Moderate fairly**: Apply consistent standards
4. **Size limits**: Set reasonable file size limits
5. **Monitor storage**: Track disk usage per region
6. **Monitor density**: Watch for regions approaching 10,000 places
7. **Migration planning**: Plan for subfolder migration in dense regions
8. **Backup strategy**: Regular backups of places/
9. **Archive old**: Consider archiving unused places
10. **Index maintenance**: Keep search indexes updated for dense regions

## Security Considerations

### Access Control

**Place Creator**:
- Edit place.txt
- Delete place and all contents
- Create/delete subfolders
- Moderate all comments
- Manage contributor content

**Admins**:
- Same as place creator
- Can be added/removed by creator

**Moderators**:
- Hide comments and files
- Cannot delete permanently
- Cannot edit place.txt

**Contributors**:
- Create own contributor folder
- Add/edit/delete own contributions
- Like and comment on content
- Cannot modify place or others' content

### File Security

**Permissions**:
- Place folders: 755 (rwxr-xr-x)
- Files: 644 (rw-r--r--)
- No execute permissions on uploaded files

**Path Validation**:
- Prevent directory traversal (../)
- Validate filenames (no special chars)
- Check file types before storage
- Scan for malicious content (if applicable)

### Location Privacy

**Coordinate Precision**:
- 6 decimal places ≈ 0.1 meter precision
- Consider privacy before using exact coordinates
- For private residences, use approximate coordinates
- Offset sensitive locations slightly

**Radius Considerations**:
- Small radius reveals specific location
- Large radius provides more privacy
- Balance accuracy with privacy needs

### Threat Mitigation

**File Upload Abuse**:
- Set maximum file sizes
- Limit total place size
- Validate file types
- Scan for malware

**Spam Prevention**:
- Rate limit likes and comments
- Require NOSTR signatures for actions
- Moderate content via .hidden/ system

**Data Integrity**:
- Use NOSTR signatures
- Hash files for integrity checks
- Regular backups
- Validate on read

## Related Documentation

- [Events Format Specification](events-format-specification.md)
- [Blog Format Specification](blog-format-specification.md)
- [Chat Format Specification](chat-format-specification.md)
- [Forum Format Specification](forum-format-specification.md)
- [Collection File Formats](../others/file-formats.md)
- [NOSTR Protocol](https://github.com/nostr-protocol/nostr)

## Change Log

### Version 1.0 (2025-11-21)

**Initial Specification**:
- Coordinate-based organization with ~30,000 regions
- Two-level folder structure (region/place)
  - Compact region naming: `{LAT}_{LON}/` (e.g., `38.7_-9.1/`)
  - Simplified format (removed "lat_" and "lon_" prefixes)
- Dense region support with numbered subfolders:
  - Automatic subfolder creation (001/, 002/, etc.) at 10,000 place threshold
  - Maintains filesystem performance in dense urban areas
  - Seamless migration from flat to subfolder structure
  - Virtually unlimited capacity per region (999 subfolders × 10,000 places)
- Place metadata with coordinates and radius (10m-1000m)
- Photo organization with individual reactions
- Contributor system with admin review
- Subfolder organization
- Granular reactions system (likes on places, files, subfolders, contributors)
- Granular comments system (comments on places, files, subfolders, contributors)
- Admin/moderator permission system
- Moderation system with .hidden/ directory
- Simple text format (no markdown)
- NOSTR signature integration
- Address and type categorization
