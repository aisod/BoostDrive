# BoostDrive Master Test Cases

## Scope
This document provides executable test cases for the full BoostDrive platform:
- Mobile app
- Web app
- Shared backend (Supabase, edge functions, notifications, role-based flows)

Each test case includes:
- **ID**
- **Module**
- **Preconditions**
- **Steps**
- **Expected Result**

---

## Test Environment
- **Build targets:** Android, iOS, Web (Chrome)
- **Backend:** Supabase (staging/prod-like test project)
- **Core test accounts:**
  - `admin_01`
  - `customer_01`
  - `seller_01`
  - `service_pro_01`
  - `service_pro_02`
  - `logistics_01`
- **Seed data needed:**
  - Approved providers with services and inventory
  - At least 5 marketplace products
  - At least 3 SOS requests across statuses
  - At least 2 delivery orders
  - At least 2 job cards

---

## A. Authentication and Account Lifecycle

### TC-AUTH-001: User registration (customer)
- **Preconditions:** Email not already used.
- **Steps:** Open app -> Sign up as customer -> submit valid data.
- **Expected Result:** Account created, user redirected to dashboard, profile row created.

### TC-AUTH-002: User registration (provider role)
- **Preconditions:** Clean email and valid provider details.
- **Steps:** Sign up as provider (mechanic/towing/logistics).
- **Expected Result:** Account created with provider role, provider profile fields persisted.

### TC-AUTH-003: Login with valid credentials
- **Preconditions:** Existing user.
- **Steps:** Enter valid email/password -> Login.
- **Expected Result:** Successful login, session persisted, correct role dashboard loaded.

### TC-AUTH-004: Login with invalid password
- **Preconditions:** Existing user.
- **Steps:** Enter wrong password -> Login.
- **Expected Result:** Login blocked with clear error message.

### TC-AUTH-005: Forgot password flow
- **Preconditions:** Existing email.
- **Steps:** Trigger reset password -> complete reset link flow -> login with new password.
- **Expected Result:** Password updated and old password rejected.

### TC-AUTH-006: Session persistence after app restart
- **Preconditions:** Logged in user.
- **Steps:** Close app/browser tab -> reopen.
- **Expected Result:** User remains authenticated until explicit logout.

### TC-AUTH-007: Logout flow
- **Preconditions:** Logged in user.
- **Steps:** Tap logout.
- **Expected Result:** Session cleared and redirected to auth screen.

---

## B. Role Routing and Access Control

### TC-RBAC-001: Admin-only routes
- **Preconditions:** Logged in as non-admin.
- **Steps:** Attempt to open admin dashboard route directly.
- **Expected Result:** Access denied/redirect; no admin data exposed.

### TC-RBAC-002: Provider-only management routes
- **Preconditions:** Logged in as customer/seller.
- **Steps:** Try opening provider service management pages.
- **Expected Result:** Customer sees read-only or blocked state; no write access.

### TC-RBAC-003: Customer read-only service marketplace
- **Preconditions:** Provider has services.
- **Steps:** Open services marketplace as customer.
- **Expected Result:** Services visible; edit/delete/toggle actions not visible.

### TC-RBAC-004: Provider CRUD on own services only
- **Preconditions:** Provider A and Provider B exist.
- **Steps:** Provider A tries to edit/delete Provider B service via UI/forced request.
- **Expected Result:** Operation blocked by policy; only owner-managed rows writable.

---

## C. Marketplace Listings (Cars, Parts, Rentals)

### TC-LIST-001: Create listing (seller)
- **Preconditions:** Seller account active.
- **Steps:** Add listing with valid required fields and image.
- **Expected Result:** Listing created and appears in marketplace feed.

### TC-LIST-002: Edit listing
- **Preconditions:** Existing seller listing.
- **Steps:** Edit title/price/description -> save.
- **Expected Result:** Updated values visible in listing and details page.

### TC-LIST-003: Delete listing
- **Preconditions:** Existing seller listing.
- **Steps:** Delete listing and confirm.
- **Expected Result:** Listing removed from seller dashboard and marketplace.

### TC-LIST-004: Listing validation
- **Preconditions:** Seller create form open.
- **Steps:** Submit with missing required fields.
- **Expected Result:** Validation errors shown; listing not created.

