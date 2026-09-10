import '../models/officer_queue_item.dart';
import 'procurement_state_service.dart';

/// Status codes for QR token validation.
enum QrValidationStatus {
  valid,
  invalidFormat,
  tokenNotFound,
  wrongCentre,
  alreadyCheckedIn,
  expiredOrCancelled,
  lateArrivalStandby,
}

/// Structured validation response returned by [QrValidationService].
class QrValidationResult {
  final bool isValid;
  final QrValidationStatus status;
  final String? tokenNumber;
  final String? bookingId;
  final String? centreName;
  final String? slotTime;
  final OfficerQueueItem? queueItem;
  final String messageEn;
  final String messageHi;
  final String messageTe;

  const QrValidationResult({
    required this.isValid,
    required this.status,
    this.tokenNumber,
    this.bookingId,
    this.centreName,
    this.slotTime,
    this.queueItem,
    required this.messageEn,
    required this.messageHi,
    required this.messageTe,
  });

  String get userMessage => messageEn;

  String getLocalizedMessage({bool isHindi = false, bool isTelugu = false}) {
    if (isTelugu) return messageTe;
    if (isHindi) return messageHi;
    return messageEn;
  }
}

/// Service managing non-sensitive QR payload creation and server-side/centre validation.
class QrValidationService {
  static const String qrPrefix = 'KISANSETU:V1';

  /// Generates a safe, non-sensitive QR payload string for a farmer's procurement booking.
  static String generateQrPayload({
    required String bookingId,
    required String tokenNumber,
    required String centreName,
    required String slotTime,
  }) {
    // Non-sensitive: contains only identifiers and logistics routing
    return '$qrPrefix:$bookingId:$tokenNumber:$centreName:$slotTime';
  }

