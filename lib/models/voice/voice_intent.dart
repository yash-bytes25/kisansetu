// KisanSetu (SIH26032) - Voice Assistant Intent Model
// Structured intent and entity representations for farmer voice interactions.

/// Supported intent types for KisanSetu Voice Assistant.
enum VoiceIntentType {
  /// Book a new procurement slot.
  bookSlot,

  /// Query current active digital token or pass.
  getTokenStatus,

  /// Query booked slot details and timing.
  getSlot,

  /// Query personalized Go-Time departure advisory.
  getGoTime,

  /// Query live queue position and people ahead.
  getQueue,

  /// Query 7-stage procurement lifecycle progression.
  getProcurementStatus,

  /// Query DBT payment status and transaction reference.
  getPaymentStatus,

  /// Query historical payment receipts and disbursements.
  getPaymentHistory,

  /// Initiate a grievance or dispute report.
  startDispute,

  /// Request recommendations for less congested alternative centres.
  recommendCentre,

  /// Check current operating status of assigned procurement centre.
  getCentreStatus,

  /// Change or update selected crop.
  changeCrop,

  /// Change or update produce volume.
  changeQuantity,

  /// Query registered farmer profile, KYC, or bank details.
  getProfileInfo,

  /// General help or guidance about KisanSetu features.
  help,

  /// Unrecognized or ambiguous speech.
  unknown,
}

/// Represents an interpreted voice interaction with extracted entities.
class VoiceIntent {
  final VoiceIntentType intent;
  final String? crop;
  final double? quantity;
  final String quantityUnit;
  final String? date;
  final String? time;
  final String? centreId;
  final String? centreName;
  final String? bookingId;
  final double confidence;
  final List<String> _explicitMissingFields;
  final String userMessage;
  final bool requiresConfirmation;

  const VoiceIntent({
    required this.intent,
    this.crop,
    this.quantity,
    this.quantityUnit = 'Quintals',
    this.date,
    this.time,
    this.centreId,
    this.centreName,
    this.bookingId,
    this.confidence = 1.0,
    List<String>? missingFields,
    this.userMessage = '',
    this.requiresConfirmation = false,
  }) : _explicitMissingFields = missingFields ?? const [];

  List<String> get missingFields {
    if (_explicitMissingFields.isNotEmpty) return _explicitMissingFields;
    if (intent == VoiceIntentType.bookSlot) {
      final missing = <String>[];
      if (crop == null || crop!.isEmpty) missing.add('crop');
      if (quantity == null || quantity! <= 0) missing.add('quantity');
      if (date == null || date!.isEmpty) missing.add('date');
      return missing;
    }
    return const [];
  }

  /// Factory for empty or unrecognized intent.
  factory VoiceIntent.unknown({String message = ''}) {
    return VoiceIntent(
      intent: VoiceIntentType.unknown,
      userMessage: message,
      confidence: 0.0,
      requiresConfirmation: false,
    );
  }

  /// Whether this intent represents an actionable task requiring confirmation.
  bool get isActionable =>
      intent == VoiceIntentType.bookSlot ||
      intent == VoiceIntentType.changeCrop ||
      intent == VoiceIntentType.changeQuantity ||
      intent == VoiceIntentType.startDispute;

  /// Whether this intent is an informational query.
  bool get isInformation => !isActionable && intent != VoiceIntentType.unknown;

  /// Whether all necessary fields are present for execution.
  bool get isComplete => missingFields.isEmpty;

  /// Creates a copy of this intent with updated or corrected values.
  VoiceIntent copyWith({
    VoiceIntentType? intent,
    String? crop,
    double? quantity,
    String? quantityUnit,
    String? date,
    String? time,
    String? centreId,
    String? centreName,
    String? bookingId,
    double? confidence,
    List<String>? missingFields,
    String? userMessage,
    bool? requiresConfirmation,
  }) {
    return VoiceIntent(
      intent: intent ?? this.intent,
      crop: crop ?? this.crop,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      date: date ?? this.date,
      time: time ?? this.time,
      centreId: centreId ?? this.centreId,
      centreName: centreName ?? this.centreName,
      bookingId: bookingId ?? this.bookingId,
      confidence: confidence ?? this.confidence,
      missingFields: missingFields ?? this.missingFields,
      userMessage: userMessage ?? this.userMessage,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
    );
  }

  Map<String, dynamic> toJson() => {
        'intent': intent.name,
        'crop': crop,
        'quantity': quantity,
        'quantityUnit': quantityUnit,
        'date': date,
        'time': time,
        'centreId': centreId,
        'centreName': centreName,
        'bookingId': bookingId,
        'confidence': confidence,
        'missingFields': missingFields,
        'userMessage': userMessage,
        'requiresConfirmation': requiresConfirmation,
      };

  factory VoiceIntent.fromJson(Map<String, dynamic> json) {
    return VoiceIntent(
      intent: VoiceIntentType.values.firstWhere(
        (e) => e.name == json['intent'],
        orElse: () => VoiceIntentType.unknown,
      ),
      crop: json['crop'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      quantityUnit: json['quantityUnit'] as String? ?? 'Quintals',
      date: json['date'] as String?,
      time: json['time'] as String?,
      centreId: json['centreId'] as String?,
      centreName: json['centreName'] as String?,
      bookingId: json['bookingId'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      missingFields: (json['missingFields'] as List<dynamic>?)?.cast<String>() ?? const [],
      userMessage: json['userMessage'] as String? ?? '',
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'VoiceIntent($intent, crop: $crop, qty: $quantity $quantityUnit, date: $date, missing: $missingFields)';
}
