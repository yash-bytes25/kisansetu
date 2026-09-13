import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/farmer_dashboard_data.dart';
import '../services/app_preferences_service.dart';
import '../services/procurement_state_service.dart';
import '../services/qr_validation_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Screen presenting ONLY the farmer's latest / currently active digital pass and QR.
///
/// Designed with RECOGNIZE → TAP → UNDERSTAND philosophy:
/// - Focused strictly on the active booking's pass and secure gate check-in QR code.
/// - Excludes past passes, queue progression charts, or prototype controls.
/// - Clear, farmer-friendly empty state with a "Book Slot" action when no booking exists.
class FarmerDigitalPassScreen extends StatefulWidget {
  final FarmerDashboardData? bookingData;
  final bool isHindi;
  final bool isTelugu;
  final VoidCallback? onBookSlot;

  const FarmerDigitalPassScreen({
    super.key,
    this.bookingData,
    this.isHindi = false,
    this.isTelugu = false,
    this.onBookSlot,
  });

  @override
  State<FarmerDigitalPassScreen> createState() => _FarmerDigitalPassScreenState();
}

class _FarmerDigitalPassScreenState extends State<FarmerDigitalPassScreen> {
  final _service = ProcurementStateService();
  final _prefs = AppPreferencesService.instance;

  bool get _isHindi => widget.isHindi || (!widget.isTelugu && _prefs.isHindi);
  bool get _isTelugu => widget.isTelugu || (!widget.isHindi && _prefs.isTelugu);

  FarmerDashboardData get _effectiveData => widget.bookingData ?? _service.farmerData;

  bool get _hasActiveBooking {
    final token = _effectiveData.tokenNumber.trim();
    if (token.isEmpty || token == 'None') return false;
    final status = _effectiveData.lifecycleStatus.toLowerCase();
    if (status == 'cancelled' || status == 'rejected') return false;
    return true;
  }

