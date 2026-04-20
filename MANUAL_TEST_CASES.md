BoostDrive Manual Test Cases
============================

Plain text format for printing, copy-paste, or spreadsheets.

SCOPE
-----
Executable manual test cases for BoostDrive: mobile app, web app, and shared Supabase backend (notifications, roles, edge functions where applicable).

Each case uses:
  ID
  Module
  Preconditions
  Steps
  Expected Result


TEST ENVIRONMENT
----------------
Build targets: Android, iOS, Web (Chrome)
Backend: Supabase (staging or prod-like test project)

Core test accounts (example names):
  admin_01
  customer_01
  seller_01
  service_pro_01
  service_pro_02
  logistics_01

Seed data needed:
  Approved providers with services and inventory
  At least 5 marketplace products
  At least 3 SOS requests across statuses
  At least 2 delivery orders
  At least 2 job cards


SECTION A — AUTHENTICATION AND ACCOUNT LIFECYCLE
------------------------------------------------

TC-AUTH-001  User registration (customer)
  Preconditions: Email not already used.
  Steps: Open app. Sign up as customer. Submit valid data.
  Expected Result: Account created. User redirected to dashboard. Profile row created.

TC-AUTH-002  User registration (provider role)
  Preconditions: Clean email and valid provider details.
  Steps: Sign up as provider (mechanic, towing, or logistics).
  Expected Result: Account created with provider role. Provider profile fields persisted.

TC-AUTH-003  Login with valid credentials
  Preconditions: Existing user.
  Steps: Enter valid email and password. Login.
  Expected Result: Successful login. Session persisted. Correct role dashboard loads.

TC-AUTH-004  Login with invalid password
  Preconditions: Existing user.
  Steps: Enter wrong password. Login.
  Expected Result: Login blocked with clear error message.

TC-AUTH-005  Forgot password flow
  Preconditions: Existing email.
  Steps: Trigger reset password. Complete reset link flow. Login with new password.
  Expected Result: Password updated. Old password rejected.

TC-AUTH-006  Session persistence after app restart
  Preconditions: Logged-in user.
  Steps: Close app or browser tab. Reopen.
  Expected Result: User remains authenticated until explicit logout.

TC-AUTH-007  Logout flow
  Preconditions: Logged-in user.
  Steps: Tap logout.
  Expected Result: Session cleared. Redirected to auth screen.


SECTION B — ROLE ROUTING AND ACCESS CONTROL
---------------------------------------------

TC-RBAC-001  Admin-only routes
  Preconditions: Logged in as non-admin.
  Steps: Attempt to open admin dashboard route directly.
  Expected Result: Access denied or redirect. No admin data exposed.

TC-RBAC-002  Provider-only management routes
  Preconditions: Logged in as customer or seller.
  Steps: Try opening provider service management pages.
  Expected Result: Read-only or blocked. No write access.

TC-RBAC-003  Customer read-only service marketplace
  Preconditions: Provider has services.
  Steps: Open services marketplace as customer.
  Expected Result: Services visible. Edit, delete, toggle not visible.

TC-RBAC-004  Provider CRUD on own services only
  Preconditions: Provider A and Provider B exist.
  Steps: Provider A tries to edit or delete Provider B service (UI or forced request).
  Expected Result: Operation blocked by policy. Only owner-managed rows writable.


SECTION C — MARKETPLACE LISTINGS (CARS, PARTS, RENTALS)
-------------------------------------------------------

TC-LIST-001  Create listing (seller)
  Preconditions: Seller account active.
  Steps: Add listing with valid required fields and image.
  Expected Result: Listing created. Appears in marketplace feed.

TC-LIST-002  Edit listing
  Preconditions: Existing seller listing.
  Steps: Edit title, price, description. Save.
  Expected Result: Updated values visible on listing and details page.

TC-LIST-003  Delete listing
  Preconditions: Existing seller listing.
  Steps: Delete listing and confirm.
  Expected Result: Listing removed from seller dashboard and marketplace.

TC-LIST-004  Listing validation
  Preconditions: Seller create form open.
  Steps: Submit with missing required fields.
  Expected Result: Validation errors shown. Listing not created.

