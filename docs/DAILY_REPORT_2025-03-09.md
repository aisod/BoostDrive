# BoostDrive – Daily Report (Monday, March 9, 2025)

This report summarizes work done today on the BoostDrive project, including tasks completed and those still pending. It is based on the current git status, modified/added files, and documentation in the repo.

---

## Executive summary

Today’s work focused on **service providers**, **SOS/emergency flows**, **customer discovery (Find a Provider)**, **provider profile/settings**, **Garage**, and **stability fixes** (null-safety, Flutter web assertions). Documentation was added for how services and providers work, SOS behavior, troubleshooting, and database requirements.

---

## 1. Tasks completed

### 1.1 Find a Provider (customer discovery)

- **Mobile**
  - Added **Find Providers** page (`apps/Mobile/lib/find_providers_page.dart`) with:
    - List of verified mechanics and towing providers
    - Filters: All / Mechanic / Towing
    - Provider cards: name, role badge, verified badge, phone, **Call** button
  - Wired into app shell: **PROVIDERS** tab in bottom nav (`main_shell.dart` case 4 → `FindProvidersPage`).

- **Web**
  - Added **Find a Provider** page (`apps/Web/lib/find_providers_page.dart`) with equivalent behavior (filters, cards, Call).
  - Linked from **Support** in top nav and from customer dashboard/nav (`shop_home_page.dart`: Support → Find a Provider; `_buildFindProviderOrServicesRequestedNav`).
  - Addressed Flutter web issues on this page: **RepaintBoundary** and replacement of **InkWell**/SegmentedButton/DropdownButton/FilterChip/IconButton/Tooltip with **GestureDetector** + Container to avoid `mouse_tracker.dart` assertion (see TROUBLESHOOTING.md).

### 1.2 SOS (emergency) and provider assignment

- **Backend / services**
  - **SosService** (`packages/boostdrive_services/lib/src/sos_service.dart`):
    - `acceptRequest(requestId, providerId)` updates `sos_requests` with `assigned_provider_id`, `responded_at`, and `status: 'assigned'`.
    - `streamProviderAssignedRequests(providerId)` streams requests where `assigned_provider_id = providerId` (accepted by that provider).
  - **Emergency Hub** (mobile) uses `assigned_provider_id` to show “Provider X is on the way” for active requests (`emergency_hub_page.dart`).

- **Documentation**
  - **SOS_SPECIFICATION.md** (new): One-tap emergency, “Big 5” services (towing, jump-start, flat tire, fuel delivery, lockout), safety (panic, welfare checks, voice notes), active emergency state (responder tracking, emergency contacts). Notes that SOS and “Services requested” are **mobile-only** for providers.
  - **HOW_SERVICES_AND_PROVIDERS_WORK.md** (new): End-to-end flow for customers (Find a Provider + SOS on mobile) and providers (web Provider Hub vs mobile “LIVE SOS ALERTS” and Accept). Includes SQL for `assigned_provider_id` and `responded_at` if missing.

### 1.3 Provider profile and settings

- **Database**
  - **supabase_provider_profile_columns.sql** (new): Adds to `profiles`:
    - Operational: `business_hours_24_7`, `service_radius_km`, `workshop_address`, `workshop_lat/lng`, `social_facebook`, `social_instagram`, `website_url`
    - Specializations: `brand_expertise`, `service_tags`, `towing_capabilities`
    - Financial: `bank_account_number`, `bank_branch`, `bank_name`, `standard_labor_rate`, `tax_vat_number`
    - Trust: `business_bio`, `gallery_urls`, `team_size`
    - Notifications: `sos_alerts_enabled`, `preferred_communication`

- **Domain model**
  - **UserProfile** (`packages/boostdrive_core/lib/src/models/user_profile.dart`): New fields for all of the above; **null-safe** parsing in `fromMap` for rows missing new columns. **`_str()` helper** used for all string fields so null/non-string from API become `''` (fixes Find a Provider `TypeError: null is not a subtype of type 'String'` on web).

- **Profile settings UI**
  - **ProfileSettingsPage** (`packages/boostdrive_ui/lib/src/profile_settings_page.dart`): Extended with:
    - Provider/shop section: shop display name, store bio, warehouse address, **service area**, **working hours**, **provider service types** (multi-select; min 1 when role is provider).
    - Full business profile: operational (24/7, radius, workshop, social, website), specializations (brand expertise, service tags, towing), financial (bank, labor rate, tax), trust (bio, gallery, team size), notifications (SOS alerts, preferred communication).
    - Controllers and state for all new fields; persistence via UserService/profile update.

