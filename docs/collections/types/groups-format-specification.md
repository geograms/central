# Geogram Groups Format Specification

Version 1.0

## Overview

Geogram groups provide a hierarchical organization and moderation system for community data curation. Groups enable communities to aggregate information from multiple sources and build Wikipedia-style compendia of regional data with built-in moderation and anti-vandalism controls.

Each group has a defined type, membership roster, and geographic areas of responsibility. Groups can validate, moderate, and curate data within their designated areas, creating a distributed trust network for information accuracy.

**Key Concepts:**
- Each collection type (except Files) has a dedicated group for moderation
- Same user (npub) can belong to multiple groups with different roles
- Groups have geographic areas of responsibility (coordinates + radius)
- Four-tier role system: Admin, Moderator, Contributor, Guest
- Candidate application system with approval workflow

## Groups Structure

```
groups/
├── group.json
├── admins.txt
├── [group_name_1]/
│   ├── group.json
│   ├── config.json              # Feature configuration
│   ├── members.txt
│   ├── areas.json
│   ├── candidates/
│   │   ├── pending/
│   │   │   ├── 2025-11-25_CR7BBQ_application.txt
│   │   │   └── 2025-11-26_X135AS_application.txt
│   │   ├── approved/
│   │   │   └── 2025-11-24_PT4XYZ_application.txt
│   │   └── rejected/
│   │       └── 2025-11-23_CT2ABC_application.txt
│   ├── photos/                  # Group photos and media
│   │   ├── group-logo.png
│   │   ├── team-photo.jpg
│   │   └── .reactions/
│   │       └── team-photo.jpg.txt
│   ├── news/                    # Published news items
│   │   ├── 2025/
│   │   │   ├── 2025-11-20_community-update.md
│   │   │   ├── 2025-11-22_safety-reminder.md
│   │   │   └── files/
│   │   │       └── {sha1}_attachment.pdf
│   │   └── 2024/
│   │       └── ...
│   ├── alerts/                  # Urgent alerts and announcements
│   │   ├── active/
│   │   │   └── 2025-11-25_weather-warning.txt
│   │   └── archived/
│   │       └── 2025-11-20_road-closure.txt
│   └── chat/                    # Public group chat
│       ├── 2025/
│       │   ├── 2025-11-20_chat.txt
│       │   ├── 2025-11-21_chat.txt
│       │   └── files/
│       │       └── {sha1}_image.jpg
│       └── 2024/
│           └── ...
├── [group_name_2]/
│   ├── group.json
│   ├── config.json
│   ├── members.txt
│   ├── areas.json
│   ├── candidates/
│   ├── photos/
│   ├── news/
│   ├── alerts/
│   └── chat/
└── [collection_type_groups]/
    ├── blog_moderators/
    │   ├── group.json
    │   ├── config.json
    │   ├── members.txt
    │   ├── areas.json
    │   ├── candidates/
    │   ├── photos/
    │   ├── news/
    │   ├── alerts/
    │   └── chat/
    └── ...
```

## Collection Root Configuration

### group.json (Root Level)

The root `group.json` defines the collection-wide configuration:

```json
{
  "collection": {
    "id": "unique-collection-id",
    "title": "Regional Groups",
    "description": "Community moderation and curation groups",
    "type": "groups",
    "created": "2025-11-25 10:30_00",
    "updated": "2025-11-25 10:30_00"
  }
}
```

### admins.txt (Root Level)

The `admins.txt` file defines collection administrators who can create, modify, and delete groups:

```
# ADMINS: Regional Groups
# Created: 2025-11-25 10:30_00

CR7BBQ
--> npub: npub1abc123def456...
--> signature: 0123456789abcdef...

X135AS
--> npub: npub1xyz789ghi012...
--> signature: fedcba9876543210...
```

**Format:**
- Header line: `# ADMINS: [Collection Title]`
- Created timestamp line
- Blank line
- Member entries with callsign, npub, and optional signature

## Group Directory Structure

Each group is stored in its own subdirectory with core files and directories:

### group.json (Group Level)

Defines the group's metadata:

```json
{
  "group": {
    "name": "city_fire_department",
    "title": "City Fire Department",
    "description": "Emergency response and fire safety for the metropolitan area",
    "type": "authority_fire",
    "collection_type": null,
    "created": "2025-11-25 11:00_00",
    "updated": "2025-11-25 11:00_00",
    "status": "active"
  }
}
```

**Fields:**
- `name`: Directory-safe identifier (lowercase, underscores)
- `title`: Human-readable group name
- `description`: Detailed description of group purpose and scope
- `type`: Group type (see Group Types section)
- `collection_type`: If this is a collection-specific group, specifies which collection type it moderates (e.g., "blog", "forum", "events"). Null for general groups.
- `created`: Creation timestamp
- `updated`: Last modification timestamp
- `status`: `active` or `inactive`

### members.txt

Defines group membership with roles:

```
# GROUP: City Fire Department
# TYPE: authority_fire
# Created: 2025-11-25 11:00_00

ADMIN: CR7BBQ
--> npub: npub1abc123def456...
--> joined: 2025-11-25 11:00_00
--> signature: 0123456789abcdef...

MODERATOR: X135AS
--> npub: npub1xyz789ghi012...
--> joined: 2025-11-25 11:15_00
--> signature: fedcba9876543210...

CONTRIBUTOR: PT4XYZ
--> npub: npub1qrs345tuv678...
--> joined: 2025-11-25 12:00_00
--> signature: 123abc456def7890...

GUEST: CT1AAA
--> npub: npub1mno678pqr901...
--> joined: 2025-11-25 13:00_00
```

**Format:**
- Header with group title and type
- `ADMIN:` for group administrators
- `MODERATOR:` for content moderators
- `CONTRIBUTOR:` for content contributors
- `GUEST:` for read-only or limited participation
- Metadata includes npub, joined timestamp, and optional signature

### areas.json

Defines geographic areas of responsibility:

```json
{
  "areas": [
    {
      "id": "area_1",
      "name": "Downtown District",
      "center": {
        "latitude": 38.7223,
        "longitude": -9.1393
      },
      "radius_km": 2.5,
      "priority": "high",
      "notes": "Primary coverage area including historic downtown"
    },
    {
      "id": "area_2",
      "name": "Industrial Zone",
      "center": {
        "latitude": 38.7456,
        "longitude": -9.1789
      },
      "radius_km": 5.0,
      "priority": "medium",
      "notes": "Secondary coverage for industrial facilities"
    }
  ],
  "updated": "2025-11-25 11:00_00"
}
```

**Area Fields:**
- `id`: Unique area identifier within the group
- `name`: Human-readable area name
- `center`: Geographic center point with latitude/longitude
- `radius_km`: Coverage radius in kilometers
- `priority`: `high`, `medium`, or `low` (for overlapping jurisdictions)
- `notes`: Optional description or special instructions

