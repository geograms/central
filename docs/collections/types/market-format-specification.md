# Market Format Specification

**Version**: 1.0
**Last Updated**: 2025-11-22
**Status**: Active

## Table of Contents

- [Overview](#overview)
- [File Organization](#file-organization)
- [Market Structure](#market-structure)
- [Shop Format](#shop-format)
- [Item Format](#item-format)
- [Order Format](#order-format)
- [Review System](#review-system)
- [FAQ System](#faq-system)
- [Inventory Management](#inventory-management)
- [Payment Integration](#payment-integration)
- [Shipping Information](#shipping-information)
- [Status Tracking](#status-tracking)
- [Multilanguage Support](#multilanguage-support)
- [Media Management](#media-management)
- [Permissions and Roles](#permissions-and-roles)
- [Moderation System](#moderation-system)
- [NOSTR Integration](#nostr-integration)
- [Complete Examples](#complete-examples)
- [Parsing Implementation](#parsing-implementation)
- [Validation Rules](#validation-rules)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)
- [Related Documentation](#related-documentation)
- [Change Log](#change-log)

## Overview

This document specifies the text-based format used for storing marketplace data in the Geogram system. The market collection type enables decentralized, offline-first e-commerce where users can create and manage shops, list items for sale, track orders, manage inventory, and facilitate peer-to-peer transactions without requiring centralized infrastructure.

### Key Features

- **Decentralized Shops**: Each user can create and manage their own shops
- **Offline-First**: Complete marketplace functionality without internet
- **Inventory Management**: Real-time stock tracking and updates
- **Order Tracking**: Complete order lifecycle from request to delivery
- **Verified Reviews**: Only purchasers with completed orders can review
- **Multilanguage Support**: Items and shops support multiple languages
- **Rich Media**: Photo and video galleries for items
- **FAQ System**: Questions and answers for each item
- **Rating System**: 1-5 star ratings from verified buyers
- **Payment Flexibility**: Supports multiple payment methods
- **Shipping Integration**: Multiple shipping options per shop
- **Return Policy**: Configurable return windows and policies
- **NOSTR Signatures**: Cryptographic verification for all transactions
- **P2P Distribution**: Entire marketplace syncs via collections

### Conceptual Model

Think of the Geogram market like a decentralized bazaar:

1. **Shop Owners** create shops and list items for sale
2. **Buyers** browse items and place orders
3. **Orders** track the complete transaction lifecycle
4. **Verified Reviews** provide trust signals from actual purchasers
5. **Inventory** updates automatically as sales occur
6. **No Central Authority**: Everything is peer-to-peer via collections

Unlike centralized marketplaces (eBay, Amazon), the Geogram market:
- Requires no servers or central infrastructure
- Syncs via P2P collection distribution
- Works completely offline
- Cryptographically verifies all transactions
- Gives complete control to shop owners

## File Organization

### Directory Structure

```
collection_name/
└── market/
    ├── shops/
    │   ├── shop-CR7BBQ/
    │   │   ├── shop.txt
    │   │   ├── logo.jpg
    │   │   ├── banner.jpg
    │   │   └── items/
    │   │       ├── item-abc123/
    │   │       │   ├── item.txt
    │   │       │   ├── gallery/
    │   │       │   │   ├── photo1.jpg
    │   │       │   │   ├── photo2.jpg
    │   │       │   │   └── demo-video.mp4
    │   │       │   ├── reviews/
    │   │       │   │   ├── review-ALPHA1.txt
    │   │       │   │   └── review-BRAVO2.txt
    │   │       │   └── faq/
    │   │       │       ├── question-001.txt
    │   │       │       └── question-002.txt
    │   │       └── item-def456/
    │   │           ├── item.txt
    │   │           └── gallery/
    │   │               └── product.jpg
    │   └── shop-ALPHA1/
    │       ├── shop.txt
    │       └── items/
    │           └── item-xyz789/
    │               └── item.txt
    ├── orders/
    │   ├── 2025/
    │   │   ├── order-2025-11-22_abc123.txt
    │   │   ├── order-2025-11-22_def456.txt
    │   │   └── order-2025-11-21_xyz789.txt
    │   └── 2024/
    │       └── order-2024-12-25_old123.txt
    └── .reactions/
        └── market.txt
```

### Shop Folder Naming

**Pattern**: `shop-{CALLSIGN}/`

**Callsign**:
- Owner's amateur radio callsign
- Uppercase, alphanumeric
- Unique identifier for the shop
- Examples: `shop-CR7BBQ`, `shop-ALPHA1`, `shop-KE7XYZ`

### Item Folder Naming

**Pattern**: `item-{item-id}/`

**Item ID**:
- First 6 characters of SHA-256 hash of item initial content
- Lowercase hexadecimal
- Ensures uniqueness within shop
- Human-readable identifier

**Examples**:
```
item-a7c5b1/      # Item ID: a7c5b1
item-3d8f2e/      # Item ID: 3d8f2e
item-9b4e6a/      # Item ID: 9b4e6a
```

### Order File Naming

**Pattern**: `order-YYYY-MM-DD_{order-id}.txt`

**Order ID**:
- First 6 characters of SHA-256 hash of order content
- Lowercase hexadecimal
- Date prefix enables chronological sorting

**Examples**:
```
order-2025-11-22_abc123.txt
order-2025-11-21_def456.txt
order-2024-12-25_xyz789.txt
```

### Year Organization for Orders

- **Format**: `orders/YYYY/` (e.g., `orders/2025/`, `orders/2024/`)
- **Purpose**: Organize orders by year for archival
- **Creation**: Automatically created when first order for that year is placed
- **Benefits**: Easy year-based browsing, accounting, and analytics

### Special Directories

**`gallery/` Directory**:
- Contains product photos and videos
- Supports: JPG, PNG, WebP, MP4, WebM
- Recommended: Multiple angles, usage examples, detail shots

**`reviews/` Directory**:
- Contains review files from verified purchasers
- Filename pattern: `review-{BUYER_CALLSIGN}.txt`
- Only one review per buyer per item

**`faq/` Directory**:
- Contains question and answer files
- Filename pattern: `question-{NNN}.txt` (sequential numbering)
- Can be added by shop owner or answered from buyer questions

**`.reactions/` Directory**:
- Hidden directory (starts with dot)
- Contains reaction files for the market collection
- Not specific to individual items or shops

**`.hidden/` Directory** (see Moderation System):
- Hidden directory for moderated content
- Contains items/reviews/comments hidden by moderators
- Not visible in standard UI

## Market Structure

### Market Collection

A market collection is identified by:
- Collection ID
- Collection name
- Owner's npub
- Creation date

The market collection contains all shops, items, and orders.

## Shop Format

### Main Shop File

Every shop must have a `shop.txt` file in the shop folder root.

**Required Fields**:
```
SHOP_ID: shop-CR7BBQ
SHOP_NAME: CR7 Radio Gear
SHOP_OWNER: CR7BBQ
OWNER_NPUB: npub1abc123...
CREATED: 2025-11-22 14:30_00
STATUS: active
```

**Optional Fields**:
```
TAGLINE: Premium amateur radio equipment and accessories
CURRENCY: USD
PAYMENT_METHODS: bitcoin, lightning, bank-transfer, cash
SHIPPING_OPTIONS: standard, express, pickup
RETURN_POLICY: 30-day return window for unopened items
CONTACT_EMAIL: shop@cr7bbq.com
CONTACT_PHONE: +351-XXX-XXX-XXX
LOCATION: Lisbon, Portugal
LANGUAGES: EN, PT, ES
```

**Multilanguage Description**:
```
# DESCRIPTION_EN:
We specialize in high-quality amateur radio equipment, antennas, and accessories.
All products are tested before shipping. Based in Lisbon, Portugal.

# DESCRIPTION_PT:
Especializamo-nos em equipamento de radioamador de alta qualidade, antenas e acessórios.
Todos os produtos são testados antes do envio. Sediado em Lisboa, Portugal.

# DESCRIPTION_ES:
Nos especializamos en equipos de radioaficionados de alta calidad, antenas y accesorios.
Todos los productos se prueban antes del envío. Con sede en Lisboa, Portugal.
```

**Payment Information**:
```
PAYMENT_INFO_EN:
- Bitcoin: bc1q...
- Lightning: lnurl...
- Bank Transfer: IBAN PT50...
- Cash on pickup: Lisbon area only

PAYMENT_INFO_PT:
- Bitcoin: bc1q...
- Lightning: lnurl...
- Transferência Bancária: IBAN PT50...
- Dinheiro na recolha: apenas área de Lisboa
```

**Shipping Information**:
```
SHIPPING_INFO_EN:
- Standard (5-7 days): €5
- Express (2-3 days): €15
- Local pickup: Free

SHIPPING_INFO_PT:
- Normal (5-7 dias): €5
- Expresso (2-3 dias): €15
- Recolha local: Grátis
```

**Return Policy**:
```
RETURN_POLICY_EN:
30-day return window for unopened items in original packaging.
Buyer pays return shipping unless item is defective.
Refund issued within 5 business days of receiving return.

RETURN_POLICY_PT:
Janela de devolução de 30 dias para artigos não abertos na embalagem original.
O comprador paga o envio de devolução, salvo se o artigo estiver defeituoso.
Reembolso emitido no prazo de 5 dias úteis após receber a devolução.
```

**NOSTR Metadata**:
```
--> npub: npub1abc123...
--> signature: 3045022100abcd...
```

### Shop Status Values

- `active`: Shop is open and accepting orders
- `paused`: Temporarily not accepting new orders
- `closed`: Shop is permanently closed
- `vacation`: Owner is away, temporary pause

### Complete Shop Example

```
SHOP_ID: shop-CR7BBQ
SHOP_NAME: CR7 Radio Gear
SHOP_OWNER: CR7BBQ
OWNER_NPUB: npub1abc123...
CREATED: 2025-11-22 14:30_00
STATUS: active
TAGLINE: Premium amateur radio equipment and accessories
CURRENCY: USD
PAYMENT_METHODS: bitcoin, lightning, bank-transfer, cash
SHIPPING_OPTIONS: standard, express, pickup
RETURN_POLICY: 30-day return window for unopened items
CONTACT_EMAIL: shop@cr7bbq.com
LOCATION: Lisbon, Portugal
LANGUAGES: EN, PT, ES

# DESCRIPTION_EN:
We specialize in high-quality amateur radio equipment, antennas, and accessories.
All products are tested before shipping. Based in Lisbon, Portugal.

# DESCRIPTION_PT:
Especializamo-nos em equipamento de radioamador de alta qualidade, antenas e acessórios.
Todos os produtos são testados antes do envio. Sediado em Lisboa, Portugal.

PAYMENT_INFO_EN:
- Bitcoin: bc1q...
- Lightning: lnurl...
- Bank Transfer: IBAN PT50...
- Cash on pickup: Lisbon area only

SHIPPING_INFO_EN:
- Standard (5-7 days): €5
- Express (2-3 days): €15
- Local pickup: Free

RETURN_POLICY_EN:
30-day return window for unopened items in original packaging.
Buyer pays return shipping unless item is defective.
Refund issued within 5 business days of receiving return.

--> npub: npub1abc123...
--> signature: 3045022100abcd...
```

## Item Format

### Main Item File

Every item must have an `item.txt` file in the item folder root.

**Required Fields**:
```
ITEM_ID: item-abc123
SHOP_ID: shop-CR7BBQ
CREATED: 2025-11-22 15:00_00
UPDATED: 2025-11-22 15:00_00
STATUS: available
TYPE: physical
```

**Basic Information**:
```
CATEGORY: electronics/radios
SKU: UV-K5-2023
BRAND: Quansheng
MODEL: UV-K5
```

**Multilanguage Titles**:
```
# TITLE_EN: Quansheng UV-K5 Dual-Band Radio
# TITLE_PT: Rádio Banda Dupla Quansheng UV-K5
# TITLE_ES: Radio de Doble Banda Quansheng UV-K5
```

**Pricing and Stock**:
```
PRICE: 35.00
CURRENCY: USD
STOCK: 15
SOLD: 47
MIN_ORDER: 1
MAX_ORDER: 5
```

**Ratings**:
```
RATING: 4.7
REVIEW_COUNT: 23
```

**Multilanguage Description**:
```
[EN]
Compact dual-band (VHF/UHF) amateur radio transceiver with excellent receive performance.
Features include:
- Frequency range: 136-174MHz / 400-520MHz
- 1000 channel memory
- VOX function
- Built-in flashlight
- Rechargeable 1600mAh battery included

Perfect for beginners and experienced operators alike.

[PT]
Transceptor de rádio amador dual-band (VHF/UHF) compacto com excelente desempenho de receção.
Características incluem:
- Gama de frequências: 136-174MHz / 400-520MHz
- Memória de 1000 canais
- Função VOX
- Lanterna integrada
- Bateria recarregável de 1600mAh incluída

Perfeito para iniciantes e operadores experientes.
```

**Specifications**:
```
SPECIFICATIONS_EN:
- Frequency Range: 136-174MHz / 400-520MHz
- Output Power: 5W (high) / 1W (low)
- Channels: 1000 memory channels
- Battery: 1600mAh Li-ion rechargeable
- Dimensions: 110 x 58 x 33mm
- Weight: 135g (without antenna)
- Antenna Connector: SMA-Female

SPECIFICATIONS_PT:
- Gama de Frequências: 136-174MHz / 400-520MHz
- Potência de Saída: 5W (alta) / 1W (baixa)
- Canais: 1000 canais de memória
- Bateria: 1600mAh Li-ion recarregável
- Dimensões: 110 x 58 x 33mm
- Peso: 135g (sem antena)
- Conector de Antena: SMA-Fêmea
```

**Shipping Information**:
```
WEIGHT: 200
WEIGHT_UNIT: grams
DIMENSIONS: 12x8x5
DIMENSIONS_UNIT: cm
SHIPPING_TIME: 2-3 business days
SHIPS_FROM: Lisbon, Portugal
```

**NOSTR Metadata**:
```
--> npub: npub1abc123...
--> signature: 3045022100abcd...
```

### Item Status Values

- `available`: In stock and available for purchase
- `out-of-stock`: Temporarily unavailable, will restock
- `low-stock`: Less than 5 units remaining
- `discontinued`: No longer available, not restocking
- `pre-order`: Not yet released, accepting pre-orders
- `draft`: Not yet published, only visible to owner

### Item Type Values

- `physical`: Physical product requiring shipping
- `digital`: Digital download (software, ebooks, etc.)
- `service`: Service offering (consulting, repair, etc.)

### Category Recommendations

Common category patterns (customizable):
```
electronics/radios
electronics/antennas
electronics/accessories
tools/hand-tools
tools/power-tools
books/technical
books/fiction
clothing/shirts
clothing/hats
survival/water-filters
survival/shelters
food/preserved
food/seeds
```

### Complete Item Example

```
ITEM_ID: item-abc123
SHOP_ID: shop-CR7BBQ
CREATED: 2025-11-22 15:00_00
UPDATED: 2025-11-22 15:00_00
STATUS: available
TYPE: physical

CATEGORY: electronics/radios
SKU: UV-K5-2023
BRAND: Quansheng
MODEL: UV-K5

# TITLE_EN: Quansheng UV-K5 Dual-Band Radio
# TITLE_PT: Rádio Banda Dupla Quansheng UV-K5

PRICE: 35.00
CURRENCY: USD
STOCK: 15
SOLD: 47
MIN_ORDER: 1
MAX_ORDER: 5

RATING: 4.7
REVIEW_COUNT: 23

[EN]
Compact dual-band (VHF/UHF) amateur radio transceiver with excellent receive performance.
Features include:
- Frequency range: 136-174MHz / 400-520MHz
- 1000 channel memory
- VOX function
- Built-in flashlight
- Rechargeable 1600mAh battery included

Perfect for beginners and experienced operators alike.

SPECIFICATIONS_EN:
- Frequency Range: 136-174MHz / 400-520MHz
- Output Power: 5W (high) / 1W (low)
- Channels: 1000 memory channels
- Battery: 1600mAh Li-ion rechargeable
- Dimensions: 110 x 58 x 33mm
- Weight: 135g (without antenna)

WEIGHT: 200
WEIGHT_UNIT: grams
DIMENSIONS: 12x8x5
DIMENSIONS_UNIT: cm
SHIPPING_TIME: 2-3 business days
SHIPS_FROM: Lisbon, Portugal

--> npub: npub1abc123...
--> signature: 3045022100abcd...
```

## Order Format

### Order File

Each order is stored in a separate file in the `orders/YYYY/` directory.

**Required Fields**:
```
ORDER_ID: order-2025-11-22_abc123
BUYER_CALLSIGN: ALPHA1
BUYER_NPUB: npub1buyer123...
SELLER_CALLSIGN: CR7BBQ
SELLER_NPUB: npub1seller456...
SHOP_ID: shop-CR7BBQ
CREATED: 2025-11-22 16:30_00
STATUS: requested
```

**Order Items**:
```
ITEMS:
- item-abc123 | qty: 2 | price: 35.00 | subtotal: 70.00
- item-def456 | qty: 1 | price: 15.00 | subtotal: 15.00
```

**Pricing**:
```
SUBTOTAL: 85.00
SHIPPING: 5.00
TAX: 0.00
TOTAL: 90.00
CURRENCY: USD
```

**Payment Information**:
```
PAYMENT_METHOD: bitcoin
PAYMENT_ADDRESS: bc1q...
PAYMENT_AMOUNT: 90.00
PAYMENT_STATUS: pending
```

**Shipping Information**:
```
SHIPPING_METHOD: standard
SHIPPING_NAME: John Smith
SHIPPING_ADDRESS: Rua Example 123, Lisbon, Portugal
SHIPPING_POSTAL: 1000-000
SHIPPING_COUNTRY: Portugal
SHIPPING_PHONE: +351-XXX-XXX-XXX
```

**Status History**:
```
STATUS_HISTORY:
2025-11-22 16:30_00 | requested | Order placed by buyer
```

**Order Notes**:
```
BUYER_NOTES:
Please include extra bubble wrap for fragile items.

SELLER_NOTES:
Items packed securely with extra protection as requested.
```

**NOSTR Signatures**:
```
--> buyer_npub: npub1buyer123...
--> buyer_signature: 3045022100buyer...
--> seller_npub: npub1seller456...
--> seller_signature: 3045022100seller...
```

### Order Status Values and Lifecycle

The order progresses through these statuses:

1. **`requested`**: Buyer has placed order, awaiting seller confirmation
2. **`confirmed`**: Seller has confirmed order, awaiting payment
3. **`paid`**: Payment received and verified
4. **`processing`**: Order is being prepared for shipment
5. **`shipped`**: Order has been shipped to buyer
6. **`in-transit`**: Order is en route to buyer
7. **`delivered`**: Order delivered to buyer
8. **`completed`**: Transaction completed, both parties satisfied
9. **`cancelled`**: Order cancelled before fulfillment
10. **`refund-requested`**: Buyer has requested refund
11. **`refunded`**: Refund processed and completed
12. **`disputed`**: Dispute raised, requires resolution

### Status Transitions

Each status change is logged in `STATUS_HISTORY` with:
- Timestamp (YYYY-MM-DD HH:MM_SS format)
- Status value
- Description/notes

**Example Status History**:
```
STATUS_HISTORY:
2025-11-22 16:30_00 | requested | Order placed by buyer
2025-11-22 17:00_00 | confirmed | Seller confirmed order
2025-11-22 18:30_00 | paid | Payment received (Bitcoin TX: abc123...)
2025-11-23 10:00_00 | processing | Items being packed
2025-11-23 14:00_00 | shipped | Tracking: PT123456789
2025-11-25 11:30_00 | delivered | Delivered to address
2025-11-25 15:00_00 | completed | Buyer confirmed receipt
```

### Payment Status Values

- `pending`: Awaiting payment
- `processing`: Payment being verified
- `completed`: Payment confirmed
- `failed`: Payment failed
- `refunded`: Payment refunded to buyer

### Complete Order Example

```
ORDER_ID: order-2025-11-22_abc123
BUYER_CALLSIGN: ALPHA1
BUYER_NPUB: npub1buyer123...
SELLER_CALLSIGN: CR7BBQ
SELLER_NPUB: npub1seller456...
SHOP_ID: shop-CR7BBQ
CREATED: 2025-11-22 16:30_00
STATUS: delivered

ITEMS:
- item-abc123 | qty: 2 | price: 35.00 | subtotal: 70.00
- item-def456 | qty: 1 | price: 15.00 | subtotal: 15.00

SUBTOTAL: 85.00
SHIPPING: 5.00
TAX: 0.00
TOTAL: 90.00
CURRENCY: USD

PAYMENT_METHOD: bitcoin
PAYMENT_ADDRESS: bc1q...
PAYMENT_AMOUNT: 90.00
PAYMENT_STATUS: completed
PAYMENT_TX: abc123def456...

SHIPPING_METHOD: standard
SHIPPING_NAME: John Smith
SHIPPING_ADDRESS: Rua Example 123, Lisbon, Portugal
SHIPPING_POSTAL: 1000-000
SHIPPING_COUNTRY: Portugal
SHIPPING_PHONE: +351-XXX-XXX-XXX
TRACKING_NUMBER: PT123456789

STATUS_HISTORY:
2025-11-22 16:30_00 | requested | Order placed by buyer
2025-11-22 17:00_00 | confirmed | Seller confirmed order
2025-11-22 18:30_00 | paid | Payment received
2025-11-23 10:00_00 | processing | Items being packed
2025-11-23 14:00_00 | shipped | Tracking: PT123456789
2025-11-25 11:30_00 | delivered | Delivered to address

BUYER_NOTES:
Please include extra bubble wrap for fragile items.

SELLER_NOTES:
Items packed securely with extra protection as requested.

--> buyer_npub: npub1buyer123...
--> buyer_signature: 3045022100buyer...
--> seller_npub: npub1seller456...
--> seller_signature: 3045022100seller...
```

## Review System

### Review File Format

Reviews are stored in the `reviews/` directory within each item folder.

**Filename Pattern**: `review-{BUYER_CALLSIGN}.txt`

**Required Fields**:
```
REVIEWER: ALPHA1
REVIEWER_NPUB: npub1reviewer123...
ITEM_ID: item-abc123
ORDER_ID: order-2025-11-22_abc123
CREATED: 2025-11-26 14:00_00
RATING: 5
VERIFIED_PURCHASE: yes
```

**Review Content**:
```
TITLE: Excellent radio for the price!

REVIEW:
This radio exceeded my expectations. Great receive sensitivity, solid build quality,
and the battery life is impressive. The built-in flashlight is a nice bonus.

Arrived well-packaged and works perfectly. Would definitely buy from this shop again.

PROS:
- Excellent receive sensitivity
- Good build quality
- Long battery life
- Includes battery and charger

CONS:
- Stock antenna could be better (easily upgraded)
- Menu system takes some getting used to
```

**Optional Fields**:
```
HELPFUL_YES: 15
HELPFUL_NO: 2
```

**NOSTR Signature**:
```
--> npub: npub1reviewer123...
--> signature: 3045022100review...
```

### Verified Purchase Requirement

- Reviews can only be created by buyers with `completed` orders
- `VERIFIED_PURCHASE` field must be `yes`
- `ORDER_ID` must reference valid completed order
- Prevents fake reviews from non-purchasers

### Rating Values

- **1 star**: Poor - Would not recommend
- **2 stars**: Below average - Disappointed
- **3 stars**: Average - Met expectations
- **4 stars**: Good - Would recommend
- **5 stars**: Excellent - Highly recommend

### Review Helpfulness

Users can mark reviews as helpful or not helpful:
- `HELPFUL_YES`: Count of users who found review helpful
- `HELPFUL_NO`: Count of users who did not find review helpful

### Complete Review Example

```
REVIEWER: ALPHA1
REVIEWER_NPUB: npub1reviewer123...
ITEM_ID: item-abc123
ORDER_ID: order-2025-11-22_abc123
CREATED: 2025-11-26 14:00_00
RATING: 5
VERIFIED_PURCHASE: yes

TITLE: Excellent radio for the price!

REVIEW:
This radio exceeded my expectations. Great receive sensitivity, solid build quality,
and the battery life is impressive. The built-in flashlight is a nice bonus.

Arrived well-packaged and works perfectly. Would definitely buy from this shop again.

PROS:
- Excellent receive sensitivity
- Good build quality
- Long battery life
- Includes battery and charger

CONS:
- Stock antenna could be better (easily upgraded)
- Menu system takes some getting used to

HELPFUL_YES: 15
HELPFUL_NO: 2

--> npub: npub1reviewer123...
--> signature: 3045022100review...
```

## FAQ System

### FAQ File Format

FAQs are stored in the `faq/` directory within each item folder.

**Filename Pattern**: `question-{NNN}.txt` (sequential: 001, 002, 003, etc.)

**Required Fields**:
```
QUESTION_ID: 001
ITEM_ID: item-abc123
CREATED: 2025-11-23 10:00_00
STATUS: answered
```

**Question**:
```
QUESTION_BY: BRAVO2
QUESTION_NPUB: npub1asker123...
QUESTION_DATE: 2025-11-23 10:00_00

QUESTION:
Does this radio support APRS out of the box, or does it require firmware modification?
```

**Answer**:
```
ANSWER_BY: CR7BBQ
ANSWER_NPUB: npub1seller456...
ANSWER_DATE: 2025-11-23 11:30_00

ANSWER:
The stock firmware does not support APRS. However, there are custom firmware options
available that add APRS functionality. I can provide links to the firmware projects
if you're interested in modding it.

For APRS out of the box, I'd recommend checking out our other listings for radios
with native APRS support.
```

**Helpfulness**:
```
HELPFUL_YES: 8
HELPFUL_NO: 0
```

**NOSTR Signatures**:
```
--> question_npub: npub1asker123...
--> question_signature: 3045022100question...
--> answer_npub: npub1seller456...
--> answer_signature: 3045022100answer...
```

### FAQ Status Values

- `pending`: Question asked, awaiting answer
- `answered`: Shop owner has provided answer
- `closed`: Question marked as resolved/closed

### Complete FAQ Example

```
QUESTION_ID: 001
ITEM_ID: item-abc123
CREATED: 2025-11-23 10:00_00
STATUS: answered

QUESTION_BY: BRAVO2
QUESTION_NPUB: npub1asker123...
QUESTION_DATE: 2025-11-23 10:00_00

QUESTION:
Does this radio support APRS out of the box, or does it require firmware modification?

ANSWER_BY: CR7BBQ
ANSWER_NPUB: npub1seller456...
ANSWER_DATE: 2025-11-23 11:30_00

ANSWER:
The stock firmware does not support APRS. However, there are custom firmware options
available that add APRS functionality. I can provide links to the firmware projects
if you're interested in modding it.

For APRS out of the box, I'd recommend checking out our other listings for radios
with native APRS support.

HELPFUL_YES: 8
HELPFUL_NO: 0

--> question_npub: npub1asker123...
--> question_signature: 3045022100question...
--> answer_npub: npub1seller456...
--> answer_signature: 3045022100answer...
```

## Inventory Management

### Stock Tracking

Items track inventory through these fields:

**In `item.txt`**:
```
STOCK: 15          # Current available quantity
SOLD: 47           # Total number sold (lifetime)
RESERVED: 2        # Items in pending/confirmed orders
MIN_ORDER: 1       # Minimum quantity per order
MAX_ORDER: 5       # Maximum quantity per order
```

### Stock Calculations

**Available Stock** = `STOCK` - `RESERVED`

**When order is placed**:
1. Check if requested quantity ≤ available stock
2. Increment `RESERVED` by order quantity
3. Create order with status `requested`

**When order is confirmed/paid**:
1. Decrement `STOCK` by order quantity
2. Decrement `RESERVED` by order quantity
3. Increment `SOLD` by order quantity

**When order is cancelled**:
1. Decrement `RESERVED` by order quantity
2. Stock becomes available again

### Out of Stock Handling

When `STOCK` reaches 0:
- Item `STATUS` automatically changes to `out-of-stock`
- Item still visible but not purchasable
- Shop owner can restock by updating `STOCK` value
- `STATUS` changes back to `available` when restocked

### Low Stock Alerts

When `STOCK` is less than 5:
- Item `STATUS` can be set to `low-stock`
- Provides visual indicator to buyers
- Encourages quicker purchasing decisions

### Unlimited Stock (Digital Items)

For digital items or services with unlimited availability:
```
STOCK: unlimited
SOLD: 234
```

- No reservation needed
- Never runs out of stock
- Still tracks `SOLD` count for statistics

## Payment Integration

### Supported Payment Methods

The market collection supports multiple payment methods configured per shop:

**Cryptocurrency**:
- `bitcoin`: Bitcoin on-chain payments
- `lightning`: Bitcoin Lightning Network
- `monero`: Monero payments

**Traditional**:
- `bank-transfer`: Bank wire transfer
- `paypal`: PayPal payments
- `cash`: Cash on pickup/delivery
- `check`: Check/cheque payment

**Barter**:
- `trade`: Trade for other items
- `service`: Service exchange

### Payment Method in Shop

```
PAYMENT_METHODS: bitcoin, lightning, bank-transfer, cash
```

### Payment Information in Shop

Each payment method should have clear instructions:

```
PAYMENT_INFO_EN:
Bitcoin:
- Address: bc1q...
- Wait for 3 confirmations before shipping

Lightning:
- LNURL: lnurl1...
- Instant settlement

Bank Transfer:
- IBAN: PT50...
- BIC: SWIFT123
- Reference: Order number

Cash:
- Pickup location: Rua Example 123, Lisbon
- Available: Mon-Fri 9am-5pm
```

### Payment in Order

```
PAYMENT_METHOD: bitcoin
PAYMENT_ADDRESS: bc1q...
PAYMENT_AMOUNT: 90.00
PAYMENT_CURRENCY: USD
PAYMENT_STATUS: completed
PAYMENT_TX: abc123def456...    # Transaction ID/reference
PAYMENT_DATE: 2025-11-22 18:30_00
```

### Payment Verification

For cryptocurrency payments:
1. Buyer sends payment to provided address
2. Buyer updates order with transaction ID
3. Seller verifies payment on blockchain
4. Order status changes to `paid`

For other payment methods:
1. Buyer initiates payment
2. Buyer provides proof (receipt, transfer confirmation)
3. Seller verifies payment
4. Order status changes to `paid`

## Shipping Information

### Shipping Options

Shops configure available shipping methods:

```
SHIPPING_OPTIONS: standard, express, pickup

SHIPPING_INFO_EN:
Standard Shipping (5-7 days):
- Portugal: €5
- Europe: €10
- Worldwide: €20

Express Shipping (2-3 days):
- Portugal: €15
- Europe: €25
- Worldwide: €40

Local Pickup (Free):
- Lisbon area only
- Arrange via contact
```

### Shipping in Order

```
SHIPPING_METHOD: standard
SHIPPING_COST: 5.00
SHIPPING_CARRIER: CTT Portugal
TRACKING_NUMBER: PT123456789
TRACKING_URL: https://tracking.ctt.pt/PT123456789

SHIPPING_NAME: John Smith
SHIPPING_ADDRESS: Rua Example 123
SHIPPING_CITY: Lisbon
SHIPPING_POSTAL: 1000-000
SHIPPING_COUNTRY: Portugal
SHIPPING_PHONE: +351-XXX-XXX-XXX
```

### Tracking Updates

Sellers can add tracking information:
```
TRACKING_NUMBER: PT123456789
TRACKING_URL: https://tracking.ctt.pt/PT123456789
TRACKING_UPDATES:
2025-11-23 14:00_00 | Picked up from sender
2025-11-24 08:00_00 | In transit to Lisbon hub
2025-11-24 16:00_00 | Out for delivery
2025-11-25 11:30_00 | Delivered
```

## Status Tracking

### Shop Status

Shops can have these statuses:
- `active`: Accepting orders
- `paused`: Temporarily not accepting orders
- `vacation`: Owner away, temporary pause
- `closed`: Permanently closed

### Item Status

Items can have these statuses:
- `available`: In stock, ready to purchase
- `out-of-stock`: Temporarily unavailable
- `low-stock`: Less than 5 units remaining
- `discontinued`: No longer restocking
- `pre-order`: Not released yet
- `draft`: Not published yet

### Order Status

See [Order Status Values and Lifecycle](#order-status-values-and-lifecycle) section for complete order status flow.

### Payment Status

- `pending`: Awaiting payment
- `processing`: Verifying payment
- `completed`: Payment confirmed
- `failed`: Payment failed
- `refunded`: Refunded to buyer

## Multilanguage Support

### Supported Languages

The market collection supports 11 languages:
- English (EN)
- Portuguese (PT)
- Spanish (ES)
- French (FR)
- German (DE)
- Italian (IT)
- Dutch (NL)
- Russian (RU)
- Chinese (ZH)
- Japanese (JA)
- Arabic (AR)

### Language Codes

Use ISO 639-1 two-letter codes:
- `EN` for English
- `PT` for Portuguese
- `ES` for Spanish
- etc.

### Multilanguage Fields

**Shop Fields**:
- `DESCRIPTION_{LANG}`: Shop description
- `PAYMENT_INFO_{LANG}`: Payment instructions
- `SHIPPING_INFO_{LANG}`: Shipping details
- `RETURN_POLICY_{LANG}`: Return policy

**Item Fields**:
- `# TITLE_{LANG}:` Item title
- `[{LANG}]` content blocks: Item description
- `SPECIFICATIONS_{LANG}:` Technical specs

### Title Format

Titles use the `#` prefix format:
```
# TITLE_EN: Quansheng UV-K5 Dual-Band Radio
# TITLE_PT: Rádio Banda Dupla Quansheng UV-K5
# TITLE_ES: Radio de Doble Banda Quansheng UV-K5
```

### Content Block Format

Multi-paragraph content uses language block markers:
```
[EN]
This is the English description.
It can span multiple paragraphs.

Features include...

[PT]
Esta é a descrição em português.
Pode abranger vários parágrafos.

As características incluem...
```

### Section Format

For specific sections with multilanguage content:
```
SPECIFICATIONS_EN:
- Frequency Range: 136-174MHz / 400-520MHz
- Output Power: 5W (high) / 1W (low)

SPECIFICATIONS_PT:
- Gama de Frequências: 136-174MHz / 400-520MHz
- Potência de Saída: 5W (alta) / 1W (baixa)
```

### Language Fallback

When displaying content:
1. Try requested language
2. Fall back to English (EN)
3. Fall back to first available language

## Media Management

### Gallery Organization

Each item can have a `gallery/` directory containing:

**Image Formats**:
- JPG/JPEG (recommended)
- PNG
- WebP
- GIF (non-animated preferred)

**Video Formats**:
- MP4 (H.264 codec recommended)
- WebM
- Maximum recommended: 50MB per video

**File Naming Recommendations**:
```
gallery/
├── main.jpg              # Primary product photo
├── front.jpg            # Front view
├── back.jpg             # Back view
├── side-left.jpg        # Side views
├── side-right.jpg
├── detail-screen.jpg    # Detail shots
├── detail-buttons.jpg
├── usage-1.jpg          # Usage examples
├── usage-2.jpg
└── demo.mp4             # Video demo
```

### Image Guidelines

**Recommended**:
- Resolution: 1200x1200px minimum for main image
- Format: JPG with 85-90% quality
- Aspect ratio: 1:1 (square) for product shots
- Background: Plain white or neutral for main image
- Show item from multiple angles
- Include detail shots of important features
- Show item in use when applicable

**Required**:
- At least one image
- First image alphabetically becomes thumbnail
- Maximum file size: 5MB per image

### Video Guidelines

**Recommended**:
- Resolution: 1920x1080 (Full HD)
- Duration: 30 seconds to 3 minutes
- Show item features and usage
- Include audio if demonstrating features
- Keep file size under 50MB

### Shop Media

Shops can have:
- `logo.jpg`: Shop logo/icon (square, 512x512px recommended)
- `banner.jpg`: Shop banner (1200x400px recommended)

## Permissions and Roles

### Shop Roles

**Shop Owner** (identified by `OWNER_NPUB`):
- Create and edit shop
- Create and edit items
- Manage inventory
- Confirm orders
- Answer FAQs
- Respond to reviews (read-only, cannot delete)
- Access all shop analytics

**Buyer** (anyone with valid NOSTR keypair):
- Browse shops and items
- Place orders
- Submit reviews (only with verified purchase)
- Ask questions (FAQ)
- Mark reviews as helpful

**Moderator** (collection owner):
- Can hide items/reviews/shops
- Cannot edit content
- Cannot delete content
- Cannot access private order information

### Permission Validation

All actions require valid NOSTR signatures:

**Shop Creation**:
```
--> npub: npub1owner123...
--> signature: 3045022100shop...
```

**Item Creation**:
```
--> npub: npub1owner123...     # Must match shop owner
--> signature: 3045022100item...
```

**Order Creation**:
```
--> buyer_npub: npub1buyer123...
--> buyer_signature: 3045022100buyer...
```

**Order Confirmation**:
```
--> seller_npub: npub1seller456...   # Must match shop owner
--> seller_signature: 3045022100seller...
```

**Review Submission**:
```
--> npub: npub1reviewer123...        # Must have completed order
--> signature: 3045022100review...
```

### Signature Verification

Each signed action must be verified:
1. Extract npub and signature
2. Reconstruct message for signing (canonical format)
3. Verify signature using npub
4. Check npub matches expected role
5. Reject if verification fails

## Moderation System

### Hidden Content

Moderators can hide inappropriate content without deletion:

**Hidden Items**:
```
item-abc123/                    # Original location
└── .hidden/
    └── hidden-by-moderator.txt  # Reason for hiding

.hidden/items/
└── item-abc123/                 # Moved here
    └── item.txt
```

**Hidden Reviews**:
```
reviews/
└── .hidden/
    └── review-SPAMMER.txt       # Moved here
```

**Hidden Shops**:
```
shops/
└── .hidden/
    └── shop-SCAMMER/            # Entire shop hidden
        └── shop.txt
```

### Moderation Log

Each hidden item requires a moderation log:

**File**: `.hidden/moderation-log.txt`

```
2025-11-22 15:00_00 | item-abc123 | Counterfeit product | MOD1
2025-11-23 10:30_00 | review-SPAMMER | Spam content | MOD2
2025-11-24 09:00_00 | shop-SCAMMER | Fraudulent shop | MOD1
```

**Format**: `timestamp | content-id | reason | moderator-callsign`

### Unhiding Content

Content can be restored:
1. Move from `.hidden/` back to original location
2. Remove moderation log entry
3. Add restoration log entry

### Moderation Transparency

- All moderation actions are logged
- Logs are visible in collection
- Shop owners notified of hidden items
- Appeals handled via collection comments

## NOSTR Integration

### NOSTR Keys

**npub (Public Key)**:
- Format: `npub1...` (Bech32 encoded)
- Used to identify users
- Public, shareable
- Used for signature verification

**nsec (Private Key)**:
- Format: `nsec1...` (Bech32 encoded)
- Used to sign actions
- **Never shared or stored in collection**
- Kept secure by user's wallet/client

### Signature Format

All signatures use Schnorr signature scheme:

```
--> npub: npub1abc123def456...
--> signature: 3045022100abcdef123456789...
```

### Message Signing

Each action creates a canonical message for signing:

**Shop Creation**:
```
market:shop:create:{SHOP_ID}:{SHOP_NAME}:{OWNER_NPUB}:{CREATED}
```

**Item Creation**:
```
market:item:create:{ITEM_ID}:{SHOP_ID}:{TITLE}:{PRICE}:{CREATED}
```

**Order Placement**:
```
market:order:create:{ORDER_ID}:{BUYER_NPUB}:{SELLER_NPUB}:{TOTAL}:{CREATED}
```

**Review Submission**:
```
market:review:create:{ITEM_ID}:{ORDER_ID}:{RATING}:{REVIEWER_NPUB}:{CREATED}
```

### Verification Process

To verify a signature:
1. Extract `npub` and `signature` from metadata
2. Reconstruct the canonical message
3. Use NOSTR library to verify signature
4. Check timestamp is reasonable (not too old/future)
5. Ensure npub has permission for action

### Identity Verification

NOSTR npubs provide decentralized identity:
- No central authority needed
- Users control their keys
- Signatures prove authenticity
- Cannot be forged or spoofed

## Complete Examples

### Example 1: Complete Shop with Items

**File**: `shops/shop-CR7BBQ/shop.txt`
```
SHOP_ID: shop-CR7BBQ
SHOP_NAME: CR7 Radio Gear
SHOP_OWNER: CR7BBQ
OWNER_NPUB: npub1abc123...
CREATED: 2025-11-22 14:30_00
STATUS: active
TAGLINE: Premium amateur radio equipment and accessories
CURRENCY: USD
PAYMENT_METHODS: bitcoin, lightning, bank-transfer
SHIPPING_OPTIONS: standard, express, pickup
LANGUAGES: EN, PT

# DESCRIPTION_EN:
We specialize in high-quality amateur radio equipment, antennas, and accessories.
All products are tested before shipping.

# DESCRIPTION_PT:
Especializamo-nos em equipamento de radioamador de alta qualidade, antenas e acessórios.
Todos os produtos são testados antes do envio.

PAYMENT_INFO_EN:
- Bitcoin: bc1q...
- Lightning: lnurl...
- Bank Transfer: IBAN PT50...

SHIPPING_INFO_EN:
- Standard (5-7 days): €5
- Express (2-3 days): €15
- Local pickup: Free

--> npub: npub1abc123...
--> signature: 3045022100abcd...
```

**File**: `shops/shop-CR7BBQ/items/item-abc123/item.txt`
```
ITEM_ID: item-abc123
SHOP_ID: shop-CR7BBQ
CREATED: 2025-11-22 15:00_00
UPDATED: 2025-11-22 15:00_00
STATUS: available
TYPE: physical

CATEGORY: electronics/radios
SKU: UV-K5-2023
BRAND: Quansheng
MODEL: UV-K5

# TITLE_EN: Quansheng UV-K5 Dual-Band Radio
# TITLE_PT: Rádio Banda Dupla Quansheng UV-K5

PRICE: 35.00
CURRENCY: USD
STOCK: 15
SOLD: 47
MIN_ORDER: 1
MAX_ORDER: 5

RATING: 4.7
REVIEW_COUNT: 23

[EN]
Compact dual-band (VHF/UHF) amateur radio transceiver with excellent receive performance.
Perfect for beginners and experienced operators alike.

WEIGHT: 200
WEIGHT_UNIT: grams
SHIPPING_TIME: 2-3 business days

--> npub: npub1abc123...
--> signature: 3045022100abcd...
```

### Example 2: Complete Order Lifecycle

**File**: `orders/2025/order-2025-11-22_abc123.txt`
```
ORDER_ID: order-2025-11-22_abc123
BUYER_CALLSIGN: ALPHA1
BUYER_NPUB: npub1buyer123...
SELLER_CALLSIGN: CR7BBQ
SELLER_NPUB: npub1seller456...
SHOP_ID: shop-CR7BBQ
CREATED: 2025-11-22 16:30_00
STATUS: completed

ITEMS:
- item-abc123 | qty: 2 | price: 35.00 | subtotal: 70.00

SUBTOTAL: 70.00
SHIPPING: 5.00
TOTAL: 75.00
CURRENCY: USD

PAYMENT_METHOD: bitcoin
PAYMENT_ADDRESS: bc1q...
PAYMENT_AMOUNT: 75.00
PAYMENT_STATUS: completed
PAYMENT_TX: abc123def456...

SHIPPING_METHOD: standard
SHIPPING_NAME: John Smith
SHIPPING_ADDRESS: Rua Example 123, Lisbon, Portugal
SHIPPING_POSTAL: 1000-000
TRACKING_NUMBER: PT123456789

STATUS_HISTORY:
2025-11-22 16:30_00 | requested | Order placed by buyer
2025-11-22 17:00_00 | confirmed | Seller confirmed order
2025-11-22 18:30_00 | paid | Payment received
2025-11-23 10:00_00 | processing | Items being packed
2025-11-23 14:00_00 | shipped | Tracking: PT123456789
2025-11-25 11:30_00 | delivered | Delivered to address
2025-11-25 15:00_00 | completed | Buyer confirmed receipt

--> buyer_npub: npub1buyer123...
--> buyer_signature: 3045022100buyer...
--> seller_npub: npub1seller456...
--> seller_signature: 3045022100seller...
```

### Example 3: Verified Review

**File**: `shops/shop-CR7BBQ/items/item-abc123/reviews/review-ALPHA1.txt`
```
REVIEWER: ALPHA1
REVIEWER_NPUB: npub1reviewer123...
ITEM_ID: item-abc123
ORDER_ID: order-2025-11-22_abc123
CREATED: 2025-11-26 14:00_00
RATING: 5
VERIFIED_PURCHASE: yes

TITLE: Excellent radio for the price!

REVIEW:
This radio exceeded my expectations. Great receive sensitivity, solid build quality,
and the battery life is impressive.

PROS:
- Excellent receive sensitivity
- Good build quality
- Long battery life

CONS:
- Stock antenna could be better

HELPFUL_YES: 15
HELPFUL_NO: 2

--> npub: npub1reviewer123...
--> signature: 3045022100review...
```

### Example 4: FAQ Entry

**File**: `shops/shop-CR7BBQ/items/item-abc123/faq/question-001.txt`
```
QUESTION_ID: 001
ITEM_ID: item-abc123
CREATED: 2025-11-23 10:00_00
STATUS: answered

QUESTION_BY: BRAVO2
QUESTION_NPUB: npub1asker123...
QUESTION_DATE: 2025-11-23 10:00_00

QUESTION:
Does this radio support APRS out of the box?

ANSWER_BY: CR7BBQ
ANSWER_NPUB: npub1seller456...
ANSWER_DATE: 2025-11-23 11:30_00

ANSWER:
The stock firmware does not support APRS. However, there are custom firmware options
available that add APRS functionality.

HELPFUL_YES: 8
HELPFUL_NO: 0

--> question_npub: npub1asker123...
--> question_signature: 3045022100question...
--> answer_npub: npub1seller456...
--> answer_signature: 3045022100answer...
```

## Parsing Implementation

### Recommended Parsing Strategy

1. **Read file line by line**
2. **Parse metadata fields** (KEY: value format)
3. **Parse language-specific titles** (# TITLE_LANG: format)
4. **Parse language blocks** ([LANG] markers)
5. **Parse sections** (SECTION_LANG: format)
6. **Parse NOSTR signatures** (--> metadata)

### Metadata Field Parsing

Format: `KEY: value`

```
SHOP_ID: shop-CR7BBQ
STATUS: active
PRICE: 35.00
```

Extract key and value, trim whitespace.

### Title Parsing

Format: `# TITLE_{LANG}: title text`

```
# TITLE_EN: Quansheng UV-K5 Dual-Band Radio
# TITLE_PT: Rádio Banda Dupla Quansheng UV-K5
```

Extract language code and title text.

### Content Block Parsing

Format: `[{LANG}]` followed by content until next language marker or section

```
[EN]
English content here.
Multiple paragraphs supported.

[PT]
Portuguese content here.
```

Collect all content between language markers.

### Section Parsing

Format: `SECTION_{LANG}:` followed by content until next section or EOF

```
SPECIFICATIONS_EN:
- Line 1
- Line 2

SPECIFICATIONS_PT:
- Linha 1
- Linha 2
```

### NOSTR Signature Parsing

Format: `--> key: value`

```
--> npub: npub1abc123...
--> signature: 3045022100abcd...
```

Extract signature metadata at end of file.

### Multi-Item Order Parsing

Format: `- item-id | qty: N | price: X | subtotal: Y`

```
ITEMS:
- item-abc123 | qty: 2 | price: 35.00 | subtotal: 70.00
- item-def456 | qty: 1 | price: 15.00 | subtotal: 15.00
```

Split on `|`, parse each field.

### Status History Parsing

Format: `timestamp | status | description`

```
STATUS_HISTORY:
2025-11-22 16:30_00 | requested | Order placed by buyer
2025-11-22 17:00_00 | confirmed | Seller confirmed order
```

Split on `|`, extract timestamp, status, and description.

## Validation Rules

### Shop Validation

Required fields:
- `SHOP_ID` must match pattern `shop-{CALLSIGN}`
- `OWNER_NPUB` must be valid NOSTR public key
- `STATUS` must be valid status value
- `CREATED` timestamp must be valid
- At least one language description required
- Valid NOSTR signature required

### Item Validation

Required fields:
- `ITEM_ID` must match pattern `item-{hash}`
- `SHOP_ID` must reference existing shop
- `TYPE` must be valid type value
- `STATUS` must be valid status value
- `PRICE` must be positive number
- `STOCK` must be non-negative integer or "unlimited"
- At least one language title required
- At least one language description required
- Valid NOSTR signature required
- Signature npub must match shop owner

### Order Validation

Required fields:
- `ORDER_ID` must match pattern `order-YYYY-MM-DD_{hash}`
- `BUYER_NPUB` must be valid NOSTR public key
- `SELLER_NPUB` must match shop owner
- `SHOP_ID` must reference existing shop
- All item IDs must reference existing items
- Quantities must respect MIN_ORDER and MAX_ORDER
- Stock must be available for all items
- `TOTAL` must match calculated total
- Valid NOSTR signatures required from both parties

### Review Validation

Required fields:
- `REVIEWER_NPUB` must be valid NOSTR public key
- `ITEM_ID` must reference existing item
- `ORDER_ID` must reference existing completed order
- `VERIFIED_PURCHASE` must be `yes`
- Order must belong to reviewer
- Order status must be `completed`
- `RATING` must be 1-5
- Valid NOSTR signature required
- Only one review per buyer per item

### FAQ Validation

Required fields:
- `QUESTION_ID` must be unique within item
- `ITEM_ID` must reference existing item
- Question must have valid NOSTR signature
- Answer npub must match shop owner (if answered)
- Answer must have valid NOSTR signature (if answered)

## Best Practices

### For Shop Owners

**Shop Setup**:
- Provide clear, detailed shop description in multiple languages
- Include clear payment instructions for all accepted methods
- Specify shipping costs and timeframes for all regions
- Define clear return policy
- Add professional logo and banner images

**Item Listings**:
- Use high-quality photos from multiple angles
- Write detailed, accurate descriptions
- Include all relevant specifications
- Set realistic stock levels
- Price competitively
- Support multiple languages for broader reach

**Order Management**:
- Confirm orders promptly (within 24 hours)
- Verify payments before shipping
- Update order status as it progresses
- Provide tracking information
- Communicate with buyers about delays
- Mark orders as completed only after delivery confirmation

**Customer Service**:
- Answer FAQ questions quickly
- Be honest about product limitations
- Address negative reviews professionally
- Honor return policy commitments
- Maintain positive reputation

**Inventory**:
- Keep stock levels accurate
- Update immediately when items sell
- Mark items as out-of-stock promptly
- Don't oversell (reserved stock tracking)

### For Buyers

**Before Purchasing**:
- Read item descriptions carefully
- Check shop ratings and reviews
- Review return policy
- Verify shipping costs and timeframes
- Check payment methods accepted

**Placing Orders**:
- Provide accurate shipping information
- Include phone number for delivery
- Double-check order before confirming
- Add notes for special requests
- Complete payment promptly

**After Delivery**:
- Confirm delivery when received
- Inspect items promptly
- Leave honest, helpful reviews
- Ask questions via FAQ for future buyers
- Mark reviews as helpful when useful

### For Collection Curators

**Content Quality**:
- Moderate spam shops/items
- Hide fraudulent content
- Maintain moderation transparency
- Respond to abuse reports
- Document moderation decisions

**Collection Organization**:
- Regular backups
- Archive old orders annually
- Monitor collection size
- Optimize image sizes
- Prune draft items periodically

## Security Considerations

### Cryptographic Verification

**Always Verify**:
- NOSTR signatures on all actions
- Shop owner signatures on items
- Buyer and seller signatures on orders
- Reviewer signatures on reviews
- Question/answer signatures on FAQ

**Never Trust**:
- Unsigned content
- Mismatched npubs (item creator ≠ shop owner)
- Orders without both buyer and seller signatures
- Reviews without verified purchase
- Suspicious timestamp patterns

### Payment Security

**Cryptocurrency Payments**:
- Always verify transactions on blockchain
- Wait for sufficient confirmations (3+ for Bitcoin)
- Use unique addresses per order
- Never reuse payment addresses
- Document transaction IDs

**Other Payment Methods**:
- Request proof of payment
- Verify payment source
- Document payment references
- Wait for bank confirmation
- Use escrow for high-value items

### Fraud Prevention

**For Buyers**:
- Check shop reputation and reviews
- Verify seller identity via NOSTR npub
- Use cryptocurrency for buyer protection
- Document all communications
- Report suspicious shops

**For Sellers**:
- Verify payment before shipping
- Use tracking for all shipments
- Document shipping proof
- Be wary of unusual requests
- Report fraudulent buyers

### Privacy Protection

**Sensitive Information**:
- Never store nsec (private keys)
- Don't include full addresses in public metadata
- Limit personal information in orders
- Use pseudonymous callsigns
- Encrypt sensitive buyer/seller communications

**Data Minimization**:
- Only collect necessary information
- Don't require real names if callsign suffices
- Limit payment information exposure
- Respect buyer privacy preferences

### Dispute Resolution

**Documentation**:
- Keep all order communications
- Save payment proofs
- Document shipping tracking
- Photograph items before shipping
- Screenshot important messages

**Escalation**:
- Attempt direct resolution first
- Involve collection moderators if needed
- Provide evidence for claims
- Follow return policy procedures
- Use cryptocurrency dispute mechanisms when applicable

## Related Documentation

### Geogram Core Documentation

- **[Collections Overview](../others/README.md)** - Introduction to collections system
- **[Architecture](../others/architecture.md)** - Collections system design
- **[API Reference](../others/api-reference.md)** - API for accessing collections
- **[Security Model](../others/security-model.md)** - Cryptographic verification

### Other Collection Types

- **[Places](places-format-specification.md)** - Geographic locations
- **[Events](events-format-specification.md)** - Time-based gatherings
- **[News](news-format-specification.md)** - News articles
- **[Postcards](postcards-format-specification.md)** - Sneakernet messaging
- **[Forum](forum-format-specification.md)** - Discussion forums
- **[Blog](blog-format-specification.md)** - Blog posts and articles

### Technical References

- **[NOSTR Protocol](https://github.com/nostr-protocol/nostr)** - NOSTR specification
- **[Schnorr Signatures](https://github.com/bitcoin/bips/blob/master/bip-0340.mediawiki)** - Signature scheme
- **[APRS](http://www.aprs.org/)** - Amateur radio positioning system

## Change Log

### Version 1.0 (2025-11-22)

Initial release of Market format specification.

**Features**:
- Shop creation and management
- Item listings with multilanguage support
- Inventory tracking and management
- Order lifecycle from request to delivery
- Verified purchase review system
- FAQ system for items
- Multiple payment methods
- Shipping integration
- Rating system (1-5 stars)
- NOSTR cryptographic verification
- Moderation system
- Media galleries for items
- Multi-currency support
- Return policy framework

---

**Document Version**: 1.0
**Last Updated**: 2025-11-22
**Maintained by**: Geogram Contributors
**License**: Apache 2.0