### TC-LIST-005: Filter and search listings
- **Preconditions:** Multiple categories listed.
- **Steps:** Use search text and category filters.
- **Expected Result:** Results update accurately and quickly.

---

## D. Cart and Checkout

### TC-CART-001: Add item to cart
- **Preconditions:** Product exists.
- **Steps:** Add from product card/details.
- **Expected Result:** Cart count and total update correctly.

### TC-CART-002: Remove item from cart
- **Preconditions:** Cart has at least one item.
- **Steps:** Remove via delete action.
- **Expected Result:** Item removed and total recalculated.

### TC-CART-003: Recommended parts push acceptance
- **Preconditions:** Provider has pushed job-card parts to customer.
- **Steps:** Open cart -> accept push.
- **Expected Result:** Pushed parts added to cart with correct quantity and price.

### TC-CART-004: Recommended parts push rejection
- **Preconditions:** Pending push exists.
- **Steps:** Dismiss push.
- **Expected Result:** Push status changes to rejected and no cart changes occur.

### TC-CART-005: Message seller directly from checkout
- **Preconditions:** Cart has items, user logged in.
- **Steps:** Checkout -> choose Message Seller Directly.
- **Expected Result:** Seller conversation opens (or seller selector appears for multi-seller carts), and prefilled cart summary message is sent.

### TC-CART-006: Online payments coming soon placeholder
- **Preconditions:** Cart has items.
- **Steps:** Checkout -> choose Online Payments (Coming Soon).
- **Expected Result:** “Coming soon” message shown; no payment transaction starts.

---

## E. Provider Services, Inventory, Kits, Equipment

### TC-PROV-001: Create provider service
- **Preconditions:** Provider account approved.
- **Steps:** Add service with category, price, duration.
- **Expected Result:** Service saved and visible in provider list and customer marketplace view.

### TC-PROV-002: Edit provider service
- **Preconditions:** Existing provider service.
- **Steps:** Update values -> save.
- **Expected Result:** Changes persist and refresh in dashboard cards.

### TC-PROV-003: Delete provider service
- **Preconditions:** Existing provider service.
- **Steps:** Delete and confirm.
- **Expected Result:** Service removed and no stale UI row remains.

### TC-PROV-004: Toggle provider online/offline
- **Preconditions:** Provider logged in.
- **Steps:** Toggle availability.
- **Expected Result:** State updates immediately without hot refresh.

### TC-PROV-005: Add inventory item
- **Preconditions:** Provider account.
- **Steps:** Add inventory part with stock quantity.
- **Expected Result:** Item appears in inventory list and saved in DB.

### TC-PROV-006: Edit inventory quantity
- **Preconditions:** Inventory item exists.
- **Steps:** Adjust stock quantity.
- **Expected Result:** Quantity persisted and displayed correctly.

### TC-PROV-007: Add service kit
- **Preconditions:** Provider has inventory parts.
- **Steps:** Create service kit with part composition.
- **Expected Result:** Kit saved and retrievable in provider UI.

### TC-PROV-008: Equipment status update
- **Preconditions:** Equipment rows exist.
- **Steps:** Update equipment status field.
- **Expected Result:** New status shown in list and available for filters.

---

## F. Job Card and Diagnostics Workflow

### TC-JC-001: Customer creates job card request
- **Preconditions:** Customer account.
- **Steps:** Open customer job card tool -> submit request.
- **Expected Result:** Job card status = submitted/pending provider quote; visible to providers.

### TC-JC-002: Job card appears to all providers
- **Preconditions:** New unassigned job card exists.
- **Steps:** Login as Provider A and Provider B.
- **Expected Result:** Both can see incoming request list item.

### TC-JC-003: Atomic quote claim (race condition)
- **Preconditions:** Same new job card, two providers online.
- **Steps:** Provider A and B attempt quote at near same time.
- **Expected Result:** Only one quote succeeds; second provider blocked with clear message.

### TC-JC-004: Provider submits labor quote
- **Preconditions:** Provider owns claim.
- **Steps:** Respond with price.
- **Expected Result:** Status changes to quoted/awaiting client response; requester notified.

### TC-JC-005: Customer accepts quote
- **Preconditions:** Quoted job card.
- **Steps:** Customer taps accept.
- **Expected Result:** Status changes to accepted; provider sees execution flow.

### TC-JC-006: Customer declines quote
- **Preconditions:** Quoted job card.
- **Steps:** Customer taps decline.
- **Expected Result:** Status changes to declined; provider receives decision notification.

