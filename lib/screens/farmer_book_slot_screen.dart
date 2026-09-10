import 'package:flutter/material.dart';
import '../models/farmer_dashboard_data.dart';
import '../models/procurement_centre.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_smart_slot_screen.dart';

/// Screen allowing the farmer to select a procurement centre and confirm produce before slot recommendation.
class FarmerBookSlotScreen extends StatefulWidget {
  final FarmerDashboardData currentData;
  final bool isHindi;
  final bool isTelugu;

  const FarmerBookSlotScreen({
    super.key,
    required this.currentData,
    required this.isHindi,
    this.isTelugu = false,
  });

  @override
  State<FarmerBookSlotScreen> createState() => _FarmerBookSlotScreenState();
}

class _FarmerBookSlotScreenState extends State<FarmerBookSlotScreen> {
  bool get _isHindi => widget.isHindi;
  bool get _isTelugu => widget.isTelugu;

  late final List<ProcurementCentre> _centres;
  ProcurementCentre? _selectedCentre;

  @override
  void initState() {
    super.initState();
    _centres = ProcurementCentre.getMockCentres();
    // Default to first centre for low cognitive load
    _selectedCentre = _centres.isNotEmpty ? _centres.first : null;
  }

  void _showVoiceGuidance() {
    final message = _isTelugu
        ? 'వాయిస్ గైడ్: మీ సమీప సేకరణ కేంద్రాన్ని ఎంచుకోండి మరియు కొనసాగడానికి మీ గోధుమ పంటను ధృవీకరించండి.'
        : (_isHindi
            ? 'आवाज गाइड: अपने नजदीकी खरीद केंद्र का चयन करें और अपनी गेहूं की फसल की पुष्टि करके आगे बढ़ें।'
            : 'Voice Guide: Select your nearest procurement centre and verify your wheat produce to continue.');

    VoiceAssistantSpeechService.instance.speak(
      message,
      language: _isTelugu
          ? 'te-IN'
          : (_isHindi ? 'hi-IN' : 'en-IN'),
    );

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
            const Icon(
              Icons.volume_up_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
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

  void _onContinue() async {
    if (_selectedCentre == null) return;

    final result = await Navigator.of(context).push<FarmerDashboardData?>(
      MaterialPageRoute<FarmerDashboardData?>(
        builder: (context) => FarmerSmartSlotScreen(
          selectedCentre: _selectedCentre!,
          currentData: widget.currentData,
          isHindi: _isHindi,
          isTelugu: _isTelugu,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Dashboard',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'KisanSetu',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            label: 'Listen to booking guidance',
            button: true,
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton.icon(
                onPressed: _showVoiceGuidance,
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                label: Text(
                  _isTelugu ? 'Listen / వినండి' : 'Listen / सुनें',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Headings
                    Text(
                      _isTelugu
                          ? 'సేకరణ స్లాట్ బుక్ చేయండి'
                          : (_isHindi
                              ? 'प्रोक्योरमेंट स्लॉट बुक करें'
                              : 'Book Procurement Slot'),
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isTelugu
                          ? 'సమీప కేంద్రాన్ని మరియు అనుకూలమైన సమయాన్ని ఎంచుకోండి.'
                          : (_isHindi
                              ? 'पास का खरीद केंद्र और उपयुक्त समय चुनें।'
                              : 'Choose a nearby centre and a suitable time.'),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // SECTION 1: Registered Produce Confirmation Card
                    _buildProduceConfirmationCard(),
                    const SizedBox(height: 24),

                    // SECTION 2: Select Centre Heading
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isTelugu
                              ? 'సేకరణ కేంద్రాన్ని ఎంచుకోండి'
                              : (_isHindi
                                  ? 'खरीद केंद्र चुनें'
                                  : 'Select Procurement Centre'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Centre selection cards
                    ..._centres.map((centre) => _buildCentreCard(centre)),
                  ],
                ),
              ),
            ),

            // Bottom Continue Action Button (56dp height)
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: ElevatedButton(
                onPressed: _selectedCentre != null ? _onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isTelugu
                          ? 'ఉత్తమ స్లాట్ ఎంచుకోండి'
                          : (_isHindi
                              ? 'सर्वोत्तम स्लॉट चुनें'
                              : 'Continue to Best Slot'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduceConfirmationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTelugu
                          ? 'మీ పంట'
                          : (_isHindi ? 'आपकी उपज' : 'Your Produce'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${widget.currentData.crop} • ${widget.currentData.quantityQuintals} Quintals',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.currentData.estimatedMspValue,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                _isTelugu
                    ? 'మీ రిజిస్టర్డ్ పంట నుండి'
                    : (_isHindi
                        ? 'आपकी पंजीकृत उपज से'
                        : 'From your registered produce'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCentreCard(ProcurementCentre centre) {
    final isSelected = _selectedCentre?.id == centre.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Semantics(
        label:
            '${centre.name}, ${centre.subLocation}. Distance: ${centre.distanceKm} km. Queue: ${centre.queueEstimate}.',
        selected: isSelected,
        button: true,
        child: Material(
          color: isSelected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedCentre = centre;
              });
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.primaryLight.withValues(alpha: 0.2),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primaryGreen : AppColors.cardBorder,
                  width: isSelected ? 2.5 : 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.surface
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store_mall_directory_rounded,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              centre.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              centre.subLocation,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isTelugu
                                    ? 'ఎంచుకోబడింది'
                                    : (_isHindi ? 'चयनित' : 'Selected'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Icon(
                          Icons.radio_button_unchecked_rounded,
                          size: 22,
                          color: AppColors.textTertiary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Distance badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${centre.distanceKm} km',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Queue badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: centre.queueStatus == 'Low'
                              ? AppColors.primaryGreen.withValues(alpha: 0.12)
                              : AppColors.warningContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.groups_rounded,
                              size: 14,
                              color: centre.queueStatus == 'Low'
                                  ? AppColors.primaryGreen
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isTelugu
                                  ? 'క్యూ: ${centre.queueStatus == 'Low' ? 'తక్కువ' : 'మధ్యస్థం'} (${centre.queueEstimate})'
                                  : (_isHindi
                                      ? 'कतार: ${centre.queueStatus == 'Low' ? 'कम' : 'मध्यम'} (${centre.queueEstimate})'
                                      : 'Queue: ${centre.queueStatus} (${centre.queueEstimate})'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: centre.queueStatus == 'Low'
                                    ? AppColors.primaryGreen
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
