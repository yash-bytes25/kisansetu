import 'package:flutter/material.dart';
import '../services/app_preferences_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_language_selection_screen.dart';
import 'language_preferences_screen.dart';
import 'officer_login_screen.dart';

/// Phase 1: Role Selection Screen for KisanSetu.
///
/// Now a [StatefulWidget] that listens to [AppPreferencesService] so the UI
/// language and voice language updates immediately when the farmer selects a
/// language from the top language bar.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _prefs = AppPreferencesService.instance;

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  // ── Localised strings ────────────────────────────────────────────────────

  String get _heading => _prefs.isTelugu
      ? 'మీరు ఎవరు?'
      : (_prefs.isHindi ? 'आप कौन हैं?' : 'Who are you?');

  String get _subheading => _prefs.isTelugu
      ? 'కొనసాగించడానికి మీ పాత్రను ఎంచుకోండి'
      : (_prefs.isHindi
          ? 'जारी रखने के लिए अपनी भूमिका चुनें'
          : 'Select your role to continue');

  String get _farmerTitle => _prefs.isTelugu
      ? 'నేను రైతును'
      : (_prefs.isHindi ? 'मैं किसान हूं' : 'I am a Farmer');

  String get _farmerSubtitle => _prefs.isTelugu
      ? 'బుక్ • ట్రాక్ • చెల్లింపు పొందు'
      : (_prefs.isHindi
          ? 'बुक करें • ट्रैक करें • पैसे पाएं'
          : 'Book • Track • Get Paid');

  String get _officerTitle => _prefs.isTelugu
      ? 'సేకరణ అధికారి'
      : (_prefs.isHindi ? 'खरीद अधिकारी' : 'Procurement Officer');

  String get _officerSubtitle => _prefs.isTelugu
      ? 'నిర్వహించు • పర్యవేక్షించు • ధృవీకరించు'
      : (_prefs.isHindi
          ? 'प्रबंधित करें • मॉनिटर करें • सत्यापित करें'
          : 'Manage • Monitor • Verify');

  String get _hintText => _prefs.isTelugu
      ? 'సులభమైన ఒకే స్పర్శ ఎంపికకు పెద్ద ట్యాప్ లక్ష్యాలు రూపొందించబడ్డాయి.'
      : (_prefs.isHindi
          ? 'एक-टच आसान चयन के लिए बड़े टैप लक्ष्य डिज़ाइन किए गए हैं।'
          : 'Large tap targets designed for one-touch easy selection.');

  String get _listenLabel => _prefs.isTelugu
      ? 'Listen / వినండి'
      : 'Listen / सुनें';

  // ── Voice guidance ───────────────────────────────────────────────────────

  void _showVoiceGuidance() {
    final message = _prefs.isTelugu
        ? 'కిసాన్‌సేతు: రైతు అయితే "నేను రైతును" నొక్కండి. అధికారి అయితే "సేకరణ అధికారి" నొక్కండి.'
        : (_prefs.isHindi
            ? 'किसानसेतु: किसान हैं तो "मैं किसान हूं" दबाएं। अधिकारी हैं तो "खरीद अधिकारी" दबाएं।'
            : 'Voice Guide: Tap "I am a Farmer" to book, track, and receive payment. Tap "Procurement Officer" to manage and verify.');
    VoiceAssistantSpeechService.instance
        .speak(message, language: _prefs.voiceLocale);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco_rounded,
                  color: AppColors.primaryGreen, size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'KisanSetu',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          // ── Combined Listen + Language picker pill ─────────────────────
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Listen button
                TextButton.icon(
                  onPressed: _showVoiceGuidance,
                  icon: const Icon(Icons.volume_up_rounded,
                      color: AppColors.primaryGreen, size: 18),
                  label: Text(
                    _listenLabel,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding:
                        const EdgeInsets.only(left: 10, right: 6, top: 6, bottom: 6),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                ),

                // Divider
                Container(
                    width: 1, height: 20,
                    color: AppColors.primaryGreen.withValues(alpha: 0.3)),

                // Settings icon → opens full preferences modal
                InkWell(
                  onTap: () => LanguagePreferencesScreen.show(context),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Icon(Icons.language_rounded,
                        color: AppColors.primaryGreen, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Branding & Subtitle
              const Text(
                'Smart Procurement Management',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'SIH26032 • Team ODE TO CODE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 16),

              // ── Language Quick-select Bar ─────────────────────────────
              _LanguageBar(
                current: _prefs.uiLanguage,
                onSelect: (code) => _prefs.setUiLanguage(code),
              ),
              const SizedBox(height: 20),

              // Question Section
              Text(_heading, style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text(_subheading, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),

              // CARD 1: Farmer Card
              _buildRoleCard(
                context: context,
                roleTitle: _farmerTitle,
                roleSubtitle: _farmerSubtitle,
                icon: Icons.agriculture_rounded,
                iconColor: AppColors.primaryGreen,
                containerColor: AppColors.primaryContainer,
                semanticDescription:
                    'Farmer role card. Book procurement, track progress, and get paid.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          const FarmerLanguageSelectionScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // CARD 2: Procurement Officer Card
              _buildRoleCard(
                context: context,
                roleTitle: _officerTitle,
                roleSubtitle: _officerSubtitle,
                icon: Icons.badge_rounded,
                iconColor: AppColors.secondary,
                containerColor: AppColors.secondaryContainer,
                semanticDescription:
                    'Procurement Officer role card. Manage operations and verify.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const OfficerLoginScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Accessibility hint
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded,
                        size: 22, color: AppColors.primaryGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_hintText, style: AppTextStyles.caption),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String roleTitle,
    required String roleSubtitle,
    required IconData icon,
    required Color iconColor,
    required Color containerColor,
    required String semanticDescription,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: semanticDescription,
      button: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: containerColor,
          highlightColor: containerColor.withValues(alpha: 0.4),
          child: Container(
            constraints: const BoxConstraints(minHeight: 110),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 38, color: iconColor),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        roleTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        roleSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Language quick-select bar ────────────────────────────────────────────────

/// A compact row of three language toggle chips shown on the Role Selection
/// screen. Tapping one immediately updates [AppPreferencesService].
class _LanguageBar extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelect;

  const _LanguageBar({required this.current, required this.onSelect});

  static const _options = [
    ('en', 'English'),
    ('hi', 'हिंदी'),
    ('te', 'తెలుగు'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: _options.map((opt) {
          final (code, label) = opt;
          final isActive = current == code;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