### config.json

Defines which features are enabled for the group and their permission settings:

```json
{
  "features": {
    "photos": true,
    "news": true,
    "alerts": true,
    "chat": true,
    "comments": false
  },
  "permissions": {
    "photos_upload": ["admin", "moderator", "contributor"],
    "photos_delete": ["admin", "moderator"],
    "news_publish": ["admin", "moderator"],
    "news_edit": ["admin", "moderator"],
    "alerts_issue": ["admin", "moderator"],
    "alerts_archive": ["admin", "moderator"],
    "chat_post": ["admin", "moderator", "contributor", "guest"],
    "chat_delete": ["admin", "moderator"],
    "cross_group_post": ["admin", "moderator", "contributor"]
  },
  "chat_settings": {
    "allow_cross_group_posts": true,
    "allow_file_attachments": true,
    "message_retention_days": 365
  },
  "updated": "2025-11-25 11:00_00"
}
```

**Features Object:**
- `photos`: Enable/disable group photo gallery
- `news`: Enable/disable news publishing
- `alerts`: Enable/disable alert system
- `chat`: Enable/disable group chat
- `comments`: Enable/disable comments on content (applies across features)

**Permissions Object:**
Each permission maps to an array of roles that can perform the action:
- `photos_upload`: Who can upload photos to group gallery
- `photos_delete`: Who can delete photos
- `news_publish`: Who can publish news items
- `news_edit`: Who can edit published news
- `alerts_issue`: Who can issue alerts
- `alerts_archive`: Who can archive alerts
- `chat_post`: Who can post in group chat
- `chat_delete`: Who can delete chat messages
- `cross_group_post`: Who can post in other groups with this group's identity

**Chat Settings:**
- `allow_cross_group_posts`: Enable members to post in other groups
- `allow_file_attachments`: Allow file/media attachments in chat
- `message_retention_days`: How long to keep chat messages (0 = forever)

Group admins can modify these settings at any time. Changes are logged with timestamps in the `updated` field.

### photos/ Directory

Groups can maintain a photo gallery showcasing their team, activities, facilities, and events. Photos support community reactions and engagement.

**Structure:**
```
photos/
├── group-logo.png
├── team-photo-2025.jpg
├── headquarters.jpg
├── training-session.jpg
└── .reactions/
    ├── team-photo-2025.jpg.txt
    └── headquarters.jpg.txt
```

**Supported Formats:**
- Images: .jpg, .jpeg, .png, .gif, .webp
- Maximum file size: 10 MB per photo
- Recommended dimensions: 1920x1080 or larger

**Photo Filenames:**
- Use descriptive names: `team-photo-2025.jpg`, `headquarters.jpg`
- Include year in filename for time-based organization
- Use lowercase with hyphens: `training-session-march-2025.jpg`

**Reactions:**
The `.reactions/` subdirectory contains reaction files for each photo:

**File:** `photos/.reactions/team-photo-2025.jpg.txt`
```
photo: team-photo-2025.jpg
uploaded: 2025-11-25 10:00_00
uploaded_by: CR7BBQ
uploaded_by_npub: npub1abc123def456...

description: Annual team photo at headquarters
tags: team, 2025, headquarters

> 2025-11-25 10:15_00 -- X135AS
--> npub: npub1xyz789ghi012...
--> reaction: 👍
--> signature: fedcba9876543210...

> 2025-11-25 10:20_00 -- PT4XYZ
--> npub: npub1qrs345tuv678...
--> reaction: ❤️
--> comment: Great team!
--> signature: 123abc456def7890...
```

**Reaction Format:**
- Timestamp with callsign header
- npub for verification
- reaction: Single emoji
- comment: Optional text comment
- signature: NOSTR signature

**Photo Permissions:**
Defined in `config.json` permissions object:
- Upload: Typically admin, moderator, contributor
- Delete: Typically admin, moderator only
- React: All roles can react to photos

### news/ Directory

Groups can publish news items, announcements, and updates to their community. News items support classifications, expiry dates, reactions, and comments.

**Structure:**
```
news/
├── 2025/
│   ├── 2025-11-20_community-update.md
│   ├── 2025-11-22_safety-reminder.md
│   ├── 2025-11-25_new-equipment.md
│   └── files/
│       ├── {sha1}_brochure.pdf
│       └── {sha1}_photo.jpg
└── 2024/
    └── ...
```

**Filename Format:** `YYYY-MM-DD_title-slug.md`

**News File Format:**

**File:** `news/2025/2025-11-25_new-equipment.md`
```markdown
---
title: New Emergency Response Equipment Arrived
author: CR7BBQ
author_npub: npub1abc123def456...
published: 2025-11-25 09:00_00
classification: normal
expires: 2025-12-25 23:59_59
tags: equipment, emergency, announcement
coordinates: 38.7223, -9.1393
signature: 0123456789abcdef...
---

# New Emergency Response Equipment Arrived

We are pleased to announce that our group has received new state-of-the-art emergency response equipment, including updated communication devices and medical supplies.

## Equipment Details

- **Radio System**: Digital encrypted radios with 50km range
- **Medical Kit**: Advanced first aid supplies meeting 2025 standards
- **Safety Gear**: Updated protective equipment for all team members

## Training Schedule

All team members will receive training on the new equipment:
- December 1-3: Radio operation training
- December 5-7: Medical equipment certification
- December 10: Final assessment

## Attachments

- [Equipment Brochure](files/a1b2c3d4e5f6_brochure.pdf)
- [Photo Gallery](files/f6e5d4c3b2a1_photo.jpg)

---

## Reactions

> 2025-11-25 09:15_00 -- X135AS
--> npub: npub1xyz789ghi012...
--> reaction: 👍
--> signature: fedcba9876543210...

> 2025-11-25 09:30_00 -- PT4XYZ
--> npub: npub1qrs345tuv678...
--> reaction: 🎉
--> comment: Excellent news! Looking forward to the training.
--> signature: 123abc456def7890...

---

## Comments

> 2025-11-25 10:00_00 -- CT1AAA
--> npub: npub1mno678pqr901...
--> comment: Will the training be mandatory for all contributors?
--> signature: mno678pqr9012345...

> 2025-11-25 10:15_00 -- CR7BBQ
--> npub: npub1abc123def456...
--> comment: @CT1AAA Yes, all active members should attend at least one session.
--> signature: abc123def4567890...
```

**News Metadata Fields:**
- `title`: Headline (max 255 characters)
- `author`: Callsign of publisher
- `author_npub`: NOSTR public key for verification
- `published`: Publication timestamp
- `classification`: `normal`, `urgent`, or `danger`
- `expires`: Optional expiry date (null for permanent)
- `tags`: Comma-separated tags
- `coordinates`: Optional location (latitude, longitude)
- `signature`: NOSTR signature of content