### TC-JC-007: Cancel job card request with confirmation
- **Preconditions:** Request still cancelable.
- **Steps:** Tap cancel -> confirm dialog.
- **Expected Result:** Request canceled and reflected in both parties’ feeds.

### TC-JC-008: Required parts visible only after acceptance (provider side)
- **Preconditions:** Quote accepted.
- **Steps:** Provider opens card details.
- **Expected Result:** Required-parts push controls shown only to provider, not requester.

### TC-JC-009: Push required parts to customer cart
- **Preconditions:** Accepted job card with parts.
- **Steps:** Provider pushes parts.
- **Expected Result:** Customer receives actionable cart recommendation prompt.

### TC-JC-010: Provider execution statuses
- **Preconditions:** Accepted job card.
- **Steps:** Provider sets active -> in-progress -> completed.
- **Expected Result:** Status transitions valid; requester receives notifications each step.

### TC-JC-011: Completion effects
- **Preconditions:** Job card completed with labor + parts.
- **Steps:** Mark completed.
- **Expected Result:** Invoice row generated, provider earnings updated, inventory deducted.

### TC-JC-012: Review prompt after completion
- **Preconditions:** Completed provider task.
- **Steps:** Customer opens dashboard/emergency hub.
- **Expected Result:** Pending review prompt created for that provider and task.

---

## G. SOS Emergency Flow

### TC-SOS-001: Create SOS request with location
- **Preconditions:** Customer with location permissions.
- **Steps:** Trigger SOS request.
- **Expected Result:** SOS row created with coordinates and pending status.

### TC-SOS-002: Provider sees pending SOS
- **Preconditions:** Pending SOS exists.
- **Steps:** Open provider SOS tab.
- **Expected Result:** Request visible in provider queue.

### TC-SOS-003: Provider accepts SOS
- **Preconditions:** Pending SOS.
- **Steps:** Accept request.
- **Expected Result:** Request assigned to provider, status updated, requester notified.

### TC-SOS-004: Provider location tracking update
- **Preconditions:** Assigned SOS.
- **Steps:** Provider tracking update occurs.
- **Expected Result:** provider_last_lat/lng and ETA fields update.

### TC-SOS-005: Provider completes SOS
- **Preconditions:** Assigned/active SOS.
- **Steps:** Mark complete with required location validation.
- **Expected Result:** Status completed/resolved and completion notification sent.

### TC-SOS-006: Failed-fetch resilience on web polling
- **Preconditions:** Simulated transient network interruption.
- **Steps:** Keep provider orders page open during interruption.
- **Expected Result:** Polling retries and stream recovers gracefully.

---

## H. Delivery / BaTLorriH Logistics

### TC-DEL-001: Pending delivery appears in queue
- **Preconditions:** Delivery order status pending.
- **Steps:** Open logistics dashboard.
- **Expected Result:** Order appears in pickup queue.

### TC-DEL-002: Assign-to-me action
- **Preconditions:** Pending order.
- **Steps:** Logistics user taps assign.
- **Expected Result:** Driver assigned; status moves to picking_up.

### TC-DEL-003: Start transit progression
- **Preconditions:** Assigned order status picking_up.
- **Steps:** Tap “Start transit”.
- **Expected Result:** Status updates to in_transit.

### TC-DEL-004: Mark delivered progression
- **Preconditions:** Order in transit.
- **Steps:** Tap “Mark delivered”.
- **Expected Result:** Status updates to delivered and moved to history lists.

### TC-DEL-005: Driver live marker priority
- **Preconditions:** Driver telemetry exists.
- **Steps:** Open map.
- **Expected Result:** Marker uses driver live coordinates when present.

---

## I. Notifications and Deep Linking

### TC-NOTIF-001: Job card quote notification to requester
- **Preconditions:** Provider submits quote.
- **Steps:** Open requester notifications and tap item.
- **Expected Result:** Deep-links to Job Card tool with correct card focus.

### TC-NOTIF-002: Job card status update notification
- **Preconditions:** Provider changes execution status.
- **Steps:** Requester taps status notification.
- **Expected Result:** Correct job card opens and displays latest status.

### TC-NOTIF-003: Notification metadata routing
- **Preconditions:** Notification has metadata job_card_id/sos_request_id.
- **Steps:** Tap notification.
- **Expected Result:** App routes using metadata IDs, not fallback string parsing only.

