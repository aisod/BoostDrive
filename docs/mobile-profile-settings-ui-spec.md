# Mobile Profile Settings — UI Inventory for Stitch

**Purpose:** Complete inventory of every UI element, component, and feature on the mobile **Profile Settings** screen for Stitch (with Google) to redesign visuals in **light and dark mode** without changing behavior.

**Platform:** Flutter mobile (`apps/Mobile` shell) + shared UI (`packages/boostdrive_ui`).

**Primary file:** `packages/boostdrive_ui/lib/src/profile_settings_page.dart` (~5,000 lines).

**Supporting UI:** `packages/boostdrive_ui/lib/src/provider_profile_ui.dart`, `dashboard_palette.dart`, `dashboard_typography.dart`, `dashboard_ui_components.dart` (`DashboardCard`, `DashboardPageContainer`).

---

## Architecture

The same `ProfileSettingsPage` widget renders **three distinct experiences** based on `UserProfile.role`:

| Role / mode | Mobile entry | Layout |
|-------------|--------------|--------|
| **Customer / casual seller** | `MainShell` tab **PROFILE** (index 5) | Customer scaffold + scrollable sections |
| **Service provider** (mechanic, towing, etc.) | Provider shell tab **Account** (index 4) | Hero banner + provider sections OR edit stepper |
| **Admin** | Rare on mobile; same page if role `admin` | Admin banner + two-column cards (wide) |

**Optional route param:** `initialProviderEditMode: true` — opens provider **edit-only** flow (stepper); back / Exit Edit Mode pops route. Used when navigating from “Edit Profile” pill.

**Data:** `userProfileProvider(userId)` → `UserProfile`; saves via `userServiceProvider.updateProfile`, `authServiceProvider` (photo, password, email).

---

## Shell context — Bottom navigation

### Customer (`MainShell`)

| Index | Label | Icon |
|-------|-------|------|
| 5 | **PROFILE** | `person_outline` / `person` (active orange) |

Other tabs: HOME, SOS, GARAGE, SHOP, PROVIDERS.

### Provider (`MainShell` provider mode)

| Index | Label | Icon |
|-------|-------|------|
| 4 | **Account** | `settings_outlined` / `settings` |

---

## Design tokens (current → Kinetic target)

| Token | Light | Dark |
|-------|-------|------|
| Page background | `#F9F9F9` (`DashboardPalette.background`) | `#09151B` |
| Nav / app bar | `#A43700` / `#CD4700` (`navBar` / `primaryContainer`) | `#F95E14` |
| Card surface | White (`surfaceContainerLowest`) | `#121D24` / elevated surfaces |
| Section label | Montserrat caps, peach/brown (`sectionLabel`) | `onSurfaceVariant` |
| Primary accent | Orange `#FF6600` / `#CD4700` | `#F95E14` |
| Error / SOS | Red (`palette.error`) | Same |
| Typography | Manrope body; Montserrat labels | Same |

**Note:** Many customer tiles still use hardcoded `#000000` text; provider flows use `DashboardPalette` more consistently. Redesign should unify with **Kinetic Precision**.

---

# Part A — Customer / general user Profile Settings

**When:** `profile.role` is not a provider role and not `admin`.

**Scaffold:** `backgroundColor: DashboardPalette.background`

### A.1 App bar

| Zone | Element | Details |
|------|---------|---------|
| Background | `palette.navBar` | Orange, elevation 4 |
| Leading | **Back** | `Icons.arrow_back_ios_new`, white, 20px → `Navigator.pop` |
| Title | **Profile Settings** | Montserrat w700, 18px, white, left-aligned |
| Actions | **Theme toggle** | `DashboardThemeToggle` compact, colored header |
| | **Notifications** | `Icons.notifications_outlined` — `onPressed: () {}` (placeholder) |
| | **Help** | `Icons.help_outline` — `onPressed: () {}` (placeholder) |
| | **Save check** (edit mode) | `Icons.check` white → `_handleSaveProfile` when `_isEditing` |

### A.2 Body layout

| Property | Value |
|----------|--------|
| Scroll | `SingleChildScrollView` |
| Width constraint | `DashboardPageContainer` max 960px |
| Top spacing | 16px after app bar |

---

### A.3 Profile summary card (`_buildProfileHeader`)

**Wrapper:** `DashboardCard`, padding 32px.