**Classifications:**
- `normal`: Regular updates and announcements
- `urgent`: Important information requiring attention
- `danger`: Critical safety warnings or emergencies

**Attachments:**
Files referenced in news items are stored in the `files/` subdirectory using SHA1-based naming for deduplication.

**Reactions and Comments:**
If enabled in `config.json`, users can react and comment on news items. Reactions appear after the main content, separated by `---`. Comments appear after reactions in a separate section.

**News Permissions:**
Defined in `config.json`:
- Publish: Typically admin and moderator
- Edit: Typically admin and moderator
- React/Comment: Based on group role and config

### alerts/ Directory

Groups can issue urgent alerts and announcements for time-sensitive information. Alerts are organized into active and archived subdirectories.

**Structure:**
```
alerts/
├── active/
│   ├── 2025-11-25_weather-warning.txt
│   └── 2025-11-26_road-closure.txt
└── archived/
    ├── 2025-11-20_power-outage.txt
    └── 2025-11-21_event-cancellation.txt
```

**Filename Format:** `YYYY-MM-DD_alert-slug.txt`

**Alert File Format:**

**File:** `alerts/active/2025-11-25_weather-warning.txt`
```
alert_id: alert_20251125_001
title: Severe Weather Warning - High Winds
group: City Fire Department
issued_by: CR7BBQ
issued_by_npub: npub1abc123def456...
issued_at: 2025-11-25 08:00_00
severity: urgent
status: active
expires: 2025-11-25 20:00_00
coordinates: 38.7223, -9.1393
radius_km: 15.0

message:
Strong winds expected throughout the metropolitan area today. Wind speeds may reach 80-100 km/h between 10:00 and 18:00.

Recommendations:
- Secure loose outdoor objects
- Avoid parking under trees
- Stay indoors during peak wind hours
- Report downed power lines immediately

Stay safe and monitor local weather updates.

signature: 0123456789abcdef...
```

**Alert Fields:**
- `alert_id`: Unique identifier (format: alert_YYYYMMDD_NNN)
- `title`: Short alert headline (max 255 chars)
- `group`: Group issuing the alert
- `issued_by`: Callsign of issuer
- `issued_by_npub`: NOSTR public key for verification
- `issued_at`: Issue timestamp
- `severity`: `info`, `warning`, `urgent`, or `danger`
- `status`: `active` or `archived`
- `expires`: Expiry timestamp (null for manual archive)
- `coordinates`: Alert location center
- `radius_km`: Alert coverage area radius
- `message`: Multi-line alert message
- `signature`: NOSTR signature

**Severity Levels:**
- `info`: General information, no action required
- `warning`: Attention needed, prepare for action
- `urgent`: Immediate attention required
- `danger`: Critical emergency, take action now

**Alert Lifecycle:**
1. Alert created in `alerts/active/`
2. Alert remains active until expired or manually archived
3. Alert moved to `alerts/archived/` when no longer relevant
4. Archived alerts kept for historical record and audit

**Auto-Archival:**
Alerts with `expires` timestamp are automatically moved to `archived/` after expiry. Alerts without expiry require manual archival by admin/moderator.

**Alert Permissions:**
Defined in `config.json`:
- Issue: Typically admin and moderator only
- Archive: Typically admin and moderator only
- View: All roles

### chat/ Directory

Groups can maintain a public chat for member communication and community engagement. Chat supports cross-group messaging where members can post in other groups with their group identity displayed.

**Structure:**
```
chat/
├── 2025/
│   ├── 2025-11-20_chat.txt
│   ├── 2025-11-21_chat.txt
│   ├── 2025-11-25_chat.txt
│   └── files/
│       ├── {sha1}_image.jpg
│       └── {sha1}_document.pdf
└── 2024/
    └── ...
```

**Filename Format:** `YYYY-MM-DD_chat.txt`

One file per day, automatically created when first message of the day is posted.

**Chat File Format:**

**File:** `chat/2025/2025-11-25_chat.txt`
```
# GROUP CHAT: City Fire Department
# DATE: 2025-11-25
# TYPE: authority_fire

> 2025-11-25 09:00_00 -- CR7BBQ
--> npub: npub1abc123def456...
--> message: Good morning team! Reminder that we have equipment training this week.
--> signature: 0123456789abcdef...

> 2025-11-25 09:15_00 -- X135AS
--> npub: npub1xyz789ghi012...
--> message: Thanks for the reminder. I've updated the schedule on our board.
--> signature: fedcba9876543210...

> 2025-11-25 10:00_00 -- PT4XYZ
--> npub: npub1qrs345tuv678...
--> message: Will there be make-up sessions for those who can't attend this week?
--> signature: 123abc456def7890...

> 2025-11-25 10:05_00 -- CR7BBQ
--> npub: npub1abc123def456...
--> reply_to: 2025-11-25 10:00_00 -- PT4XYZ
--> message: Yes, we'll schedule additional sessions in December if needed.
--> signature: abc123def4567890...

> 2025-11-25 14:30_00 -- CT1AAA
--> npub: npub1mno678pqr901...
--> message: Here's a photo from today's inspection
--> attachment: files/f1e2d3c4b5a6_inspection.jpg
--> signature: mno678pqr9012345...
```

**Message Format:**
- Header: `> YYYY-MM-DD HH:MM_ss -- CALLSIGN`
- Metadata lines start with `-->`
- `npub`: Sender's NOSTR public key
- `message`: Message content (can be multi-line)
- `reply_to`: Optional reference to another message
- `attachment`: Optional file reference (in files/ subdirectory)
- `signature`: NOSTR signature

**Cross-Group Messaging:**

Groups with `allow_cross_group_posts` enabled in their config.json can allow members to post in other groups' chats. When cross-posting, the sender's group identity is displayed.

**Example Cross-Group Post:**

**File:** `citizens_group/chat/2025/2025-11-25_chat.txt`
```
> 2025-11-25 15:00_00 -- CR7BBQ [City Fire Department]
--> npub: npub1abc123def456...
--> from_group: City Fire Department
--> from_group_type: authority_fire
--> posting_as: contributor
--> message: Attention citizens: Please be cautious with outdoor fires today due to high winds. Check weather warnings before any outdoor activities.
--> signature: 0123456789abcdef...

> 2025-11-25 15:10_00 -- CT2XYZ
--> npub: npub1stu901vwx234...
--> message: @CR7BBQ Thank you for the warning! Will make sure to secure everything outside.
--> signature: stu901vwx2345678...
```

**Cross-Group Post Fields:**
- `from_group`: Name of the group the poster represents
- `from_group_type`: Type of the originating group
- `posting_as`: Poster's role in their group
- Display format in UI: "CALLSIGN [GROUP NAME]"

**Choosing Group Identity:**

When a user belongs to multiple groups and cross-group posting is enabled, they can choose which group identity to post with:

