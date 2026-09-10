import 'dart:convert';

/// Essential procurement information cached locally for offline access.
///
/// Designed to ensure farmers can view their digital pass, booking slot,
/// centre location, and last-known status even with zero internet connectivity.
/// Never stores sensitive credentials or auth secrets.
class OfflineEssentialInfoModel {
  final String farmerName;
  final String farmerPhone;
  final String cropName;
  final String quantity;
  final String centreName;
  final String centreAddress;
  final double centreDistanceKm;
  final String tokenNumber;
  final String bookingId;
  final String bookingDate;
  final String bookedSlotTime;
  final String qrPayload;
  final int lastKnownPeopleAhead;
  final int lastKnownTotalInQueue;
  final int lastKnownEstimatedWaitMinutes;
  final String lastKnownCentreStatus;
  final String lastKnownGoTimeRecommendation;
  final String lastKnownRecommendedDepartureTime;
  final String lastKnownExpectedTurnTime;
  final String lastKnownWaitReason;
  final String lifecycleStatus;
  final String checkInStatus;
  final String paymentStatus;
  final double netPayable;
  final String paymentReference;
  final String paymentDate;
  final List<String> importantNotifications;
  final DateTime lastUpdatedTimestamp;

  const OfflineEssentialInfoModel({
    required this.farmerName,
    required this.farmerPhone,
    required this.cropName,
    required this.quantity,
    required this.centreName,
    this.centreAddress = 'Main Mandi Yard, Gate 2, GT Road',
    this.centreDistanceKm = 4.2,
    required this.tokenNumber,
    required this.bookingId,
    required this.bookingDate,
    required this.bookedSlotTime,
    required this.qrPayload,
    required this.lastKnownPeopleAhead,
    required this.lastKnownTotalInQueue,
    required this.lastKnownEstimatedWaitMinutes,
    required this.lastKnownCentreStatus,
    required this.lastKnownGoTimeRecommendation,
    required this.lastKnownRecommendedDepartureTime,
    required this.lastKnownExpectedTurnTime,
    required this.lastKnownWaitReason,
    required this.lifecycleStatus,
    required this.checkInStatus,
    required this.paymentStatus,
    required this.netPayable,
    required this.paymentReference,
    required this.paymentDate,
    this.importantNotifications = const [],
    required this.lastUpdatedTimestamp,
  });

  /// Formatted time string: "10:42 AM"
  String get lastUpdatedFormatted {
    final hour = lastUpdatedTimestamp.hour;
    final minute = lastUpdatedTimestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12
        ? hour - 12
        : (hour == 0 ? 12 : hour);
    return '$formattedHour:$minute $period';
  }

  /// Whether the cached information is considered stale (> 30 minutes old).
  bool get isStale =>
      DateTime.now().difference(lastUpdatedTimestamp).inMinutes >= 30;

