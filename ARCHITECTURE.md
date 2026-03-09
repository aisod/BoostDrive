# BoostDrive Technical Architecture

This document provides an in-depth look at the architectural design and technical decisions behind the BoostDrive Ecosystem.

## 📐 Design Philosophy

BoostDrive follows a **Domain-Driven, Layered Architecture** managed within a **Melos Monorepo**. The primary goals are:
1. **Code Reuse**: ~80% of business logic and UI components are shared across Mobile and Web.
2. **Platform Independence**: Mobile-specific (location) and Web-specific (JS interop) code is isolated via conditional imports and stubs.
3. **Reactivity**: Using Riverpod to ensure the UI reacts instantly to backend changes (SOS status, Marketplace inventory).

---

## 🏗️ The Monorepo Structure

```mermaid
graph TD
    A[apps/Mobile] --> E[Shared Packages]
    B[apps/Web] --> E
    
    subgraph E [Shared Packages]
        P1[boostdrive_ui] --> P2[boostdrive_core]
        P3[boostdrive_services] --> P2
        P3 --> P4[boostdrive_auth]
        P4 --> P2
    end
```

### 1. Application Layer (`apps/`)
- **`apps/Mobile`**: Handles the "Services" side of the business. 
  - *Key Logic*: Geo-tracking, SOS management.
  - *Platforms*: Optimized for iOS, Android, and Browser.
- **`apps/Web`**: Handles the "Marketplace" side.
  - *Key Logic*: Shop navigation, Booking management.
  - *Platforms*: Optimized for Desktop Browser.

### 2. Infrastructure Layer (`packages/`)
- **`boostdrive_auth`**: 
  - Centralizes Supabase authentication logic.
  - Implements cross-platform auth methods (email, phone, username, OAuth providers like Google and Apple).
- **`boostdrive_services`**:
  - Contains Data Access Objects (DAOs) and Service Providers.
  - *SOSService*: Real-time stream of emergency requests via Supabase subscriptions.
  - *ProductService*: CRUD operations for vehicle/part listings using Supabase PostgreSQL.

### 3. Presentation Layer (`packages/boostdrive_ui`)
- Uses a unified **Theme Engine** based on premium dark-mode aesthetics.
- Implements the **PremiumPageLayout** which ensures consistent backgrounds and glassmorphism effects project-wide.

### 4. Domain Layer (`packages/boostdrive_core`)
- Contains Plain Old Dart Objects (PODOs) for all data entities.
- Shared constants like `Namibia_Bounds` for map constraints.

---

## 🚑 Service Providers (Responders)

Service Providers are the **physical backbone** of the platform: they bridge digital requests and on-the-ground automotive solutions. The full specification is in **`docs/SERVICE_PROVIDER_SPECIFICATION.md`**. Summary:

- **Emergency Response**: Geolocation-based matching with stranded motorists; immediate assistance (roadside, towing). Implemented via `SosService`, `sos_requests`, and mobile SOS flows.
- **Diagnostics & Repair**: Identify vehicle issues; upload a **required parts list** to the user’s account, linked to BoostDrive.shop marketplace.
- **Quality**: Vetted network; rating/review system (schema/UI to be expanded as needed).
- **Services**: Emergency (roadside, towing), mechanical (mobile + shop), **real-time arrival tracking** for the customer, and **installation** of parts bought on the .shop platform.

Roles in `profiles` (`mechanic`, `towing`, `service_provider`) and `verification_status` support provider vetting; delivery/tracking flows support ETA and status for logistics.

---

## 🔐 Authentication Flow (Cross-Platform)

BoostDrive uses **Supabase Auth** with support for multiple authentication methods:

1. **Email/Password**: Traditional email-based authentication with email verification.
2. **Phone/OTP**: SMS-based authentication with one-time password verification.
3. **Username**: Users can log in with their username instead of email.
4. **OAuth Providers**: Google and Apple sign-in for seamless social authentication.
5. **Password Reset**: OTP-based password reset flow for enhanced security.

---

## 📡 Database Architecture (Supabase)

The migration from Firestore to Supabase introduces a relational schema with the following core tables:

| Table | Role |
| :--- | :--- |
| **`profiles`** | User profiles, role-based access metadata. Linked to Auth. |
| **`products`** | Marketplace inventory (Cars, Parts). |
| **`sos_requests`** | Time-series log of emergency triggers, coordinates, and status. |
| **`bookings`** | Rental transaction records. |
| **`orders`** | Product sales and checkout records. |

---

## 🛠️ State Management Pattern

We use **Riverpod 2.x** with the following conventions:
- **`FutureProvider`**: For one-time fetches (e.g., getting featured cars).
- **`StreamProvider`**: For live data (e.g., SOS status updates).
- **`StateProvider`**: For UI-local state (e.g., loading indicators).
- **`ChangeNotifierProvider`**: (Limited use) for complex legacy UI states.

---

## 📦 Asset Management

Assets are primarily hosted in `packages/boostdrive_ui`. However, to ensure maximum performance and bypass Flutter package path complexities during build, key "Hero" assets are duplicated into the local `apps/Mobile/assets` folder and registered in the local `pubspec.yaml`.

---

## 🚀 Deployment Strategy

1. **Web**: Deployed via hosting platforms (Vercel, Netlify, or custom) using `flutter build web --web-renderer canvaskit`.
2. **Android**: Distributed via **Play Store** (AAB) or direct APK for logistics testing.
3. **CI/CD**: Melos-aware pipelines run `melos analyze` and `melos test` on every push.