**Example User (CR7BBQ) belongs to:**
- City Fire Department (admin)
- Blog Moderators (contributor)
- Events Team (moderator)

When posting in another group's chat, CR7BBQ can choose to appear as:
- "CR7BBQ [City Fire Department]" (authority figure)
- "CR7BBQ [Blog Moderators]" (community contributor)
- "CR7BBQ [Events Team]" (event coordinator)

The choice depends on the context and which identity is most relevant to the message.

**Chat Features:**
- **Real-time messaging**: New messages appended to daily file
- **File attachments**: Images, documents stored in files/ subdirectory
- **Message replies**: Reference previous messages with reply_to
- **Cross-group posts**: Post in other groups with group identity badge
- **Message retention**: Configurable in config.json (default: 365 days)
- **Moderation**: Admins/moderators can delete inappropriate messages

**Chat Permissions:**
Defined in `config.json`:
- `chat_post`: Who can post messages (typically all roles)
- `chat_delete`: Who can delete messages (typically admin, moderator)
- `cross_group_post`: Who can post in other groups with group identity

**File Attachments:**
Files shared in chat are stored in the `files/` subdirectory using SHA1-based naming:
- Format: `{sha1_hash}_{original_filename}`
- Enables deduplication across messages
- Maximum size defined by collection settings
- Supported formats: images, documents, archives

**Message Deletion:**
When a message is deleted by a moderator:
```
> 2025-11-25 16:00_00 -- DELETED
--> npub: [removed]
--> message: [Message removed by moderator]
--> deleted_by: X135AS
--> deleted_by_npub: npub1xyz789ghi012...
--> deleted_at: 2025-11-25 16:05_00
--> deletion_reason: Inappropriate content
--> signature: deleted_signature_here
```

Deleted messages are replaced with tombstone entries to preserve conversation flow and maintain audit trail.

### candidates/ Directory

Contains application files from users requesting to join the group. Applications are organized into three subdirectories based on status: `pending/`, `approved/`, and `rejected/`.

**Filename Format:** `YYYY-MM-DD_{CALLSIGN}_application.txt`

This format allows for easy chronological sorting in file browsers and quick identification of application dates.

**Subdirectories:**
- `pending/`: New applications awaiting review
- `approved/`: Applications that have been accepted
- `rejected/`: Applications that have been declined

**Example:** `candidates/pending/2025-11-25_CR7BBQ_application.txt`

#### Application File Format

Application files use a text-based key-value format for easy parsing and readability:

```
group: City Fire Department
applicant: CR7BBQ
npub: npub1abc123def456...
applied: 2025-11-25 14:00_00
status: pending
requested_role: contributor
location: Lisbon, Portugal
experience: 10 years professional firefighter

references:
- npub1xyz789ghi012... (X135AS - Professional colleague)
- npub1qrs345tuv678... (PT4XYZ - Former supervisor)
- npub1mno678pqr901... (CT1AAA - Community member)

introduction:
I am a professional firefighter with 10 years of experience in emergency response and fire safety. Throughout my career, I have been involved in emergency incident management, public safety education, and community outreach programs.

I would like to contribute to the community by helping moderate fire safety reports and providing official verification for emergency incidents in the Lisbon area. My professional experience allows me to quickly assess the accuracy and severity of fire-related reports, ensuring the community receives reliable and timely information.

I am passionate about public safety and believe that a well-moderated reporting system can save lives by disseminating accurate information quickly. I am committed to maintaining high standards of accuracy and professionalism in all moderation activities.

signature: 0123456789abcdef...

---
DECISION RECORD
---

decision: approved
decided_by: X135AS
decided_by_npub: npub1xyz789ghi012...
decided_at: 2025-11-25 16:30_00
approved_role: contributor
decision_reason: Verified professional firefighter credentials with relevant experience in emergency response. References confirmed professional competence and reliability. Strong introduction demonstrates understanding of moderation responsibilities.
decision_signature: fedcba9876543210...
```

**Application Field Descriptions:**

**Core Fields:**
- `group`: Name of the group being applied to
- `applicant`: Callsign of the applicant
- `npub`: Applicant's NOSTR public key
- `applied`: Timestamp of application submission (YYYY-MM-DD HH:MM_ss)
- `status`: Current status (`pending`, `approved`, `rejected`)
- `requested_role`: Role requested (`contributor`, `moderator`, `admin`, `guest`)
- `location`: Optional geographic location of applicant
- `experience`: Brief summary of relevant experience

**References Section:**
- `references`: List of npub keys with optional names/descriptions
- Format: `- npub... (Name - Relationship)`
- References can be contacted to vouch for the candidate
- Minimum 0 references (optional), recommended 2-3
- Each reference should include context about their relationship

**Introduction Section:**
- `introduction`: Multi-paragraph letter explaining:
  - Relevant qualifications and experience
  - Why they want to join the group
  - What they can contribute
  - Understanding of role responsibilities
  - Commitment to group values and standards
- Should be detailed and personal (500-2000 words recommended)
- Demonstrates communication skills and motivation

**Signature:**
- `signature`: Cryptographic signature of the application content
- Must be the last field before the decision record

**Decision Record Section:**
- Added after admin/moderator reviews the application
- Separated by `--- DECISION RECORD ---` marker
- Contains all decision-related information:
  - `decision`: `approved` or `rejected`
  - `decided_by`: Callsign of decision maker
  - `decided_by_npub`: NOSTR public key of decision maker
  - `decided_at`: Timestamp of decision (YYYY-MM-DD HH:MM_ss)
  - `approved_role`: Role granted if approved (`null` if rejected)
  - `decision_reason`: Detailed explanation of decision
  - `decision_signature`: Cryptographic signature of decision maker

**File Movement:**
After a decision is made, the application file is moved:
- From `candidates/pending/` to `candidates/approved/` (if approved)
- From `candidates/pending/` to `candidates/rejected/` (if rejected)

The filename remains unchanged during the move, preserving the chronological sorting.

## Role System

Groups use a four-tier role system:

### ADMIN
**Can Do:**
- Everything a Moderator can do
- Add/remove members from any role
- Modify group metadata (title, description, type)
- Define and modify areas of responsibility
- Approve/reject moderator applications
- Promote/demote members
- Delete the group (with confirmation)
- Grant admin role to other members

**Cannot Do:**
- Override collection-level admin decisions

### MODERATOR
**Can Do:**
- Everything a Contributor can do
- Review and approve/reject content submissions
- Hide or flag inappropriate content
- Edit metadata of approved content
- Review contributor applications
- Approve guest applications
- View moderation logs and analytics
- Ban users from posting (temporary)

**Cannot Do:**
- Modify group settings or areas
- Add/remove moderators or admins
- Permanently delete content (only hide)

### CONTRIBUTOR
**Can Do:**
- Everything a Guest can do
- Submit content for review
- Edit their own submitted content
- Attach files and media
- Comment on content
- Vote on content quality
- Apply to become a moderator