| Element | Details |
|---------|---------|
| **Avatar** | 110×110 circle, `primaryFixed` border 4px, shadow |
| Tap avatar | Opens **Profile Photo** bottom sheet |
| Upload overlay | Dark scrim + `CircularProgressIndicator` when `_isUploading` |
| **Camera FAB** | Bottom-right on avatar, orange circle, `Icons.camera_alt` white |
| **Display name** | Montserrat 28px w700; fallback **Set Name** |
| **Subtitle** | **BoostDrive Customer since {year}** or **BoostDrive Seller since {year}** if `isSeller` |
| Provider-as-customer variant | Role uppercase + “Professional Partner”, star row “— (— reviews)” (placeholder) |

---

### A.4 Personal Information card (`_buildPersonalInformation`)

**Wrapper:** `DashboardCard`, elevated, padding 24px.

| Element | Details |
|---------|---------|
| **Section header** | **PERSONAL INFORMATION** — `DashboardTypography.sectionLabel` |
| **Edit toggle** | IconButton `edit` / `close` orange — toggles `_isEditing` |
| **Inner container** | Rounded 16px, `surfaceContainerLow`, bordered |

#### Info rows (`_buildInfoTile`)

Each row: white icon box (10px pad) + orange icon + label + value/field.

| Row | Icon | Label | Field |
|-----|------|-------|-------|
| 1 | `person_outline` | **Full Name** | `_nameController` |
| 2 | `email_outlined` | **Email Address** | `_emailController` |
| — | Subheader | **CONTACT DETAILS** | `contact_phone_outlined` + caps label |
| 3 | `phone_android_outlined` | **Personal Contact Number** | `_phoneController` |

**View mode:** Shows text or **Not set**.  
**Edit mode:** Inline `TextField` borderless.  
**Editable chevron:** `arrow_forward_ios` peach when editable (unused on last row).

#### Edit mode footer (when `_isEditing`)

| Button | Style | Action |
|--------|-------|--------|
| **Cancel** | Outlined, peach border | Discards edit, invalidates profile |
| **Save Changes** | Orange filled | `_handleSaveProfile` + loading spinner |

**Save behavior:** Updates name, phone, emergency contacts; email change may trigger verification dialog.

---

### A.5 Safety & SOS panel (`_buildSafetySection`) — mobile only (`!kIsWeb`)

**Wrapper:** `ProviderProfileUi.safetyPanel` (accent styling).

| Element | Details |
|---------|---------|
| **SOS badge** | Red-tint box, **SOS** label bold |
| **Title** | **Emergency contacts** |
| **Description** | Notifications sent on breakdown/collision |
| **Contact summary card** | Tappable → `_showEmergencyContactsEditor` |
| Empty copy | *No contacts saved. Tap Manage to add…* |
| Filled copy | Numbered list (up to 4) name + phone; **+ N more** |
| **Manage** | Red/orange link text on right |

---

### A.6 Hub & operations (`_buildControlCenterSection`)

**Wrapper:** `ProviderProfileUi.controlCenterShell` + `ExpansionTile`.

| Element | Details |
|---------|---------|
| **Collapsed title** | **Hub & operations** (orange label style) |
| **Subtitle** | **Emergency contacts.** (customers) or **Staff, payouts.** (service shops) |
| **Expand icon** | Orange chevron |

#### Expanded children (customer)

| ListTile | Icon | Title | Subtitle | Tap |
|----------|------|-------|----------|-----|
| 1 | `contact_phone_outlined` | Emergency contacts | Dynamic summary from saved contacts | Opens same editor as Safety panel |

#### Expanded children (registered service shop only)

| ListTile | Tap behavior |
|----------|----------------|
| Staff & roles | Snackbar: coming soon |
| Payouts | Snackbar: points to Financial & Payout section |

---

### A.7 Account actions (`_buildAccountActions`)

| Button | Style | Action |
|--------|-------|--------|
| **Log Out** | Outlined orange border | Confirm dialog → `signOut` |
| **Delete Account** | Text button red | Confirm dialog → delete profile |

Responsive: row on wide, column on narrow.

---

### A.8 Footer

| Text | Value |
|------|--------|
| Version | **BoostDrive Version 2.4.1 (1209)** — Manrope 11px |

---

# Part B — Overlays & dialogs (customer)

### B.1 Profile Photo bottom sheet

| Element | Details |
|---------|---------|
| Handle | 40×4 drag pill |
| Title | **Profile Photo** |
| Option 1 | **Choose Photo** — gallery → crop (mobile) → upload |
| Option 2 | **No Profile Photo** — show initials |
| Option 3 | **Delete Photo** — destructive red icon |

### B.2 Emergency contacts bottom sheet (`_EmergencyContactsSheet`)

| Element | Details |
|---------|---------|
| Height | Up to 78% screen |
| Title | **Emergency contacts** orange |
| Description | SOS reference copy |
| **Per contact block** | **Contact N** header, delete if >1 |
| Fields | **Name**, **Phone** outlined |
| **Add another contact** | Outlined button |
| Footer | **Save** (primary) / dismiss |

