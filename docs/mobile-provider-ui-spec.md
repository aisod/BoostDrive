# Mobile Service Provider UI — Complete Inventory for Stitch

**Purpose:** Full inventory of every screen, tab, overlay, and UI element on the **mobile service provider side** of BoostDrive for Stitch (with Google) to redesign in **light and dark mode** without changing behavior.

**Platform:** Flutter (`apps/Mobile`) + shared UI (`packages/boostdrive_ui`).

**Scope:** Users whose profile resolves to provider shell roles: `service_pro`, `seller`, or `logistics` (see `resolveMobileShellRole` in `apps/Mobile/lib/providers.dart`). **Super admin** and **customer** shells are out of scope here.

---

## Architecture overview

```text
MainShell (provider mode)
├── Tab 0: ProviderHub
│   ├── Tab A: MY SERVICES (ServiceProDashboard) OR MY STORE (SellerDashboard)
│   └── Tab B: BATLORRIH (BaTLorriHLogisticsDashboard)
├── Tab 1: ProviderInventoryPage
├── Tab 2: ProviderOrdersPage
│   ├── SOS | REQUESTS | HISTORY
├── Tab 3: ProviderServicesPage (service_pro + logistics only)
└── Tab 4: ProfileSettingsPage (provider / seller account)

Pushed routes (not bottom tabs)
├── SosRequestDetailPage
├── MessagesPage
├── JobCardToolPage
└── ProfileSettingsPage(initialProviderEditMode: true) — edit-only stepper
```

**Data:** Supabase via `boostdrive_auth`, `boostdrive_services`, `boostdrive_core`. No Firebase on mobile.

**Global wrapper on Dashboard tab:** `ProviderProfileSetupReminderScopeMobile` — periodic incomplete-profile dialog (service providers only, not sellers).

---

## Shared shell — Bottom navigation

**File:** `apps/Mobile/lib/main_shell.dart`

**Container:** `MobileCustomerUi.glassBottomNav` wrapping `BottomNavigationBar`.

| Property | Value |
|----------|--------|
| Background | Transparent (glass effect on parent) |
| Selected color | `#FF6600` orange |
| Unselected color | `DashboardPalette.muted` |
| Label style | 10px, letter-spacing 0.5; selected weight 700 |
| Type | `fixed` (5 tabs always visible) |

| Index | Label | Icon (inactive / active) | Screen |
|-------|-------|--------------------------|--------|
| 0 | Dashboard | `grid_view_rounded` | `ProviderHub` |
| 1 | Inventory | `inventory_2_outlined` / `inventory_2` | `ProviderInventoryPage` |
| 2 | Orders | `shopping_bag_outlined` / `shopping_bag` | `ProviderOrdersPage` |
| 3 | Services | `group_outlined` / `group` | `ProviderServicesPage` |
| 4 | Account | `settings_outlined` / `settings` | `ProfileSettingsPage` |

**Behavior:** Tapping a tab swaps body via `KeyedSubtree`; state preserved per tab index in `_providerTabIndex`.

---

## Design tokens (current provider UI)

Provider-facing screens mostly use **dark-first** styling (`BoostDriveTheme.backgroundDark`, `#131D25` cards) inside `PremiumPageLayout` or full-screen dark containers. Orange brand `#FF6600` / `BoostDriveTheme.primaryColor`. Seller dashboard accent blue `#0095FF`.

| Token | Typical value |
|-------|----------------|
| Page background | `BoostDriveTheme.backgroundDark` / dark scaffold |
| Card surface | `#131D25` or `surfaceDark` at 50–55% opacity |
| Borders | `Colors.white` at 5% alpha |
| Primary CTA | Orange filled buttons |
| Seller accent | `#0095FF` |
| Typography | Manrope (headlines/body), some Montserrat in shared components |
| Card radius | 16–24px |
| Section labels | UPPERCASE, 10–11px, letter-spacing 1 |

**Kinetic target (redesign):** Align with `DashboardPalette` light `#F9F9F9` / dark `#09151B`, 24px cards, glass app bars where used on customer flows.

---

# Screen 1 — Provider Hub (container)

**File:** `apps/Mobile/lib/provider_hub.dart`  
**Entry:** Bottom nav **Dashboard** (index 0).

### 1.1 App bar