TC-LIST-005  Filter and search listings
  Preconditions: Multiple categories listed.
  Steps: Use search text and category filters.
  Expected Result: Results update accurately and quickly.


SECTION D — CART AND CHECKOUT
-----------------------------

TC-CART-001  Add item to cart
  Preconditions: Product exists.
  Steps: Add from product card or details.
  Expected Result: Cart count and total update correctly.

TC-CART-002  Remove item from cart
  Preconditions: Cart has at least one item.
  Steps: Remove via delete action.
  Expected Result: Item removed. Total recalculated.

TC-CART-003  Recommended parts push acceptance
  Preconditions: Provider has pushed job-card parts to customer.
  Steps: Open cart. Accept push.
  Expected Result: Pushed parts added with correct quantity and price.

TC-CART-004  Recommended parts push rejection
  Preconditions: Pending push exists.
  Steps: Dismiss push.
  Expected Result: Push status rejected. No cart changes.

TC-CART-005  Message seller directly from checkout
  Preconditions: Cart has items. User logged in.
  Steps: Checkout. Choose Message Seller Directly.
  Expected Result: Seller conversation opens (or seller selector appears for multi-seller carts). Prefilled cart summary message is sent.

TC-CART-006  Online payments coming soon placeholder
  Preconditions: Cart has items.
  Steps: Checkout. Choose Online Payments (Coming Soon).
  Expected Result: Coming-soon message shown. No payment transaction starts.


SECTION E — PROVIDER SERVICES, INVENTORY, KITS, EQUIPMENT
---------------------------------------------------------

TC-PROV-001  Create provider service
  Preconditions: Provider account approved.
  Steps: Add service with category, price, duration.
  Expected Result: Service saved. Visible in provider list and customer marketplace view.

TC-PROV-002  Edit provider service
  Preconditions: Existing provider service.
  Steps: Update values. Save.
  Expected Result: Changes persist. Dashboard cards refresh.

TC-PROV-003  Delete provider service
  Preconditions: Existing provider service.
  Steps: Delete and confirm.
  Expected Result: Service removed. No stale UI row.

TC-PROV-004  Toggle provider online or offline
  Preconditions: Provider logged in.
  Steps: Toggle availability.
  Expected Result: State updates immediately without hot refresh.

TC-PROV-005  Add inventory item
  Preconditions: Provider account.
  Steps: Add inventory part with stock quantity.
  Expected Result: Item appears in inventory list. Saved in database.

TC-PROV-006  Edit inventory quantity
  Preconditions: Inventory item exists.
  Steps: Adjust stock quantity.
  Expected Result: Quantity persisted and displayed correctly.

TC-PROV-007  Add service kit
  Preconditions: Provider has inventory parts.
  Steps: Create service kit with part composition.
  Expected Result: Kit saved. Retrievable in provider UI.

TC-PROV-008  Equipment status update
  Preconditions: Equipment rows exist.
  Steps: Update equipment status field.
  Expected Result: New status shown in list and available for filters.


SECTION F — JOB CARD AND DIAGNOSTICS WORKFLOW
----------------------------------------------

TC-JC-001  Customer creates job card request
  Preconditions: Customer account.
  Steps: Open customer job card tool. Submit request.
  Expected Result: Status submitted or pending provider quote. Visible to providers.

TC-JC-002  Job card appears to all providers
  Preconditions: New unassigned job card exists.
  Steps: Log in as Provider A and Provider B.
  Expected Result: Both see incoming request in list.

TC-JC-003  Atomic quote claim (race)
  Preconditions: Same new job card. Two providers online.
  Steps: Provider A and B attempt quote at nearly the same time.
  Expected Result: Only one quote succeeds. Second provider blocked with clear message.

TC-JC-004  Provider submits labor quote
  Preconditions: Provider owns claim.
  Steps: Respond with price.
  Expected Result: Status quoted or awaiting client response. Requester notified.

TC-JC-005  Customer accepts quote
  Preconditions: Quoted job card.
  Steps: Customer taps accept.
  Expected Result: Status accepted. Provider sees execution flow.