Post-save: success or “Partially saved” migration dialog.

### B.3 Log out / Delete account dialogs

Dark-surface `AlertDialog` with Cancel + confirm (red for delete/log out).

### B.4 Email change confirm

When email edited on save: dialog **Confirm Email Change** → Supabase verification email.

---

# Part C — Service provider Profile Settings

**When:** `_isProviderRole(profile.role)` is true.

**Scaffold:** `extendBodyBehindAppBar: true`, transparent app bar over hero.

### C.1 Provider app bar (`ProviderProfileUi.providerAppBar`)

| Element | Details |
|---------|---------|
| Background | Transparent over gradient hero |
| Leading | Back `arrow_back_ios_new` white |
| Title | **Provider Profile** or **Edit Profile Settings** |
| Actions | Theme toggle; **Edit Profile** pill (white) OR **Exit Edit Mode** text |

**Edit Profile** navigates to `ProfileSettingsPage(initialProviderEditMode: true)`.

---

### C.2 Hero banner (`_buildProviderBanner`)

| Element | Details |
|---------|---------|
| Height | 180px + status bar + toolbar |
| Background | Orange gradient (`ProviderProfileUi.heroBannerDecoration`) |
| **Avatar** | 104px diameter, white border 4px, overlaps below banner |
| Camera FAB | When edit mode / edit-only page |
| Hint | **Tap photo to change** under avatar (edit only) |

### C.3 Identity block (below banner)

| Element | Details |
|---------|---------|
| **Business display name** | `profile.displayName` Manrope 28px w800 |
| **Verified chip** | If `verificationStatus` approved: **Verified {Mechanic/Towing/…}** |

---

### C.4 View mode sections (mobile, narrow)

Stacked `ProviderProfileUi.sectionCard` blocks (icon + UPPERCASE title + content):

| # | Section title | Icon | Key fields / features |
|---|---------------|------|------------------------|
| 1 | **Business Information** | `business_center` | Registered name, trading name, business phones (multi), business type dropdown (CC / Pty Ltd / Sole Prop), registration #, years, primary category |
| 2 | **Safety & SOS** | `emergency` (accent) | Same as customer safety panel (`!kIsWeb`) |
| 3 | **Service Area & Hours** | `location_on` | Service area text, working hours, 24/7 toggle |
| 4 | **Services You Provide** | `build_circle` | Multi-select chips: mechanic, towing, parts, rental (`!kIsWeb`) |
| 5 | **Operational & Business Details** | `business_center` | 24/7 switch, service radius km, workshop address, Facebook, Instagram, website |
| 6 | **Service Specializations** | `build_circle` | Brand expertise chips, service tag chips, towing capability chips; custom “other” chips |
| 7 | **Financial & Payout** | `account_balance_wallet` (accent) | Bank name, branch, account #, labor rate N$, VAT number |
| 8 | **Trust & Experience** | `verified_user` | Business bio textarea, gallery grid (1–10 photos), team size |
| 9 | **Documents Vault** | `folder` (`!kIsWeb`) | Legal doc slots 0–6 (+ towing slot 4), upload PDF/Office, progress badge |
| 10 | **Control Center** | `hub` | Expansion tile (emergency / staff / payouts) |
| — | **Account actions** | | Log out, delete account |
| Footer | | Version + **AUTHORIZED PROVIDER INSTANCE** |

**Wide bento layout (`width > 900`):** Two-column grid combining business info, specializations read-only, trust, documents.

---

### C.5 Edit mode — 2-step stepper (`_buildProviderStepperContent`)

**Stepper titles:**  
1. **Business Profile**  
2. **Legal Docs & Certs**

| UI | Details |
|----|---------|
| Step indicators | Numbered circles, connectors, check when done |
| Step 0 content | Business Information, Trust & Experience, Service Specializations, Operational details, Service area, Financial payout |
| Step 1 content | Documents Vault uploads |
| **Next** | Validates step, advances |
| **Save Profile** | Last step → save + exit edit |
| **Back** | Previous step |
| **Cancel** | Revert / pop |
| **Save Changes** | Save from any step without finishing stepper |

---

### C.6 Documents Vault (detail)

| Slot | Document type |
|------|----------------|
| 0 | BIPA or CC1 business registration |
| 1 | Certified copy of owner ID |
| 2 | Municipal fitness certificate |
| 3 | NTA trade certificate |
| 4 | Road Carrier Permit (towing only) |
| 5 | NamRA tax certificate |
| 6 | Social Security good standing |

Each row: status text (Pending / Submitted), upload button, max 10 MB, extensions pdf/doc/xlsx/etc.

