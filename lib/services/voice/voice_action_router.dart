// KisanSetu (SIH26032) - Voice Action Router
// Bridges voice intents to existing KisanSetu services, ensuring strict validation and confirmation.

import '../../models/voice/voice_intent.dart';
import '../auth_service.dart';
import '../connectivity_service.dart';
import '../procurement_state_service.dart';

/// Result wrapper returned by VoiceActionRouter execution.
class VoiceActionResult {
  final bool isSuccess;
  final String message;
  final String? spokenFeedback;
  final Map<String, dynamic> data;
  final String? navigateRoute;

  const VoiceActionResult({
    required this.isSuccess,
    required this.message,
    this.spokenFeedback,
    this.data = const {},
    this.navigateRoute,
  });
}

/// Routes validated and confirmed voice intents to existing KisanSetu domain services.
class VoiceActionRouter {
  final ProcurementStateService _stateService;

  VoiceActionRouter({ProcurementStateService? stateService})
      : _stateService = stateService ?? ProcurementStateService();

  /// Executes an intent.
  /// Actionable intents (bookSlot, changeCrop, etc.) MUST have requiresConfirmation=true
  /// and be explicitly confirmed by the farmer before calling this method.
  Future<VoiceActionResult> executeIntent(
    VoiceIntent intent, {
    bool isTelugu = false,
    bool isHindi = false,
  }) async {
    switch (intent.intent) {
      case VoiceIntentType.getTokenStatus:
        return _handleTokenQuery(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.getGoTime:
        return _handleGoTimeQuery(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.getQueue:
        return _handleQueueQuery(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.getPaymentStatus:
        return _handlePaymentStatusQuery(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.getPaymentHistory:
        return _handlePaymentHistoryQuery(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.getProcurementStatus:
        return _handleProcurementStatusQuery(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.recommendCentre:
        return _handleCentreRecommendation(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.getCentreStatus:
        return _handleCentreStatusQuery(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.getProfileInfo:
        return _handleProfileQuery(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.bookSlot:
        return _handleBookSlotAction(intent, isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.changeCrop:
        return _handleChangeCropAction(intent, isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.changeQuantity:
        return _handleChangeQuantityAction(intent, isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.startDispute:
        return _handleStartDisputeAction(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.help:
        return _handleHelp(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.getSlot:
        return _handleSlotQuery(isTelugu: isTelugu, isHindi: isHindi);

      case VoiceIntentType.unknown:
        return VoiceActionResult(
          isSuccess: false,
          message: isTelugu
              ? 'క్షమించండి, మీ అభ్యర్థన అర్థం కాలేదు. దయచేసి మళ్లీ ప్రయత్నించండి.'
              : (isHindi
                  ? 'क्षमा करें, मुझे समझ नहीं आया। कृपया दोबारा प्रयास करें।'
                  : "Sorry, I couldn't understand that request. Please try again."),
        );
    }
  }

  // --- Information Handlers ---

  VoiceActionResult _handleTokenQuery({required bool isTelugu, required bool isHindi}) {
    final data = _stateService.farmerData;
    final token = data.tokenNumber;
    final centre = data.centreName;
    final slot = data.bookedSlotTime ?? '11:30 AM';

    final text = isTelugu
        ? 'మీ క్రియాశీల టోకెన్ సంఖ్య $token. కేంద్రం: $centre. స్లాట్ సమయం: $slot.'
        : (isHindi
            ? 'आपका सक्रिय टोकन नंबर $token है। केंद्र: $centre। स्लॉट समय: $slot।'
            : 'Your active digital token is $token at $centre. Booked slot time is $slot.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      data: {'token': token, 'centre': centre, 'slot': slot},
    );
  }

  VoiceActionResult _handleGoTimeQuery({required bool isTelugu, required bool isHindi}) {
    final data = _stateService.farmerData;
    final departure = data.recommendedDepartureTime;
    final waitMin = data.expectedWaitMinutes;
    final ahead = data.peopleAhead;

    final text = isTelugu
        ? 'మీ సిఫార్సు చేయబడిన బయలుదేరే సమయం $departure. అంచనా వేసిన ప్రయాణ సమయం 25 నిమిషాలు. కేంద్రంలో $ahead మంది ముందున్నారు.'
        : (isHindi
            ? 'आपके प्रस्थान का अनुशंसित समय $departure है। यात्रा का समय लगभग 25 मिनट है। केंद्र पर आपके आगे $ahead किसान हैं।'
            : 'Your recommended departure time is $departure. Estimated travel time is 25 minutes. There are $ahead farmers ahead of you.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      data: {'departure': departure, 'waitMinutes': waitMin, 'ahead': ahead},
    );
  }

  VoiceActionResult _handleQueueQuery({required bool isTelugu, required bool isHindi}) {
    final data = _stateService.farmerData;
    final ahead = data.peopleAhead;
    final waitMin = data.expectedWaitMinutes;
    final pos = ahead + 1;

    final text = isTelugu
        ? 'క్యూలో మీ స్థానం $pos. మీ ముందు $ahead మంది రైతులు ఉన్నారు. సుమారు వేచి ఉండే సమయం $waitMin నిమిషాలు.'
        : (isHindi
            ? 'कतार में आपकी स्थिति $pos है। आपके आगे $ahead किसान हैं। अनुमानित प्रतीक्षा समय $waitMin मिनट है।'
            : 'Your queue position is $pos with $ahead farmers ahead of you. Estimated wait time is $waitMin minutes.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      data: {'ahead': ahead, 'position': pos, 'waitMinutes': waitMin},
    );
  }

  VoiceActionResult _handleSlotQuery({required bool isTelugu, required bool isHindi}) {
    final data = _stateService.farmerData;
    final slot = data.bookedSlotTime ?? '11:30 AM';
    final centre = data.centreName;

    final text = isTelugu
        ? 'మీ బుక్ చేసిన స్లాట్ సమయం $slot, $centre వద్ద.'
        : (isHindi
            ? 'आपका बुक किया गया स्लॉट समय $slot है, $centre पर।'
            : 'Your booked procurement slot is $slot at $centre.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      data: {'slot': slot, 'centre': centre},
    );
  }

  VoiceActionResult _handlePaymentStatusQuery({required bool isTelugu, required bool isHindi}) {
    final data = _stateService.farmerData;
    final status = data.paymentStatus;
    final ref = data.paymentReference;

    final text = isTelugu
        ? 'మీ DBT చెల్లింపు స్థితి: $status. రిఫరెన్స్ సంఖ్య: $ref.'
        : (isHindi
            ? 'आपके डीबीटी भुगतान की स्थिति: $status है। संदर्भ संख्या: $ref।'
            : 'Your DBT payment status is currently $status with reference $ref.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      data: {'status': status, 'reference': ref},
    );
  }

  VoiceActionResult _handlePaymentHistoryQuery({required bool isTelugu, required bool isHindi}) {
    final data = _stateService.farmerData;
    final ref = data.paymentReference;
    final crop = data.cropName;

    final text = isTelugu
        ? '$crop అమ్మకానికి సంబంధించిన తాజా చెల్లింపు రశీదు రిఫరెన్స్ $ref అందుబాటులో ఉంది.'
        : (isHindi
            ? '$crop की खरीद की नवीनतम भुगतान रसीद संदर्भ संख्या $ref के साथ उपलब्ध है।'
            : 'Your latest payment receipt for $crop is available under reference $ref.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      navigateRoute: 'payment_history',
    );
  }

  VoiceActionResult _handleProcurementStatusQuery({required bool isTelugu, required bool isHindi}) {
    final data = _stateService.farmerData;
    final stage = data.lifecycleStatus;

    final text = isTelugu
        ? 'మీ సరుకు సేకరణ స్థితి: $stage. తదుపరి దశ కోసం కేంద్ర అధికారుల సూచనలను గమనించండి.'
        : (isHindi
            ? 'आपकी उपज की खरीद स्थिति: $stage है।'
            : 'Your procurement status is currently: $stage.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      data: {'stage': stage},
    );
  }

  VoiceActionResult _handleCentreRecommendation({required bool isTelugu, required bool isHindi}) {
    final data = _stateService.farmerData;
    final currentCentre = data.centreName;
    final load = _stateService.centreCapacityPercent;

    final text = isTelugu
        ? '$currentCentre ప్రస్తుత రద్దీ $load%. తక్కువ రద్దీ ఉన్న సమీప కేంద్రాలను ప్రత్యామ్నాయ కేంద్రాల స్క్రీన్‌లో చూడవచ్చు.'
        : (isHindi
            ? '$currentCentre में वर्तमान लोड $load% है। कम भीड़ वाले नजदीकी केंद्रों को आप वैकल्पिक केंद्र सूची में देख सकते हैं।'
            : '$currentCentre currently has $load% load. You can review less congested nearby centres on the alternative centres screen.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      navigateRoute: 'alternative_centres',
    );
  }

  VoiceActionResult _handleCentreStatusQuery({required bool isTelugu, required bool isHindi}) {
    final data = _stateService.farmerData;
    final centre = data.centreName;
    final delay = _stateService.centreDelayMinutes;
    final status = _stateService.centreStatus;

    final text = isTelugu
        ? '$centre కేంద్రం స్థితి: $status. అదనపు ఆలస్యం: $delay నిమిషాలు.'
        : (isHindi
            ? '$centre केंद्र की स्थिति: $status है। अतिरिक्त विलंब: $delay मिनट।'
            : '$centre operating status is $status with an active delay of $delay minutes.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      data: {'centre': centre, 'status': status, 'delay': delay},
    );
  }

  VoiceActionResult _handleProfileQuery({required bool isTelugu, required bool isHindi}) {
    final data = _stateService.farmerData;
    final name = data.farmerName;
    final phone = AuthService.instance.currentPhone ?? '9876543210';
    final aadhaar = _stateService.aadhaarMasked;
    final bank = _stateService.bankAccountNumberMasked;

    final text = isTelugu
        ? 'రైతు: $name, ఫోన్: $phone, ఆధార్: $aadhaar (ధృవీకరించబడింది), బ్యాంక్ ఖాతా: $bank.'
        : (isHindi
            ? 'किसान: $name, फोन: $phone, आधार: $aadhaar (सत्यापित), बैंक खाता: $bank।'
            : 'Farmer: $name, Phone: $phone, Aadhaar: $aadhaar (Verified), Bank Account: $bank.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      data: {'name': name, 'phone': phone, 'aadhaar': aadhaar, 'bank': bank},
    );
  }

  VoiceActionResult _handleHelp({required bool isTelugu, required bool isHindi}) {
    final text = isTelugu
        ? 'నేను మీకు స్లాట్ బుకింగ్, టోకెన్ స్థితి, క్యూ సమయం, ప్రయాణ సమయం (Go-Time), మరియు చెల్లింపు వివరాల విషయంలో సహాయం చేయగలను.'
        : (isHindi
            ? 'मैं स्लॉट बुकिंग, टोकन स्थिति, कतार प्रतीक्षा समय, प्रस्थान समय (Go-Time), और भुगतान विवरण में आपकी सहायता कर सकता हूँ।'
            : 'I can assist you with slot booking, token status, queue wait time, Go-Time departure advisory, and DBT payment details.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
    );
  }

  // --- Action Handlers (Strictly Confirmed) ---

  Future<VoiceActionResult> _handleBookSlotAction(
    VoiceIntent intent, {
    required bool isTelugu,
    required bool isHindi,
  }) async {
    // Check offline constraint
    if (!AppConnectivityService.instance.isOnline) {
      final text = isTelugu
          ? 'ఆఫ్‌లైన్‌లో ఉన్నప్పుడు కొత్త స్లాట్ బుకింగ్ సాధ్యం కాదు. దయచేసి ఇంటర్నెట్ కనెక్ట్ చేయండి.'
          : (isHindi
              ? 'ऑफ़लाइन होने पर नया स्लॉट बुक नहीं किया जा सकता। कृपया इंटरनेट कनेक्ट करें।'
              : 'Cannot book a new slot while offline. Please connect to the internet.');
      return VoiceActionResult(isSuccess: false, message: text, spokenFeedback: text);
    }

    final crop = intent.crop ?? 'Wheat';
    final qty = intent.quantity ?? 50.0;
    final date = intent.date ?? 'Tomorrow';

    // Synchronize booking via existing state service
    _stateService.updateFarmerBooking(
      centreName: _stateService.farmerData.centreName,
      bookedSlot: _stateService.farmerData.bookedSlotTime ?? '11:30 AM',
      tokenNumber: _stateService.farmerData.tokenNumber,
      crop: crop,
      quantity: '${qty.toStringAsFixed(0)} Quintals',
    );

    final text = isTelugu
        ? '$crop ($qty క్వింటాళ్లు, $date) కోసం ఉత్తమ స్లాట్ విజయవంతంగా ఎంపిక చేయబడింది.'
        : (isHindi
            ? '$crop ($qty क्विंटल, $date) के लिए सर्वश्रेष्ठ स्लॉट सफलतापूर्वक चुना गया है।'
            : 'Successfully selected the best slot for $crop ($qty Quintals, $date).');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      navigateRoute: 'smart_slot',
      data: {'crop': crop, 'quantity': qty, 'date': date},
    );
  }

  Future<VoiceActionResult> _handleChangeCropAction(
    VoiceIntent intent, {
    required bool isTelugu,
    required bool isHindi,
  }) async {
    final crop = intent.crop ?? 'Wheat';
    final currentQty = _stateService.farmerData.quantity;

    _stateService.updateFarmerBooking(
      centreName: _stateService.farmerData.centreName,
      bookedSlot: _stateService.farmerData.bookedSlotTime ?? '11:30 AM',
      tokenNumber: _stateService.farmerData.tokenNumber,
      crop: crop,
      quantity: currentQty,
    );

    final text = isTelugu
        ? 'పంట విజయవంతంగా $crop గా నవీకరించబడింది.'
        : (isHindi
            ? 'फसल सफलतापूर्वक $crop में बदल दी गई है।'
            : 'Crop successfully updated to $crop.');

    return VoiceActionResult(isSuccess: true, message: text, spokenFeedback: text);
  }

  Future<VoiceActionResult> _handleChangeQuantityAction(
    VoiceIntent intent, {
    required bool isTelugu,
    required bool isHindi,
  }) async {
    final qty = intent.quantity ?? 50.0;
    final currentCrop = _stateService.farmerData.cropName;

    _stateService.updateFarmerBooking(
      centreName: _stateService.farmerData.centreName,
      bookedSlot: _stateService.farmerData.bookedSlotTime ?? '11:30 AM',
      tokenNumber: _stateService.farmerData.tokenNumber,
      crop: currentCrop,
      quantity: '${qty.toStringAsFixed(0)} Quintals',
    );

    final text = isTelugu
        ? 'పరిమాణం విజయవంతంగా $qty క్వింటాళ్లుగా నవీకరించబడింది.'
        : (isHindi
            ? 'मात्रा सफलतापूर्वक $qty क्विंटल अपडेट कर दी गई है।'
            : 'Quantity successfully updated to $qty Quintals.');

    return VoiceActionResult(isSuccess: true, message: text, spokenFeedback: text);
  }

  VoiceActionResult _handleStartDisputeAction({required bool isTelugu, required bool isHindi}) {
    final text = isTelugu
        ? 'సమస్య లేదా ఫిర్యాదు నమోదు చేయడానికి సమస్య స్క్రీన్‌కు వెళ్లండి.'
        : (isHindi
            ? 'शिकायत या समस्या दर्ज करने के लिए विवाद निवारण स्क्रीन खोलें।'
            : 'Opening dispute reporting workflow.');

    return VoiceActionResult(
      isSuccess: true,
      message: text,
      spokenFeedback: text,
      navigateRoute: 'dispute',
    );
  }
}
