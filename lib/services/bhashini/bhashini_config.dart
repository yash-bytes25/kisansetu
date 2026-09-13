// KisanSetu (SIH26032) - Bhashini Pipeline Configuration Model
// Pure abstraction for NLTM Bhashini pipeline parameters.
//
// ZERO-CREDENTIAL SECURITY DIRECTIVE:
// No real API keys, secrets, or user IDs are stored in this file or client artifacts.
// Real credentials reside strictly server-side in Supabase Edge Functions.
// Client uses placeholders or compile-time flags for environment switches.


/// Enum representing the core services within the Bhashini pipeline.
enum BhashiniServiceType {
  ald('Audio Language Identification'),
  asr('Automatic Speech Recognition'),
  nmt('Neural Machine Translation'),
  tts('Text to Speech');

  const BhashiniServiceType(this.displayName);
  final String displayName;
}

/// Service-specific configuration descriptor.
class BhashiniServiceConfig {
  const BhashiniServiceConfig({
    this.serviceId,
    this.modelId,
    this.endpointUrl,
    this.supportedLanguages = const [],
    this.isEnabled = false,
  });

  /// The ULCA pipeline service ID assigned by Bhashini upon approval.
  final String? serviceId;

  /// The model ID for this specific pipeline step.
  final String? modelId;

  /// Dedicated inference or proxy endpoint URL.
  final String? endpointUrl;

  /// Languages officially enabled for this service in the approved pipeline.
  final List<String> supportedLanguages;

  /// Whether this specific sub-service is active and enabled.
  final bool isEnabled;

  bool isLanguageSupported(String lang) {
    if (!isEnabled || supportedLanguages.isEmpty) return false;
    final normalized = lang.trim().toLowerCase();
    return supportedLanguages.any(
      (l) => l.toLowerCase() == normalized || normalized.startsWith(l.toLowerCase()),
    );
  }

  BhashiniServiceConfig copyWith({
    String? serviceId,
    String? modelId,
    String? endpointUrl,
    List<String>? supportedLanguages,
    bool? isEnabled,
  }) {
    return BhashiniServiceConfig(
      serviceId: serviceId ?? this.serviceId,
      modelId: modelId ?? this.modelId,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Central configuration for Bhashini voice and translation architecture.
class BhashiniConfig {
  const BhashiniConfig({
    this.userId = const String.fromEnvironment('BHASHINI_USER_ID', defaultValue: ''),
    this.apiKey = const String.fromEnvironment('BHASHINI_API_KEY', defaultValue: ''),
    this.inferenceApiKey = const String.fromEnvironment('BHASHINI_INFERENCE_KEY', defaultValue: ''),
    this.pipelineEndpoint = const String.fromEnvironment(
      'BHASHINI_PIPELINE_URL',
      defaultValue: '',
    ),
    this.aldConfig = const BhashiniServiceConfig(
      supportedLanguages: ['en', 'hi', 'te'],
    ),
    this.asrConfig = const BhashiniServiceConfig(
      supportedLanguages: ['en', 'hi', 'te'],
    ),
    this.nmtConfig = const BhashiniServiceConfig(
      supportedLanguages: ['en', 'hi', 'te'],
    ),
    this.ttsConfig = const BhashiniServiceConfig(
      supportedLanguages: ['en', 'hi', 'te'],
    ),
    this.useServerSideProxy = true,
  });

  /// User ID issued by Bhashini developer portal.
  /// Kept empty in client binaries; populated server-side in Supabase Edge Functions.
  final String userId;

  /// Pipeline API key issued by Bhashini developer portal.
  final String apiKey;

  /// Inference API key returned by Bhashini pipeline computation.
  final String inferenceApiKey;

  /// Root URL for the Bhashini pipeline endpoint (or Edge Function proxy).
  final String pipelineEndpoint;

  /// Audio Language Identification config.
  final BhashiniServiceConfig aldConfig;

  /// Automatic Speech Recognition config.
  final BhashiniServiceConfig asrConfig;

  /// Machine Translation config.
  final BhashiniServiceConfig nmtConfig;

  /// Text to Speech config.
  final BhashiniServiceConfig ttsConfig;

  /// Whether to route all requests via secure Supabase Edge Function (default true).
  final bool useServerSideProxy;

  /// Checks if live Bhashini credentials are fully provided and verified.
  /// Remains false during approval pending phase.
  bool get isConfigured {
    if (useServerSideProxy) {
      // With server-side proxy, client does not hold credentials directly.
      // Returns true only when a valid proxy endpoint is configured.
      return pipelineEndpoint.trim().isNotEmpty;
    }
    return userId.trim().isNotEmpty &&
        apiKey.trim().isNotEmpty &&
        pipelineEndpoint.trim().isNotEmpty;
  }

  /// Validates configuration and returns a descriptive error message or null if valid.
  String? validate() {
    if (!isConfigured) {
      return 'Bhashini configuration pending official approval. '
          'No production credentials or proxy endpoints configured.';
    }
    return null;
  }

  /// Checks if a specific Bhashini sub-service supports a language.
  bool isLanguageSupported(BhashiniServiceType service, String langCode) {
    switch (service) {
      case BhashiniServiceType.ald:
        return aldConfig.isLanguageSupported(langCode);
      case BhashiniServiceType.asr:
        return asrConfig.isLanguageSupported(langCode);
      case BhashiniServiceType.nmt:
        return nmtConfig.isLanguageSupported(langCode);
      case BhashiniServiceType.tts:
        return ttsConfig.isLanguageSupported(langCode);
    }
  }

  BhashiniConfig copyWith({
    String? userId,
    String? apiKey,
    String? inferenceApiKey,
    String? pipelineEndpoint,
    BhashiniServiceConfig? aldConfig,
    BhashiniServiceConfig? asrConfig,
    BhashiniServiceConfig? nmtConfig,
    BhashiniServiceConfig? ttsConfig,
    bool? useServerSideProxy,
  }) {
    return BhashiniConfig(
      userId: userId ?? this.userId,
      apiKey: apiKey ?? this.apiKey,
      inferenceApiKey: inferenceApiKey ?? this.inferenceApiKey,
      pipelineEndpoint: pipelineEndpoint ?? this.pipelineEndpoint,
      aldConfig: aldConfig ?? this.aldConfig,
      asrConfig: asrConfig ?? this.asrConfig,
      nmtConfig: nmtConfig ?? this.nmtConfig,
      ttsConfig: ttsConfig ?? this.ttsConfig,
      useServerSideProxy: useServerSideProxy ?? this.useServerSideProxy,
    );
  }
}