| Element | Details |
|---------|---------|
| Background | `BoostDriveTheme.primaryColor` orange, elevation 0 |
| Leading | Default back (if route stacked); `automaticallyImplyLeading: true` |
| Title | **Provider Hub** — white, w900, 20px, letter-spacing -0.5 |
| Actions | `mobileAppBarActions()` → theme toggle (+ optional trailing) |
| Bottom | `TabBar` with 2 tabs |

### 1.2 Hub tab bar

| Tab | Label when | Content |
|-----|--------------|---------|
| 1 | **MY SERVICES** if not seller; **MY STORE** if `profile.role` contains `seller` | `ServiceProDashboard` or `SellerDashboard` |
| 2 | **BATLORRIH** (always) | `BaTLorriHLogisticsDashboard` |

| TabBar style | White indicator weight 3; selected white; unselected white70; bold 13px labels |

### 1.3 Layout wrapper

| Element | Details |
|---------|---------|
| `PremiumPageLayout` | `showBackground: false` (no global hero image) |
| Child height | `MediaQuery.height - 120` (accounts for app bar + tab bar) |
| `TabBarView` | Swipe between trade dashboard and logistics dashboard |

### 1.4 Profile setup reminder (overlay)

**File:** `packages/boostdrive_ui/lib/src/provider_profile_setup_reminder.dart` — `ProviderProfileSetupReminderScopeMobile`

| Trigger | Every 3 minutes if profile incomplete; also on first frame |
| Who | `profile.isProvider` and role does **not** contain `seller` |
| Dialog | Non-dismissible barrier; **Complete your profile** title with warning icon |
| Body | Explanation + checklist of missing steps (`ProviderProfileCompletion`) |
| Actions | **Remind me later** (pop); **Edit Profile** → `ProfileSettingsPage(initialProviderEditMode: true)` |

---

# Screen 2 — Service Pro Dashboard (MY SERVICES tab)

**File:** `apps/Mobile/lib/service_pro_dashboard.dart`  
**Roles:** `service_pro`, `logistics` (and non-seller providers in hub tab 1).

**Layout:** `SingleChildScrollView`, horizontal padding 20px, bottom padding ~120px for nav bar.

### 2.1 Header row

| Element | Details |
|---------|---------|
| Avatar | Circle 24px radius; network image or person icon orange |
| Name | `profile.displayName` — Manrope 18 w800 white |
| Subtitle | **PRO ID: @** + first 8 chars of uid uppercase |
| Notifications | Circular icon button; red badge with unread count OR red dot if live SOS alerts |
| Messages | Chat bubble icon; red badge with unread conversation count |
| Tap notifications | Opens notifications overlay dialog |
| Tap messages | Pushes `MessagesPage` |

### 2.2 Availability status

| Element | Details |
|---------|---------|
| Section label | **AVAILABILITY STATUS** — 10px caps white70 |
| Control | Segmented row: **AVAILABLE** (wifi icon) \| **OFFLINE** (power icon) |
| Active segment | Orange fill when online; white10 when offline selected |
| Loading | **Updating availability...** while saving |
| Online hint | Green bullet: **Live location visible to SOS dispatch** |
| Behavior | Updates `profile.isOnline` via `userService.updateProfile`; optimistic UI |

### 2.3 Active job map

| Element | Details |
|---------|---------|
| Section label | **ACTIVE JOB MAP** |
| Map height | 220px, 24px radius, bordered |
| Map | `GoogleMap` via `BoostdriveGoogleMapGate`; dark custom map style |
| Marker | Orange default marker at provider GPS (**My Location**) |
| Overlay pill | **ONE-TAP NAV READY** with navigation icon |
| FAB | Small orange **my_location** — re-centers camera |
| Behavior | Polls provider location to assigned SOS every 20s when jobs active |

### 2.4 Stats row (3 cards)

| Card | Label | Value | Subtext |
|------|-------|-------|---------|
| 1 | Earnings | `$` + `totalEarnings` | **LIFETIME** (green) |
| 2 | Jobs | completed SOS count | **COMPLETED** |
| 3 | Rating | **—** | **NO REVIEWS YET** (muted) |

### 2.5 Live SOS alerts

| Element | Details |
|---------|---------|
| Header | **LIVE SOS ALERTS** + **HISTORY** text button (placeholder `onPressed: () {}`) |
| Empty (no service types) | Message: add types in Account → Profile |
| Empty (no matches) | Message listing provider service types |
| Request cards | One per matching pending SOS from global stream |

**Each SOS request card:**

