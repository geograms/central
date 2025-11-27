# Relay Format Specification

**Version**: 1.5 (Draft)
**Last Updated**: 2025-11-26
**Status**: Draft

## Table of Contents

- [Overview](#overview)
- [Relay Architecture](#relay-architecture)
- [Root Relay vs Node Relay](#root-relay-vs-node-relay)
- [File Organization](#file-organization)
- [Relay Configuration](#relay-configuration)
  - [Node Storage Configuration](#node-storage-configuration)
  - [Binary Data Handling](#binary-data-handling)
  - [Cache Management](#cache-management)
- [Authority Hierarchy](#authority-hierarchy)
- [Network Federation](#network-federation)
- [User Collection Approval](#user-collection-approval)
- [Public Collections (Canonical)](#public-collections-canonical)
- [Offline Operation and Peer-to-Peer Sync](#offline-operation-and-peer-to-peer-sync)
- [Collection Synchronization](#collection-synchronization)
- [Connection Points and Participation Scoring](#connection-points-and-participation-scoring)
- [Trust and Reputation](#trust-and-reputation)
- [Moderation System](#moderation-system)
- [Anti-Spam Protection](#anti-spam-protection)
- [Connection Protocols](#connection-protocols)
- [Discovery Mechanisms](#discovery-mechanisms)
- [Channel Bridging](#channel-bridging)
- [Storage Management](#storage-management)
- [Complete Examples](#complete-examples)
- [Validation Rules](#validation-rules)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)
- [Related Documentation](#related-documentation)
- [Change Log](#change-log)

## Overview

This document specifies the format and behavior for Geogram relay nodes. A relay is a device (desktop, mobile, or dedicated hardware) that bridges geogram devices across different networks, enabling decentralized data synchronization and message delivery without requiring central servers.

The relay system creates a mesh network where devices can discover each other, exchange collections, and propagate updates across geographic and network boundaries.

### Key Features

- **Decentralized Network**: No central server required; any device can become a relay
- **Hierarchical Authority**: Root relays define network policy; nodes inherit and enforce rules
- **Network Bridging**: Connect devices across WiFi, LAN, Bluetooth, and internet boundaries
- **Collection Sync**: Synchronize collections (reports, places, contacts, etc.) across the mesh
- **Store-and-Forward**: Cache and deliver messages for offline recipients
- **Moderation Propagation**: Anti-spam and content moderation flows from root to nodes
- **Trust Network**: Reputation-based trust scoring for relay operators
- **NOSTR Integration**: Cryptographic identity for all relay operators

### Use Cases

- **Community Networks**: Local community shares data through federated relays
- **Disaster Response**: Mesh network when internet is unavailable
- **Event Coordination**: Festival or conference attendees share information
- **Regional Data Hubs**: Cities or regions operate root relays for local data
- **Offline-First Communities**: Remote areas with intermittent connectivity
- **Privacy-Focused Networks**: No central logging, distributed trust

## Relay Architecture

### Network Topology

```
                    ┌─────────────────┐
                    │   Root Relay    │
                    │  (Network Owner)│
                    │   npub1root...  │
                    └────────┬────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │ Node Relay  │   │ Node Relay  │   │ Node Relay  │
    │  Region A   │   │  Region B   │   │  Region C   │
    └──────┬──────┘   └──────┬──────┘   └──────┬──────┘
           │                 │                 │
     ┌─────┴─────┐     ┌─────┴─────┐     ┌─────┴─────┐
     │           │     │           │     │           │
  ┌──▼──┐     ┌──▼──┐──▼──┐     ┌──▼──┐──▼──┐     ┌──▼──┐
  │Device│   │Device│Device│   │Device│Device│   │Device│
  └─────┘   └─────┘└─────┘   └─────┘└─────┘   └─────┘
```

### Relay Roles

| Role | Description | Responsibilities |
|------|-------------|------------------|
| **Root Relay** | Network owner/founder | Defines policies, appoints admins, ultimate authority |
| **Network Admin** | Appointed by root | Manages node relays, appoints group admins |
| **Group Admin** | Manages collection types | Curates content, appoints moderators |
| **Moderator** | Content moderation | Hides spam, enforces community guidelines |
| **Node Operator** | Runs a node relay | Provides connectivity, follows network rules |
| **Contributor** | Creates content | Submits data through the network |

### What Makes a Relay

A device becomes a relay when it:

1. **Enables Relay Mode**: User activates relay functionality in settings
2. **Generates Relay Identity**: Creates a new NOSTR keypair (npub/nsec) specifically for the relay
3. **Assigns Relay Callsign**: Receives a callsign with X3 prefix (e.g., X3LB9K, X3PT01)
4. **Joins a Network**: Connects to a root relay or operates as independent root
5. **Accepts Connections**: Listens for incoming device connections
6. **Synchronizes Data**: Exchanges collections with connected peers

### Callsign Prefixes

Geogram uses callsign prefixes to identify entity types:

| Prefix | Entity Type | Description |
|--------|-------------|-------------|
| X1 | User/Operator | Human operators and administrators |
| X3 | Relay | Relay nodes (both root and node relays) |

**Callsign Format**:
- Maximum length: 6 characters total (including the 2-character prefix)
- X1 prefix: 4 characters for the user callsign (e.g., X1CR7B, X1PT4X)
- X3 prefix: 4 characters derived from the relay's npub key (e.g., X3LB9K, X3RL1P)

**X3 Callsign Generation**:
When a relay is created, its X3 callsign is automatically generated from the first 4 valid characters of the relay's npub key (after the "npub1" prefix), converted to uppercase alphanumeric format. This ensures:
- Unique callsigns tied to cryptographic identity
- Deterministic generation from the public key
- Easy verification of callsign-to-npub mapping

**Important**: A relay has its own cryptographic identity (npub/nsec) separate from its operator. This allows:
- Relay identity to persist even if operator changes
- Clear separation between operator actions and relay actions
- Relay-to-relay authentication independent of human operators
- Revocation of relay without affecting operator's personal identity

## Root Relay vs Node Relay

### Root Relay

The root relay is the authoritative source for a relay network. It defines:

- **Network Identity**: Unique network identifier and name
- **Network Policies**: Acceptable content, size limits, retention rules
- **Authority Structure**: Who can administer, moderate, and contribute
- **Federation Rules**: Which other networks to peer with
- **Collection Types**: Which collection types the network supports

**Root Relay Characteristics**:
- Created by network founder
- Single root per network (can have backup roots for redundancy)
- All policy changes originate from root
- Holds the master copy of authority lists
- Can revoke any node's membership

### Node Relay

Node relays extend the network by:

- **Bridging Connections**: Connect local devices to the broader network
- **Caching Data**: Store collections for local access and offline use
- **Enforcing Policy**: Apply root-defined rules to local content
- **Propagating Updates**: Forward new content to root and peers
- **Serving Clients**: Respond to device sync requests

**Node Relay Characteristics**:
- Registers with a root relay
- Inherits policies from root
- Operates within defined geographic/topical scope
- Can be revoked by root or network admins
- May operate in degraded mode if disconnected from root

### Comparison Table

| Aspect | Root Relay | Node Relay |
|--------|------------|------------|
| Network Authority | Ultimate | Delegated |
| Policy Definition | Creates policies | Inherits/enforces policies |
| Admin Appointment | Appoints all admins | Cannot appoint admins |
| Moderator Control | Appoints group admins | Can request moderators |
| Collection Scope | All network collections | Subset or geographic scope |
| Revocation Power | Can revoke any node | Cannot revoke peers |
| Identity Source | Self-signed | Root-signed certificate |
| Operates Independently | Yes | Limited (follows cached policy) |

## File Organization

### Relay Directory Structure

```
relay/
├── relay.json                          # Relay identity and configuration
├── network.json                        # Network membership and root info
├── authorities/
│   ├── root.txt                        # Root relay identity
│   ├── admins/                         # Network administrators (one file per X1 callsign)
│   │   ├── X1CR7B.txt
│   │   ├── X1PT4X.txt
│   │   └── X1AD3X.txt
│   ├── group-admins/
│   │   ├── reports/                    # Report collection group admins (X1 callsigns)
│   │   │   ├── X1FR1P.txt
│   │   │   └── X1CT2P.txt
│   │   ├── places/                     # Places collection group admins
│   │   │   └── X1GE1P.txt
│   │   └── events/                     # Events collection group admins
│   │       └── X1EV1P.txt
│   └── moderators/                      # Moderators (X1 callsigns)
│       ├── reports/                    # Report moderators
│       │   ├── X1VL1P.txt
│       │   └── X1VL2P.txt
│       ├── places/                     # Places moderators
│       │   └── X1MD1P.txt
│       └── events/                     # Events moderators
│           └── X1MD2P.txt
├── policies/
│   ├── network-policy.json             # Network-wide rules
│   ├── content-policy.json             # Content guidelines
│   ├── retention-policy.json           # Data retention rules
│   └── federation-policy.json          # Peering rules
├── collections/
│   ├── approved/                       # User collections approved for sync
│   │   ├── {collection_id}.txt         # Approved collection metadata
│   │   └── ...
│   ├── pending/                        # Collections awaiting approval
│   │   └── {collection_id}.txt
│   ├── suspended/                      # Temporarily suspended collections
│   │   └── {collection_id}.txt
│   └── banned/                         # Permanently banned collections
│       └── {collection_id}.txt
├── public/                             # Root-defined public collections (canonical)
│   ├── forum/                          # Public forum (synced from root)
│   ├── chat/                           # Public chat (synced from root)
│   └── announcements/                  # Network announcements
├── peers/
│   ├── nodes/                          # Connected node relays
│   │   ├── {callsign}.txt              # Node info per callsign
│   │   └── ...
│   └── federated/
│       ├── {network_id}.txt            # Federated network info
│       └── ...
├── banned/
│   ├── users/                          # Banned users (one file per callsign)
│   │   ├── X1SP1X.txt
│   │   └── ...
│   └── content/                        # Banned content hashes
│       └── {hash}.txt
├── reputation/                         # User reputation (one file per callsign)
│   ├── X1CR7B.txt
│   ├── X1PT4X.txt
│   └── ...
├── sync/
│   ├── topology.json                   # Network topology and node connections
│   ├── nodes/                          # Per-node sync state
│   │   ├── {callsign}.json
│   │   └── ...
│   └── queue/
│       ├── outbound/                   # Pending outbound sync
│       └── inbound/                    # Pending inbound processing
└── logs/
    ├── connections.log                 # Connection history
    ├── moderation.log                  # Moderation actions
    └── sync.log                        # Sync activity
```

### Relay Identity File (relay.json)

The relay has its own cryptographic identity, separate from the operator who manages it. The relay callsign uses the X3 prefix, while the operator uses their personal X1 callsign.

```json
{
  "relay": {
    "id": "a7f3b9e1d2c4f6a8",
    "callsign": "X3LB9K",
    "npub": "npub1relay789...",
    "name": "Lisbon Community Relay",
    "description": "Community relay serving the greater Lisbon area",
    "type": "node",
    "version": "1.0",
    "created": "2025-11-26 10:00_00",
    "updated": "2025-11-26 10:00_00"
  },
  "operator": {
    "callsign": "X1CR7B",
    "npub": "npub1operator123...",
    "contact": "operator@example.com"
  },
  "capabilities": {
    "max_connections": 100,
    "max_storage_gb": 50,
    "supported_collections": ["reports", "places", "events", "contacts", "news"],
    "supported_protocols": ["websocket", "bluetooth", "lan", "lora", "wifi_halow", "espmesh", "espnow"]
  },
  "location": {
    "latitude": 38.7223,
    "longitude": -9.1393,
    "radius_km": 50,
    "description": "Greater Lisbon Area"
  },
  "uptime": {
    "since": "2025-11-26 10:00_00",
    "expected_availability": "24/7"
  }
}
```

**Note**:
- The `relay.id` field uses the collection's auto-generated ID (typically a hex string). This ID is created when the relay collection is first initialized and remains constant throughout the relay's lifetime.
- The `relay.callsign` uses the X3 prefix to identify it as a relay device.
- The `relay.npub` is the relay's own NOSTR public key, generated when the relay is created.
- The `operator.callsign` uses the X1 prefix to identify a human operator.

### Network Membership File (network.json)

```json
{
  "network": {
    "id": "portugal-community-network",
    "name": "Portugal Community Network",
    "description": "Federated relay network for Portuguese communities",
    "root_callsign": "X3PT1R",
    "root_npub": "npub1root456...",
    "root_url": "wss://root.example.com/relay"
  },
  "membership": {
    "joined": "2025-11-26 10:00_00",
    "status": "active",
    "role": "node",
    "certificate": "base64-encoded-root-signed-certificate"
  },
  "sync": {
    "last_root_sync": "2025-11-26 15:30_00",
    "last_authority_update": "2025-11-26 15:30_00",
    "last_policy_update": "2025-11-26 14:00_00"
  }
}
```

## Relay Configuration

### Root Relay Configuration

```json
{
  "root": {
    "network_id": "portugal-community-network",
    "network_name": "Portugal Community Network",
    "relay_callsign": "X3PT1R",
    "relay_npub": "npub1rootrelay...",
    "founded": "2025-11-01 00:00_00",
    "founder_callsign": "X1FD1X",
    "founder_npub": "npub1founder789..."
  },
  "authority": {
    "require_registration": true,
    "require_approval": false,
    "auto_approve_contributors": true,
    "moderator_threshold": 3
  },
  "content": {
    "allowed_collections": ["reports", "places", "events", "contacts", "news", "forum"],
    "max_file_size_mb": 50,
    "max_collection_size_gb": 10,
    "require_signatures": true
  },
  "moderation": {
    "enable_community_flagging": true,
    "flag_threshold_hide": 5,
    "flag_threshold_review": 10,
    "auto_ban_threshold": 20
  },
  "retention": {
    "default_ttl_days": 365,
    "emergency_ttl_days": 30,
    "resolved_report_ttl_days": 90
  },
  "federation": {
    "allow_federation": true,
    "auto_accept_peers": false,
    "trusted_networks": ["npub1trusted1...", "npub1trusted2..."]
  }
}
```

### Node Relay Configuration

When a device decides to become a node relay, it needs to configure several settings that determine how it participates in the network.

#### Node Setup Requirements

To become a node relay, the device must:

1. **Have a valid identity**: NOSTR keypair (npub/nsec)
2. **Connect to a root relay**: Obtain network membership
3. **Allocate storage**: Reserve disk space for caching
4. **Configure scope**: Define what data to cache and serve

#### Basic Node Configuration (node-config.json)

```json
{
  "node": {
    "name": "Lisbon Downtown Relay",
    "description": "Community relay serving downtown Lisbon area",
    "network_id": "portugal-community-network",
    "root_url": "wss://root.example.com/relay"
  },
  "relay": {
    "callsign": "X3LD1K",
    "npub": "npub1relay1...",
    "nsec": "nsec1relay1secret..."
  },
  "operator": {
    "callsign": "X1ND1P",
    "npub": "npub1operator...",
    "contact": "operator@example.com"
  },
  "scope": {
    "geographic": {
      "center": {"latitude": 38.7223, "longitude": -9.1393},
      "radius_km": 25
    },
    "collections": ["reports", "places", "events", "public_forum", "public_chat"],
    "collection_filters": {
      "reports": {"severity": ["emergency", "urgent", "attention"]},
      "events": {"max_age_days": 30}
    }
  },
  "schedule": {
    "availability": "24/7",
    "maintenance_window": "Sunday 03:00-05:00 UTC"
  }
}
```

### Node Storage Configuration

Nodes cache data from the root relay and connected peers. Storage is primarily allocated for text files to maximize capacity and longevity.

#### Storage Philosophy: Text-First

The relay system prioritizes text data over binary data:

| Data Type | Storage Priority | Reason |
|-----------|-----------------|--------|
| **Text files** (.txt, .json, .md) | High | Small size, essential content |
| **Metadata** | High | Required for sync and validation |
| **Thumbnails** | Medium | Small binary, aids navigation |
| **Images** | Low | Large, optional for relay function |
| **Videos/Audio** | Very Low | Very large, rarely cached |
| **Attachments** | Minimal | Only cached on explicit request |

#### Storage Configuration (storage-config.json)

```json
{
  "storage": {
    "base_path": "/var/lib/geogram-relay",
    "total_allocated_mb": 500,
    "warning_threshold_percent": 80,
    "critical_threshold_percent": 95
  },
  "allocation": {
    "text_content": {
      "max_mb": 300,
      "priority": "high",
      "description": "Text files, JSON, markdown - core relay data"
    },
    "metadata": {
      "max_mb": 50,
      "priority": "high",
      "description": "Sync state, indexes, authority files"
    },
    "thumbnails": {
      "max_mb": 50,
      "priority": "medium",
      "description": "Small preview images (max 10KB each)"
    },
    "binary_cache": {
      "max_mb": 100,
      "priority": "low",
      "description": "Optional binary files, cleared first when space needed"
    }
  },
  "binary_policy": {
    "cache_binaries": false,
    "cache_thumbnails": true,
    "thumbnail_max_kb": 10,
    "binary_on_demand": true,
    "binary_ttl_hours": 24
  },
  "cleanup": {
    "auto_cleanup": true,
    "cleanup_interval_hours": 6,
    "preserve_text_content": true,
    "binary_cleanup_first": true
  }
}
```

#### Storage Allocation by Collection Type

```json
{
  "collection_storage": {
    "public_forum": {
      "max_mb": 50,
      "text_only": true,
      "sync_full_history": false,
      "history_days": 90
    },
    "public_chat": {
      "max_mb": 30,
      "text_only": true,
      "sync_full_history": false,
      "history_days": 30
    },
    "reports": {
      "max_mb": 100,
      "text_only": true,
      "cache_thumbnails": true,
      "sync_geographic": true,
      "geographic_radius_km": 50
    },
    "places": {
      "max_mb": 50,
      "text_only": true,
      "cache_thumbnails": true,
      "sync_geographic": true
    },
    "events": {
      "max_mb": 30,
      "text_only": true,
      "sync_future_only": true,
      "future_days": 90
    },
    "user_collections": {
      "max_mb": 40,
      "text_only": true,
      "subscribed_only": true
    },
    "authorities": {
      "max_mb": 10,
      "text_only": true,
      "sync_always": true,
      "never_delete": true
    }
  }
}
```

### Binary Data Handling

By default, nodes do not cache binary data (images, videos, files). This policy ensures:

- **Longer storage life**: Text is orders of magnitude smaller
- **Faster sync**: Only essential data transferred
- **Lower bandwidth**: Reduced network usage
- **Broader reach**: Works on constrained devices (ESP32, Raspberry Pi)

#### Binary Handling Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **text_only** | Never cache binaries | Low-storage devices, LoRa relays |
| **thumbnails_only** | Cache small previews only | Standard relay operation |
| **on_demand** | Fetch binaries when requested | Desktop relays with more storage |
| **full_cache** | Cache all data | High-capacity dedicated relays |

#### Text-Only Mode Configuration

```json
{
  "binary_policy": {
    "mode": "text_only",
    "cache_binaries": false,
    "cache_thumbnails": false,
    "forward_binary_requests": true,
    "binary_source": "origin"
  }
}
```

When a client requests a binary file:
1. Node checks if cached (usually not in text_only mode)
2. Node forwards request to origin (root or author device)
3. Origin sends binary directly to client
4. Node does not store the binary

#### Thumbnails-Only Mode Configuration

```json
{
  "binary_policy": {
    "mode": "thumbnails_only",
    "cache_binaries": false,
    "cache_thumbnails": true,
    "thumbnail_max_dimensions": {"width": 100, "height": 100},
    "thumbnail_max_kb": 10,
    "thumbnail_format": "webp",
    "generate_thumbnails": false,
    "accept_thumbnails_from": ["root", "author"]
  }
}
```

#### On-Demand Mode Configuration

```json
{
  "binary_policy": {
    "mode": "on_demand",
    "cache_binaries": true,
    "binary_max_size_mb": 5,
    "binary_ttl_hours": 24,
    "binary_cleanup_on_space_pressure": true,
    "popular_threshold": 3,
    "cache_popular_binaries": true
  }
}
```

### Cache Management

#### Cache Priority (What to Keep)

When storage is limited, prioritize:

1. **Authority files** (never delete)
2. **Sync state and metadata** (essential for operation)
3. **Recent text content** (last 7 days)
4. **Active/urgent reports** (regardless of age)
5. **Subscribed user collections**
6. **Older text content** (30-90 days)
7. **Thumbnails** (delete when space needed)
8. **Binary cache** (delete first)

#### Cache Eviction Policy

```json
{
  "eviction": {
    "policy": "lru_with_priority",
    "never_evict": [
      "authorities/*",
      "sync/topology.json",
      "network.json",
      "relay.json"
    ],
    "evict_first": [
      "binary_cache/*",
      "thumbnails/*"
    ],
    "evict_by_age": {
      "public_chat": {"max_age_days": 30},
      "public_forum": {"max_age_days": 90},
      "events": {"past_events_days": 7}
    },
    "evict_by_distance": {
      "enabled": true,
      "keep_radius_km": 25,
      "extended_radius_km": 100,
      "extended_keep_days": 7
    }
  }
}
```

#### Storage Monitoring

```json
{
  "monitoring": {
    "check_interval_minutes": 30,
    "alert_on_warning": true,
    "alert_on_critical": true,
    "auto_cleanup_on_warning": false,
    "auto_cleanup_on_critical": true,
    "report_to_root": true
  }
}
```

### Minimal Node Configuration

For resource-constrained devices (ESP32, Raspberry Pi Zero, etc.):

```json
{
  "node": {
    "name": "Minimal LoRa Relay",
    "type": "minimal"
  },
  "storage": {
    "total_allocated_mb": 50,
    "mode": "text_only"
  },
  "allocation": {
    "text_content": {"max_mb": 35},
    "metadata": {"max_mb": 10},
    "authorities": {"max_mb": 5}
  },
  "binary_policy": {
    "mode": "text_only",
    "cache_binaries": false,
    "cache_thumbnails": false
  },
  "sync": {
    "collections": ["reports", "authorities"],
    "reports_filter": {"severity": ["emergency", "urgent"]},
    "geographic_radius_km": 10,
    "history_days": 7
  },
  "schedule": {
    "sync_interval_minutes": 60,
    "power_saving": true
  }
}
```

### Standard Node Configuration

For typical desktop/server relays:

```json
{
  "node": {
    "name": "Community Relay",
    "type": "standard"
  },
  "storage": {
    "total_allocated_mb": 500
  },
  "allocation": {
    "text_content": {"max_mb": 300},
    "metadata": {"max_mb": 50},
    "thumbnails": {"max_mb": 50},
    "binary_cache": {"max_mb": 100}
  },
  "binary_policy": {
    "mode": "thumbnails_only",
    "cache_thumbnails": true,
    "thumbnail_max_kb": 10
  },
  "sync": {
    "collections": ["reports", "places", "events", "public_forum", "public_chat", "authorities"],
    "geographic_radius_km": 50,
    "history_days": 90
  }
}
```

### High-Capacity Node Configuration

For dedicated relay servers with ample storage:

```json
{
  "node": {
    "name": "Regional Hub Relay",
    "type": "high_capacity"
  },
  "storage": {
    "total_allocated_mb": 10000
  },
  "allocation": {
    "text_content": {"max_mb": 5000},
    "metadata": {"max_mb": 500},
    "thumbnails": {"max_mb": 1000},
    "binary_cache": {"max_mb": 3500}
  },
  "binary_policy": {
    "mode": "on_demand",
    "cache_binaries": true,
    "binary_max_size_mb": 10,
    "binary_ttl_hours": 168
  },
  "sync": {
    "collections": "all",
    "geographic_radius_km": 200,
    "history_days": 365,
    "full_public_collections": true
  }
}
```

### Node Setup Wizard

When setting up a new node, the application guides through:

```
┌─────────────────────────────────────────────────────────────┐
│                  NODE RELAY SETUP WIZARD                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Step 1: Network Connection                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Root Relay URL: [wss://root.example.com/relay    ]  │   │
│  │ Status: ✓ Connected                                 │   │
│  │ Network: Portugal Community Network                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Step 2: Storage Allocation                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Available disk space: 50 GB                         │   │
│  │                                                     │   │
│  │ Allocate to relay: [  500  ] MB                     │   │
│  │                                                     │   │
│  │ Recommended:                                        │   │
│  │   • Minimal (50 MB)  - LoRa/constrained devices    │   │
│  │   • Standard (500 MB) - Desktop/Raspberry Pi       │   │
│  │   • High (10 GB) - Dedicated server                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Step 3: Binary Data Policy                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ( ) Text only - Maximum storage efficiency          │   │
│  │ (•) Thumbnails only - Balanced (recommended)        │   │
│  │ ( ) On-demand - Cache popular binaries              │   │
│  │ ( ) Full cache - Store everything                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Step 4: Geographic Scope                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Center: [38.7223], [-9.1393] (current location)     │   │
│  │ Radius: [  50  ] km                                 │   │
│  │                                                     │   │
│  │ ○ Cache data within this radius                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Step 5: Collections to Cache                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [✓] Reports (emergency, urgent, attention)          │   │
│  │ [✓] Places                                          │   │
│  │ [✓] Events (future 90 days)                         │   │
│  │ [✓] Public Forum (last 90 days)                     │   │
│  │ [✓] Public Chat (last 30 days)                      │   │
│  │ [ ] User Collections (subscribed only)              │   │
│  │ [✓] Authority Files (always synced)                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│                    [ Cancel ]  [ < Back ]  [ Finish ]       │
└─────────────────────────────────────────────────────────────┘
```

### Storage Status Display

```
┌─────────────────────────────────────────────────────────────┐
│                    RELAY STORAGE STATUS                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Total Allocated: 500 MB                                    │
│  Used: 342 MB (68%)  ████████████████░░░░░░░░               │
│                                                             │
│  By Category:                                               │
│  ├─ Text Content:  245 MB / 300 MB  ████████████████░░░    │
│  │  ├─ Reports:      85 MB                                 │
│  │  ├─ Places:       42 MB                                 │
│  │  ├─ Events:       18 MB                                 │
│  │  ├─ Public Forum: 55 MB                                 │
│  │  ├─ Public Chat:  25 MB                                 │
│  │  └─ User Colls:   20 MB                                 │
│  │                                                         │
│  ├─ Metadata:       38 MB /  50 MB  ████████████████░░░░   │
│  ├─ Thumbnails:     32 MB /  50 MB  █████████████░░░░░░░   │
│  └─ Binary Cache:   27 MB / 100 MB  █████░░░░░░░░░░░░░░░   │
│                                                             │
│  Items Cached:                                              │
│  ├─ Reports:        1,520 items (85 MB text, 15 MB thumbs) │
│  ├─ Places:           830 items (42 MB text, 8 MB thumbs)  │
│  ├─ Events:           156 items (18 MB text)               │
│  ├─ Forum Posts:    2,500 items (55 MB text)               │
│  ├─ Chat Messages:  8,000 items (25 MB text)               │
│  └─ User Collections:  45 items (20 MB text)               │
│                                                             │
│  Binary Cache:                                              │
│  ├─ Thumbnails:     1,250 files (32 MB)                    │
│  └─ On-demand:         12 files (27 MB, expires in 18h)    │
│                                                             │
│  Last Cleanup: 2025-11-26 14:00 UTC                        │
│  Next Cleanup: 2025-11-26 20:00 UTC (auto)                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Authority Hierarchy

### Authority Flow

```
┌────────────────────────────────────────────────────────────────┐
│                         ROOT RELAY                              │
│  - Defines network policies                                     │
│  - Appoints/revokes Network Admins                             │
│  - Ultimate ban authority                                       │
│  - Signs node certificates                                      │
└─────────────────────────┬──────────────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────────────┐
│                      NETWORK ADMINS                             │
│  - Manage node registrations                                    │
│  - Appoint/revoke Group Admins                                 │
│  - Handle escalated moderation                                  │
│  - Monitor network health                                       │
└─────────────────────────┬──────────────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────────────┐
│                       GROUP ADMINS                              │
│  - Manage specific collection types (reports, places, etc.)    │
│  - Appoint/revoke Moderators for their collection              │
│  - Curate featured content                                      │
│  - Define collection-specific guidelines                        │
└─────────────────────────┬──────────────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────────────┐
│                        MODERATORS                               │
│  - Review flagged content                                       │
│  - Hide inappropriate content                                   │
│  - Warn users about guideline violations                        │
│  - Escalate serious issues to Group Admins                     │
└────────────────────────────────────────────────────────────────┘
```

### Authority Files

Each authority (admin, group admin, moderator) has their own individual file named by callsign. This makes it simple to add, update, or remove authorities - just add or delete the corresponding file.

#### Root Authority (authorities/root.txt)

```
# ROOT: Portugal Community Network

NPUB: npub1founder789...
CALLSIGN: X1ROOT
CREATED: 2025-11-01 00:00_00
LAST_ACTIVE: 2025-11-26 15:00_00

Network founder and ultimate authority.

Public keys for verification:
- Primary: npub1founder789...
- Backup: npub1backup123...

--> signature: root_self_signature_here...
```

#### Network Admin (authorities/admins/X1CR7B.txt)

One file per admin callsign (X1 prefix for human operators). To remove an admin, simply delete their file.

```
# ADMIN: X1CR7B

CALLSIGN: X1CR7B
NPUB: npub1admin1...
APPOINTED: 2025-11-05 10:00_00
APPOINTED_BY: npub1founder789...
REGIONS: Lisbon, Setúbal
STATUS: active

Experienced network operator with 5+ years in community networks.

--> appointed_by_npub: npub1founder789...
--> signature: root_signature_for_x1cr7bbq...
```

#### Network Admin (authorities/admins/X1PT4X.txt)

```
# ADMIN: X1PT4X

CALLSIGN: X1PT4X
NPUB: npub1admin2...
APPOINTED: 2025-11-10 14:00_00
APPOINTED_BY: npub1founder789...
REGIONS: Porto, Braga
STATUS: active

Manages northern Portugal relay network.

--> appointed_by_npub: npub1founder789...
--> signature: root_signature_for_x1pt4xyz...
```

#### Group Admin (authorities/group-admins/reports/X1FR1P.txt)

One file per group admin callsign (X1 prefix for human operators), organized by collection type.

```
# GROUP ADMIN: X1FR1P
# COLLECTION: reports

CALLSIGN: X1FR1P
NPUB: npub1fireadmin...
APPOINTED: 2025-11-06 10:00_00
APPOINTED_BY: npub1admin1...
SCOPE: Emergency reports, Fire hazards
STATUS: active

Fire department liaison for emergency report verification.

--> appointed_by_npub: npub1admin1...
--> signature: admin_signature_for_x1fire1pt...
```

#### Moderator (authorities/moderators/reports/X1VL1P.txt)

One file per moderator callsign (X1 prefix for human operators), organized by collection type.

```
# MODERATOR: X1VL1P
# COLLECTION: reports

CALLSIGN: X1VL1P
NPUB: npub1mod1...
APPOINTED: 2025-11-08 10:00_00
APPOINTED_BY: npub1fireadmin...
SCOPE: Lisbon downtown
STATUS: active

Community volunteer moderating downtown Lisbon reports.

--> appointed_by_npub: npub1fireadmin...
--> signature: groupadmin_signature_for_vol1pt...
```

#### Removing Authorities

To remove an admin, group admin, or moderator:

1. Delete their individual file
2. Optionally move to a `revoked/` subfolder with revocation reason:

```
# authorities/admins/revoked/X1PT4X.txt

# REVOKED ADMIN: X1PT4X

CALLSIGN: X1PT4X
NPUB: npub1admin2...
ORIGINAL_APPOINTED: 2025-11-10 14:00_00
REVOKED: 2025-11-26 10:00_00
REVOKED_BY: npub1founder789...
REASON: Inactive for 90 days

--> revoked_by_npub: npub1founder789...
--> signature: root_revocation_signature...
```

### Authority Propagation

When root updates authority lists:

1. **Root Signs Update**: Root signs the updated authority file
2. **Push to Nodes**: Root pushes update to all connected nodes
3. **Nodes Verify**: Nodes verify signature chain (root → admin → group admin)
4. **Apply Locally**: Nodes update their local authority cache
5. **Propagate Down**: Nodes inform connected devices of changes

```
Timeline:

T+0:   Root updates admins.txt, signs with root key
T+1s:  Root pushes to connected nodes
T+5s:  Nodes verify root signature
T+10s: Nodes apply new admin list
T+15s: Nodes notify connected devices
T+30s: All devices have updated authority info
```

### Authority Revocation

Revocations take immediate effect and propagate urgently:

```
# REVOCATION: Network Admin

REVOKED: X1PT4X
--> npub: npub1admin2...
--> revoked_by: npub1founder789...
--> revoked_at: 2025-11-26 10:00_00
--> reason: Inactive for 90 days
--> effective: immediate
--> propagation: urgent

--> signature: root_revocation_signature...
```

## Network Federation

### Federation Overview

Relay networks can federate with each other, allowing:

- **Cross-Network Search**: Find content from federated networks
- **Content Mirroring**: Cache popular content from peer networks
- **Redundancy**: Backup when primary network is unreachable
- **Geographic Coverage**: Extend reach through partnerships

### Federation Agreement

```json
{
  "federation": {
    "local_network": "portugal-community-network",
    "peer_network": "spain-community-network",
    "established": "2025-11-20 10:00_00",
    "status": "active"
  },
  "trust_level": "trusted",
  "sharing": {
    "share_reports": true,
    "share_places": true,
    "share_events": true,
    "share_contacts": false,
    "share_authority_lists": true
  },
  "moderation": {
    "honor_bans": true,
    "require_review": false,
    "auto_flag_threshold": 10
  },
  "signatures": {
    "local_root": "npub1portugal_root...",
    "local_signature": "portugal_federation_signature...",
    "peer_root": "npub1spain_root...",
    "peer_signature": "spain_federation_signature..."
  }
}
```

## User Collection Approval

The root relay controls which user collections are allowed to sync across the network. Some collection types (like shops, businesses, or advertisements) require explicit approval before being distributed.

### Approval Workflow

```
User Creates Collection
         │
         ▼
┌─────────────────────┐
│  Submit for Review  │ ── User requests network inclusion
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Pending Approval   │ ── collections/pending/{id}.txt
└─────────┬───────────┘
          │
    ┌─────┴─────┐
    ▼           ▼
 Approve      Reject
    │           │
    ▼           ▼
collections/  collections/
approved/     banned/
    │
    ▼
Synced to
All Nodes
```

### Collection States

| State | Directory | Description |
|-------|-----------|-------------|
| **pending** | `collections/pending/` | Awaiting admin/moderator approval |
| **approved** | `collections/approved/` | Approved and synced across network |
| **suspended** | `collections/suspended/` | Temporarily suspended (can be reinstated) |
| **banned** | `collections/banned/` | Permanently banned from network |

### Approval Required Collections

The root defines which collection types require approval:

```json
{
  "approval_policy": {
    "require_approval": ["shops", "businesses", "services", "advertisements"],
    "auto_approve": ["reports", "places", "events"],
    "admin_only": ["announcements", "official_notices"]
  }
}
```

### Pending Collection (collections/pending/f3d8a2b1c4e5.txt)

```
# PENDING COLLECTION: f3d8a2b1c4e5

COLLECTION_ID: f3d8a2b1c4e5
TYPE: shops
OWNER: X1CR7B
OWNER_NPUB: npub1user123...
SUBMITTED: 2025-11-26 10:00_00
TITLE: Lisbon Tech Shop
DESCRIPTION: Electronics and repair services in downtown Lisbon

Location: 38.7223, -9.1393
Website: https://example.com

--> owner_signature: user_submission_signature...
```

### Approved Collection (collections/approved/f3d8a2b1c4e5.txt)

```
# APPROVED COLLECTION: f3d8a2b1c4e5

COLLECTION_ID: f3d8a2b1c4e5
TYPE: shops
OWNER: X1CR7B
OWNER_NPUB: npub1user123...
SUBMITTED: 2025-11-26 10:00_00
APPROVED: 2025-11-26 14:00_00
APPROVED_BY: X1PT4X
APPROVED_BY_NPUB: npub1admin2...
STATUS: active

TITLE: Lisbon Tech Shop
DESCRIPTION: Electronics and repair services in downtown Lisbon

Location: 38.7223, -9.1393
Website: https://example.com

--> owner_signature: user_submission_signature...
--> approval_signature: admin_approval_signature...
```

### Suspended Collection (collections/suspended/f3d8a2b1c4e5.txt)

```
# SUSPENDED COLLECTION: f3d8a2b1c4e5

COLLECTION_ID: f3d8a2b1c4e5
TYPE: shops
OWNER: X1CR7B
OWNER_NPUB: npub1user123...
ORIGINAL_APPROVED: 2025-11-26 14:00_00
SUSPENDED: 2025-11-28 16:00_00
SUSPENDED_BY: X1VL1P
SUSPENDED_BY_NPUB: npub1mod1...
REASON: Multiple user complaints about inaccurate information
DURATION: 7 days
REINSTATE_DATE: 2025-12-05 16:00_00

TITLE: Lisbon Tech Shop

--> suspension_signature: moderator_suspension_signature...
```

### Banned Collection (collections/banned/f3d8a2b1c4e5.txt)

```
# BANNED COLLECTION: f3d8a2b1c4e5

COLLECTION_ID: f3d8a2b1c4e5
TYPE: shops
OWNER: X1CR7B
OWNER_NPUB: npub1user123...
BANNED: 2025-11-30 10:00_00
BANNED_BY: X1PT4X
BANNED_BY_NPUB: npub1admin2...
REASON: Fraudulent business, multiple verified complaints
PERMANENT: true

Previous suspensions:
- 2025-11-28: Inaccurate information (7 days)

TITLE: Lisbon Tech Shop (BANNED)

--> ban_signature: admin_ban_signature...
```

### Who Can Approve/Suspend/Ban

| Action | Who Can Perform |
|--------|-----------------|
| Approve pending | Admins, Group Admins (for their collection type) |
| Suspend approved | Admins, Group Admins, Moderators |
| Reinstate suspended | Admins, Group Admins |
| Ban (permanent) | Admins only |
| Unban | Root only |

## Public Collections (Canonical)

Public collections are defined and hosted by the root relay. They are the canonical source of truth - all updates flow through the root, and nodes sync from the root.

### Public Collection Types

| Collection | Purpose | Sync Direction |
|------------|---------|----------------|
| **forum** | Network-wide discussion | Users → Root → Nodes |
| **chat** | Real-time network chat | Users → Root → Nodes |
| **announcements** | Official network announcements | Root → Nodes (read-only) |
| **documentation** | Network guides and help | Root → Nodes (read-only) |

### Sync Flow for Public Collections

```
┌──────────────────────────────────────────────────────────────┐
│                        ROOT RELAY                             │
│                   (Canonical Source)                          │
│                                                              │
│  public/forum/      public/chat/      public/announcements/  │
└─────────────────────────┬────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │  Node A   │   │  Node B   │   │  Node C   │
    │  (copy)   │   │  (copy)   │   │  (copy)   │
    └─────┬─────┘   └─────┬─────┘   └─────┬─────┘
          │               │               │
          ▼               ▼               ▼
      Devices         Devices         Devices
```

### User Contribution Flow

When a user posts to a public collection:

1. **User submits** post to their connected node
2. **Node forwards** to root relay
3. **Root validates** (signatures, permissions, content policy)
4. **Root accepts/rejects** the submission
5. **If accepted**: Root adds to canonical collection
6. **Root broadcasts** update to all nodes
7. **Nodes sync** and update their local copies

### Public Forum Structure (public/forum/)

```
public/forum/
├── forum.json                          # Forum configuration
├── categories/
│   ├── general/
│   │   ├── category.json
│   │   └── threads/
│   │       ├── 2025-11-26_welcome-thread.txt
│   │       └── 2025-11-26_rules-discussion.txt
│   ├── technical/
│   │   ├── category.json
│   │   └── threads/
│   │       └── 2025-11-25_setup-help.txt
│   └── regional/
│       ├── category.json
│       └── threads/
│           └── 2025-11-24_lisbon-meetup.txt
└── moderation/
    ├── hidden/
    └── reported/
```

### Public Chat Structure (public/chat/)

```
public/chat/
├── chat.json                           # Chat configuration
├── channels/
│   ├── general/
│   │   ├── channel.json
│   │   └── messages/
│   │       ├── 2025-11-26.txt          # Daily message log
│   │       └── 2025-11-25.txt
│   ├── emergency/
│   │   ├── channel.json
│   │   └── messages/
│   │       └── 2025-11-26.txt
│   └── regional/
│       └── lisbon/
│           ├── channel.json
│           └── messages/
│               └── 2025-11-26.txt
└── moderation/
    └── hidden/
```

### Announcements Structure (public/announcements/)

Announcements are read-only for all except root admins.

```
public/announcements/
├── announcements.json
├── active/
│   ├── 2025-11-26_network-maintenance.txt
│   └── 2025-11-20_welcome-message.txt
└── archived/
    └── 2025-11-15_beta-launch.txt
```

### Announcement Format

```
# ANNOUNCEMENT: Network Maintenance Scheduled

CREATED: 2025-11-26 10:00_00
AUTHOR: X1ROOT
AUTHOR_NPUB: npub1founder789...
PRIORITY: normal
EXPIRES: 2025-11-28 00:00_00

## Network Maintenance Scheduled

The relay network will undergo scheduled maintenance on
November 28th from 02:00 to 04:00 UTC.

During this time:
- Sync may be delayed
- Some nodes may be temporarily offline
- Emergency channels remain active

Thank you for your patience.

--> npub: npub1founder789...
--> signature: root_announcement_signature...
```

### Canonical Source Enforcement

When root is online, nodes respect root as the canonical source:

1. **Forward submissions**: User posts forwarded to root for processing
2. **Sync from root**: Periodic pull from root to update local copy
3. **Version tracking**: Nodes track their version vs root version
4. **Conflict resolution**: Root version always wins when online

**Important**: Public collections support peer-to-peer sync when root is offline. See [Offline Operation](#offline-operation-and-peer-to-peer-sync) for details.

## Offline Operation and Peer-to-Peer Sync

Network connectivity to the root relay is not guaranteed. Nodes may be disconnected from root for extended periods due to network issues, geographic isolation, or root maintenance. The relay system is designed to continue operating in these conditions.

### Collection Ownership Model

Understanding who "owns" a collection determines sync behavior:

| Collection Type | Owner | Write Access | Sync Source |
|-----------------|-------|--------------|-------------|
| **Public collections** (forum, chat, etc.) | Root relay | Users submit, root accepts | Root when online; peer-to-peer when offline |
| **User collections** (blogs, shops, etc.) | Author device | Author device only | Author device |
| **Network data** (reports, places, events) | Community | Any authorized user | Peer-to-peer with signature validation |

### Sync Rules by Collection Type

#### 1. Public Collections (Root-Owned)

Public collections like forum, chat, and announcements are owned by the root relay but can sync between nodes when root is offline.

**When Root is Online**:
```
User Post → Node → Root (validates) → All Nodes
                      ↓
               Canonical Version
```

**When Root is Offline**:
```
User Post → Node A → Signs with user's nsec
                ↓
            Node B, C, D (peer-to-peer sync)
                ↓
         Marked as "pending_root_confirmation"
                ↓
         When root online: Root validates → Canonical
```

**Peer-to-Peer Public Collection Sync**:

```json
{
  "public_forum_sync": {
    "collection": "public/forum",
    "sync_mode": "peer_to_peer",
    "root_status": "offline",
    "root_last_seen": "2025-11-26 10:00_00",
    "local_changes": [
      {
        "id": "msg_a7f3b9e1",
        "type": "forum_post",
        "author": "X1CR7B",
        "author_npub": "npub1user123...",
        "timestamp": "2025-11-26 15:30_00",
        "status": "pending_root_confirmation",
        "synced_to_nodes": ["X3RL1P", "X3RL2P"],
        "signature": "author_signature..."
      }
    ],
    "pending_root_sync": 15
  }
}
```

**Rules for Peer-to-Peer Public Collection Sync**:

1. **User posts are signed**: All submissions signed with author's nsec
2. **Nodes accept signed posts**: Verify signature before accepting
3. **Mark as pending**: Posts marked `pending_root_confirmation`
4. **Sync between nodes**: Nodes exchange pending posts peer-to-peer
5. **Root reconciliation**: When root online, validates and confirms posts
6. **Rejection handling**: Root can reject invalid posts; nodes remove them

#### 2. User Collections (Author-Owned)

User collections (blogs, shops, personal data) can only be modified by the author's device. Other devices can subscribe and sync read-only.

**Write Access**:
```
Author Device → Creates/Modifies → Signs with nsec
                                        ↓
                                  Collection Updated
```

**Read Access (Subscribers)**:
```
Author Device → Node A → Node B → Subscriber Device
                  ↓         ↓
            Sync (read-only copies)
```

**Subscriber Sync Rules**:

1. **Read-only**: Subscribers cannot add or modify items
2. **Author is source**: Author device is always source of truth
3. **Signature required**: All items signed by author
4. **Peer-to-peer allowed**: Nodes can sync user collections between themselves
5. **No modifications**: Nodes relay exactly what author published

**User Collection Sync State**:

```json
{
  "user_collection_sync": {
    "collection_id": "f3d8a2b1c4e5",
    "type": "blog",
    "owner": "X1CR7B",
    "owner_npub": "npub1user123...",
    "owner_device_id": "device_abc123",
    "sync_mode": "author_source",
    "last_author_sync": "2025-11-26 14:00_00",
    "local_version": 50,
    "items_count": 120,
    "subscribers": ["X3RL1P", "X3RL2P", "device_xyz789"],
    "write_access": "author_only"
  }
}
```

**Attempting to Write to Another's Collection**:

```
Subscriber Device → Attempts to add item → REJECTED
                                              ↓
                                    "Error: Write access denied.
                                     Only author device can modify
                                     this collection."
```

#### 3. Network Collections (Community-Owned)

Reports, places, and events are community collections where any authorized user can contribute.

**Write Access**:
- Any user with sufficient reputation
- Must sign contributions with nsec
- Subject to moderation

**Sync Rules**:
- Peer-to-peer sync allowed
- Signature validation required
- No single source of truth (distributed)
- Conflicts resolved by timestamp + authority level

### Offline Operation Modes

#### Mode 1: Root Temporarily Offline

Root expected to return soon (hours/days).

```
┌─────────────────────────────────────────────────────┐
│                    ROOT (Offline)                    │
│                   Last seen: 2h ago                  │
└─────────────────────────────────────────────────────┘
                         ╳
           ┌─────────────┼─────────────┐
           │             │             │
    ┌──────▼──────┐ ┌────▼────┐ ┌──────▼──────┐
    │   Node A    │◄─────────►│   Node B    │
    │  (active)   │           │  (active)   │
    └──────┬──────┘           └──────┬──────┘
           │                         │
           └─────────┬───────────────┘
                     │
              ┌──────▼──────┐
              │   Node C    │
              │  (active)   │
              └─────────────┘

Nodes sync peer-to-peer, queue changes for root
```

**Behavior**:
- Nodes continue operating normally
- Public collection changes queued as "pending"
- User collections sync normally (author-based)
- When root returns, pending items reconciled

#### Mode 2: Root Extended Offline

Root offline for extended period (days/weeks).

**Behavior**:
- Nodes elect temporary coordinator (highest reliability score)
- Coordinator tracks pending changes
- Network continues full operation
- All changes still require user signatures
- Root reconciliation when available

**Temporary Coordinator**:

```json
{
  "offline_mode": {
    "root_status": "extended_offline",
    "root_last_seen": "2025-11-20 10:00_00",
    "temporary_coordinator": {
      "callsign": "X3RL1P",
      "npub": "npub1relay1...",
      "elected": "2025-11-21 00:00_00",
      "election_reason": "highest_reliability_score",
      "reliability_score": 98
    },
    "pending_root_reconciliation": {
      "forum_posts": 150,
      "chat_messages": 2500,
      "user_collections_updated": 45
    }
  }
}
```

#### Mode 3: Partitioned Network

Some nodes can reach root, others cannot.

```
┌─────────────────────────────────────────────────────┐
│                      ROOT                            │
│                   (Online)                           │
└────────────────────┬────────────────────────────────┘
                     │
           ┌─────────┴─────────┐
           │                   │
    ┌──────▼──────┐     ┌──────▼──────┐
    │   Node A    │     │   Node B    │
    │ (connected) │     │ (connected) │
    └─────────────┘     └─────────────┘

    ════════════════ NETWORK PARTITION ════════════════

    ┌─────────────┐     ┌─────────────┐
    │   Node C    │◄───►│   Node D    │
    │ (isolated)  │     │ (isolated)  │
    └─────────────┘     └─────────────┘
```

**Behavior**:
- Connected nodes (A, B) sync with root normally
- Isolated nodes (C, D) sync peer-to-peer
- When partition heals:
  - Isolated nodes receive root-confirmed changes
  - Isolated nodes' pending changes sent to root
  - Root validates and confirms or rejects

### Peer-to-Peer Sync Protocol

#### Sync Handshake

```
Node A → Node B: {
  "type": "sync_hello",
  "node": "X3RL1P",
  "npub": "npub1relay1...",
  "root_status": "offline",
  "root_last_seen": "2025-11-26 10:00_00",
  "collections": {
    "public_forum": {"version": 100, "pending": 5},
    "public_chat": {"version": 500, "pending": 12},
    "user_X1CR7B_blog": {"version": 50, "owner_synced": "2025-11-26 14:00_00"}
  }
}

Node B → Node A: {
  "type": "sync_hello_ack",
  "node": "X3RL2P",
  "root_status": "offline",
  "collections": {
    "public_forum": {"version": 98, "pending": 3},
    "public_chat": {"version": 495, "pending": 8},
    "user_X1CR7B_blog": {"version": 50, "owner_synced": "2025-11-26 14:00_00"}
  }
}
```

#### Sync Exchange

```
Node A → Node B: {
  "type": "sync_diff",
  "collection": "public_forum",
  "items": [
    {
      "id": "post_123",
      "author": "X1CR7B",
      "author_npub": "npub1user123...",
      "timestamp": "2025-11-26 15:00_00",
      "content": "...",
      "status": "pending_root_confirmation",
      "signature": "author_signature..."
    }
  ]
}

Node B → Node A: {
  "type": "sync_diff_ack",
  "collection": "public_forum",
  "accepted": ["post_123"],
  "rejected": []
}
```

#### Validation During Peer Sync

Before accepting items from peers, nodes validate:

1. **Signature valid**: Author's signature verifies against npub
2. **Author authorized**: Author has permission to post (not banned)
3. **Timestamp reasonable**: Not too far in future, not ancient
4. **Content policy**: Passes basic content filters
5. **Not duplicate**: Item not already present

### Root Reconciliation

When root comes back online:

#### Step 1: Nodes Report Pending Changes

```
Node → Root: {
  "type": "pending_changes_report",
  "node": "X3RL1P",
  "offline_duration": "48h",
  "pending_items": {
    "public_forum": [
      {"id": "post_123", "author_npub": "npub1...", "signature": "..."},
      {"id": "post_124", "author_npub": "npub2...", "signature": "..."}
    ],
    "public_chat": [
      {"id": "msg_456", "author_npub": "npub1...", "signature": "..."}
    ]
  }
}
```

#### Step 2: Root Validates and Confirms

```
Root → Node: {
  "type": "reconciliation_result",
  "confirmed": ["post_123", "msg_456"],
  "rejected": [
    {
      "id": "post_124",
      "reason": "author_banned_during_offline_period",
      "action": "delete"
    }
  ],
  "canonical_version": {
    "public_forum": 105,
    "public_chat": 520
  }
}
```

#### Step 3: Nodes Apply Reconciliation

- Confirmed items marked as `confirmed` (no longer pending)
- Rejected items deleted from local storage
- Version numbers updated to match root
- Nodes propagate reconciliation to other peers

### Sync Priority During Offline

When syncing peer-to-peer, prioritize:

1. **Emergency content**: Emergency reports, urgent alerts
2. **Recent user collections**: Author-published updates
3. **Public collection pending items**: Forum posts, chat messages
4. **Historical sync**: Older items, backfill

### Data Integrity Guarantees

| Scenario | Guarantee |
|----------|-----------|
| User collection modified by non-author | **Rejected** - signature won't validate |
| Public post without valid signature | **Rejected** - nodes won't accept |
| Post from banned user during offline | **Accepted temporarily**, rejected at reconciliation |
| Conflicting edits to same item | **Timestamp wins**, or root decides at reconciliation |
| Fake node injecting data | **Rejected** - node certificate validation |

### Offline-Safe Operations

Operations that work fully offline (peer-to-peer):

- ✅ Reading any synced collection
- ✅ Publishing to own user collection
- ✅ Posting to public collections (pending confirmation)
- ✅ Syncing user collections from author peers
- ✅ Creating reports, places, events
- ✅ Viewing and contributing to community data

Operations that require root (eventually):

- ⏳ Confirmation of public collection posts
- ⏳ Authority changes (admin/moderator appointments)
- ⏳ User collection approval (shops, businesses)
- ⏳ Permanent bans
- ⏳ Policy updates

## Collection Synchronization

### Sync Protocol

1. **Handshake**: Devices exchange sync state (last sync time, version vectors)
2. **Diff Exchange**: Identify changes since last sync
3. **Priority Transfer**: Emergency/urgent content first
4. **Bulk Transfer**: Remaining content by collection type
5. **Verification**: Confirm all items received, validate signatures
6. **Commit**: Update sync state

### Network Topology (sync/topology.json)

The topology file represents the current state of the network: which nodes exist, their capabilities, and how they can communicate with each other.

```json
{
  "network": {
    "id": "portugal-community-network",
    "root_npub": "npub1founder789...",
    "updated": "2025-11-26 15:30_00"
  },
  "nodes": {
    "X3PT1R": {
      "callsign": "X3PT1R",
      "npub": "npub1rootrelay...",
      "relay_id": "a7f3b9e1d2c4f6a8",
      "type": "root",
      "location": {"lat": 38.7223, "lon": -9.1393},
      "status": "online",
      "last_seen": "2025-11-26 15:30_00",
      "channels": ["internet", "wifi_lan", "bluetooth"]
    },
    "X3RL1P": {
      "callsign": "X3RL1P",
      "npub": "npub1relay1...",
      "relay_id": "b8g4c0f2e3d5g7b9",
      "type": "node",
      "location": {"lat": 38.7100, "lon": -9.1500},
      "status": "online",
      "last_seen": "2025-11-26 15:28_00",
      "channels": ["internet", "wifi_lan", "bluetooth", "lora"]
    },
    "X3RL2P": {
      "callsign": "X3RL2P",
      "npub": "npub1relay2...",
      "relay_id": "c9h5d1g3f4e6h8c0",
      "type": "node",
      "location": {"lat": 41.1579, "lon": -8.6291},
      "status": "online",
      "last_seen": "2025-11-26 15:25_00",
      "channels": ["internet", "wifi_halow", "espmesh"]
    },
    "X3RL3P": {
      "callsign": "X3RL3P",
      "npub": "npub1relay3...",
      "relay_id": "d0i6e2h4g5f7i9d1",
      "type": "node",
      "location": {"lat": 37.0194, "lon": -7.9304},
      "status": "offline",
      "last_seen": "2025-11-26 10:00_00",
      "channels": ["lora", "radio", "espnow"]
    }
  },
  "connections": [
    {
      "from": "X3PT1R",
      "to": "X3RL1P",
      "channels": ["internet", "wifi_lan"],
      "quality": "excellent",
      "latency_ms": 15,
      "last_sync": "2025-11-26 15:28_00"
    },
    {
      "from": "X3PT1R",
      "to": "X3RL2P",
      "channels": ["internet"],
      "quality": "good",
      "latency_ms": 45,
      "last_sync": "2025-11-26 15:25_00"
    },
    {
      "from": "X3RL1P",
      "to": "X3RL2P",
      "channels": ["internet"],
      "quality": "good",
      "latency_ms": 50,
      "last_sync": "2025-11-26 15:20_00"
    },
    {
      "from": "X3RL1P",
      "to": "X3RL3P",
      "channels": ["lora"],
      "quality": "fair",
      "latency_ms": 500,
      "last_sync": "2025-11-26 10:00_00"
    },
    {
      "from": "X3RL2P",
      "to": "X3RL3P",
      "channels": [],
      "quality": "disconnected",
      "latency_ms": null,
      "last_sync": null
    }
  ],
  "channel_types": {
    "internet": {
      "description": "TCP/IP over internet",
      "typical_latency_ms": 20,
      "bandwidth": "high",
      "reliability": "depends on ISP"
    },
    "wifi_lan": {
      "description": "Local WiFi network",
      "typical_latency_ms": 5,
      "bandwidth": "high",
      "reliability": "high"
    },
    "wifi_halow": {
      "description": "WiFi HaLow (802.11ah) long-range low-power",
      "typical_latency_ms": 50,
      "bandwidth": "medium",
      "reliability": "high"
    },
    "bluetooth": {
      "description": "Bluetooth Low Energy",
      "typical_latency_ms": 100,
      "bandwidth": "low",
      "reliability": "medium",
      "range_m": 100
    },
    "lora": {
      "description": "LoRa long-range radio",
      "typical_latency_ms": 500,
      "bandwidth": "very low",
      "reliability": "high",
      "range_km": 15
    },
    "radio": {
      "description": "Amateur/CB radio modem",
      "typical_latency_ms": 1000,
      "bandwidth": "very low",
      "reliability": "variable",
      "range_km": 50
    },
    "espmesh": {
      "description": "ESP-MESH WiFi mesh network",
      "typical_latency_ms": 30,
      "bandwidth": "medium",
      "reliability": "high"
    },
    "espnow": {
      "description": "ESP-NOW peer-to-peer protocol",
      "typical_latency_ms": 20,
      "bandwidth": "low",
      "reliability": "high",
      "range_m": 200
    }
  }
}
```

### Per-Node Sync State (sync/nodes/X3RL1P.json)

Individual sync state for each connected node:

```json
{
  "node": {
    "callsign": "X3RL1P",
    "npub": "npub1relay1...",
    "relay_id": "b8g4c0f2e3d5g7b9"
  },
  "sync_state": {
    "last_sync": "2025-11-26 15:28_00",
    "sync_version": 12345,
    "active_channel": "wifi_lan"
  },
  "collections": {
    "reports": {
      "version": 100,
      "last_item": "2025-11-26 15:00_00",
      "items_synced": 1520,
      "pending_items": 0
    },
    "places": {
      "version": 50,
      "last_item": "2025-11-26 14:00_00",
      "items_synced": 830,
      "pending_items": 2
    },
    "events": {
      "version": 25,
      "last_item": "2025-11-26 12:00_00",
      "items_synced": 156,
      "pending_items": 0
    },
    "public_forum": {
      "version": 200,
      "last_item": "2025-11-26 15:25_00",
      "items_synced": 2500,
      "pending_items": 5,
      "canonical_source": "root"
    },
    "public_chat": {
      "version": 500,
      "last_item": "2025-11-26 15:27_00",
      "items_synced": 8000,
      "pending_items": 12,
      "canonical_source": "root"
    }
  },
  "reliability": {
    "score": 95,
    "uptime_percent": 99.5,
    "successful_syncs": 10000,
    "failed_syncs": 50
  }
}
```

### Conflict Resolution

When multiple nodes modify the same item:

1. **Timestamp Priority**: Later timestamp wins (clock sync required)
2. **Authority Override**: Higher authority always wins
3. **Merge When Possible**: Combine non-conflicting changes
4. **Preserve History**: Keep all versions for audit

## Connection Points and Participation Scoring

Users earn points for connecting to relays and participating in the network. These points accumulate into a score that determines reputation level and unlocks features.

### Points Philosophy

The points system rewards:
- **Presence**: Being connected and available to the network
- **Contribution**: Creating valuable content (reports, places, events)
- **Verification**: Helping validate others' contributions
- **Relay Support**: Running a relay node, bridging channels
- **Community**: Helping other users, moderating content

### Point Categories

| Category | Description | Points Range |
|----------|-------------|--------------|
| **Connection** | Time spent connected to relays | 1-10 pts/hour |
| **Contribution** | Creating content | 5-50 pts/item |
| **Verification** | Confirming others' reports | 2-10 pts/verification |
| **Relay Operation** | Running a node relay | 10-100 pts/day |
| **Bridging** | Forwarding messages across channels | 1-5 pts/message |
| **Storage** | Caching data for the network | 1-10 pts/MB/day |
| **Moderation** | Flagging spam, reviewing content | 5-20 pts/action |
| **Community** | Helping users, answering questions | 5-15 pts/interaction |

### Points Tracking Per Relay

Each relay tracks points for connected users:

#### User Points File (points/X1CR7B.json)

```json
{
  "user": {
    "callsign": "X1CR7B",
    "npub": "npub1user123..."
  },
  "relay": {
    "callsign": "X3RL1P",
    "npub": "npub1relay1..."
  },
  "period": {
    "start": "2025-11-01 00:00_00",
    "end": "2025-11-30 23:59_59",
    "type": "monthly"
  },
  "points": {
    "total": 1250,
    "breakdown": {
      "connection": {
        "points": 450,
        "details": {
          "hours_connected": 180,
          "points_per_hour": 2.5,
          "bonus_uptime_streak": 50
        }
      },
      "contribution": {
        "points": 420,
        "details": {
          "reports_created": 12,
          "places_added": 8,
          "events_posted": 3,
          "forum_posts": 25,
          "chat_messages": 150
        }
      },
      "verification": {
        "points": 180,
        "details": {
          "reports_verified": 45,
          "accurate_verifications": 42,
          "accuracy_rate": 0.93
        }
      },
      "community": {
        "points": 120,
        "details": {
          "helpful_responses": 15,
          "users_assisted": 8,
          "content_liked_by_others": 35
        }
      },
      "moderation": {
        "points": 80,
        "details": {
          "spam_flagged": 12,
          "flags_upheld": 10,
          "flag_accuracy": 0.83
        }
      }
    }
  },
  "multipliers": {
    "account_age_bonus": 1.2,
    "streak_bonus": 1.1,
    "quality_bonus": 1.15
  },
  "final_score": 1725,
  "updated": "2025-11-26 15:30_00",
  "relay_signature": "relay_points_signature..."
}
```

### Point Earning Rules

#### Connection Points

```json
{
  "connection_points": {
    "base_rate": {
      "points_per_hour": 1,
      "max_daily": 24
    },
    "active_bonus": {
      "description": "Bonus for being actively available (not idle)",
      "multiplier": 2.0,
      "idle_threshold_minutes": 30
    },
    "uptime_streak": {
      "description": "Consecutive days connected",
      "7_days": {"bonus": 10},
      "30_days": {"bonus": 50},
      "90_days": {"bonus": 150},
      "365_days": {"bonus": 500}
    },
    "peak_hours_bonus": {
      "description": "Bonus for being online during high-demand periods",
      "multiplier": 1.5,
      "peak_hours": ["08:00-10:00", "18:00-21:00"]
    }
  }
}
```

#### Contribution Points

```json
{
  "contribution_points": {
    "reports": {
      "emergency": 50,
      "urgent": 30,
      "attention": 20,
      "info": 10,
      "verified_bonus": 1.5,
      "first_reporter_bonus": 2.0
    },
    "places": {
      "new_place": 15,
      "detailed_description": 5,
      "with_photos": 10,
      "verified_by_others": 1.3
    },
    "events": {
      "new_event": 20,
      "community_event": 10,
      "well_attended_bonus": 25
    },
    "forum": {
      "new_thread": 10,
      "reply": 2,
      "helpful_answer": 15,
      "marked_solution": 25
    },
    "chat": {
      "message": 0.1,
      "max_daily": 10
    }
  }
}
```

#### Verification Points

```json
{
  "verification_points": {
    "verify_report": {
      "base": 5,
      "accurate_bonus": 3,
      "early_verification_bonus": 2,
      "inaccurate_penalty": -5
    },
    "verify_place": {
      "base": 3,
      "still_exists": 2,
      "updated_info": 5
    },
    "accuracy_multiplier": {
      "description": "Multiplier based on historical accuracy",
      "90_percent": 1.5,
      "80_percent": 1.2,
      "70_percent": 1.0,
      "below_70": 0.5
    }
  }
}
```

#### Relay Operation Points

```json
{
  "relay_operation_points": {
    "node_uptime": {
      "points_per_day": 50,
      "99_percent_uptime_bonus": 1.5,
      "95_percent_uptime_bonus": 1.2
    },
    "bridging": {
      "message_forwarded": 1,
      "cross_channel_bridge": 3,
      "emergency_relay": 10,
      "max_daily": 500
    },
    "storage_contribution": {
      "points_per_gb_cached": 10,
      "serving_requests": 1,
      "max_daily": 100
    },
    "network_health": {
      "helping_sync": 5,
      "peer_discovery": 10,
      "redundancy_contribution": 20
    }
  }
}
```

### Score Calculation

Points are aggregated into a score with decay and bonuses:

```json
{
  "score_calculation": {
    "base_score": "sum of all points",
    "decay": {
      "enabled": true,
      "type": "exponential",
      "half_life_days": 90,
      "minimum_retention": 0.1
    },
    "multipliers": {
      "account_age": {
        "1_month": 1.0,
        "3_months": 1.1,
        "6_months": 1.2,
        "1_year": 1.3,
        "2_years": 1.5
      },
      "verification_accuracy": {
        "high": 1.2,
        "medium": 1.0,
        "low": 0.8
      },
      "community_standing": {
        "no_warnings": 1.0,
        "warned": 0.8,
        "suspended_history": 0.5
      }
    },
    "penalties": {
      "spam_submission": -50,
      "false_verification": -20,
      "community_violation": -100,
      "temporary_ban": -500
    }
  }
}
```

### Feature Unlocking by Score

Score determines which features users can access:

#### Feature Tiers

```
┌─────────────────────────────────────────────────────────────────────┐
│                      FEATURE UNLOCK TIERS                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  TIER 0: New User (0-50 points)                                    │
│  ├─ ✓ Read all public content                                      │
│  ├─ ✓ Connect to relays                                            │
│  ├─ ✓ View maps and reports                                        │
│  ├─ ✗ Post to forum (read-only)                                    │
│  ├─ ✗ Create reports (limited to 1/day)                            │
│  └─ ✗ Chat (rate limited: 10 msgs/hour)                            │
│                                                                     │
│  TIER 1: Newcomer (51-200 points)                                  │
│  ├─ ✓ All Tier 0 features                                          │
│  ├─ ✓ Post to forum (5 posts/day)                                  │
│  ├─ ✓ Create reports (5/day)                                       │
│  ├─ ✓ Chat (50 msgs/hour)                                          │
│  ├─ ✓ Add places (2/day)                                           │
│  └─ ✗ Verify others' reports                                       │
│                                                                     │
│  TIER 2: Regular (201-500 points)                                  │
│  ├─ ✓ All Tier 1 features                                          │
│  ├─ ✓ Unlimited forum posts                                        │
│  ├─ ✓ Create reports (20/day)                                      │
│  ├─ ✓ Unlimited chat                                               │
│  ├─ ✓ Add places (10/day)                                          │
│  ├─ ✓ Verify others' reports                                       │
│  ├─ ✓ Create events                                                │
│  └─ ✗ Submit shop/business collections                             │
│                                                                     │
│  TIER 3: Trusted (501-1000 points)                                 │
│  ├─ ✓ All Tier 2 features                                          │
│  ├─ ✓ Unlimited reports                                            │
│  ├─ ✓ Submit shop/business collections                             │
│  ├─ ✓ Create public events                                         │
│  ├─ ✓ Flag content for moderation                                  │
│  ├─ ✓ Give small reputation (+5) to others                         │
│  └─ ✓ Priority sync (faster updates)                               │
│                                                                     │
│  TIER 4: Veteran (1001-5000 points)                                │
│  ├─ ✓ All Tier 3 features                                          │
│  ├─ ✓ Create groups                                                │
│  ├─ ✓ Become collection curator                                    │
│  ├─ ✓ Give reputation (+15) to others                              │
│  ├─ ✓ Access beta features                                         │
│  └─ ✓ Eligible for moderator nomination                            │
│                                                                     │
│  TIER 5: Leader (5001+ points)                                     │
│  ├─ ✓ All Tier 4 features                                          │
│  ├─ ✓ Create network-wide announcements (with approval)            │
│  ├─ ✓ Give reputation (+25) to others                              │
│  ├─ ✓ Run relay node with elevated trust                           │
│  └─ ✓ Eligible for group admin nomination                          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

#### Feature Configuration (features-config.json)

```json
{
  "feature_tiers": {
    "tier_0": {
      "name": "New User",
      "min_score": 0,
      "max_score": 50,
      "features": {
        "read_content": true,
        "connect_relay": true,
        "view_maps": true,
        "forum_post": false,
        "reports_per_day": 1,
        "chat_per_hour": 10,
        "add_places": false,
        "verify_reports": false
      }
    },
    "tier_1": {
      "name": "Newcomer",
      "min_score": 51,
      "max_score": 200,
      "features": {
        "forum_posts_per_day": 5,
        "reports_per_day": 5,
        "chat_per_hour": 50,
        "places_per_day": 2,
        "verify_reports": false
      }
    },
    "tier_2": {
      "name": "Regular",
      "min_score": 201,
      "max_score": 500,
      "features": {
        "forum_posts_per_day": -1,
        "reports_per_day": 20,
        "chat_per_hour": -1,
        "places_per_day": 10,
        "verify_reports": true,
        "create_events": true,
        "submit_business": false
      }
    },
    "tier_3": {
      "name": "Trusted",
      "min_score": 501,
      "max_score": 1000,
      "features": {
        "reports_per_day": -1,
        "submit_business": true,
        "public_events": true,
        "flag_content": true,
        "give_reputation_max": 5,
        "priority_sync": true
      }
    },
    "tier_4": {
      "name": "Veteran",
      "min_score": 1001,
      "max_score": 5000,
      "features": {
        "create_groups": true,
        "collection_curator": true,
        "give_reputation_max": 15,
        "beta_features": true,
        "moderator_eligible": true
      }
    },
    "tier_5": {
      "name": "Leader",
      "min_score": 5001,
      "max_score": -1,
      "features": {
        "network_announcements": true,
        "give_reputation_max": 25,
        "elevated_relay_trust": true,
        "group_admin_eligible": true
      }
    }
  }
}
```

### Points Aggregation Across Relays

Users may connect to multiple relays. Points are aggregated network-wide:

```json
{
  "aggregated_score": {
    "callsign": "X1CR7B",
    "npub": "npub1user123...",
    "total_score": 3250,
    "tier": "veteran",
    "by_relay": [
      {
        "relay": "X3RL1P",
        "points": 1725,
        "period": "2025-11",
        "signature": "relay1_signature..."
      },
      {
        "relay": "X3RL2P",
        "points": 980,
        "period": "2025-11",
        "signature": "relay2_signature..."
      },
      {
        "relay": "X3RL3P",
        "points": 545,
        "period": "2025-11",
        "signature": "relay3_signature..."
      }
    ],
    "historical": {
      "2025-10": 2800,
      "2025-09": 2100,
      "2025-08": 1500
    },
    "decay_applied": true,
    "effective_score": 3250,
    "updated": "2025-11-26 15:30_00"
  }
}
```

### Points Verification

Each relay signs the points it awards, enabling verification:

```json
{
  "points_certificate": {
    "type": "points_award",
    "user": {
      "callsign": "X1CR7B",
      "npub": "npub1user123..."
    },
    "relay": {
      "callsign": "X3RL1P",
      "npub": "npub1relay1..."
    },
    "period": "2025-11",
    "points_awarded": 1725,
    "breakdown_hash": "sha256_of_detailed_breakdown...",
    "issued": "2025-11-30 23:59_59",
    "expires": "2026-02-28 23:59_59",
    "relay_signature": "relay_certificate_signature..."
  }
}
```

### Anti-Gaming Measures

Prevent manipulation of the points system:

```json
{
  "anti_gaming": {
    "rate_limits": {
      "max_points_per_hour": 100,
      "max_points_per_day": 500,
      "cooldown_after_max": "1 hour"
    },
    "quality_checks": {
      "duplicate_content_penalty": -10,
      "low_quality_threshold": "flagged by 3+ users",
      "self_verification_blocked": true
    },
    "suspicious_patterns": {
      "rapid_fire_posting": "flag for review",
      "coordinated_voting": "investigate",
      "unusual_connection_patterns": "monitor"
    },
    "verification_requirements": {
      "high_value_actions": "require additional confirmation",
      "new_accounts": "enhanced monitoring for 7 days"
    },
    "decay_prevents_hoarding": {
      "points_decay": true,
      "recent_activity_weighted": true
    }
  }
}
```

### Points Dashboard

Users can view their points status:

```
┌─────────────────────────────────────────────────────────────────────┐
│                      POINTS DASHBOARD: CR7BBQ                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Total Score: 3,250 points                                         │
│  Tier: VETERAN (Tier 4)                                            │
│  Next Tier: LEADER at 5,001 points (1,751 to go)                   │
│                                                                     │
│  Progress: ████████████████████░░░░░░░░ 65%                        │
│                                                                     │
│  This Month's Points: +425                                          │
│  ├─ Connection:    +120 (180 hours online)                         │
│  ├─ Contributions: +180 (12 reports, 5 places)                     │
│  ├─ Verifications: +85  (42 accurate verifications)                │
│  └─ Community:     +40  (helping others, forum activity)           │
│                                                                     │
│  Multipliers Active:                                                │
│  ├─ Account Age (1 year):     1.3x                                 │
│  ├─ Verification Accuracy:    1.2x (93% accurate)                  │
│  └─ 30-day Streak:            +50 bonus                            │
│                                                                     │
│  Unlocked Features:                                                 │
│  ✓ Unlimited reports and forum posts                               │
│  ✓ Create groups and events                                        │
│  ✓ Give reputation to others (up to +15)                           │
│  ✓ Flag content for moderation                                     │
│  ✓ Eligible for moderator role                                     │
│                                                                     │
│  Points by Relay:                                                   │
│  ├─ RELAY1PT (Lisbon):     1,725 pts                               │
│  ├─ RELAY2PT (Porto):        980 pts                               │
│  └─ RELAY3PT (Algarve):      545 pts                               │
│                                                                     │
│  Recent Activity:                                                   │
│  ├─ Today:     +35 pts (5 verifications, 2 forum posts)            │
│  ├─ Yesterday: +42 pts (1 report, 8 verifications)                 │
│  └─ This Week: +180 pts                                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Integration with Reputation System

Points feed into the broader reputation system:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  CONNECTION POINTS           REPUTATION SCORE                   │
│  (Automated, relay-tracked)   (Manual + automated)              │
│                                                                 │
│  ┌─────────────────┐         ┌─────────────────┐               │
│  │ Connection Time │────────►│                 │               │
│  │ Contributions   │         │   Combined      │               │
│  │ Verifications   │────────►│   Reputation    │──► Feature    │
│  │ Relay Operation │         │   Score         │    Unlocks    │
│  │ Community Help  │────────►│                 │               │
│  └─────────────────┘         │                 │               │
│                              │                 │               │
│  ┌─────────────────┐         │                 │               │
│  │ Manual Grants   │────────►│                 │               │
│  │ (by admins/mods)│         │                 │               │
│  └─────────────────┘         └─────────────────┘               │
│                                                                 │
│  Points:     Objective, automated, relay-verified              │
│  Reputation: Includes points + manual grants + penalties       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Points Storage in Relay Directory

```
relay/
├── points/
│   ├── current/                        # Current period points
│   │   ├── CR7BBQ.json
│   │   ├── PT4XYZ.json
│   │   └── ...
│   ├── historical/                     # Past periods
│   │   ├── 2025-10/
│   │   │   ├── CR7BBQ.json
│   │   │   └── ...
│   │   └── 2025-09/
│   │       └── ...
│   ├── certificates/                   # Signed points certificates
│   │   ├── CR7BBQ_2025-11.txt
│   │   └── ...
│   └── aggregated/                     # Network-wide aggregation
│       ├── CR7BBQ.json
│       └── ...
```

## Trust and Reputation

### User Reputation

Each user has their own reputation file named by callsign. Reputation entries are individually signed by the person giving the reputation, creating an auditable trail.

#### Reputation File (reputation/X1CR7B.txt)

```
# REPUTATION: X1CR7B

CALLSIGN: X1CR7B
NPUB: npub1user123...
CURRENT_SCORE: 85
LEVEL: trusted
UPDATED: 2025-11-26 10:00_00

## Reputation Entries

### Entry 1
GIVEN_BY: X1ROOT
GIVEN_BY_NPUB: npub1founder789...
DATE: 2025-11-01 10:00_00
VALUE: +20
REASON: Network founding member, initial trust grant
--> signature: founder_signature_for_entry1...

### Entry 2
GIVEN_BY: X1FR1P
GIVEN_BY_NPUB: npub1fireadmin...
DATE: 2025-11-10 14:30_00
VALUE: +15
REASON: Verified 50 accurate emergency reports
--> signature: fireadmin_signature_for_entry2...

### Entry 3
GIVEN_BY: X1VL2P
GIVEN_BY_NPUB: npub1mod2...
DATE: 2025-11-15 09:00_00
VALUE: +10
REASON: Consistent high-quality place submissions
--> signature: mod2_signature_for_entry3...

### Entry 4
GIVEN_BY: X1CT2P
GIVEN_BY_NPUB: npub1cityadmin...
DATE: 2025-11-20 16:00_00
VALUE: +25
REASON: Helped resolve major infrastructure issue
--> signature: cityadmin_signature_for_entry4...

### Entry 5
GIVEN_BY: X1MD1P
GIVEN_BY_NPUB: npub1mod1...
DATE: 2025-11-22 11:00_00
VALUE: +15
REASON: Community leadership and helpful responses
--> signature: mod1_signature_for_entry5...
```

#### Reputation Entry Format

Each entry must include:
- **GIVEN_BY**: Callsign of the person giving reputation
- **GIVEN_BY_NPUB**: NOSTR public key of the giver (for verification)
- **DATE**: When the reputation was given
- **VALUE**: Positive or negative integer value
- **REASON**: Explanation for the reputation change
- **signature**: Cryptographic signature using the giver's nsec

**Validation**: The signature is verified against the GIVEN_BY_NPUB to ensure authenticity. Invalid signatures cause the entry to be ignored.

**Reputation Levels** (calculated from sum of all valid entries):
- **new** (0-20): New user, content reviewed before publishing
- **regular** (21-50): Normal user, standard rate limits
- **trusted** (51-80): Trusted contributor, relaxed limits
- **verified** (81-100): Verified contributor, priority processing

**Who Can Give Reputation**:
- **Root/Admins**: Can give ±50 per entry
- **Group Admins**: Can give ±25 per entry
- **Moderators**: Can give ±15 per entry
- **Trusted Users**: Can give ±5 per entry (limited to 3 entries per user per month)

### Node Reliability

Node reliability is also tracked per callsign with individual files.

#### Node Reliability File (sync/nodes/X3RL1P.json)

```json
{
  "node": {
    "callsign": "X3RL1P",
    "npub": "npub1relay1...",
    "relay_id": "a7f3b9e1d2c4f6a8",
    "name": "Lisbon Downtown Relay"
  },
  "reliability": {
    "score": 95,
    "status": "healthy",
    "updated": "2025-11-26 10:00_00"
  },
  "metrics": {
    "uptime_percent": 99.5,
    "avg_response_ms": 50,
    "successful_syncs": 10000,
    "failed_syncs": 50,
    "last_seen": "2025-11-26 15:30_00"
  },
  "violations": {
    "count": 0,
    "last_violation": null,
    "history": []
  },
  "reputation_entries": [
    {
      "given_by": "X1ROOT",
      "given_by_npub": "npub1founder789...",
      "date": "2025-11-05 10:00_00",
      "value": 50,
      "reason": "Reliable node operator since network founding",
      "signature": "root_signature..."
    }
  ]
}
```

## Moderation System

### Moderation Flow

```
User Reports Content
         │
         ▼
┌─────────────────────┐
│  Community Flagging │ ── Multiple users flag same content
└─────────┬───────────┘
          │
          ▼ (threshold reached)
┌─────────────────────┐
│  Moderator Review   │ ── Moderator evaluates flags
└─────────┬───────────┘
          │
    ┌─────┴─────┐
    ▼           ▼
 Approve      Hide
    │           │
    ▼           ▼
 Clear      Hidden from
 Flags       Public
              │
              ▼ (if severe)
┌─────────────────────┐
│  Escalate to Group  │
│       Admin         │
└─────────┬───────────┘
          │
    ┌─────┴─────┐
    ▼           ▼
 Reinstate    Ban User
              / Delete
```

### Moderation Log (logs/moderation.log)

```
2025-11-26 10:00_00 | FLAG | npub1user1... flagged report:38.7223_-9.1393_spam | reason: spam
2025-11-26 10:05_00 | FLAG | npub1user2... flagged report:38.7223_-9.1393_spam | reason: spam
2025-11-26 10:10_00 | FLAG | npub1user3... flagged report:38.7223_-9.1393_spam | reason: spam
2025-11-26 10:15_00 | THRESHOLD | report:38.7223_-9.1393_spam reached flag threshold (3)
2025-11-26 10:20_00 | REVIEW | npub1mod1... reviewing report:38.7223_-9.1393_spam
2025-11-26 10:25_00 | HIDE | npub1mod1... hid report:38.7223_-9.1393_spam | reason: confirmed spam
2025-11-26 10:30_00 | PROPAGATE | hide action sent to 15 connected nodes
```

### Ban Propagation

When a user is banned:

1. **Add to banned/users.txt** with reason and evidence
2. **Sign ban record** with moderator/admin signature
3. **Propagate to nodes** with signature chain
4. **Nodes verify** signature authority
5. **Apply locally** - reject content from banned user

```
# BANNED USERS

BANNED: SPAMMER1
--> npub: npub1spammer...
--> banned_at: 2025-11-26 10:00_00
--> banned_by: npub1mod1...
--> authority_level: moderator
--> reason: Repeated spam submissions
--> evidence: 15 flagged items in 24 hours
--> duration: permanent
--> signature: moderator_ban_signature...

--> countersigned_by: npub1groupadmin...
--> countersignature: groupadmin_approval_signature...
```

## Anti-Spam Protection

### Rate Limiting

```json
{
  "rate_limits": {
    "new_user": {
      "reports_per_hour": 2,
      "places_per_day": 5,
      "comments_per_hour": 10,
      "file_upload_mb_per_day": 50
    },
    "regular_user": {
      "reports_per_hour": 10,
      "places_per_day": 20,
      "comments_per_hour": 50,
      "file_upload_mb_per_day": 200
    },
    "trusted_user": {
      "reports_per_hour": 50,
      "places_per_day": 100,
      "comments_per_hour": 200,
      "file_upload_mb_per_day": 1000
    }
  }
}
```

### Content Filtering

- **Duplicate Detection**: Hash-based detection of duplicate submissions
- **Text Analysis**: Flag suspicious patterns (excessive links, repeated text)
- **Image Hashing**: Detect known spam/inappropriate images
- **Velocity Checks**: Flag rapid-fire submissions
- **Geographic Anomalies**: Flag submissions far from user's usual location

### Challenge System

For suspicious activity, require proof-of-work or human verification:

```json
{
  "challenges": {
    "enable_pow": true,
    "pow_difficulty": 16,
    "enable_captcha": false,
    "challenge_threshold": 5
  }
}
```

## Connection Protocols

### Supported Protocols

| Protocol | Use Case | Port/Channel | Range | Bandwidth |
|----------|----------|--------------|-------|-----------|
| **Internet (WebSocket)** | Global relay | wss://relay.example.com | Unlimited | High |
| **Internet (HTTP REST)** | Collection sync | https://relay.example.com/api | Unlimited | High |
| **WiFi LAN** | Local network sync | mDNS discovery, port 8765 | ~100m | High |
| **WiFi HaLow (802.11ah)** | Long-range low-power | 900 MHz band | 1km+ | Medium |
| **Bluetooth LE** | Short-range mesh | BLE GATT service | ~100m | Low |
| **LoRa** | Long-range low-bandwidth | 868/915 MHz | 15km+ | Very Low |
| **Radio (Amateur/CB)** | Very long range | Packet radio modem | 50km+ | Very Low |
| **ESP-MESH** | WiFi mesh network | ESP proprietary | ~200m per hop | Medium |
| **ESP-NOW** | Peer-to-peer WiFi | ESP proprietary | ~200m | Low |

### Protocol Selection

Relays automatically select the best available channel based on:

1. **Connectivity**: What's available between nodes
2. **Latency requirements**: Urgent messages prefer faster channels
3. **Bandwidth needs**: Large syncs prefer high-bandwidth channels
4. **Power constraints**: Battery devices prefer low-power options
5. **Reliability**: Critical messages use most reliable channel

### Multi-Channel Operation

A single relay can operate on multiple channels simultaneously:

```json
{
  "active_channels": {
    "internet": {
      "enabled": true,
      "url": "wss://relay.example.com",
      "status": "connected"
    },
    "wifi_lan": {
      "enabled": true,
      "interface": "wlan0",
      "status": "listening"
    },
    "bluetooth": {
      "enabled": true,
      "service_uuid": "0x1234",
      "status": "advertising"
    },
    "lora": {
      "enabled": true,
      "frequency": 868.1,
      "spreading_factor": 7,
      "status": "listening"
    },
    "espmesh": {
      "enabled": false,
      "reason": "hardware not available"
    }
  }
}
```

### WebSocket Protocol

```
# Connection handshake
Client → Relay: {"type": "hello", "version": "1.0", "npub": "npub1client..."}
Relay → Client: {"type": "hello_ack", "version": "1.0", "npub": "npub1relay...", "challenge": "random123"}
Client → Relay: {"type": "auth", "signature": "signed_challenge..."}
Relay → Client: {"type": "auth_ack", "session": "session_id", "capabilities": [...]}

# Sync request
Client → Relay: {"type": "sync_request", "collections": ["reports"], "since": "2025-11-26 10:00_00"}
Relay → Client: {"type": "sync_response", "items": [...], "more": false}

# Subscribe to updates
Client → Relay: {"type": "subscribe", "collections": ["reports"], "region": {"lat": 38.72, "lon": -9.13, "radius_km": 10}}
Relay → Client: {"type": "subscribe_ack", "subscription_id": "sub123"}
Relay → Client: {"type": "update", "subscription_id": "sub123", "item": {...}}
```

## Discovery Mechanisms

### mDNS/Bonjour Discovery

Relays announce themselves on local networks:

```
Service: _geogram-relay._tcp.local
TXT Records:
  - version=1.0
  - npub=npub1relay...
  - name=Lisbon Community Relay
  - collections=reports,places,events
  - network=portugal-community-network
```

### Bluetooth LE Advertisement

```
Service UUID: 0x1234 (Geogram Relay)
Characteristics:
  - 0x1235: Relay Info (JSON)
  - 0x1236: Sync Request
  - 0x1237: Sync Response
```

### Bootstrap Nodes

New devices can find the network through:

1. **Well-known relays**: Hardcoded bootstrap URLs
2. **DNS-based discovery**: SRV records for `_geogram._tcp.domain.com`
3. **QR code**: Scan relay connection info
4. **NFC**: Tap to connect

## Channel Bridging

Relays can bridge between different communication channels, allowing devices on one network type to communicate with devices on another. A relay with both WiFi and LoRa interfaces can forward messages between internet-connected devices and off-grid LoRa nodes.

### Bridge Concept

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│    INTERNET                    BRIDGE RELAY                 LORA    │
│    ────────                    ────────────                 ────    │
│                                                                     │
│  ┌─────────┐                 ┌─────────────┐              ┌───────┐ │
│  │ Desktop │◄───WiFi/WAN────►│   RELAY1PT  │◄────LoRa────►│ ESP32 │ │
│  │  App    │                 │             │              │ Node  │ │
│  └─────────┘                 │  Channels:  │              └───────┘ │
│                              │  - Internet │                        │
│  ┌─────────┐                 │  - WiFi LAN │              ┌───────┐ │
│  │ Mobile  │◄───Internet────►│  - BLE      │◄────BLE─────►│ Watch │ │
│  │  App    │                 │  - LoRa     │              │       │ │
│  └─────────┘                 └─────────────┘              └───────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Bridge Types

| Bridge | From | To | Use Case |
|--------|------|-----|----------|
| **Internet ↔ LoRa** | WAN | LoRa radio | Remote areas, off-grid sensors |
| **WiFi ↔ BLE** | Local WiFi | Bluetooth | Wearables, IoT devices |
| **Internet ↔ Radio** | WAN | Amateur radio | Emergency comms, very long range |
| **LoRa ↔ ESPMesh** | LoRa | ESP-MESH | Extend mesh into LoRa range |
| **WiFi ↔ WiFi HaLow** | 2.4/5GHz | 900MHz | Long-range WiFi bridging |
| **BLE ↔ ESPNow** | Bluetooth | ESP-NOW | Short-range protocol bridge |

### Bridge Configuration (bridges.json)

```json
{
  "bridges": {
    "enabled": true,
    "relay_callsign": "X3RL1P",
    "relay_npub": "npub1relay1..."
  },
  "available_channels": [
    {
      "type": "internet",
      "enabled": true,
      "interface": "eth0",
      "status": "connected",
      "public_ip": "203.0.113.50",
      "bandwidth_mbps": 100
    },
    {
      "type": "wifi_lan",
      "enabled": true,
      "interface": "wlan0",
      "ssid": "GeogramRelay",
      "status": "active",
      "connected_clients": 5
    },
    {
      "type": "bluetooth",
      "enabled": true,
      "interface": "hci0",
      "status": "advertising",
      "connected_devices": 2,
      "range_m": 50
    },
    {
      "type": "lora",
      "enabled": true,
      "interface": "/dev/ttyUSB0",
      "frequency_mhz": 868.1,
      "spreading_factor": 7,
      "bandwidth_khz": 125,
      "status": "listening",
      "range_km": 15
    },
    {
      "type": "radio",
      "enabled": false,
      "reason": "hardware not available"
    }
  ],
  "bridge_rules": [
    {
      "name": "Internet to LoRa",
      "from": "internet",
      "to": "lora",
      "enabled": true,
      "priority": "emergency_first",
      "rate_limit_per_hour": 100,
      "max_message_bytes": 200
    },
    {
      "name": "WiFi to BLE",
      "from": "wifi_lan",
      "to": "bluetooth",
      "enabled": true,
      "bidirectional": true
    },
    {
      "name": "LoRa to Internet",
      "from": "lora",
      "to": "internet",
      "enabled": true,
      "forward_to_root": true
    }
  ]
}
```

### Bridge Location and Metadata

Each bridge relay advertises its location and capabilities:

```json
{
  "bridge_info": {
    "callsign": "X3RL1P",
    "npub": "npub1relay1...",
    "name": "Lisbon Hilltop Bridge",
    "description": "Internet-LoRa bridge serving greater Lisbon area"
  },
  "location": {
    "latitude": 38.7223,
    "longitude": -9.1393,
    "altitude_m": 150,
    "description": "Hilltop location with clear line of sight",
    "indoor": false,
    "antenna_height_m": 10
  },
  "coverage": {
    "lora_range_km": 20,
    "bluetooth_range_m": 100,
    "wifi_range_m": 50,
    "estimated_coverage_area_km2": 1250
  },
  "power_source": {
    "primary": "solar",
    "backup": "battery",
    "grid_connected": false,
    "solar_panel_watts": 100,
    "battery_capacity_wh": 500,
    "current_battery_percent": 85,
    "estimated_runtime_hours": 72
  },
  "status": {
    "online": true,
    "last_seen": "2025-11-26 15:30_00",
    "uptime_hours": 720
  }
}
```

### Power Source Types

Relays must declare their power source for network planning:

| Power Source | Code | Reliability | Notes |
|--------------|------|-------------|-------|
| **Electric Grid** | `grid` | High | Continuous power, depends on grid reliability |
| **Solar** | `solar` | Medium | Daylight dependent, needs battery backup |
| **Battery** | `battery` | Low | Limited runtime, needs recharging |
| **Solar + Battery** | `solar_battery` | Medium-High | Self-sustaining in good weather |
| **Generator (Fuel)** | `fuel` | Medium | Requires fuel supply, noisy |
| **Wind** | `wind` | Variable | Location dependent |
| **Grid + Battery (UPS)** | `grid_ups` | Very High | Grid with battery backup |
| **Vehicle** | `vehicle` | Variable | Mobile relay, depends on vehicle |

### Power Configuration (power-config.json)

```json
{
  "power": {
    "primary_source": "solar_battery",
    "grid_connected": false,
    "sources": {
      "solar": {
        "panel_watts": 100,
        "panel_count": 2,
        "total_watts": 200,
        "orientation": "south",
        "tilt_degrees": 35
      },
      "battery": {
        "type": "lithium",
        "capacity_wh": 500,
        "voltage": 12,
        "current_percent": 85,
        "health_percent": 95,
        "cycles": 150
      }
    },
    "consumption": {
      "idle_watts": 5,
      "active_watts": 15,
      "peak_watts": 25,
      "avg_daily_wh": 180
    },
    "thresholds": {
      "low_battery_percent": 20,
      "critical_battery_percent": 10,
      "shutdown_percent": 5
    },
    "power_saving": {
      "enabled": true,
      "reduce_tx_power_below": 30,
      "disable_wifi_below": 20,
      "emergency_only_below": 10
    }
  }
}
```

### Connected Devices Registry

Each bridge tracks devices connected through each channel:

```json
{
  "connected_devices": {
    "updated": "2025-11-26 15:30_00",
    "total_devices": 12,
    "by_channel": {
      "internet": {
        "count": 3,
        "devices": [
          {
            "callsign": "X1CR7B",
            "npub": "npub1user1...",
            "device_type": "desktop",
            "connected_since": "2025-11-26 10:00_00",
            "last_activity": "2025-11-26 15:28_00",
            "ip": "192.168.1.100"
          },
          {
            "callsign": "X1PT4X",
            "npub": "npub1user2...",
            "device_type": "mobile",
            "connected_since": "2025-11-26 14:00_00",
            "last_activity": "2025-11-26 15:30_00",
            "ip": "192.168.1.101"
          }
        ]
      },
      "wifi_lan": {
        "count": 5,
        "devices": [
          {
            "callsign": "X1LC1X",
            "npub": "npub1local1...",
            "device_type": "raspberry_pi",
            "connected_since": "2025-11-26 08:00_00",
            "mac": "AA:BB:CC:DD:EE:01"
          }
        ]
      },
      "bluetooth": {
        "count": 2,
        "devices": [
          {
            "callsign": "X1WC1X",
            "npub": "npub1watch1...",
            "device_type": "wearable",
            "connected_since": "2025-11-26 12:00_00",
            "ble_address": "11:22:33:44:55:66"
          }
        ]
      },
      "lora": {
        "count": 2,
        "devices": [
          {
            "callsign": "X1SN1X",
            "npub": "npub1sensor1...",
            "device_type": "esp32_lora",
            "last_heard": "2025-11-26 15:25_00",
            "rssi_dbm": -85,
            "snr_db": 7.5,
            "distance_km": 8.5
          },
          {
            "callsign": "X3RM1X",
            "npub": "npub1remote1...",
            "device_type": "standalone_relay",
            "last_heard": "2025-11-26 15:20_00",
            "rssi_dbm": -110,
            "snr_db": 2.0,
            "distance_km": 15.2
          }
        ]
      }
    }
  }
}
```

### Bridge Advertisement

Bridges advertise their capabilities to the network:

```json
{
  "bridge_advertisement": {
    "type": "bridge_announce",
    "callsign": "X3RL1P",
    "npub": "npub1relay1...",
    "timestamp": "2025-11-26 15:30_00",
    "location": {
      "lat": 38.7223,
      "lon": -9.1393,
      "alt_m": 150
    },
    "channels": ["internet", "wifi_lan", "bluetooth", "lora"],
    "bridges": [
      {"from": "internet", "to": "lora"},
      {"from": "wifi_lan", "to": "bluetooth"},
      {"from": "lora", "to": "internet"}
    ],
    "power": {
      "source": "solar_battery",
      "battery_percent": 85,
      "grid_connected": false
    },
    "capacity": {
      "connected_devices": 12,
      "max_devices": 50,
      "available_slots": 38
    },
    "coverage": {
      "lora_km": 20,
      "ble_m": 100
    },
    "signature": "bridge_announcement_signature..."
  }
}
```

### Network Bridge Map

The network maintains a map of all bridges:

```json
{
  "bridge_map": {
    "network_id": "portugal-community-network",
    "updated": "2025-11-26 15:30_00",
    "bridges": [
      {
        "callsign": "X3RL1P",
        "location": {"lat": 38.7223, "lon": -9.1393},
        "channels": ["internet", "wifi_lan", "bluetooth", "lora"],
        "power": "solar_battery",
        "status": "online",
        "connected_devices": 12
      },
      {
        "callsign": "X3RL2P",
        "location": {"lat": 41.1579, "lon": -8.6291},
        "channels": ["internet", "wifi_halow", "espmesh"],
        "power": "grid_ups",
        "status": "online",
        "connected_devices": 25
      },
      {
        "callsign": "X3RL3P",
        "location": {"lat": 37.0194, "lon": -7.9304},
        "channels": ["lora", "radio", "espnow"],
        "power": "solar_battery",
        "status": "online",
        "connected_devices": 5,
        "note": "Off-grid relay, LoRa/radio only"
      }
    ],
    "bridge_routes": [
      {
        "description": "Internet to Algarve off-grid",
        "path": ["internet", "X3RL1P:lora", "X3RL3P"],
        "hops": 2,
        "latency_ms": 600
      },
      {
        "description": "Porto mesh to Lisbon",
        "path": ["X3RL2P:espmesh", "internet", "X3RL1P:wifi_lan"],
        "hops": 2,
        "latency_ms": 80
      }
    ]
  }
}
```

### Message Routing Across Bridges

When a message needs to cross channel boundaries:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MESSAGE ROUTING                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Source: CR7BBQ (Desktop on Internet)                               │
│  Destination: SENSOR1 (ESP32 on LoRa)                              │
│                                                                     │
│  Route Discovery:                                                   │
│  1. CR7BBQ → Internet → RELAY1PT                                   │
│  2. RELAY1PT bridges Internet → LoRa                               │
│  3. RELAY1PT → LoRa → SENSOR1                                      │
│                                                                     │
│  ┌──────────┐      ┌─────────────┐      ┌──────────┐               │
│  │  CR7BBQ  │─────►│  RELAY1PT   │─────►│ SENSOR1  │               │
│  │ Internet │      │ Int↔LoRa   │      │   LoRa   │               │
│  └──────────┘      └─────────────┘      └──────────┘               │
│                                                                     │
│  Message transforms:                                                │
│  - Internet: Full JSON message (2KB)                               │
│  - LoRa: Compressed binary (200 bytes max)                         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Bridge Protocol Adaptation

Bridges must adapt messages between protocols with different capabilities:

| Protocol | Max Message | Format | Encryption | Latency |
|----------|-------------|--------|------------|---------|
| Internet | Unlimited | JSON | TLS | Low |
| WiFi LAN | 64KB | JSON | Optional | Low |
| BLE | 512 bytes | Binary | AES | Medium |
| LoRa | 255 bytes | Binary | AES | High |
| Radio | 200 bytes | Binary | Optional | Very High |
| ESPNow | 250 bytes | Binary | Optional | Low |

#### Message Compression for Low-Bandwidth Channels

```json
{
  "compression": {
    "lora": {
      "enabled": true,
      "method": "msgpack",
      "max_bytes": 200,
      "truncate_fields": ["description"],
      "omit_fields": ["photos", "attachments"],
      "priority_fields": ["id", "type", "author", "timestamp", "coordinates", "severity"]
    },
    "radio": {
      "enabled": true,
      "method": "custom_binary",
      "max_bytes": 180,
      "emergency_only": true
    },
    "bluetooth": {
      "enabled": true,
      "method": "msgpack",
      "max_bytes": 500,
      "chunk_large_messages": true
    }
  }
}
```

### Bridge Status Reporting

Bridges report their status to the network:

```
┌─────────────────────────────────────────────────────────────────────┐
│                      BRIDGE STATUS: RELAY1PT                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Location: 38.7223, -9.1393 (Lisbon Hilltop)                       │
│  Status: ONLINE                                                     │
│  Uptime: 30 days, 5 hours                                          │
│                                                                     │
│  Power: ☀️ Solar + Battery                                          │
│  ├─ Battery: 85% ████████████████░░░░                              │
│  ├─ Solar Input: 45W (good sunlight)                               │
│  └─ Est. Runtime: 72 hours (no sun)                                │
│                                                                     │
│  Channels:                                                          │
│  ├─ 🌐 Internet     [CONNECTED]  3 devices   ↑50 ↓120 msgs/hr     │
│  ├─ 📶 WiFi LAN     [ACTIVE]     5 devices   ↑30 ↓45 msgs/hr      │
│  ├─ 📱 Bluetooth    [ADVERTISING] 2 devices   ↑10 ↓15 msgs/hr      │
│  └─ 📻 LoRa         [LISTENING]  2 devices   ↑5 ↓8 msgs/hr        │
│                                                                     │
│  Active Bridges:                                                    │
│  ├─ Internet ↔ LoRa    45 msgs bridged today                       │
│  ├─ WiFi ↔ BLE         120 msgs bridged today                      │
│  └─ LoRa → Internet    32 msgs forwarded to root                   │
│                                                                     │
│  Coverage:                                                          │
│  ├─ LoRa: ~20 km radius (clear line of sight)                      │
│  ├─ BLE: ~100 m radius                                             │
│  └─ WiFi: ~50 m radius                                             │
│                                                                     │
│  Last Activity: 2025-11-26 15:30:00 UTC                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Bridge Failover

When a bridge channel fails, traffic reroutes:

```json
{
  "failover": {
    "enabled": true,
    "detection": {
      "heartbeat_interval_seconds": 60,
      "failure_threshold": 3,
      "recovery_threshold": 2
    },
    "routes": [
      {
        "primary": "internet",
        "fallback": ["wifi_lan", "lora"],
        "auto_switch": true
      },
      {
        "primary": "lora",
        "fallback": ["radio"],
        "auto_switch": true,
        "notify_on_failover": true
      }
    ],
    "notifications": {
      "notify_root": true,
      "notify_connected_devices": true,
      "broadcast_status_change": true
    }
  }
}
```

### Bridge Security

Bridges validate messages crossing channel boundaries:

1. **Signature verification**: All messages must have valid NOSTR signatures
2. **Source validation**: Verify sender is authorized on source channel
3. **Destination check**: Confirm destination is reachable on target channel
4. **Rate limiting**: Prevent flooding across bridges
5. **Content inspection**: Reject malformed or oversized messages
6. **Replay protection**: Track message IDs to prevent duplicates

```json
{
  "bridge_security": {
    "require_signatures": true,
    "verify_on_bridge": true,
    "rate_limit": {
      "per_device_per_hour": 100,
      "per_channel_per_hour": 1000,
      "emergency_bypass": true
    },
    "blocked_sources": [],
    "allowed_destinations": "all",
    "max_message_age_minutes": 60,
    "replay_window_minutes": 5
  }
}
```

## Storage Management

### Storage Allocation

```json
{
  "storage": {
    "total_allocated_gb": 50,
    "collections": {
      "reports": {"max_gb": 10, "used_gb": 5.2},
      "places": {"max_gb": 15, "used_gb": 8.1},
      "events": {"max_gb": 5, "used_gb": 2.0},
      "relay_messages": {"max_gb": 10, "used_gb": 3.5},
      "cache": {"max_gb": 10, "used_gb": 7.2}
    },
    "warning_threshold_percent": 80,
    "critical_threshold_percent": 95
  }
}
```

### Garbage Collection

Priority for cleanup (low priority deleted first):

1. **Expired items**: Past TTL
2. **Resolved reports**: After retention period
3. **Old events**: Past event date + buffer
4. **Low-engagement content**: Few views/interactions
5. **Distant content**: Outside geographic scope

## Complete Examples

### Example 1: Desktop as Root Relay

```
# User launches geogram-desktop
# Settings → Relay → Enable Relay Mode

1. User clicks "Create New Network"
2. Enters network name: "Lisbon Mesh Network"
3. System generates relay keypair
4. Creates relay/ directory structure
5. Self-signs root certificate
6. Begins listening for connections

relay.json:
{
  "relay": {
    "id": "lisbon-mesh-network-root",
    "name": "Lisbon Mesh Network Root",
    "type": "root",
    "version": "1.0",
    "created": "2025-11-26 10:00_00",
    "callsign": "X3LB1R",
    "npub": "npub1rootrelay...",
    "nsec": "nsec1rootrelaysecret..."
  },
  "operator": {
    "callsign": "X1CR7B",
    "npub": "npub1operator..."
  },
  "capabilities": {
    "max_connections": 200,
    "max_storage_gb": 100,
    "supported_collections": ["reports", "places", "events", "contacts", "news", "forum"]
  }
}
```

### Example 2: Desktop Joining as Node

```
# User launches geogram-desktop
# Settings → Relay → Enable Relay Mode

1. User clicks "Join Existing Network"
2. Enters root relay URL: wss://root.lisbon-mesh.local
3. System connects and retrieves network info
4. User reviews and accepts network policies
5. Root verifies user identity (npub signature)
6. Root issues node certificate
7. Node downloads authority lists and policies
8. Node begins serving local clients

network.json:
{
  "network": {
    "id": "lisbon-mesh-network",
    "name": "Lisbon Mesh Network",
    "root_npub": "npub1root789..."
  },
  "membership": {
    "joined": "2025-11-26 11:00_00",
    "status": "active",
    "role": "node",
    "certificate": "root_signed_node_certificate..."
  }
}
```

### Example 3: Authority Assignment Flow

```
Timeline:

Day 1: Root (CR7BBQ) creates network
Day 2: Root appoints PT4XYZ as Network Admin
Day 3: PT4XYZ appoints FIRE1PT as Group Admin for Reports
Day 4: FIRE1PT appoints VOL1PT as Moderator for Reports

Authority Chain:
npub1root (CR7BBQ)
  └── signs → npub1admin (PT4XYZ) [Network Admin]
        └── signs → npub1groupadmin (FIRE1PT) [Reports Group Admin]
              └── signs → npub1mod (VOL1PT) [Reports Moderator]

All authority changes:
1. Signed by appointing authority
2. Pushed to root
3. Countersigned by root (optional for audit)
4. Propagated to all nodes
5. Cached locally on all devices
```

## Validation Rules

### Relay Identity Validation

- [ ] `relay.json` must exist and be valid JSON
- [ ] `relay.id` must be unique within network
- [ ] `relay.type` must be "root" or "node"
- [ ] `operator.npub` must be valid NOSTR public key
- [ ] `operator.callsign` must match NPUB owner

### Authority Chain Validation

- [ ] All authority assignments must be signed
- [ ] Signature must come from valid higher authority
- [ ] Root signatures verified against root.txt
- [ ] Admin signatures verified against admins.txt
- [ ] Revocations invalidate all dependent assignments
- [ ] Timestamp chain must be chronologically valid

### Network Membership Validation

- [ ] Node certificate must be signed by root
- [ ] Node npub must match certificate
- [ ] Certificate must not be revoked
- [ ] Certificate must not be expired
- [ ] Node policies must match network policies

## Best Practices

### For Root Operators

1. **Maintain Availability**: Root should have high uptime (99%+)
2. **Backup Keys**: Secure backup of root keypair essential
3. **Document Policies**: Clear, public network policies
4. **Responsive Governance**: Address issues promptly
5. **Designate Backup**: Have backup root for emergencies
6. **Regular Audits**: Review authority assignments periodically
7. **Monitor Health**: Track node reliability and network performance

### For Node Operators

1. **Follow Policies**: Adhere to network policies strictly
2. **Stay Updated**: Keep authority lists and policies current
3. **Report Issues**: Flag policy violations to admins
4. **Maintain Storage**: Monitor and manage storage allocation
5. **Ensure Connectivity**: Maximize uptime and reachability
6. **Cache Wisely**: Prioritize relevant geographic/topical content

### For Moderators

1. **Consistent Enforcement**: Apply rules uniformly
2. **Document Actions**: Log reasons for all moderation
3. **Escalate Appropriately**: Know when to involve Group Admins
4. **Avoid Bias**: Moderate content, not people
5. **Respond Promptly**: Address flags within reasonable time

## Security Considerations

### Key Management

- Root keypair is most critical - secure offline backup recommended
- Node certificates should have expiration and renewal
- Compromised keys require immediate revocation propagation
- Multi-signature support for critical operations (optional)

### Attack Vectors

| Attack | Mitigation |
|--------|------------|
| Root compromise | Backup root, key rotation, multi-sig |
| Sybil (fake nodes) | Certificate requirements, reputation system |
| Content flooding | Rate limiting, PoW challenges |
| Man-in-middle | TLS/WSS, signature verification |
| Authority spoofing | Signature chain verification |
| Denial of service | Connection limits, blacklisting |

### Privacy

- Relay operators can see metadata (who syncs, when)
- Content encryption (end-to-end) prevents relay content reading
- Consider onion routing for sensitive communications
- User location can be inferred from sync patterns

## Related Documentation

- [Relay System Overview](../others/relay/README.md)
- [Relay Functionality](../others/relay/relay-functionality.md)
- [Relay Protocol](../others/relay/relay-protocol.md)
- [Message Integrity](../others/relay/message-integrity.md)
- [Groups Format Specification](groups-format-specification.md)
- [Reports Format Specification](report-format-specification.md)

## Change Log

### Version 1.5 (Draft - 2025-11-26)

**Connection Points and Participation Scoring**:
- Added comprehensive "Connection Points and Participation Scoring" section
- Points philosophy: presence, contribution, verification, relay support, community
- Point categories: connection, contribution, verification, relay operation, bridging, storage, moderation, community
- Per-relay points tracking with detailed breakdown (points/CR7BBQ.json)
- Point earning rules for: connection (hourly, streaks, peak hours), contributions (reports, places, events, forum, chat), verification (accuracy bonuses/penalties), relay operation (uptime, bridging, storage)
- Score calculation with decay (90-day half-life) and multipliers (account age, accuracy, standing)
- Six feature tiers: New User, Newcomer, Regular, Trusted, Veteran, Leader
- Feature unlocking by score (posting limits, verification, business submissions, moderation eligibility)
- Points aggregation across multiple relays
- Signed points certificates for verification
- Anti-gaming measures (rate limits, quality checks, suspicious pattern detection)
- Points dashboard UI mockup
- Integration diagram showing points feeding into reputation system
- Points directory structure in relay folder

### Version 1.4 (Draft - 2025-11-26)

**Channel Bridging**:
- Added comprehensive "Channel Bridging" section
- Bridge concept diagram showing multi-channel relay operation
- Bridge types table (Internet↔LoRa, WiFi↔BLE, Internet↔Radio, etc.)
- Bridge configuration (bridges.json) with available channels and bridge rules
- Bridge location and metadata with coverage areas
- Power source types (grid, solar, battery, fuel, wind, vehicle, UPS)
- Power configuration with consumption tracking and power-saving modes
- Connected devices registry tracking devices per channel
- Bridge advertisement protocol for network discovery
- Network bridge map showing all bridges and routes
- Message routing across bridges with route discovery
- Bridge protocol adaptation for different channel capabilities
- Message compression for low-bandwidth channels (LoRa, Radio, BLE)
- Bridge status reporting with visual display
- Bridge failover configuration with automatic channel switching
- Bridge security (signature verification, rate limiting, replay protection)

### Version 1.3 (Draft - 2025-11-26)

**Node Storage and Configuration**:
- Expanded Node Relay Configuration section with comprehensive setup requirements
- Added Storage Philosophy: Text-First approach to maximize storage efficiency
- Storage Configuration with allocation by category (text, metadata, thumbnails, binary)
- Storage Allocation by Collection Type with per-collection limits and policies
- Binary Data Handling section with four modes: text_only, thumbnails_only, on_demand, full_cache
- Cache Management with priority list and eviction policies
- Three node configuration profiles: Minimal (50 MB), Standard (500 MB), High-Capacity (10 GB)
- Node Setup Wizard UI mockup for guided configuration
- Storage Status Display for monitoring usage
- Binary forwarding for text-only nodes (request routed to origin)

### Version 1.2 (Draft - 2025-11-26)

**Offline Operation and Peer-to-Peer Sync**:
- Added comprehensive "Offline Operation and Peer-to-Peer Sync" section
- Documented collection ownership model: public (root), user (author), network (community)
- Public collections can sync peer-to-peer when root is offline
- User collections are author-only for writes; subscribers sync read-only
- Posts marked `pending_root_confirmation` during offline operation
- Root reconciliation process when connectivity restored
- Three offline modes: temporary offline, extended offline, partitioned network
- Temporary coordinator election for extended root offline periods
- Peer-to-peer sync protocol with handshake and exchange
- Validation rules during peer sync (signature, authorization, timestamp, content)
- Data integrity guarantees table
- Offline-safe vs root-required operations list

### Version 1.1 (Draft - 2025-11-26)

**Updates based on review feedback**:
- Changed authority files to individual files per callsign (easier to manage additions/removals)
- Relay ID now uses the auto-generated collection ID
- Reputation system updated to individual files per callsign with signed entries
- Each reputation entry includes: giver, date, value, reason, and cryptographic signature
- Added network topology tracking in sync/topology.json
- Topology includes node capabilities and connection channels between nodes
- Added comprehensive channel types: WiFi, WiFi HaLow, Bluetooth, LoRa, Radio, ESPMesh, ESPNow
- Added User Collection Approval section for managing user-submitted collections (shops, etc.)
- Collections can be: pending, approved, suspended, or banned
- Added Public Collections (Canonical) section for root-defined collections (forum, chat)
- Public collections sync from root as canonical source
- User contributions flow: User → Node → Root → All Nodes
- Updated Connection Protocols with full channel matrix including range and bandwidth
- Added multi-channel operation support

### Version 1.0 (Draft - 2025-11-26)

**Initial Specification**:
- Relay architecture with root/node hierarchy
- Authority structure: root → admin → group admin → moderator
- Network federation between relay networks
- Collection synchronization protocols
- Trust and reputation system
- Moderation system with propagation
- Anti-spam protection mechanisms
- Connection protocols (WebSocket, Bluetooth, LAN)
- Discovery mechanisms (mDNS, BLE, bootstrap)
- Storage management and garbage collection
- Complete configuration file formats
- Authority file formats with signature chains
- Validation rules for all components
- Security considerations and attack mitigations
