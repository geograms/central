# Report Format Specification

**Version**: 1.0
**Last Updated**: 2025-11-23
**Status**: Draft

## Table of Contents

- [Overview](#overview)
- [File Organization](#file-organization)
- [Coordinate-Based Organization](#coordinate-based-organization)
- [Report Format](#report-format)
- [Severity Levels](#severity-levels)
- [Report Types Reference](#report-types-reference)
- [Photos and Media](#photos-and-media)
- [Photo Guidelines](#photo-guidelines)
- [Verification System](#verification-system)
- [Duplicate Detection](#duplicate-detection)
- [Authority Integration](#authority-integration)
- [Subscription System](#subscription-system)
- [News Log System](#news-log-system)
- [Official Entity Groups](#official-entity-groups)
- [Report Updates](#report-updates)
- [Resolution Tracking](#resolution-tracking)
- [Expiration and TTL](#expiration-and-ttl)
- [Priority Queue](#priority-queue)
- [Analytics and Statistics](#analytics-and-statistics)
- [Reactions System](#reactions-system)
- [Comments](#comments)
- [Permissions and Roles](#permissions-and-roles)
- [Moderation System](#moderation-system)
- [NOSTR Integration](#nostr-integration)
- [Integration Features](#integration-features)
- [Complete Examples](#complete-examples)
- [Parsing Implementation](#parsing-implementation)
- [File Operations](#file-operations)
- [Validation Rules](#validation-rules)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)
- [Related Documentation](#related-documentation)
- [Change Log](#change-log)

## Overview

This document specifies the text-based format used for storing reports in the Geogram system. The reports collection type provides a platform for users to report issues, hazards, problems, or items of concern at specific geographic locations.

Reports are designed for documenting things that need attention, repair, or awareness - from broken infrastructure to dangerous conditions, vandalism, emergencies, or missing items.

### Key Features

- **Coordinate-Based Organization**: Reports organized by geographic regions
- **Mandatory Location**: Every report must have exact coordinates
- **Severity Classification**: Four severity levels (emergency, urgent, attention, info)
- **Type Categorization**: 260+ predefined report types for consistent classification
- **Status Tracking**: Track reports from open through resolution
- **Photo Documentation**: Attach multiple photos with guidelines showing the issue
- **Community Photo Contributions**: Anyone can contribute photos to `contributed-photos/` folder
- **Verification System**: Community can confirm reports for increased credibility
- **Duplicate Detection**: Link and consolidate similar nearby reports
- **Subscription System**: Users subscribe to receive notifications about report progress
- **News Log**: Public timeline (`news.txt`) tracking all events from creation to resolution
- **Official Entity Groups**: Fire departments, city maintenance, etc. auto-authorized to update
- **Authority Integration**: Track official case numbers and notifications
- **Updates System**: Add status updates as situation changes
- **Resolution Proof**: Document when and how issue was resolved
- **Expiration and TTL**: Auto-close or archive old unresolved reports
- **Priority Queue**: Sort by severity, age, and geographic clustering
- **Analytics**: Heat maps, statistics, and response time tracking
- **Multilanguage Support**: Title and description in multiple languages
- **Simple Text Format**: Plain text descriptions (no markdown)
- **NOSTR Integration**: Cryptographic signatures for authenticity
- **Community Engagement**: Likes and comments on reports
- **Export/Import**: GeoJSON, API integration for third-party systems

## File Organization

### Directory Structure

```
collection_name/
├── active/                             # Active reports
│   ├── 38.7_-9.1/                      # Region folder (1° precision)
│   │   ├── 38.7223_-9.1393_broken-sidewalk/
│   │   │   ├── report.txt
│   │   │   ├── news.txt                # News/log timeline
│   │   │   ├── photo1.jpg
│   │   │   ├── photo2.jpg
│   │   │   ├── contributed-photos/     # Community contributed photos
│   │   │   │   ├── user1_evidence.jpg
│   │   │   │   └── user2_angle.jpg
│   │   │   ├── updates/
│   │   │   │   ├── 2025-11-22_repair-started.txt
│   │   │   │   └── 2025-11-25_completed.txt
│   │   │   └── .reactions/
│   │   │       ├── report.txt
│   │   │       └── photo1.jpg.txt
│   │   └── 38.7169_-9.1399_vandalized-sign/
│   │       ├── report.txt
│   │       ├── vandalism-photo.jpg
│   │       └── .reactions/
│   │           └── report.txt
│   ├── 40.7_-74.0/                     # Another region
│   │   └── 40.7128_-74.0060_dangerous-pothole/
│   │       ├── report.txt
│   │       └── pothole.jpg
│   └── 35.6_139.6/                     # Dense region with subfolders
│       ├── 001/
│       │   └── 35.6762_139.6503_fire-hazard/
│       │       └── report.txt
│       └── 002/
│           └── 35.6812_139.7671_broken-railing/
│               └── report.txt
└── expired/                            # Expired or deactivated reports
    └── 38.7_-9.1/
        └── 38.7100_-9.1350_old-pothole/
            ├── report.txt              # STATUS: closed or expired
            └── photo.jpg
```

### Active vs Expired Organization

**active/** Directory:
- Contains all open, in-progress, and recently resolved reports
- Reports that require attention or monitoring
- Default location for new reports
- Actively searched and displayed in standard views

**expired/** Directory:
- Contains closed reports past their expiration date
- Deactivated reports (manually closed, no action needed)
- Old resolved reports (configurable age, e.g., >90 days after resolution)
- Archived for historical reference
- Not shown in standard views
- Can be searched separately for historical data

**Moving Between Directories**:
Reports are automatically moved from `active/` to `expired/` when:
1. TTL expires and STATUS is changed to `closed`
2. STATUS manually changed to `closed` and configured retention period passes
3. STATUS is `resolved` and configured post-resolution period passes (e.g., 90 days)
4. Admin manually deactivates the report

The entire report folder (including all photos, updates, reactions) is moved while maintaining the same region structure.

### Region Folder Naming

**Pattern**: `{LAT}_{LON}/`

**Coordinate Rounding**:
- Round latitude to 1 decimal place (e.g., 38.7223 → 38.7)
- Round longitude to 1 decimal place (e.g., -9.1393 → -9.1)
- Same system as Places collection (~30,000 regions globally)
- Each region covers approximately 130 km × 130 km at the equator

**Examples**:
```
active/38.7_-9.1/          # Active reports in Lisbon area, Portugal
active/40.7_-74.0/         # Active reports in New York City area, USA
expired/51.5_-0.1/         # Expired reports in London area, UK
```

### Dense Region Organization

For regions with many reports (dense urban areas), numbered subfolders:

**Threshold**: 10,000 reports per folder

**Structure**:
```
active/35.6_139.6/          # Tokyo region (active)
├── 001/                    # Reports 1-10,000
│   ├── report1/
│   └── ...
└── 002/                    # Reports 10,001-20,000
    └── ...

expired/35.6_139.6/         # Tokyo region (expired)
└── 001/
    └── old-reports/
```

### Report Folder Naming

**Pattern**: `{LAT}_{LON}_{sanitized-description}/`

**Full Precision Coordinates**:
- Use full precision (6 decimal places recommended)
- Latitude: -90.0 to +90.0
- Longitude: -180.0 to +180.0

**Sanitization Rules**:
1. Convert description to lowercase
2. Replace spaces and underscores with single hyphens
3. Remove all non-alphanumeric characters (except hyphens)
4. Collapse multiple consecutive hyphens
5. Remove leading/trailing hyphens
6. Truncate to 50 characters
7. Prepend full coordinates

**Examples**:
```
Description: "Broken Sidewalk on Main Street"
Coordinates: 38.7223, -9.1393
→ 38.7223_-9.1393_broken-sidewalk-on-main-street/

Description: "Dangerous Pothole @ Highway Exit"
Coordinates: 40.7128, -74.0060
→ 40.7128_-74.0060_dangerous-pothole-highway-exit/

Description: "Vandalized Public Sign"
Coordinates: 51.5055, -0.0754
→ 51.5055_-0.0754_vandalized-public-sign/
```

### Special Directories

**`.reactions/` Directory**:
- Hidden directory (starts with dot)
- Contains reaction files for report and items
- One file per item that has likes/comments

**`.hidden/` Directory**:
- Hidden directory for moderated content
- Contains files/comments hidden by moderators
- Not visible in standard UI

**`updates/` Directory**:
- Contains status update files
- Chronological updates on report progress
- Resolution documentation

## Coordinate-Based Organization

Uses the same grid system as Places collection:

1. **Region Level**: Rounded coordinates (1 decimal place)
   - ~30,000 regions globally
   - ~130 km × 130 km per region

2. **Report Level**: Full precision coordinates (6 decimals)
   - Precision: ~0.1 meters (at equator)
   - Exact location identification

**Finding a Report's Region**:
```
Given coordinates: 38.7223, -9.1393

1. Round latitude to 1 decimal: 38.7
2. Round longitude to 1 decimal: -9.1
3. Format region path: active/38.7_-9.1/
4. Check report count in region:
   - If < 10,000: Report goes directly in region folder
   - If ≥ 10,000: Report goes in appropriate numbered subfolder

Full path: active/38.7_-9.1/38.7223_-9.1393_broken-sidewalk/
```

## Report Format

### Main Report File

Every report must have a `report.txt` file in the report folder root.

**Complete Structure (Single Language)**:
```
# REPORT: Brief Description

CREATED: YYYY-MM-DD HH:MM_ss
AUTHOR: CALLSIGN
COORDINATES: lat,lon
SEVERITY: emergency|urgent|attention|info
TYPE: category
STATUS: open|in-progress|resolved|closed
ADDRESS: Full Address (optional)
CONTACT: Contact information (optional)
VERIFIED_BY: npub1user1..., npub1user2... (optional)
VERIFICATION_COUNT: 3 (optional)
DUPLICATE_OF: report-folder-name (optional)
RELATED_REPORTS: report-folder1, report-folder2 (optional)
OFFICIAL_CASE: CASE-12345 (optional)
AUTHORITY_NOTIFIED: Fire Department, 2025-11-23 14:30_00 (optional)
TTL: 2592000 (optional, in seconds)
EXPIRES: 2025-12-23 10:00_00 (optional)
ADMINS: npub1abc123..., npub1xyz789... (optional)
MODERATORS: npub1delta..., npub1echo... (optional)
UPDATE_AUTHORIZED: npub1user1..., npub1user2... (optional)
SUBSCRIBERS: npub1sub1..., npub1sub2... (optional)
SUBSCRIBER_COUNT: 15 (optional)

Detailed description of the reported issue.
Plain text format.
No markdown formatting.

Can include multiple paragraphs describing
the problem, its location, and any relevant
context or safety concerns.

--> npub: npub1...
--> signature: hex_signature
```

**Complete Structure (Multilanguage)**:
```
# REPORT_EN: Brief Description in English
# REPORT_PT: Breve Descrição em Português
# REPORT_ES: Breve Descripción en Español

CREATED: YYYY-MM-DD HH:MM_ss
AUTHOR: CALLSIGN
COORDINATES: lat,lon
SEVERITY: emergency|urgent|attention|info
TYPE: category
STATUS: open|in-progress|resolved|closed
ADDRESS: Full Address (optional)
CONTACT: Contact information (optional)
VERIFIED_BY: npub1user1..., npub1user2... (optional)
VERIFICATION_COUNT: 3 (optional)
DUPLICATE_OF: report-folder-name (optional)
RELATED_REPORTS: report-folder1, report-folder2 (optional)
OFFICIAL_CASE: CASE-12345 (optional)
AUTHORITY_NOTIFIED: Fire Department, 2025-11-23 14:30_00 (optional)
TTL: 2592000 (optional, in seconds)
EXPIRES: 2025-12-23 10:00_00 (optional)
ADMINS: npub1abc123..., npub1xyz789... (optional)
MODERATORS: npub1delta..., npub1echo... (optional)
UPDATE_AUTHORIZED: npub1user1..., npub1user2... (optional)
SUBSCRIBERS: npub1sub1..., npub1sub2... (optional)
SUBSCRIBER_COUNT: 15 (optional)

[EN]
Detailed description in English.
Multiple paragraphs allowed.

[PT]
Descrição detalhada em Português.
Vários parágrafos permitidos.

[ES]
Descripción detallada en Español.
Se permiten múltiples párrafos.

--> npub: npub1...
--> signature: hex_signature
```

### Header Section

1. **Title Line** (required)
   - **Single Language Format**: `# REPORT: <description>`
   - **Multilanguage Format**: `# REPORT_XX: <description>`
   - **Examples**:
     - Single: `# REPORT: Broken Sidewalk`
     - Multi: `# REPORT_EN: Broken Sidewalk`
     - Multi: `# REPORT_PT: Calçada Quebrada`
   - **Supported Languages**: EN, PT, ES, FR, DE, IT, NL, RU, ZH, JA, AR

2. **Blank Line** (required)
   - Separates title from metadata

3. **Created Timestamp** (required)
   - **Format**: `CREATED: YYYY-MM-DD HH:MM_ss`
   - **Example**: `CREATED: 2025-11-23 10:00_00`
   - **Note**: Underscore before seconds

4. **Author Line** (required)
   - **Format**: `AUTHOR: <callsign>`
   - **Example**: `AUTHOR: CR7BBQ`
   - **Note**: Author is automatically an admin

5. **Coordinates** (required)
   - **Format**: `COORDINATES: <lat>,<lon>`
   - **Example**: `COORDINATES: 38.7223,-9.1393`
   - **Constraints**: Valid lat,lon coordinates
   - **Precision**: Up to 6 decimal places recommended
   - **Note**: Exact location is mandatory for all reports

6. **Severity** (required)
   - **Format**: `SEVERITY: emergency|urgent|attention|info`
   - **Example**: `SEVERITY: urgent`
   - **Values**:
     - `emergency`: Immediate danger to life or property
     - `urgent`: Needs prompt attention, potential safety risk
     - `attention`: Should be addressed soon, non-critical
     - `info`: Informational, low priority

7. **Type** (required)
   - **Format**: `TYPE: <category>`
   - **Example**: `TYPE: infrastructure-broken`
   - **Purpose**: Categorize the type of issue
   - **See**: Report Types Reference section

8. **Status** (required)
   - **Format**: `STATUS: open|in-progress|resolved|closed`
   - **Values**:
     - `open`: Report submitted, awaiting action
     - `in-progress`: Being worked on
     - `resolved`: Issue fixed/addressed
     - `closed`: Report closed (resolved or no action needed)
   - **Default**: `open`

9. **Address** (optional)
   - **Format**: `ADDRESS: <full address>`
   - **Example**: `ADDRESS: 123 Main Street, Lisbon, Portugal`
   - **Purpose**: Human-readable location description

10. **Contact** (optional)
    - **Format**: `CONTACT: <contact information>`
    - **Example**: `CONTACT: Local authorities notified`
    - **Purpose**: Note if authorities contacted or how to follow up
    - **Note**: Avoid personal contact info for privacy

11. **Verified By** (optional)
    - **Format**: `VERIFIED_BY: <npub1>, <npub2>, ...`
    - **Example**: `VERIFIED_BY: npub1user1..., npub1user2...`
    - **Purpose**: List of users who verified/confirmed the report
    - **See**: Verification System section

12. **Verification Count** (optional)
    - **Format**: `VERIFICATION_COUNT: <number>`
    - **Example**: `VERIFICATION_COUNT: 5`
    - **Purpose**: Total number of independent verifications
    - **Note**: Auto-updated when users verify

13. **Duplicate Of** (optional)
    - **Format**: `DUPLICATE_OF: <report-folder-name>`
    - **Example**: `DUPLICATE_OF: 38.7223_-9.1393_broken-sidewalk`
    - **Purpose**: Mark this report as duplicate of another
    - **See**: Duplicate Detection section

14. **Related Reports** (optional)
    - **Format**: `RELATED_REPORTS: <folder1>, <folder2>, ...`
    - **Example**: `RELATED_REPORTS: 38.7220_-9.1390_cracked-curb`
    - **Purpose**: Link to related nearby reports
    - **See**: Duplicate Detection section

15. **Official Case** (optional)
    - **Format**: `OFFICIAL_CASE: <case-number>`
    - **Example**: `OFFICIAL_CASE: FIRE-2025-1234`
    - **Purpose**: Track official authority case/ticket number
    - **See**: Authority Integration section

16. **Authority Notified** (optional)
    - **Format**: `AUTHORITY_NOTIFIED: <authority>, <timestamp>`
    - **Example**: `AUTHORITY_NOTIFIED: Fire Department, 2025-11-23 14:30_00`
    - **Purpose**: Record which authority was notified and when
    - **See**: Authority Integration section

17. **TTL** (optional)
    - **Format**: `TTL: <seconds>`
    - **Example**: `TTL: 2592000` (30 days)
    - **Purpose**: Time-to-live in seconds before report expires
    - **See**: Expiration and TTL section

18. **Expires** (optional)
    - **Format**: `EXPIRES: YYYY-MM-DD HH:MM_ss`
    - **Example**: `EXPIRES: 2025-12-23 10:00_00`
    - **Purpose**: Exact expiration timestamp (calculated from CREATED + TTL)
    - **See**: Expiration and TTL section

19. **Admins** (optional)
    - **Format**: `ADMINS: <npub1>, <npub2>, ...`
    - **Example**: `ADMINS: npub1abc123..., npub1xyz789...`
    - **Purpose**: Additional administrators for report
    - **Note**: Author is always admin automatically, even if not listed here

20. **Moderators** (optional)
    - **Format**: `MODERATORS: <npub1>, <npub2>, ...`
    - **Example**: `MODERATORS: npub1delta..., npub1echo...`
    - **Purpose**: Users who can moderate content (hide inappropriate photos/comments)

21. **Update Authorized** (optional)
    - **Format**: `UPDATE_AUTHORIZED: <npub1>, <npub2>, ...`
    - **Example**: `UPDATE_AUTHORIZED: npub1firefighter..., npub1inspector...`
    - **Purpose**: Users authorized to add updates/news to this report
    - **Note**: Admins can always add updates; this field grants additional users permission
    - **See**: Official Entity Groups section for global authorization groups

22. **Subscribers** (optional)
    - **Format**: `SUBSCRIBERS: <npub1>, <npub2>, ...`
    - **Example**: `SUBSCRIBERS: npub1user1..., npub1user2...`
    - **Purpose**: List of users subscribed to receive notifications about this report
    - **Note**: Auto-updated when users subscribe/unsubscribe
    - **See**: Subscription System section

23. **Subscriber Count** (optional)
    - **Format**: `SUBSCRIBER_COUNT: <number>`
    - **Example**: `SUBSCRIBER_COUNT: 15`
    - **Purpose**: Total number of subscribers
    - **Note**: Auto-calculated from SUBSCRIBERS list length

24. **Blank Line** (required)
    - Separates header from content

### Content Section

**Single Language Format**:
```
Description of the issue.
Multiple paragraphs allowed.

Include relevant details about:
- What is broken/damaged/missing
- When it was noticed
- Potential dangers or hazards
- Urgency of the situation
```

**Multilanguage Format**:
```
[EN]
Description in English.
Multiple paragraphs allowed.

[PT]
Descrição em Português.
Vários parágrafos permitidos.

[ES]
Descripción en Español.
Se permiten múltiples párrafos.
```

**Characteristics**:
- **Plain text only** (no markdown)
- Multiple paragraphs allowed
- Blank lines separate paragraphs
- Whitespace preserved
- No length limit (reasonable sizes recommended)
- At least one language required for multilanguage format

### Report Metadata

Metadata appears after content:

```
--> npub: npub1abc123...
--> signature: hex_signature_string...
```

## Severity Levels

### Emergency

**Severity**: `SEVERITY: emergency`

**Characteristics**:
- Immediate danger to life or property
- Requires urgent response
- Should be reported to authorities immediately
- Highest priority

**Examples**:
- Fire outbreak
- Gas leak
- Collapsed structure
- Active flooding endangering people
- Live electrical wires on ground
- Bridge structural failure
- Chemical spill

**Response Time**: Immediate (minutes)

**UI Display**: Red badge, prominent alert

### Urgent

**Severity**: `SEVERITY: urgent`

**Characteristics**:
- Potential safety risk
- Needs prompt attention
- Could escalate if not addressed soon
- High priority

**Examples**:
- Large pothole in busy street
- Broken traffic light
- Damaged guardrail on highway
- Fallen tree blocking road
- Broken water main
- Missing manhole cover
- Unstable wall or fence

**Response Time**: Within hours to 1 day

**UI Display**: Orange badge, high visibility

### Attention

**Severity**: `SEVERITY: attention`

**Characteristics**:
- Should be addressed soon
- Not immediately dangerous
- Quality of life impact
- Normal priority

**Examples**:
- Broken sidewalk
- Graffiti/vandalism
- Broken street light
- Damaged park bench
- Litter accumulation
- Broken playground equipment
- Peeling paint on public infrastructure

**Response Time**: Within days to weeks

**UI Display**: Yellow badge, standard visibility

### Info

**Severity**: `SEVERITY: info`

**Characteristics**:
- Informational
- Low priority
- No immediate action needed
- Awareness/documentation

**Examples**:
- Minor cosmetic damage
- Suggestions for improvement
- Observations about area
- Historical documentation
- Wear and tear (normal aging)

**Response Time**: When convenient, if at all

**UI Display**: Blue badge, low-key presentation

## Report Types Reference

This section provides a comprehensive list of 260+ predefined report types organized by category. Use the most specific type that matches the issue being reported.

### 1. Road Infrastructure

**Pavement Damage**:
- `pothole`: Hole or depression in road surface
- `pothole-large`: Large pothole (>30cm diameter)
- `pavement-crack`: Cracks in road pavement
- `pavement-sinking`: Sunken or subsided pavement
- `pavement-heaving`: Raised or buckled pavement
- `pavement-crumbling`: Deteriorating pavement edges
- `asphalt-missing`: Missing chunks of asphalt
- `road-erosion`: Road edge erosion
- `road-collapse`: Road surface collapse or cave-in

**Road Surface Issues**:
- `road-flooding`: Standing water on roadway
- `road-ice`: Icy road conditions
- `road-oil-spill`: Oil or fuel spill on road
- `road-debris`: Debris on roadway
- `road-obstruction`: Object blocking road
- `road-damage-general`: General road damage

**Road Markings**:
- `marking-faded`: Faded lane markings
- `marking-missing`: Missing road markings
- `marking-damaged`: Damaged or incorrect markings
- `crosswalk-faded`: Faded pedestrian crosswalk
- `stop-line-missing`: Missing stop line

### 2. Sidewalk and Pedestrian Infrastructure

**Sidewalk Damage**:
- `sidewalk-crack`: Cracked sidewalk
- `sidewalk-broken`: Broken or damaged sidewalk
- `sidewalk-uneven`: Trip hazard from uneven sidewalk
- `sidewalk-sinking`: Sunken sidewalk section
- `sidewalk-heaving`: Raised sidewalk (tree roots, frost)
- `sidewalk-missing`: Missing sidewalk section
- `sidewalk-obstruction`: Obstruction blocking sidewalk

**Curbs and Ramps**:
- `curb-damage`: Damaged or broken curb
- `curb-missing`: Missing curb section
- `ramp-damaged`: Damaged wheelchair ramp
- `ramp-missing`: Missing accessibility ramp
- `ramp-too-steep`: Non-compliant ramp slope

**Pedestrian Crossings**:
- `crosswalk-damage`: Damaged crosswalk
- `crossing-signal-broken`: Non-functioning crossing signal
- `crossing-button-broken`: Pedestrian button not working
- `crossing-unsafe`: Dangerous crossing conditions

### 3. Bridges and Overpasses

**Structural Issues**:
- `bridge-crack`: Cracks in bridge structure
- `bridge-damage`: General bridge damage
- `bridge-railing-damage`: Damaged bridge railing
- `bridge-deck-damage`: Damaged bridge deck
- `overpass-damage`: Damaged overpass
- `underpass-damage`: Damaged underpass

**Bridge Safety**:
- `bridge-ice`: Icy bridge conditions
- `bridge-debris`: Debris on bridge
- `bridge-lighting-out`: Bridge lights not working

### 4. Traffic Control

**Traffic Signals**:
- `traffic-light-out`: Traffic light not working
- `traffic-light-stuck`: Traffic light stuck on one color
- `traffic-light-timing`: Poor signal timing
- `traffic-light-damaged`: Physically damaged signal
- `traffic-light-flickering`: Flickering traffic light
- `traffic-light-missing`: Missing traffic signal

**Traffic Signs**:
- `sign-missing`: Missing traffic sign
- `sign-damaged`: Damaged or bent sign
- `sign-graffiti`: Sign covered with graffiti
- `sign-faded`: Faded, illegible sign
- `sign-obstructed`: Sign blocked by vegetation
- `sign-wrong`: Incorrect or misleading sign
- `sign-fallen`: Fallen or knocked-down sign

**Traffic Safety Devices**:
- `barrier-damaged`: Damaged traffic barrier
- `barrier-missing`: Missing safety barrier
- `guardrail-damaged`: Damaged guardrail
- `guardrail-missing`: Missing guardrail section
- `bollard-damaged`: Damaged bollard
- `speed-bump-damaged`: Damaged speed bump
- `cone-needed`: Area needs traffic cones
- `barricade-needed`: Area needs barricades

### 5. Lighting

**Street Lighting**:
- `streetlight-out`: Street light not working
- `streetlight-flickering`: Flickering street light
- `streetlight-dim`: Dim or weak street light
- `streetlight-damaged`: Physically damaged light fixture
- `streetlight-missing`: Missing street light
- `streetlight-daytime`: Light on during daytime
- `streetlight-knocked-down`: Knocked over light post

**Other Public Lighting**:
- `parking-light-out`: Parking lot light out
- `park-light-out`: Park lighting not working
- `path-light-out`: Pathway/trail light out
- `tunnel-light-out`: Tunnel lighting issues
- `underpass-light-out`: Underpass lighting out

### 6. Utilities - Water

**Water Main Issues**:
- `water-leak`: Water main leak
- `water-leak-major`: Major water main break
- `pipe-burst`: Burst water pipe
- `water-flooding`: Flooding from water main
- `water-pressure-low`: Low water pressure issue

**Hydrants and Valves**:
- `hydrant-leaking`: Leaking fire hydrant
- `hydrant-damaged`: Damaged fire hydrant
- `hydrant-knocked-over`: Knocked over hydrant
- `hydrant-obstructed`: Hydrant blocked or inaccessible
- `valve-leaking`: Leaking water valve

**Drainage**:
- `drainage-blocked`: Blocked storm drain
- `drainage-overflow`: Overflowing drain
- `grate-missing`: Missing drainage grate
- `grate-damaged`: Damaged drain grate
- `catch-basin-full`: Full catch basin
- `flooding-drainage`: Flooding due to poor drainage

**Sewer**:
- `sewer-backup`: Sewer backup
- `sewer-odor`: Sewer odor problem
- `manhole-overflow`: Overflowing manhole
- `manhole-cover-missing`: Missing manhole cover (DANGEROUS)
- `manhole-cover-damaged`: Damaged manhole cover
- `manhole-cover-noisy`: Noisy/rattling manhole cover

### 7. Utilities - Electrical

**Power Lines**:
- `power-line-down`: Downed power line (EMERGENCY)
- `power-line-low`: Low-hanging power line
- `power-line-damaged`: Damaged power line
- `power-line-arcing`: Arcing or sparking power line
- `power-outage`: Power outage

**Electrical Hazards**:
- `electrical-hazard`: Exposed electrical wiring
- `electrical-box-open`: Open electrical box
- `transformer-noise`: Noisy transformer
- `transformer-leaking`: Leaking transformer
- `transformer-damaged`: Damaged transformer
- `utility-pole-damaged`: Damaged utility pole
- `utility-pole-leaning`: Leaning utility pole

### 8. Utilities - Gas

**Gas Issues** (All potentially EMERGENCY):
- `gas-leak`: Suspected gas leak
- `gas-odor`: Smell of natural gas
- `gas-line-damaged`: Damaged gas line
- `gas-meter-damaged`: Damaged gas meter

### 9. Utilities - Telecommunications

**Infrastructure**:
- `cable-down`: Downed cable/wire
- `cable-low`: Low-hanging cable
- `cable-damaged`: Damaged cable
- `phone-line-down`: Downed telephone line
- `utility-box-damaged`: Damaged utility box
- `utility-box-open`: Open utility/junction box

### 10. Trees and Vegetation

**Tree Hazards**:
- `tree-fallen`: Fallen tree
- `tree-leaning`: Dangerously leaning tree
- `tree-dead`: Dead tree posing risk
- `tree-damaged`: Damaged tree (storm, disease)
- `branch-hanging`: Hanging/broken branch
- `branch-fallen`: Fallen branch on road/path
- `tree-obstruction`: Tree blocking road or path
- `tree-root-damage`: Tree roots damaging infrastructure

**Vegetation Issues**:
- `vegetation-overgrown`: Overgrown vegetation
- `vegetation-blocking-sign`: Vegetation blocking sign
- `vegetation-blocking-view`: Vegetation blocking sight lines
- `weeds-excessive`: Excessive weed growth
- `invasive-species`: Invasive plant species

### 11. Parks and Recreation

**Playground**:
- `playground-broken`: Broken playground equipment
- `playground-unsafe`: Unsafe playground conditions
- `playground-swing-broken`: Broken swing
- `playground-slide-damaged`: Damaged slide
- `playground-surface-damaged`: Damaged playground surface

**Park Amenities**:
- `bench-damaged`: Damaged park bench
- `bench-missing`: Missing park bench
- `table-damaged`: Damaged picnic table
- `fountain-broken`: Non-functioning fountain
- `fountain-leaking`: Leaking fountain
- `restroom-damaged`: Damaged park restroom
- `restroom-closed`: Restroom closed/locked
- `restroom-dirty`: Unsanitary restroom

**Sports Facilities**:
- `court-damaged`: Damaged sports court
- `goal-damaged`: Damaged sports goal
- `field-damage`: Damaged sports field
- `track-damage`: Damaged running track

**Trails and Paths**:
- `trail-damage`: Damaged trail
- `trail-erosion`: Trail erosion
- `trail-obstruction`: Trail obstruction
- `path-flooding`: Flooded pathway
- `boardwalk-damaged`: Damaged boardwalk

**Park Structures**:
- `fence-damaged`: Damaged fence
- `fence-missing`: Missing fence section
- `gate-broken`: Broken gate
- `shelter-damaged`: Damaged shelter/pavilion
- `sign-vandalized`: Vandalized park sign

### 12. Vandalism and Graffiti

**Property Damage**:
- `vandalism`: General vandalism
- `graffiti`: Graffiti on public property
- `graffiti-offensive`: Offensive graffiti
- `window-broken`: Broken window (vandalism)
- `equipment-vandalized`: Vandalized equipment
- `sign-vandalized`: Vandalized sign

**Environmental Vandalism**:
- `tree-vandalized`: Damaged/cut tree (vandalism)
- `plant-damage`: Damaged plants/flowers
- `monument-vandalized`: Vandalized monument/statue

### 13. Waste and Cleanliness

**Waste Management**:
- `trash-overflow`: Overflowing trash receptacle
- `trash-bin-missing`: Missing trash bin
- `trash-bin-damaged`: Damaged trash bin
- `recycling-overflow`: Overflowing recycling bin
- `dumpster-overflow`: Overflowing dumpster

**Illegal Dumping**:
- `illegal-dumping`: Illegal waste dumping
- `illegal-dumping-large`: Large-scale illegal dumping
- `hazardous-waste`: Improperly disposed hazardous waste
- `construction-debris`: Illegally dumped construction debris

**Litter and Cleanup**:
- `litter-excessive`: Excessive litter
- `cleanup-needed`: Area needs cleaning
- `debris-accumulation`: Accumulated debris
- `beach-cleanup-needed`: Beach needs cleaning

**Biohazards**:
- `biohazard`: Biohazard material
- `needles`: Discarded needles/sharps
- `medical-waste`: Improper medical waste

### 14. Water Bodies

**Water Quality**:
- `water-pollution`: Water pollution
- `algae-bloom`: Algae bloom
- `fish-kill`: Dead fish
- `water-discoloration`: Discolored water

**Shoreline**:
- `erosion-shoreline`: Shoreline erosion
- `debris-waterway`: Debris in waterway
- `dock-damaged`: Damaged dock
- `pier-damaged`: Damaged pier

### 15. Buildings and Structures

**Building Hazards**:
- `building-damage`: Damaged building
- `building-collapse-risk`: Building collapse risk
- `wall-damaged`: Damaged wall
- `wall-graffiti`: Wall with graffiti
- `window-broken`: Broken window
- `door-damaged`: Damaged door
- `roof-damage`: Damaged roof
- `roof-leak`: Leaking roof

**Abandoned Buildings**:
- `building-abandoned`: Abandoned building
- `building-boarded`: Boarded up building
- `building-open`: Unsecured building

**Commercial/Industrial**:
- `loading-zone-blocked`: Blocked loading zone
- `dumpster-location`: Improperly placed dumpster

### 16. Safety Hazards

**Fire Hazards**:
- `fire`: Active fire (EMERGENCY)
- `fire-hazard`: Fire hazard
- `smoke`: Smoke source
- `burning-illegal`: Illegal burning

**Chemical/Environmental**:
- `spill-hazard`: Chemical/oil spill
- `spill-large`: Large spill (EMERGENCY)
- `fumes`: Hazardous fumes
- `dust-hazard`: Excessive dust hazard
- `air-quality`: Air quality concern

**Physical Hazards**:
- `sharp-object`: Exposed sharp objects
- `broken-glass`: Broken glass hazard
- `hole-hazard`: Dangerous hole or pit
- `tripping-hazard`: Trip hazard
- `slip-hazard`: Slippery conditions
- `fall-hazard`: Fall hazard

**Structural**:
- `structural-damage`: Structural damage concern
- `unstable-structure`: Unstable structure
- `retaining-wall-failure`: Failing retaining wall
- `sinkhole`: Sinkhole
- `cliff-erosion`: Eroding cliff/embankment

### 17. Parking

**Parking Infrastructure**:
- `parking-sign-damaged`: Damaged parking sign
- `parking-meter-broken`: Broken parking meter
- `parking-line-faded`: Faded parking lines
- `parking-surface-damaged`: Damaged parking surface

**Parking Enforcement**:
- `parking-obstruction`: Vehicle creating hazard
- `parking-disabled-violation`: Illegal use of disabled parking
- `parking-hydrant-blocked`: Vehicle blocking hydrant
- `parking-driveway-blocked`: Vehicle blocking driveway
- `parking-abandoned-vehicle`: Abandoned vehicle

### 18. Public Transportation

**Bus Stops**:
- `bus-stop-damaged`: Damaged bus stop
- `bus-stop-dirty`: Dirty bus stop
- `bus-shelter-damaged`: Damaged bus shelter
- `bus-bench-damaged`: Damaged bus bench
- `bus-sign-damaged`: Damaged bus stop sign

**Transit Infrastructure**:
- `transit-station-damage`: Damaged transit station
- `bike-rack-damaged`: Damaged bike rack
- `bike-lane-obstruction`: Bike lane obstruction
- `bike-lane-damaged`: Damaged bike lane

### 19. Animals

**Wildlife**:
- `dead-animal`: Dead animal removal needed
- `injured-animal`: Injured animal
- `dangerous-animal`: Potentially dangerous animal
- `animal-trapped`: Trapped animal

**Pests**:
- `pest-infestation`: Pest problem
- `rodent-issue`: Rodent problem
- `insect-infestation`: Insect infestation
- `bee-hive`: Problematic bee/wasp nest

**Stray Animals**:
- `stray-dog`: Stray dog
- `stray-cat`: Stray cat colony
- `animal-neglect`: Animal neglect/abuse

### 20. Weather and Natural Events

**Storm Damage**:
- `storm-damage`: Storm damage
- `wind-damage`: Wind damage
- `hail-damage`: Hail damage
- `tornado-damage`: Tornado damage
- `hurricane-damage`: Hurricane damage

**Winter Conditions**:
- `snow-removal-needed`: Snow removal needed
- `ice-hazard`: Icy conditions
- `snow-ice-mixed`: Mixed snow/ice hazard
- `snowplow-damage`: Damage from snowplow
- `ice-dam`: Ice dam issue

**Flooding**:
- `flooding`: Flooding
- `flood-damage`: Flood damage
- `flash-flood`: Flash flooding (EMERGENCY)
- `street-flooding`: Street flooding

**Other Weather**:
- `heat-hazard`: Extreme heat concern
- `drought-impact`: Drought impact
- `lightning-damage`: Lightning strike damage
- `earthquake-damage`: Earthquake damage

### 21. Accessibility

**ADA Compliance**:
- `accessibility-issue`: General accessibility problem
- `ramp-non-compliant`: Non-compliant accessibility ramp
- `sidewalk-accessible-issue`: Sidewalk accessibility issue
- `door-accessible-issue`: Inaccessible door
- `parking-accessible-issue`: Disabled parking issue
- `restroom-accessible-issue`: Restroom accessibility problem
- `signage-accessible-issue`: Missing/inadequate accessible signage

**Obstructions**:
- `wheelchair-obstruction`: Obstruction blocking wheelchair access
- `path-too-narrow`: Path too narrow for accessibility
- `elevator-broken`: Broken elevator (accessibility)

### 22. Noise and Odor

**Noise**:
- `noise-excessive`: Excessive noise
- `noise-construction`: Construction noise
- `noise-traffic`: Traffic noise issue
- `noise-industrial`: Industrial noise
- `noise-late-night`: Late-night noise disturbance

**Odor**:
- `odor-sewer`: Sewer odor
- `odor-gas`: Gas odor (EMERGENCY if strong)
- `odor-industrial`: Industrial odor
- `odor-waste`: Waste/garbage odor
- `odor-chemical`: Chemical odor

### 23. Security and Safety

**Lighting (Security)**:
- `lighting-inadequate`: Inadequate lighting (security concern)
- `dark-area`: Poorly lit area creating safety issue

**Suspicious Conditions**:
- `suspicious-package`: Suspicious package/object
- `suspicious-activity`: Suspicious activity

### 24. Other

**General Maintenance**:
- `needs-repair`: General repair needed
- `needs-maintenance`: Routine maintenance needed
- `needs-replacement`: Item needs replacement
- `needs-painting`: Painting needed
- `rust-corrosion`: Rust or corrosion issue
- `wear-tear`: General wear and tear

**Miscellaneous**:
- `other`: Other issue not categorized
- `request-service`: Service request
- `question`: Question about area/facility
- `suggestion`: Suggestion for improvement

## Photos and Media

### Photo Organization

Photos can be stored in multiple locations within a report:

1. **Report root folder** - Initial evidence photos by report author
2. **contributed-photos/** folder - Community contributed photos (anyone can add)
3. **updates/** folder - Progress photos attached to updates

**Example**:
```
38.7223_-9.1393_broken-sidewalk/
├── report.txt
├── photo1.jpg                      # Author's initial evidence
├── photo2.jpg                      # Author's different angle
├── close-up.jpg                    # Author's detail shot
├── contributed-photos/             # Community contributions
│   ├── CR7BBQ_2025-11-23_photo.jpg
│   ├── X135AS_2025-11-24_angle.jpg
│   └── BRAVO2_2025-11-24_detail.jpg
└── updates/
    └── 2025-11-25_repair-complete/
        ├── update.txt
        └── after-repair.jpg
```

### Community Contributed Photos

**contributed-photos/** Directory:
- **Purpose**: Allow any user to add additional evidence photos
- **Permissions**: Open to all authenticated users
- **Use Cases**:
  - Different angles of the same issue
  - Evidence of issue worsening over time
  - Confirmation photos from other community members
  - Updated photos showing current state

**Photo Naming Convention**:
- Format: `{CALLSIGN}_{YYYY-MM-DD}_{description}.jpg`
- Examples:
  - `CR7BBQ_2025-11-23_different-angle.jpg`
  - `X135AS_2025-11-24_now-worse.jpg`
  - `BRAVO2_2025-11-24_confirmed.jpg`

**Metadata File** (Optional):
Each contributed photo can have an optional metadata file with same name + `.txt`:

```
contributed-photos/CR7BBQ_2025-11-23_different-angle.jpg
contributed-photos/CR7BBQ_2025-11-23_different-angle.jpg.txt
```

**Metadata Format**:
```
CONTRIBUTED_BY: CR7BBQ
CONTRIBUTED_AT: 2025-11-23 14:00_00
COORDINATES: 38.7223,-9.1393

Photo taken from the north side showing the crack
extends further than initially reported.

--> npub: npub1abc...
--> signature: hex_sig
```

**Moderation**:
- Admins and moderators can hide inappropriate contributed photos
- Hidden photos moved to `.hidden/contributed-photos/`
- Original contributor notified

### Supported Media Types

**Images**:
- JPG, JPEG, PNG, WebP
- Recommended: JPG for photos
- Any resolution (high resolution recommended for evidence)

**Videos**:
- MP4, WebM
- Short clips (under 2 minutes)
- Useful for showing moving hazards

**Documents**:
- PDF for official reports or correspondence
- TXT for additional notes

### Individual Photo Reactions

Each photo can have its own likes and comments:

**Reaction File**: `.reactions/photo-name.jpg.txt`

**Format**:
```
LIKES: CR7BBQ, X135AS, BRAVO2

> 2025-11-23 14:00_00 -- CR7BBQ
This clearly shows the extent of the damage.
--> npub: npub1abc...
--> signature: hex_sig
```

## Photo Guidelines

### Overview

Quality photos are essential for effective reports. Clear, well-composed photos help authorities understand the issue and provide evidence of the problem.

### Recommended Photo Practices

**What to Photograph**:
1. **Wide shot**: Overall context showing the problem in its environment
2. **Medium shot**: The specific issue from a clear angle
3. **Close-up**: Details of the damage or hazard
4. **Reference markers**: Include landmarks, street signs, or building numbers
5. **Scale reference**: Include objects for size comparison (optional)
6. **Multiple angles**: Different perspectives of the same issue

**Technical Guidelines**:
- **Resolution**: Minimum 1280x720, recommended 1920x1080 or higher
- **Focus**: Ensure the issue is in sharp focus
- **Lighting**: Take photos in good lighting conditions when possible
- **Orientation**: Use appropriate orientation (landscape or portrait)
- **Timestamp**: Enable camera timestamp if available
- **GPS**: Enable GPS tagging for automatic location verification

**What to Avoid**:
- Blurry or out-of-focus images
- Photos taken in darkness without adequate lighting
- Photos that don't clearly show the reported issue
- Photos with people's faces (privacy concerns)
- Photos of private property interiors (unless necessary and with permission)

### Photo Metadata

**Automatic Extraction**:
- GPS coordinates (verify against COORDINATES field)
- Timestamp (verify against CREATED field)
- Camera make/model
- Image resolution

**Validation**:
- Compare photo GPS with report coordinates (should be within 100m)
- Flag photos with coordinates >100m away as "external reference"
- Check photo timestamp is reasonable relative to report creation

### Before/After Documentation

**Best Practice for Resolution**:
```
Initial Report:
- before-wide.jpg (wide shot showing problem)
- before-detail.jpg (close-up of issue)

Resolution Update:
- updates/2025-11-26_repair-complete/
  - after-wide.jpg (same angle as before-wide.jpg)
  - after-detail.jpg (same angle as before-detail.jpg)
```

**Comparison Tips**:
- Take "after" photos from same position as "before" photos
- Use same time of day if possible (similar lighting)
- Include same reference markers
- Shows clear evidence of resolution

## Verification System

### Overview

Community members can verify/confirm reports they have personally witnessed or experienced. Verification increases report credibility and helps authorities prioritize genuine issues.

### Verification Process

**How to Verify**:
1. User views report
2. If they have witnessed the same issue, clicks "Verify/Confirm"
3. System adds their npub to VERIFIED_BY list
4. Increments VERIFICATION_COUNT
5. Optionally adds verification comment

**Verification Criteria**:
- User must have different npub than report author
- User can verify each report only once
- Verification requires signature
- User should have personally witnessed the issue

### Verification Fields

**VERIFIED_BY**:
- Comma-separated list of npub values
- Each npub represents one verifier
- Format: `VERIFIED_BY: npub1user1..., npub1user2..., npub1user3...`

**VERIFICATION_COUNT**:
- Integer count of verifications
- Auto-calculated from VERIFIED_BY list length
- Format: `VERIFICATION_COUNT: 3`

### Verification Levels

**Classification by Verification Count**:
- **Unverified** (0): Only reporter, needs confirmation
- **Confirmed** (1-2): Some community confirmation
- **Well-Confirmed** (3-5): Multiple witnesses
- **Highly Verified** (6+): Widely witnessed issue

**UI Display**:
- Show verification count prominently
- Badge system:
  - ⚠️ Unverified (gray)
  - ✓ Confirmed (green)
  - ✓✓ Well-Confirmed (blue)
  - ✓✓✓ Highly Verified (gold)

### Verification Comments

Users can add verification comments:

```
.reactions/report.txt:

> 2025-11-23 12:00_00 -- X135AS
Can confirm - I almost tripped here yesterday! Still broken as of this morning.
--> verification: true
--> npub: npub1xyz...
--> signature: hex_sig
```

**Verification Metadata**: `--> verification: true`

### Anti-Spam Measures

**Verification Limits**:
- Require account age >7 days for verification
- Rate limit: Max 20 verifications per day per user
- Flag suspicious patterns (same users verifying same author's reports)
- Moderators can remove fake verifications

## Duplicate Detection

### Overview

Multiple users may report the same issue. The duplicate detection system helps consolidate reports and prevent clutter.

### Detection Criteria

**Automatic Detection**:
- **Distance**: Within 50 meters of existing report
- **Type**: Same report TYPE
- **Time Window**: Created within 7 days of each other
- **Severity**: Same or similar severity level

**Similarity Scoring**:
```
Score = 0
if distance < 50m: Score += 40
if same TYPE: Score += 30
if within 7 days: Score += 20
if same SEVERITY: Score += 10

if Score >= 60: Suggest as duplicate
if Score >= 80: Strong duplicate match
```

### Duplicate Linking

**DUPLICATE_OF Field**:
- Points to the "primary" report (usually the earliest)
- Format: `DUPLICATE_OF: 38.7223_-9.1393_broken-sidewalk`
- Marks this report as duplicate

**RELATED_REPORTS Field**:
- Lists related but not identical reports
- Format: `RELATED_REPORTS: 38.7220_-9.1390_cracked-curb, 38.7225_-9.1395_tree-damage`
- Useful for tracking clustered issues

### Duplicate Workflow

**When Creating New Report**:
1. System searches for similar reports within 100m
2. If matches found, show list to user
3. User can:
   - Confirm it's new/different issue
   - Mark as duplicate of existing report
   - Add as related report

**Marking as Duplicate**:
```
1. Add DUPLICATE_OF: field to new report
2. Set STATUS: closed
3. Add comment linking to primary report
4. Update VERIFICATION_COUNT on primary report
5. Transfer photos to primary report (optional)
```

**Merging Duplicates**:
- Admin can merge duplicate reports
- Combine photos from all duplicates
- Consolidate comments
- Update verification count
- Keep all original reports linked

### UI Display

**Duplicate Badge**:
- Show "Duplicate" badge on duplicate reports
- Link to primary report
- Show all linked duplicates on primary report
- Cluster view on map for related issues

## Authority Integration

### Overview

Integration with official authorities and reporting systems. Track when authorities are notified and monitor official case status.

### Notification Tracking

**AUTHORITY_NOTIFIED Field**:
- Records which authority was notified
- Includes timestamp
- Format: `AUTHORITY_NOTIFIED: <authority>, <timestamp>`
- Multiple notifications separated by semicolon

**Examples**:
```
AUTHORITY_NOTIFIED: Fire Department, 2025-11-23 14:30_00

AUTHORITY_NOTIFIED: City Maintenance, 2025-11-23 10:00_00; Police Department, 2025-11-23 10:15_00
```

**Supported Authorities**:
- Fire Department
- Police Department
- City Maintenance / Public Works
- Emergency Services (911/112)
- Environmental Protection Agency
- Health Department
- Animal Control
- Transportation Department
- Utilities Company

### Official Case Number

**OFFICIAL_CASE Field**:
- Tracks the case/ticket number from official system
- Format: `OFFICIAL_CASE: <case-number>`
- Allows cross-referencing with government systems

**Examples**:
```
OFFICIAL_CASE: FIRE-2025-1234
OFFICIAL_CASE: NYC-311-20251123-5678
OFFICIAL_CASE: MAINTENANCE-REQ-789
```

### API Integration (Future)

**Potential Integrations**:
- **311 Systems**: Auto-submit reports to city 311 systems
- **FixMyStreet**: Export to FixMyStreet platforms
- **SeeClickFix**: Integration with SeeClickFix
- **Custom APIs**: Municipality-specific APIs

**Bi-directional Sync**:
- Export report to official system → receive case number
- Monitor case status → update report STATUS automatically
- Official resolution → add resolution update

### Notification Templates

**Emergency Template**:
```
Subject: Emergency Report - {TYPE} at {ADDRESS}
Severity: EMERGENCY
Location: {COORDINATES} - {ADDRESS}
Description: {CONTENT}
Reported by: {AUTHOR}
Photos: [links]
Geogram Report ID: {FOLDER_NAME}
```

**Non-Emergency Template**:
```
Subject: Public Issue Report - {TYPE}
Severity: {SEVERITY}
Location: {COORDINATES} - {ADDRESS}
Description: {CONTENT}
Reported: {CREATED}
Verified by: {VERIFICATION_COUNT} community members
Photos: [links]
Geogram Report ID: {FOLDER_NAME}
```

## Subscription System

### Overview

Users can subscribe to reports to receive notifications about important events such as status changes, new updates, resolution, or when the report is closed.

### Subscribing to Reports

**How to Subscribe**:
1. User views a report
2. Clicks "Subscribe" button
3. Their npub is added to SUBSCRIBERS list
4. SUBSCRIBER_COUNT incremented
5. User receives confirmation

**Subscription Options**:
- Subscribe to all events
- Subscribe to specific events only (status changes, resolution, closure)
- Set notification preferences (immediate, daily digest, weekly digest)

### Notification Events

**Trigger Events**:
- **Status Change**: When STATUS field changes (open → in-progress → resolved → closed)
- **New Update**: When an update is added to updates/ folder
- **New Photo**: When photo is added to contributed-photos/
- **Verification Milestone**: When verification count reaches thresholds (5, 10, 20+)
- **Resolution**: When STATUS changes to resolved
- **Closure**: When STATUS changes to closed
- **Expiration Warning**: 7 days before TTL expiration
- **Authority Response**: When AUTHORITY_NOTIFIED or OFFICIAL_CASE added
- **Admin Comment**: When admin adds important comment

### Notification Format

**Email Notification Example**:
```
Subject: [Geogram] Report Update: Broken Sidewalk - Status Changed

Report: Broken Sidewalk
Location: Main Street near Café Central, Lisbon
Severity: ATTENTION
Status: OPEN → IN-PROGRESS

Update:
City maintenance crew has been dispatched. Repair work
scheduled to begin tomorrow morning.

View full report: [link]
Unsubscribe: [link]
```

**In-App Notification Example**:
```
🔔 Report Update
Broken Sidewalk (Main Street)
Status changed: OPEN → IN-PROGRESS
2 hours ago
[View Report]
```

### Managing Subscriptions

**Subscribe Field**:
- Added to report.txt SUBSCRIBERS field
- Format: `SUBSCRIBERS: npub1user1..., npub1user2...`
- Auto-updated when users subscribe/unsubscribe

**Unsubscribe**:
- User clicks unsubscribe in notification
- Or unsubscribes from report view
- Their npub removed from SUBSCRIBERS list
- SUBSCRIBER_COUNT decremented

**View Subscribers** (Admins only):
- Admins can see list of subscribers
- Useful for gauging community interest
- Subscriber count is public

### Subscription Privacy

**Privacy Considerations**:
- Subscriber list visible only to report admins
- SUBSCRIBER_COUNT is public
- Individual users can see their own subscriptions
- No public list of who is subscribed

## News Log System

### Overview

The news log provides a chronological record of all significant events in a report's lifecycle. It serves as a public timeline that anyone can read to understand what has happened from creation to resolution.

### News Log File

**Location**: `<report-folder>/news.txt`

**Structure**:
```
# NEWS LOG: Broken Sidewalk

> 2025-11-23 10:00_00
Report created by CR7BBQ
Severity: ATTENTION | Type: sidewalk-damage
Location: Main Street near Café Central, Lisbon

> 2025-11-23 12:30_00
3 community members verified this report

> 2025-11-24 09:00_00 -- CITY_MAINTENANCE (Fire Department)
City maintenance notified. Work order #12345 created.
Crew dispatched to assess damage.
--> npub: npub1citymaint...
--> signature: hex_sig

> 2025-11-24 14:00_00 -- CR7BBQ
Added 2 contributed photos showing crack extension

> 2025-11-25 08:00_00 -- FIRE_DEPT (Fire Department)
Repair work has begun. Area cordoned off for safety.
Expected completion: End of day.
--> npub: npub1firedept...
--> signature: hex_sig

> 2025-11-25 18:00_00 -- CITY_MAINTENANCE (City Maintenance)
Repair completed. New concrete poured.
Area will reopen tomorrow after curing.
STATUS: RESOLVED
--> npub: npub1citymaint...
--> signature: hex_sig

> 2025-11-26 09:00_00
Report closed. Issue successfully resolved.
```

### News Entry Format

**Automatic Entries** (system-generated):
```
> YYYY-MM-DD HH:MM_ss
Event description
```

**Manual Entries** (by authorized users):
```
> YYYY-MM-DD HH:MM_ss -- CALLSIGN (Entity Group)
Entry content describing the update or action taken.
Can span multiple lines.
--> npub: npub1...
--> signature: hex_sig
```

### Automatic News Events

Events automatically added to news log:

1. **Report Created**
   ```
   > 2025-11-23 10:00_00
   Report created by CR7BBQ
   Severity: URGENT | Type: pothole
   ```

2. **Verification Milestones**
   ```
   > 2025-11-23 14:00_00
   5 community members verified this report
   ```

3. **Status Changes**
   ```
   > 2025-11-24 09:00_00
   Status changed: OPEN → IN-PROGRESS
   ```

4. **Authority Notification**
   ```
   > 2025-11-24 10:00_00
   Fire Department notified
   Official case: FIRE-2025-1234
   ```

5. **Community Milestones**
   ```
   > 2025-11-24 16:00_00
   10 subscribers following this report
   ```

6. **Photo Contributions**
   ```
   > 2025-11-25 11:00_00
   X135AS contributed 2 additional photos
   ```

7. **Resolution**
   ```
   > 2025-11-26 15:00_00
   Report marked as RESOLVED by CR7BBQ
   ```

8. **Closure**
   ```
   > 2025-11-27 09:00_00
   Report closed
   ```

### Manual News Entries

**Who Can Add News Entries**:
1. Report admins (author + ADMINS field)
2. Users in UPDATE_AUTHORIZED field
3. Users belonging to Official Entity Groups (see next section)

**Adding a News Entry**:
- Authorized user composes update
- Signs with their npub
- Entry appended to news.txt
- All subscribers notified
- Entry appears in report timeline

**Entry Guidelines**:
- Be clear and concise
- State what action was taken or what changed
- Include relevant details (timeline, next steps)
- Professional tone for official entities
- Sign all manual entries

### News vs Updates

**News Log** (`news.txt`):
- Public timeline for everyone
- Short, chronological entries
- Mix of automatic and manual entries
- Easy to scan entire history
- Always visible

**Updates** (`updates/` folder):
- Detailed status updates
- Full files with photos
- Can be lengthy
- Official documentation of progress
- Requires more effort to review all

**When to Use Each**:
- Use **News** for quick updates, announcements, timeline events
- Use **Updates** for detailed progress reports with photos and documentation
- Both can be used together - updates can be summarized in news log

## Official Entity Groups

### Overview

Official entity groups are globally or relay-defined groups of users representing official organizations (fire departments, city maintenance, schools, etc.) who automatically have permission to add updates and news entries to reports in their domain.

### Group Definition

**Configuration File**: `config/entity-groups.txt` (relay-level or global)

**Format**:
```
# ENTITY_GROUP: Fire Department
GROUP_ID: fire-department
MEMBERS: npub1firefighter1..., npub1firefighter2..., npub1chief...
REPORT_TYPES: fire-hazard, fire, smoke, burning-illegal, spill-hazard
AUTO_AUTHORIZE: true
BADGE: 🚒
DESCRIPTION: Official fire department personnel

# ENTITY_GROUP: City Maintenance
GROUP_ID: city-maintenance
MEMBERS: npub1worker1..., npub1supervisor..., npub1inspector...
REPORT_TYPES: pothole, pavement-damage, sidewalk-damage, streetlight-out, road-damage-general
AUTO_AUTHORIZE: true
BADGE: 🔧
DESCRIPTION: City public works and maintenance

# ENTITY_GROUP: Police Department
GROUP_ID: police-department
MEMBERS: npub1officer1..., npub1officer2...
REPORT_TYPES: vandalism, graffiti, suspicious-activity, parking-obstruction
AUTO_AUTHORIZE: true
BADGE: 👮
DESCRIPTION: Local police department

# ENTITY_GROUP: School District
GROUP_ID: school-district
MEMBERS: npub1principal..., npub1facilities...
REPORT_TYPES: playground-broken, school-related, accessibility-issue
AUTO_AUTHORIZE: true
BADGE: 🏫
DESCRIPTION: School district facilities management

# ENTITY_GROUP: Environmental Services
GROUP_ID: environmental-services
MEMBERS: npub1enviro1..., npub1inspector...
REPORT_TYPES: illegal-dumping, water-pollution, hazardous-waste, biohazard
AUTO_AUTHORIZE: true
BADGE: 🌱
DESCRIPTION: Environmental protection and services
```

### Group Fields

**GROUP_ID**: Unique identifier for the group

**MEMBERS**: List of npubs who are members of this group

**REPORT_TYPES**: Types of reports this group is automatically authorized for
- Can be specific types or wildcards
- `*` means all report types
- Multiple types comma-separated

**AUTO_AUTHORIZE**:
- `true`: Group members automatically added to UPDATE_AUTHORIZED for matching reports
- `false`: Group exists but requires manual authorization per report

**BADGE**: Emoji or symbol displayed next to group member names

**DESCRIPTION**: Human-readable description of the group

### Automatic Authorization

**How it Works**:
1. User creates report with TYPE: pothole
2. System checks entity-groups.txt
3. Finds "City Maintenance" group has REPORT_TYPES including pothole
4. AUTO_AUTHORIZE is true
5. All members of City Maintenance group automatically can add updates/news
6. No need to manually add them to UPDATE_AUTHORIZED field

**Benefits**:
- Official responders can immediately update reports
- No waiting for report author to grant permission
- Streamlined communication
- Community knows who official responders are

### Group Member Display

When a group member adds news or updates:
```
> 2025-11-25 14:00_00 -- WORKER123 (🔧 City Maintenance)
Repair scheduled for tomorrow morning at 8:00 AM.
Crew will need 2-3 hours to complete the work.
--> npub: npub1worker123...
--> signature: hex_sig
```

**UI Display**:
- User's callsign shown
- Group badge and name in parentheses
- Clearly identifies official personnel
- Builds trust with community

### Managing Entity Groups

**Adding Members**:
- Update entity-groups.txt config file
- Add npub to MEMBERS list
- Changes take effect immediately

**Removing Members**:
- Remove npub from MEMBERS list
- User loses authorization for future reports
- Existing entries remain signed by them

**Creating New Groups**:
- Add new ENTITY_GROUP section
- Define members, report types, authorization
- Can be very specific (e.g., "Park Rangers" for park-related reports)

### Per-Report Override

Even with entity groups, report admins can:
- Explicitly grant additional users via UPDATE_AUTHORIZED field
- Remove authorization (though group members may regain via AUTO_AUTHORIZE)
- Have final control over their reports

## Report Updates

### Overview

As the situation changes or work progresses, updates can be added to track the report's progress.

### Updates Directory

**Location**: `<report-folder>/updates/`

**Structure**:
```
38.7223_-9.1393_broken-sidewalk/
├── report.txt
└── updates/
    ├── 2025-11-24_authorities-notified.txt
    ├── 2025-11-25_repair-started.txt
    └── 2025-11-26_repair-completed.txt
```

### Update File Format

**Filename Pattern**: `YYYY-MM-DD_brief-description.txt`

**Format**:
```
# UPDATE: Brief Update Title

UPDATED: YYYY-MM-DD HH:MM_ss
AUTHOR: CALLSIGN
NEW_STATUS: in-progress|resolved|closed (optional)

Description of the update.

Details about what changed, progress made,
or new information about the reported issue.

--> npub: npub1...
--> signature: hex_sig
```

**Example**:
```
# UPDATE: Repair Work Started

UPDATED: 2025-11-25 09:00_00
AUTHOR: X135AS
NEW_STATUS: in-progress

City maintenance crew arrived this morning.
They have cordoned off the area and begun
repairing the broken sidewalk.

Expected completion: end of day.

--> npub: npub1xyz...
--> signature: hex_sig123
```

### Status Transitions

Updates can change the report status:

**Workflow**:
```
open → in-progress  (work has started)
in-progress → resolved  (issue fixed)
resolved → closed  (verified and confirmed)
open → closed  (no action needed/duplicate/invalid)
```

## Resolution Tracking

### Marking as Resolved

When the issue is fixed:

**Resolution Update**:
```
# UPDATE: Issue Resolved

UPDATED: 2025-11-26 15:30_00
AUTHOR: CR7BBQ
NEW_STATUS: resolved

The sidewalk has been fully repaired.
New concrete poured and area is now safe.

Attaching photo of completed work.

--> npub: npub1abc...
--> signature: hex_sig
```

### Before/After Photos

**Recommended Practice**:
1. Initial report: photos showing the problem
2. Resolution update: photos showing the fix
3. Clear visual documentation of issue → resolution

**Example**:
```
report.txt
problem-photo1.jpg        # Before
problem-photo2.jpg        # Before
updates/
└── 2025-11-26_resolved/
    ├── update.txt
    ├── after-photo1.jpg  # After
    └── after-photo2.jpg  # After
```

## Expiration and TTL

### Overview

Reports can have an expiration time (TTL - Time To Live) after which they are automatically closed or archived. This prevents stale reports from cluttering the system.

### TTL Field

**Format**: `TTL: <seconds>`

**Common Values**:
- `604800` (7 days) - For temporary conditions
- `2592000` (30 days) - Default for most reports
- `7776000` (90 days) - For long-term infrastructure issues
- `31536000` (365 days) - For persistent problems

**Examples**:
```
TTL: 604800
TTL: 2592000
```

### Expiration Timestamp

**EXPIRES Field**:
- Auto-calculated: CREATED + TTL
- Format: `EXPIRES: YYYY-MM-DD HH:MM_ss`
- Example: `EXPIRES: 2025-12-23 10:00_00`

**Calculation**:
```
Created: 2025-11-23 10:00_00
TTL: 2592000 (30 days)
→ Expires: 2025-12-23 10:00_00
```

### Expiration Behavior

**What Happens at Expiration**:

**For Open Reports**:
1. STATUS changes from `open` to `closed`
2. Auto-comment added: "Report expired without resolution"
3. Report stays visible but marked as expired
4. Can be manually re-opened if issue persists

**For In-Progress Reports**:
1. Send notification to admins
2. Extend TTL by 30 days automatically (one-time extension)
3. Add comment noting extension
4. If still in-progress after extension, close as expired

**For Resolved Reports**:
1. No action needed
2. Report stays resolved

**For Closed Reports**:
1. No action needed
2. Already closed

### TTL Override

**Manual Override**:
- Admins can modify TTL at any time
- Can extend expiration
- Can set TTL: 0 for "never expires"
- Requires update with signature

**Example Override**:
```
# UPDATE: Extending Report Expiration

UPDATED: 2025-12-20 09:00_00
AUTHOR: CR7BBQ
NEW_TTL: 7776000

Issue still not resolved. Extending expiration by 90 more days
to ensure it remains tracked until fixed.

--> npub: npub1abc...
--> signature: hex_sig
```

### Archival to Expired Directory

**Automatic Move to expired/**:
When reports expire or are closed:
1. Entire report folder moved from `active/{region}/` to `expired/{region}/`
2. Maintains same folder structure and region organization
3. Preserves all content: report.txt, photos, updates, reactions
4. Not shown in active/standard views
5. Still searchable in historical/expired views
6. Can be restored to active/ by admins if needed

**Move Triggers**:
- TTL expiration with STATUS: closed
- Manual closure with retention period elapsed
- Resolved reports after configured period (e.g., 90 days)
- Admin manual deactivation

**Example**:
```
Before:
active/38.7_-9.1/38.7223_-9.1393_broken-sidewalk/

After expiration:
expired/38.7_-9.1/38.7223_-9.1393_broken-sidewalk/
```

## Priority Queue

### Overview

System for prioritizing reports based on multiple factors, helping authorities and responders focus on most critical issues first.

### Priority Score Calculation

**Scoring Algorithm**:
```
Priority Score = Severity Weight + Age Weight + Verification Weight

Severity Weight:
- emergency: 1000
- urgent: 500
- attention: 100
- info: 10

Age Weight (days since created):
- 0-1 days: +50
- 1-3 days: +30
- 3-7 days: +10
- 7-30 days: +5
- 30+ days: +0

Verification Weight:
- Unverified (0): +0
- Confirmed (1-2): +20
- Well-Confirmed (3-5): +40
- Highly Verified (6+): +60
```

**Example Calculation**:
```
Report A:
- SEVERITY: emergency (1000)
- Age: 2 days (+30)
- Verifications: 5 (+40)
→ Priority Score: 1070

Report B:
- SEVERITY: attention (100)
- Age: 0.5 days (+50)
- Verifications: 8 (+60)
→ Priority Score: 210

Report A has higher priority and should be addressed first.
```

### Queue Ordering

**Primary Sort**: Priority Score (descending)

**Tie-breaker**: Created timestamp (oldest first)

**Filter Options**:
- By SEVERITY
- By TYPE
- By geographic region
- By STATUS
- By verification level

### Geographic Clustering

**Cluster Detection**:
- Group reports within 200m of each other
- Same TYPE
- Similar SEVERITY

**Cluster Priority**:
- Cluster Priority = Sum of individual priorities
- Clusters bubble to top of queue
- Indicates widespread problem area

**Example**:
```
Cluster: Downtown Sidewalk Issues
- 5 reports within 150m radius
- All TYPE: sidewalk-damage
- Total Priority: 520
- Indicates systemic sidewalk problem requiring area-wide repair
```

### UI Display

**Queue View**:
```
Priority Queue - City Maintenance

[Emergency] Gas Leak - Main Street (Score: 1050)
  Created: 2 hours ago | Verified by 3 users

[Cluster: 5 reports] Downtown Sidewalk Issues (Score: 520)
  Multiple cracked sidewalks in same area

[Urgent] Missing Manhole Cover - Highway 101 (Score: 550)
  Created: 4 hours ago | Verified by 1 user
```

## Analytics and Statistics

### Overview

Comprehensive analytics to understand reporting patterns, response times, and problem areas.

### Report Statistics

**Overall Metrics**:
- Total reports: All-time count
- Open reports: Currently unresolved
- Resolved reports: Successfully fixed
- Closed reports: No action taken
- Average response time: Time from creation to in-progress
- Average resolution time: Time from creation to resolved
- Verification rate: % of reports with at least one verification

**By Severity**:
- Count per severity level
- Average response time per severity
- Resolution rate per severity

**By Type**:
- Count per report type
- Most common types
- Least resolved types

**By Region**:
- Reports per geographic region
- Hot spots (high concentration areas)
- Cold spots (low reporting areas)

### Heat Maps

**Issue Heat Map**:
- Geographic visualization of report density
- Color-coded by severity
- Time-based filtering (last 7 days, 30 days, all-time)
- Type filtering (show only specific types)

**Resolution Heat Map**:
- Shows where issues are being resolved
- Highlights areas with poor resolution rates
- Identifies effective vs. ineffective authorities

### Time-Based Analytics

**Reporting Trends**:
- Reports per day/week/month
- Peak reporting times
- Seasonal patterns
- Trend lines (increasing/decreasing)

**Response Time Trends**:
- Average time to first response
- Improving or declining response times
- Comparison by authority/region

### User Analytics

**Top Reporters**:
- Users with most reports
- Quality score (verification rate of their reports)
- Resolution rate of their reports

**Top Verifiers**:
- Users who verify most reports
- Contribution to community credibility

**Authority Performance**:
- Response times by authority
- Resolution rates
- User satisfaction (based on comments)

### Export Capabilities

**Data Export**:
- CSV export of all reports
- Filtered exports (by date, severity, type, region)
- Statistics summary export
- GeoJSON for mapping applications

**API Access**:
- REST API for retrieving statistics
- Real-time dashboards
- Integration with BI tools

### Dashboard Views

**Public Dashboard**:
```
Community Reporting Dashboard

Total Reports: 1,247
Open: 234 | In Progress: 89 | Resolved: 892 | Closed: 32

Top Issues:
1. Sidewalk Damage (187 reports)
2. Potholes (145 reports)
3. Streetlights Broken (98 reports)

Hot Spots (Last 30 Days):
- Downtown District: 67 reports
- Waterfront Area: 45 reports
- Industrial Zone: 23 reports

Average Response Time: 2.3 days
Average Resolution Time: 14.7 days
```

**Authority Dashboard**:
```
City Maintenance Dashboard

Assigned to You: 34 reports
Priority Queue: [View all]

High Priority:
- [Emergency] 2 reports needing immediate attention
- [Urgent] 8 reports requiring prompt response

Response Time Stats:
- Your average: 1.8 days (↓ 0.3 from last month)
- City average: 2.3 days
- Your resolution rate: 87% (↑ 5% from last month)
```

## Reactions System

### Overview

Users can react to reports and photos:
- Like the report
- Comment on report
- Like individual photos
- Comment on photos

### Reactions Directory

**Location**: `<report-folder>/.reactions/`

**Files**:
- `report.txt`: Reactions on the report itself
- `photo-name.jpg.txt`: Reactions on specific photo

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

### Report Reactions Example

```
.reactions/report.txt:
LIKES: X135AS, BRAVO2, ALPHA1

> 2025-11-23 12:00_00 -- X135AS
Thanks for reporting this! I almost tripped here yesterday.
--> npub: npub1xyz...
--> signature: hex_sig

> 2025-11-23 14:30_00 -- BRAVO2
I've contacted the city about this issue.
--> npub: npub1bravo...
--> signature: hex_sig
```

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
   - Format: `> YYYY-MM-DD HH:MM_ss -- CALLSIGN`
   - Starts with `>` followed by space

2. **Content** (required)
   - Plain text, multiple lines allowed

3. **Metadata** (optional)
   - npub and signature

### Comment Locations

- **Report comments**: `.reactions/report.txt`
- **Photo comments**: `.reactions/photo.jpg.txt`
- **Update comments**: `.reactions/updates/update-file.txt`

## Permissions and Roles

### Roles

#### Report Author

The user who created the report (AUTHOR field). **The author is automatically an administrator** of the report with full control.

**Permissions**:
- Edit report.txt (modify description, fields)
- Add updates to updates/ folder
- Add entries to news.txt log
- Upload additional photos to report root
- Add/remove other admins and moderators
- Manage UPDATE_AUTHORIZED list (grant update permissions)
- **Hide/remove inappropriate photos** (from root, contributed-photos/, updates/)
- Hide/remove inappropriate comments
- Close report
- Move report to expired/
- Delete report entirely

#### Admins

Additional administrators listed in ADMINS field. Have nearly all permissions of the report author.

**Permissions**:
- Edit report.txt
- Add updates to updates/ folder
- Add entries to news.txt log
- Upload photos to report root and updates/
- **Hide/remove inappropriate photos** (from root, contributed-photos/, updates/)
- Hide/remove inappropriate comments
- Manage UPDATE_AUTHORIZED list (grant update permissions)
- View subscriber list
- Close report

#### Moderators

Users with moderation privileges listed in MODERATORS field.

**Permissions**:
- Hide comments (move to .hidden/)
- Hide photos (move to .hidden/) from any folder
- View moderation log
- Cannot edit report.txt
- Cannot add updates or news entries
- Cannot close report

#### Update Authorized Users

Users listed in UPDATE_AUTHORIZED field or members of Official Entity Groups with AUTO_AUTHORIZE for this report type.

**Permissions**:
- **Add updates** to updates/ folder
- **Add news entries** to news.txt log
- View full report
- Comment on report
- Cannot edit report.txt
- Cannot hide content
- Cannot close report

**Examples**:
- Fire department personnel on fire-related reports
- City maintenance workers on infrastructure reports
- School facilities staff on playground issues
- Environmental inspectors on pollution reports

**Display**:
- Identified with entity group badge in news entries and updates
- Clearly marked as official personnel
- Builds community trust

#### Community Members

All authenticated users (not report author, admins, moderators, or update authorized).

**Permissions**:
- **View report**: Access all report details, photos, updates, and news
- **Subscribe**: Receive notifications about report events
- **Like report**: Add like to report
- **Like photos**: Add likes to any photo (author's or contributed)
- **Comment on report**: Add comments to report
- **Comment on photos**: Add comments on any photo
- **Contribute photos**: Upload photos to `contributed-photos/` folder (no approval needed)
- **Verify report**: Add verification/confirmation if they witnessed the issue
- **Add to favorites**: Bookmark/favorite reports for tracking
- **Share report**: Share report link with others

**Important Notes**:
- Photo contributions are immediate and public
- Inappropriate photos can be hidden by admins/moderators after the fact
- All contributions require authentication and signatures
- Users should only contribute relevant, appropriate photos
- Subscriptions are private (only subscriber count is public)

## Moderation System

### Overview

Admins and moderators can hide inappropriate content without permanently deleting it.

### Hidden Content Directory

**Location**: `<report-folder>/.hidden/`

**Structure**:
```
.hidden/
├── comments/
│   └── report_comment_20251123_120000_SPAMMER.txt
├── files/
│   └── inappropriate-photo.jpg
├── contributed-photos/
│   └── SPAMMER_2025-11-23_inappropriate.jpg
└── moderation-log.txt
```

**What Can Be Hidden**:
- Report comments
- Photo comments
- Author's photos (from report root)
- Community contributed photos (from contributed-photos/)
- Update photos

### Moderation Log

**File**: `.hidden/moderation-log.txt`

**Format**:
```
> 2025-11-23 16:00_00 -- MODERATOR1 (moderator)
ACTION: hide_comment
TARGET: report.txt
AUTHOR: SPAMMER
REASON: Spam comment
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

**Report Signature**:
```
--> npub: npub1abc123...
--> signature: hex_signature
```

**Comment Signature**:
```
> 2025-11-23 14:30_00 -- CR7BBQ
Great report!
--> npub: npub1abc...
--> signature: hex_sig
```

## Integration Features

### Overview

The reports system supports multiple integration methods for interoperability with external systems, mapping applications, and data analysis tools.

### GeoJSON Export

**Format**: Standard GeoJSON FeatureCollection

**Structure**:
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [-9.1393, 38.7223]
      },
      "properties": {
        "id": "38.7223_-9.1393_broken-sidewalk",
        "title": "Broken Sidewalk",
        "description": "Large crack in sidewalk creating trip hazard...",
        "severity": "attention",
        "type": "sidewalk-damage",
        "status": "open",
        "created": "2025-11-23T10:00:00Z",
        "author": "CR7BBQ",
        "verified_by": 3,
        "address": "Main Street near Café Central, Lisbon",
        "photos": [
          "photo1.jpg",
          "photo2.jpg"
        ]
      }
    }
  ]
}
```

**Use Cases**:
- Import into GIS applications (QGIS, ArcGIS)
- Display on web maps (Leaflet, Mapbox, Google Maps)
- Spatial analysis
- City planning tools

### CSV Export

**Format**: Comma-separated values with headers

**Columns**:
```
id,created,author,coordinates_lat,coordinates_lon,severity,type,status,address,description,verification_count,photos_count,official_case
```

**Example**:
```csv
id,created,author,coordinates_lat,coordinates_lon,severity,type,status,address,description,verification_count,photos_count,official_case
38.7223_-9.1393_broken-sidewalk,2025-11-23 10:00:00,CR7BBQ,38.7223,-9.1393,attention,sidewalk-damage,open,"Main Street near Café Central, Lisbon","Large crack in sidewalk creating trip hazard",3,2,
```

**Use Cases**:
- Import into spreadsheets (Excel, Google Sheets)
- Database imports
- Statistical analysis
- Report generation

### RSS/Atom Feeds

**Purpose**: Real-time notification of new reports

**Feed Types**:
- All reports feed
- Filtered by severity
- Filtered by type
- Filtered by region
- Filtered by status

**Example Feed URL**:
```
https://geogram.example.com/reports/feed/rss
https://geogram.example.com/reports/feed/rss?severity=emergency
https://geogram.example.com/reports/feed/rss?region=38.7_-9.1
https://geogram.example.com/reports/feed/rss?type=pothole
```

### REST API

**Base URL**: `/api/v1/reports`

**Endpoints**:

**List Reports**:
```
GET /api/v1/reports
Query Parameters:
  - severity: emergency|urgent|attention|info
  - type: <report-type>
  - status: open|in-progress|resolved|closed
  - region: <lat>_<lon>
  - radius: <meters> (search radius)
  - lat, lon: <coordinates> (for radius search)
  - created_after: <timestamp>
  - created_before: <timestamp>
  - verified: true|false (has verifications)
  - limit: <number> (default: 100)
  - offset: <number> (pagination)
```

**Get Single Report**:
```
GET /api/v1/reports/{report-id}
Returns full report details including all updates
```

**Create Report** (Authenticated):
```
POST /api/v1/reports
Body: JSON report data
Returns: Created report ID
```

**Update Report** (Authenticated):
```
POST /api/v1/reports/{report-id}/updates
Body: Update data
Returns: Update confirmation
```

**Verify Report** (Authenticated):
```
POST /api/v1/reports/{report-id}/verify
Returns: Updated verification count
```

**Get Statistics**:
```
GET /api/v1/reports/stats
Query Parameters:
  - region: <lat>_<lon>
  - time_period: 7d|30d|90d|1y|all
Returns: Statistics object
```

### Webhooks

**Purpose**: Real-time notifications to external systems

**Events**:
- `report.created`: New report submitted
- `report.updated`: Report status changed
- `report.verified`: Report verified by user
- `report.resolved`: Report marked as resolved
- `report.commented`: New comment added
- `report.priority_high`: Report reaches high priority score

**Webhook Payload**:
```json
{
  "event": "report.created",
  "timestamp": "2025-11-23T10:00:00Z",
  "report": {
    "id": "38.7223_-9.1393_broken-sidewalk",
    "severity": "attention",
    "type": "sidewalk-damage",
    "coordinates": [38.7223, -9.1393],
    "address": "Main Street near Café Central, Lisbon",
    "url": "https://geogram.example.com/reports/..."
  }
}
```

**Configuration**:
- Subscribe to specific event types
- Filter by severity, type, or region
- Include/exclude data in payload

### Third-Party Integrations

**FixMyStreet Integration**:
- Export reports to FixMyStreet platforms
- Bi-directional sync
- Map official case numbers

**SeeClickFix Integration**:
- Create issues in SeeClickFix
- Track status updates
- Sync resolutions

**311 Systems**:
- Auto-submit to city 311 systems
- Map report types to 311 categories
- Track case numbers

**Slack/Discord Notifications**:
- Send notifications to team channels
- Filter by severity or type
- Include photos and location maps

**Email Notifications**:
- Subscribe to region-based alerts
- Daily/weekly digest emails
- Emergency-only notifications

### Map Embeddings

**Embed Code** (iframe):
```html
<iframe
  src="https://geogram.example.com/reports/map?region=38.7_-9.1"
  width="100%"
  height="600px"
  frameborder="0">
</iframe>
```

**JavaScript Widget**:
```html
<div id="geogram-reports-map"></div>
<script src="https://geogram.example.com/widgets/reports-map.js"></script>
<script>
  GeogramReportsMap.init({
    container: 'geogram-reports-map',
    region: '38.7_-9.1',
    severities: ['emergency', 'urgent'],
    height: '600px'
  });
</script>
```

**Customization Options**:
- Filter by severity, type, status
- Custom marker colors
- Show/hide report details
- Click-through to full report

### Data Import

**Import from CSV**:
- Bulk import reports from CSV files
- Field mapping configuration
- Validation and error reporting
- Preview before import

**Import from GeoJSON**:
- Import geospatial data
- Automatic coordinate extraction
- Type mapping from properties

**Import from Other Systems**:
- FixMyStreet import
- SeeClickFix import
- Custom CSV/JSON formats
- Migration tools

## Complete Examples

### Example 1: Simple Report (Single Language)

```
# REPORT: Broken Sidewalk

CREATED: 2025-11-23 10:00_00
AUTHOR: CR7BBQ
COORDINATES: 38.7223,-9.1393
SEVERITY: attention
TYPE: sidewalk-damage
STATUS: open
ADDRESS: Main Street near Café Central, Lisbon

Large crack in sidewalk creating trip hazard.
Approximately 20cm wide crack running across
the entire width of the sidewalk.

Noticed this morning. Could be dangerous especially
for elderly pedestrians or people with mobility aids.

--> npub: npub1abc123...
--> signature: hex_signature
```

### Example 2: Emergency Report with Updates

```
# REPORT: Fire Outbreak

CREATED: 2025-11-23 14:30_00
AUTHOR: X135AS
COORDINATES: 40.7128,-74.0060
SEVERITY: emergency
TYPE: fire-hazard
STATUS: resolved
ADDRESS: Warehouse District, Building 42, New York
CONTACT: Fire department notified immediately

Active fire in abandoned warehouse.
Heavy smoke visible from several blocks away.

Fire department has been called (911).
Area being evacuated.

--> npub: npub1xyz789...
--> signature: hex_sig1

=== updates/2025-11-23_fire-contained.txt ===
# UPDATE: Fire Contained

UPDATED: 2025-11-23 15:45_00
AUTHOR: X135AS
NEW_STATUS: in-progress

Fire department has fire under control.
No injuries reported. Building will be
demolished for safety.

--> npub: npub1xyz789...
--> signature: hex_sig2

=== updates/2025-11-23_all-clear.txt ===
# UPDATE: All Clear

UPDATED: 2025-11-23 18:00_00
AUTHOR: X135AS
NEW_STATUS: resolved

Fire completely extinguished.
Area has been secured.
Building scheduled for demolition tomorrow.

--> npub: npub1xyz789...
--> signature: hex_sig3
```

### Example 3: Multilanguage Report

```
# REPORT_EN: Vandalized Public Sign
# REPORT_PT: Sinal Público Vandalizado
# REPORT_ES: Señal Pública Vandalizada

CREATED: 2025-11-23 09:00_00
AUTHOR: BRAVO2
COORDINATES: 51.5055,-0.0754
SEVERITY: attention
TYPE: vandalism
STATUS: open
ADDRESS: Tower Bridge Road, London

[EN]
Historic information sign has been spray-painted
with graffiti. The sign provides historical information
about Tower Bridge and is an important tourist resource.

The graffiti should be removed to preserve the
area's appearance and historical value.

[PT]
Sinal de informação histórica foi pichado
com grafite. O sinal fornece informação histórica
sobre a Tower Bridge e é um recurso turístico importante.

O grafite deve ser removido para preservar a
aparência e valor histórico da área.

[ES]
La señal de información histórica ha sido pintada
con graffiti. La señal proporciona información histórica
sobre el Tower Bridge y es un recurso turístico importante.

El graffiti debe ser eliminado para preservar la
apariencia y valor histórico del área.

--> npub: npub1bravo...
--> signature: hex_sig
```

## Parsing Implementation

### Report File Parsing

```
1. Read report.txt as UTF-8 text
2. Parse title lines:
   - Single language: "# REPORT: <description>"
   - Multilanguage: "# REPORT_XX: <description>"
3. Verify at least one title exists
4. Parse header lines:
   - CREATED, AUTHOR, COORDINATES (required)
   - SEVERITY, TYPE, STATUS (required)
   - ADDRESS, CONTACT (optional)
   - ADMINS, MODERATORS (optional)
5. Parse content section
6. Extract metadata (npub, signature)
7. Verify signature
```

### Region Calculation

```
1. Extract coordinates from COORDINATES field
2. Round latitude to 1 decimal place
3. Round longitude to 1 decimal place
4. Format region folder: {LAT}_{LON}/
5. Check for numbered subfolders
6. Determine correct location for report
```

## File Operations

### Creating a Report

```
1. User fills in report details
2. Sanitize description
3. Generate folder name: {lat}_{lon}_description/
4. Calculate region from coordinates
5. Create region directory if needed: active/{region}/
6. Create report folder: active/{region}/{lat}_{lon}_description/
7. Create report.txt with header and content
8. Create news.txt with initial entry:
   > YYYY-MM-DD HH:MM_ss
   Report created by {AUTHOR}
   Severity: {SEVERITY} | Type: {TYPE}
   Location: {ADDRESS}
9. Create .reactions/ directory
10. Create contributed-photos/ directory
11. Author's npub automatically becomes admin
12. Set STATUS: open
13. Set folder permissions (755)
```

### Subscribing to a Report

```
1. User views report and clicks "Subscribe"
2. Verify user is authenticated
3. Check user's npub not already in SUBSCRIBERS list
4. Add user's npub to SUBSCRIBERS field in report.txt
5. Increment SUBSCRIBER_COUNT
6. Add entry to news.txt:
   > YYYY-MM-DD HH:MM_ss
   User subscribed (total subscribers: X)
7. Send confirmation to user
8. User receives future notifications based on preferences
```

### Contributing a Photo

```
1. User selects report to contribute to
2. User uploads photo with description
3. Verify user is authenticated
4. Generate filename: {CALLSIGN}_{YYYY-MM-DD}_{description}.jpg
5. Save to report's contributed-photos/ folder
6. Optionally create metadata file (.txt)
7. Set file permissions (644)
8. Photo immediately visible to all users
9. Add entry to news.txt:
   > YYYY-MM-DD HH:MM_ss
   {CALLSIGN} contributed photo
10. Notify subscribers if configured
```

### Adding an Update

```
1. Verify report exists in active/
2. Create updates/ folder if not exists
3. Generate update filename: YYYY-MM-DD_description.txt
4. Create update file with content
5. If NEW_STATUS specified, update report.txt STATUS field
6. Set file permissions (644)
```

### Resolving a Report

```
1. Add final update with NEW_STATUS: resolved
2. Update STATUS in report.txt
3. Optionally add before/after photos
4. Mark completion timestamp
5. Report remains in active/ for configured period
6. After period elapses, moved to expired/
```

### Expiring/Archiving a Report

```
1. Check if report meets expiration criteria
2. Update STATUS to closed (if not already)
3. Move entire folder from active/{region}/ to expired/{region}/
4. Preserve all content (report.txt, photos, updates, reactions)
5. Maintain same folder name and structure
6. Update search indexes
7. Remove from active views
```

## Validation Rules

### Report Validation

- [x] First line must start with `# REPORT: ` or `# REPORT_XX: `
- [x] At least one title required
- [x] CREATED must have valid timestamp
- [x] AUTHOR must not be empty
- [x] COORDINATES must be valid lat,lon
- [x] SEVERITY must be: emergency, urgent, attention, or info
- [x] TYPE must not be empty
- [x] STATUS must be: open, in-progress, resolved, or closed
- [x] Folder name must match {lat}_{lon}_* pattern
- [x] Report folder must be in correct region
- [x] Active reports must be in active/ directory
- [x] Expired/closed reports must be in expired/ directory

### Coordinate Validation

- Latitude: -90.0 to +90.0
- Longitude: -180.0 to +180.0
- Format: `lat,lon` (no spaces)
- Precision: Up to 6 decimal places

### Severity Validation

- Must be one of: emergency, urgent, attention, info
- Case-sensitive (lowercase)

### Status Validation

- Must be one of: open, in-progress, resolved, closed
- Case-sensitive (lowercase)

## Best Practices

### For Report Creators

1. **Accurate coordinates**: Use precise GPS coordinates
2. **Choose correct severity**: Don't over-dramatize, be accurate
3. **Clear description**: Describe the issue clearly and completely
4. **Quality photos**: Take clear photos from multiple angles
5. **Include context**: Mention landmarks or nearby features
6. **Safety first**: For emergencies, contact authorities before/while reporting
7. **Follow up**: Add updates as situation changes

### For Community Members

1. **Confirm reports**: Like or comment if you can confirm the issue
2. **Add information**: Comment with additional context if you know it
3. **Contribute photos**: Add photos from different angles or showing progression
4. **Verify reports**: Use the verification system to confirm you witnessed the issue
5. **Avoid duplicates**: Check existing reports before creating new one
6. **Respect privacy**: Don't include personal information in comments or photos
7. **Be constructive**: Comments and contributions should be helpful and relevant
8. **Photo quality**: Contribute clear, relevant photos that add value
9. **Stay on topic**: Only contribute content directly related to the reported issue
10. **Report inappropriate content**: Flag spam or inappropriate contributions

### For Authorities/Responders

1. **Add updates**: Keep community informed of progress
2. **Mark resolved**: Update status when issue is fixed
3. **Document resolution**: Add after photos showing completed work
4. **Thank reporters**: Acknowledge community participation

### For Developers

1. **Validate input**: Check coordinates, severity, type
2. **Index by region**: Efficient geographic querying
3. **Filter by severity**: Allow users to filter by urgency
4. **Map integration**: Display reports on interactive maps
5. **Notification system**: Alert users to new reports in their area
6. **Duplicate detection**: Suggest similar nearby reports

## Security Considerations

### Access Control

**Report Creator**:
- Edit report
- Add updates
- Upload additional photos
- Close report
- Delete report

**Admins**:
- Same as creator
- Moderate content

**Moderators**:
- Hide inappropriate content
- Cannot edit or delete

**Viewers**:
- View reports
- Add reactions
- Comment

### Privacy Considerations

**Location Data**:
- Exact coordinates are public and required
- Necessary for identifying the issue location
- Users should be aware reports are public

**Personal Information**:
- Avoid including personal contact information
- Use CONTACT field sparingly
- Don't include home addresses unless necessary

### Data Integrity

- NOSTR signatures verify authenticity
- Signatures prevent tampering
- All changes tracked through updates

## Related Documentation

- [Places Format Specification](places-format-specification.md)
- [Events Format Specification](events-format-specification.md)
- [Collection File Formats](../others/file-formats.md)
- [NOSTR Protocol](https://github.com/nostr-protocol/nostr)

## Change Log

### Version 1.0 (2025-11-23)

**Initial Specification**:
- **Active/Expired Organization**: Reports organized in `active/` and `expired/` directories
  - Active reports in `active/{region}/` for ongoing issues
  - Expired/archived reports in `expired/{region}/` for historical reference
  - Automatic migration between directories based on TTL and status
- **Community Photo Contributions**: Open contribution system
  - `contributed-photos/` folder for community photos
  - Any authenticated user can contribute photos without approval
  - Photos immediately visible, moderated after the fact
  - Report author and admins can hide inappropriate photos
  - Metadata files optional for context
- **Subscription System**: Users can subscribe to reports
  - Receive notifications for status changes, updates, resolution
  - Subscribe/unsubscribe from report view
  - Email and in-app notifications
  - Private subscriber list (only count is public)
  - Multiple notification trigger events
- **News Log System**: Public timeline of report events
  - `news.txt` file tracks chronological events
  - Automatic entries for important milestones
  - Manual entries by authorized users
  - Easy-to-scan history from creation to resolution
  - Complements detailed updates/ folder
- **Official Entity Groups**: Global authorization for official organizations
  - Fire departments, city maintenance, police, schools, etc.
  - Defined at relay/global level in `config/entity-groups.txt`
  - AUTO_AUTHORIZE grants automatic update permissions
  - Group badges identify official personnel
  - Streamlined communication with authorities
- **Update Authorization**: Fine-grained permission control
  - UPDATE_AUTHORIZED field for per-report permissions
  - Entity group members auto-authorized for matching report types
  - Authorized users can add updates and news entries
  - Report author always has full admin control
- Coordinate-based organization by region
- Mandatory exact location (coordinates) for all reports
- Four severity levels (emergency, urgent, attention, info)
- 260+ comprehensive report type categories across 24 major groups
- Status tracking (open, in-progress, resolved, closed)
- Updates system for tracking progress
- Resolution documentation
- Multilanguage support (11 languages: EN, PT, ES, FR, DE, IT, NL, RU, ZH, JA, AR)
- Photo documentation with guidelines
- Photo verification and metadata extraction
- **Verification system**: Community can confirm/verify reports
- **Duplicate detection**: Automatic and manual duplicate linking
- **Authority integration**: Track official case numbers and notifications
- **Expiration and TTL**: Automatic lifecycle management
- **Priority queue**: Smart prioritization by severity, age, and verification
- **Analytics and statistics**: Comprehensive metrics and heat maps
- Reactions system (likes and comments on reports and photos)
- **Open permissions**: All authenticated users can like, comment, and contribute photos
- Moderation system (.hidden/ directory)
- Permissions and roles (author, admins, moderators, community members)
- NOSTR signature integration for authenticity
- Dense region support (numbered subfolders for >10,000 reports)
- **Integration features**: GeoJSON, CSV, REST API, webhooks, RSS feeds
- Map embedding and data import/export