| Element | Details |
|---------|---------|
| Tag chip | **SOS — {TYPE}** — red if towing, blue otherwise |
| Distance | Amber text (GPS distance or enable GPS message) |
| Title | User note or **No notes provided** |
| Subtitle | Truncated customer id |
| Hint row | Tap to open — customer sees responding before accept |
| **OPEN REQUEST** | Outlined button → `SosRequestDetailPage` |
| **ACCEPT** | Orange filled — accept + assign provider |

### 2.6 Ongoing fulfillment

| Element | Details |
|---------|---------|
| Header | **ONGOING FULFILLMENT** |
| Empty | Icon `assignment_outlined` + **No ongoing jobs** |
| Job rows | Assigned SOS list: shipping icon, note/type, status, chevron → detail page |

### 2.7 Active services

| Element | Details |
|---------|---------|
| Header | **ACTIVE SERVICES** |
| Empty | Settings icon + prompt to add in Services tab |
| Content | Orange `Chip` per active row from `provider_services` catalog |

### 2.8 Customer job card requests

| Element | Details |
|---------|---------|
| Header | **CUSTOMER JOB CARD REQUESTS** |
| Empty | **No new job card requests yet.** |
| Tiles | Up to 3 visible — `MobileJobCardUi.providerTile` |
| **Respond** | Opens quote dialog (labor amount N$) → sends provider quote |
| Status | Only when status `submitted` |

**Quote dialog:** Title **Respond with labor quote**; amount field; **CANCEL** / **SEND QUOTE**.

---

# Screen 3 — Seller Dashboard (MY STORE tab)

**File:** `apps/Mobile/lib/seller_dashboard.dart`  
**When:** Hub tab 1 label **MY STORE** (`profile.role` contains `seller`).

**Accent:** Blue `#0095FF` for FAB, tabs, prices (distinct from orange service pro).

### 3.1 Header

| Element | Details |
|---------|---------|
| Avatar | 28px radius |
| Title | **BoostDrive Seller** |
| Subtitle | `{registeredBusinessName or "My Store"} • Official Seller` |
| Search | Icon button (placeholder `onPressed: () {}`) |
| Notifications | Bell with red dot badge |

### 3.2 Performance section

| Element | Details |
|---------|---------|
| Title | **Performance** |
| Period | **Last 7 Days** + dropdown chevron (display only) |
| Horizontal scroll cards | **Total Sales** `$12,450` +12%; **Active Listings** `1,248` +3%; **Pending Orders** `14` 0% |
| Card size | 160px wide, 24px radius |

### 3.3 Tab section (visual tabs — note: all show inventory UI)

| Tab labels | INVENTORY \| SERVICE REQUESTS \| ORDERS |
| Content below | Search row + product list (tab controller exists; content is inventory-focused) |

### 3.4 Inventory search row

| Element | Details |
|---------|---------|
| Search field | Placeholder **Search SKU, name or VIN...** (display row, not wired TextField in mock) |
| Filter | 56×56 tune icon button |

### 3.5 Product / inventory cards

| Element | Details |
|---------|---------|
| Image | 100×100, 16px radius; network or placeholder icon |
| Tag pill | SALVAGE / NEW OEM / USED — color-coded |
| Title | Product name, 2 lines max |
| SKU line | **SKU: {id}** |
| Price | `$` + amount in blue |
| Stock pill | In Stock (green) / Out of Stock / Draft (orange) |
| Clicks | Eye icon + click count |
| Menu | `more_vert` icon |
| Data | `sellerProductsProvider` or placeholder demo cards when empty |

### 3.6 Service requests section (below tabs)

Separate section **Service Requests** with request cards (read file if needed - user had _buildServiceRequestsSection).

### 3.7 FAB

| Element | Details |
|---------|---------|
| Position | Standard FAB |
| Color | Blue `#0095FF` |
| Icon | `add` white 32px |
| Action | `onPressed: () {}` placeholder |

---

# Screen 4 — BaTLorriH Logistics Dashboard (BATLORRIH tab)

**File:** `apps/Mobile/lib/batlorrih_logistics_dashboard.dart`  
**Audience:** All provider-shell users; logistics-focused copy and delivery orders.

### 4.1 Header

| Element | Details |
|---------|---------|
| Icon box | Orange shipping icon in rounded square |
| Brand | **BaTLorriH** bold |
| Name | `profile.fullName` |
| Subtitle | **Logistics • Parts & Vehicle Transport** |