TC-JC-006  Customer declines quote
  Preconditions: Quoted job card.
  Steps: Customer taps decline.
  Expected Result: Status declined. Provider receives decision notification.

TC-JC-007  Cancel job card request with confirmation
  Preconditions: Request still cancelable.
  Steps: Tap cancel. Confirm in dialog.
  Expected Result: Request canceled. Reflected for both parties.

TC-JC-008  Required parts only after acceptance (provider side)
  Preconditions: Quote accepted.
  Steps: Provider opens card details.
  Expected Result: Required-parts controls shown only to provider, not requester.

TC-JC-009  Push required parts to customer cart
  Preconditions: Accepted job card with parts.
  Steps: Provider pushes parts.
  Expected Result: Customer receives actionable cart recommendation.

TC-JC-010  Provider execution statuses
  Preconditions: Accepted job card.
  Steps: Provider sets active, in-progress, completed as applicable.
  Expected Result: Valid transitions. Requester notified at each step.

TC-JC-011  Completion effects
  Preconditions: Job card completed with labor and parts.
  Steps: Mark completed.
  Expected Result: Invoice row generated if schema supports. Provider earnings updated. Inventory deducted where wired.

TC-JC-012  Review prompt after completion
  Preconditions: Completed provider task.
  Steps: Customer opens dashboard or emergency hub.
  Expected Result: Pending review prompt for that provider and task.


SECTION G — SOS EMERGENCY FLOW
------------------------------

TC-SOS-001  Create SOS request with location
  Preconditions: Customer with location permissions.
  Steps: Trigger SOS request.
  Expected Result: SOS row created with coordinates and pending status.

TC-SOS-002  Provider sees pending SOS
  Preconditions: Pending SOS exists.
  Steps: Open provider SOS tab.
  Expected Result: Request visible in provider queue.

TC-SOS-003  Provider accepts SOS
  Preconditions: Pending SOS.
  Steps: Accept request.
  Expected Result: Assigned to provider. Status updated. Requester notified.

TC-SOS-004  Provider location tracking update
  Preconditions: Assigned SOS.
  Steps: Provider tracking update occurs (app flow).
  Expected Result: provider_last_lat, provider_last_lng, ETA update where implemented.

TC-SOS-005  Provider completes SOS
  Preconditions: Assigned or active SOS.
  Steps: Mark complete with required location validation if any.
  Expected Result: Status completed or resolved. Completion notification sent.

TC-SOS-006  Failed-fetch resilience on web
  Preconditions: Simulated transient network interruption.
  Steps: Keep provider orders page open during interruption.
  Expected Result: Polling or stream recovers gracefully.


SECTION H — DELIVERY / BaTLorriH LOGISTICS
------------------------------------------

TC-DEL-001  Pending delivery appears in queue
  Preconditions: Delivery order status pending.
  Steps: Open logistics dashboard.
  Expected Result: Order appears in pickup queue.

TC-DEL-002  Assign-to-me action
  Preconditions: Pending order.
  Steps: Logistics user taps assign.
  Expected Result: Driver assigned. Status moves to picking_up.

TC-DEL-003  Start transit progression
  Preconditions: Assigned order status picking_up.
  Steps: Tap Start transit.
  Expected Result: Status in_transit.

TC-DEL-004  Mark delivered progression
  Preconditions: Order in transit.
  Steps: Tap Mark delivered.
  Expected Result: Status delivered. Appears in history where implemented.

TC-DEL-005  Driver live marker priority
  Preconditions: Driver telemetry exists.
  Steps: Open map on logistics view.
  Expected Result: Marker uses driver live coordinates when present.


SECTION I — NOTIFICATIONS AND DEEP LINKING
------------------------------------------

TC-NOTIF-001  Job card quote notification to requester
  Preconditions: Provider submits quote.
  Steps: Open requester notifications. Tap item.
  Expected Result: Opens Job Card tool with correct card focus.

TC-NOTIF-002  Job card status update notification
  Preconditions: Provider changes execution status.
  Steps: Requester taps status notification.
  Expected Result: Correct job card opens with latest status.

