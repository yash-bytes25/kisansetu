import 'package:flutter/material.dart';
import '../models/farmer_dashboard_data.dart';
import '../models/procurement_centre.dart';
import '../services/location_distance_service.dart';
import '../services/location_master_service.dart';
import '../services/procurement_state_service.dart';
import '../services/repositories/repository_provider.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_crop_selection_screen.dart';
import 'farmer_smart_slot_screen.dart';

/// Screen allowing the farmer to select location (State -> District -> Mandal),
/// confirm area, discover nearby centres with Haversine distance and operational metrics,
/// and continue to smart slot recommendation.
class FarmerBookSlotScreen extends StatefulWidget {
  final FarmerDashboardData currentData;
  final bool isHindi;
  final bool isTelugu;
  final List<ProcurementCentre>? centresOverride;

  // Optional pre-configuration for testing or direct navigation
  final String? initialState;
  final String? initialDistrict;
  final String? initialMandal;
  final bool isLocationConfirmed;

  const FarmerBookSlotScreen({
    super.key,
    required this.currentData,
    required this.isHindi,
    this.isTelugu = false,
    this.centresOverride,
    this.initialState,
    this.initialDistrict,
    this.initialMandal,
    this.isLocationConfirmed = false,
  });

  @override
  State<FarmerBookSlotScreen> createState() => _FarmerBookSlotScreenState();
}

class _FarmerBookSlotScreenState extends State<FarmerBookSlotScreen> {
  bool get _isHindi => widget.isHindi;
  bool get _isTelugu => widget.isTelugu;

  late FarmerDashboardData _currentData;

  // Cascading Location Selection state
  LocationItem? _selectedState;
  LocationItem? _selectedDistrict;
  LocationItem? _selectedMandal;
  bool _isLocationConfirmed = false;

  // Procurement Centres state
  List<ProcurementCentre> _centres = [];
  bool _isLoadingCentres = false;
  bool _isShowingNearbyCentres = false;
  ProcurementCentre? _selectedCentre;

  // Permission notice dismissal state
  bool _dismissedPermissionBanner = false;

  @override
  void initState() {
    super.initState();
    _currentData = widget.currentData;

    // Initialize from optional parameters if provided
    final master = LocationMasterService.instance;
    if (widget.initialState != null) {
      final states = master.getStates();
      _selectedState = states.firstWhere(
        (s) =>
            s.nameEn.toLowerCase() == widget.initialState!.toLowerCase() ||
            s.id.toLowerCase() == widget.initialState!.toLowerCase(),
        orElse: () => states.first,
      );
    }
    if (_selectedState != null && widget.initialDistrict != null) {
      final districts = master.getDistrictsForState(_selectedState!.id);
      try {
        _selectedDistrict = districts.firstWhere((d) =>
            d.nameEn.toLowerCase() == widget.initialDistrict!.toLowerCase() ||
            d.id.toLowerCase() == widget.initialDistrict!.toLowerCase());
      } catch (_) {}
    }
    if (_selectedDistrict != null && widget.initialMandal != null) {
      final mandals = master.getMandalsForDistrict(_selectedDistrict!.id);
      try {
        _selectedMandal = mandals.firstWhere((m) =>
            m.nameEn.toLowerCase() == widget.initialMandal!.toLowerCase() ||
            m.id.toLowerCase() == widget.initialMandal!.toLowerCase());
      } catch (_) {}
    }

    // Determine initial confirmation
    if (widget.centresOverride != null) {
      _isLocationConfirmed = true;
      _centres = List.from(widget.centresOverride!);
      if (_centres.isNotEmpty) {
        _selectedCentre = _centres.first;
      }
    } else if (widget.isLocationConfirmed &&
        _selectedState != null &&
        _selectedDistrict != null &&
        _selectedMandal != null) {
      _isLocationConfirmed = true;
      _loadCentres();
    }
  }

