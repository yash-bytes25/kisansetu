# KisanSetu – Phase G-A Architecture & Implementation Report
## Voice Assistant Framework ("Speak. Understand. Confirm. Act.")
**Project**: KisanSetu – Smart Procurement Management Platform  
**Hackathon**: Smart India Hackathon (SIH 2026) | Problem Statement: SIH26032  
**Team**: ODE TO CODE  
**Status**: Completed & Validated (Framework Only)  

> [!IMPORTANT]
> **Real Bhashini integration is pending API approval.**
> This implementation delivers the clean, extensible voice assistant framework, trilingual NLU engine, conversational slot filling, and confirmation safety pipeline. No live Bhashini API keys or Gemini API credentials are required or embedded in client source code.

---

## 1. Purpose of the KisanSetu Voice Assistant
The KisanSetu Voice Assistant is **NOT a generic chatbot**, weather widget, or agricultural marketplace. It is an **actionable farmer accessibility and operational coordination layer** designed specifically for agricultural procurement under MSP.

### Core Tagline
> **"Speak. Understand. Confirm. Act."**

It enables farmers of diverse digital literacy levels to speak naturally in their mother tongue (English, Hindi, Telugu) to:
1. Book a procurement slot via conversational progressive slot filling.
2. Check active token number and digital pass status.
3. Query real-time queue position and waiting time.
4. Access intelligent Go-Time departure recommendations.
5. Inquire about DBT payment processing status and payment history references.
6. Verify procurement centre operational status and delays.
7. Receive alternative procurement centre recommendations during peak congestion.
8. Report grievances or scale weight discrepancies via dispute management.
9. Inspect registered KYC and profile details.

---

## 2. Service & Provider Architecture

The framework decouples input ingestion, intent extraction, response generation, and domain dispatch through strict abstract interfaces:

```
                      Farmer Interaction
                              │
                    ┌─────────▼─────────┐
                    │ VoiceInputProvider│
                    └─────────┬─────────┘
                              │
               ┌──────────────┴──────────────┐
               ▼                             ▼
   [MockVoiceInputProvider]        [BhashiniVoiceInputProvider]
         (Phase G-A)                     (Future via Edge Function)
               │                             │
               └──────────────┬──────────────┘
                              ▼
                     ┌────────────────┐
                     │ IntentProvider │
                     └────────┬───────┘
                              │
               ┌──────────────┴──────────────┐
               ▼                             ▼
      [MockIntentProvider]          [GeminiIntentProvider]
    (Trilingual Regex/Rules)         (Future via Edge Function)
               │                             │
               └──────────────┬──────────────┘
                              ▼
                  ┌──────────────────────┐
                  │ VoiceSessionService  │ (Multi-turn state & slot filling)
                  └───────────┬──────────┘
                              │
                  ┌───────────▼──────────┐
                  │  CONFIRMATION SAFETY │ (Mandatory Farmer Tap)
                  └───────────┬──────────┘
                              │
                  ┌───────────▼──────────┐
                  │  VoiceActionRouter   │
                  └───────────┬──────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
[SmartSlotService]  [ProcurementStateService] [DisputeService]
```

### File Structure
- `lib/models/voice/voice_intent.dart`: Structured intent model with slot entities, missing fields, confidence, and confirmation flags.
- `lib/models/voice/voice_message.dart`: Conversational turn model with `VoiceSender` and `VoiceAssistantMode` (`ASK`, `DO`, `EXPLAIN`).
- `lib/services/voice/voice_provider_interfaces.dart`: Abstract interfaces (`VoiceInputProvider`, `VoiceOutputProvider`, `IntentProvider`).
- `lib/services/voice/mock_voice_providers.dart`: Rule-based trilingual NLU engine, conversational slot filling, correction handler, and speech synthesizers.
- `lib/services/voice/voice_session_service.dart`: Reactive state management (`ChangeNotifier`) tracking messages, current intent, language, and modes.
- `lib/services/voice/voice_response_service.dart`: Multilingual response formatter for greetings, slot questions, confirmation cards, and fallbacks.
- `lib/services/voice/voice_action_router.dart`: Router connecting confirmed voice intents to existing KisanSetu backend services.
- `lib/services/voice/voice_assistant_service.dart`: High-level singleton facade coordinating input, parsing, confirmation, and dispatch.
- `lib/services/bhashini/`: Clean edge boundaries for future Bhashini ASR, TTS, and Translation endpoints.
- `lib/services/ai/gemini_service.dart`: Clean edge boundary for future Gemini semantic NLU.
- `lib/screens/farmer/farmer_voice_assistant_screen.dart`: Complete voice assistant UI with animated mic, confirmation card, and suggestion chips.

---