TC-NOTIF-003  Notification metadata routing
  Preconditions: Notification has metadata job_card_id or sos_request_id.
  Steps: Tap notification.
  Expected Result: Routes using metadata IDs reliably.

TC-NOTIF-004  Mark-as-read behavior
  Preconditions: Unread notifications exist.
  Steps: Open and tap one notification.
  Expected Result: Marked read. Unread badge decrements.

TC-NOTIF-005  Bidirectional communication visibility
  Preconditions: Customer and provider exchange job-card decisions.
  Steps: Check both users notifications.
  Expected Result: Both parties see corresponding updates.


SECTION J — MESSAGING AND SUPPORT
--------------------------------

TC-MSG-001  Start new conversation
  Preconditions: Two users with valid IDs.
  Steps: Open provider profile. Send first message.
  Expected Result: Conversation created. Message visible to both.

TC-MSG-002  Send text, image, voice message
  Preconditions: Existing conversation.
  Steps: Send each supported message type.
  Expected Result: Delivery and rendering correct across clients.

TC-MSG-003  Unread badge updates
  Preconditions: Recipient has unread messages.
  Steps: Open notifications or messages list.
  Expected Result: Unread count appears and clears when viewed.

TC-SUP-001  Create support ticket
  Preconditions: Logged-in user.
  Steps: Submit support request.
  Expected Result: Ticket created. Visible in support center or admin queue.

TC-SUP-002  Admin responds to support ticket
  Preconditions: Open ticket exists.
  Steps: Admin posts response.
  Expected Result: User notified. User can view reply.


SECTION K — ADMIN DASHBOARDS AND FINANCIAL SIGNALS
--------------------------------------------------

TC-ADM-001  Active SOS KPI dynamic
  Preconditions: SOS rows with operational active statuses (pending, assigned, accepted, active per product definition).
  Steps: Open admin dashboard.
  Expected Result: KPI matches live operational count.

TC-ADM-002  SOS operational map render
  Preconditions: Active SOS rows with valid coordinates.
  Steps: Open operational overview map.
  Expected Result: Map visible. Marker count matches plotted rows with coordinates.

TC-ADM-003  Service Revenue Breakdown dynamic
  Preconditions: provider_services rows with category and price.
  Steps: Open financials view.
  Expected Result: Category totals and percentages reflect live aggregates.

TC-ADM-004  Dynamic commission and opex config
  Preconditions: platform_financial_settings row exists if migrated.
  Steps: Change commission_rate or operating_cost. Reload financials.
  Expected Result: KPI and net revenue reflect DB config.

TC-ADM-005  Pending verification KPI
  Preconditions: Pending verification users exist.
  Steps: Open dashboard.
  Expected Result: Count matches pending queue size.


SECTION L — SECURITY, DATA INTEGRITY, POLICIES
----------------------------------------------

TC-SEC-001  RLS blocks unauthorized write
  Preconditions: Customer session token.
  Steps: Attempt provider_services insert or update via client as customer.
  Expected Result: Supabase rejects operation.

TC-SEC-002  Provider manages only own service rows
  Preconditions: Provider A and B rows.
  Steps: Provider A updates Provider B row.
  Expected Result: Operation rejected.

TC-SEC-003  Notification write policy
  Preconditions: Regular user.
  Steps: Attempt insert notification for unrelated recipient.
  Expected Result: Rejected unless policy explicitly allows system path.

TC-SEC-004  No secret leakage in repo
  Preconditions: Working tree has changes.
  Steps: Inspect files before commit.
  Expected Result: No .env or credential files committed.


SECTION M — PERFORMANCE AND RELIABILITY
---------------------------------------

TC-PERF-001  Dashboard load under normal data size
  Preconditions: Large representative dataset (for example 1000+ rows across core tables).
  Steps: Open key dashboards.
  Expected Result: Acceptable first paint and interactivity on test environment (team defines target, e.g. under 3 seconds).

TC-PERF-002  Stream update responsiveness
  Preconditions: Live streams active.
  Steps: Change SOS status. Observe UI.
  Expected Result: UI updates near real-time without manual refresh.

TC-PERF-003  Retry resilience during intermittent network
  Preconditions: Short disconnect simulated.
  Steps: Keep provider or admin pages open.
  Expected Result: Streams or polling recover and data re-syncs.