  /// Creates a copy with optional updated fields.
  OfflineEssentialInfoModel copyWith({
    String? farmerName,
    String? farmerPhone,
    String? cropName,
    String? quantity,
    String? centreName,
    String? centreAddress,
    double? centreDistanceKm,
    String? tokenNumber,
    String? bookingId,
    String? bookingDate,
    String? bookedSlotTime,
    String? qrPayload,
    int? lastKnownPeopleAhead,
    int? lastKnownTotalInQueue,
    int? lastKnownEstimatedWaitMinutes,
    String? lastKnownCentreStatus,
    String? lastKnownGoTimeRecommendation,
    String? lastKnownRecommendedDepartureTime,
    String? lastKnownExpectedTurnTime,
    String? lastKnownWaitReason,
    String? lifecycleStatus,
    String? checkInStatus,
    String? paymentStatus,
    double? netPayable,
    String? paymentReference,
    String? paymentDate,
    List<String>? importantNotifications,
    DateTime? lastUpdatedTimestamp,
  }) {
    return OfflineEssentialInfoModel(
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      cropName: cropName ?? this.cropName,
      quantity: quantity ?? this.quantity,
      centreName: centreName ?? this.centreName,
      centreAddress: centreAddress ?? this.centreAddress,
      centreDistanceKm: centreDistanceKm ?? this.centreDistanceKm,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      bookingId: bookingId ?? this.bookingId,
      bookingDate: bookingDate ?? this.bookingDate,
      bookedSlotTime: bookedSlotTime ?? this.bookedSlotTime,
      qrPayload: qrPayload ?? this.qrPayload,
      lastKnownPeopleAhead: lastKnownPeopleAhead ?? this.lastKnownPeopleAhead,
      lastKnownTotalInQueue:
          lastKnownTotalInQueue ?? this.lastKnownTotalInQueue,
      lastKnownEstimatedWaitMinutes:
          lastKnownEstimatedWaitMinutes ?? this.lastKnownEstimatedWaitMinutes,
      lastKnownCentreStatus:
          lastKnownCentreStatus ?? this.lastKnownCentreStatus,
      lastKnownGoTimeRecommendation:
          lastKnownGoTimeRecommendation ?? this.lastKnownGoTimeRecommendation,
      lastKnownRecommendedDepartureTime: lastKnownRecommendedDepartureTime ??
          this.lastKnownRecommendedDepartureTime,
      lastKnownExpectedTurnTime:
          lastKnownExpectedTurnTime ?? this.lastKnownExpectedTurnTime,
      lastKnownWaitReason: lastKnownWaitReason ?? this.lastKnownWaitReason,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      checkInStatus: checkInStatus ?? this.checkInStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      netPayable: netPayable ?? this.netPayable,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentDate: paymentDate ?? this.paymentDate,
      importantNotifications:
          importantNotifications ?? this.importantNotifications,
      lastUpdatedTimestamp: lastUpdatedTimestamp ?? this.lastUpdatedTimestamp,
    );
  }