  Future<void> _loadCentres() async {
    setState(() {
      _isLoadingCentres = true;
      _selectedCentre = null;
      _isShowingNearbyCentres = false;
    });

    if (widget.centresOverride != null) {
      // In override mode, filter to mandal if specified
      final overrideList = widget.centresOverride!;
      if (_selectedMandal != null) {
        final mandalCentres = overrideList.where((c) {
          return c.mandal.toLowerCase() ==
                  _selectedMandal!.nameEn.toLowerCase() ||
              c.mandal.toLowerCase() == _selectedMandal!.id.toLowerCase();
        }).toList();
        _centres = mandalCentres;
      } else {
        _centres = List.from(overrideList);
      }
    } else if (_selectedState != null &&
        _selectedDistrict != null &&
        _selectedMandal != null) {
      final repo = RepositoryProvider.centre;
      _centres = await repo.getCentresByLocation(
        state: _selectedState!.nameEn,
        district: _selectedDistrict!.nameEn,
        mandal: _selectedMandal!.nameEn,
      );
    } else {
      _centres = [];
    }

    // Sort centres intelligently
    final farmerCoords = LocationDistanceService.instance.currentCoordinates;
    _centres.sort((a, b) => ProcurementCentre.compareRecommendation(
          a,
          b,
          farmerLat: farmerCoords?.latitude,
          farmerLng: farmerCoords?.longitude,
        ));

    if (mounted) {
      setState(() {
        _isLoadingCentres = false;
      });
    }
  }

  Future<void> _loadNearbyCentres() async {
    if (_selectedState == null || _selectedDistrict == null) return;
    setState(() {
      _isLoadingCentres = true;
      _selectedCentre = null;
    });

    final repo = RepositoryProvider.centre;
    final farmerCoords = LocationDistanceService.instance.currentCoordinates;
    final nearby = await repo.getNearbyCentres(
      state: _selectedState!.nameEn,
      district: _selectedDistrict!.nameEn,
      latitude: farmerCoords?.latitude,
      longitude: farmerCoords?.longitude,
      limit: 5,
    );

    if (mounted) {
      setState(() {
        _centres = nearby;
        _isShowingNearbyCentres = true;
        _isLoadingCentres = false;
      });
    }
  }

  void _onConfirmLocation() {
    if (_selectedState == null ||
        _selectedDistrict == null ||
        _selectedMandal == null) {
      return;
    }
    setState(() {
      _isLocationConfirmed = true;
    });
    _loadCentres();
  }

  void _onChangeLocation() {
    setState(() {
      _isLocationConfirmed = false;
      _isShowingNearbyCentres = false;
      _centres = [];
      _selectedCentre = null;
    });
  }

  void _onStateChanged(LocationItem? state) {
    if (_selectedState?.id != state?.id) {
      setState(() {
        _selectedState = state;
        _selectedDistrict = null;
        _selectedMandal = null;
        _isLocationConfirmed = false;
        _isShowingNearbyCentres = false;
        _centres = [];
        _selectedCentre = null;
      });
    }
  }

  void _onDistrictChanged(LocationItem? district) {
    if (_selectedDistrict?.id != district?.id) {
      setState(() {
        _selectedDistrict = district;
        _selectedMandal = null;
        _isLocationConfirmed = false;
        _isShowingNearbyCentres = false;
        _centres = [];
        _selectedCentre = null;
      });
    }
  }

