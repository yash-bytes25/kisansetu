# KisanSetu Phase G-B0: Bhashini Integration Preparation Document
**Project**: KisanSetu – Smart Procurement Management Platform  
**SIH 2026** | Problem Statement: SIH26032  
**Tagline**: *"Speak. Understand. Confirm. Act."*  

---

> [!IMPORTANT]
> **OFFICIAL STATUS**: **Real Bhashini integration is pending API approval.**  
> No real Bhashini API calls are made during this evaluation phase. All demonstrations operate on high-fidelity, vendor-agnostic Mock Voice Providers (`DEMO/MOCK`). Zero real or fake credentials reside in client code, Flutter assets, APK resources, or git history.

---

## 1. Architectural Overview & Pipeline Contract

The KisanSetu voice processing pipeline is structured with a strict zero-trust boundary:

```
Farmer Microphone / Audio Input
              ↓
    [AudioPayload (In-Memory)]
              ↓
 [VoiceInputProvider (ASR Interface)]
              ↓
  [Supabase Edge Function Proxy]   <--- BHASHINI CREDENTIAL BOUNDARY (Server-Side Secrets)
              ↓
      [Bhashini ALD Service]        <--- Audio Language Identification
              ↓
      [Bhashini ASR Service]        <--- Speech-to-Text Recognition
              ↓
   [Gemini Intent Provider]         <--- Structured NLU (Schema-Enforced)
              ↓
         [VoiceIntent]              <--- Extracted Intent & Entities
              ↓
   [Validation & Safety Guard]      <--- Completeness Check & Missing Slot Prompts
              ↓
    [Farmer Confirmation Card]      <--- MANDATORY: Zero AI Database Mutation Without User Consent
              ↓
      [VoiceActionRouter]           <--- Existing KisanSetu Domain Services
              ↓
   [Response & Explanation Text]
              ↓
     [Bhashini TTS Service]         <--- Text-to-Speech Synthesis
              ↓
     [Audio Output / Speaker]
```

---

## 2. Core Service Contracts

