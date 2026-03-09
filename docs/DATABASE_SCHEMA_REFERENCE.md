# BoostDrive – Database schema reference

This document lists the **tables, columns, and storage buckets** the app expects in Supabase. Use it to create or alter your database so the app works correctly.

---

## 1. **profiles**

Used by: `UserService` (auth, profile, roles, verification).

| Column | Type | Notes |
|--------|------|--------|
| `id` | `uuid` (PK) | Matches `auth.users.id` |
| `full_name` | `text` | |
| `phone_number` | `text` | e.g. `+264...` |
| `email` | `text` | |
| `role` | `text` | e.g. `customer`, `mechanic`, `towing`, `admin`, `service_provider` |
| `profile_img` | `text` | URL |
| `is_buyer` | `boolean` | default `true` |
| `is_seller` | `boolean` | default `false` |
| `created_at` | `timestamptz` | |
| `last_active` | `timestamptz` | |
| `loyalty_points` | `integer` | default `0` |
| `is_online` | `boolean` | default `true` |
| `verification_status` | `text` | e.g. `pending`, `approved`, `rejected` |
| `total_earnings` | `numeric` | default `0` |
| `reminders_enabled` | `boolean` | default `true` |
| `deals_enabled` | `boolean` | default `false` |
| `emergency_contact_name` | `text` | |
| `emergency_contact_phone` | `text` | |

---

## 2. **conversations**

Used by: `MessageService` (chat threads per product).

| Column | Type | Notes |
|--------|------|--------|
| `id` | `uuid` (PK) | |
| `product_id` | `uuid` | FK to `products.id` (nullable if repair-only) |
| `buyer_id` | `uuid` | FK to `profiles.id` |
| `seller_id` | `uuid` | FK to `profiles.id` |
| `created_at` | `timestamptz` | Used for sorting; updated when a message is sent |

Optional (for list UI): `product_title` (denormalized), `last_message` – can be computed in app or via DB function.

---

## 3. **messages**

Used by: `MessageService` (chat messages, read receipts).

| Column | Type | Notes |
|--------|------|--------|
| `id` | `uuid` (PK) | |
| `conversation_id` | `uuid` | FK to `conversations.id` |
| `sender_id` | `uuid` | FK to `profiles.id` |
| `content` | `text` | Message text or attachment URL |
| `created_at` | `timestamptz` | |
| **`is_read`** | **`boolean`** | **Required for read receipts (single/double tick). Default `false`.** |

**If `is_read` is missing:**  
- Read receipts (grey / double orange tick) will not work.  
- Add: `ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;`

**Row Level Security (RLS):**  
- For “mark as read” and the notification bell count to work, the **recipient** must be allowed to **UPDATE** `messages` (at least the `is_read` column) for messages they received (i.e. where `sender_id != auth.uid()`).  
- If updates are blocked by RLS, the app will log "markConversationAsRead completed" / "markAllAsRead completed" but the unread count will not go down. Add a policy that allows `UPDATE` on `messages` when the row’s `conversation_id` is in a conversation where the user is the buyer or seller, and `sender_id != auth.uid()`.

---

## 4. **products**

Used by: `ProductService`.

| Column | Type | Notes |
|--------|------|--------|
| `id` | `uuid` (PK) | |
| `title` | `text` | |
| `subtitle` | `text` | |
| `price` | `numeric` | |
| `image_urls` | `jsonb` or `text[]` | Array of URLs |
| `image_url` | `text` | Optional single URL fallback |
| `location` | `text` | e.g. `Namibia` |
| `is_featured` | `boolean` | default `false` |
| `category` | `text` | e.g. `car`, `part`, `rental` |
| `condition` | `text` | e.g. `new`, `used`, `salvage` |
| `status` | `text` | e.g. `available`, `sold`, `draft` |
| `fitment` | `jsonb` | e.g. `{"make":"Toyota","model":"Hilux","year":2020}` |
| `seller_id` | `uuid` | FK to `profiles.id` |
| `created_at` | `timestamptz` | |
| `description` | `text` | |

---

## 5. **orders**

Used by: `CheckoutService` (cart → order).

| Column | Type | Notes |
|--------|------|--------|
| `id` | `uuid` (PK) | |
| `user_id` | `uuid` | Buyer |
| `status` | `text` | e.g. `pending`, `paid`, `shipped`, `completed` |
| `created_at` | `timestamptz` | |
| `total` | `numeric` | |
| `items` | `jsonb` | Array of `{ productId, title, price, quantity, category, rentalStart?, rentalEnd? }` |

---

## 6. **bookings**

Used by: `BookingService`.

| Column | Type | Notes |
|--------|------|--------|
| `id` | `uuid` (PK) | |
| `product_id` | `uuid` | |
| `customer_id` | `uuid` | |
| `type` | `text` | e.g. `rental` |
| `start_date` | `date` / `timestamptz` | |
| `end_date` | `date` / `timestamptz` | |
| `total_price` | `numeric` | |
| `status` | `text` | e.g. `confirmed` |
| `is_insurance_verified` | `boolean` | |
| `created_at` | `timestamptz` | |

---

## 7. **transactions**

Used by: `PaymentService`.