**Cannot Do:**
- Approve or moderate content
- Access moderation logs
- Modify other users' content

### GUEST
**Can Do:**
- View public content
- Read discussions (collection-type dependent)
- View group information and areas
- Apply to become a contributor
- Report inappropriate content

**Cannot Do:**
- Submit content (depends on collection type settings)
- Edit any content
- Access member-only areas

**Note:** Guest permissions vary by collection type. Some collections may allow guests to submit content, while others restrict this to contributors.

## Group Types

Groups are categorized by type, which determines their role and permissions:

### Social Groups
- **`friends`**: Informal friend networks for local coordination

### Organizations
- **`association`**: Community associations, NGOs, clubs

### Authority Forces
- **`authority_police`**: Law enforcement agencies
- **`authority_fire`**: Fire departments and emergency response
- **`authority_civil_protection`**: Civil protection and disaster response
- **`authority_military`**: Military organizations (restricted)

### Health Services
- **`health_hospital`**: Hospitals and medical centers
- **`health_clinic`**: Clinics and health posts
- **`health_emergency`**: Emergency medical services (EMS)

### Administrative
- **`admin_townhall`**: Municipal administration
- **`admin_regional`**: Regional government bodies
- **`admin_national`**: National agencies (restricted)

### Infrastructure
- **`infrastructure_utilities`**: Utilities (water, power, telecom)
- **`infrastructure_transport`**: Public transportation authorities

### Education
- **`education_school`**: Schools and educational institutions
- **`education_university`**: Universities and higher education

### Collection-Specific
- **`collection_moderator`**: Moderates a specific collection type (blog, forum, events, news, etc.)

## Collection-Specific Groups

Each collection type (except Files) requires a dedicated moderation group:

### Concept

- **One group per collection type** within a groups collection
- Each group has limited geographic scope (coordinates + radius)
- Groups moderate content only within their defined areas
- Collection admins appoint initial group admins
- Groups operate autonomously within their jurisdiction
- Same user can be admin of blog group and contributor in forum group

### Example Structure

```
groups/
├── blog_moderators/
│   ├── group.json (collection_type: "blog")
│   ├── members.txt
│   ├── areas.json (covers Lisbon metropolitan area)
│   └── candidates/
│       ├── pending/
│       ├── approved/
│       └── rejected/
├── forum_moderators/
│   ├── group.json (collection_type: "forum")
│   ├── members.txt
│   ├── areas.json (covers Lisbon + surrounding districts)
│   └── candidates/
│       ├── pending/
│       ├── approved/
│       └── rejected/
├── events_moderators/
│   ├── group.json (collection_type: "events")
│   ├── members.txt
│   ├── areas.json
│   └── candidates/
│       ├── pending/
│       ├── approved/
│       └── rejected/
└── reports_moderators/
    ├── group.json (collection_type: "report")
    ├── members.txt
    ├── areas.json
    └── candidates/
        ├── pending/
        ├── approved/
        └── rejected/
```

### Collection-Specific Group Configuration

```json
{
  "group": {
    "name": "blog_moderators",
    "title": "Blog Content Moderators",
    "description": "Moderate and curate blog posts for Lisbon region",
    "type": "collection_moderator",
    "collection_type": "blog",
    "created": "2025-11-25 11:00_00",
    "updated": "2025-11-25 11:00_00",
    "status": "active"
  }
}
```

### How It Works

1. **Collection Admin** creates the groups collection
2. **Collection Admin** creates initial groups for each collection type
3. **Collection Admin** appoints initial group admins
4. **Group Admins** define areas of responsibility
5. **Group Admins** recruit and manage their teams
6. Groups operate **autonomously** for topics within their jurisdiction
7. **Collection Admin** only intervenes for disputes or violations

### Multi-Group Membership

Users can participate in multiple groups with different roles:

**Example:**
```
CR7BBQ's memberships:
- blog_moderators: ADMIN
- forum_moderators: CONTRIBUTOR
- events_moderators: MODERATOR
- lisbon_fire_department: CONTRIBUTOR
```

This allows users to have expertise and authority in some areas while learning in others.

## Application Workflow

### 1. User Applies to Group

User creates an application explaining their qualifications and desired role:

1. User navigates to group page
2. Clicks "Apply to Join"
3. Fills out application form:
   - Requested role (contributor, moderator, admin, guest)
   - Motivation and experience
   - Geographic location
4. Signs application with NOSTR key
5. Application saved to `candidates/{CALLSIGN}_application.txt`

### 2. Group Admin/Moderator Reviews

Authorized members review applications:

- **Admins** can approve any role
- **Moderators** can approve contributor and guest applications
- Review includes checking:
  - User's reputation in other groups
  - Stated qualifications
  - Need for role in group
  - Geographic coverage needs

### 3. Decision Made

Reviewer makes decision:

**Approve:**
1. Add decision record section to application file
2. Set `decision: approved` and `approved_role`
3. Add decision maker details and signature
4. Provide detailed reason for approval
5. Move file from `candidates/pending/` to `candidates/approved/`
6. Add user to `members.txt` with approved role
7. Notify user of approval

**Reject:**
1. Add decision record section to application file
2. Set `decision: rejected` and `approved_role: null`
3. Add decision maker details and signature
4. Provide detailed reason for rejection with constructive feedback
5. Move file from `candidates/pending/` to `candidates/rejected/`
6. Notify user with reason and suggestions for improvement

### 4. Audit Trail

All decisions are permanently recorded within the application file itself:
- Complete application history in one file
- Decision maker's signature for authentication
- Timestamp of decision
- Applicant details and introduction
- Requested vs approved role
- Detailed reason for decision
- References for verification

This creates accountability and transparency while keeping all related information in one place for easy review and audit.

## Moderation and Data Curation

### Hierarchical Trust Model

Groups operate in a hierarchical trust model:

1. **Collection Admins**: Manage groups, resolve disputes, system-wide oversight
2. **Group Admins**: Manage group membership and areas, approve high-priority content
3. **Group Moderators**: Review and approve/reject submitted content
4. **Group Contributors**: Submit content for review, participate in curation
5. **Group Guests**: View content, report issues, limited participation

### Content Approval Workflow

1. User submits data (report, place, news, etc.) in a group's area of responsibility
2. Submission is flagged for review by the relevant collection-specific group
3. Group moderators review the submission
4. Approved content is marked as verified by the group
5. Rejected content is flagged with reason (spam, inaccurate, duplicate)

### Verification Levels

Content can have different verification levels:

- **Unverified**: Submitted but not reviewed
- **Group Verified**: Approved by at least one group moderator
- **Authority Verified**: Approved by authority group (police, fire, admin)
- **Multi-Verified**: Approved by multiple independent groups
- **Rejected**: Flagged as inaccurate or spam

### Anti-Vandalism Features