### 4.2 Metrics row

| Card | Content |
|------|---------|
| REVENUE | `$` + totalEarnings, trend +12.4% |
| DELIVERIES | Completed delivery count, **98% Success** |

### 4.3 Core logistics focus

| Card | Icon | Title | Description |
|------|------|-------|-------------|
| 1 | settings_input_component | Parts Delivery | Seller/warehouse to user/workshop |
| 2 | directions_car | Vehicle Transport | Rental and salvage movement |
| 3 | hub | Ecosystem Connectivity | Last-mile for digital transactions |

### 4.4 Live dispatch map

| Element | Details |
|---------|---------|
| Title row | Map icon + **Live Dispatch Map** + **FULLSCREEN** button |
| Map | 220px; markers per active `DeliveryOrder` |
| Marker colors | Orange in transit, azure otherwise |
| Overlay | **N DRIVERS LIVE** green dot |
| Fullscreen dialog | Full-screen map with orange app bar, close, theme actions |

### 4.5 Order tabs

| Tab | Filter |
|-----|--------|
| Active Queue | Non-delivered, non-cancelled |
| Pickups | Pickup-oriented subset |
| Completed | Delivered / history |

### 4.6 Order list items

Delivery order cards with status, addresses, driver assignment (see file for row actions).

---

# Screen 5 — Inventory (bottom nav tab 1)

**File:** `apps/Mobile/lib/provider_inventory_page.dart`

**Background:** Full-screen `BoostDriveTheme.backgroundDark`, `SafeArea`, pull-to-refresh.

### 5.1 Page header

| Element | Details |
|---------|---------|
| Title | **INVENTORY** — 22px w900 white |

### 5.2 Search

| Element | Details |
|---------|---------|
| Field | **Search parts, SKU, barcode…** |
| Icon | Search prefix |
| Behavior | Filters list client-side |

### 5.3 Summary cards (3-up)

| Card | Metric |
|------|--------|
| Total items | Row count |
| Low stock | qty ≤ threshold |
| Mobile ready | % with `available_for_mobile` |

### 5.4 Quick-add barcode

| Element | Details |
|---------|---------|
| Section | **Quick-add (barcode)** |
| Field | **Scan or type barcode** |
| Button | **ADD** — inserts inventory line |
| Note | Camera scanner planned later |

### 5.5 Parts list

**Per-item tile:** name, SKU, stock qty, threshold, mobile flag, edit/adjust actions (tap opens dialogs/sheets in file).

### 5.6 Service kits

| Element | Details |
|---------|---------|
| **Add kit** | Outlined button → add kit dialog |
| Cards | Name, vehicle notes; edit / delete icons |
| Empty | Hint to create in Supabase |

### 5.7 Equipment status

| Element | Details |
|---------|---------|
| **Add equipment** | Outlined button |
| Cards | Name, status; edit / delete |

---

# Screen 6 — Orders (bottom nav tab 2)

**File:** `apps/Mobile/lib/provider_orders_page.dart`

**Title:** **ORDERS** (top padding).

### 6.1 Tab bar

| Tab | Content widget |
|-----|----------------|
| SOS | `_SosTab` |
| REQUESTS | `_RequestsTab` |
| HISTORY | `_HistoryTab` |

### 6.2 SOS tab

| State | UI |
|-------|-----|
| Focus mode | One assigned SOS; message hides other cards; **CANCEL ASSIGNMENT** |
| No types | Prompt to set service types in profile |
| Pending pool | Stream of matching SOS cards |

**SOS card elements:**

| Element | Action |
|---------|--------|
| Status label | Focused / Pending |
| Note or type | Title |
| **Call** | Placeholder snackbar |
| **Navigate** | Opens Google Maps directions |
| **OPEN** | `SosRequestDetailPage` |
| **ACCEPT** | Assign provider |
| **CANCEL ASSIGNMENT** | Dialog with optional reason |

### 6.3 Requests tab

| Section | Content |
|---------|---------|
| JOB CARD EXECUTION | Cards with labor amount, status progression buttons (SET ACTIVE → IN PROGRESS → COMPLETED) |
| OTHER REQUESTS | `service_requests` list tiles |

### 6.4 History tab

Completed / past SOS and requests list (historical statuses).

---

# Screen 7 — Services (bottom nav tab 3)

