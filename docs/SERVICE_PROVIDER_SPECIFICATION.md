# Service Provider (Responder) Specification

According to the **BoostDrive Project Specification**, Service Providers (also referred to as **Responders**) act as the physical backbone of the BoostDrive.com platform, bridging the gap between digital requests and on-the-ground automotive solutions.

---

## Core Functions of the Service Provider

| Function | Description |
|----------|-------------|
| **Emergency Response** | Providers use geolocation technology to match with stranded motorists and provide immediate assistance. |
| **Diagnostics & Repair Integration** | They identify vehicle issues and can upload a **required parts list** directly to a user’s account, which then links to the **BoostDrive.shop** marketplace. |
| **Quality Maintenance** | Providers are part of a **vetted network** and are subject to a **rating/review system** to ensure high-quality service across the ecosystem. |

---

## Specific Services to Be Offered

The provider network (mobile mechanics and established auto repair shops) is expected to offer the following:

| Category | Specific Services |
|----------|-------------------|
| **Emergency Services** | On-demand roadside assistance and emergency towing. |
| **Mechanical Services** | Mobile mechanic repairs and in-presence auto repair shop services. |
| **Logistics & Support** | Real-time tracking of their arrival for the customer. |
| **Marketplace Support** | Installation of major parts purchased via the BoostDrive.shop platform. |

---

## Implementation Notes (Codebase Alignment)

- **Emergency / SOS**: `SosService`, `sos_requests` table, and mobile SOS flows support emergency requests and (where implemented) provider matching and status updates.
- **Roles**: `profiles.role` includes `mechanic`, `towing`, `service_provider`; profiles support `verification_status` for vetting.
- **Marketplace link**: Products and orders live in `products` and `orders`; a “required parts list” from a provider could be represented as a list of product IDs or a dedicated table linked to a service/SOS record.
- **Ratings/reviews**: Not yet modelled in the schema; consider a `provider_reviews` or `service_ratings` table and UI for customers to rate completed jobs.
- **Real-time arrival tracking**: Delivery/tracking flows (e.g. `delivery_orders`, `ServiceTrackingPage`) support status and ETA; extend as needed for “responder en route” and ETA to customer.

This document is the single source of truth for the Service Provider scope; architecture and feature work should align with it.

---

## Concrete tasks and database changes

### Database (Supabase)

Run **`docs/supabase_service_provider_schema.sql`** in the SQL Editor to add:

| Change | Purpose |
|--------|---------|
| **sos_requests**: `assigned_provider_id`, `responded_at` | Assign a responder to an SOS; track who is en route. |
| **provider_reviews** (new table) | Store rating (1–5) and optional review text per customer/provider (and optional service reference). RLS: anyone can read; only customer can insert their review. |
| **provider_parts_recommendations** (new table) | Required parts list: provider, user, optional vehicle/sos/service ref, `product_ids` (array of `products.id`) and note. Links to BoostDrive.shop. RLS: user reads own; provider inserts. |
| **service_history**: `recommended_product_ids` (jsonb), `order_id` | Optional: recommend products for this service; link installation jobs to an order. |

See **`docs/DATABASE_SCHEMA_REFERENCE.md`** (section “Database changes for Service Providers”) for a short summary.

### Application tasks (after DB is updated)

1. **SOS provider assignment**  
   In mobile (or web) responder flow: when a provider accepts an SOS, set `sos_requests.assigned_provider_id` and `responded_at`; show “Provider X is en route” and ETA to the customer.

2. **Required parts list**  
   Provider UI: after diagnostics (or from an SOS/repair), add rows to `provider_parts_recommendations` with chosen `product_ids`. Customer UI: show “Your mechanic recommended these parts” with links to product pages on .shop.

3. **Ratings and reviews**  
   After a job is completed (SOS or service_history), allow the customer to submit a row in `provider_reviews`. Show average rating and reviews on provider profile and in responder lists.

4. **Installation of .shop parts**  
   When creating a service_history entry for “Installation”, set `order_id` to the order that contains the parts; optionally prefill `recommended_product_ids` from that order.
