import 'package:flutter/material.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_phone_login_screen.dart';

/// Phase 2: Farmer Language Selection Screen for KisanSetu.
///
/// Designed with RECOGNIZE → TAP → UNDERSTAND philosophy:
/// - Visual-first large language cards
/// - English and Hindi options
/// - Clear non-color-only selected states (check indicator, badge, border weight)
/// - Voice guidance action
/// - Requires selection to continue to the phone login placeholder
class FarmerLanguageSelectionScreen extends StatefulWidget {
  const FarmerLanguageSelectionScreen({super.key});

  @override
  State<FarmerLanguageSelectionScreen> createState() =>
      _FarmerLanguageSelectionScreenState();
}

class _FarmerLanguageSelectionScreenState
    extends State<FarmerLanguageSelectionScreen> {
  String? _selectedLanguage; // 'en' or 'hi'

  void _showVoiceGuidance() {
    final isTelugu = _selectedLanguage == 'te';
    final isHindi = _selectedLanguage == 'hi';

    final message = isTelugu
        ? 'వాయిస్ గైడ్: మీరు తెలుగు భాషను ఎంచుకున్నారు. కొనసాగడానికి క్రింద ఉన్న బటన్‌ను నొక్కండి.'
        : (isHindi
            ? 'वॉइस गाइड: आपने हिंदी भाषा का चयन किया है। आगे बढ़ने के लिए नीचे दिए गए बटन पर टैप करें।'
            : (_selectedLanguage == 'en'
                ? 'Voice Guide: You have selected English. Tap Continue at the bottom to proceed.'
                : 'Voice Guide: Choose your preferred language. Tap English, Hindi, or Telugu, then tap Continue at the bottom.'));

    final langCode = isTelugu ? 'te-IN' : (isHindi ? 'hi-IN' : 'en-IN');
    VoiceAssistantSpeechService.instance.speak(message, language: langCode);

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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onContinue() {
    if (_selectedLanguage == null) return;

    final languageLabel = _selectedLanguage == 'te'
        ? 'తెలుగు'
        : (_selectedLanguage == 'hi' ? 'हिंदी' : 'English');

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerPhoneLoginScreen(
          selectedLanguage: languageLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Role Selection',
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
                Icons.eco_rounded,
                color: AppColors.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'KisanSetu',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            label: 'Listen to language selection voice guide',
            button: true,
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton.icon(
                onPressed: _showVoiceGuidance,
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
                label: const Text(
                  'Listen / వినండి / सुनें',
                  style: TextStyle(
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Headings
                    const Text(
                      'Choose Your Language',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'अपनी भाषा चुनें • మీ భాషను ఎంచుకోండి',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the language you are comfortable using.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // CARD 1: English
                    _buildLanguageCard(
                      code: 'en',
                      primaryTitle: 'English',
                      secondaryTitle: 'English',
                      icon: Icons.language_rounded,
                      semanticLabel:
                          'Select English language. Tap to select.',
                    ),
                    const SizedBox(height: 14),

                    // CARD 2: Hindi
                    _buildLanguageCard(
                      code: 'hi',
                      primaryTitle: 'हिंदी',
                      secondaryTitle: 'Hindi',
                      icon: Icons.translate_rounded,
                      semanticLabel:
                          'हिंदी भाषा का चयन करें. Tap to select Hindi.',
                    ),
                    const SizedBox(height: 14),

                    // CARD 3: Telugu
                    _buildLanguageCard(
                      code: 'te',
                      primaryTitle: 'తెలుగు',
                      secondaryTitle: 'Telugu',
                      icon: Icons.g_translate_rounded,
                      semanticLabel:
                          'తెలుగు భాషను ఎంచుకోండి. Tap to select Telugu.',
                    ),
                    const SizedBox(height: 20),

                    // Accessibility visual hint
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 22,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tap any card to select. The checkmark indicates your active choice.',
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Prominent Bottom Continue Action
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: ElevatedButton(
                onPressed: _selectedLanguage != null ? _onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  disabledBackgroundColor: AppColors.cardBorder,
                  disabledForegroundColor: AppColors.textTertiary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedLanguage == 'te'
                          ? 'ముందుకు సాగండి'
                          : (_selectedLanguage == 'hi'
                              ? 'आगे बढ़ें'
                              : 'Continue'),
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

  Widget _buildLanguageCard({
    required String code,
    required String primaryTitle,
    required String secondaryTitle,
    required IconData icon,
    required String semanticLabel,
  }) {
    final isSelected = _selectedLanguage == code;

    return Semantics(
      label: semanticLabel,
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? AppColors.primaryContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedLanguage = code;
            });
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primaryLight.withValues(alpha: 0.2),
          child: Container(
            constraints: const BoxConstraints(minHeight: 90),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isSelected ? AppColors.primaryGreen : AppColors.cardBorder,
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              children: [
                // Visual Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: isSelected ? Colors.white : AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),

                // Language text labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        primaryTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        secondaryTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection Indicator (Non-color reliant: Checkmark vs circle + label)
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Selected',
                          style: TextStyle(
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
                    size: 26,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