### TC-NOTIF-004: Mark-as-read behavior
- **Preconditions:** Unread notifications exist.
- **Steps:** Open and tap one notification.
- **Expected Result:** Notification marked read and unread badge count decrements.

### TC-NOTIF-005: Bidirectional communication visibility
- **Preconditions:** Customer/provider exchange job-card decisions.
- **Steps:** Check both users’ notifications.
- **Expected Result:** Both parties receive corresponding updates.

---

## J. Messaging and Support

### TC-MSG-001: Start new conversation
- **Preconditions:** Two users with valid IDs.
- **Steps:** Open provider profile -> send first message.
- **Expected Result:** Conversation created and message appears for both users.

### TC-MSG-002: Send text/image/voice message
- **Preconditions:** Existing conversation.
- **Steps:** Send each supported message type.
- **Expected Result:** Delivery and rendering correct across clients.

### TC-MSG-003: Unread badge updates
- **Preconditions:** Recipient has unread messages.
- **Steps:** Open notifications/messages list.
- **Expected Result:** Unread count appears and clears when viewed.

### TC-SUP-001: Create support ticket
- **Preconditions:** Logged-in user.
- **Steps:** Submit support request.
- **Expected Result:** Ticket created and visible in support center/admin queue.

### TC-SUP-002: Admin responds to support ticket
- **Preconditions:** Open ticket exists.
- **Steps:** Admin posts response.
- **Expected Result:** User receives support notification and can view reply.

---

## K. Admin Dashboards and Financial Signals

### TC-ADM-001: Active SOS KPI dynamic
- **Preconditions:** SOS rows with active operational statuses.
- **Steps:** Open admin dashboard.
- **Expected Result:** KPI equals live count from operational active stream.

### TC-ADM-002: SOS operational map render
- **Preconditions:** Active SOS rows with valid coordinates.
- **Steps:** Open operational overview map.
- **Expected Result:** Map visible with marker count matching plotted rows.

### TC-ADM-003: Service Revenue Breakdown dynamic
- **Preconditions:** provider_services rows with category + price.
- **Steps:** Open financials view.
- **Expected Result:** Category totals and percentages reflect live DB aggregates.

### TC-ADM-004: Dynamic commission/opex config
- **Preconditions:** platform_financial_settings row exists.
- **Steps:** Change commission_rate/operating_cost -> reload financials.
- **Expected Result:** KPI and net revenue recalculate immediately from DB config.

### TC-ADM-005: Pending verification KPI
- **Preconditions:** Pending verification users exist.
- **Steps:** Open dashboard.
- **Expected Result:** Count matches current pending queue size.

---

## L. Security, Data Integrity, and Policies

### TC-SEC-001: RLS blocks unauthorized write
- **Preconditions:** Customer token.
- **Steps:** Attempt provider_services insert/update via client.
- **Expected Result:** Supabase rejects operation.

### TC-SEC-002: Provider can manage only own service rows
- **Preconditions:** Provider A and B rows.
- **Steps:** Provider A tries to update Provider B row.
- **Expected Result:** Operation rejected.

### TC-SEC-003: Notification write policy validation
- **Preconditions:** Regular user.
- **Steps:** Attempt insert notification for unrelated recipient.
- **Expected Result:** Operation rejected unless policy allows system path.

### TC-SEC-004: No secret leakage in repo
- **Preconditions:** Working tree has changes.
- **Steps:** Inspect tracked files before commit.
- **Expected Result:** No `.env` or credential file included in commit.

---

## M. Performance and Reliability

### TC-PERF-001: Dashboard load under normal data size
- **Preconditions:** 1k+ representative rows across core tables.
- **Steps:** Open key dashboards.
- **Expected Result:** First meaningful paint and interactive state acceptable (<3s target on test env).

### TC-PERF-002: Stream update responsiveness
- **Preconditions:** Live stream providers active.
- **Steps:** Change SOS status and observe UI.
- **Expected Result:** UI reflects updates near real-time without manual refresh.

### TC-PERF-003: Retry resilience during intermittent network
- **Preconditions:** Simulate short disconnect.
- **Steps:** Keep provider/admin pages open.
- **Expected Result:** Streams/polling recover and data re-syncs.

---

## N. Regression Smoke Suite (Release Gate)