1. **Area-based responsibility**: Groups only moderate content in their defined areas
2. **Multi-signature verification**: Important content requires multiple approvals
3. **Audit trail**: All approvals/rejections are signed and logged
4. **Reputation tracking**: Members build reputation through accurate contributions
5. **Dispute resolution**: Collection admins resolve conflicts between groups
6. **Application screening**: New members vetted before joining

## Group Permissions Summary

### What Collection Admins Can Do:
- Create, modify, and delete groups
- Add/remove group admins
- Modify group areas of responsibility
- Resolve disputes between groups
- System-wide moderation overrides
- View all application files (pending, approved, rejected)

### What Group Admins Can Do:
- Everything moderators can do
- Add/remove group members
- Promote members to moderators
- Modify group description and metadata
- Define and modify areas of responsibility
- Approve any role application
- View group analytics and activity

### What Group Moderators Can Do:
- Everything contributors can do
- Review content submissions in group areas
- Approve/reject content with reasoning
- Hide inappropriate content
- Edit group-verified content
- Approve contributor/guest applications
- View moderation history

### What Group Contributors Can Do:
- Everything guests can do
- Submit content for review
- Edit own submissions
- Participate in discussions
- Vote on content quality
- Apply for moderator role

### What Group Guests Can Do:
- View group information and areas
- Read public content
- Report inappropriate content
- Apply to become a contributor
- Limited participation (collection-type dependent)

## Overlapping Areas

When multiple groups have overlapping areas:

1. **Priority-based**: Higher priority groups get first review opportunity
2. **Type-based**: Authority groups take precedence over social groups
3. **Multi-verification**: Content in overlap zones can be verified by multiple groups
4. **Consensus building**: Conflicting verdicts require admin mediation
5. **Collection-specific priority**: Collection-specific groups have priority for their content type

## NOSTR Integration

### Signatures

All group operations support NOSTR signatures:

1. Admin list entries include npub and signature
2. Group member entries include npub and signature
3. Application files include npub and signature
4. Decision logs include npub and signature of decision maker
5. Moderation actions are signed for audit trails
6. Content approvals/rejections are cryptographically signed

### Verification

Signatures verify:
- Admin authority for group management
- Member identity for submissions
- Decision maker identity for applications
- Moderator actions for audit
- Anti-spoofing and non-repudiation

## Timestamp Format

Timestamps use the format: `YYYY-MM-DD HH:MM_ss`

Example: `2025-11-25 14:30_45`

Note the underscore before seconds.

## Character Encoding

All group files use UTF-8 encoding.

## Line Endings

Files use Unix-style line endings (`\n`).

## Maximum Lengths

**Core Fields:**
- Group name (directory): 64 characters
- Group title: 255 characters
- Group description: 2000 characters
- Area name: 255 characters
- Area notes: 1000 characters
- Member callsign: 32 characters

**Application Fields:**
- Application introduction: 5000 characters
- Application experience: 500 characters
- Application location: 255 characters
- Decision reason: 1000 characters
- References: 10 maximum per application

**Photos:**
- Photo filename: 255 characters
- Photo description: 1000 characters
- Photo tags: 255 characters (comma-separated)
- Photo file size: 10 MB maximum
- Comment on photo: 500 characters

**News:**
- News title: 255 characters
- News author callsign: 32 characters
- News tags: 500 characters (comma-separated)
- News content: 50000 characters (markdown)
- Comment on news: 1000 characters

**Alerts:**
- Alert ID: 32 characters
- Alert title: 255 characters
- Alert message: 5000 characters
- Alert severity: 10 characters (enum value)

**Chat:**
- Chat message: 2000 characters
- Chat attachment filename: 255 characters
- Chat attachment size: 25 MB maximum
- Messages per day file: Unlimited (one file per day)

## Parsing Rules

**General:**
1. JSON files must be valid UTF-8 encoded JSON
2. All text files use UTF-8 encoding
3. Timestamps use format: `YYYY-MM-DD HH:MM_ss`
4. Coordinates must be valid WGS84 decimal degrees
5. Signature fields must contain valid hex-encoded signatures

**Members & Applications:**
6. `members.txt` must start with `# GROUP:` header
7. Member entries start with role prefix: `ADMIN:`, `MODERATOR:`, `CONTRIBUTOR:`, `GUEST:`
8. Application files use key-value format: `key: value`
9. Application filenames follow format: `YYYY-MM-DD_{CALLSIGN}_application.txt`
10. Applications are organized in subdirectories: `pending/`, `approved/`, `rejected/`
11. Multi-line fields like `introduction` continue until next key or section marker
12. References section uses list format with `- ` prefix
13. Decision record section starts with `--- DECISION RECORD ---` marker

**Configuration:**
14. config.json features object maps feature names to boolean values
15. config.json permissions object maps permission names to role arrays
16. Role arrays must contain only valid roles: `admin`, `moderator`, `contributor`, `guest`
17. Group type must match one of the defined types
18. Collection type must match existing collection types if specified
19. Radius must be positive number in kilometers

**Photos:**
20. Photo filenames should be descriptive (no SHA1 hashing)
21. Reaction files stored in `.reactions/` with `.txt` extension
22. Reaction files use photo filename + `.txt`: `photo.jpg` → `.reactions/photo.jpg.txt`
23. Reaction entries start with `> YYYY-MM-DD HH:MM_ss -- CALLSIGN`
24. Reaction metadata lines start with `-->`

**News:**
25. News filenames follow format: `YYYY-MM-DD_title-slug.md`
26. News files use markdown with YAML frontmatter
27. Frontmatter enclosed in `---` delimiters
28. News organized by year in subdirectories: `2025/`, `2024/`, etc.
29. News attachments stored in `year/files/` with SHA1 naming
30. Classification must be: `normal`, `urgent`, or `danger`
31. Reactions section starts after `---` separator
32. Comments section follows reactions after another `---` separator

**Alerts:**
33. Alert filenames follow format: `YYYY-MM-DD_alert-slug.txt`
34. Alert files use key-value format: `key: value`
35. Alert ID format: `alert_YYYYMMDD_NNN` (sequential per day)
36. Severity must be: `info`, `warning`, `urgent`, or `danger`
37. Status must be: `active` or `archived`
38. Active alerts in `alerts/active/`, archived in `alerts/archived/`
39. Multi-line message field continues until signature field

**Chat:**
40. Chat filenames follow format: `YYYY-MM-DD_chat.txt`
41. One chat file per day, organized by year
42. Chat files start with `# GROUP CHAT:` header
43. Message entries start with `> YYYY-MM-DD HH:MM_ss -- CALLSIGN`
44. Cross-group posts include `[GROUP NAME]` in header
45. Message metadata lines start with `-->`
46. Required metadata: `npub`, `message`, `signature`
47. Optional metadata: `reply_to`, `attachment`, `from_group`, `from_group_type`, `posting_as`
48. Chat attachments stored in `year/files/` with SHA1 naming
49. Deleted messages replaced with tombstone entries
50. Multi-line messages continue until next metadata line or next message