SECTION N — REGRESSION SMOKE SUITE (RELEASE GATE)
-------------------------------------------------

TC-SMOKE-001  Auth login and logout — Expected: Pass
TC-SMOKE-002  Create, edit, delete listing — Expected: Pass
TC-SMOKE-003  Add to cart and manual checkout — Expected: Pass
TC-SMOKE-004  Customer job card, provider quote, customer accept — Expected: Pass
TC-SMOKE-005  Provider completes job card, review prompt appears — Expected: Pass
TC-SMOKE-006  SOS create, accept, complete — Expected: Pass
TC-SMOKE-007  Logistics assign, in_transit, delivered — Expected: Pass
TC-SMOKE-008  Notification deep-link opens correct target — Expected: Pass
TC-SMOKE-009  Admin SOS KPI and map update from live data — Expected: Pass
TC-SMOKE-010  Admin financials dynamic breakdown loads — Expected: Pass


EXECUTION MATRIX (SUGGESTED)
----------------------------
Run suites on: Web Chrome, Android, iOS.
Run Smoke Suite on every candidate build.
Run full manual suite before milestone, demo, or release.


TRACEABILITY
------------
For each executed case record:
  Build number
  Tester name
  Date and time
  Environment (staging or production clone)
  Evidence (screenshot, video, or log excerpt)
  Pass / Fail / Blocked and defect ID if failed


TARGETED QA RETEST MATRIX (18 APRIL FAILED CASES)
-------------------------------------------------
Use this compact rerun list for failed IDs from the 18 April QA report.

TC-RETEST-SO-02  SOS waiting status and context visibility
  Preconditions: Customer logged in, one active SOS exists.
  Steps:
    1) Open Emergency SOS.
    2) Confirm active SOS card is visible.
    3) Verify status chip and context line (time + coordinates).
    4) Verify waiting map or fallback panel is visible (not blank).
  Expected Result: Status/context always readable; no blank waiting screen.

TC-RETEST-SO-08  SOS navigate action launches maps
  Preconditions: Active SOS with valid coordinates.
  Steps:
    1) Open active SOS card.
    2) Tap navigate/open-map action.
    3) If blocked by device/browser, check user feedback.
  Expected Result: External map opens via URI fallback; if blocked, clear snackbar appears.

TC-RETEST-MP-01  Map render stability
  Preconditions: Map key configured; map-enabled screens available.
  Steps:
    1) Open SOS and other map-enabled screens.
    2) Refresh and repeat.
    3) Simulate key/load issue if possible.
  Expected Result: Map renders or explicit fallback panel appears (never silent blank block).

TC-RETEST-MP-02  Route launch from map actions
  Preconditions: Valid latitude/longitude exists on SOS/map item.
  Steps:
    1) Tap route/open-in-maps action from each relevant screen.
    2) Repeat on web and Android.
  Expected Result: Route opens in external map/browser; failure shows clear feedback.

TC-RETEST-RS-01  Realtime recovery on flaky network
  Preconditions: User signed in; SOS/messages/notifications pages open.
  Steps:
    1) Start on stable network and confirm data loads.
    2) Simulate intermittent DNS/network drops.
    3) Observe behavior during outage and after recovery.
  Expected Result: No crash; polling fallback keeps data usable and auto-recovers.

TC-RETEST-MKP-06  Payment validation trigger timing
  Preconditions: Open secure payment dialog from listing/cart flow.
  Steps:
    1) Open form and do not type.
    2) Confirm no validation errors on initial render.
    3) Tap submit with empty fields.
    4) Correct fields incrementally and re-submit.
  Expected Result: Errors appear only after submit/interaction; valid input proceeds.

TC-RETEST-CD-03  Add Vehicle save reliability
  Preconditions: Authenticated customer on Garage.
  Steps:
    1) Open Add Vehicle.
    2) Fill required fields (make/model/plate/year) and save.
    3) Repeat with optional fields omitted.
    4) Confirm list refresh.
  Expected Result: Vehicle saves and appears immediately; invalid required fields are blocked with clear messages.

End of document.
