import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/supabase_config.dart';
import '../services/auth_service.dart';
import '../services/procurement_state_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_dashboard_screen.dart';

/// Phase 3: Farmer OTP Verification Screen.
///
/// Implements prototype demo authentication with Demo OTP = '123456'.
class FarmerOtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String selectedLanguage;

  const FarmerOtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.selectedLanguage,
  });

  @override
  State<FarmerOtpVerificationScreen> createState() =>
      _FarmerOtpVerificationScreenState();
}

class _FarmerOtpVerificationScreenState
    extends State<FarmerOtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  String? _errorMessage;
  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _resendCountdown = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get _maskedPhoneNumber {
    if (widget.phoneNumber.length >= 10) {
      final last4 = widget.phoneNumber.substring(widget.phoneNumber.length - 4);
      return '+91 ******$last4';
    }
    return '+91 ${widget.phoneNumber}';
  }

  bool get _isTelugu =>
      widget.selectedLanguage == 'తెలుగు' || widget.selectedLanguage == 'te';
  bool get _isHindi =>
      widget.selectedLanguage == 'हिंदी' || widget.selectedLanguage == 'hi';

  void _showVoiceGuidance() {
    final message = _isTelugu
        ? 'వాయిస్ గైడ్: మీ మొబైల్‌కు పంపిన 6-అంకెల OTP కోడ్‌ను నమోదు చేయండి. డెమో పరీక్ష కోసం 1 2 3 4 5 6 ఉపయోగించండి.'
        : (_isHindi
            ? 'वॉइस गाइड: अपने मोबाइल पर भेजे गए 6-अंकीय OTP कोड को दर्ज करें। इस प्रोटोटाइप परीक्षण के लिए डेमो कोड 1 2 3 4 5 6 का उपयोग करें।'
            : 'Voice Guide: Enter the 6-digit OTP code sent to your mobile. For testing this prototype, use demo code 1 2 3 4 5 6.');

    VoiceAssistantSpeechService.instance.speak(
      message,
      language: _isTelugu ? 'te-IN' : (_isHindi ? 'hi-IN' : 'en-IN'),
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

  void _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.length != 6) {
      setState(() {
        _errorMessage = _isTelugu
            ? 'దయచేసి పూర్తి 6-అంకెల OTPని నమోదు చేయండి.'
            : (_isHindi
                ? 'कृपया 6 अंकों का पूरा OTP दर्ज करें।'
                : 'Please enter a complete 6-digit OTP.');
      });
      return;
    }

    final result = await AuthService.instance.verifyFarmerOtp(
      phoneNumber: widget.phoneNumber,
      otp: enteredOtp,
      preferredLanguage: _isTelugu ? 'te' : (_isHindi ? 'hi' : 'en'),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      if (SupabaseConfig.shouldUseSupabase) {
        await ProcurementStateService().loadFromRepositories();
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = null;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => FarmerDashboardScreen(
            phoneNumber: widget.phoneNumber,
            selectedLanguage: widget.selectedLanguage,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = result.errorMessage ??
            (_isTelugu
                ? 'చెల్లని OTP. దయచేసి కోడ్‌ని తనిఖీ చేసి మళ్లీ ప్రయత్నించండి (డెమో: 123456).'
                : (_isHindi
                    ? 'अमान्य OTP। कृपया सही 6-अंकीय कोड दर्ज करें (डेमो: 123456)।'
                    : 'Invalid OTP. Please check the code and try again (Demo: 123456).'));
      });
    }
  }

  void _resendOtp() {
    if (_resendCountdown == 0) {
      _startCountdown();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                _isTelugu
                    ? 'కొత్త OTP పంపబడింది (డెమో: 123456)'
                    : (_isHindi
                        ? 'नया OTP भेजा गया (डेमो: 123456)'
                        : 'New OTP sent (Demo: 123456)'),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.selectedLanguage == 'हिंदी';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Mobile Number',
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
            label: 'Listen to OTP verification voice instructions',
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
                  _isTelugu ? 'Listen / వినండి' : 'Listen / सुनें',
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
                    // Headings
                    const Text(
                      'Enter OTP',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isTelugu
                          ? 'OTP నమోదు చేయండి'
                          : (_isHindi ? 'OTP दर्ज करें' : 'Enter OTP'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isTelugu
                          ? 'ధృవీకరణ కోడ్ ఈ నంబర్‌కు పంపబడింది:'
                          : (isHindi
                              ? 'सत्यापन कोड इस नंबर पर भेजा गया है:'
                              : 'Verification code sent to:'),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    // Masked phone display
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_android_rounded,
                          size: 18,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _maskedPhoneNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // OTP Input Field
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isTelugu
                                  ? '6-అంకెల ధృవీకరణ కోడ్'
                                  : (_isHindi
                                      ? '6-अंकीय सत्यापन कोड'
                                      : '6-Digit Verification Code'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 12.0,
                                color: AppColors.textPrimary,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              decoration: InputDecoration(
                                hintText: '••••••',
                                hintStyle: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 12.0,
                                  color: AppColors.textTertiary
                                      .withValues(alpha: 0.5),
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: _errorMessage != null
                                        ? AppColors.error
                                        : AppColors.cardBorder,
                                    width: _errorMessage != null ? 2 : 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: _errorMessage != null
                                        ? AppColors.error
                                        : AppColors.cardBorder,
                                    width: _errorMessage != null ? 2 : 1,
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
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onChanged: (val) {
                                if (_errorMessage != null) {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                }
                              },
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

                    // Demo Helper Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            size: 20,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isTelugu
                                  ? 'డెమో కోసం OTP కోడ్: 123456'
                                  : (_isHindi
                                      ? 'डेमो के लिए कोड: 123456'
                                      : 'Prototype Demo OTP: 123456'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Resend OTP section
                    Center(
                      child: _resendCountdown > 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isTelugu
                                      ? 'మళ్లీ పంపండి ($_resendCountdown s)'
                                      : (_isHindi
                                          ? 'पुनः भेजें ($_resendCountdown s)'
                                          : 'Resend OTP in $_resendCountdown s'),
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            )
                          : TextButton.icon(
                              onPressed: _resendOtp,
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              label: Text(
                                _isTelugu
                                    ? 'OTP మళ్లీ పంపండి'
                                    : (_isHindi ? 'OTP पुनः भेजें' : 'Resend OTP'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Verify Button
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: ElevatedButton(
                onPressed: _verifyOtp,
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
                          ? 'OTP ధృవీకరించండి'
                          : (_isHindi ? 'OTP सत्यापित करें' : 'Verify OTP'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle_rounded, size: 22),
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