### A. Audio Language Identification (ALD)
- **Contract**: `AudioLanguageIdentifier` ([bhashini_ald_service.dart](file:///c:/Users/kbhav/OneDrive/Documents/ode%20to%20code/lib/services/bhashini/bhashini_ald_service.dart))
- **Method**: `Future<String> identifyLanguage(AudioPayload audio)`
- **Behavior**: Given an in-memory `AudioPayload`, identifies the spoken Indian language (e.g., `hi`, `te`, `en`). Throws `EmptyAudioException` if buffer is empty, or `BhashiniUnavailableException` if pending approval.

### B. Automatic Speech Recognition (ASR)
- **Contract**: `BhashiniAsrProvider` ([bhashini_asr_service.dart](file:///c:/Users/kbhav/OneDrive/Documents/ode%20to%20code/lib/services/bhashini/bhashini_asr_service.dart))
- **Methods**:
  - `Future<bool> startListening({language, onResult, onError})`
  - `Future<String> transcribeAudio(AudioPayload audio)`
- **Behavior**: Validates language support against configuration, streams speech buffers to server edge proxy, and delivers real-time transcripts.

### C. Neural Machine Translation (NMT)
- **Contract**: `MachineTranslationProvider` ([bhashini_translation_service.dart](file:///c:/Users/kbhav/OneDrive/Documents/ode%20to%20code/lib/services/bhashini/bhashini_translation_service.dart))
- **Method**: `Future<String> translate({sourceText, sourceLang, targetLang})`
- **Behavior**: Translates between 22 scheduled Indian languages. Unconfigured state safely falls back to source text.

### D. Text-to-Speech (TTS)
- **Contract**: `BhashiniTtsProvider` ([bhashini_tts_service.dart](file:///c:/Users/kbhav/OneDrive/Documents/ode%20to%20code/lib/services/bhashini/bhashini_tts_service.dart))
- **Methods**:
  - `Future<void> speak(text, {language})`
  - `Future<Uint8List?> synthesizeAudio(text, {language})`
- **Behavior**: Converts localized text responses into high-naturality speech audio buffers for playback.

---

## 3. Provider Switching Mechanism

The Voice Assistant supports instant runtime switching without code modifications:

```dart
// Default Mode:
VoiceAssistantService.instance.setProviderMode(VoiceProviderMode.mock);

// Live Bhashini Mode (Once Approved):
VoiceAssistantService.instance.setProviderMode(VoiceProviderMode.realBhashini);
```

| Provider Mode | Active Input | Active Output | Active NLU / Intent | Default |
|:---|:---|:---|:---|:---:|
| `DEMO/MOCK` | `MockVoiceInputProvider` | `MockVoiceOutputProvider` | `MockIntentProvider` | **YES** |
| `REAL_BHASHINI` | `BhashiniAsrService` | `BhashiniTtsService` | `GeminiService` | NO (Awaiting Approval) |

---

## 4. Security & Server-Side Credential Boundary

- **Client Binary Cleanliness**: No API keys or authorization headers exist in client code, Flutter assets, JavaScript bundles, or Android APK resources.
- **Server-Side Proxy**: Supabase Edge Function (`supabase/functions/bhashini-proxy/index.ts`) securely holds credentials:
  - `BHASHINI_API_KEY`: Pipeline authorization key.
  - `BHASHINI_USER_ID`: Developer portal user identifier.
  - `BHASHINI_PIPELINE_ID`: Approved ULCA pipeline identifier.
- **Pending Guard**: When server secrets are unconfigured, the proxy returns `503 Service Unavailable` with `status: "PENDING_APPROVAL"`, triggering graceful offline/mock fallback.

---

## 5. Ephemeral Audio Contract

- **Contract**: `AudioPayload` ([voice_audio_data.dart](file:///c:/Users/kbhav/OneDrive/Documents/ode%20to%20code/lib/models/voice/voice_audio_data.dart))
- **Privacy Rule**: Farmer speech audio is stored strictly in memory (`Uint8List`) during recognition and playback.
- **Zero Disk Persistence**: Raw audio payloads are never written to SQLite, Supabase tables, browser cache, or mobile file systems.

---

## 6. Offline Fallback & Failure Handling

When connectivity drops or Bhashini services are unreachable:
1. The Voice Assistant displays a clean, reassuring farmer prompt:
   > *"Voice service is temporarily unavailable. You can type your request instead."*  
   > *(HI: "आवाज़ सेवा अस्थायी रूप से अनुपलब्ध है। आप अपना अनुरोध टाइप कर सकते हैं।")*  
   > *(TE: "వాయిస్ సేవ తాత్కాలికంగా అందుబాటులో లేదు. మీరు మీ అభ్యర్థనను టైప్ చేయవచ్చు.")*
2. Technical errors and raw HTTP codes are strictly sanitized.
3. Offline queue, Go-Time caching, and offline receipt rules continue functioning unchanged.

---

## 7. Gemini AI Boundary & Safety Constraints

- **Restricted Access**: Gemini receives only transcribed text and previous intent context.
- **Structured Output**: Returns structured `VoiceIntent` objects according to strict JSON Schema.
- **Zero Direct Database Mutation**: Gemini and voice providers cannot mutate database state directly.
- **Mandatory Farmer Confirmation**: All actions (booking slots, changing quantities, lodging disputes) require explicit confirmation via the Farmer Confirmation Card.

---

## 8. Next Steps Once Bhashini Approval is Granted

1. Provision server secrets in Supabase Edge Functions:
   ```bash
   supabase secrets set BHASHINI_USER_ID="..." BHASHINI_API_KEY="..." BHASHINI_PIPELINE_ID="..."
   ```
2. Retrieve approved pipeline configuration (service IDs, model IDs, and supported language pairs).
3. Connect `bhashini-proxy` Edge Function to the live Bhashini ULCA gateway.
4. Toggle client mode via environment flag `BHASHINI_PIPELINE_URL`.
