# Find a Provider — View Profile UI Specification

Specification for redesigning the **View Profile** screen opened from the **Find a Provider** page (`/find-provider`) on the BoostDrive website. Intended for Stitch with Google and design handoff.

**Implementation reference:** `apps/Web/lib/find_providers_page.dart` — `_ProviderCard`, `_ProviderDetailPage`, `_SectionTitle`, `_SpecializationChip`, `_TrustItem`, `_BusinessDetailRow`.

---

## 1. User flow

1. Customer opens **Find a Provider** (`/find-provider`).
2. They search, filter, and sort verified providers (mechanics, towing, parts, rental, etc.).
3. Each provider appears as a **card** in a responsive grid.
4. Tapping the card or **View Profile** opens the full **Provider Profile** screen (`_ProviderDetailPage`).
5. From the profile, the user can call, message, or (placeholder) request a quote.

**Data source:** `UserProfile` from Supabase via `verifiedProvidersProvider`.

**Roles:** Logged-in customers see the profile inside `PremiumPageLayout`. Guests see it inside `PublicPageFrame` with site header/footer.

---

## 2. Brand and design tokens

| Token | Hex / value | Usage |
|--------|-------------|--------|
| Primary orange | `#FF6600` | Buttons, accents, verified badges, chips, borders |
| Dark background | `#09151B` | Profile detail body atmosphere |
| Dark surface | `#121D24` | Trust metric cards |
| Body text (dark UI) | `#EBEBF5` | Main copy on profile detail |
| Muted text | `#90B2CB` | Section subtitles, labels |
| Light page background | `#F5F7F8` | Find a Provider list page |
| Accent orange | `#FF8C00` | Secondary accent |
| Hours (list) | Green ~`#2E7D32` | Working hours pill on cards |
| Hours (detail) | `Colors.green.shade400` | Working hours text |
| Promo badge | Orange tint | “Promo” on list cards |

**Typography notes**

- List cards: bold weights (w800) for names; 18px title on cards.
- Profile sections: 18px section titles, w900, white, letter-spacing -0.5.
- Body copy on profile: 15px, line height ~1.5–1.6.

---

## 3. Provider list card (entry point)

Shown on Find a Provider **before** opening View Profile. Helps Stitch understand context.

### 3.1 Container

- Background: light card (`PublicPagePalette.cardBackground`).
- Border radius: **28px**.
- Padding: **20px**.
- Border: 1px palette border color.
- Shadow: soft, offset (0, 10), blur 24.
- Entire card is clickable (pointer cursor on web).

### 3.2 Header row

| Element | Specification |
|---------|----------------|
| Avatar | Circle, radius **30** (60px). Background: primary orange at **14%** opacity. **Initials only** — no profile photo. Text: 22px, w800, orange. |
| Business name | `displayName` — registered business name for providers, else `fullName`. 18px, w800, title color. |
| Verified badge | Pill if `verificationStatus == 'approved'`. Orange 12% fill, check icon + “Verified”, 11px w800. |
| Promo badge | Orange pill “Promo” if active promotions exist for provider category. |
| Role | e.g. Mechanic, Towing, Service Provider, Parts Supplier, Rental Agency. 14px w700, body color. |

### 3.3 Preview content

- **Bio:** Max 3 lines, ellipsis. Fallback: *“Verified provider profile on BoostDrive. View this profile to see services, experience, and contact information.”*
- **Info pills** (rounded capsules, icon + label, max width ~280px):
  - **Location** (`near_me`): `serviceAreaDescription`, else `workshopAddress`, else *“Service area on request”*.
  - **Hours** (`schedule`): `workingHours` or *“Availability on request”* (green on list).
  - **Experience** (`history`): “{n} years experience” if `yearsInOperation` set.
  - **Phone** (`phone_outlined`): first business number, else personal `phoneNumber`.
- **Tags:** Up to 2 `brandExpertise` + 2 `serviceTags` as small rounded chips (11px w700).