  /// Parses and validates a scanned QR payload against the current procurement centre state.
  static QrValidationResult validate({
    required String rawPayload,
    required String currentCentreName,
  }) {
    final trimmed = rawPayload.trim();
    if (trimmed.isEmpty) {
      return const QrValidationResult(
        isValid: false,
        status: QrValidationStatus.invalidFormat,
        messageEn: 'Scanned QR code is empty or unreadable.',
        messageHi: 'स्कैन किया गया क्यूआर कोड खाली या पढ़ने योग्य नहीं है।',
        messageTe: 'స్కాన్ చేసిన క్యూఆర్ కోడ్ ఖాళీగా ఉంది లేదా చదవలేకపోతున్నాము.',
      );
    }

    String tokenNumber = '';
    String? bookingId;
    String? centreName;
    String? slotTime;

    // Check standard KisanSetu QR format: KISANSETU:V1:<bookingId>:<token>:<centre>:<slot>
    if (trimmed.startsWith('$qrPrefix:')) {
      final parts = trimmed.split(':');
      if (parts.length >= 4) {
        bookingId = parts[2];
        tokenNumber = parts[3];
        if (parts.length >= 5) centreName = parts[4];
        if (parts.length >= 6) slotTime = parts.sublist(5).join(':');
      } else {
        return const QrValidationResult(
          isValid: false,
          status: QrValidationStatus.invalidFormat,
          messageEn: 'Invalid KisanSetu QR code format.',
          messageHi: 'अमान्य किसानसेतु क्यूआर कोड प्रारूप।',
          messageTe: 'చెల్లని కిసాన్‌సేతు క్యూఆర్ కోడ్ ఫార్మాట్.',
        );
      }
    } else if (trimmed.toUpperCase().startsWith('TK-') ||
        RegExp(r'^[0-9A-Z-]+$').hasMatch(trimmed)) {
      // Direct token entry or legacy token scan (e.g. TK-8492)
      tokenNumber = trimmed.toUpperCase();
    } else {
      return const QrValidationResult(
        isValid: false,
        status: QrValidationStatus.invalidFormat,
        messageEn: 'Unrecognized QR code format. Not a KisanSetu token.',
        messageHi: 'अपरिचित क्यूआर कोड। यह किसानसेतु टोकन नहीं है।',
        messageTe: 'గుర్తించబడని క్యూఆర్ కోడ్. ఇది కిసాన్‌సేతు టోకెన్ కాదు.',
      );
    }

    // Centre verification (Do not trust QR contents alone, verify match)
    if (centreName != null &&
        centreName.isNotEmpty &&
        centreName.toLowerCase() != currentCentreName.toLowerCase()) {
      return QrValidationResult(
        isValid: false,
        status: QrValidationStatus.wrongCentre,
        tokenNumber: tokenNumber,
        centreName: centreName,
        messageEn:
            'Wrong Centre: Token booked for another centre ("$centreName"). Current centre is "$currentCentreName".',
        messageHi:
            'गलत खरीद केंद्र: यह टोकन दूसरे केंद्र ("$centreName") के लिए बुक है। वर्तमान केंद्र "$currentCentreName" है।',
        messageTe:
            'తప్పు కేంద్రం: టోకెన్ మరొక కేంద్రం ("$centreName") కోసం బుక్ చేయబడింది. ప్రస్తుత కేంద్రం "$currentCentreName".',
      );
    }

    // Lookup token in ProcurementStateService queue
    final state = ProcurementStateService();
    final queueItems = state.queue;
    final itemIndex =
        queueItems.indexWhere((item) => item.tokenNumber == tokenNumber);

    if (itemIndex == -1) {
      return QrValidationResult(
        isValid: false,
        status: QrValidationStatus.tokenNotFound,
        tokenNumber: tokenNumber,
        messageEn: 'Token $tokenNumber not found in active procurement records.',
        messageHi: 'टोकन $tokenNumber खरीद रिकॉर्ड में नहीं मिला।',
        messageTe: 'సక్రియ సేకరణ రికార్డులలో టోకెన్ $tokenNumber కనుగొనబడలేదు.',
      );
    }

    final item = queueItems[itemIndex];

    final currentStatus = item.status.toLowerCase();

    // Duplicate check-in verification
    if (item.checkInStatus.toLowerCase() == 'checked in' ||
        item.checkInStatus.toLowerCase() == 'already used') {
      return QrValidationResult(
        isValid: false,
        status: QrValidationStatus.alreadyCheckedIn,
        tokenNumber: tokenNumber,
        queueItem: item,
        messageEn:
            'Token $tokenNumber is already checked in (${item.checkInStatus}).',
        messageHi:
            'टोकन $tokenNumber का चेक-इन पहले ही हो चुका है (${item.checkInStatus})।',
        messageTe:
            'టోకెన్ $tokenNumber ఇప్పటికే తనిఖీ చేయబడింది (${item.checkInStatus}).',
      );
    }

    if (currentStatus == 'completed' ||
        currentStatus == 'payment completed' ||
        currentStatus == 'cancelled' ||
        currentStatus == 'expired') {
      return QrValidationResult(
        isValid: false,
        status: QrValidationStatus.expiredOrCancelled,
        tokenNumber: tokenNumber,
        queueItem: item,
        messageEn:
            'Token $tokenNumber is already completed or expired (${item.status}).',
        messageHi:
            'टोकन $tokenNumber पहले ही पूर्ण या समाप्त हो चुका है (${item.status})।',
        messageTe:
            'టోకెన్ $tokenNumber ఇప్పటికే పూర్తయింది లేదా గడువు ముగిసింది (${item.status}).',
      );
    }

    // Valid check-in candidate!
    return QrValidationResult(
      isValid: true,
      status: QrValidationStatus.valid,
      tokenNumber: tokenNumber,
      bookingId: bookingId ?? 'BOOK-001',
      centreName: currentCentreName,
      slotTime: slotTime ?? item.bookedSlot,
      queueItem: item,
      messageEn: 'Token verified successfully. Ready for check-in.',
      messageHi: 'टोकन सफलतापूर्वक सत्यापित। चेक-इन के लिए तैयार।',
      messageTe: 'టోకెన్ విజయవంతంగా ధృవీకరించబడింది. చెక్-ఇన్‌కు సిద్ధంగా ఉంది.',
    );
  }
}