- **UserService**
  - Fetches and maps new profile columns (e.g. `service_area_description`, `working_hours`, `provider_service_types`) so Find a Provider and settings stay in sync with DB.

### 1.4 Garage (mobile)

- **GaragePage** (`apps/Mobile/lib/garage_page.dart`) (new):
  - Tab/section: **My Garage** (vehicles from `userVehiclesProvider`), **Active Orders**, **Service History**, **Shop promo** banner.
  - Uses `PremiumPageLayout`, app bar “My Garage” with “Add Vehicle” action.
- **Navigation**: Wired in **main_shell.dart** (case 2 → `GaragePage`) as a main bottom-nav destination.

### 1.5 Documentation and schema reference

- **SERVICE_PROVIDER_SPECIFICATION.md** (new): Core functions (emergency, diagnostics/repair, quality), specific services (emergency, mechanical, logistics, marketplace), implementation notes (SOS, roles, marketplace link, ratings, tracking). **Concrete tasks**: DB changes (`sos_requests` columns, `provider_reviews`, `provider_parts_recommendations`, `service_history` extensions); app tasks (SOS assignment, required parts list, ratings/reviews, installation of .shop parts).
- **DATABASE_SCHEMA_REFERENCE.md** (updated): Checklist for Find a Provider, read receipts, delete conversation, **SOS provider Accept** (`assigned_provider_id`, `responded_at`, RLS), listing click count, **provider location & hours** and **provider_service_types**, and reference to **supabase_provider_profile_columns.sql** for full provider business profile.
- **TROUBLESHOOTING.md** (new):
  - Find a Provider `TypeError: null is not a subtype of type 'String'`: cause (null profile fields), fix (UserProfile `_str()` coercion), optional migration for new columns.
  - `removeChild` / “Bad state: Not connected to an application”: DevTools/DWDS, not app code; when to ignore or run without DWDS.
  - `mouse_tracker.dart` assertion: RepaintBoundary and GestureDetector replacements on Shop Home and Find a Provider; full restart, no hot reload.
  - WebSocket / network errors: Supabase URL and connectivity.

- **ARCHITECTURE.md** (updated): References SERVICE_PROVIDER_SPECIFICATION, roles, SOS, logistics, delivery/tracking.

### 1.6 Bug fixes and stability

- **Null-safety (Find a Provider)**: `UserProfile.fromMap` now uses `_str()` (and list/int/bool/double helpers) so every string field is never null; avoids red overlay on web when profile data has nulls or legacy rows.
- **Flutter web assertions**: RepaintBoundary on root (e.g. `main.dart`), GestureDetector instead of InkWell on Shop Home and Find a Provider to reduce `_debugDuringDeviceUpdate` / mouse tracker issues.
- **Messages / read receipts**: MessageService uses `is_read` for sending, streaming unread, and marking read; Messages page shows WhatsApp-style ticks. Schema reference documents `messages.is_read`. (One legacy file `docs/supabase_messages_is_read.sql` was removed; behavior is documented in DATABASE_SCHEMA_REFERENCE.)

### 1.7 Other touched areas

- **Login / auth**: `login_page.dart`, `login_widget.dart` (boostdrive_ui); `auth_service.dart` (boostdrive_auth) – likely small fixes or wiring.
- **Dashboards**: Mobile and Web – customer, seller, service pro, super admin – updated for new nav (Find a Provider, Garage), provider hub, or batlorrih logistics.
- **Product / shop**: `product_service.dart`, `product.dart` (boostdrive_core); `product_detail_page` (Mobile & Web); `shop_home_page` (Web) – product detail and shop home wiring.
- **Chat**: `chat_page.dart` (Mobile), `messages_page.dart` (Web) – read receipts and UI.
- **Pubspec**: Mobile and Web `pubspec.yaml` – dependency or asset updates.

---

## 2. Tasks still pending

These are explicitly listed in **SERVICE_PROVIDER_SPECIFICATION.md** or implied by docs; not all may have been started today.

### 2.1 Database (Supabase)

