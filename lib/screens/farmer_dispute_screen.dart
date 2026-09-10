import 'package:flutter/material.dart';
import '../services/app_preferences_service.dart';
import '../services/procurement_state_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Phase 8: KisanSetu Farmer Dispute & Discrepancy Reporting Screen.
///
/// Designed with RECOGNIZE → TAP → UNDERSTAND philosophy:
/// - Low cognitive load with recognizable grievance reason cards.
/// - Allows reporting weight discrepancies, grading issues, or payment delays.
/// - Stores the dispute report in shared state for offline/prototype verification.
/// - Provides instant submission feedback.
class FarmerDisputeScreen extends StatefulWidget {
  final String tokenNumber;
  final bool isHindi;
  final bool isTelugu;
  final String? initialReason;

  const FarmerDisputeScreen({
    super.key,
    required this.tokenNumber,
    this.isHindi = false,
    this.isTelugu = false,
    this.initialReason,
  });

  @override
  State<FarmerDisputeScreen> createState() => _FarmerDisputeScreenState();
}

class _FarmerDisputeScreenState extends State<FarmerDisputeScreen> {
  final _service = ProcurementStateService();
  final _explanationController = TextEditingController();
  late String _selectedReason;
  bool _isSubmitted = false;
  final _prefs = AppPreferencesService.instance;
  bool get _isHindi  => widget.isHindi || (!widget.isTelugu && _prefs.isHindi);
  bool get _isTelugu => widget.isTelugu || (!widget.isHindi && _prefs.isTelugu);