### 3.4 Card actions

| Button | Style | Behavior |
|--------|--------|----------|
| Contact | Outlined, orange foreground, 16px radius | Business numbers dialog (web) or tel flow. Hidden if no numbers. |
| View Profile | Filled orange, 16px radius | Navigates to Provider Profile page. |

### 3.5 List grid breakpoints

| Viewport width | Columns |
|----------------|---------|
| ≤ 760px | 1 |
| 761–1140px | 2 |
| > 1140px | 3 |

Spacing: 20px cross/main axis. Aspect ratio ~0.98 (wide) / 1.02 (narrow).

---

## 4. View Profile page — page chrome

### 4.1 Logged-in user

- Shell: `PremiumPageLayout`.
- **App bar:** Provider `displayName` as title; **white back arrow** (leading) → `Navigator.pop`.
- Body: `SingleChildScrollView`, content max width **900px**, centered, **24px** padding.

### 4.2 Guest (not logged in)

- Shell: `PublicPageFrame` (site nav + footer).
- **Back:** `TextButton.icon` — arrow + “Back” above profile body.
- Same 900px constrained scrollable content.

### 4.3 Visual mode

Profile body content uses a **dark UI treatment** (white / light text, orange accents) and is largely **independent of the global light/dark theme** for section content.

---

## 5. View Profile page — sections (top to bottom)

### 5.1 Hero / identity

**Layout:** Horizontal row.

| Element | Specification |
|---------|----------------|
| Avatar | Radius **40** (80px). Orange fill 20%. **Initials only** — 32px bold orange. **No `profileImg` used.** |
| Name | `displayName`, white, 22px bold |
| Role chip | Padding 10×4, orange 20% background, 8px radius, orange text w600 |
| Verified | Orange `verified` icon, 20px, beside chip if approved |

**Spacing:** 20px between avatar and text block; **32px** below hero before About.

---

### 5.2 About

| Part | Specification |
|------|----------------|
| Section icon | `info_outline`, orange, 20px |
| Title | **About** — white, 18px, w900 |
| Body | `businessBio` or fallback: *“No bio added yet. This provider is part of the BoostDrive verified network.”* |
| Text style | White 90% opacity, 15px, line height 1.6 |

---

### 5.3 Gallery (conditional)

**Visibility:** Only if `galleryUrls` contains non-empty URLs including `/provider-galleries/`.

| Part | Specification |
|------|----------------|
| Title | **Gallery (N/10 photos)** — N = count, max 10 |
| Subtitle | *“Workshop, tow truck, or completed repairs.”* |
| Grid | 4 columns, 12px gap, square tiles (aspect ratio 1) |
| Tile | 12px radius, border `#FF6600` ~13% opacity, `BoxFit.cover` network image |
| Tap | Fullscreen dialog: black ~87% background, `InteractiveViewer` zoom 0.5–4×, close button top-right |

**Redesign opportunity:** 4 columns is tight on mobile — consider 2 columns or horizontal scroll.

---

### 5.4 Service specializations (conditional)

**Visibility:** Any of: `brandExpertise`, `serviceTags`, or (towing role + `towingCapabilities`).

| Part | Specification |
|------|----------------|
| Icon | `build_circle_outlined` |
| Title | **Service Specializations** |
| Subtitle | *“Used for search filters and matching.”* |

**Sub-blocks (each optional):**

1. **Brand expertise** — dim label + chips  
2. **Service tags** — dim label + chips  
3. **Towing capabilities** — only when role contains “towing” + chips  

**Chip style:**

- Padding: 14×8 horizontal/vertical.
- Radius: 12px.
- Background: orange 10%; border: orange 80%, 1.5px.
- Icon: `check_circle`, orange, 16px.
- Label: white, 13px w700.
- Labels via `UserProfile.getSpecializationLabel(key)` (e.g. `toyota` → “Toyota”).

---

### 5.5 Trust and experience