  /// Converts model to JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'cropName': cropName,
      'quantity': quantity,
      'centreName': centreName,
      'centreAddress': centreAddress,
      'centreDistanceKm': centreDistanceKm,
      'tokenNumber': tokenNumber,
      'bookingId': bookingId,
      'bookingDate': bookingDate,
      'bookedSlotTime': bookedSlotTime,
      'qrPayload': qrPayload,
      'lastKnownPeopleAhead': lastKnownPeopleAhead,
      'lastKnownTotalInQueue': lastKnownTotalInQueue,
      'lastKnownEstimatedWaitMinutes': lastKnownEstimatedWaitMinutes,
      'lastKnownCentreStatus': lastKnownCentreStatus,
      'lastKnownGoTimeRecommendation': lastKnownGoTimeRecommendation,
      'lastKnownRecommendedDepartureTime': lastKnownRecommendedDepartureTime,
      'lastKnownExpectedTurnTime': lastKnownExpectedTurnTime,
      'lastKnownWaitReason': lastKnownWaitReason,
      'lifecycleStatus': lifecycleStatus,
      'checkInStatus': checkInStatus,
      'paymentStatus': paymentStatus,
      'netPayable': netPayable,
      'paymentReference': paymentReference,
      'paymentDate': paymentDate,
      'importantNotifications': importantNotifications,
      'lastUpdatedTimestamp': lastUpdatedTimestamp.toIso8601String(),
    };
  }

  /// Deserializes model from JSON Map with null/fallback safety.
  factory OfflineEssentialInfoModel.fromJson(Map<String, dynamic> json) {
    return OfflineEssentialInfoModel(
      farmerName: json['farmerName'] as String? ?? 'Ramesh Kumar',
      farmerPhone: json['farmerPhone'] as String? ?? '9876543210',
      cropName: json['cropName'] as String? ?? 'Wheat',
      quantity: json['quantity'] as String? ?? '50 Quintals',
      centreName:
          json['centreName'] as String? ?? 'Example Procurement Centre',
      centreAddress: json['centreAddress'] as String? ??
          'Main Mandi Yard, Gate 2, GT Road',
      centreDistanceKm:
          (json['centreDistanceKm'] as num?)?.toDouble() ?? 4.2,
      tokenNumber: json['tokenNumber'] as String? ?? 'TK-8492',
      bookingId: json['bookingId'] as String? ?? 'BK-8492',
      bookingDate: json['bookingDate'] as String? ?? '09 Sep 2026',
      bookedSlotTime: json['bookedSlotTime'] as String? ?? '11:30 AM',
      qrPayload: json['qrPayload'] as String? ?? '',
      lastKnownPeopleAhead: json['lastKnownPeopleAhead'] as int? ?? 7,
      lastKnownTotalInQueue: json['lastKnownTotalInQueue'] as int? ?? 8,
      lastKnownEstimatedWaitMinutes:
          json['lastKnownEstimatedWaitMinutes'] as int? ?? 35,
      lastKnownCentreStatus:
          json['lastKnownCentreStatus'] as String? ?? 'Open • Normal',
      lastKnownGoTimeRecommendation:
          json['lastKnownGoTimeRecommendation'] as String? ?? 'Leave Now',
      lastKnownRecommendedDepartureTime:
          json['lastKnownRecommendedDepartureTime'] as String? ?? '10:45 AM',
      lastKnownExpectedTurnTime:
          json['lastKnownExpectedTurnTime'] as String? ?? '11:45 AM',
      lastKnownWaitReason: json['lastKnownWaitReason'] as String? ?? '',
      lifecycleStatus: json['lifecycleStatus'] as String? ?? 'Waiting',
      checkInStatus: json['checkInStatus'] as String? ?? 'Not Checked In',
      paymentStatus: json['paymentStatus'] as String? ?? 'Pending',
      netPayable: (json['netPayable'] as num?)?.toDouble() ?? 114205.0,
      paymentReference:
          json['paymentReference'] as String? ?? 'PAY-2026-8492',
      paymentDate: json['paymentDate'] as String? ?? '09 Sep 2026',
      importantNotifications: (json['importantNotifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastUpdatedTimestamp: json['lastUpdatedTimestamp'] != null
          ? DateTime.tryParse(json['lastUpdatedTimestamp'] as String) ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  /// Encodes to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Decodes from JSON string safely.
  static OfflineEssentialInfoModel? tryFromJsonString(String rawJson) {
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      return OfflineEssentialInfoModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Trilingual speech guidance for voice assistant when offline.
  String toSpeechSummary({
    String? language,
    bool isHindi = false,
    bool isTelugu = false,
  }) {
    final useTelugu = isTelugu || language == 'te';
    final useHindi = isHindi || language == 'hi';

    if (useTelugu) {
      return 'ఆఫ్‌లైన్ ముఖ్యమైన సమాచారం. మీ టోకెన్ $tokenNumber, రైతు $farmerName. '
          'పంట: $cropName ($quantity). '
          '$centreName లో బుక్ చేసిన స్లాట్ $bookedSlotTime. '
          'చివరిగా తెలిసిన స్థితి: $lifecycleStatus. చివరిగా అప్‌డేట్ చేసిన సమయం: $lastUpdatedFormatted.';
    }
    if (useHindi) {
      return 'ऑफ़लाइन आवश्यक जानकारी। आपका टोकन $tokenNumber, किसान $farmerName। '
          'फसल: $cropName ($quantity)। '
          '$centreName में बुक किया गया स्लॉट $bookedSlotTime। '
          'अंतिम ज्ञात स्थिति: $lifecycleStatus। अंतिम अपडेट समय: $lastUpdatedFormatted।';
    }
    return 'Offline Essential Information. Token $tokenNumber for $farmerName. '
        'Crop: $cropName ($quantity). '
        'Booked slot $bookedSlotTime at $centreName. '
        'Last known status: $lifecycleStatus. Last updated at $lastUpdatedFormatted.';
  }
}
