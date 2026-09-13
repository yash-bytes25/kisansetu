import 'package:flutter/material.dart';
import '../models/farmer_dashboard_data.dart';
import '../models/procurement_centre.dart';
import '../models/procurement_slot.dart';
import '../services/smart_slot_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_slot_confirmation_screen.dart';

/// Screen presenting the Smart Slot Recommendations.
///
/// Features the "Best Time to Visit" decision support for farmers.
class FarmerSmartSlotScreen extends StatefulWidget {
  final ProcurementCentre selectedCentre;
  final FarmerDashboardData currentData;
  final bool isHindi;
  final bool isTelugu;

  const FarmerSmartSlotScreen({
    super.key,
    required this.selectedCentre,
    required this.currentData,
    required this.isHindi,
    this.isTelugu = false,
  });

  @override
  State<FarmerSmartSlotScreen> createState() => _FarmerSmartSlotScreenState();
}

class _FarmerSmartSlotScreenState extends State<FarmerSmartSlotScreen> {
  bool get _isHindi => widget.isHindi;
  bool get _isTelugu => widget.isTelugu;

  late final List<ProcurementSlot> _slots;
  ProcurementSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _slots = SmartSlotService.recommendSlots(
      centre: widget.selectedCentre,
      crop: widget.currentData.crop,
    );
    // Default to the recommended slot
    _selectedSlot = _slots.firstWhere(
      (s) => s.isRecommended,
      orElse: () => _slots.first,
    );
  }

  void _showVoiceGuidance() {
    final message = _isTelugu
        ? 'వాయిస్ గైడ్: సిఫార్సు చేయబడిన సమయం 11:30 AM, ఇందులో కేవలం 15 నిమిషాల వేచి ఉండే సమయం ఉంటుంది. స్లాట్‌ను ఎంచుకుని ముందుకు సాగండి.'
        : (_isHindi
            ? 'आवाज गाइड: अनुशंसित समय 11:30 AM है जिसमें केवल 15 मिनट प्रतीक्षा समय है। अपनी पसंद का स्लॉट चुनें और आगे बढ़ें।'
            : 'Voice Guide: The recommended slot is 11:30 AM with the lowest expected wait time of 15 minutes. Select a slot and tap Continue.');

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
    if (_selectedSlot == null) return;

    final result = await Navigator.of(context).push<FarmerDashboardData?>(
      MaterialPageRoute<FarmerDashboardData?>(
        builder: (context) => FarmerSlotConfirmationScreen(
          centre: widget.selectedCentre,
          slot: _selectedSlot!,
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
          tooltip: 'Back to Centre Selection',
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
            label: 'Listen to smart slot voice guidance',
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
                          ? 'మీకు అనుకూలమైన సమయం'
                          : (_isHindi ? 'आपके लिए सही समय' : 'Best Time to Visit'),
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isTelugu
                          ? 'కేంద్ర సామర్థ్యం, ప్రస్తుత క్యూ మరియు ఆశించిన ప్రాసెసింగ్ సమయం ఆధారంగా సిఫార్సు చేయబడింది.'
                          : (_isHindi
                              ? 'केंद्र क्षमता, वर्तमान कतार और अपेक्षित प्रसंस्करण समय के आधार पर अनुशंसित।'
                              : 'Recommended based on centre capacity, current queue, and expected processing time.'),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // Centre quick banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.store_rounded,
                            size: 18,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.selectedCentre.name,
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
                    const SizedBox(height: 18),

                    // Slot options list
                    ..._slots.map((slot) => _buildSlotCard(slot)),
                  ],
                ),
              ),
            ),

            // Bottom Continue Button (56dp height)
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: ElevatedButton(
                onPressed: _selectedSlot != null ? _onContinue : null,
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
                          ? 'ముందుకు సాగండి'
                          : (_isHindi ? 'आगे बढ़ें' : 'Continue'),
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

  Widget _buildSlotCard(ProcurementSlot slot) {
    final isSelected = _selectedSlot?.id == slot.id;
    final isRecommended = slot.isRecommended;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Semantics(
        label:
            '${slot.time} slot, ${slot.tag}. Expected wait: ${slot.expectedWait}. ${isRecommended ? 'Recommended option.' : ''}',
        selected: isSelected,
        button: true,
        child: Material(
          color: isSelected
              ? AppColors.primaryContainer
              : (isRecommended ? AppColors.surface : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSlot = slot;
              });
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.primaryLight.withValues(alpha: 0.2),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : (isRecommended
                          ? AppColors.primaryLight
                          : AppColors.cardBorder),
                  width: isSelected ? 2.5 : (isRecommended ? 2.0 : 1.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              slot.time,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Status Tag (e.g. Recommended, Good, Busy)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isRecommended
                                      ? AppColors.primaryGreen
                                      : (slot.tag == 'Busy'
                                          ? AppColors.errorContainer
                                          : AppColors.surfaceVariant),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isRecommended
                                        ? AppColors.primaryGreen
                                        : (slot.tag == 'Busy'
                                            ? AppColors.error
                                            : AppColors.cardBorder),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isRecommended) ...[
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                      Text(
                                        _isTelugu
                                            ? (isRecommended
                                                ? 'సిఫార్సు చేయబడింది'
                                                : (slot.tag == 'Busy'
                                                    ? 'రద్దీ'
                                                    : slot.tag))
                                            : (_isHindi
                                                ? (isRecommended
                                                    ? 'अनुशंसित'
                                                    : (slot.tag == 'Busy'
                                                        ? 'व्यस्त'
                                                        : slot.tag))
                                                : slot.tag),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isRecommended
                                              ? Colors.white
                                              : (slot.tag == 'Busy'
                                                  ? AppColors.error
                                                  : AppColors.textPrimary),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Non-color-only Selection Indicator
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                                  fontSize: 11,
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
                  const SizedBox(height: 10),

                  // Expected wait and arrival wrap
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isTelugu
                                ? 'అంచనా వేచి ఉండే సమయం: ${slot.expectedWait}'
                                : (_isHindi
                                    ? 'अपेक्षित प्रतीक्षा: ${slot.expectedWait}'
                                    : 'Expected wait: ${slot.expectedWait}'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isTelugu
                                ? 'చేరుకునే సమయం: ${slot.recommendedArrival}'
                                : (_isHindi
                                    ? 'आगमन: ${slot.recommendedArrival}'
                                    : 'Arrival: ${slot.recommendedArrival}'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
