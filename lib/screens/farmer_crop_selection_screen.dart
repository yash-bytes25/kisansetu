import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../services/app_preferences_service.dart';
import '../services/crop_catalogue_service.dart';
import '../services/payment_calculation_service.dart';
import '../services/procurement_state_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/responsive_layout.dart';

/// Screen allowing the farmer to view the crop catalogue, search/filter crops,
/// adjust the expected procurement quantity, handle active booking warnings,
/// and commit changes to the procurement state.
class FarmerCropSelectionScreen extends StatefulWidget {
  final String currentCropName;
  final double currentQuantity;
  final bool isHindi;
  final bool isTelugu;

  final bool showProminentOnly;

  const FarmerCropSelectionScreen({
    super.key,
    required this.currentCropName,
    required this.currentQuantity,
    required this.isHindi,
    this.isTelugu = false,
    this.showProminentOnly = false,
  });

  @override
  State<FarmerCropSelectionScreen> createState() =>
      _FarmerCropSelectionScreenState();
}

class _FarmerCropSelectionScreenState extends State<FarmerCropSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _prefs = AppPreferencesService.instance;

  bool get _isHindi => _prefs.isHindi || widget.isHindi;
  bool get _isTelugu => _prefs.isTelugu || widget.isTelugu;

  CropCategory? _selectedCategory;
  CropModel? _selectedCrop;
  double _selectedQuantity = 50.0;
  String _searchQuery = '';
  bool _showOnlyOtherCrops = false;
  bool _showOnlyProminent = false;

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_rebuildOnPrefs);
    _selectedQuantity = widget.currentQuantity;
    _showOnlyProminent = widget.showProminentOnly;
    // Find initial crop from catalogue
    final existing = CropCatalogueService.findByName(widget.currentCropName);
    _selectedCrop = existing ?? CropCatalogueService.prominent10Crops.first;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _prefs.removeListener(_rebuildOnPrefs);
    _searchController.dispose();
    super.dispose();
  }

  void _rebuildOnPrefs() {
    if (mounted) setState(() {});
  }

  List<CropModel> get _filteredCrops {
    List<CropModel> crops;
    if (_searchQuery.isNotEmpty) {
      crops = CropCatalogueService.searchCrops(_searchQuery);
    } else if (_showOnlyOtherCrops) {
      crops = CropCatalogueService.otherCrops;
    } else if (_showOnlyProminent) {
      crops = CropCatalogueService.prominent10Crops;
    } else {
      // By default, full catalogue starting with the 10 default crops
      crops = CropCatalogueService.allCrops;
    }
    if (_selectedCategory != null && !_showOnlyProminent && !_showOnlyOtherCrops) {
      crops = crops.where((c) => c.category == _selectedCategory).toList();
    }
    return crops;
  }

  void _speakGuidance() {
    String message;
    String langCode;
    if (_isTelugu) {
      message =
          'దయచేసి 10 ప్రధాన పంటల నుండి లేదా ఇతర పంటల నుండి మీ పంటను మరియు పరిమాణాన్ని ఎంచుకోండి. ధృవీకరించిన తర్వాత వివరాలు అప్‌డేట్ అవుతాయి.';
      langCode = 'te-IN';
    } else if (_isHindi) {
      message =
          'कृपया 10 मुख्य फसलों या अन्य फसलों में से अपनी फसल और मात्रा चुनें। पुष्टि के बाद विवरण अपडेट हो जाएगा।';
      langCode = 'hi-IN';
    } else {
      message =
          'Please select your crop from the 10 prominent crops or other crops and specify quantity. Confirming will update your produce.';
      langCode = 'en-IN';
    }

    VoiceAssistantSpeechService.instance.speak(message, language: langCode);
  }

  Future<void> _handleConfirmCropSelection() async {
    if (_selectedCrop == null) return;

    final stateService = ProcurementStateService();
    final hasActiveBooking = stateService.farmerData.hasActiveBooking;

    if (hasActiveBooking) {
      final shouldProceed = await _showActiveBookingWarningDialog();
      if (shouldProceed != true) {
        return;
      }
    }

    _showQuantityModal();
  }

  Future<bool?> _showActiveBookingWarningDialog() {
    final farmerData = ProcurementStateService().farmerData;
    final token = farmerData.tokenNumber;
    final slot = farmerData.bookedSlotTime ?? '11:30 AM';

    String title;
    String warning;
    String cancelLabel;
    String confirmLabel;

    if (widget.isTelugu) {
      title = 'యాక్టివ్ బుకింగ్ గుర్తించబడింది';
      warning =
          'మీకు ఇప్పటికే ${farmerData.cropName} కోసం యాక్టివ్ బుకింగ్ ($token, $slot వద్ద) ఉంది. '
          'పంటను మార్చడం ద్వారా మీ టోకెన్ మరియు సెంటర్ క్యూ వివరాలు అప్‌డేట్ అవుతాయి. మీరు కొనసాగించాలనుకుంటున్నారా?';
      cancelLabel = 'ప్రస్తుత బుకింగ్‌ను ఉంచండి';
      confirmLabel = 'ధృవీకరించి పంటను మార్చండి';
    } else if (widget.isHindi) {
      title = 'सक्रिय बुकिंग पाई गई';
      warning =
          'आपके पास पहले से ही ${farmerData.cropName} के लिए सक्रिय स्लॉट बुकिंग ($token, $slot पर) है। '
          'फसल बदलने से आपका टोकन और मंडी कतार विवरण अपडेट हो जाएंगे। क्या आप आगे बढ़ना चाहते हैं?';
      cancelLabel = 'वर्तमान बुकिंग रखें';
      confirmLabel = 'पुष्टि करें और फसल बदलें';
    } else {
      title = 'Active Booking Detected';
      warning =
          'You already have an active appointment ($token at $slot) for ${farmerData.cropName}. '
          'Changing your crop will update your registered appointment and mandi queue details. Do you want to proceed?';
      cancelLabel = 'Keep Current Booking';
      confirmLabel = 'Confirm & Change Crop';
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          warning,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            key: const ValueKey('btn_cancel_booking_warning'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            key: const ValueKey('btn_confirm_booking_warning'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showQuantityModal() {
    final qtyController =
        TextEditingController(text: _selectedQuantity.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final crop = _selectedCrop!;
            final currentVal =
                double.tryParse(qtyController.text) ?? _selectedQuantity;
            final mspRate = PaymentCalculationService.getMspRate(crop.cropName);
            final totalEstimatedValue = currentVal * mspRate;

            void updateQty(double delta) {
              var newVal =
                  (double.tryParse(qtyController.text) ?? 50.0) + delta;
              if (newVal < 1) newVal = 1;
              if (newVal > 1000) newVal = 1000;
              setModalState(() {
                _selectedQuantity = newVal;
                qtyController.text = newVal.toStringAsFixed(0);
              });
            }

            final modalTitle = widget.isTelugu
                ? 'మీ పంటను ${crop.nameTe}గా మార్చాలా?'
                : (widget.isHindi
                    ? 'क्या आप अपनी फसल को ${crop.nameHi} में बदलना चाहते हैं?'
                    : 'Change your crop to ${crop.cropName}?');

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Confirmation Title
                    Text(
                      modalTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),

                    // Crop Preview Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(crop.icon,
                                size: 26, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${crop.cropName} (${crop.nameHi} / ${crop.nameTe})',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'Govt MSP Rate',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const Text(
                                      ' • ',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '₹${mspRate.toStringAsFixed(0)} / Quintal',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quantity Stepper Heading
                    Text(
                      widget.isTelugu
                          ? 'పరిమాణం (క్వింటాళ్ళు):'
                          : (widget.isHindi
                              ? 'मात्रा (क्विंटल):'
                              : 'Quantity (Quintals):'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // -10, -5, [TextField], +5, +10 Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _stepperButton(
                          label: '-10',
                          onTap: () => updateQty(-10),
                        ),
                        const SizedBox(width: 8),
                        _stepperButton(
                          label: '-5',
                          onTap: () => updateQty(-5),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            key: const ValueKey('input_crop_quantity'),
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.cardBorder),
                              ),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                final p = double.tryParse(val);
                                if (p != null && p > 0) {
                                  _selectedQuantity = p;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        _stepperButton(
                          label: '+5',
                          onTap: () => updateQty(5),
                        ),
                        const SizedBox(width: 8),
                        _stepperButton(
                          label: '+10',
                          onTap: () => updateQty(10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Total Value Preview
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.isTelugu
                                ? 'అంచనా మొత్తం విలువ:'
                                : (widget.isHindi
                                    ? 'अनुमानित कुल मूल्य:'
                                    : 'Est. Total Value:'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '₹${totalEstimatedValue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Buttons: Cancel & Confirm
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey('btn_cancel_crop_selection'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.cardBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(modalCtx).pop(),
                            child: Text(
                              widget.isTelugu
                                  ? 'రద్దు చేయండి'
                                  : (widget.isHindi ? 'रद्द करें' : 'Cancel'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            key: const ValueKey('btn_save_crop_selection'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final parsed =
                                  double.tryParse(qtyController.text) ??
                                      _selectedQuantity;
                              final finalQty = parsed <= 0 ? 50.0 : parsed.clamp(1.0, 1000.0);

                              try {
                                ProcurementStateService().changeFarmerCrop(
                                  crop: _selectedCrop!,
                                  quantityQuintals: finalQty,
                                );

                                Navigator.of(modalCtx).pop();
                                Navigator.of(context).pop(true);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      widget.isTelugu
                                          ? 'Crop Updated Successfully • పంట విజయవంతంగా నవీకరించబడింది'
                                          : (widget.isHindi
                                              ? 'Crop Updated Successfully • फसल सफलतापूर्वक अपडेट की गई'
                                              : 'Crop Updated Successfully'),
                                    ),
                                    backgroundColor: AppColors.primaryGreen,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating crop: $e'),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              widget.isTelugu
                                  ? 'నిర్ధారించండి'
                                  : (widget.isHindi
                                      ? 'पुष्टि करें'
                                      : 'Confirm'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _stepperButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crops = _filteredCrops;
    _selectedCrop ??= crops.isNotEmpty ? crops.first : CropCatalogueService.prominent10Crops.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isTelugu
              ? 'పంటను ఎంచుకోండి'
              : (_isHindi ? 'फसल चुनें' : 'Select Crop'),
          style: AppTextStyles.titleLarge,
        ),
        actions: [
          IconButton(
            key: const ValueKey('btn_crop_voice_guide'),
            icon: const Icon(Icons.volume_up_rounded),
            tooltip: _isTelugu
                ? 'వాయిస్ సహాయం'
                : (_isHindi ? 'आवाज सहायता' : 'Voice Guide'),
            onPressed: _speakGuidance,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= ResponsiveLayout.desktopMin;
          final isTablet = width >= ResponsiveLayout.mobileMax &&
              width < ResponsiveLayout.desktopMin;
          final int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
          final double childAspectRatio =
              isDesktop ? 1.25 : (isTablet ? 1.15 : 0.92);

          return Center(
            child: SizedBox(
              width: isDesktop ? 980 : width,
              height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search & Filter Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: Column(
                      children: [
                        TextField(
                          key: const ValueKey('search_crop_input'),
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: _isTelugu
                                ? 'పంట పేరుతో వెతకండి (ఉదా. గోధుమ, వరి)...'
                                : (_isHindi
                                    ? 'फसल का नाम खोजें (उदा. गेहूं, धान)...'
                                    : 'Search crops (e.g. Wheat, Rice, Mustard)...'),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 20),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.cardBorder),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Category Chips Bar with All, 10 Main Crops, Other Crops, and Categories
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _categoryChip(
                                key: const ValueKey('chip_filter_all'),
                                label: _isTelugu
                                    ? 'అన్నీ'
                                    : (_isHindi ? 'सभी' : 'All'),
                                isSelected: _selectedCategory == null &&
                                    !_showOnlyOtherCrops &&
                                    !_showOnlyProminent,
                                onTap: () => setState(() {
                                  _selectedCategory = null;
                                  _showOnlyOtherCrops = false;
                                  _showOnlyProminent = false;
                                }),
                              ),
                              const SizedBox(width: 8),
                              _categoryChip(
                                key: const ValueKey('chip_filter_main_10'),
                                label: _isTelugu
                                    ? '10 ప్రధాన పంటలు'
                                    : (_isHindi ? '10 मुख्य फसलें' : '10 Main Crops'),
                                isSelected: _showOnlyProminent && _selectedCategory == null,
                                onTap: () => setState(() {
                                  _selectedCategory = null;
                                  _showOnlyOtherCrops = false;
                                  _showOnlyProminent = true;
                                }),
                              ),
                              const SizedBox(width: 8),
                              _categoryChip(
                                key: const ValueKey('chip_filter_other'),
                                label: _isTelugu
                                    ? 'ఇతర పంటలు'
                                    : (_isHindi ? 'अन्य फसलें' : 'Other Crops'),
                                isSelected: _showOnlyOtherCrops && _selectedCategory == null,
                                onTap: () => setState(() {
                                  _selectedCategory = null;
                                  _showOnlyOtherCrops = true;
                                  _showOnlyProminent = false;
                                }),
                              ),
                              const SizedBox(width: 8),
                              _categoryChip(
                                key: const ValueKey('chip_filter_cereals'),
                                label: _isTelugu
                                    ? 'ధాన్యాలు'
                                    : (_isHindi ? 'अनाज' : 'Cereals'),
                                isSelected:
                                    _selectedCategory == CropCategory.cereals,
                                onTap: () => setState(() {
                                  _selectedCategory = CropCategory.cereals;
                                  _showOnlyOtherCrops = false;
                                  _showOnlyProminent = false;
                                }),
                              ),
                              const SizedBox(width: 8),
                              _categoryChip(
                                key: const ValueKey('chip_filter_pulses'),
                                label: _isTelugu
                                    ? 'పప్పుధాన్యాలు'
                                    : (_isHindi ? 'दालें' : 'Pulses'),
                                isSelected:
                                    _selectedCategory == CropCategory.pulses,
                                onTap: () => setState(() {
                                  _selectedCategory = CropCategory.pulses;
                                  _showOnlyOtherCrops = false;
                                  _showOnlyProminent = false;
                                }),
                              ),
                              const SizedBox(width: 8),
                              _categoryChip(
                                key: const ValueKey('chip_filter_oilseeds'),
                                label: _isTelugu
                                    ? 'నూనెగింజలు'
                                    : (_isHindi ? 'तिलहन' : 'Oilseeds'),
                                isSelected:
                                    _selectedCategory == CropCategory.oilseeds,
                                onTap: () => setState(() {
                                  _selectedCategory = CropCategory.oilseeds;
                                  _showOnlyOtherCrops = false;
                                  _showOnlyProminent = false;
                                }),
                              ),
                              const SizedBox(width: 8),
                              _categoryChip(
                                key: const ValueKey('chip_filter_commercial'),
                                label: _isTelugu
                                    ? 'వాణిజ్య'
                                    : (_isHindi ? 'व्यावसायिक' : 'Commercial'),
                                isSelected:
                                    _selectedCategory == CropCategory.commercial,
                                onTap: () => setState(() {
                                  _selectedCategory = CropCategory.commercial;
                                  _showOnlyOtherCrops = false;
                                  _showOnlyProminent = false;
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.cardBorder),

                  if (_showOnlyProminent &&
                      _selectedCategory == null &&
                      _searchQuery.isEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 18, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isTelugu
                                  ? '10 ప్రధాన పంటలు: వరి, మొక్కజొన్న, కందులు, పెసలు, మినుములు, గోధుమలు, వేరుశెనగ, పొద్దుతిరుగుడు, పత్తి, చెరకు'
                                  : (_isHindi
                                      ? '10 मुख्य फसलें: धान, मक्का, तूर, मूंग, उड़द, गेहूं, मूंगफली, सूरजमुखी, कपास, गन्ना'
                                      : '10 Main Crops: Paddy, Maize, Red Gram, Green Gram, Black Gram, Wheat, Groundnut, Sunflower, Cotton, Sugarcane'),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Crop Grid
                  Expanded(
                    child: crops.isEmpty
                        ? Center(
                            child: Text(
                              _isTelugu
                                  ? 'ఎటువంటి పంటలు కనుగొనబడలేదు'
                                  : (_isHindi
                                      ? 'कोई फसल नहीं मिली'
                                      : 'No crops found matching search'),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: childAspectRatio,
                            ),
                            itemCount: crops.length,
                            itemBuilder: (context, index) {
                              final crop = crops[index];
                              final isSelected = _selectedCrop?.id == crop.id;
                              return _cropCard(crop, isSelected);
                            },
                          ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          if (_selectedCrop != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _selectedCrop!.icon,
                                color: AppColors.primaryGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isTelugu
                                        ? _selectedCrop!.nameTe
                                        : (_isHindi
                                            ? _selectedCrop!.nameHi
                                            : _selectedCrop!.cropName),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedQuantity.toStringAsFixed(0)} Quintals • ${_selectedCrop!.category.localizedName(isHindi: _isHindi, isTelugu: _isTelugu)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_selectedCrop == null) const Spacer(),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            key: const ValueKey('btn_proceed_crop_selection'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 44),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _selectedCrop == null
                                ? null
                                : _handleConfirmCropSelection,
                            child: Text(
                              _isTelugu
                                  ? 'పరిమాణం & నిర్ధారణ'
                                  : (_isHindi
                                      ? 'मात्रा एवं पुष्टि'
                                      : 'Quantity & Confirm'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryChip({
    Key? key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      key: key,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryGreen,
      backgroundColor: AppColors.surfaceVariant,
      onSelected: (_) => onTap(),
    );
  }

  Widget _cropCard(CropModel crop, bool isSelected) {
    final mspRate = PaymentCalculationService.getMspRate(crop.cropName);
    final primaryName = _isTelugu
        ? crop.nameTe
        : (_isHindi ? crop.nameHi : crop.cropName);
    final secondaryName = _isTelugu || _isHindi
        ? crop.cropName
        : crop.nameHi;
    final thirdName = _isTelugu
        ? crop.nameHi
        : (_isHindi ? crop.nameTe : crop.nameTe);

    return InkWell(
      key: ValueKey('crop_card_${crop.id}'),
      onTap: () {
        setState(() {
          _selectedCrop = crop;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withValues(alpha: 0.7)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.cardBorder,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryGreen.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 8 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row 1: Crop Icon + Selection Radio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    crop.icon,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.primaryGreen,
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.cardBorder,
                ),
              ],
            ),

            // Row 2: Primary Name (localized)
            Text(
              primaryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
              ),
            ),

            // Row 3: Secondary Name
            Text(
              secondaryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),

            // Row 4: Third Name
            Text(
              thirdName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textSecondary,
              ),
            ),

            // Row 5: MSP Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'MSP: ₹${mspRate.toStringAsFixed(0)}/Qtl',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),

            // Row 6: Select Button
            SizedBox(
              height: 26,
              width: double.infinity,
              child: ElevatedButton(
                key: ValueKey('btn_select_${crop.id}'),
                onPressed: () {
                  setState(() {
                    _selectedCrop = crop;
                  });
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.surfaceVariant,
                  foregroundColor:
                      isSelected ? Colors.white : AppColors.primaryGreen,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  isSelected
                      ? (_isTelugu
                          ? 'ఎంచుకోబడింది'
                          : (_isHindi ? 'चयनित' : 'Selected'))
                      : (_isTelugu
                          ? 'ఎంచుకోండి'
                          : (_isHindi ? 'चुनें' : 'Select')),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