  void _onMandalChanged(LocationItem? mandal) {
    if (_selectedMandal?.id != mandal?.id) {
      setState(() {
        _selectedMandal = mandal;
        _isLocationConfirmed = false;
        _isShowingNearbyCentres = false;
        _centres = [];
        _selectedCentre = null;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    await LocationDistanceService.instance
        .requestLocationPermission(grant: true);
    if (mounted) {
      setState(() {
        // Re-sort with farmer coordinates if available
        final farmerCoords =
            LocationDistanceService.instance.currentCoordinates;
        _centres.sort((a, b) => ProcurementCentre.compareRecommendation(
              a,
              b,
              farmerLat: farmerCoords?.latitude,
              farmerLng: farmerCoords?.longitude,
            ));
      });
    }
  }

  void _showVoiceGuidance() {
    final String message;
    if (!_isLocationConfirmed) {
      message = _isTelugu
          ? 'వాయిస్ గైడ్: మీరు ఎక్కడ సేకరించాలనుకుంటున్నారో ఎంచుకోండి. మొదట మీ రాష్ట్రం, తరువాత జిల్లా, మరియు మండలాన్ని ఎంచుకుని ధృవీకరించండి.'
          : (_isHindi
              ? 'आवाज गाइड: आप कहां खरीद कराना चाहते हैं, इसका चयन करें। पहले राज्य, फिर जिला, और फिर मंडल चुनकर पुष्टि करें।'
              : 'Voice Guide: Select where you want to procure. Select your State, District, and Mandal, then tap Confirm to find available centres.');
    } else {
      final centreCount = _centres.length;
      message = _isTelugu
          ? 'వాయిస్ గైడ్: ${_selectedMandal?.nameTe ?? ''} మండలంలో $centreCount సేకరణ కేంద్రాలు అందుబాటులో ఉన్నాయి. మీ దూరం మరియు వేచి ఉండే సమయాన్ని బట్టి కేంద్రాన్ని ఎంచుకోండి.'
          : (_isHindi
              ? 'आवाज गाइड: ${_selectedMandal?.nameHi ?? ''} मंडल में $centreCount खरीद केंद्र उपलब्ध हैं। दूरी और प्रतीक्षा समय देखकर अपना केंद्र चुनें।'
              : 'Voice Guide: Found $centreCount procurement centres in ${_selectedMandal?.nameEn ?? ''} Mandal. Review distance and wait times, then select your preferred centre.');
    }

    VoiceAssistantSpeechService.instance.speak(
      message,
      language: _isTelugu ? 'te-IN' : (_isHindi ? 'hi-IN' : 'en-IN'),
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

  void _openChangeCrop() async {
    final qtyStr = _currentData.quantity.replaceAll(RegExp(r'[^0-9.]'), '');
    final currentQty = double.tryParse(qtyStr) ?? 50.0;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => FarmerCropSelectionScreen(
          currentCropName: _currentData.cropName,
          currentQuantity: currentQty,
          isHindi: _isHindi,
          isTelugu: _isTelugu,
          showProminentOnly: true,
        ),
      ),
    );

    if (mounted) {
      final updatedData = ProcurementStateService().farmerData;
      setState(() {
        _currentData = updatedData;
      });
    }
  }

  void _onContinue() async {
    if (_selectedCentre == null) return;

    final result = await Navigator.of(context).push<FarmerDashboardData?>(
      MaterialPageRoute<FarmerDashboardData?>(
        builder: (context) => FarmerSmartSlotScreen(
          selectedCentre: _selectedCentre!,
          currentData: _currentData,
          isHindi: _isHindi,
          isTelugu: _isTelugu,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _openSearchableLocationPicker({
    required String title,
    required List<LocationItem> items,
    required LocationItem? currentSelection,
    required ValueChanged<LocationItem> onSelected,
  }) async {
    final result = await showModalBottomSheet<LocationItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchableLocationBottomSheet(
        title: title,
        items: items,
        currentSelection: currentSelection,
        isHindi: _isHindi,
        isTelugu: _isTelugu,
      ),
    );

    if (result != null) {
      onSelected(result);
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
          Padding(
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
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Page Headings
                        Text(
                          _isTelugu
                              ? 'సేకరణ కేంద్రాన్ని ఎంచుకోండి'
                              : (_isHindi
                                  ? 'खरीद केंद्र चुनें'
                                  : 'Book Procurement Slot'),
                          style: AppTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isTelugu
                              ? 'మీ సేకరణ ప్రాంతాన్ని ఎంచుకుని, సమీప కేంద్రాన్ని నిర్ధారించండి.'
                              : (_isHindi
                                  ? 'अपना खरीद क्षेत्र चुनें और नजदीकी केंद्र निर्धारित करें।'
                                  : 'Select your procurement area and choose an operating centre.'),
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 20),

                        // SECTION 1: Registered Produce Confirmation Card
                        _buildProduceConfirmationCard(),
                        const SizedBox(height: 24),

                        // SECTION 2: Location Selection ("Where do you want to procure?")
                        if (!_isLocationConfirmed)
                          _buildLocationSelectionSection()
                        else
                          _buildConfirmedAreaHeader(),

                        const SizedBox(height: 16),

                        // SECTION 3: Location Access Banner (if not granted)
                        if (_isLocationConfirmed &&
                            !LocationDistanceService.instance.hasLocation &&
                            !_dismissedPermissionBanner)
                          _buildLocationPermissionBanner(),

                        // SECTION 4: Available Procurement Centres Results
                        if (_isLocationConfirmed) ...[
                          if (_isLoadingCentres)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_centres.isEmpty)
                            _buildNoCentresFoundCard()
                          else ...[
                            if (_isShowingNearbyCentres) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.primaryLight, width: 1.0),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.near_me_rounded,
                                      size: 20,
                                      color: AppColors.primaryGreen,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isTelugu
                                                ? 'సమీపంలోని అందుబాటులో ఉన్న కేంద్రాలు చూపబడుతున్నాయి'
                                                : (_isHindi
                                                    ? 'आस-पास के उपलब्ध केंद्र दिखाए जा रहे हैं'
                                                    : 'Showing nearby available centres'),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primaryGreen,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _isTelugu
                                                ? 'మీ ప్రాంతం నుండి దూరం ఆధారంగా క్రమబద్ధీకరించబడింది'
                                                : (_isHindi
                                                    ? 'आपके क्षेत्र से दूरी के आधार पर क्रमित'
                                                    : 'Sorted by distance from your location/region'),
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
                              ),
                            ],
                            Row(
                              children: [
                                const Icon(
                                  Icons.store_mall_directory_rounded,
                                  size: 20,
                                  color: AppColors.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isShowingNearbyCentres
                                      ? (_isTelugu
                                          ? 'సమీప సేకరణ కేంద్రాలు (${_centres.length})'
                                          : (_isHindi
                                              ? 'नजदीकी खरीद केंद्र (${_centres.length})'
                                              : 'Nearby Procurement Centres (${_centres.length})'))
                                      : (_isTelugu
                                          ? 'అందుబాటులో ఉన్న సేకరణ కేంద్రాలు (${_centres.length})'
                                          : (_isHindi
                                              ? 'उपलब्ध खरीद केंद्र (${_centres.length})'
                                              : 'Available Procurement Centres (${_centres.length})')),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._centres.map((c) => _buildCentreCard(c)),
                          ],
                        ],
                      ],
                    ),
                  ),
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: ElevatedButton(
                    key: const ValueKey('btn_continue_best_slot'),
                    onPressed: _selectedCentre != null ? _onContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      disabledBackgroundColor:
                          AppColors.primaryGreen.withValues(alpha: 0.3),
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 1: PRODUCE CONFIRMATION
  // ==========================================
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
              Text(
                _isTelugu
                    ? 'మీ పంట'
                    : (_isHindi ? 'आपकी उपज' : 'Your Produce'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_currentData.crop} • ${_currentData.quantity}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentData.estimatedMspValue,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isTelugu
                        ? 'మీ నమోదిత పంట నుండి'
                        : (_isHindi
                            ? 'आपकी पंजीकृत उपज से'
                            : 'From your registered produce'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                key: const ValueKey('btn_change_crop_quantity_booking'),
                onPressed: _openChangeCrop,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(
                  _isTelugu
                      ? 'పంట / పరిమాణం మార్చండి'
                      : (_isHindi ? 'फसल / मात्रा बदलें' : 'Change Crop / Quantity'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(
                      color: AppColors.primaryGreen, width: 1.2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 2: CASCADING LOCATION SELECTION
  // ==========================================
  Widget _buildLocationSelectionSection() {
    final master = LocationMasterService.instance;
    final availableDistricts = _selectedState != null
        ? master.getDistrictsForState(_selectedState!.id)
        : <LocationItem>[];
    final availableMandals = _selectedDistrict != null
        ? master.getMandalsForDistrict(_selectedDistrict!.id)
        : <LocationItem>[];

    final isAllSelected = _selectedState != null &&
        _selectedDistrict != null &&
        _selectedMandal != null;

    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(
                Icons.location_on_rounded,
                size: 22,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isTelugu
                      ? 'మీరు ఎక్కడ సేకరించాలనుకుంటున్నారు?'
                      : (_isHindi
                          ? 'आप कहां खरीद कराना चाहते हैं?'
                          : 'Where do you want to procure?'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isTelugu
                ? 'సేకరణ కేంద్రాలను కనుగొనడానికి రాష్ట్రం, జిల్లా మరియు మండలాన్ని ఎంచుకోండి.'
                : (_isHindi
                    ? 'खरीद केंद्र खोजने के लिए राज्य, जिला और मंडल का चयन करें।'
                    : 'Select State, District, and Mandal to discover available centres.'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          // 1. STATE SELECTOR
          _buildLocationDropdownField(
            keyName: 'select_state_field',
            label: _isTelugu ? 'రాష్ట్రం' : (_isHindi ? 'राज्य' : 'State'),
            selectedItem: _selectedState,
            placeholder: _isTelugu
                ? 'రాష్ట్రాన్ని ఎంచుకోండి'
                : (_isHindi ? 'राज्य चुनें' : 'Select State'),
            enabled: true,
            onTap: () {
              _openSearchableLocationPicker(
                title: _isTelugu
                    ? 'రాష్ట్రాన్ని ఎంచుకోండి'
                    : (_isHindi ? 'राज्य चुनें' : 'Select State'),
                items: master.getStates(),
                currentSelection: _selectedState,
                onSelected: _onStateChanged,
              );
            },
          ),
          const SizedBox(height: 14),

          // 2. DISTRICT SELECTOR
          _buildLocationDropdownField(
            keyName: 'select_district_field',
            label: _isTelugu ? 'జిల్లా' : (_isHindi ? 'जिला' : 'District'),
            selectedItem: _selectedDistrict,
            placeholder: _selectedState == null
                ? (_isTelugu
                    ? 'ముందుగా రాష్ట్రాన్ని ఎంచుకోండి'
                    : (_isHindi ? 'पहले राज्य चुनें' : 'Select State first'))
                : (_isTelugu
                    ? 'జిల్లాను ఎంచుకోండి'
                    : (_isHindi ? 'जिला चुनें' : 'Select District')),
            enabled: _selectedState != null,
            onTap: _selectedState == null
                ? null
                : () {
                    _openSearchableLocationPicker(
                      title: _isTelugu
                          ? 'జిల్లాను ఎంచుకోండి'
                          : (_isHindi ? 'जिला चुनें' : 'Select District'),
                      items: availableDistricts,
                      currentSelection: _selectedDistrict,
                      onSelected: _onDistrictChanged,
                    );
                  },
          ),
          const SizedBox(height: 14),

          // 3. MANDAL SELECTOR
          _buildLocationDropdownField(
            keyName: 'select_mandal_field',
            label: _isTelugu ? 'మండలం' : (_isHindi ? 'मंडल' : 'Mandal'),
            selectedItem: _selectedMandal,
            placeholder: _selectedDistrict == null
                ? (_isTelugu
                    ? 'ముందుగా జిల్లాను ఎంచుకోండి'
                    : (_isHindi ? 'पहले जिला चुनें' : 'Select District first'))
                : (_isTelugu
                    ? 'మండలాన్ని ఎంచుకోండి'
                    : (_isHindi ? 'मंडल चुनें' : 'Select Mandal')),
            enabled: _selectedDistrict != null,
            onTap: _selectedDistrict == null
                ? null
                : () {
                    _openSearchableLocationPicker(
                      title: _isTelugu
                          ? 'మండలాన్ని ఎంచుకోండి'
                          : (_isHindi ? 'मंडल चुनें' : 'Select Mandal'),
                      items: availableMandals,
                      currentSelection: _selectedMandal,
                      onSelected: _onMandalChanged,
                    );
                  },
          ),
          const SizedBox(height: 20),

          // CONFIRM LOCATION BUTTON & PREVIEW
          if (isAllSelected) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isTelugu
                            ? 'ఎంచుకున్న సేకరణ ప్రాంతం'
                            : (_isHindi
                                ? 'चयनित खरीद क्षेत्र'
                                : 'Selected Procurement Area'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedState!.localizedName(isHindi: _isHindi, isTelugu: _isTelugu)} • ${_selectedDistrict!.localizedName(isHindi: _isHindi, isTelugu: _isTelugu)} • ${_selectedMandal!.localizedName(isHindi: _isHindi, isTelugu: _isTelugu)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const ValueKey('btn_confirm_find_centres'),
              onPressed: _onConfirmLocation,
              icon: const Icon(Icons.search_rounded, size: 20),
              label: Text(
                _isTelugu
                    ? 'ధృవీకరించి సేకరణ కేంద్రాలను కనుగొనండి'
                    : (_isHindi
                        ? 'पुष्टि करें और खरीद केंद्र खोजें'
                        : 'Confirm & Find Procurement Centres'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationDropdownField({
    required String keyName,
    required String label,
    required LocationItem? selectedItem,
    required String placeholder,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final displayText = selectedItem != null
        ? selectedItem.localizedName(isHindi: _isHindi, isTelugu: _isTelugu)
        : placeholder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          key: ValueKey(keyName),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: enabled ? AppColors.surface : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedItem != null
                    ? AppColors.primaryGreen
                    : (enabled ? AppColors.cardBorder : Colors.transparent),
                width: selectedItem != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 20,
                  color: enabled
                      ? (selectedItem != null
                          ? AppColors.primaryGreen
                          : AppColors.textSecondary)
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selectedItem != null
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: selectedItem != null
                          ? AppColors.textPrimary
                          : (enabled
                              ? AppColors.textSecondary
                              : AppColors.textTertiary),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 28,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 3: CONFIRMED AREA HEADER
  // ==========================================
  Widget _buildConfirmedAreaHeader() {
    final stateStr = _selectedState?.localizedName(
            isHindi: _isHindi, isTelugu: _isTelugu) ??
        'Punjab';
    final districtStr = _selectedDistrict?.localizedName(
            isHindi: _isHindi, isTelugu: _isTelugu) ??
        'Ludhiana';
    final mandalStr = _selectedMandal?.localizedName(
            isHindi: _isHindi, isTelugu: _isTelugu) ??
        'Khanna';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isTelugu
                      ? 'ఎంచుకున్న సేకరణ ప్రాంతం'
                      : (_isHindi
                          ? 'चयनित खरीद क्षेत्र'
                          : 'Selected Procurement Area'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$stateStr • $districtStr • $mandalStr',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            key: const ValueKey('btn_change_location'),
            onPressed: _onChangeLocation,
            icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
            label: Text(
              _isTelugu
                  ? 'మార్చండి'
                  : (_isHindi ? 'बदलें' : 'Change Location'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 4: LOCATION PERMISSION BANNER
  // ==========================================
  Widget _buildLocationPermissionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 22,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isTelugu
                      ? 'ఖచ్చితమైన దూరాన్ని చూడటానికి లొకేషన్‌ను ప్రారంభించండి'
                      : (_isHindi
                          ? 'सटीक दूरी देखने के लिए स्थान सक्षम करें'
                          : 'Enable location for accurate distance'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isTelugu
                      ? 'మీ పరికర స్థానం ఆధారంగా ప్రతి సేకరణ కేంద్రం ఎంత దూరంలో ఉందో లెక్కించబడుతుంది.'
                      : (_isHindi
                          ? 'आपके डिवाइस स्थान का उपयोग केवल केंद्रों की दूरी मापने के लिए किया जाता है।'
                          : 'Your location is used solely to calculate straight-line distance to each centre.'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      key: const ValueKey('btn_enable_location'),
                      onPressed: _requestLocationPermission,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isTelugu
                            ? 'ప్రారంభించండి'
                            : (_isHindi ? 'सक्षम करें' : 'Enable Location'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _dismissedPermissionBanner = true;
                        });
                      },
                      child: Text(
                        _isTelugu
                            ? 'తర్వాత'
                            : (_isHindi ? 'बाद में' : 'Not Now'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 5: NO CENTRES FOUND EMPTY STATE
  // ==========================================
  Widget _buildNoCentresFoundCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 40,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isTelugu
                ? 'ఈ ప్రాంతంలో ప్రస్తుతం ఎటువంటి సేకరణ కేంద్రాలు అందుబాటులో లేవు.'
                : (_isHindi
                    ? 'इस क्षेत्र में वर्तमान में कोई खरीद केंद्र उपलब्ध नहीं है।'
                    : 'No procurement centre currently available in this area.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isTelugu
                ? 'ఈ మండలంలో కాన్ఫిగర్ చేయబడిన ప్రభుత్వ సేకరణ కేంద్రం అందుబాటులో లేదు. మీ ప్రాంతానికి సమీపంలో ఉన్న కేంద్రాలను చూడవచ్చు.'
                : (_isHindi
                    ? 'इस मंडल में कोई कॉन्फ़िगर किया गया सरकारी खरीद केंद्र उपलब्ध नहीं है। आप अपने क्षेत्र के नजदीकी केंद्र देख सकते हैं।'
                    : 'No configured procurement centre exists in this mandal. You can check available centres nearby in your region.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                key: const ValueKey('btn_view_nearby_centres'),
                onPressed: _loadNearbyCentres,
                icon: const Icon(Icons.near_me_rounded, size: 18),
                label: Text(
                  _isTelugu
                      ? 'సమీప కేంద్రాలను చూడండి'
                      : (_isHindi ? 'नजदीकी केंद्र देखें' : 'View Nearby Centres'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey('btn_change_location_empty'),
                onPressed: _onChangeLocation,
                icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                label: Text(
                  _isTelugu
                      ? 'స్థానాన్ని మార్చండి'
                      : (_isHindi ? 'स्थान बदलें' : 'Change Location'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 6: PROCUREMENT CENTRE CARD
  // ==========================================
  Widget _buildCentreCard(ProcurementCentre centre) {
    final isSelected = _selectedCentre?.id == centre.id;
    final farmerCoords = LocationDistanceService.instance.currentCoordinates;
    final distanceKm = centre.calculateDistanceKmFrom(
      farmerCoords?.latitude,
      farmerCoords?.longitude,
    );
    final hasLocation = LocationDistanceService.instance.hasLocation;

    final distanceLabel = LocationDistanceService.formatDistanceLabel(
      hasLocation ? distanceKm : null,
      isHindi: _isHindi,
      isTelugu: _isTelugu,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
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
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.cardBorder,
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
                              centre.address ?? centre.subLocation,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // EXPLICIT SELECT CENTRE BUTTON
                      ElevatedButton(
                        key: ValueKey('btn_select_centre_${centre.id}'),
                        onPressed: () {
                          setState(() {
                            _selectedCentre = centre;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.surface,
                          foregroundColor: isSelected
                              ? Colors.white
                              : AppColors.primaryGreen,
                          elevation: isSelected ? 1 : 0,
                          side: BorderSide(
                            color: AppColors.primaryGreen,
                            width: isSelected ? 1.5 : 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              isSelected
                                  ? (_isTelugu
                                      ? 'ఎంచుకోబడింది'
                                      : (_isHindi ? 'चयनित' : 'Selected'))
                                  : (_isTelugu
                                      ? 'కేంద్రాన్ని ఎంచుకోండి'
                                      : (_isHindi
                                          ? 'केंद्र चुनें'
                                          : 'Select Centre')),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  const SizedBox(height: 10),

                  // ATTRIBUTES BADGES
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Distance badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasLocation
                              ? AppColors.primaryContainer
                                  .withValues(alpha: 0.5)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasLocation
                                ? AppColors.primaryLight
                                : AppColors.cardBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasLocation
                                  ? Icons.near_me_rounded
                                  : Icons.location_off_outlined,
                              size: 14,
                              color: hasLocation
                                  ? AppColors.primaryGreen
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distanceLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: hasLocation
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: centre.isNormal
                              ? AppColors.primaryGreen.withValues(alpha: 0.12)
                              : AppColors.warningContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: centre.isNormal
                                    ? AppColors.primaryGreen
                                    : AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              centre.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: centre.isNormal
                                    ? AppColors.primaryGreen
                                    : AppColors.warning,
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
                                  ? 'క్యూ: ${centre.queueStatus == 'Low' ? 'తక్కువ' : 'మధ్యస్థం'} • ${centre.queueEstimate}'
                                  : (_isHindi
                                      ? 'कतार: ${centre.queueStatus == 'Low' ? 'कम' : 'मध्यम'} • ${centre.queueEstimate}'
                                      : 'Queue: ${centre.queueStatus} • ${centre.queueEstimate}'),
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

                      // Available Slots badge
                      if (centre.availableSlotsCount != null &&
                          centre.availableSlotsCount! > 0)
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
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isTelugu
                                    ? 'స్లాట్‌లు: ${centre.availableSlotsCount}'
                                    : (_isHindi
                                        ? 'स्लॉट: ${centre.availableSlotsCount}'
                                        : 'Slots: ${centre.availableSlotsCount}'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
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
      );
  }
}

// ==========================================
// SEARCHABLE LOCATION BOTTOM SHEET
// ==========================================
class _SearchableLocationBottomSheet extends StatefulWidget {
  final String title;
  final List<LocationItem> items;
  final LocationItem? currentSelection;
  final bool isHindi;
  final bool isTelugu;

  const _SearchableLocationBottomSheet({
    required this.title,
    required this.items,
    required this.currentSelection,
    required this.isHindi,
    required this.isTelugu,
  });

  @override
  State<_SearchableLocationBottomSheet> createState() =>
      _SearchableLocationBottomSheetState();
}

class _SearchableLocationBottomSheetState
    extends State<_SearchableLocationBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<LocationItem> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          final en = item.nameEn.toLowerCase();
          final hi = item.nameHi.toLowerCase();
          final te = item.nameTe.toLowerCase();
          return en.contains(clean) ||
              hi.contains(clean) ||
              te.contains(clean);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Search Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: false,
              decoration: InputDecoration(
                hintText: widget.isTelugu
                    ? 'శోధించండి...'
                    : (widget.isHindi ? 'खोजें...' : 'Search...'),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.primaryGreen),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // List of items
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(
                      widget.isTelugu
                          ? 'ఫలితాలు కనుగొనబడలేదు'
                          : (widget.isHindi
                              ? 'कोई परिणाम नहीं मिला'
                              : 'No matches found'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected =
                          widget.currentSelection?.id == item.id;
                      final localized = item.localizedName(
                        isHindi: widget.isHindi,
                        isTelugu: widget.isTelugu,
                      );

                      return InkWell(
                        key: ValueKey('picker_item_${item.id}'),
                        onTap: () => Navigator.of(context).pop(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 56),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryContainer
                                    .withValues(alpha: 0.4)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localized,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primaryGreen
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (localized != item.nameEn)
                                      Text(
                                        item.nameEn,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primaryGreen,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