## 3. Supported Intents (`VoiceIntentType`)

| Intent Enum | Purpose | Requires Confirmation | Target Service |
|:---|:---|:---:|:---|
| `bookSlot` | Book a procurement slot | **Yes** | `ProcurementStateService.updateFarmerBooking` + `SmartSlotScreen` |
| `getTokenStatus` | Retrieve active digital token | No | `FarmerDashboardData.tokenNumber` |
| `getGoTime` | Get recommended departure time | No | `QueuePredictionService.predict` / `FarmerDashboardData` |
| `getQueue` | Get queue position & wait time | No | `FarmerDashboardData.peopleAhead` |
| `getPaymentStatus` | Check DBT payment processing state | No | `FarmerDashboardData.paymentStatus` / `paymentReference` |
| `getPaymentHistory` | Query latest payment receipts | No | `FarmerPaymentHistoryScreen` |
| `getProcurementStatus`| Check stage (Sampling, Weighment) | No | `FarmerDashboardData.lifecycleStatus` |
| `recommendCentre` | Get less congested centres | No | `FarmerAlternativeCentresScreen` |
| `getCentreStatus` | Check if centre is open or delayed | No | `ProcurementStateService.centreStatus` |
| `changeCrop` | Update crop on active booking | **Yes** | `ProcurementStateService.updateFarmerBooking` |
| `changeQuantity` | Update quantity on active booking | **Yes** | `ProcurementStateService.updateFarmerBooking` |
| `getProfileInfo` | Query KYC, Aadhaar & bank details | No | `AuthService` + `ProcurementStateService` |
| `startDispute` | Report grievance or scale discrepancy | **Yes** | `FarmerDisputeScreen` |
| `help` | KisanSetu voice assistant help | No | `VoiceResponseService` |

---

## 4. Confirmation Safety Rule (Strict Guarantee)

> [!CAUTION]
> **Zero Unconfirmed Database Mutations**: The KisanSetu voice assistant will **NEVER** create, update, or cancel bookings based solely on interpreted voice speech.

1. Speech is transcribed and processed into a `VoiceIntent`.
2. Missing slots are filled conversationally through multi-turn questions.
3. Once all required slots (`crop`, `quantity`, `date`) are satisfied, the system generates an interactive **Confirmation Card** with:
   - Understood crop name
   - Understood quantity and unit
   - Understood date
   - Recommended centre and smart slot
   - **`[ CONFIRM & CONTINUE ]`**, **`[ CHANGE ]`**, and **`[ CANCEL ]`** buttons
4. Only when the farmer explicitly taps `[ CONFIRM & CONTINUE ]` is the `VoiceActionRouter` invoked to execute the existing booking or update workflow.
5. Tapping `[ CANCEL ]` or saying "Cancel" immediately clears the pending intent without any changes to the database.

---

## 5. Conversational Slot Filling & Dynamic Correction

The assistant supports progressive slot filling and non-destructive corrections without restarting the conversation:

```
Farmer:    "I want to sell wheat."
Assistant: "How much wheat do you want to sell?"
Farmer:    "50 kilos."
Assistant: "What date would you like to visit?"
Farmer:    "Tomorrow."
Assistant: "I understood: Wheat – 50 Quintals – Tomorrow. Find the best slot?"
           [Confirm & Continue] [Change] [Cancel]

Farmer:    "No, make it 100 kg."
System:    Updates quantity = 100 Quintals, keeps crop = Wheat, date = Tomorrow.
```

---

## 6. Offline Restrictions & Security Boundary

1. **Offline Mode**: If the device is disconnected (`AppConnectivityService.instance.isOnline == false`), the assistant:
   - Provides cached information where available (token, offline pass).
   - Strictly blocks creating new bookings or claiming live queue positions.
   - Informs the farmer in plain language that internet connectivity is required.
2. **Security & Secrets**:
   - Zero hardcoded API keys in Flutter client source code.
   - In future phases, client queries will pass to Supabase Edge Functions with authenticated JWTs, where Bhashini and Gemini keys are stored safely as encrypted environment secrets.

---

## 7. Verification Summary

- **Static Analysis (`flutter analyze --no-pub`)**: **0 issues found**
- **Test Suite (`flutter test`)**: **273 / 273 tests passing (100% pass rate)**
  - 250 baseline tests (Phases A–F) fully preserved with 0 regressions.
  - 23 new Phase G-A tests covering intent parsing, slot filling, corrections, safety, routing, and UI rendering.
- **Flutter Web Build (`flutter build web --release`)**: **Successful** (`build\web`)
- **Android APK Build (`flutter build apk --release`)**: **Successful** (`build\app\outputs\flutter-apk\app-release.apk`, 69.0 MB)