**Gallery photos** use slots 7–16 in same `galleryUrls` array (separate from legal slots).

---

### C.7 Provider field patterns

| Pattern | Details |
|---------|---------|
| Labels | `_providerLabel` / `ProviderProfileUi.fieldLabel` |
| Inputs | 8px radius, bordered; read-only gray fill when not editing |
| Multi-select chips | Toggle brand/service/towing tags; add custom via dialogs |
| Primary buttons | `ProviderProfileUi.primaryButtonStyle` orange |

---

# Part D — Admin Profile Settings

**When:** `profile.role == 'admin'`.

### D.1 Admin banner (`_buildAdminBanner`)

Fixed 180px hero, avatar overlap, admin-specific chrome.

### D.2 Content (padding 24–64px)

| Section | Contents |
|---------|----------|
| **Personal Information** | Same tile pattern as customer; edit toggle |
| **Account Security** | Black card: **Change Password** row; fake session row “ASUS Laptop…” |
| **Control Center** | Same expansion as customer |
| **Admin footer** | Full-width red **LOG OUT**; **BoostDrive Admin v1.0.4** |

### D.3 Change Password dialog

| Field | Validation |
|-------|------------|
| Current password | Obscure toggle |
| New password | Obscure toggle |
| Confirm | Must match new |

---

# Part E — Shared components reference

| Component | File | Used for |
|-----------|------|----------|
| `DashboardCard` | `dashboard_ui_components.dart` | Customer header, personal info |
| `DashboardPageContainer` |同上 | Max width wrapper |
| `ProviderProfileUi.sectionCard` | `provider_profile_ui.dart` | Provider sections |
| `ProviderProfileUi.safetyPanel` |同上 | SOS block |
| `ProviderProfileUi.controlCenterShell` |同上 | Hub expansion wrapper |
| `ProviderProfileUi.providerStepper` |同上 | Edit flow steps |
| `DashboardThemeToggle` | `dashboard_theme_toggle.dart` | App bars |

---

# Part F — States & edge cases

| State | UI |
|-------|-----|
| Not logged in | Center: **Not logged in** |
| Loading profile | Center `CircularProgressIndicator` |
| Profile null | **Profile not found** |
| Error | White screen, red icon, **Try Again** |
| Saving profile | Button spinners, disabled inputs |
| Uploading photo | Avatar scrim + progress |
| Uploading documents | Document vault loading flags |
| Suspended | (Not separate UI on this page) |

---

# Part G — Behavior preserved (do not change in redesign)

- Edit / save / cancel personal info flow  
- Email verification on change  
- Profile photo pick / crop / upload / delete / initials  
- Emergency contacts CRUD (sheet + save to profile JSON)  
- Provider stepper validation and document slot requirements  
- Provider gallery vs legal document slot separation (0–6 vs 7–16)  
- Multi business phone numbers for providers  
- Service type and specialization chip selection  
- Log out and delete account confirmations  
- Role-based section visibility (`kIsWeb` hides some mobile-only blocks)  
- Navigation: customer tab vs provider tab vs pushed edit route  

---

# Part H — Stitch redesign checklist

Provide **light + dark** frames for:

- [ ] Customer Profile Settings — full scroll (header, personal info, safety, hub collapsed/expanded, account actions, footer)
- [ ] Customer — personal info **edit mode** (inline fields + cancel/save)
- [ ] Profile Photo bottom sheet  
- [ ] Emergency contacts bottom sheet  
- [ ] Provider Profile — view mode (hero + section cards)  
- [ ] Provider Profile — edit stepper step 1 & 2  
- [ ] Documents Vault detail  
- [ ] Provider app bar: view vs edit-only titles  
- [ ] Admin variant (optional if in scope)  
- [ ] Dialogs: logout, delete, change password, email confirm  

**Match Kinetic:** 24px card radius, 12px controls, Manrope/Montserrat, orange `#FF6600`, dark `#09151B`, light `#F9F9F9`.

---

## Files reference

| File | Role |
|------|------|
| `packages/boostdrive_ui/lib/src/profile_settings_page.dart` | All layouts + logic |
| `packages/boostdrive_ui/lib/src/provider_profile_ui.dart` | Provider/safety/control UI primitives |
| `apps/Mobile/lib/main_shell.dart` | Tab embedding (customer index 5, provider index 4) |
| `packages/boostdrive_core/lib/src/models/user_profile.dart` | Profile fields |
| `packages/boostdrive_core/lib/src/provider_profile_completion.dart` | Provider validation rules |

---

*Generated from codebase audit for Stitch + Google UI redesign. Behavior must remain unchanged unless product explicitly requests functional changes.*