## Example Complete Group

### groups/lisbon_fire/group.json
```json
{
  "group": {
    "name": "lisbon_fire",
    "title": "Lisbon Fire Department",
    "description": "Fire safety, emergency response, and hazard prevention for Lisbon metropolitan area",
    "type": "authority_fire",
    "collection_type": null,
    "created": "2025-11-25 11:00_00",
    "updated": "2025-11-25 14:30_00",
    "status": "active"
  }
}
```

### groups/lisbon_fire/members.txt
```
# GROUP: Lisbon Fire Department
# TYPE: authority_fire
# Created: 2025-11-25 11:00_00

ADMIN: CR7BBQ
--> npub: npub1abc123def456789...
--> joined: 2025-11-25 11:00_00
--> signature: 0123456789abcdef...

MODERATOR: X135AS
--> npub: npub1xyz789ghi012345...
--> joined: 2025-11-25 11:15_00
--> signature: fedcba9876543210...

CONTRIBUTOR: PT4XYZ
--> npub: npub1qrs345tuv678901...
--> joined: 2025-11-25 12:00_00
--> signature: 123abc456def7890...

GUEST: CT1AAA
--> npub: npub1mno678pqr901234...
--> joined: 2025-11-25 13:00_00
```

### groups/lisbon_fire/areas.json
```json
{
  "areas": [
    {
      "id": "area_downtown",
      "name": "Lisbon Downtown",
      "center": {
        "latitude": 38.7223,
        "longitude": -9.1393
      },
      "radius_km": 3.0,
      "priority": "high",
      "notes": "Primary responsibility area including Baixa, Chiado, and Alfama districts"
    },
    {
      "id": "area_belem",
      "name": "Belém District",
      "center": {
        "latitude": 38.6979,
        "longitude": -9.2065
      },
      "radius_km": 2.5,
      "priority": "high",
      "notes": "Historic monuments and waterfront area"
    },
    {
      "id": "area_airport",
      "name": "Airport Zone",
      "center": {
        "latitude": 38.7756,
        "longitude": -9.1354
      },
      "radius_km": 4.0,
      "priority": "medium",
      "notes": "Shared responsibility with airport authority"
    }
  ],
  "updated": "2025-11-25 14:30_00"
}
```

### groups/lisbon_fire/candidates/pending/2025-11-25_CT2ABC_application.txt
```
group: Lisbon Fire Department
applicant: CT2ABC
npub: npub1stu901vwx234567...
applied: 2025-11-25 14:00_00
status: pending
requested_role: contributor
location: Lisbon, Alfama district
experience: 5 years volunteer firefighter

references:
- npub1abc123def456... (CR7BBQ - Training supervisor)
- npub1xyz789ghi012... (X135AS - Fellow volunteer)

introduction:
I am a volunteer firefighter with 5 years of experience in emergency response and fire prevention. I have been actively involved with the Alfama volunteer fire brigade since 2020, participating in over 100 emergency calls and numerous fire safety education programs in local schools.

I would like to help moderate emergency reports and provide community education about fire safety in my neighborhood. Living in the historic Alfama district, I understand the unique fire safety challenges of densely populated areas with older buildings, and I am committed to helping our community stay informed and safe.

My volunteer experience has taught me the importance of accurate, timely information during emergencies. I believe I can contribute meaningfully to the moderation team by helping verify fire-related reports and ensuring the community receives reliable information.

signature: stu901vwx2345678...
```

### groups/lisbon_fire/candidates/approved/2025-11-24_PT4XYZ_application.txt
```
group: Lisbon Fire Department
applicant: PT4XYZ
npub: npub1qrs345tuv678901...
applied: 2025-11-24 10:30_00
status: approved
requested_role: contributor
location: Lisbon, Bairro Alto
experience: 3 years community safety volunteer

references:
- npub1abc123def456... (CR7BBQ - Community safety coordinator)
- npub1mno678pqr901... (CT1AAA - Neighborhood association president)

introduction:
I am an active community safety volunteer with 3 years of experience working with local neighborhood associations on fire prevention and emergency preparedness. While I don't have professional firefighting experience, I have completed first responder training and am deeply committed to community safety.

I want to contribute to the Lisbon Fire Department group as a way to help my community stay safe and informed. I believe that accurate reporting and community education are essential components of fire prevention, and I am eager to learn from professional firefighters while helping moderate community reports.

My background in community organizing has taught me how to communicate effectively with diverse audiences and verify information from multiple sources. I am committed to maintaining high standards of accuracy and would value the opportunity to contribute to this important public safety initiative.

signature: 123abc456def7890...

---
DECISION RECORD
---

decision: approved
decided_by: CR7BBQ
decided_by_npub: npub1abc123def456789...
decided_at: 2025-11-24 12:15_00
approved_role: contributor
decision_reason: Active volunteer with good community reputation and strong references. Demonstrates genuine commitment to public safety and community service. Introduction shows good understanding of moderation responsibilities. Approved for contributor role with mentorship from experienced moderators.
decision_signature: abc123def4567890...
```

### groups/lisbon_fire/candidates/rejected/2025-11-23_CT3XYZ_application.txt
```
group: Lisbon Fire Department
applicant: CT3XYZ
npub: npub1uvw567xyz890123...
applied: 2025-11-23 09:00_00
status: rejected
requested_role: moderator
location: Unknown
experience: None specified

references:

introduction:
I want to be a moderator.

signature: uvw567xyz8901234...

---
DECISION RECORD
---

decision: rejected
decided_by: X135AS
decided_by_npub: npub1xyz789ghi012345...
decided_at: 2025-11-23 11:00_00
approved_role: null
decision_reason: Application lacks sufficient detail about qualifications and experience. No references provided. Introduction does not demonstrate understanding of moderation responsibilities or commitment to public safety. Recommend reapplying with more detailed introduction, relevant experience, and at least one reference. Consider applying for guest role first to learn about the group's activities.
decision_signature: 987fedcba6543210...
```

## Example Collection-Specific Group

### groups/blog_moderators/group.json
```json
{
  "group": {
    "name": "blog_moderators",
    "title": "Regional Blog Moderators",
    "description": "Curate and moderate blog posts for quality and accuracy in the Lisbon region",
    "type": "collection_moderator",
    "collection_type": "blog",
    "created": "2025-11-25 10:00_00",
    "updated": "2025-11-25 10:00_00",
    "status": "active"
  }
}
```

