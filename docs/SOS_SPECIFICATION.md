# BoostDrive SOS (Save Our Souls) Specification

The SOS system is the high-priority, "emergency mode" designed to provide instant relief to stranded or distressed motorists. It operates as a rapid-response bridge between the user in a crisis and the network of verified service providers.

**Platform:** SOS functionality is **mobile-only**. The web app does not show the "Services requested" tab on the provider dashboard; providers view and accept SOS requests in the **mobile application** only.

---

## 1. The "One-Tap" Emergency Trigger

The core of the SOS feature is a high-visibility button that, when activated, initiates a sequence of automated actions so the user stays safe without navigating complex menus.

- **Instant Dispatch:** Immediately broadcasts a distress signal to the nearest Towing Services and Mobile Mechanics.
- **Live Geolocation Sharing:** Automatically pulls the user's high-precision GPS coordinates and shares them with the responder in real time.
- **Crisis Countdown:** Usually includes a 3–5 second "cancel" timer to prevent accidental triggers before the alert goes live.

---

## 2. Primary SOS Service Categories ("Big 5")

According to standard roadside assistance protocols and the BoostDrive ecosystem, the SOS feature covers these emergency situations:

| SOS Service | What it covers |
|-------------|----------------|
| **Emergency Towing** | Flatbed or hook-and-chain recovery for accidents or major mechanical failures. |
| **Battery Jump-Start** | Instant dispatch of a provider with a booster pack or replacement battery if the vehicle won't start. |
| **Flat Tire Assistance** | On-site tire changes or repair for punctures/blowouts, especially in dangerous or remote areas. |
| **Fuel Delivery** | Emergency delivery of enough petrol or diesel to get the motorist to the nearest station. |
| **Lockout Service** | Assistance for users who have locked their keys inside the vehicle or lost them entirely. |

---

## 3. Safety & Security Features

SOS is not only for car trouble; it also supports **personal safety**:

- **"Panic" Mode:** A silent alert for security threats (e.g. suspicious individuals near the car or road-spiking incidents) that notifies private security or local authorities.
- **Automatic Welfare Checks:** If the app detects a sudden stop or impact (using the phone's accelerometer), it can trigger an "Are you okay?" prompt that escalates to SOS if not answered.
- **Voice Note Integration:** Users can send a hands-free voice note during the SOS to explain the situation to the responder while staying vigilant.

---

## 4. Logistics & Communication (Active Emergency State)

Once the SOS is active, the app enters an **"Active Emergency"** state:

- **Responder Tracking:** The user sees a live map of the responder (Towing/Mechanic) moving toward their location, providing turn-by-turn reassurance.
- **Emergency Contact Alerts:** The app can automatically SMS up to four pre-selected emergency contacts with the user's location and a link to track the situation.
- **Digital Proof:** If enabled, the app can record audio/video of the scene for later use in insurance or police reports.

---

## Implementation Notes

- **Customer (mobile):** Emergency Hub lets users request **Towing** or **Mobile Mechanic**; location and request are sent; active request card shows assigned provider and status.
- **Provider (mobile):** Service Pro Dashboard includes **LIVE SOS ALERTS**; providers see pending requests and can **Accept** to assign themselves; customer then sees "Provider X is on the way."
- **Provider (web):** The "Services requested" tab is **not** shown on the web provider dashboard; SOS request handling is mobile-only.
