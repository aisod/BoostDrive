# Mobile BaTLorriH (Logistics) UI Spec for Stitch

## Purpose
This document is the complete UI inventory for the **BaTLorriH (logistics)** side of the mobile app.  
Use it in Stitch to redesign the interface in **light and dark mode** without changing behavior.

---

## 1) Access and Navigation Context

- Role: `logistics` (also visible in provider shell flows)
- Entry: Bottom nav `HUB` -> `ProviderHub` -> top segmented tab `BATLORRIH`
- Parent shell stays visible:
  - Glass app bar (avatar, BoostDrive title, single theme toggle)
  - Hub tabs (`MY SERVICES` / `BATLORRIH`)
  - Bottom navigation (HUB, INVENTORY, ORDERS, SERVICES, ACCOUNT)

---

## 2) BaTLorriH Screen Structure (Top to Bottom)

### A. Header Card
- Title: `BaTLorriH Logistics: {provider full name}`
- Subtitle: `Parts Delivery • Vehicle Transport • Last-Mile Solutions`
- Card style: rounded premium surface, ~24px radius

### B. Metrics Row (2 cards)
- Card 1:
  - Label: `Revenue`
  - Value: Provider total earnings (currency)
  - Subtext: `Lifetime`
- Card 2:
  - Label: `Deliveries`
  - Value: count of delivered orders
  - Subtext: `Completed`

### C. Core Logistics Focus (3 purpose cards)
- Section title: `CORE LOGISTICS FOCUS`
- Card 1:
  - Icon: parts/delivery
  - Title: `Parts Delivery`
  - Description: warehouse/seller -> user/workshop logistics
- Card 2:
  - Icon: vehicle transport
  - Title: `Vehicle Transport`
  - Description: rental and salvage movement
- Card 3:
  - Icon: connectivity/hub
  - Title: `Ecosystem Connectivity`
  - Description: last-mile execution of digital transactions

### D. Live Dispatch Map
- Section header:
  - Left: `Live dispatch map`
  - Right action: `FULLSCREEN`
- Inline map:
  - Height: ~220
  - Rounded corners (~24)
  - Markers for active delivery orders
  - Marker color states:
    - In transit: orange
    - Other active: blue/azure
- Live status overlay pill:
  - `LIVE DISPATCHING`
  - `GPS SYNCED`
  - Active driver count (unique assigned drivers)

### E. Fullscreen Map Modal (from `FULLSCREEN`)
- Fullscreen dialog/screen
- App bar:
  - Title: `Live Dispatch Map`
  - Close button
  - Theme toggle action
- Full map with active order markers

### F. Dispatch Queue Tabs
- Segmented tabs:
  - `ACTIVE`
  - `PICKUPS`
  - `DONE`
- Filtering logic:
  - ACTIVE: not delivered and not cancelled
  - PICKUPS: pending or picking_up
  - DONE: delivered

### G. Delivery Order Cards
Each order card includes:

- Status chip (pending / picking_up / in_transit / delivered)
- ETA block (label + ETA value)
- Order title (`Order #<short id>`)
- Pickup row:
  - Label `PICKUP`
  - pickup address
- Drop-off row:
  - Label `DROP-OFF`
  - drop-off address
- Assignment row:
  - Pending state: route-finding message
  - Assigned state: driver indicator + driver name/id
- Contextual primary action button:
  - Pending: `Assign to me`
  - Picking up (assigned to me): `Start transit`
  - In transit (assigned to me): `Mark delivered`
  - Otherwise: `View`

### H. Empty State
- If tab has no orders:
  - centered icon + message:
  - `No orders in this category.`

---

## 3) Action and Status Behavior (Must Keep)

- Assign flow:
  - `Assign to me` updates order to `picking_up` and sets current user as driver
- Progression flow:
  - `picking_up` -> `in_transit`
  - `in_transit` -> `delivered`
- Non-owner behavior:
  - Users not assigned to the order see `View` instead of progress action
- Feedback:
  - Show snackbars for success and failure

---

## 4) Related Logistics Detail Screen (Opened from `View`)

### Service Tracking / Order Tracking Screen
- App bar:
  - title `Order Tracking`
  - back button
  - optional contact action
- Progress stepper:
  - PENDING -> PICKUP -> IN TRANSIT -> DELIVERED
- Dynamic status headline + ETA subtitle
- Order information card
- Logistics partner/driver card
- Status timeline/log feed with step updates

---

## 5) Visual System Targets (Kinetic Precision)

- Primary accent: orange (`#FF6600`)
- Typography:
  - Manrope for headlines/body
  - Montserrat for labels/buttons
- Radius:
  - cards ~24
  - controls ~12
- Surfaces:
  - frosted/glass app areas where applicable
  - premium elevated cards
- Must support both:
  - Light mode
  - Dark mode

---

## 6) Stitch Deliverables Requested

1. BaTLorriH dashboard (light + dark)
2. Fullscreen map modal (light + dark)
3. Dispatch queue tab states (ACTIVE / PICKUPS / DONE)
4. Delivery order card component states (pending, in progress, delivered, unassigned)
5. Empty state component
6. Order tracking detail screen (light + dark)

---

## 7) Constraint

UI redesign only.  
**Do not change existing business logic, flow logic, status transitions, or backend behavior.**

