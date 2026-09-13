import 'package:flutter/material.dart';
import '../models/farmer_payment_record.dart';
import '../services/app_preferences_service.dart';
import '../services/payment_calculation_service.dart';
import '../services/procurement_state_service.dart';
import '../services/repositories/repository_provider.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_payment_screen.dart';

/// Screen presenting the logged-in farmer's procurement payment history.
///
/// Designed with RECOGNIZE → TAP → UNDERSTAND philosophy:
/// - Displays chronological procurement payment cards sorted newest first.
/// - Clear visibility of crop, quantity, centre, amount, date, status, and reference.
/// - Selecting any payment navigates to the detailed transparency/receipt screen
///   for THAT specific transaction where the farmer can download the invoice/receipt.
/// - Clear, friendly empty state ("No payments received yet") when no records exist.
class FarmerPaymentHistoryScreen extends StatefulWidget {
  final List<FarmerPaymentRecord>? customPayments;
  final bool isHindi;
  final bool isTelugu;

  const FarmerPaymentHistoryScreen({
    super.key,
    this.customPayments,
    this.isHindi = false,
    this.isTelugu = false,
  });

  @override
  State<FarmerPaymentHistoryScreen> createState() =>
      _FarmerPaymentHistoryScreenState();
}

class _FarmerPaymentHistoryScreenState
    extends State<FarmerPaymentHistoryScreen> {
  final _service = ProcurementStateService();
  final _prefs = AppPreferencesService.instance;

  bool _isLoading = true;
  List<FarmerPaymentRecord> _payments = [];

  bool get _isHindi => widget.isHindi || (!widget.isTelugu && _prefs.isHindi);
  bool get _isTelugu => widget.isTelugu || (!widget.isHindi && _prefs.isTelugu);

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    if (widget.customPayments != null) {
      final list = List<FarmerPaymentRecord>.from(widget.customPayments!);
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      setState(() {
        _payments = list;
        _isLoading = false;
      });
      return;
    }

    try {
      final farmerId = '22222222-2222-2222-2222-222222222222';
      final rawList = await RepositoryProvider.payment.getFarmerPayments(farmerId);
      final parsed = rawList.map((m) => FarmerPaymentRecord.fromMap(m)).toList();
      parsed.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      if (mounted) {
        setState(() {
          _payments = parsed;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showVoiceGuidance() {
    final guideText = _payments.isEmpty
        ? (_isTelugu
            ? 'వాయిస్ గైడ్: ఇంకా ఎలాంటి చెల్లింపులు అందలేదు. తూకం మరియు ఆమోదం పూర్తయిన తర్వాత చెల్లింపులు ఇక్కడ కనిపిస్తాయి.'
            : (_isHindi
                ? 'आवाज गाइड: अभी तक कोई भुगतान प्राप्त नहीं हुआ। तौल और स्वीकृति के बाद भुगतान यहां दिखाई देंगे।'
                : 'Voice Guide: No payments received yet. Transactions will appear here once procurement is accepted.'))
        : (_isTelugu
            ? 'వాయిస్ గైడ్: మీ వద్ద ${_payments.length} చెల్లింపు రికార్డులు ఉన్నాయి. రసీదు చూడటానికి మరియు డౌన్‌లోడ్ చేయడానికి లావాదేవీని ఎంచుకోండి.'
            : (_isHindi
                ? 'आवाज गाइड: आपके पास ${_payments.length} भुगतान रिकॉर्ड हैं। रसीद देखने और डाउनलोड करने के लिए लेनदेन चुनें।'
                : 'Voice Guide: You have ${_payments.length} payment records. Tap any transaction to view transparency breakdown and download receipt.'));

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

  void _onSelectPayment(FarmerPaymentRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerPaymentScreen(
          isHindi: _isHindi,
          isTelugu: _isTelugu,
          paymentData: record.toDashboardData(
            farmerName: _service.farmerData.farmerName,
          ),
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
                Icons.receipt_long_rounded,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isTelugu
                  ? 'నా చెల్లింపులు'
                  : (_isHindi ? 'भुगतान इतिहास' : 'Payment History'),
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              )
            : _payments.isEmpty
                ? _buildEmptyState()
                : _buildPaymentList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
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
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isTelugu
                    ? 'ఇంకా ఎలాంటి చెల్లింపులు అందలేదు'
                    : (_isHindi
                        ? 'अभी तक कोई भुगतान प्राप्त नहीं हुआ'
                        : 'No payments received yet'),
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isTelugu
                    ? 'సేకరణ కేంద్రం వద్ద తూకం మరియు ఆమోదం పూర్తయిన తర్వాత మీ DBT చెల్లింపులు ఇక్కడ కనిపిస్తాయి.'
                    : (_isHindi
                        ? 'खरीद केंद्र पर तौल और स्वीकृति पूरी होने के बाद आपके डीबीटी भुगतान यहां दिखाई देंगे।'
                        : 'Your DBT procurement payments will appear here once weighment is accepted at the centre.'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20.0),
      itemCount: _payments.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isTelugu
                      ? 'సేకరణ లావాదేవీలు'
                      : (_isHindi ? 'खरीद लेनदेन' : 'Procurement Transactions'),
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isTelugu
                      ? 'రసీదు డౌన్‌లోడ్ చేయడానికి లావాదేవీని ఎంచుకోండి'
                      : (_isHindi
                          ? 'रसीद डाउनलोड करने के लिए लेनदेन चुनें'
                          : 'Select a payment to download receipt & view breakdown'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final payment = _payments[index - 1];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(FarmerPaymentRecord payment) {
    final isCompleted = payment.paymentStatus.toLowerCase().contains('completed') ||
        payment.paymentStatus.toLowerCase().contains('success');
    final isProcessing = payment.paymentStatus.toLowerCase().contains('processing') ||
        payment.paymentStatus.toLowerCase().contains('initiated');

    final Color statusColor = isCompleted
        ? AppColors.primaryGreen
        : (isProcessing ? AppColors.secondary : AppColors.warning);
    final Color statusBg = isCompleted
        ? AppColors.primaryContainer
        : (isProcessing ? AppColors.secondary.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.12));

    final String statusLabel = isCompleted
        ? (_isTelugu ? 'పూర్తయింది' : (_isHindi ? 'पूर्ण' : 'Completed'))
        : (isProcessing
            ? (_isTelugu ? 'ప్రక్రియలో ఉంది' : (_isHindi ? 'प्रक्रियाधीन' : 'Processing'))
            : (_isTelugu ? 'పెండింగ్‌లో ఉంది' : (_isHindi ? 'लंबित' : 'Pending')));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onSelectPayment(payment),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Crop Name & Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: AppColors.primaryGreen,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          payment.cropName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle Row: Quantity & Procurement Centre
                Row(
                  children: [
                    Text(
                      payment.quantity,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Text(' • ',
                        style: TextStyle(color: AppColors.textTertiary)),
                    Expanded(
                      child: Text(
                        payment.centreName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 10),

                // Bottom Row: Amount & Date / Reference + Chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PaymentCalculationService.formatCurrency(
                              payment.netAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${payment.paymentDate} • ${payment.paymentReference}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _isTelugu
                              ? 'రసీదు'
                              : (_isHindi ? 'रसीद' : 'Receipt'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primaryGreen,
                          size: 20,
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
    );
  }
}