**File:** `apps/Mobile/lib/provider_services_page.dart`

**Access:** `service_pro` or `logistics` only. Sellers see centered message: catalog management for service providers only.

### 7.1 Header

| Element | Details |
|---------|---------|
| Title | **SERVICES** top-left |

### 7.2 Service catalog cards

| Element | Details |
|---------|---------|
| Name | 16px w800 white |
| Category | Orange label (mechanical, towing, etc.) |
| Description | Muted body |
| Price | **N$** formatted |
| Duration | **~ N min** |
| **Active** switch | Toggles `is_active` in DB |
| Edit | Opens bottom sheet form |
| Delete | Confirm dialog |

### 7.3 FAB / add

Floating or sheet entry to **add service** — form fields: name, category dropdown, description, price, estimated minutes (see `_openAddSheet` in file).

**Categories:** mechanical, electrical, bodywork, diagnostics, towing, other.

---

# Screen 8 — Account / Provider Profile Settings (bottom nav tab 4)

**File:** `packages/boostdrive_ui/lib/src/profile_settings_page.dart`  
**Also documented in:** `docs/mobile-profile-settings-ui-spec.md` Part C.

### 8.1 View mode (mobile provider)

| Element | Details |
|---------|---------|
| Scaffold | `extendBodyBehindAppBar: true` |
| App bar | Transparent; **Provider Profile** title; theme toggle; **Edit Profile** white pill |
| Hero | 180px orange gradient banner |
| Avatar | 104px overlapping banner; camera FAB in edit mode |
| Identity | Business display name; **Verified {role}** chip if approved |

**Stacked section cards** (`ProviderProfileUi.sectionCard`):

1. Business Information  
2. Safety & SOS (mobile only)  
3. Service Area & Hours  
4. Services You Provide (chips: mechanic, towing, parts, rental)  
5. Operational & Business Details  
6. Service Specializations (brand / service / towing chips)  
7. Financial & Payout  
8. Trust & Experience (bio, gallery 1–10 photos, team size)  
9. Documents Vault (mobile only) — 7 legal slots + gallery slots 7–16  
10. Control Center (expansion: emergency contacts / staff / payouts)  
11. Log out / Delete account  
12. Footer: version + **AUTHORIZED PROVIDER INSTANCE**

### 8.2 Edit mode (pushed route)

**Route:** `ProfileSettingsPage(initialProviderEditMode: true)`

| Element | Details |
|---------|---------|
| App bar title | **Edit Profile Settings** |
| Action | **Exit Edit Mode** text → pop |
| Stepper | Step 1 **Business Profile**; Step 2 **Legal Docs & Certs** |
| Buttons | Back, Next, Save Profile, Cancel, Save Changes |
| Fields | Read-only gray when not editing; orange primary buttons |

---

# Screen 9 — SOS Request Detail (pushed)

**File:** `apps/Mobile/lib/sos_request_detail_page.dart`

| Element | Details |
|---------|---------|
| App bar | **SOS REQUEST**; theme toggle in actions |
| Title block | User note, type, emergency category, lat/lng |
| Map | Expanded — requester location marker |
| Hint | Customer sees provider reviewing while on screen |
| Primary CTA | **ACCEPT REQUEST** / **ASSIGNED TO YOU** / **ALREADY ASSIGNED** |
| **NAVIGATE TO CLIENT** | If valid coordinates |
| **Complete** | Proximity-gated completion + optional note |
| **Cancel assignment** | If assigned to me |
| Heartbeat | Provider responding ping every 12s while open |

---

# Screen 10 — Messages (pushed)

**File:** `apps/Mobile/lib/messages_page.dart`  
**Entry:** Service pro dashboard header chat icon.

Uses `MessagesUi` (Kinetic) — list + active chat, composer, voice, read receipts, tablet split. Same component family as customer messages; provider context in conversation headers.

---

# Screen 11 — Job Card Tool (pushed, optional)

**File:** `apps/Mobile/lib/job_card_tool_page.dart`  
**UI module:** `packages/boostdrive_ui/lib/src/mobile_job_card_ui.dart`

| Mode | Title | Features |
|------|-------|----------|
| Provider | Incoming Job Cards | Stats row, provider tiles, quote/respond, detail sheet |
| Customer | My Job Card Requests | FAB new job card, customer tiles |

Provider dashboard embeds summary tiles; full page available via navigation/deep link with `initialJobCardId`.

---

# Shared components reference

