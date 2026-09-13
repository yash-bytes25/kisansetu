# KisanSetu — SIH 2026 Grand Finale Demo Playbook & Checklist

> **Status:** Software Baseline FROZEN for SIH Evaluation (Phases A–F Complete)  
> **Problem Statement:** SIH26032 — Dynamic Queue Management, Smart Slot Allocation, and Transparent Procurement for Agricultural Mandis  
> **Target Audience:** SIH Evaluation Panel / Jury  

---

## 1. Quick Launch & Environment Setup

| Platform | Recommended Demo URL / Command | Fallback Mode |
| :--- | :--- | :--- |
| **Web (Primary)** | Production Vercel Deployment or `flutter run -d chrome --release` | Local Mock Repository Mode |
| **Android APK** | `build/app/outputs/flutter-apk/app-release.apk` (68.4 MB) | Local In-Memory Cache |
| **Backend** | Supabase Cloud PostgreSQL with Row Level Security (RLS) | Full In-Memory State (`ProcurementStateService`) |

### Demo Credentials (No Real Secrets)
- **Farmer Login:** Mobile `9876543210` | Demo OTP: `123456`
- **Procurement Officer Login:** Officer ID: `OFFICER001` | Password: `password123`
- **Reference Farmer Record:** Ramesh Kumar (Token: `TK-8492`, Registered: 50 Qtl Wheat, Khanna Grain Market)

---

## 2. Step-by-Step Judge Demonstration Script

### Act 1: The Farmer Experience (Visual-First, Multilingual, Low Cognitive Load)

1. **Role Selection & Multilingual Onboarding**
   - Open KisanSetu landing screen.
   - Highlight the **Trilingual Toggle** (English / हिंदी / తెలుగు).
   - Switch language to **हिंदी** or **తెలుగు** to demonstrate instant localization.
   - Tap **Farmer (किसान / రైతు)**.

2. **Secure Phone Login & Demo OTP Verification**
   - Enter mobile number: `9876543210`.
   - On OTP verification screen, highlight the judge-friendly badge: `Prototype Demo OTP: 123456`.
   - Enter `123456` and tap **Verify OTP**.
   - *Judge Point:* Explain that production architecture uses DLT-registered SMS gateways (CDAC / NIC SMS Seva), cleanly abstracted in `AuthService`.

3. **Farmer Dashboard & Produce Inspection**
   - Point out key dashboard metrics:
     - Active Booking Token: `TK-8492`
     - Centre: `Khanna Grain Market`
     - Registered Crop: `Wheat` (50 Quintals)
     - Live Queue Position: `7 farmers ahead` (~35 min wait)
   - Tap the **Voice Assistance** button to demonstrate audio guidance in the active language.

4. **Change Crop & 23-Crop Catalogue Demonstration**
   - Tap **"Change Crop"** on the produce card.
   - Show the **10 Prominent Crops** instantly rendered with official CCEA 2024-25 MSP benchmarks.
   - Adjust volume with `+10 / -10` Quintal stepper to observe real-time value synchronization.

5. **Booking Flow & Smart Slot Allocation**
   - Tap **"Book Token"** on Dashboard to confirm produce and open slot selection.
   - Showcase capacity-aware color tags: *Recommended* (Green), *Good* (Blue), *Busy* (Orange).
   - Open **Go-Time Details**:
     - Explain the core motto: *"Normal systems tell farmers to book. KisanSetu tells farmers when to go."*
     - Live travel calculation + queue delay offset informs the exact departure advisory.

6. **Digital QR Pass & Privacy Shielding**
   - Tap **"My Token / Digital Pass"**.
   - Display the secure QR code embedding token `TK-8492`, farmer ID, and slot time.
   - Point out that Aadhaar and raw bank credentials are cryptographically excluded from the QR payload.

7. **Alternative Centre Recommendation**
   - Navigate to **Alternative Centres** screen.
   - Explain how automatic congestion intelligence detects overloaded yards (>85% load) and guides farmers to nearby under-utilized centres with travel distance and time trade-offs.

8. **Procurement Status, Transparent Weighment & Payment Tracking**
   - Open **Procurement Status** (7-stage visual tracker: Booked → Arrived → Quality Check → Weighment → Accepted → Payment Pending → Completed).
   - Navigate to **Payment Screen**:
     - Transparent breakdown: Gross Amount `₹114,205.00` (50.2 Qtl × ₹2,275/Qtl CCEA MSP).
     - Deductions: `₹0.00`. Net Payable: `₹114,205.00`.
     - Highlight the transparency notice: `Simulated demo reference for SIH26032 prototype evaluation`.

9. **Grievance / Dispute Reporting**
   - Open **Report Issue / Dispute**.
   - Select reason (e.g., *Weight Discrepancy* or *Quality Grade Issue*).
   - Tap **Submit Report** to show instant grievance registration.

---

### Act 2: The Procurement Officer Experience (Operations & Institutional Governance)