| Part | Specification |
|------|----------------|
| Icon | `verified_user_outlined` |
| Title | **Trust & Experience** |
| Subtitle | *“Business bio and portfolio build customer trust.”* |

**Metric cards** (~160px wide, wrap layout):

- Background: `#09151B` at 80% opacity.
- Radius: 16px; border: orange tint `0x22FF6600`.
- Icon in circular container (orange 15% fill).
- Label: 12px, dim, w600.
- Value: 16px, white, w800.

| Card | Shown when | Value format |
|------|------------|--------------|
| Experience | `yearsInOperation != null` | `{n} Years` |
| Team size | `teamSize != null` | `{n} People` |
| Labor rate | `standardLaborRate != null` | `N${rate}/hr` |
| Verification | Always | `Approved` or `Pending` |

---

### 5.6 Business details (conditional)

**Visibility:** `registrationNumber` or `taxVatNumber` non-empty.

| Part | Specification |
|------|----------------|
| Icon | `business_outlined` |
| Title | **Business details** |
| Rows | `Registration Number:` / `Tax / VAT Number:` — dim label + white selectable value |

---

### 5.7 Location and hours (conditional)

**Visibility:** `serviceAreaDescription` or `workingHours` non-empty.

| Part | Specification |
|------|----------------|
| Icon | `location_on_outlined` |
| Title | **Location & hours** |
| Service area | `near_me` icon (dim) + white text, 15px, line height 1.5 |
| Working hours | `schedule` icon + **green** text w700, 15px |

---

### 5.8 Contact information (conditional)

**Visibility:** `businessContactNumber` non-empty (comma-separated list supported).

| Part | Specification |
|------|----------------|
| Icon | `contact_phone_outlined` |
| Title | **Contact Information** |
| Rows | Business icon + underlined orange **“Business: {number}"**, 16px w600, tappable |

*Note: Personal `phoneNumber` is used for Call/Message fallback but is not listed as separate rows in this section.*

---

### 5.9 Action bar (bottom)

**Layout:** Single row, three equal-width actions, 12px gaps.

| Button | Visual | Enabled when | Behavior |
|--------|--------|--------------|----------|
| **Call Now** | Filled orange, white phone icon + label | Business contact exists | Opens business numbers dialog |
| **Send Message** | Outlined orange border, chat icon | Always shown | Login required; creates direct conversation → Messages page |
| **Request Quote** | Outlined orange border, quote icon | Always shown | Snackbar: *“Request quote — coming soon”* (placeholder) |

**Send Message states:**

- Default: chat icon + “Send Message”.
- Loading: 20×20 orange `CircularProgressIndicator`.
- Not logged in: snackbar *“Please log in to send a message.”*

**Redesign opportunity:** Stack buttons vertically on narrow viewports.

---

## 6. Data model — fields used on profile

| Field | UI usage |
|--------|----------|
| `uid` | Messaging API (`providerId`) |
| `displayName` | App bar title, hero (business name if provider) |
| `fullName` | Fallback for `displayName` |
| `registeredBusinessName` | Drives `displayName` for providers |
| `role` | Role chip; towing-specific sections |
| `verificationStatus` | Verified badge / trust card |
| `businessBio` | About section |
| `galleryUrls` | Gallery grid (filtered by `/provider-galleries/`) |
| `brandExpertise` | Specialization chips |
| `serviceTags` | Specialization chips |
| `towingCapabilities` | Towing chips |
| `yearsInOperation` | Trust card; list pill |
| `teamSize` | Trust card |
| `standardLaborRate` | Trust card (N$) |
| `registrationNumber` | Business details |
| `taxVatNumber` | Business details |
| `serviceAreaDescription` | Location; list pill |
| `workingHours` | Hours; list pill |
| `workshopAddress` | List pill fallback for location |
| `businessContactNumber` | Call, contact section (comma-separated) |
| `phoneNumber` | Call fallback; list pill |
| `profileImg` | **Not displayed** (initials only) |
| `isOnline` | Used in list sort/filter only |
| `primaryServiceCategory` | Promotions lookup on list card |

