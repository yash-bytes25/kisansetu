# KisanSetu — Supabase Backend Setup & Migration Guide

**Project:** KisanSetu (SIH26032)  
**Team:** ODE TO CODE  
**Phase:** Phase 10 — Supabase Backend Foundation  

This guide walks developers through setting up the persistent Supabase backend for KisanSetu. The application uses a **safe dual-mode backend architecture**: it defaults to `BackendMode.local` (running 100% offline with zero credentials required), and connects to Supabase when `--dart-define` parameters are provided.

---

## 1. Create a Supabase Project

1. Log in to [Supabase Dashboard](https://app.supabase.com/).
2. Click **New Project** and select your organization.
3. Provide project details:
   - **Name:** `kisansetu-procurement`
   - **Database Password:** Generate a strong, secure password and store it safely in your password manager.
   - **Region:** Choose a region close to your primary deployment target (e.g., `ap-south-1` for Mumbai / India).
   - **Pricing Plan:** Free tier is sufficient for development and demonstration.
4. Wait for database provisioning to complete (typically ~2 minutes).

---

## 2. Configure URL & Publishable Key

Once the project is created:
1. Navigate to **Project Settings** → **API** (`/project/<project-ref>/settings/api`).
2. Copy the following values:
   - **Project URL:** `https://<your-project-ref>.supabase.co`
   - **Project API Keys** → `anon` `public` key: `eyJh...`

> [!CAUTION]
> **NEVER** copy or expose the `service_role` (secret) key in Flutter code or command line arguments. Flutter is a client-side application; storing service-role keys in client builds allows attackers to bypass Row-Level Security entirely. Only use the `anon` / `publishable` key.

3. For local developer convenience, create a `.env` file in the project root (**never commit this file** — it is already added to `.gitignore`):

```env
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-actual-anon-publishable-key-here
BACKEND_MODE=supabase
```

---

## 3. Run Database Schema

1. In your Supabase Dashboard, open **SQL Editor** from the left navigation.
2. Click **New Query**.
3. Open the schema file from this repository:
   [`supabase/schema.sql`](supabase/schema.sql)
4. Copy the entire contents of `supabase/schema.sql` into the SQL Editor.
5. Click **Run** (Ctrl + Enter).
6. Verify that the query executes successfully and creates the 10 core tables:
   - `farmers`
   - `procurement_centres`
   - `officer_profiles`
   - `farmer_produce`
   - `bookings`
   - `queue_entries`
   - `procurement_records`
   - `payments`
   - `notifications`
   - `disputes`

Alternatively, if you use the Supabase CLI:
```bash
supabase link --project-ref <your-project-ref>
supabase db push
```

---

## 4. Enable Required Extensions

The schema script automatically runs:
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
To verify enabled extensions in Supabase Dashboard:
- Go to **Database** → **Extensions**.
- Confirm that `uuid-ossp` and `pgcrypto` are active.

---

## 5. Configure Authentication

KisanSetu supports two user authentication profiles:

### A. Farmer Authentication (Phone / OTP)
1. Go to **Authentication** → **Providers** → **Phone**.
2. For testing/prototyping without incurring SMS carrier charges:
   - Enable **Phone provider**.
   - Under **Phone Auth**, configure test phone numbers (e.g. `+919876543210` with test code `123456`).
3. For local mode, KisanSetu automatically accepts demo OTP `123456` without external SMS delivery.

### B. Officer Authentication (Email & Password)
1. Go to **Authentication** → **Providers** → **Email**.
2. Ensure **Email provider** is enabled.
3. Create an initial procurement officer in **Authentication** → **Users** → **Add User**:
   - Email: `officer001@kisansetu.gov.in`
   - Password: Choose a secure password
   - Auto Confirm User: Checked
4. In the SQL Editor, assign this officer to a procurement centre in `public.officer_profiles`:
   ```sql
   INSERT INTO public.officer_profiles (officer_id, centre_id, role)
   VALUES (
     '<user-id-from-auth.users>',
     (SELECT id FROM public.procurement_centres LIMIT 1),
     'procurement_officer'
   );
   ```

---

## 6. Configure Row Level Security (RLS)

All 10 tables have Row Level Security enabled in `supabase/schema.sql`.

### RLS Verification Checklist:
- **Farmers:**
  - Can only query and update their own record (`auth.uid() = id`).
  - Can only create and view bookings, produce, queue entries, records, and payments linked to their `farmer_id`.
- **Officers:**
  - Can view and manage bookings, queue entries, records, and payments only for the procurement centre assigned to them in `public.officer_profiles`.
- **Blanket Policies:**
  - `WITH CHECK (true)` is **strictly prohibited** on mutable production tables.

To verify RLS status:
- Open **Authentication** → **Policies** in Supabase Dashboard.
- Confirm all tables show green "RLS Enabled" badges.

---

## 7. Configure Realtime

The schema enables Realtime publication on live operational tables:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.queue_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.procurement_records;
ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
```

To verify Realtime in Dashboard:
1. Go to **Database** → **Replication**.
2. Confirm the 5 tables above are toggled **ON** under the `supabase_realtime` publication.

---

## 8. Run Flutter App in Local Mode (Default)

To run the application with the existing zero-dependency in-memory prototype:
```bash
# Web (Chrome)
flutter run -d chrome

# Android
flutter run
```
In this mode:
- `BackendMode.local` is active by default.
- No network requests are made to Supabase.
- Demo OTP `123456` and Officer login `OFFICER001` work seamlessly.
- All Phase 1–9 features function 100% offline.

---

## 9. Switch to Supabase Mode for Integration Testing

To launch KisanSetu connected to your live Supabase project:

```bash
flutter run -d chrome \
  --dart-define=BACKEND_MODE=supabase \
  --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=eyJh...
```

For Android APK build:
```bash
flutter build apk --debug \
  --dart-define=BACKEND_MODE=supabase \
  --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=eyJh...
```

---

## 10. Demo Seed Process & Demo Credentials

To populate a development or evaluation Supabase environment with safe, fully-structured demonstration data:

1. Open your Supabase project dashboard → **SQL Editor**.
2. Click **New Query**.
3. Open and copy the contents of [`supabase/seed.sql`](supabase/seed.sql).
4. Click **Run**.
5. The seed script provisions:
   - **Primary Procurement Centre:** `Khanna Grain Market` (UUID: `11111111-1111-1111-1111-111111111111`), capacity 500 Qtl/day, load 75%, 15 Qtl/hr.
   - **Secondary Alternative Centre:** `Samrala Sub-Yard (Grain Silo)` (UUID: `11111111-1111-1111-1111-111111111112`), capacity 400 Qtl/day, load 30%, 18 Qtl/hr (demonstrating dynamic alternative recommendations).
   - **Officer Profile:** Assigned to `officer001@kisansetu.gov.in` at Khanna Grain Market.
   - **Farmer Profile:** Ramesh Kumar (phone: `9876543210`), language: Hindi (`hi`).
   - **Produce Record:** Wheat (`गेहूं`), 50 Quintals.
   - **Active Booking:** Token `TK-8492`, Slot `11:30 AM`.
   - **Live Queue Record:** Position 7 (6 ahead, estimated wait: 35 min, expected turn: 12:05 PM).
   - **Procurement Record:** Expected 50.00 Qtl, Actual 50.20 Qtl, Quality: FAQ grade.
   - **Payment Record:** Gross & Net: ₹1,14,205 (based on CCEA 2024-25 Wheat MSP ₹2,275/qtl).
   - **Notifications:** Booking confirmation and Go-Time optimal departure alerts.
   - **Dispute Record:** Sample grievance `DSP-8492-01` (weight mismatch tracking).

### Verified Demo Credentials:
| Persona | Access Method | Identifier / Email | Password / OTP | Default Centre |
| :--- | :--- | :--- | :--- | :--- |
| **Farmer (Ramesh Kumar)** | Mobile Phone | `9876543210` | `123456` | Khanna Grain Market |
| **Procurement Officer** | Email / Officer ID | `OFFICER001` (`officer001@kisansetu.gov.in`) | `123456` | Khanna Grain Market |

---

## 11. Complete SIH Judge End-to-End Demonstration Script

### Part 1: Farmer Journey
1. **Login:** Launch app → Select English / Hindi / Telugu → Enter phone `9876543210` → Verify OTP `123456`.
2. **Dashboard Overview:** View live Token card `TK-8492`, "When Should I Go?" Go-Time departure card, and current produce.
3. **Change Crop & Produce Sync:** Tap "Change Crop" / "फसल बदलें" → Select from the 10 prominent crops (e.g. Paddy / Maize / Cotton / Tur) or browse 23 crops → Adjust quantity stepper → Confirm → Observe instant MSP calculation, push notification, and produce card update.
4. **Find Centre & Smart Slot:** Tap "Book Slot" → Browse available procurement centres (Khanna Grain Market / Samrala Sub-Yard) → Check capacity load indicators → Select recommended smart slot → Generate digital booking.
5. **QR Digital Pass:** Tap "Digital Pass" → View tamper-evident QR code with encoded booking metadata and offline fallback.
6. **Go-Time & Check-In:** Observe real-time traffic + queue departure advisory → Simulate arrival check-in → Status moves to "Checked In".
7. **Live Queue Tracking:** View live queue position countdown (e.g., position 7 → 6 ahead → ~35 min).
8. **Procurement Status:** Monitor multi-stage progress: Gate Entry → Sampling & Assaying (FAQ grade) → Weighbridge → Acceptance.
9. **Payment Transparency:** Open Payment screen → Review gross produce value, deductions (₹0), net payable amount, and official CCEA reference MSP benchmark.
10. **Grievance / Dispute:** If discrepancy arises, file a dispute → Track real-time resolution status.

### Part 2: Officer Operations Journey
1. **Officer Login:** Switch to Officer portal → Enter Officer ID `OFFICER001` → Password `123456`.
2. **Operations Dashboard:** Review centre KPIs (Total Bookings: 24, Arrived: 16, In Queue: 7, Completed: 9, Centre Load: 75%).
3. **View Active Queue:** Inspect farmers waiting in line, sort by token, arrival time, or status.
4. **QR Scan & Validation:** Open Scan QR → Simulate or camera-scan farmer QR pass → Auto-validates token `TK-8492` and marks arrival.
5. **Stage Progression:** Progress farmer through workflow:
   - Mark as "Processing / Sampling"
   - Enter weighbridge weight (e.g., 50.20 Qtl)
   - Record quality assaying grade (Grade A / FAQ / Grade B)
   - Accept procurement lot
6. **Payment & Settlement Trigger:** Review generated payment advice (`PAY-2026-8492`), approve payment status transition to `Processing` or `Completed`.
7. **Operational Exceptions:** View delay management alerts, adjust processing rate, or trigger Dynamic Slot Reallocation / Alternative Centre diversion.

---

## 12. Production Integration Boundaries & Limitations

To ensure absolute transparency and technical rigor during evaluation:

1. **SMS Gateway:**
   - *Current State:* KisanSetu utilizes in-app push notifications and simulated OTP (`123456`) for demonstration.
   - *Production Boundary:* Requires integrating a licensed TRAI-compliant DLT (Distributed Ledger Technology) SMS gateway (such as NIC SMS Gateway, Textlocal, or CDAC Mobile Seva) for live SMS delivery.
2. **Direct Benefit Transfer (DBT) Bank Settlement:**
   - *Current State:* Payment calculations, MSP valuations, deductions, and payment status lifecycles are fully modeled with CCEA reference benchmarks and stored in PostgreSQL / local state.
   - *Production Boundary:* Direct electronic fund transfer requires bridging to Government PFMS (Public Financial Management System) or NPCI APBS (Aadhaar Payment Bridge System) using bank-grade digital signatures.
3. **Aadhaar / e-KYC Verification:**
   - *Current State:* Farmer identities use simulated OTP phone verification and mock identification tokens.
   - *Production Boundary:* Direct Aadhaar biometric/OTP authentication requires onboarding as a registered AUA/KUA with UIDAI.
4. **MSP Rate Feeds:**
   - *Current State:* Official reference benchmarks from the Government of India CCEA pricing (2024-25 / 2025-26) are embedded and dynamically calculated in `PaymentCalculationService`.
   - *Production Boundary:* Live dynamic feeds can be polled from Agmarknet or e-NAM APIs.

---

## 13. Final Security & Release Checklist

Before final demonstration and release builds:
- [x] No `service_role` keys present in code or configuration.
- [x] `.env` and credential files listed in `.gitignore`.
- [x] All Supabase tables protected by explicit RLS policies (`auth.uid()` checks).
- [x] Publishable/anon key used strictly for client interactions.
- [x] Dual-mode architecture functional: local offline-ready demo runs with zero configuration.
- [x] Zero real farmer PII present in seed scripts or source code.
- [x] All MSP rates identified as official CCEA reference benchmarks.