1. **Officer Login & Dashboard**
   - Switch to Officer role.
   - Enter Officer ID: `OFFICER001` | Password: `password123`.
   - Show the 11-metric operational KPI grid:
     - Today's Bookings, Arrived, In Queue, Completed, Average Wait, Dock Velocity, Yard Load.
   - Point out the dynamic operating status banner (`Normal / Open`, `Delayed`, `Temporarily Stopped`).

2. **Real Camera QR Scanner & Check-In**
   - Open **Scanner** from Action Areas.
   - Demonstrate the **real laptop webcam preview** with live viewfinder overlay.
   - Show external USB camera switching and device selection.
   - Scan farmer token `TK-8492`:
     - Verified farmer card appears with registered produce and slot.
     - Tap **CHECK IN FARMER** to transition farmer into the live queue.
     - Show duplicate scan rejection when scanning the same token again.

3. **Produce Inspection, Actual Weighment & Quality Grading**
   - Open **Farmer Detail Screen** for `TK-8492`.
   - Select Quality Grade: **FAQ** (Fair Average Quality).
   - Record actual weighbridge scale reading (e.g. 50.2 Qtl) and observe real-time discrepancy calculation.
   - Advance stage: *Quality Check Passed* → *Weighment Recorded* → *Accepted*.

4. **Immutable Weighment Audit Trail (Phase E)**
   - Scroll down to **Section 4: Weighment Audit Trail** on Farmer Detail screen.
   - Highlight the read-only historical ledger showing original weight, updated scale weight, delta kg, officer ID attribution, timestamp, and override reason.
   - Reiterate that this ledger is permanently immutable to prevent scale tampering or corruption.

5. **Dispute Audit Console (Phase E)**
   - Open **Dispute Console** from Action Areas.
   - Filter disputes by status chip (`All`, `Active`, `Under Review`, `Escalated`, `Resolved`, `Rejected`).
   - Tap on dispute card for `TK-8492` (Ramesh Kumar):
     - View registered vs actual quantity and percentage discrepancy.
     - Tap **Resolve Dispute** → enter resolution notes → tap **Confirm Resolution**.

6. **DBT Payment Oversight & Exception Settlement (Phase E)**
   - Open **Payment Oversight** console.
   - Show the 7-stage DBT lifecycle flowchart (`Produce Accepted` → `Completed`).
   - Review DBT performance metrics (Total, Completed, Pending, Failed).
   - Locate an exception card (e.g., `IFSC Mismatch`) with high severity badge → tap **Retry Settlement** to reset status to `Processing`.

7. **Centre Administration & Operating Status Control (Phase E)**
   - Open **Centre Admin** from Action Areas.
   - Verify that non-assigned centres display an **Access Restricted** shield.
   - For authorized centre, demonstrate throughput adjustments (capacity, processing rate/hr, delays).
   - Switch status to **Temporarily Stopped** and highlight the safety confirmation modal: **"Confirm Centre Suspension"**.

---

### Act 3: Resilience, Security & Technical Highlights

1. **Explainable Deterministic Intelligence**
   - Explain to the jury: The intelligence engine uses operational mathematical models (queue depth, processing velocity, arrival schedules, delay offsets) rather than black-box approximations.

2. **Offline-First Resilience**
   - Simulate network disconnection.
   - Show that farmer digital passes, tokens, and produce summaries remain accessible through cached essential state, while online-dependent operations gracefully notify the user.

3. **Strict Security & RLS Isolation**
   - Highlight that Supabase publishable anon keys are strictly isolated, `service_role` keys are forbidden from client source, and database tables are protected by PostgreSQL Row Level Security.

---

## 3. Judge Questions & Clear Architectural Answers

| Question | Recommended Concise Answer |
| :--- | :--- |
| *Is the payment transfer directly connected to RBI / PFMS?* | **"In this prototype, DBT payments are managed via a verified transactional state machine with audit records and CCEA 2024-25 MSP calculations. The service architecture is designed as an integration boundary ready to plug into PFMS / NPCI e-Kuber APIs in production."** |
| *How are farmers authenticated without smartphones?* | **"KisanSetu supports feature phones via IVR / SMS broadcast fallback and kiosk check-in tokens. For smartphones, we prioritize visual icons, voice guidance in regional languages, and high-contrast cards."** |
| *How does dynamic slot allocation prevent mandi congestion?* | **"The algorithm distributes arrival times using intake velocity and weighbridge throughput, flattening arrival spikes and giving farmers an individualized Go-Time departure advisory."** |
| *What happens if the internet goes down at the mandi?* | **"KisanSetu includes an offline-first state engine. Officers can continue scanning verified offline QR tokens and recording weights locally; data reconciles automatically once connectivity resumes."** |
| *Can an officer change scale records after procurement?* | **"Every scale adjustment is permanently recorded in the Immutable Weighment Audit Trail with officer ID, original vs updated weight, delta, timestamp, and justification reason."** |
| *Can an officer tamper with other centres?* | **"No. The officer centre authorization boundary strictly enforces `AuthService.currentCentreId`, displaying an Access Restricted screen if unauthorized centres are accessed."** |