| Component | File |
|-----------|------|
| `ProviderProfileUi` | `provider_profile_ui.dart` — section cards, hero, stepper, inputs |
| `ProviderProfileSetupReminderScopeMobile` | `provider_profile_setup_reminder.dart` |
| `MobileJobCardUi` | `mobile_job_card_ui.dart` |
| `MobileCustomerUi` | `mobile_customer_ui.dart` — glass nav, app bar actions |
| `DashboardPalette` / `DashboardTypography` | Theme tokens |
| `PremiumPageLayout` | Hub wrapper |
| `BoostdriveGoogleMapGate` | Map API key gate |
| `mobileAppBarActions` | Theme toggle helper |

---

# States and edge cases

| State | UI |
|-------|-----|
| Not logged in | **Please log in** |
| Profile loading | `CircularProgressIndicator` |
| Provider services page wrong role | Centered explanation text |
| Inventory / orders DB error | Red error text + migration hints |
| Saving availability | Disabled toggles + status text |
| Empty lists | Context-specific empty cards with icons |
| Optimistic online toggle | Reverts on API failure |

---

# Behavior to preserve (Stitch redesign)

- Role-based hub tab label (MY SERVICES vs MY STORE)  
- SOS accept / assign / cancel / complete / proximity rules  
- Provider online toggle and location pulse to assigned SOS  
- Service type filtering for SOS matching  
- Inventory CRUD, kits, equipment operations  
- Service catalog active toggle and CRUD  
- Provider profile stepper validation and document slot indices 0–6 vs gallery 7–16  
- Profile setup reminder interval and navigation to edit mode  
- Bottom nav five-tab structure and indices  
- All Supabase reads/writes and Riverpod invalidation patterns  

---

# Stitch redesign checklist

Provide **light + dark** frames for:

- [ ] Provider bottom navigation (5 tabs, active Dashboard)
- [ ] Provider Hub app bar + two hub tabs
- [ ] Service Pro Dashboard — full scroll (header, availability, map, stats, SOS card, ongoing, services chips, job cards)
- [ ] Service Pro — SOS request card states (pending vs accepted)
- [ ] Seller Dashboard — performance cards + inventory card
- [ ] BaTLorriH — metrics, purpose cards, map, order tabs
- [ ] Inventory — summary, barcode add, part row, kit row
- [ ] Orders — SOS / Requests / History tabs
- [ ] Services — catalog card + add/edit sheet
- [ ] Provider Profile — view hero + section cards
- [ ] Provider Profile — edit stepper steps 1 and 2
- [ ] Documents Vault rows
- [ ] SOS Request Detail
- [ ] Messages (provider entry)
- [ ] Job card quote dialog
- [ ] Complete profile reminder dialog
- [ ] Notifications overlay (from dashboard header)

**Match Kinetic:** Manrope/Montserrat, orange `#FF6600`, 24px cards, light `#F9F9F9` / dark `#09151B`, glass nav consistent with customer mobile.

---

## Files reference

| File | Role |
|------|------|
| `apps/Mobile/lib/main_shell.dart` | Provider bottom nav + tab routing |
| `apps/Mobile/lib/provider_hub.dart` | Hub container + tab bar |
| `apps/Mobile/lib/service_pro_dashboard.dart` | Mechanic/towing/etc. dashboard |
| `apps/Mobile/lib/seller_dashboard.dart` | Marketplace seller dashboard |
| `apps/Mobile/lib/batlorrih_logistics_dashboard.dart` | Logistics / BaTLorriH |
| `apps/Mobile/lib/provider_inventory_page.dart` | Inventory tab |
| `apps/Mobile/lib/provider_orders_page.dart` | Orders tab |
| `apps/Mobile/lib/provider_services_page.dart` | Services catalog tab |
| `apps/Mobile/lib/sos_request_detail_page.dart` | SOS detail flow |
| `apps/Mobile/lib/messages_page.dart` | Messaging |
| `apps/Mobile/lib/job_card_tool_page.dart` | Job cards |
| `packages/boostdrive_ui/lib/src/profile_settings_page.dart` | Account tab profile |
| `packages/boostdrive_ui/lib/src/provider_profile_ui.dart` | Provider UI primitives |
| `apps/Mobile/lib/providers.dart` | Role resolution |

---

*Generated from codebase audit for Stitch + Google UI redesign. Redesign visuals only unless product requests functional changes.*
