# BoostDrive Troubleshooting

## Flutter Web: `TypeError: null is not a subtype of type 'String'` (Find a Provider)

**Symptom:** Red error overlay on Find a Provider: `TypeError: null: type 'Null' is not a subtype of type 'String'`.

**Cause:** Profile data from the API can have `null` for some fields (e.g. before DB columns like `service_area_description` / `working_hours` exist, or legacy rows). The app expected non-null strings.

**What we did:** `UserProfile.fromMap` now coerces every string field with a safe `_str()` helper so null or non-string values become `''`. No UI should receive null for a required `String`.

**If it still appears:** Run the DB migration in `docs/supabase_profiles_provider_location_hours.sql` so provider rows include the new columns. Do a full restart (`flutter run -d chrome`) after code changes.

---

## Flutter Web: `removeChild` / "Bad state: Not connected to an application"

**Symptom:** Console shows `Cannot read properties of null (reading 'removeChild')` at `main.dart.js` or `Error: Bad state: Not connected to an application` from `DevHandler` / `client.js`.

**Cause:** These come from the **Dart DevTools / debug extension** (Chrome extension or DWDS), not from your app code. They typically occur when the debug connection drops (e.g. hot restart, network blip, or the app tab is closed) and the extension tries to update the DOM.

**What you can do:**
- Ignore them if the app itself runs fine.
- Disable the Dart DevTools extension temporarily, or run without debugging: `flutter run -d chrome --no-enable-dwds` (or run a release build).
- Reload the app tab and reconnect DevTools if you need to debug.

---

## Flutter Web: `mouse_tracker.dart` assertion (`_debugDuringDeviceUpdate`)

**Symptom:** Console shows repeated:
```text
Assertion failed: file:///.../flutter/.../mouse_tracker.dart:199:12
!_debugDuringDeviceUpdate is not true
```

**Cause:** Known Flutter web issue where the mouse tracker can get into an inconsistent state during pointer/layout updates, especially after hot reload or when using certain widgets (dropdowns, overlays, segmented controls).

**What we did in the app:**
- On the **Find a Provider** page, replaced all widgets that use Flutter’s mouse/hover tracking with simple tap-only widgets:
  - **SegmentedButton** → custom `_ListMapToggle` and `_ToggleSegment` (GestureDetector + Container).
  - **DropdownButton** (Sort by) → `_SortChip` (GestureDetector + Container).
  - **FilterChip** (category/quick links) → custom chips using **GestureDetector** + Container.
  - **InkWell** → **GestureDetector** (cards, quick links, list/map segments).
  - **IconButton** → **GestureDetector** + Icon (call button, app bar back).
  - **Tooltip** → removed (they use hover).
  - **OutlinedButton** / **ElevatedButton** (detail page) → **GestureDetector** + Container.
- Wrapped the Find a Provider page body in **RepaintBoundary** to isolate repaints.

**What you should do:**
1. **Full restart** (do not rely on hot reload): stop the app (`Ctrl+C`), then run again:
   ```bash
   flutter run -d chrome
   ```
2. If it still happens only when opening Find a Provider, close that tab and reopen the app, or navigate away and back after a full restart.
3. Ensure you're on a recent Flutter stable channel; this has been improved in newer SDK versions.

---

## WebSocket / `ERR_NAME_NOT_RESOLVED` / `ERR_INTERNET_DISCONNECTED`

**Symptom:** Console shows many `WebSocket connection to 'wss://...supabase.co/...' failed`, `net::ERR_NAME_NOT_RESOLVED`, or `ERR_INTERNET_DISCONNECTED`, and possibly `AuthRetryableFetchException`.

**Cause:** The browser cannot reach the Supabase backend (no internet, VPN, firewall, or wrong Supabase URL). This is a **network/environment** issue, not an app bug.

**What you can do:** Check your internet connection, VPN, and that `jpkkielcwlssmictmjrl.supabase.co` (or your project URL) is correct in your Supabase config. The app will show errors or empty data until the backend is reachable.
