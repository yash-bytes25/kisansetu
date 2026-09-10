import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_otp_verification_screen.dart';

/// Phase 3: Farmer Phone Login Screen for KisanSetu.
///
/// Collects the Indian 10-digit mobile number and initiates OTP verification.
class FarmerPhoneLoginScreen extends StatefulWidget {
  final String selectedLanguage;

  const FarmerPhoneLoginScreen({
    super.key,
    required this.selectedLanguage,
  });

  @override
  State<FarmerPhoneLoginScreen> createState() => _FarmerPhoneLoginScreenState();
}

class _FarmerPhoneLoginScreenState extends State<FarmerPhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showVoiceGuidance() {
    final isTelugu =
        widget.selectedLanguage == 'తెలుగు' || widget.selectedLanguage == 'te';
    final isHindi =
        widget.selectedLanguage == 'हिंदी' || widget.selectedLanguage == 'hi';

    final message = isTelugu
        ? 'వాయిస్ గైడ్: మీ 10-అంకెల మొబైల్ నంబర్‌ను నమోదు చేయండి. ధృవీకరణ కోసం 6-అంకెల OTP పంపబడుతుంది.'
        : (isHindi
            ? 'वॉइस गाइड: अपना 10-अंकीय मोबाइल नंबर दर्ज करें। हम पहचान सत्यापन के लिए 6-अंकीय OTP कोड भेजेंगे।'
            : 'Voice Guide: Enter your 10-digit mobile number. We will send you a 6-digit OTP code to verify your identity.');

    VoiceAssistantSpeechService.instance.speak(
      message,
      language: isTelugu ? 'te-IN' : (isHindi ? 'hi-IN' : 'en-IN'),
    );

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

  void _onSendOtp() {
    final isTelugu =
        widget.selectedLanguage == 'తెలుగు' || widget.selectedLanguage == 'te';
    final isHindi =
        widget.selectedLanguage == 'हिंदी' || widget.selectedLanguage == 'hi';
    final rawNumber = _phoneController.text.trim();

    // Validation: Exactly 10 digits starting with 6-9
    if (rawNumber.length != 10) {
      setState(() {
        _errorMessage = isTelugu
            ? 'దయచేసి 10 అంకెల సరైన మొబైల్ నంబరును నమోదు చేయండి.'
            : (isHindi
                ? 'कृपया 10 अंकों का मान्य मोबाइल नंबर दर्ज करें।'
                : 'Please enter a valid 10-digit mobile number.');
      });
      return;
    }

    final startsWithValidDigit = RegExp(r'^[6-9]').hasMatch(rawNumber);
    if (!startsWithValidDigit) {
      setState(() {
        _errorMessage = isTelugu
            ? 'మొబైల్ నంబర్ 6, 7, 8 లేదా 9 తో ప్రారంభం కావాలి.'
            : (isHindi
                ? 'मोबाइल नंबर 6, 7, 8 या 9 से शुरू होना चाहिए।'
                : 'Mobile number must start with 6, 7, 8, or 9.');
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerOtpVerificationScreen(
          phoneNumber: rawNumber,
          selectedLanguage: widget.selectedLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTelugu =
        widget.selectedLanguage == 'తెలుగు' || widget.selectedLanguage == 'te';
    final isHindi = widget.selectedLanguage == 'हिंदी';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Language Selection',
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
            label: 'Listen to phone number entry voice instructions',
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
                label: Text(
                  isTelugu ? 'Listen / వినండి' : 'Listen / सुनें',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
                    // Active Language Pill
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.translate_rounded,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Language: ${widget.selectedLanguage}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Headings
                    const Text(
                      'Enter Your Mobile Number',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTelugu
                          ? 'మీ మొబైల్ నంబర్ నమోదు చేయండి'
                          : (isHindi ? 'अपना मोबाइल नंबर दर्ज करें' : 'Enter Your Mobile Number'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTelugu
                          ? 'రైతు ప్రొఫైల్ ధృవీకరణ కోసం 6-అంకెల OTP పంపబడుతుంది.'
                          : (isHindi
                              ? 'सत्यापन के लिए आपके मोबाइल नंबर पर 6 अंकों का OTP भेजा जाएगा।'
                              : 'A 6-digit OTP will be sent to verify your farmer profile.'),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Phone Number Input Card
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTelugu
                                  ? '10-అంకెల మొబైల్ నంబర్'
                                  : (isHindi
                                      ? '10-अंकीय मोबाइल नंबर'
                                      : '10-Digit Mobile Number'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Country Code Prefix
                                Container(
                                  height: 56,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: AppColors.cardBorder),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '+91',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Number TextField
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    autofocus: true,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: AppColors.textPrimary,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: InputDecoration(
                                      hintText: isTelugu
                                          ? '10 అంకెల నంబర్ నమోదు చేయండి'
                                          : (isHindi
                                              ? 'मोबाइल नंबर दर्ज करें'
                                              : 'Enter 10 digits'),
                                      hintStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0,
                                        color: AppColors.textTertiary,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.surfaceVariant,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: _errorMessage != null
                                              ? AppColors.error
                                              : AppColors.cardBorder,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: _errorMessage != null
                                              ? AppColors.error
                                              : AppColors.cardBorder,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: _errorMessage != null
                                              ? AppColors.error
                                              : AppColors.primaryGreen,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                    onChanged: (val) {
                                      if (_errorMessage != null) {
                                        setState(() {
                                          _errorMessage = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // Error display (non-color-reliant: icon + text)
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.error),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Security / Privacy Note
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isTelugu
                                  ? 'మీ నంబర్ సురక్షితమైనది మరియు కేవలం కొనుగోలు ట్రాకింగ్ మరియు చెల్లింపు నోటీసుల కోసం మాత్రమే ఉపయోగించబడుతుంది.'
                                  : (isHindi
                                      ? 'आपका नंबर सुरक्षित है और इसका उपयोग केवल खरीद स्थिति और भुगतान अधिसूचनाओं के लिए किया जाएगा।'
                                      : 'Your number is secure and used only for procurement tracking and payment notices.'),
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

            // Bottom Send OTP Button
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: ElevatedButton(
                onPressed: _onSendOtp,
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
                      isTelugu ? 'OTP పంపండి' : (isHindi ? 'OTP भेजें' : 'Send OTP'),
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
}
