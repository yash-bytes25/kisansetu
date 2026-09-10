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

## 10. Security Checklist

Before pushing any changes:
- [x] No `service_role` keys present in code or configuration.
- [x] `.env` and credential files listed in `.gitignore`.
- [x] All Supabase tables protected by explicit RLS policies.
- [x] Publishable/anon key used strictly for client interactions.
- [x] Local mode remains fully functional without credentials.
