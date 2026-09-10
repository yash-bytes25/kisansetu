import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'payment_calculation_service.dart';

/// In-memory prototype service for KisanSetu proactive farmer notifications.
///
/// Designed cleanly as a ChangeNotifier to power the Farmer Message Centre,
/// Dashboard preview, unread badges, and voice assistance.
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal() {
    reset();
  }

  final List<NotificationModel> _notifications = [];
  final Set<String> _deduplicationKeys = {};

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Resets notifications to the initial session baseline.
  void reset() {
    _notifications.clear();
    _deduplicationKeys.clear();

    // Default session baseline notifications
    _notifications.addAll([
      const NotificationModel(
        id: 'init_booking_1',
        type: NotificationType.bookingConfirmed,
        action: NotificationActionType.myToken,
        titleEn: 'Booking Confirmed',
        titleHi: 'बुकिंग की पुष्टि',
        titleTe: 'బుకింగ్ ధృవీకరించబడింది',
        messageEn:
            'Your procurement slot is confirmed.\nToken: TK-8493 • Slot: 11:30 AM\nCentre: Example Procurement Centre',
        messageHi:
            'आपका प्रोक्योरमेंट स्लॉट पक्का हो गया है।\nटोकन: TK-8493 • समय: 11:30 AM\nकेंद्र: Example Procurement Centre',
        messageTe:
            'మీ సేకరణ స్లాట్ ధృవీకరించబడింది.\nటోకెన్: TK-8493 • స్లాట్: 11:30 AM\nకేంద్రం: Example Procurement Centre',
        timestamp: '10:00 AM',
        icon: Icons.check_circle_rounded,
        tokenNumber: 'TK-8493',
        isRead: false,
      ),
      const NotificationModel(
        id: 'init_queue_2',
        type: NotificationType.queueUpdated,
        action: NotificationActionType.myToken,
        titleEn: 'Queue Update',
        titleHi: 'कतार अपडेट',
        titleTe: 'క్యూ అప్‌డేట్',
        messageEn:
            'Your queue position has changed.\nPeople ahead: 7 • Estimated wait: 35 min',
        messageHi:
            'आपकी कतार की स्थिति बदल गई है।\nआगे लोग: 7 • अनुमानित प्रतीक्षा: 35 मिनट',
        messageTe:
            'మీ క్యూ స్థానం మారింది.\nముందున్నవారు: 7 • అంచనా వేచి ఉండే సమయం: 35 నిమిషాలు',
        timestamp: '10:15 AM',
        icon: Icons.people_alt_rounded,
        tokenNumber: 'TK-8493',
        isRead: false,
      ),
      const NotificationModel(
        id: 'init_departure_3',
        type: NotificationType.goodTimeToLeave,
        action: NotificationActionType.goTimeDetails,
        titleEn: 'When To Leave',
        titleHi: 'जाने का सही समय',
        titleTe: 'బయలుదేరడానికి సమయం',
        messageEn:
            'Good time to leave.\nRecommended departure: 10:55 AM • Expected turn: 11:30 AM',
        messageHi:
            'निकलने का सही समय।\nअनुशंसित प्रस्थान: 10:55 AM • संभावित बारी: 11:30 AM',
        messageTe:
            'బయలుదేరడానికి మంచి సమయం.\nసిఫార్సు చేయబడిన ప్రయాణం: 10:55 AM • ఆశించిన వంతు: 11:30 AM',
        timestamp: '10:30 AM',
        icon: Icons.departure_board_rounded,
        tokenNumber: 'TK-8493',
        isRead: false,
      ),
    ]);

    _deduplicationKeys.add('bookingConfirmed_TK-8493_11:30 AM');
    _deduplicationKeys.add('queueUpdated_7');
    _deduplicationKeys.add('goodTimeToLeave_10:55 AM');

    notifyListeners();
  }

  /// Marks a specific notification as read.
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Marks all notifications as read.
  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Adds a notification with deduplication checks.
  void addNotification(NotificationModel model, {String? deduplicationKey}) {
    if (deduplicationKey != null) {
      if (_deduplicationKeys.contains(deduplicationKey)) {
        return; // Suppress duplicate notification
      }
      _deduplicationKeys.add(deduplicationKey);
    }
    // Insert newest on top
    _notifications.insert(0, model);
    notifyListeners();
  }

  /// Helper: General or Realtime alert.
  void notifyGeneralAlert({
    required String titleEn,
    required String messageEn,
    String titleHi = '',
    String messageHi = '',
    String titleTe = '',
    String messageTe = '',
    String? tokenNumber,
  }) {
    addNotification(
      NotificationModel(
        id: 'notif_gen_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.bookingConfirmed,
        action: NotificationActionType.none,
        titleEn: titleEn,
        titleHi: titleHi.isNotEmpty ? titleHi : titleEn,
        titleTe: titleTe.isNotEmpty ? titleTe : titleEn,
        messageEn: messageEn,
        messageHi: messageHi.isNotEmpty ? messageHi : messageEn,
        messageTe: messageTe.isNotEmpty ? messageTe : messageEn,
        timestamp: 'Just now',
        icon: Icons.notifications_rounded,
        tokenNumber: tokenNumber,
      ),
    );
  }

  /// Helper: Farmer confirms a new slot booking.
  void notifyBookingConfirmed({
    required String tokenNumber,
    required String slotTime,
    required String centreName,
  }) {
    final key = 'bookingConfirmed_${tokenNumber}_$slotTime';
    addNotification(
      NotificationModel(
        id: 'notif_book_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.bookingConfirmed,
        action: NotificationActionType.myToken,
        titleEn: 'Booking Confirmed',
        titleHi: 'बुकिंग की पुष्टि',
        titleTe: 'బుకింగ్ ధృవీకరించబడింది',
        messageEn:
            'Your procurement slot is confirmed.\nToken: $tokenNumber • Slot: $slotTime\nCentre: $centreName',
        messageHi:
            'आपका प्रोक्योरमेंट स्लॉट पक्का हो गया है।\nटोकन: $tokenNumber • समय: $slotTime\nकेंद्र: $centreName',
        messageTe:
            'మీ సేకరణ స్లాట్ ధృవీకరించబడింది.\nటోకెన్: $tokenNumber • స్లాట్: $slotTime\nకేంద్రం: $centreName',
        timestamp: 'Just now',
        icon: Icons.check_circle_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Queue position changes significantly.
  void notifyQueueUpdate({
    required String tokenNumber,
    required int peopleAhead,
    required String estimatedWait,
  }) {
    final key = 'queueUpdated_$peopleAhead';
    addNotification(
      NotificationModel(
        id: 'notif_queue_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.queueUpdated,
        action: NotificationActionType.myToken,
        titleEn: 'Queue Update',
        titleHi: 'कतार अपडेट',
        titleTe: 'క్యూ అప్‌డేట్',
        messageEn:
            'Your queue position has changed.\nPeople ahead: $peopleAhead • Estimated wait: $estimatedWait',
        messageHi:
            'आपकी कतार की स्थिति बदल गई है।\nआगे लोग: $peopleAhead • अनुमानित प्रतीक्षा: $estimatedWait',
        messageTe:
            'మీ క్యూ స్థానం మారింది.\nముందున్నవారు: $peopleAhead • అంచనా వేచి ఉండే సమయం: $estimatedWait',
        timestamp: 'Just now',
        icon: Icons.people_alt_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Departure recommendation alert.
  void notifyWhenToLeave({
    required String tokenNumber,
    required String departureTime,
    required String expectedTurn,
  }) {
    final key = 'goodTimeToLeave_$departureTime';
    addNotification(
      NotificationModel(
        id: 'notif_leave_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.goodTimeToLeave,
        action: NotificationActionType.goTimeDetails,
        titleEn: 'When To Leave',
        titleHi: 'जाने का सही समय',
        titleTe: 'బయలుదేరడానికి సమయం',
        messageEn:
            'Good time to leave.\nRecommended departure: $departureTime • Expected turn: $expectedTurn',
        messageHi:
            'निकलने का सही समय।\nअनुशंसित प्रस्थान: $departureTime • संभावित बारी: $expectedTurn',
        messageTe:
            'బయలుదేరడానికి మంచి సమయం.\nసిఫార్సు చేయబడిన ప్రయాణం: $departureTime • ఆశించిన వంతు: $expectedTurn',
        timestamp: 'Just now',
        icon: Icons.departure_board_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Centre status disruptions (Busy / Delayed).
  void notifyCentreStatus({
    required String status,
    required String reasonEn,
    required String reasonHi,
    String? reasonTe,
    String? tokenNumber,
  }) {
    final key = 'centreStatus_${status}_${DateTime.now().minute}';
    final isDelayed = status.contains('Delayed');
    addNotification(
      NotificationModel(
        id: 'notif_centre_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.centreStatus,
        action: NotificationActionType.goTimeDetails,
        titleEn: isDelayed ? 'Procurement Delayed' : 'Centre Busy',
        titleHi: isDelayed ? 'प्रोक्योरमेंट में देरी' : 'केंद्र व्यस्त है',
        titleTe: isDelayed ? 'సేకరణ ఆలస్యం అయింది' : 'కేంద్రంలో రద్దీ ఉంది',
        messageEn: reasonEn,
        messageHi: reasonHi,
        messageTe: reasonTe ?? reasonEn,
        timestamp: 'Just now',
        icon: isDelayed
            ? Icons.warning_amber_rounded
            : Icons.hourglass_top_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Queue moves significantly faster.
  void notifyQueueImprovement({
    required String tokenNumber,
    int? waitMinutes,
    int? newAhead,
    int? expectedWaitMinutes,
    String? turnTime,
  }) {
    final effectiveWait = waitMinutes ?? expectedWaitMinutes ?? 0;
    final key = 'queueImprovement_${tokenNumber}_$effectiveWait';
    addNotification(
      NotificationModel(
        id: 'notif_queue_imp_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.queueUpdated,
        action: NotificationActionType.goTimeDetails,
        titleEn: 'Queue Moving Faster',
        titleHi: 'कतार तेजी से आगे बढ़ रही है',
        titleTe: 'క్యూ వేగంగా కదులుతోంది',
        messageEn: 'Your expected waiting time has reduced to $effectiveWait minutes.',
        messageHi: 'आपकी अनुमानित प्रतीक्षा अवधि घटकर $effectiveWait मिनट हो गई है।',
        messageTe: 'మీ అంచనా వేచి ఉండే సమయం $effectiveWait నిమిషాలకు తగ్గింది.',
        timestamp: 'Just now',
        icon: Icons.trending_down_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Centre delay notification.
  void notifyCentreDelay({
    required String tokenNumber,
    required int delayMinutes,
    String? updatedDeparture,
    String? newTurnTime,
  }) {
    final key = 'centreDelay_${tokenNumber}_$delayMinutes';
    addNotification(
      NotificationModel(
        id: 'notif_delay_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.centreStatus,
        action: NotificationActionType.goTimeDetails,
        titleEn: 'Centre Delayed',
        titleHi: 'केंद्र विलंबित है',
        titleTe: 'కేంద్రం ఆలస్యమైంది',
        messageEn:
            'Procurement is delayed by approximately $delayMinutes minutes. Your recommended arrival time has changed.',
        messageHi:
            'खरीद प्रक्रिया लगभग $delayMinutes मिनट विलंबित है। आपका अनुशंसित आगमन समय बदल गया है।',
        messageTe:
            'సేకరణ సుమారు $delayMinutes నిమిషాలు ఆలస్యమైంది. మీ సిఫార్సు చేసిన రాక సమయం మారింది.',
        timestamp: 'Just now',
        icon: Icons.warning_amber_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Centre temporarily stopped.
  void notifyCentreStopped({required String tokenNumber}) {
    final key = 'centreStopped_$tokenNumber';
    addNotification(
      NotificationModel(
        id: 'notif_stop_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.centreStatus,
        action: NotificationActionType.goTimeDetails,
        titleEn: 'Procurement Paused',
        titleHi: 'खरीद प्रक्रिया रुकी हुई है',
        titleTe: 'సేకరణ తాత్కాలికంగా ఆగిపోయింది',
        messageEn:
            'Procurement is temporarily stopped. Please do not travel yet. We will notify you when processing resumes.',
        messageHi:
            'खरीद प्रक्रिया अस्थायी रूप से रुकी हुई है। कृपया अभी यात्रा न करें। कार्य फिर से शुरू होने पर हम आपको सूचित करेंगे।',
        messageTe:
            'సేకరణ తాత్కాలికంగా ఆపివేయబడింది. దయచేసి ఇంకా బయలుదేరవద్దు. సేవలు పునఃప్రారంభమైనప్పుడు మేము తెలియజేస్తాము.',
        timestamp: 'Just now',
        icon: Icons.pause_circle_filled_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Physical procurement processing stages.
  void notifyProcurementProcessing({
    required String stageName,
    required String detailsEn,
    required String detailsHi,
    String? detailsTe,
    String? tokenNumber,
  }) {
    final key = 'procurementProcessing_$stageName';
    addNotification(
      NotificationModel(
        id: 'notif_proc_proc_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.procurementProcessing,
        action: NotificationActionType.procurementStatus,
        titleEn: 'Procurement: $stageName',
        titleHi: 'खरीद: $stageName',
        titleTe: 'సేకరణ: $stageName',
        messageEn: detailsEn,
        messageHi: detailsHi,
        messageTe: detailsTe ?? detailsEn,
        timestamp: 'Just now',
        icon: Icons.sync_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Produce accepted.
  void notifyProcurementAccepted({
    required String crop,
    required String quantity,
    String? tokenNumber,
  }) {
    final key = 'procurementAccepted_${tokenNumber}_$quantity';
    addNotification(
      NotificationModel(
        id: 'notif_proc_acc_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.procurementAccepted,
        action: NotificationActionType.procurementStatus,
        titleEn: 'Procurement Update',
        titleHi: 'खरीद अपडेट',
        titleTe: 'సేకరణ అప్‌డేట్',
        messageEn:
            'Your produce has been accepted.\n$crop: $quantity',
        messageHi:
            'आपकी उपज स्वीकार कर ली गई है।\n$crop: $quantity',
        messageTe:
            'మీ పంట ఆమోదించబడింది.\n$crop: $quantity',
        timestamp: 'Just now',
        icon: Icons.task_alt_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Payment initiated.
  void notifyPaymentInitiated({
    required double amount,
    required String reference,
    String? tokenNumber,
  }) {
    final formatted = PaymentCalculationService.formatCurrency(amount);
    final key = 'paymentInitiated_$reference';
    addNotification(
      NotificationModel(
        id: 'notif_pay_init_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.paymentInitiated,
        action: NotificationActionType.payment,
        titleEn: 'Payment Processing',
        titleHi: 'भुगतान प्रक्रियाधीन',
        titleTe: 'చెల్లింపు ప్రక్రియలో ఉంది',
        messageEn:
            'Direct Benefit Transfer initiated.\nAmount: $formatted • Reference: $reference',
        messageHi:
            'डीबीटी भुगतान प्रक्रिया शुरू हो गई है।\nराशि: $formatted • संदर्भ: $reference',
        messageTe:
            'DBT చెల్లింపు ప్రారంభించబడింది.\nమొత్తం: $formatted • రిఫరెన్స్: $reference',
        timestamp: 'Just now',
        icon: Icons.currency_rupee_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Payment completed.
  void notifyPaymentCompleted({
    required double amount,
    required String reference,
    String? tokenNumber,
  }) {
    final formatted = PaymentCalculationService.formatCurrency(amount);
    final key = 'paymentCompleted_$reference';
    addNotification(
      NotificationModel(
        id: 'notif_pay_comp_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.paymentCompleted,
        action: NotificationActionType.payment,
        titleEn: 'Payment Update',
        titleHi: 'भुगतान अपडेट',
        titleTe: 'చెల్లింపు పూర్తయింది',
        messageEn:
            'Your payment has been completed.\nAmount: $formatted • Reference: $reference',
        messageHi:
            'आपका भुगतान सफलतापूर्वक पूरा हो गया है।\nराशि: $formatted • संदर्भ: $reference',
        messageTe:
            'మీ చెల్లింపు విజయవంతంగా పూర్తయింది.\nమొత్తం: $formatted • రిఫరెన్స్: $reference',
        timestamp: 'Just now',
        icon: Icons.verified_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Dispute submitted.
  void notifyDisputeSubmitted({
    required String disputeId,
    required String category,
    String? tokenNumber,
  }) {
    final key = 'disputeSubmitted_$disputeId';
    addNotification(
      NotificationModel(
        id: 'notif_dispute_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.disputeSubmitted,
        action: NotificationActionType.procurementStatus,
        titleEn: 'Dispute Registered',
        titleHi: 'शिकायत दर्ज हुई',
        titleTe: 'ఫిర్యాదు నమోదు చేయబడింది',
        messageEn:
            'Your dispute has been received for review.\nTracking ID: $disputeId • Category: $category',
        messageHi:
            'आपकी शिकायत समीक्षा के लिए दर्ज कर ली गई है।\nट्रैकिंग आईडी: $disputeId • श्रेणी: $category',
        messageTe:
            'మీ ఫిర్యాదు పరిశీలన కోసం స్వీకరించబడింది.\nట్రాకింగ్ ఐడి: $disputeId • విభాగం: $category',
        timestamp: 'Just now',
        icon: Icons.gavel_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Gate Check-in confirmed.
  void notifyCheckInConfirmed({
    required String tokenNumber,
    required String centreName,
    required String arrivalTime,
  }) {
    final key = 'checkInConfirmed_$tokenNumber';
    addNotification(
      NotificationModel(
        id: 'notif_checkin_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.checkInConfirmed,
        action: NotificationActionType.myToken,
        titleEn: 'Gate Check-In Confirmed',
        titleHi: 'गेट चेक-इन सत्यापित',
        titleTe: 'గేట్ చెక్-ఇన్ ధృవీకరించబడింది',
        messageEn:
            'Digital pass verified at centre gate.\nToken: $tokenNumber • Arrival: $arrivalTime\nYou are now in the active queue.',
        messageHi:
            'केंद्र के द्वार पर डिजिटल पास सत्यापित हुआ।\nटोकन: $tokenNumber • आगमन: $arrivalTime\nआप अब सक्रिय कतार में हैं।',
        messageTe:
            'కేంద్రం గేటు వద్ద డిజిటల్ పాస్ ధృవీకరించబడింది.\nటోకెన్: $tokenNumber • రాక: $arrivalTime\nమీరు ఇప్పుడు క్రియాశీల క్యూలో ఉన్నారు.',
        timestamp: 'Just now',
        icon: Icons.qr_code_scanner_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Crop / produce change confirmed.
  void notifyCropChanged({
    required String cropNameEn,
    required String cropNameHi,
    required String cropNameTe,
    required String quantity,
    required String estimatedMsp,
    String? tokenNumber,
  }) {
    addNotification(
      NotificationModel(
        id: 'notif_crop_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.procurementProcessing,
        action: NotificationActionType.procurementStatus,
        titleEn: 'Produce Updated',
        titleHi: 'उपज अद्यतन की गई',
        titleTe: 'పంట వివరాలు నవీకరించబడ్డాయి',
        messageEn:
            'Your produce has been updated to $cropNameEn ($quantity).\nEstimated MSP: $estimatedMsp',
        messageHi:
            'आपकी उपज $cropNameHi ($quantity) में बदल दी गई है।\nअनुमानित एमएसपी: $estimatedMsp',
        messageTe:
            'మీ పంట $cropNameTe ($quantity) గా నవీకరించబడింది.\nఅంచనా వేసిన ఎంఎస్‌పి: $estimatedMsp',
        timestamp: 'Just now',
        icon: Icons.grass_rounded,
        tokenNumber: tokenNumber,
      ),
    );
  }

  /// Helper: Slot reallocated dynamically by officer to avoid overload.
  void notifySlotReallocated({
    required String tokenNumber,
    required String oldSlot,
    required String newSlot,
    required String centreName,
    required String reasonEn,
    String? reasonHi,
    String? reasonTe,
    required String newDepartureTime,
  }) {
    final key = 'slotReallocated_${tokenNumber}_$newSlot';
    final rHi = reasonHi ?? reasonEn;
    final rTe = reasonTe ?? reasonEn;

    addNotification(
      NotificationModel(
        id: 'notif_realloc_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.slotReallocated,
        action: NotificationActionType.myToken,
        titleEn: 'Slot Reallocated',
        titleHi: 'स्लॉट पुनर्निर्धारित',
        titleTe: 'స్లాట్ మార్చబడింది',
        messageEn:
            'Your procurement slot has been rescheduled to reduce wait time.\nToken: $tokenNumber • New Slot: $newSlot (was $oldSlot)\nReason: $reasonEn\nRecommended Departure: $newDepartureTime',
        messageHi:
            'प्रतीक्षा समय कम करने के लिए आपका प्रोक्योरमेंट स्लॉट बदल दिया गया है।\nटोकन: $tokenNumber • नया स्लॉट: $newSlot (पहले $oldSlot)\nकारण: $rHi\nअनुशंसित प्रस्थान: $newDepartureTime',
        messageTe:
            'వేచి ఉండే సమయాన్ని తగ్గించడానికి మీ సేకరణ స్లాట్ మార్చబడింది.\nటోకెన్: $tokenNumber • కొత్త స్లాట్: $newSlot (గతంలో $oldSlot)\nకారణం: $rTe\nసిఫార్సు చేయబడిన ప్రయాణం: $newDepartureTime',
        timestamp: 'Just now',
        icon: Icons.update_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Helper: Farmer explicitly switched to a recommended alternative procurement centre.
  void notifyCentreChanged({
    required String tokenNumber,
    required String oldCentre,
    required String newCentre,
    required String newSlot,
    required String departureTime,
  }) {
    final key = 'centreChanged_${tokenNumber}_${newCentre}_$newSlot';

    addNotification(
      NotificationModel(
        id: 'notif_centre_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.centreChanged,
        action: NotificationActionType.myToken,
        titleEn: 'Centre Switched',
        titleHi: 'खरीद केंद्र बदला गया',
        titleTe: 'సేకరణ కేంద్రం మార్చబడింది',
        messageEn:
            'Your booking has been transferred to $newCentre.\nToken: $tokenNumber • Slot: $newSlot (was at $oldCentre)\nRecommended Departure: $departureTime',
        messageHi:
            'आपकी बुकिंग को $newCentre में स्थानांतरित कर दिया गया है।\nटोकन: $tokenNumber • स्लॉट: $newSlot ($oldCentre से बदला गया)\nअनुशंसित प्रस्थान: $departureTime',
        messageTe:
            'మీ బుకింగ్ $newCentre కు బదిలీ చేయబడింది.\nటోకెన్: $tokenNumber • స్లాట్: $newSlot (గతంలో $oldCentre)\nసిఫార్సు చేయబడిన ప్రయాణం: $departureTime',
        timestamp: 'Just now',
        icon: Icons.store_mall_directory_rounded,
        tokenNumber: tokenNumber,
      ),
      deduplicationKey: key,
    );
  }

  /// Synthesizes voice assistant summary text for Listen / వినండి / सुनें.
  String generateVoiceSummary({
    required bool isHindi,
    bool isTelugu = false,
    required String tokenNumber,
    required int peopleAhead,
    required String departureTime,
  }) {
    final count = unreadCount;
    if (isTelugu) {
      if (count == 0) {
        return 'వాయిస్ అసిస్టెంట్: మీకు కొత్త సందేశాలు లేవు. మీ టోకెన్ $tokenNumber కోసం సిఫార్సు చేయబడిన బయలుదేరే సమయం $departureTime.';
      }
      return 'వాయిస్ అసిస్టెంట్: మీకు $count కొత్త అప్‌డేట్‌లు ఉన్నాయి. మీ టోకెన్ $tokenNumber. క్యూలో $peopleAhead మంది ముందున్నారు మరియు బయలుదేరే సమయం $departureTime.';
    } else if (isHindi) {
      if (count == 0) {
        return 'आवाज सहायक: आपके पास कोई नया संदेश नहीं है। टोकन $tokenNumber के लिए निकलने का सही समय $departureTime है।';
      }
      return 'आवाज सहायक: आपके पास $count नए अपडेट हैं। आपका टोकन $tokenNumber है। कतार में $peopleAhead लोग आगे हैं और निकलने का सही समय $departureTime है।';
    } else {
      if (count == 0) {
        return 'Voice Assistant: You have no unread updates. Your procurement token is $tokenNumber. Recommended departure time is $departureTime.';
      }
      return 'Voice Assistant: You have $count new updates. Your procurement token is $tokenNumber. Your current queue position is $peopleAhead people ahead. Your recommended departure time is $departureTime.';
    }
  }
}