  void _showVoiceGuidance() {
    final String guideText;
    if (!_hasActiveBooking) {
      guideText = _isTelugu
          ? 'వాయిస్ గైడ్: మీ వద్ద ప్రస్తుతం యాక్టివ్ డిజిటల్ పాస్ లేదు. కొత్త టోకెన్ పొందడానికి స్లాట్ బుక్ చేయండి.'
          : (_isHindi
              ? 'आवाज गाइड: आपके पास कोई सक्रिय डिजिटल पास नहीं है। नया टोकन पाने के लिए स्लॉट बुक करें।'
              : 'Voice Guide: You do not have an active digital pass. Tap Book Slot to confirm a procurement token.');
    } else {
      guideText = _isTelugu
          ? 'వాయిస్ గైడ్: మీ యాక్టివ్ డిజిటల్ పాస్ టోకెన్ ${_effectiveData.tokenNumber}. పంట: ${_effectiveData.cropName}, పరిమాణం: ${_effectiveData.quantity}, కేంద్రం: ${_effectiveData.centreName}, స్లాట్: ${_effectiveData.bookedSlotTime ?? "11:30 AM"}.'
          : (_isHindi
              ? 'आवाज गाइड: आपका सक्रिय डिजिटल पास टोकन ${_effectiveData.tokenNumber} है। फसल: ${_effectiveData.cropName}, मात्रा: ${_effectiveData.quantity}, खरीद केंद्र: ${_effectiveData.centreName}, स्लॉट: ${_effectiveData.bookedSlotTime ?? "11:30 AM"}।'
              : 'Voice Guide: Your active digital pass token is ${_effectiveData.tokenNumber}. Produce: ${_effectiveData.cropName}, Quantity: ${_effectiveData.quantity}, Centre: ${_effectiveData.centreName}, Slot: ${_effectiveData.bookedSlotTime ?? "11:30 AM"}.');
    }

    final langCode = _isTelugu ? 'te-IN' : (_isHindi ? 'hi-IN' : 'en-IN');
    VoiceAssistantSpeechService.instance.speak(guideText, language: langCode);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                guideText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: _isTelugu ? 'వెనుకకు' : (_isHindi ? 'वापस' : 'Back'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isTelugu
                  ? 'డిజిటల్ పాస్ / QR'
                  : (_isHindi ? 'डिजिटल पास / क्यूआर' : 'Digital Pass / QR'),
              style: AppTextStyles.titleMedium,
            ),
          ],
        ),
        actions: [
          Semantics(
            label: _isTelugu
                ? 'వాయిస్ వినండి'
                : (_isHindi ? 'आवाज गाइड' : 'Voice guidance'),
            button: true,
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton.icon(
                onPressed: _showVoiceGuidance,
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.primaryGreen,
                  size: 18,
                ),
                label: Text(
                  _isTelugu ? 'Listen / వినండి' : 'Listen / सुनें',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: _hasActiveBooking
              ? _buildActivePassView(_effectiveData)
              : _buildEmptyState(),
        ),
      ),
    );
  }

  /// Empty state when the farmer has no active booking pass.
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 56,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isTelugu
                ? 'యాక్టివ్ డిజిటల్ పాస్ లేదు'
                : (_isHindi
                    ? 'कोई सक्रिय डिजिटल पास नहीं'
                    : 'No active digital pass'),
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isTelugu
                ? 'ధృవీకరించబడిన డిజిటల్ పాస్ & QR కోడ్‌ను పొందడానికి సేకరణ స్లాట్‌ను బుక్ చేయండి.'
                : (_isHindi
                    ? 'सत्यापित डिजिटल पास और क्यूआर कोड प्राप्त करने के लिए खरीद स्लॉट बुक करें।'
                    : 'Book a procurement slot to generate your verified digital pass & instant QR check-in.'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onBookSlot?.call();
              },
              icon: const Icon(Icons.calendar_month_rounded, size: 20),
              label: Text(
                _isTelugu
                    ? 'స్లాట్ బుక్ చేయండి'
                    : (_isHindi ? 'स्लॉट बुक करें' : 'Book Slot'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Active Digital Pass view showing only the farmer's latest active booking.
  Widget _buildActivePassView(FarmerDashboardData data) {
    final isCheckedIn = data.checkInStatus == 'Checked In';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Digital Pass Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryGreen, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pass Header Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isTelugu
                            ? 'నా టోకెన్'
                            : (_isHindi ? 'मेरा टोकन' : 'MY TOKEN'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.tokenNumber,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isTelugu
                              ? 'యాక్టివ్ పాస్'
                              : (_isHindi ? 'सक्रिय पास' : 'ACTIVE PASS'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 16),

              // Booking Details
              _buildDetailRow(
                icon: Icons.grass_rounded,
                label: _isTelugu ? 'పంట & పరిమాణం:' : (_isHindi ? 'फसल एवं मात्रा:' : 'Produce & Quantity:'),
                value: '${data.cropName} • ${data.quantity}',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.store_rounded,
                label: _isTelugu ? 'సేకరణ కేంద్రం:' : (_isHindi ? 'खरीद केंद्र:' : 'Procurement Centre:'),
                value: data.centreName,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.event_available_rounded,
                label: _isTelugu ? 'స్లాట్ సమయం:' : (_isHindi ? 'स्लॉट समय:' : 'Slot Date & Time:'),
                value: 'Today · ${data.bookedSlotTime ?? '11:30 AM'}',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: isCheckedIn ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                label: _isTelugu ? 'ప్రస్తుత స్థితి:' : (_isHindi ? 'वर्तमान स्थिति:' : 'Booking Status:'),
                value: isCheckedIn
                    ? (_isTelugu ? 'చెక్-ఇన్ పూర్తయింది' : (_isHindi ? 'चेक-इन हो गया' : 'Checked In'))
                    : (_isTelugu ? 'వేచి ఉంది (క్యూలో)' : (_isHindi ? 'प्रतीक्षारत' : 'Waiting (In Queue)')),
                valueColor: isCheckedIn ? AppColors.success : AppColors.secondary,
              ),

              const SizedBox(height: 18),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 18),

              // Shielded QR Pass
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: QrValidationService.generateQrPayload(
                          bookingId: 'BK-${data.tokenNumber.replaceAll('TK-', '')}',
                          tokenNumber: data.tokenNumber,
                          centreName: data.centreName,
                          slotTime: data.bookedSlotTime ?? '11:30 AM',
                        ),
                        version: QrVersions.auto,
                        size: 175,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Security / Privacy Note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield_rounded,
                          size: 15,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isTelugu
                              ? 'సురక్షిత QR పాస్ • వ్యక్తిగత డేటా రక్షించబడింది'
                              : (_isHindi
                                  ? 'सुरक्षित क्यूआर पास • व्यक्तिगत डेटा सुरक्षित'
                                  : 'Secure QR Pass • Shielded PII'),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isTelugu
                          ? 'కేంద్రం వద్ద గేట్ ఎంట్రీ కోసం ఈ QR కోడ్‌ను చూపించండి.'
                          : (_isHindi
                              ? 'खरीद केंद्र के गेट पर त्वरित चेक-इन के लिए यह क्यूआर दिखाएं।'
                              : 'Present this digital pass at the gate for fast check-in.'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Back to Dashboard Action Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            label: Text(
              _isTelugu
                  ? 'డాష్‌బోర్డ్‌కు తిరిగి వెళ్లండి'
                  : (_isHindi ? 'डैशबोर्ड पर वापस जाएं' : 'Back to Dashboard'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen, width: 1.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