### Fields on model but not shown on profile today

- `socialFacebook`, `socialInstagram`, `websiteUrl`
- `workshopLat`, `workshopLng`, `workshopAddress` (as dedicated map/address block)
- `storeBiography`, `tradingName`, `businessType`
- `preferredCommunication`, `serviceRadiusKm`, `businessHours24_7`
- Star ratings / reviews
- Services catalog or pricing table

---

## 7. Interactions and edge cases

| Scenario | Current behavior |
|----------|------------------|
| No bio | Placeholder about verified network |
| No gallery | Section hidden |
| No specializations | Section hidden |
| No registration/tax | Business details hidden |
| No location/hours | Location section hidden |
| No business phone | Call Now hidden |
| Request Quote | Non-functional placeholder |
| Gallery tap | Lightbox with zoom + close |
| Web phone tap | Dialog with copy-to-clipboard (not `tel:`) |
| Multiple business numbers | Dialog lists all; first used in some flows |
| Provider user visits `/find-provider` | Redirected to Provider Hub |

---

## 8. Responsive and accessibility notes

| Area | Current behavior | Redesign suggestion |
|------|------------------|---------------------|
| Profile max width | 900px centered | Keep or widen slightly for gallery |
| Gallery columns | Fixed 4 | 2 on mobile, 3 tablet, 4 desktop |
| Action buttons | 3-column row | Stack on `< 600px` |
| Avatar | Initials only | Optional `profileImg` |
| Color contrast | Dark body on theme scaffold | Ensure WCAG on orange/white pairs |
| Focus / keyboard | MouseRegion on custom tap targets | Use semantic buttons for a11y |

---

## 9. Gaps and future features (not implemented)

Documented in code comments but **not in UI:**

- **Services & pricing** catalog section
- **Request quote** workflow (placeholder only)
- Reviews and star ratings on profile
- Map / distance from user
- Online / available-now indicator on detail page
- Social and website links

---

## 10. Stitch prompt (copy-paste)

```
Redesign BoostDrive’s Provider View Profile screen (opened from Find a Provider).

Brand: primary orange #FF6600, dark premium automotive feel (#09151B / #121D24), light list page #F5F7F8.

Flow: User taps provider card → full profile. Max content width 900px, scrollable.

Sections (hide if empty):
1. Hero — avatar (initials or photo), business name, role pill, verified badge
2. About — business bio
3. Gallery — up to 10 workshop/repair photos, lightbox on tap
4. Service specializations — chips for brands, services, towing capabilities
5. Trust cards — years experience, team size, labor rate N$/hr, verification status
6. Business details — registration, VAT
7. Location & hours — service area, working hours (hours in green)
8. Contact — business phone numbers
9. Sticky CTAs — Call Now (primary orange), Send Message (outline), Request Quote (outline, coming soon)

Also refine the list card on Find a Provider: verified/promo badges, bio preview, location/hours pills, Contact + View Profile buttons.

Improve mobile: gallery columns, stacked CTAs, readable typography. Support light and dark theme where possible but profile can stay dark-premium.

Keep all existing data fields conditional. Namibia currency N$ for labor rate.
```

---

## 11. Related files

| File | Purpose |
|------|---------|
| `apps/Web/lib/find_providers_page.dart` | List + profile UI |
| `packages/boostdrive_core/lib/src/models/user_profile.dart` | Profile model |
| `packages/boostdrive_ui/lib/src/theme.dart` | Brand colors |
| `packages/boostdrive_ui/lib/src/premium_layout.dart` | Logged-in profile shell |
| `apps/Web/lib/public_page_frame.dart` | Guest profile shell |
| `apps/Web/lib/messages_page.dart` | Message destination after Send Message |

---

*Last updated from codebase: Find a Provider / View Profile as implemented in `find_providers_page.dart`.*
