import 'package:flutter/material.dart';
import '../services/app_preferences_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';

/// Language and Voice Preferences bottom-sheet modal.
///
/// Allows the farmer to independently set:
///   1. **UI Language** — all text/subtitles across the app
///   2. **Voice Language** — language spoken by the voice assistant
///
/// Can be shown from the Role Selection screen and from the More tab on the
/// Farmer Dashboard using [LanguagePreferencesScreen.show].
class LanguagePreferencesScreen extends StatefulWidget {
  const LanguagePreferencesScreen({super.key});

  /// Convenience method to show this screen as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LanguagePreferencesScreen(),
    );
  }

  @override
  State<LanguagePreferencesScreen> createState() =>
      _LanguagePreferencesScreenState();
}

class _LanguagePreferencesScreenState
    extends State<LanguagePreferencesScreen> {
  final _prefs = AppPreferencesService.instance;

  late String _uiLang;
  late String _voiceLang;

  static const _languages = [
    _LangEntry(code: 'en', native: 'English',  english: 'English', flag: '🇮🇳'),
    _LangEntry(code: 'hi', native: 'हिंदी',    english: 'Hindi',   flag: '🇮🇳'),
    _LangEntry(code: 'te', native: 'తెలుగు',   english: 'Telugu',  flag: '🇮🇳'),
  ];

  @override
  void initState() {
    super.initState();
    _uiLang    = _prefs.uiLanguage;
    _voiceLang = _prefs.voiceLanguage;
  }

  void _applyAndClose() {
    _prefs.setUiLanguage(_uiLang, syncVoice: false);
    _prefs.setVoiceLanguage(_voiceLang);
    Navigator.of(context).pop();
  }

  void _testVoice() {
    final fullLocale = _voiceLang == 'te'
        ? 'te-IN'
        : (_voiceLang == 'hi' ? 'hi-IN' : 'en-IN');
    final sample = _voiceLang == 'te'
        ? 'నమస్కారం! కిసాన్‌సేతు వాయిస్ సహాయకుడు సిద్ధంగా ఉన్నాడు.'
        : (_voiceLang == 'hi'
            ? 'नमस्ते! किसानसेतु आवाज सहायक तैयार है।'
            : 'Hello! KisanSetu Voice Assistant is ready.');
    VoiceAssistantSpeechService.instance.speak(sample, language: fullLocale);
  }

  String get _headingUi => _uiLang == 'te'
      ? 'భాష & వాయిస్ ప్రాధాన్యతలు'
      : (_uiLang == 'hi' ? 'भाषा और आवाज़ सेटिंग्स' : 'Language & Voice Settings');

  String get _uiLangLabel => _uiLang == 'te'
      ? 'UI భాష'
      : (_uiLang == 'hi' ? 'UI भाषा' : 'UI Language');

  String get _voiceLangLabel => _uiLang == 'te'
      ? 'వాయిస్ భాష'
      : (_uiLang == 'hi' ? 'आवाज़ भाषा' : 'Voice Language');

  String get _testLabel => _uiLang == 'te'
      ? 'వాయిస్ పరీక్షించండి'
      : (_uiLang == 'hi' ? 'आवाज़ परीक्षण करें' : 'Test Voice');

  String get _applyLabel => _uiLang == 'te'
      ? 'వర్తింపజేయి'
      : (_uiLang == 'hi' ? 'लागू करें' : 'Apply');

  String get _noteText => _uiLang == 'te'
      ? 'మీరు UI మరియు వాయిస్‌ను వేర్వేరుగా సెట్ చేయవచ్చు.'
      : (_uiLang == 'hi'
          ? 'UI और आवाज़ भाषा अलग-अलग सेट की जा सकती है।'
          : 'You can set UI and Voice languages independently.');

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.50,
      maxChildSize: 0.90,
      builder: (ctx, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.language_rounded,
                            color: AppColors.primaryGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _headingUi,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textSecondary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      _noteText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── UI Language ────────────────────────────────────────
                    _SectionHeader(
                      icon: Icons.text_fields_rounded,
                      label: _uiLangLabel,
                    ),
                    const SizedBox(height: 10),
                    ..._languages.map((l) => _LangTile(
                          entry: l,
                          isSelected: _uiLang == l.code,
                          accentColor: AppColors.primaryGreen,
                          onTap: () => setState(() => _uiLang = l.code),
                        )),

                    const SizedBox(height: 20),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 20),

                    // ── Voice Language ─────────────────────────────────────
                    _SectionHeader(
                      icon: Icons.record_voice_over_rounded,
                      label: _voiceLangLabel,
                    ),
                    const SizedBox(height: 10),
                    ..._languages.map((l) => _LangTile(
                          entry: l,
                          isSelected: _voiceLang == l.code,
                          accentColor: AppColors.accentAmber,
                          onTap: () => setState(() => _voiceLang = l.code),
                        )),

                    const SizedBox(height: 20),

                    // Test Voice button
                    OutlinedButton.icon(
                      onPressed: _testVoice,
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: Text(_testLabel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentAmber,
                        side: const BorderSide(color: AppColors.accentAmber),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Apply button
                    ElevatedButton(
                      onPressed: _applyAndClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _applyLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Internal helper widgets ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LangTile extends StatelessWidget {
  final _LangEntry entry;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _LangTile({
    required this.entry,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? accentColor.withValues(alpha: 0.08)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accentColor : AppColors.cardBorder,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Text(entry.flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.native,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? accentColor
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        entry.english,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: accentColor, size: 22)
                else
                  Icon(Icons.radio_button_unchecked_rounded,
                      color: AppColors.cardBorder, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LangEntry {
  final String code;
  final String native;
  final String english;
  final String flag;
  const _LangEntry(
      {required this.code,
      required this.native,
      required this.english,
      required this.flag});
}