  static const List<Map<String, String>> _reasons = [
    {
      'en': 'Quantity is incorrect',
      'hi': 'मात्रा / वजन गलत है',
      'te': 'పరిమాణం / బరువు తప్పుగా ఉంది',
      'icon': 'scale',
    },
    {
      'en': 'Quality grade is incorrect',
      'hi': 'गुणवत्ता ग्रेड गलत है',
      'te': 'నాణ్యత గ్రేడ్ సరిపోలడం లేదు',
      'icon': 'science',
    },
    {
      'en': 'Payment amount is incorrect',
      'hi': 'भुगतान राशि गलत है',
      'te': 'చెల్లింపు మొత్తం తప్పుగా ఉంది',
      'icon': 'payment',
    },
    {
      'en': 'Payment is delayed',
      'hi': 'भुगतान में देरी हो रही है',
      'te': 'చెల్లింపులో ఆలస్యం అవుతోంది',
      'icon': 'time',
    },
    {
      'en': 'Other',
      'hi': 'अन्य समस्या',
      'te': 'ఇతర సమస్య',
      'icon': 'more',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedReason = widget.initialReason ?? _reasons.first['en']!;
  }

  @override
  void dispose() {
    _explanationController.dispose();
    super.dispose();
  }

  void _showVoiceGuidance() {
    final guideText = _isTelugu
        ? 'సమస్య నివేదిక: దయచేసి క్రింది ఎంపికల నుండి మీ సమస్యను ఎంచుకుని "నివేదిక సమర్పించండి" పై నొక్కండి.'
        : (_isHindi
            ? 'समस्या रिपोर्ट: कृपया नीचे दिए गए विकल्पों में से अपनी समस्या चुनें और "रिपोर्ट जमा करें" पर टैप करें।'
            : 'Dispute Assistant: Please select your issue from the options below and tap "Submit Report".');
    final langCode =
        _isTelugu ? 'te-IN' : (_isHindi ? 'hi-IN' : 'en-IN');
    VoiceAssistantSpeechService.instance
        .speak(guideText, language: langCode);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 5),
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

  void _submitDispute() {
    _service.submitDispute(
      tokenNumber: widget.tokenNumber,
      reason: _selectedReason,
      explanation: _explanationController.text.trim().isNotEmpty
          ? _explanationController.text.trim()
          : null,
    );

    setState(() {
      _isSubmitted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isTelugu
                    ? 'మీ నివేదిక విజయవంతంగా సమర్పించబడింది.'
                    : (_isHindi
                        ? 'आपकी रिपोर्ट सफलतापूर्वक जमा कर दी गई है।'
                        : 'Your report has been submitted.'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForReason(String type) {
    switch (type) {
      case 'scale':
        return Icons.scale_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'time':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.help_outline_rounded;
    }
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
          tooltip: _isTelugu
              ? 'వెనుకకు'
              : (_isHindi ? 'वापस' : 'Back'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Text(
              'KisanSetu • ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryGreen,
              ),
            ),
            Text(
              _isTelugu
                  ? 'సమస్య నివేదిక'
                  : (_isHindi ? 'समस्या रिपोर्ट' : 'Report a Problem'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            label: _isTelugu
                ? 'వాయిస్ వినండి'
                : (_isHindi ? 'आवाज सुनें' : 'Listen to guidance'),
            button: true,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: _isSubmitted
              ? _buildSuccessConfirmation()
              : _buildDisputeForm(),
        ),
      ),
    );
  }

  Widget _buildDisputeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Heading & Helper
        Text(
          _isTelugu
              ? 'సమస్యను నివేదించండి'
              : (_isHindi ? 'समस्या की रिपोर्ट करें' : 'Report a Problem'),
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          _isTelugu
              ? 'బరువు, నాణ్యత లేదా చెల్లింపులో ఏదైనా సమస్య ఉంటే, దయచేసి క్రింద వివరాలను నమోదు చేయండి.'
              : (_isHindi
                  ? 'यदि वजन, गुणवत्ता या भुगतान में कोई समस्या है, तो कृपया नीचे विवरण दर्ज करें।'
                  : 'If you notice an issue with weight, quality, or payment, submit your report for review.'),
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 20),

        // Predefined Reasons
        Text(
          _isTelugu
              ? 'సమస్య రకాన్ని ఎంచుకోండి:'
              : (_isHindi ? 'समस्या का प्रकार चुनें:' : 'Select Problem Reason:'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        Column(
          children: _reasons.map((r) {
            final isSelected = _selectedReason == r['en'];
            final label = _isTelugu
                ? r['te']!
                : (_isHindi ? r['hi']! : r['en']!);
            final icon = _getIconForReason(r['icon']!);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.secondary
                      : AppColors.cardBorder,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              color: isSelected
                  ? AppColors.secondaryContainer.withValues(alpha: 0.3)
                  : AppColors.surface,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _selectedReason = r['en']!;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 14.0),
                  child: Row(
                    children: [
                      Icon(icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.textTertiary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Optional explanation field
        Text(
          _isTelugu
              ? 'అదనపు వివరాలు (ఐచ్ఛికం):'
              : (_isHindi
                  ? 'अतिरिक्त विवरण (वैकल्पिक):'
                  : 'Additional Explanation (Optional):'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        TextFormField(
          controller: _explanationController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: _isTelugu
                ? 'దయచేసి సమస్య గురించి సంక్షిప్త వివరాలు రాయండి...'
                : (_isHindi
                    ? 'कृपया समस्या का संक्षिप्त विवरण लिखें...'
                    : 'Enter a short explanation of the issue...'),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Primary Submit Action (>=56dp)
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _submitDispute,
            icon: const Icon(Icons.send_rounded, size: 20),
            label: Text(
              _isTelugu
                  ? 'నివేదిక సమర్పించండి'
                  : (_isHindi ? 'रिपोर्ट जमा करें' : 'Submit Report'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
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
    );
  }

  Widget _buildSuccessConfirmation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen, width: 2.0),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.primaryGreen, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            _isTelugu
                ? 'మీ నివేదిక నమోదు చేయబడింది'
                : (_isHindi
                    ? 'आपकी रिपोर्ट दर्ज कर ली गई है'
                    : 'Your report has been submitted.'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isTelugu
                ? 'సేకరణ అధికారికి తెలియజేయబడింది. టోకెన్ సంఖ్య: ${widget.tokenNumber}'
                : (_isHindi
                    ? 'प्रोक्योरमेंट अधिकारी को सूचित कर दिया गया है। टोकन संख्या: ${widget.tokenNumber}'
                    : 'The Procurement Officer has been notified. Token: ${widget.tokenNumber}'),
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 20, color: AppColors.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isTelugu
                        ? 'కారణం: $_selectedReason'
                        : (_isHindi
                            ? 'कारण: $_selectedReason'
                            : 'Reason: $_selectedReason'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isTelugu
                    ? 'మునుపటి స్క్రీన్‌కు వెళ్లండి'
                    : (_isHindi ? 'वापस जाएं' : 'Return to Previous Screen'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