- Run **provider_reviews** table creation (rating 1–5, review text, RLS: customer inserts, anyone reads).
- Run **provider_parts_recommendations** (required parts list: provider, user, optional vehicle/SOS ref, `product_ids`, note; RLS: user reads own, provider inserts).
- Optional **service_history** extensions: `recommended_product_ids` (jsonb), `order_id`.
- Ensure **sos_requests**: `assigned_provider_id`, `responded_at` and RLS “Providers can update when accepting” are applied (SQL in HOW_SERVICES_AND_PROVIDERS_WORK.md).
- Apply **supabase_provider_profile_columns.sql** (and any profiles migration for `service_area_description`, `working_hours`, `provider_service_types`) so Find a Provider and profile settings work against live DB.

### 2.2 Application features

1. **SOS provider assignment (polish)**
   - Show “Provider X is en route” and ETA to customer after accept (data exists; UI/UX may need refinement).
   - Optional: real-time arrival tracking / ETA in Emergency Hub.

2. **Required parts list**
   - Provider UI: after diagnostics/SOS/repair, add rows to `provider_parts_recommendations` with chosen `product_ids`.
   - Customer UI: “Your mechanic recommended these parts” with links to product pages on .shop.

3. **Ratings and reviews**
   - After job completion (SOS or service_history), customer submits row in `provider_reviews`.
   - Show average rating and reviews on provider profile and in responder lists.

4. **Installation of .shop parts**
   - When creating service_history for “Installation”, set `order_id` to the order containing the parts; optionally prefill `recommended_product_ids` from that order.

5. **SOS “Big 5” and safety**
   - SOS_SPECIFICATION describes Battery Jump-Start, Flat Tire, Fuel Delivery, Lockout (in addition to Towing and Mobile Mechanic). Implement specific request types and any panic/welfare/voice note features as needed.

### 2.3 Uncommitted / in-progress work (from git status)

- **Uncommitted changes**: Many of the files above are modified (M) or added (A) but may not all be committed.
- **Untracked files**:
  - `apps/Mobile/lib/garage_page.dart`
  - `docs/SOS_SPECIFICATION.md`
  - `docs/supabase_provider_profile_columns.sql`
- **Deleted**: `docs/supabase_messages_is_read.sql` (read receipts are documented in DATABASE_SCHEMA_REFERENCE; migration may live elsewhere or be inlined).

Recommendation: Review diff, run tests, then commit with clear messages (e.g. “feat(mobile): Add Garage tab and Find Providers”, “docs: Add SOS and provider specs and troubleshooting”) and push when ready.

---

## 3. File change summary

| Area | Files |
|------|--------|
| **Mobile** | `main.dart`, `main_shell.dart`, `find_providers_page.dart`, `garage_page.dart`, `emergency_hub_page.dart`, `customer_dashboard.dart`, `seller_dashboard.dart`, `service_pro_dashboard.dart`, `super_admin_dashboard.dart`, `chat_page.dart`, `login_page.dart`, `product_detail_page.dart`, `batlorrih_logistics_dashboard.dart` |
| **Web** | `main.dart`, `find_providers_page.dart`, `shop_home_page.dart`, `messages_page.dart`, `product_detail_page.dart`, `seller_dashboard_page.dart`, `service_pro_dashboard_page.dart`, `super_admin_dashboard_page.dart` |
| **Packages** | `boostdrive_auth` (auth_service), `boostdrive_core` (product, user_profile), `boostdrive_services` (message_service, product_service, sos_service, user_service), `boostdrive_ui` (login_page, login_widget, profile_settings_page) |
| **Docs** | `ARCHITECTURE.md`, `DATABASE_SCHEMA_REFERENCE.md`, `HOW_SERVICES_AND_PROVIDERS_WORK.md`, `SERVICE_PROVIDER_SPECIFICATION.md`, `TROUBLESHOOTING.md`, `SOS_SPECIFICATION.md` (untracked), `supabase_provider_profile_columns.sql` (untracked) |
| **Deleted** | `docs/supabase_messages_is_read.sql` |

---

## 4. Next steps (suggested)

1. **Commit and push** current work with descriptive messages; add untracked docs and SQL if desired.
2. **Run Supabase migrations**: provider profile columns, SOS columns + RLS, then (when ready) provider_reviews and provider_parts_recommendations.
3. **Test** Find a Provider (web + mobile) with real provider profiles and null/legacy data.
4. **Implement** remaining provider features in order: required parts list → ratings/reviews → installation link.
5. **Expand SOS** to the full “Big 5” and safety features per SOS_SPECIFICATION.md when prioritised.

---

*Report generated from repository state and documentation. For exact commit history, run `git log` and `git status` in the repo.*