### groups/blog_moderators/members.txt
```
# GROUP: Regional Blog Moderators
# TYPE: collection_moderator
# COLLECTION: blog
# Created: 2025-11-25 10:00_00

ADMIN: CR7BBQ
--> npub: npub1abc123def456789...
--> joined: 2025-11-25 10:00_00
--> signature: 0123456789abcdef...

MODERATOR: X135AS
--> npub: npub1xyz789ghi012345...
--> joined: 2025-11-25 10:30_00
--> signature: fedcba9876543210...

MODERATOR: PT4XYZ
--> npub: npub1qrs345tuv678901...
--> joined: 2025-11-25 11:00_00
--> signature: 123abc456def7890...

CONTRIBUTOR: CT1AAA
--> npub: npub1mno678pqr901234...
--> joined: 2025-11-25 11:30_00
```

### groups/blog_moderators/areas.json
```json
{
  "areas": [
    {
      "id": "area_lisbon",
      "name": "Greater Lisbon",
      "center": {
        "latitude": 38.7223,
        "longitude": -9.1393
      },
      "radius_km": 15.0,
      "priority": "high",
      "notes": "Primary coverage for Lisbon metropolitan area blog content"
    }
  ],
  "updated": "2025-11-25 10:00_00"
}
```

## Implementation Notes

**Core Structure:**
- Group directories must have valid filesystem names (no special characters)
- Area radius calculations use haversine formula for spherical distance
- Overlapping areas are detected automatically by the system
- Member npub keys must be validated before adding to groups
- Group type determines default permissions and capabilities
- JSON files are validated on read/write operations
- Areas can be visualized on map view with circle overlays
- Priority determines review order when multiple groups claim responsibility
- Same npub can appear in multiple groups' `members.txt` with different roles

**Membership & Applications:**
- Application files are automatically created when users apply via UI
- Applications start in `candidates/pending/` subdirectory
- After decision, files are moved to `candidates/approved/` or `candidates/rejected/`
- Filename format `YYYY-MM-DD_{CALLSIGN}_application.txt` enables chronological sorting
- Decision record is appended to application file (not a separate log)
- All application history remains in one file for easy audit
- References can be contacted via their npub to verify candidate qualifications
- Introduction letter demonstrates candidate's communication skills and motivation
- Decision signatures are verified against decision maker's npub

**Feature Configuration:**
- config.json controls which features are enabled per group
- Permissions are checked against user's role before allowing actions
- Feature directories (photos/, news/, alerts/, chat/) created only when features are enabled
- Admins can enable/disable features at any time
- Changes to config.json are logged with timestamps

**Photos Feature:**
- Photos stored with descriptive filenames in photos/ directory
- .reactions/ subdirectory contains reaction files for each photo
- Photo uploads verified for format and size limits
- SHA1 hashing not used for photos (use descriptive names instead)
- Reactions tracked per-photo in separate text files

**News Feature:**
- News files organized by year in subdirectories (2025/, 2024/, etc.)
- Markdown format with YAML frontmatter for metadata
- Files referenced in news stored in year/files/ with SHA1 naming
- Expired news can be auto-archived or kept for historical record
- Classifications (normal, urgent, danger) determine display priority

**Alerts Feature:**
- Alerts organized into active/ and archived/ subdirectories
- Active alerts displayed prominently in UI
- Expired alerts automatically moved to archived/
- Alert severity determines notification level and UI presentation
- Geographic filtering based on coordinates and radius

**Chat Feature:**
- One chat file per day, automatically created on first message
- Files organized by year (2025/, 2024/, etc.)
- Messages appended in real-time to daily file
- File attachments stored in year/files/ with SHA1 naming
- Message retention enforced based on config.json settings
- Old messages deleted after retention period expires

**Cross-Group Messaging:**
- Users can select which group identity to post with
- Cross-group posts include from_group metadata fields
- UI displays cross-group posts with "[GROUP NAME]" badge
- Permissions checked in both source and target groups
- Cross-group posting requires allow_cross_group_posts in both groups

**Collection Integration:**
- Collection-specific groups are automatically created when collection is initialized
- Groups can be deactivated but not deleted (for audit trail preservation)
- Group verification badges appear on content they've approved
- Multi-group verification possible for content in overlapping areas

## Integration with Other Collection Types

Groups integrate with other collection types for moderation:

### Reports
- Groups can verify report accuracy
- Authority groups provide official status updates
- Health groups validate medical emergency reports
- Collection-specific report group moderates all reports in area

### News
- Groups can verify news authenticity
- Admin groups provide official announcements
- Multiple group verification builds credibility
- Collection-specific news group moderates all news in area

### Events
- Groups can endorse or certify events
- Authority groups provide safety clearances
- Admin groups grant official event status
- Collection-specific events group moderates all events in area

### Places
- Groups maintain accurate place information
- Infrastructure groups update facility status
- Admin groups manage official landmarks
- Collection-specific places group moderates all places in area

### Forums
- Groups moderate forum discussions
- Authority groups provide official responses
- Collection-specific forum group moderates all threads in area

### Blogs
- Groups curate high-quality blog content
- Expert groups verify technical accuracy
- Collection-specific blog group moderates all posts in area

## Summary

Geogram groups provide:

**Core Organization:**
✅ Hierarchical organization for community moderation
✅ Geographic area-based responsibility with coordinates and radius
✅ Multiple group types for different organizations
✅ Four-tier role system: Admin, Moderator, Contributor, Guest
✅ Same user can belong to multiple groups with different roles
✅ Collection-specific groups for each collection type (except Files)
✅ Autonomous group operation within jurisdiction

**Membership Management:**
✅ Application workflow with organized candidate system (pending/approved/rejected folders)
✅ Date-prefixed filenames for chronological sorting (YYYY-MM-DD_{CALLSIGN}_application.txt)
✅ Reference system for vouching candidates
✅ Introduction letter requirement for candidates
✅ Approval/rejection decisions embedded in application files with signatures
✅ Complete audit trail in single file per candidate

**Group Features (Modular & Configurable):**
✅ Photo gallery with reactions and community engagement
✅ News publishing with classifications (normal, urgent, danger)
✅ Alert system for urgent announcements (active/archived)
✅ Public chat with real-time messaging
✅ Cross-group messaging (post in other groups with group identity badge)
✅ Configurable feature permissions per group (config.json)
✅ Comments system (can be enabled/disabled per group)

**Communication & Collaboration:**
✅ Cross-group identity system ("Brito [police]" format)
✅ User can choose which group identity to post with
✅ File attachments in chat and photos
✅ Message replies and threading
✅ Reactions on photos and news items

**Security & Trust:**
✅ Anti-vandalism through multi-signature verification
✅ Audit trail for all membership and moderation actions
✅ NOSTR integration for cryptographic verification
✅ Transparent decision making with signed logs
✅ Message deletion with tombstone entries for audit trail

**Geographic & Moderation:**
✅ Flexible area definition with radius-based coverage
✅ Priority system for overlapping jurisdictions
✅ Integration with all collection types for data curation
✅ Wikipedia-style collaborative knowledge building
✅ Distributed trust network model
