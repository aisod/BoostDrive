# How customers find services and how providers see requests

## How sellers/customers find services from service providers

### Web
1. **Find a Provider (browse and call)**  
   - Go to **Support** in the top navigation → click **Find a Provider**.  
   - You see a list of verified mechanics and towing providers.  
   - Use the **All / Mechanic / Towing** filters.  
   - Each card shows name, role badge, verified badge, phone, and a **Call** button to ring the provider.

2. **Emergency / roadside (SOS)**  
   - On **mobile**, use the **Emergency Hub** (e.g. from the app menu or dashboard) to request **Towing** or **Mobile Mechanic**.  
   - This creates an SOS request; verified providers can see it and accept it (see below).  
   - On web, emergency requests are created from the mobile app; the web app focuses on “Find a Provider” for browsing and calling.

### Mobile
1. **Find a Provider**  
   - Open the **PROVIDERS** tab in the bottom navigation.  
   - Same as web: list of verified providers, filters (All, Mechanic, Towing), **Call** on each card.

2. **Emergency (SOS)**  
   - Open **Emergency Hub** (e.g. from home or menu).  
   - Tap **Request Towing** or **Mobile Mechanic**.  
   - Your location and request are sent; providers see it under “Incoming requests” and can accept.

---

## How and where service providers view requested services

### Web (Provider Hub)
1. Log in with an account whose **role** is **service_provider**, **mechanic**, or **towing** (or equivalent).  
2. You land on **Provider Hub** (dashboard for providers).  
3. The provider dashboard nav on **web** shows **HOME**, **ROUTES**, **FLEET**, **FINANCE** only. **Services requested** (incoming SOS) is **mobile-only**; see Mobile (Provider app) below.

### Mobile (Provider app)
1. Log in as a **service pro** (mechanic/towing/service_provider).  
2. The app shows **Provider Hub** with tabs **MY SERVICES** and **BATLORRIH**.  
3. On **MY SERVICES** (Service Pro Dashboard), scroll to **LIVE SOS ALERTS**.  
4. Pending requests appear as cards; tap **ACCEPT REQUEST** to assign yourself.  
5. After accepting, the customer’s app can show “Provider X is on the way” (e.g. on Emergency Hub / active request card).

---

## Database requirement for “Accept” to work

The **Accept** action updates `sos_requests` with the provider’s id and timestamp. Ensure the table has:

- `assigned_provider_id` (uuid, nullable)
- `responded_at` (timestamptz, nullable)

If these columns are missing, run in Supabase SQL Editor:

```sql
ALTER TABLE sos_requests
  ADD COLUMN IF NOT EXISTS assigned_provider_id uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS responded_at timestamptz;

-- Optional: allow providers to update only pending rows when accepting
CREATE POLICY "Providers can update sos_requests when accepting"
  ON sos_requests FOR UPDATE
  TO authenticated
  USING (status = 'pending')
  WITH CHECK (assigned_provider_id = auth.uid());
```

After this, **Accept** on web (REQUESTS tab) and mobile (ACCEPT REQUEST on a card) will persist and customers will see the provider as assigned.