| Column | Type | Notes |
|--------|------|--------|
| `id` | `text` (PK) | e.g. `TXN_...` |
| `product_id` | `uuid` | |
| `customer_id` | `uuid` | |
| `amount` | `numeric` | |
| `status` | `text` | e.g. `completed` |
| `payment_method` | `text` | |
| `created_at` | `timestamptz` | |

---

## 8. **sos_requests**

Used by: `SosService`.

| Column | Type | Notes |
|--------|------|--------|
| `id` | `uuid` (PK) | |
| `user_id` | `uuid` | |
| `type` | `text` | |
| `status` | `text` | e.g. `pending`, `accepted`, `assigned`, `cancelled` |
| `location` | `jsonb` | e.g. `{"lat": ..., "lng": ...}` |
| `user_note` | `text` | |
| `created_at` | `timestamptz` | |

---

## 9. **delivery_orders**

Used by: `DeliveryService`.

| Column | Type | Notes |
|--------|------|--------|
| `id` | `uuid` (PK) | |
| `customer_id` | `uuid` | |
| `seller_id` | `uuid` | |
| `driver_id` | `uuid` (nullable) | |
| `status` | `text` | e.g. `pending`, `picking_up`, `in_transit`, `delivered` |
| `pickup_location` | `jsonb` | |
| `dropoff_location` | `jsonb` | |
| `items` | `jsonb` | |
| `eta` | `text` | |
| `created_at` | `timestamptz` | |

---

## 10. **vehicles**

Used by: `VehicleService`.

| Column | Type | Notes |
|--------|------|--------|
| `id` | `uuid` (PK) | |
| `owner_id` | `uuid` | |
| `make` | `text` | |
| `model` | `text` | |
| `year` | `integer` | |
| `plate_number` | `text` | |
| `health_status` | `text` | |
| `fuel_level` | `text` | |
| `type` | `text` | e.g. `personal`, `logistics` |
| `image_urls` | `jsonb` or `text[]` | |
| `created_at` | `timestamptz` | |
| Plus optional fields used by `Vehicle.fromMap`: `mileage`, `tire_health`, `service_history_type`, `last_service_date`, `last_service_mileage`, `transmission`, `fuel_type`, `drive_type`, `engine_capacity`, `next_license_renewal`, `accident_history`, `modifications`, `spare_key`, `interior_material`, `safety_tech`, `towing_capacity`, `description`, `next_service_due_mileage`, `oil_life`, `brake_fluid_status`, `active_faults`, `vin`, `insurance_expiry`, `warranty_expiry`, `fuel_efficiency`, `exterior_condition` |

---

## 11. **service_history**

Used by: `ServiceRecordService`.

| Column | Type | Notes |
|--------|------|--------|
| `id` | `uuid` (PK) | |
| `vehicle_id` | `uuid` | |
| `provider_id` | `uuid` | |
| `service_name` | `text` | |
| `price` | `numeric` | |
| `completed_at` | `timestamptz` | |
| `receipt_urls` | `jsonb` or `text[]` | Optional `receipt_url` single fallback |
| `mileage` or `mileage_at_service` | `integer` | Optional |

---

## Storage buckets

Create these in Supabase Storage and set policies so the app can read/write as needed:

| Bucket | Purpose |
|--------|---------|
| `product-images` | Product photos |
| `message-attachments` | Chat images and voice message files (must exist for messaging + attachments) |
| `vehicles` | Vehicle photos |
| `service_receipts` | Service receipt files |

---

## Realtime (streams)

The app uses Supabase Realtime on:

- `messages` (by `conversation_id`)
- `conversations`
- `profiles`
- `products`
- `transactions`
- `bookings`
- `sos_requests`
- `delivery_orders`
- `vehicles`
- `service_history`

Ensure **Realtime** is enabled for these tables in the Supabase dashboard (Database → Replication).

---

## Critical change for messaging: `messages.is_read`

For WhatsApp-style read receipts (single grey tick = delivered, double orange = seen), the app requires:

- **Table:** `messages`
- **Column:** `is_read` (`boolean`, default `false`)

If this column does not exist yet, run in the SQL editor:

```sql
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;
```

Then ensure `markConversationAsRead` is called when a user opens a conversation (the app already does this); it updates `messages.is_read` to `true` for that conversation for messages not sent by the current user.

---

## Row Level Security (RLS) for deleting conversations

If you see **"Conversation could not be deleted. You may not have permission"**, RLS is blocking the delete. The app deletes **messages** in that conversation first, then the **conversation** row. Both tables must allow the current user to delete.

Run the following in the Supabase **SQL Editor** (Dashboard → SQL Editor → New query). It enables RLS on both tables if not already on, and adds policies so a user can delete conversations (and their messages) where they are the buyer or seller.

```sql
-- Enable RLS on tables (no-op if already enabled)
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Allow users to DELETE a conversation if they are the buyer or seller
DROP POLICY IF EXISTS "Users can delete own conversations" ON conversations;
CREATE POLICY "Users can delete own conversations"
  ON conversations
  FOR DELETE
  USING (
    auth.uid() = buyer_id OR auth.uid() = seller_id
  );

-- Allow users to DELETE messages in conversations where they are buyer or seller
DROP POLICY IF EXISTS "Users can delete messages in own conversations" ON messages;
CREATE POLICY "Users can delete messages in own conversations"
  ON messages
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = messages.conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
  );
```

After running this, try deleting a conversation again; it should succeed and disappear from the list.