### TC-SMOKE-001: Auth login/logout
- **Expected Result:** Pass.

### TC-SMOKE-002: Create/edit/delete listing
- **Expected Result:** Pass.

### TC-SMOKE-003: Add to cart + manual checkout
- **Expected Result:** Pass.

### TC-SMOKE-004: Customer creates job card; provider quotes; customer accepts
- **Expected Result:** Pass.

### TC-SMOKE-005: Provider completes job card; review prompt appears
- **Expected Result:** Pass.

### TC-SMOKE-006: SOS create -> accept -> complete
- **Expected Result:** Pass.

### TC-SMOKE-007: Logistics assign -> in_transit -> delivered
- **Expected Result:** Pass.

### TC-SMOKE-008: Notification deep-link opens correct target
- **Expected Result:** Pass.

### TC-SMOKE-009: Admin SOS KPI and map both update from live data
- **Expected Result:** Pass.

### TC-SMOKE-010: Admin financials dynamic breakdown loads
- **Expected Result:** Pass.

---

## Suggested Execution Matrix
- Execute each suite on:
  - **Web Chrome**
  - **Android**
  - **iOS**
- Run **Smoke Suite** on every candidate build.
- Run full suites before milestone/demo/release.

---

## Traceability Notes
- Link each test result to:
  - Build number
  - Tester
  - Date/time
  - Environment (staging/prod clone)
  - Evidence (screenshots/video/log excerpts)

---

## Targeted QA Retest Matrix (18 April Failed Cases)

Use this compact rerun list for the failed IDs from the 18 April QA PDF.

### TC-RETEST-SO-02: SOS waiting status + context visibility
- **Preconditions:** Customer logged in, one active SOS exists.
- **Steps:**
  1. Open `Emergency SOS`.
  2. Ensure active SOS card is visible.
  3. Verify status chip + context line (time and coordinates) are shown.
  4. Verify waiting map or fallback panel is visible (not blank).
- **Expected Result:** Status and context are always readable; UI does not remain blank.

### TC-RETEST-SO-08: SOS navigate action launches maps
- **Preconditions:** Active SOS with valid coordinates.
- **Steps:**
  1. Open active SOS card.
  2. Tap navigate/open-map action.
  3. If blocked by device/browser, observe user feedback.
- **Expected Result:** External map opens via supported URI fallback chain; if launch fails, a clear snackbar is shown.

### TC-RETEST-MP-01: Map render stability
- **Preconditions:** Map key configured; map-enabled screens accessible.
- **Steps:**
  1. Open SOS map screens and provider/customer map surfaces.
  2. Refresh the page and repeat.
  3. Temporarily simulate key/load issues if possible.
- **Expected Result:** Map renders or explicit fallback view appears (never silent blank rectangle).

### TC-RETEST-MP-02: Route launch from map actions
- **Preconditions:** Valid lat/lng on SOS/map-enabled item.
- **Steps:**
  1. Tap route/open-in-maps action from each relevant screen.
  2. Repeat on web and Android.
- **Expected Result:** Route opens in external map/browser; failures produce clear user-facing feedback.

### TC-RETEST-RS-01: Realtime recovery on flaky network
- **Preconditions:** User signed in; open SOS/messages/notifications pages.
- **Steps:**
  1. Start with stable connection and confirm data loads.
  2. Simulate intermittent DNS/network drops.
  3. Observe data streams during outage and after recovery.
- **Expected Result:** Realtime errors do not crash the page; polling fallback keeps data available and recovers automatically.

### TC-RETEST-MKP-06: Payment validation trigger timing
- **Preconditions:** Open secure payment dialog from a listing/cart flow.
- **Steps:**
  1. Open payment form and do not type.
  2. Confirm no immediate validation errors are shown.
  3. Tap submit with empty fields.
  4. Correct fields incrementally and re-submit.
- **Expected Result:** Errors appear only after submit/user interaction; valid input allows confirmation path.

### TC-RETEST-CD-03: Add Vehicle save reliability
- **Preconditions:** Authenticated customer on Garage.
- **Steps:**
  1. Open `Add Vehicle`.
  2. Fill required fields (make/model/plate/year) and save.
  3. Repeat with optional fields omitted.
  4. Verify list refresh.
- **Expected Result:** Vehicle saves successfully, appears in garage immediately, and invalid required input is blocked with clear messages.

