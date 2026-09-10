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

  const FarmerCropSelectionScreen({
    super.key,
    required this.currentCropName,
    required this.currentQuantity,
    required this.isHindi,
    this.isTelugu = false,
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

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_rebuildOnPrefs);
    _selectedQuantity = widget.currentQuantity;
    // Find initial crop from catalogue
    final existing = CropCatalogueService.findByName(widget.currentCropName);
    _selectedCrop = existing ?? CropCatalogueService.allCrops.first;
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
    var crops = _searchQuery.isEmpty
        ? CropCatalogueService.allCrops
        : CropCatalogueService.searchCrops(_searchQuery);
    if (_selectedCategory != null) {
      crops = crops.where((c) => c.category == _selectedCategory).toList();
    }
    return crops;
  }

  void _speakGuidance() {
    String message;
    String langCode;
    if (_isTelugu) {
      message =
          'దయచేసి అందుబాటులో ఉన్న 20+ సేకరణ పంటల కేటలాగ్ (10 ప్రధాన పంటలతో సహా) నుండి మీ పంటను మరియు పరిమాణాన్ని ఎంచుకోండి. ధృవీకరించిన తర్వాత మీ వివరాలు అప్‌డేట్ అవుతాయి.';
      langCode = 'te-IN';
    } else if (_isHindi) {
      message =
          'कृपया उपलब्ध 20+ फसलों की सूची (10 मुख्य फसलों सहित) में से अपनी फसल और मात्रा का चयन करें। पुष्टि के बाद आपका विवरण अपडेट हो जाएगा।';
      langCode = 'hi-IN';
    } else {
      message =
          'Please select your produce from the full crop catalogue with 10 main crops and 20+ varieties, and enter quantity in quintals. Confirming will update your details.';
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(crop.icon,
                              size: 28, color: AppColors.primaryGreen),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isTelugu
                                    ? crop.nameTe
                                    : (widget.isHindi
                                        ? crop.nameHi
                                        : crop.cropName),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                widget.isTelugu
                                    ? 'పరిమాణాన్ని నిర్ధారించండి'
                                    : (widget.isHindi
                                        ? 'उपज मात्रा दर्ज करें'
                                        : 'Specify Expected Quantity'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quantity Stepper
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
                        const SizedBox(width: 12),
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
                                _selectedQuantity =
                                    double.tryParse(val) ?? _selectedQuantity;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 16),

                    // MSP Preview Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isTelugu
                                    ? 'ప్రభుత్వ కనీస మద్దతు ధర'
                                    : (widget.isHindi
                                        ? 'सरकारी एमएसपी दर'
                                        : 'Govt MSP Rate'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '₹${mspRate.toStringAsFixed(0)} / Quintal',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.isTelugu
                                    ? 'అంచనా మొత్తం విలువ'
                                    : (widget.isHindi
                                        ? 'अनुमानित कुल मूल्य'
                                        : 'Est. Total Value'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
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
                        final finalQty = parsed <= 0 ? 50.0 : parsed;

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
                                  ? 'పంట విజయవంతంగా ${_selectedCrop!.nameTe}గా మార్చబడింది'
                                  : (widget.isHindi
                                      ? 'फसल सफलतापूर्वक ${_selectedCrop!.nameHi} में बदल दी गई'
                                      : 'Crop successfully changed to ${_selectedCrop!.cropName}'),
                            ),
                            backgroundColor: AppColors.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        widget.isTelugu
                            ? 'పంటను సేవ్ చేసి అప్‌డేట్ చేయండి'
                            : (widget.isHindi
                                ? 'फसल सहेजें और अपडेट करें'
                                : 'Save & Update Crop'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    _selectedCrop ??= crops.isNotEmpty ? crops.first : CropCatalogueService.allCrops.first;

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
          final int crossAxisCount;
          final double childAspectRatio;

          if (width >= 850) {
            // On desktop: 5 columns x 2 rows = exactly 10 crops visible at once!
            crossAxisCount = 5;
            childAspectRatio = 1.55;
          } else if (width >= 550) {
            // On tablet: 4 columns
            crossAxisCount = 4;
            childAspectRatio = 1.45;
          } else {
            // On mobile: 2 columns x 5 rows
            crossAxisCount = 2;
            childAspectRatio = 1.68;
          }

          return Center(
            child: SizedBox(
              width: isDesktop ? 980 : width,
              height: constraints.maxHeight,
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

                        // Category Chips Bar
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _categoryChip(
                                label: _isTelugu
                                    ? 'అన్నీ'
                                    : (_isHindi ? 'सभी' : 'All'),
                                isSelected: _selectedCategory == null,
                                onTap: () =>
                                    setState(() => _selectedCategory = null),
                              ),
                              const SizedBox(width: 8),
                              _categoryChip(
                                label: _isTelugu
                                    ? 'ధాన్యాలు'
                                    : (_isHindi ? 'अनाज' : 'Cereals'),
                                isSelected:
                                    _selectedCategory == CropCategory.cereals,
                                onTap: () => setState(() =>
                                    _selectedCategory = CropCategory.cereals),
                              ),
                              const SizedBox(width: 8),
                              _categoryChip(
                                label: _isTelugu
                                    ? 'పప్పుధాన్యాలు'
                                    : (_isHindi ? 'दालें' : 'Pulses'),
                                isSelected:
                                    _selectedCategory == CropCategory.pulses,
                                onTap: () => setState(
                                    () => _selectedCategory = CropCategory.pulses),
                              ),
                              const SizedBox(width: 8),
                              _categoryChip(
                                label: _isTelugu
                                    ? 'నూనెగింజలు'
                                    : (_isHindi ? 'तिलहन' : 'Oilseeds'),
                                isSelected:
                                    _selectedCategory == CropCategory.oilseeds,
                                onTap: () => setState(() =>
                                    _selectedCategory = CropCategory.oilseeds),
                              ),
                              const SizedBox(width: 8),
                              _categoryChip(
                                label: _isTelugu
                                    ? 'వాణిజ్య'
                                    : (_isHindi ? 'व्यावसायिक' : 'Commercial'),
                                isSelected:
                                    _selectedCategory == CropCategory.commercial,
                                onTap: () => setState(() =>
                                    _selectedCategory = CropCategory.commercial),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.cardBorder),

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
                          ElevatedButton(
                            key: const ValueKey('btn_proceed_crop_selection'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
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
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
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
    final primaryName = _isTelugu
        ? crop.nameTe
        : (_isHindi ? crop.nameHi : crop.cropName);
    final secondaryName = _isTelugu || _isHindi
        ? crop.cropName
        : crop.nameHi;

    return InkWell(
      key: ValueKey('crop_card_${crop.id}'),
      onTap: () {
        setState(() {
          _selectedCrop = crop;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.cardBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryGreen.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 6 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
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
            const SizedBox(height: 3),
            Text(
              primaryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
              ),
            ),
            Text(
              secondaryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
