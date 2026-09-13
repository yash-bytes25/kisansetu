import 'package:flutter/material.dart';
import '../services/app_preferences_service.dart';
import '../services/auth_service.dart';
import '../services/procurement_state_service.dart';
import '../services/repositories/repository_provider.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import 'farmer_crop_selection_screen.dart';
import 'language_preferences_screen.dart';
import 'role_selection_screen.dart';

/// Screen allowing the farmer to view and update profile information,
/// registered produce, Aadhaar/DBT details, language preferences, and account actions.
class FarmerProfileScreen extends StatefulWidget {
  final bool isHindi;
  final bool isTelugu;

  const FarmerProfileScreen({
    super.key,
    required this.isHindi,
    this.isTelugu = false,
  });

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _service = ProcurementStateService();
  final _prefs = AppPreferencesService.instance;
  late String _farmerName;
  late String _phone;
  late String _farmerState;
  late String _farmerDistrict;
  late String _farmerVillage;
  late String _aadhaarMasked;
  late String _bankName;
  late String _accountNumber;
  late String _ifscCode;
  late String _dbtStatus;
  String _farmerId = '22222222-2222-2222-2222-222222222222';
  bool _isLoading = false;

  bool get _isTelugu => widget.isTelugu;
  bool get _isHindi => widget.isHindi;

  @override
  void initState() {
    super.initState();
    _farmerName = _service.farmerData.farmerName;
    _farmerState = _service.farmerState;
    _farmerDistrict = _service.farmerDistrict;
    _farmerVillage = _service.farmerVillage;
    _aadhaarMasked = _service.aadhaarMasked;
    _bankName = _service.bankName;
    _accountNumber = _service.bankAccountNumber;
    _ifscCode = _service.ifscCode;
    _dbtStatus = _service.dbtStatus;
    _phone = AuthService.instance.currentPhone ?? '9876543210';
    _farmerId = AuthService.instance.currentUserId ??
        '22222222-2222-2222-2222-222222222222';
    _prefs.addListener(_onPrefsUpdated);
    _service.addListener(_onStateUpdated);
    _loadProfile();
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsUpdated);
    _service.removeListener(_onStateUpdated);
    super.dispose();
  }

  void _onPrefsUpdated() {
    if (mounted) setState(() {});
  }

  void _onStateUpdated() {
    if (mounted) {
      setState(() {
        _farmerName = _service.farmerData.farmerName;
        _farmerState = _service.farmerState;
        _farmerDistrict = _service.farmerDistrict;
        _farmerVillage = _service.farmerVillage;
        _aadhaarMasked = _service.aadhaarMasked;
        _bankName = _service.bankName;
        _accountNumber = _service.bankAccountNumber;
        _ifscCode = _service.ifscCode;
        _dbtStatus = _service.dbtStatus;
      });
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile =
          await RepositoryProvider.farmer.getFarmerProfile(_farmerId);
      if (profile != null && mounted) {
        setState(() {
          if (profile['name'] != null &&
              profile['name'].toString().trim().isNotEmpty) {
            _farmerName = profile['name'].toString();
          }
          if (profile['phone'] != null) {
            _phone = profile['phone'].toString();
          }
          if (profile['state'] != null &&
              profile['state'].toString().trim().isNotEmpty) {
            _farmerState = profile['state'].toString();
          }
          if (profile['district'] != null &&
              profile['district'].toString().trim().isNotEmpty) {
            _farmerDistrict = profile['district'].toString();
          }
          if (profile['village'] != null &&
              profile['village'].toString().trim().isNotEmpty) {
            _farmerVillage = profile['village'].toString();
          }
          if (profile['bank_name'] != null &&
              profile['bank_name'].toString().trim().isNotEmpty) {
            _bankName = profile['bank_name'].toString();
          }
          if (profile['ifsc_code'] != null &&
              profile['ifsc_code'].toString().trim().isNotEmpty) {
            _ifscCode = profile['ifsc_code'].toString();
          }
        });
      }
    } catch (e) {
      debugPrint('FarmerProfileScreen._loadProfile error: $e');
    }
  }

  Future<void> _editNameDialog() async {
    final controller = TextEditingController(text: _farmerName);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _isTelugu
              ? 'పేరును సవరించండి'
              : (_isHindi ? 'नाम संपादित करें' : 'Edit Name'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: _isTelugu
                  ? 'రైతు పేరు'
                  : (_isHindi ? 'किसान का नाम' : 'Farmer Name'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return _isTelugu
                    ? 'దయచేసి చెల్లుబాటు అయ్యే పేరును నమోదు చేయండి'
                    : (_isHindi
                        ? 'कृपया एक मान्य नाम दर्ज करें'
                        : 'Please enter a valid name');
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _isTelugu ? 'రద్దు' : (_isHindi ? 'रद्द करें' : 'Cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(_isTelugu ? 'సేవ్ చేయండి' : (_isHindi ? 'सहेजें' : 'Save')),
          ),
        ],
      ),
    );

    if (updated != null && updated.isNotEmpty && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        await RepositoryProvider.farmer.createOrUpdateProfile(
          id: _farmerId,
          phone: _phone,
          name: updated,
          preferredLanguage: _prefs.uiLanguage,
        );

        _service.updateFarmerName(updated);

        setState(() {
          _farmerName = updated;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isTelugu
                    ? 'ప్రొఫైల్ విజయవంతంగా నవీకరించబడింది'
                    : (_isHindi
                        ? 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई'
                        : 'Profile updated successfully'),
              ),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _openEditKycDialog() async {
    final stateController = TextEditingController(text: _farmerState);
    final districtController = TextEditingController(text: _farmerDistrict);
    final villageController = TextEditingController(text: _farmerVillage);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.badge_outlined,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isTelugu
                    ? 'వ్యక్తిగత & KYC వివరాలను సవరించండి'
                    : (_isHindi
                        ? 'व्यक्तिगत और आधार विवरण संपादित करें'
                        : 'Edit Personal & KYC Details'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Mobile Number (Read-only / Protected)
                  TextFormField(
                    initialValue: '+91 $_phone',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: _isTelugu
                          ? 'మొబైల్ సంఖ్య'
                          : (_isHindi ? 'मोबाइल नंबर' : 'Mobile Number'),
                      prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                      suffixIcon: const Tooltip(
                        message: 'Authentication identity - protected',
                        child: Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textTertiary),
                      ),
                      helperText: _isTelugu
                          ? 'లాగిన్ కోసం లింక్ చేయబడింది (రక్షించబడింది)'
                          : (_isHindi
                              ? 'प्रमाणीकरण से जुड़ा हुआ (सुरक्षित)'
                              : 'Linked to authentication (read-only)'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Aadhaar (e-KYC) (Masked & Verified / Protected)
                  TextFormField(
                    initialValue: _aadhaarMasked,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: _isTelugu
                          ? 'ఆధార్ (e-KYC)'
                          : (_isHindi ? 'आधार (ई-केवाईसी)' : 'Aadhaar (e-KYC)'),
                      prefixIcon: const Icon(Icons.verified_user_outlined, size: 20),
                      suffixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _isTelugu
                                  ? 'ధృవీకరించబడింది'
                                  : (_isHindi ? 'सत्यापित' : 'Verified'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      helperText: _isTelugu
                          ? 'ప్రోటోటైప్ e-KYC ధృవీకరించబడింది'
                          : (_isHindi
                              ? 'प्रोटोटाइप ई-केवाईसी सत्यापित'
                              : 'Prototype e-KYC Verified (masked)'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. State (Editable)
                  TextFormField(
                    key: const ValueKey('input_kyc_state'),
                    controller: stateController,
                    decoration: InputDecoration(
                      labelText: _isTelugu ? 'రాష్ట్రం' : (_isHindi ? 'राज्य' : 'State'),
                      prefixIcon: const Icon(Icons.map_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isTelugu
                            ? 'దయచేసి రాష్ట్రాన్ని నమోదు చేయండి'
                            : (_isHindi ? 'कृपया राज्य दर्ज करें' : 'Please enter state');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 4. District (Editable)
                  TextFormField(
                    key: const ValueKey('input_kyc_district'),
                    controller: districtController,
                    decoration: InputDecoration(
                      labelText: _isTelugu ? 'జిల్లా' : (_isHindi ? 'ज़िला' : 'District'),
                      prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isTelugu
                            ? 'దయచేసి జిల్లాను నమోదు చేయండి'
                            : (_isHindi ? 'कृपया ज़िला दर्ज करें' : 'Please enter district');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 5. Village (Editable)
                  TextFormField(
                    key: const ValueKey('input_kyc_village'),
                    controller: villageController,
                    decoration: InputDecoration(
                      labelText: _isTelugu ? 'గ్రామం' : (_isHindi ? 'गाँव' : 'Village'),
                      prefixIcon: const Icon(Icons.holiday_village_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isTelugu
                            ? 'దయచేసి గ్రామాన్ని నమోదు చేయండి'
                            : (_isHindi ? 'कृपया गाँव दर्ज करें' : 'Please enter village');
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('btn_cancel_kyc'),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _isTelugu ? 'రద్దు' : (_isHindi ? 'रद्द करें' : 'Cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            key: const ValueKey('btn_save_kyc'),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newState = stateController.text.trim();
                final newDistrict = districtController.text.trim();
                final newVillage = villageController.text.trim();

                Navigator.pop(ctx);

                _service.updateKycDetails(
                  state: newState,
                  district: newDistrict,
                  village: newVillage,
                );

                await RepositoryProvider.farmer.updateKycDetails(
                  farmerId: _farmerId,
                  state: newState,
                  district: newDistrict,
                  village: newVillage,
                );

                if (mounted) {
                  setState(() {
                    _farmerState = newState;
                    _farmerDistrict = newDistrict;
                    _farmerVillage = newVillage;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isTelugu
                            ? 'వ్యక్తిగత & KYC వివరాలు విజయవంతంగా నవీకరించబడ్డాయి'
                            : (_isHindi
                                ? 'व्यक्तिगत और आधार विवरण सफलतापूर्वक अपडेट किए गए'
                                : 'Personal & KYC details updated successfully'),
                      ),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _isTelugu ? 'సేవ్ చేయండి' : (_isHindi ? 'सहेजें' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditBankDialog() async {
    final bankNameController = TextEditingController(text: _bankName);
    final accountController = TextEditingController(text: _accountNumber);
    final ifscController = TextEditingController(text: _ifscCode);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isTelugu
                    ? 'MSP DBT బ్యాంకు వివరాలను సవరించండి'
                    : (_isHindi
                        ? 'एमएसपी डीबीटी बैंक विवरण संपादित करें'
                        : 'Edit MSP DBT Bank Details'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Bank Name
                  TextFormField(
                    key: const ValueKey('input_bank_name'),
                    controller: bankNameController,
                    decoration: InputDecoration(
                      labelText: _isTelugu
                          ? 'బ్యాంకు పేరు'
                          : (_isHindi ? 'बैंक का नाम' : 'Bank Name'),
                      prefixIcon: const Icon(Icons.account_balance_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 3) {
                        return _isTelugu
                            ? 'దయచేసి సరైన బ్యాంకు పేరును నమోదు చేయండి'
                            : (_isHindi
                                ? 'कृपया एक मान्य बैंक का नाम दर्ज करें'
                                : 'Please enter a valid bank name');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. Account Number
                  TextFormField(
                    key: const ValueKey('input_bank_account_number'),
                    controller: accountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _isTelugu
                          ? 'ఖాతా సంఖ్య'
                          : (_isHindi ? 'खाता संख्या' : 'Account Number'),
                      prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                      helperText: _isTelugu
                          ? '9 నుండి 18 అంకెల సంఖ్య (ప్రొఫైల్‌లో మాస్క్ చేయబడుతుంది)'
                          : (_isHindi
                              ? '9 से 18 अंकों की संख्या (प्रोफ़ाइल पर सुरक्षित रहेगी)'
                              : '9 to 18 digits (masked on profile display)'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isTelugu
                            ? 'దయచేసి ఖాతా సంఖ్యను నమోదు చేయండి'
                            : (_isHindi
                                ? 'कृपया खाता संख्या दर्ज करें'
                                : 'Please enter account number');
                      }
                      final clean = val.trim().replaceAll(' ', '');
                      if (!RegExp(r'^\d{9,18}$').hasMatch(clean)) {
                        return _isTelugu
                            ? 'ఖాతా సంఖ్య 9 నుండి 18 అంకెలు ఉండాలి'
                            : (_isHindi
                                ? 'खाता संख्या 9 से 18 अंकों की होनी चाहिए'
                                : 'Account number must be 9 to 18 digits');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. IFSC Code
                  TextFormField(
                    key: const ValueKey('input_bank_ifsc_code'),
                    controller: ifscController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'IFSC Code',
                      prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                      helperText: _isTelugu
                          ? '11 అక్షరాల IFSC (ఉదా. SBIN0001234)'
                          : (_isHindi
                              ? '11 अक्षरों का आईएफएससी (उदा. SBIN0001234)'
                              : '11-character IFSC (e.g. SBIN0001234)'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return _isTelugu
                            ? 'దయచేసి IFSC కోడ్‌ను నమోదు చేయండి'
                            : (_isHindi ? 'कृपया IFSC कोड दर्ज करें' : 'Please enter IFSC code');
                      }
                      final clean = val.trim().toUpperCase();
                      if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(clean)) {
                        return _isTelugu
                            ? 'చెల్లుబాటు అయ్యే 11-అక్షరాల IFSC కోడ్‌ను నమోదు చేయండి'
                            : (_isHindi
                                ? 'मान्य 11-अक्षरों का IFSC कोड दर्ज करें'
                                : 'Please enter a valid 11-character IFSC (e.g. SBIN0001234)');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 4. DBT Status (Read-only / System-controlled)
                  TextFormField(
                    initialValue: _isTelugu
                        ? 'ఆధార్-లింక్డ్ సక్రియం'
                        : (_isHindi ? 'आधार-लिंक्ड सक्रिय' : 'Aadhaar-Linked Active'),
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: _isTelugu
                          ? 'DBT స్థితి'
                          : (_isHindi ? 'DBT स्थिति' : 'DBT Status'),
                      prefixIcon: const Icon(Icons.security_rounded, size: 20),
                      suffixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      helperText: _isTelugu
                          ? 'NPCI ఆధార్ మ్యాపర్ ద్వారా సిస్టమ్-నియంత్రిత స్థితి'
                          : (_isHindi
                              ? 'एनपीसीआई आधार मैपर द्वारा सिस्टम-नियंत्रित'
                              : 'System-controlled via NPCI Aadhaar mapper'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('btn_cancel_bank'),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _isTelugu ? 'రద్దు' : (_isHindi ? 'रद्द करें' : 'Cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            key: const ValueKey('btn_save_bank'),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newBank = bankNameController.text.trim();
                final newAcc = accountController.text.trim().replaceAll(' ', '');
                final newIfsc = ifscController.text.trim().toUpperCase();

                // Show confirmation before saving sensitive bank changes
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (confirmCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isTelugu
                                ? 'బ్యాంక్ వివరాల నవీకరణను ధృవీకరించండి'
                                : (_isHindi
                                    ? 'बैंक विवरण अपडेट की पुष्टि करें'
                                    : 'Confirm Bank Details Update'),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTelugu
                              ? 'మీరు మీ MSP DBT బ్యాంక్ ఖాతా వివరాలను క్రింది విధంగా మార్చాలనుకుంటున్నారా?'
                              : (_isHindi
                                  ? 'क्या आप अपना एमएसपी डीबीटी बैंक खाता विवरण निम्नानुसार अपडेट करना चाहते हैं?'
                                  : 'Are you sure you want to update your MSP DBT bank account to the following?'),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                newBank,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A/C ending in **${newAcc.length >= 4 ? newAcc.substring(newAcc.length - 4) : newAcc} • IFSC: $newIfsc',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isTelugu
                              ? 'భవిష్యత్తులోని అన్ని MSP చెల్లింపులు ఈ ధృవీకరించబడిన ఖాతాకు జమ చేయబడతాయి.'
                              : (_isHindi
                                  ? 'भविष्य के सभी एमएसपी भुगतान सीधे इस सत्यापित खाते में भेजे जाएंगे।'
                                  : 'All future MSP procurement proceeds will be transferred directly to this verified account.'),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        key: const ValueKey('btn_cancel_bank_confirm'),
                        onPressed: () => Navigator.pop(confirmCtx, false),
                        child: Text(
                          _isTelugu ? 'రద్దు' : (_isHindi ? 'रद्द करें' : 'Cancel'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      ElevatedButton(
                        key: const ValueKey('btn_confirm_save_bank'),
                        onPressed: () => Navigator.pop(confirmCtx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _isTelugu ? 'ధృవీకరించి సేవ్ చేయండి' : (_isHindi ? 'पुष्टि करें और सहेजें' : 'Confirm & Save'),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted && ctx.mounted) {
                  Navigator.pop(ctx);

                  _service.updateBankDetails(
                    bankName: newBank,
                    accountNumber: newAcc,
                    ifscCode: newIfsc,
                  );

                  final masked = 'A/C ending in **${newAcc.length >= 4 ? newAcc.substring(newAcc.length - 4) : newAcc}';

                  await RepositoryProvider.farmer.updateBankDetails(
                    farmerId: _farmerId,
                    bankName: newBank,
                    accountNumberMasked: masked,
                    ifscCode: newIfsc,
                  );

                  if (mounted) {
                    setState(() {
                      _bankName = newBank;
                      _accountNumber = newAcc;
                      _ifscCode = newIfsc;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isTelugu
                              ? 'DBT బ్యాంక్ వివరాలు విజయవంతంగా నవీకరించబడ్డాయి'
                              : (_isHindi
                                  ? 'डीबीटी बैंक विवरण सफलतापूर्वक अपडेट किए गए'
                                  : 'DBT bank details updated successfully'),
                        ),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _isTelugu ? 'సేవ్ చేయండి' : (_isHindi ? 'सहेजें' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _openChangeCrop() async {
    final qtyStr =
        _service.farmerData.quantity.replaceAll(RegExp(r'[^0-9.]'), '');
    final currentQty = double.tryParse(qtyStr) ?? 50.0;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => FarmerCropSelectionScreen(
          currentCropName: _service.farmerData.cropName,
          currentQuantity: currentQty,
          isHindi: _isHindi,
          isTelugu: _isTelugu,
          showProminentOnly: true,
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  void _showVoiceGuidance() {
    final data = _service.farmerData;
    final text = _isTelugu
        ? 'రైతు ప్రొఫైల్: $_farmerName, మొబైల్: $_phone, పంట: ${data.cropName}, రాష్ట్రం: $_farmerState, జిల్లా: $_farmerDistrict, గ్రామం: $_farmerVillage. బ్యాంక్: $_bankName, ఖాతా: ${_service.bankAccountNumberMasked}, IFSC: $_ifscCode. ఆధార్ ధృవీకరించబడింది మరియు డీబీటీ సక్రియంగా ఉంది.'
        : (_isHindi
            ? 'किसान प्रोफ़ाइल: $_farmerName, मोबाइल: $_phone, फसल: ${data.cropName}, राज्य: $_farmerState, ज़िला: $_farmerDistrict, गाँव: $_farmerVillage। बैंक: $_bankName, खाता: ${_service.bankAccountNumberMasked}, IFSC: $_ifscCode। आधार सत्यापित है और डीबीटी सक्रिय है।'
            : 'Farmer Profile: $_farmerName, Phone: $_phone, Crop: ${data.cropName}, State: $_farmerState, District: $_farmerDistrict, Village: $_farmerVillage. Bank: $_bankName, Account: ${_service.bankAccountNumberMasked}, IFSC: $_ifscCode. Aadhaar is verified and DBT is active.');

    final langCode = _isTelugu ? 'te-IN' : (_isHindi ? 'hi-IN' : 'en-IN');
    VoiceAssistantSpeechService.instance.speak(text, language: langCode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 4),
        content: Text(text),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _isTelugu
              ? 'లాగ్ అవుట్ కావాలా?'
              : (_isHindi ? 'लॉग आउट करें?' : 'Log Out?'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          _isTelugu
              ? 'మీరు మీ కిసాన్‌సేతు ఖాతా నుండి లాగ్ అవుట్ చేయాలనుకుంటున్నారా?'
              : (_isHindi
                  ? 'क्या आप अपने किसानसेतु खाते से लॉग आउट करना चाहते हैं?'
                  : 'Are you sure you want to log out of your KisanSetu account?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _isTelugu ? 'రద్దు' : (_isHindi ? 'रद्द करें' : 'Cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(_isTelugu
                ? 'లాగ్ అవుట్'
                : (_isHindi ? 'लॉग आउट' : 'Log Out')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.instance.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const RoleSelectionScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmerData = _service.farmerData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: _isTelugu
              ? 'వెనుకకు'
              : (_isHindi ? 'वापस जाएं' : 'Back'),
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
            Text(
              _isTelugu
                  ? 'నా ప్రొఫైల్'
                  : (_isHindi ? 'मेरी प्रोफ़ाइल' : 'My Profile'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            label: 'Listen to profile guidance',
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
                  _isTelugu
                      ? 'వినండి'
                      : (_isHindi ? 'सुनें' : 'Listen'),
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Farmer Identity Card
                  _buildHeaderCard(),
                  const SizedBox(height: 16),

                  // 2. Personal & KYC Details Card
                  _buildCard(
                    title: _isTelugu
                        ? 'వ్యక్తిగత & ఆధార్ వివరాలు'
                        : (_isHindi
                            ? 'व्यक्तिगत और आधार विवरण'
                            : 'Personal & KYC Details'),
                    icon: Icons.badge_outlined,
                    action: TextButton.icon(
                      key: const ValueKey('btn_edit_personal_kyc'),
                      onPressed: _openEditKycDialog,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(
                        _isTelugu
                            ? 'సవరించండి'
                            : (_isHindi ? 'संपादित करें' : 'Edit'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                      ),
                    ),
                    children: [
                      _buildDetailRow(
                        label: _isTelugu
                            ? 'మొబైల్ సంఖ్య'
                            : (_isHindi ? 'मोबाइल नंबर' : 'Mobile Number'),
                        value: '+91 $_phone',
                      ),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      _buildDetailRow(
                        label: _isTelugu
                            ? 'ఆధార్ సంఖ్య'
                            : (_isHindi ? 'आधार संख्या' : 'Aadhaar (e-KYC)'),
                        value: _aadhaarMasked,
                        badge: _isTelugu
                            ? 'ధృవీకరించబడింది'
                            : (_isHindi ? 'सत्यापित' : 'Verified'),
                        badgeColor: AppColors.primaryGreen,
                      ),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      _buildDetailRow(
                        label: _isTelugu
                            ? 'రాష్ట్రం & జిల్లా'
                            : (_isHindi ? 'राज्य और ज़िला' : 'State & District'),
                        value: '$_farmerState · $_farmerDistrict',
                      ),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      _buildDetailRow(
                        label: _isTelugu ? 'గ్రామం' : (_isHindi ? 'गाँव' : 'Village'),
                        value: _farmerVillage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Registered Farming & Produce Card
                  _buildCard(
                    title: _isTelugu
                        ? 'నమోదిత వ్యవసాయం & పంట'
                        : (_isHindi
                            ? 'पंजीकृत कृषि और उपज'
                            : 'Registered Farming & Produce'),
                    icon: Icons.agriculture_rounded,
                    action: TextButton.icon(
                      onPressed: _openChangeCrop,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(
                        _isTelugu
                            ? 'పంట మార్చండి'
                            : (_isHindi ? 'फसल बदलें' : 'Change Crop'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                      ),
                    ),
                    children: [
                      _buildDetailRow(
                        label: _isTelugu
                            ? 'ప్రాథమిక పంట'
                            : (_isHindi ? 'प्राथमिक फसल' : 'Primary Crop'),
                        value: farmerData.cropName,
                      ),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      _buildDetailRow(
                        label: _isTelugu
                            ? 'నమోదిత పరిమాణం'
                            : (_isHindi ? 'पंजीकृत मात्रा' : 'Registered Quantity'),
                        value: farmerData.quantity,
                      ),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      _buildDetailRow(
                        label: _isTelugu
                            ? 'కేటాయించిన కేంద్రం'
                            : (_isHindi ? 'आवंटित केंद्र' : 'Assigned Centre'),
                        value: farmerData.centreName,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. MSP Direct Benefit Transfer (DBT) Bank Account Card
                  _buildCard(
                    title: _isTelugu
                        ? 'MSP ప్రత్యక్ష ప్రయోజన బదిలీ (DBT) బ్యాంకు'
                        : (_isHindi
                            ? 'एमएसपी प्रत्यक्ष लाभ अंतरण (DBT) बैंक'
                            : 'MSP Direct Benefit Transfer (DBT) Bank'),
                    icon: Icons.account_balance_rounded,
                    action: TextButton.icon(
                      key: const ValueKey('btn_edit_bank_details'),
                      onPressed: _openEditBankDialog,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(
                        _isTelugu
                            ? 'సవరించండి'
                            : (_isHindi ? 'संपादित करें' : 'Edit'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                      ),
                    ),
                    children: [
                      _buildDetailRow(
                        label: _isTelugu
                            ? 'బ్యాంకు పేరు'
                            : (_isHindi ? 'बैंक का नाम' : 'Bank Name'),
                        value: _bankName,
                      ),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      _buildDetailRow(
                        label: _isTelugu
                            ? 'ఖాతా సంఖ్య'
                            : (_isHindi ? 'खाता संख्या' : 'Account Number'),
                        value: _service.bankAccountNumberMasked,
                      ),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      _buildDetailRow(
                        label: 'IFSC Code',
                        value: _ifscCode,
                      ),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      _buildDetailRow(
                        label: _isTelugu
                            ? 'DBT స్థితి'
                            : (_isHindi ? 'DBT स्थिति' : 'DBT Status'),
                        value: _isTelugu
                            ? 'ఆధార్-లింక్డ్ సక్రియం'
                            : (_isHindi
                                ? 'आधार-लिंक्ड सक्रिय'
                                : _dbtStatus),
                        badge: 'ACTIVE',
                        badgeColor: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Preferences Card
                  _buildCard(
                    title: _isTelugu
                        ? 'భాష & ప్రాధాన్యతలు'
                        : (_isHindi
                            ? 'भाषा और प्राथमिकताएं'
                            : 'Language & Preferences'),
                    icon: Icons.language_rounded,
                    action: TextButton.icon(
                      onPressed: () =>
                          LanguagePreferencesScreen.show(context),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: Text(
                        _isTelugu
                            ? 'మార్చండి'
                            : (_isHindi ? 'बदलें' : 'Change'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                      ),
                    ),
                    children: [
                      _buildDetailRow(
                        label: _isTelugu
                            ? 'ప్రస్తుత యాప్ భాష'
                            : (_isHindi ? 'वर्तमान ऐप भाषा' : 'Current App Language'),
                        value: _isTelugu
                            ? 'తెలుగు (Telugu)'
                            : (_isHindi ? 'हिंदी (Hindi)' : 'English'),
                      ),
                      const Divider(height: 20, color: AppColors.cardBorder),
                      _buildDetailRow(
                        label: _isTelugu
                            ? 'వాయిస్ సహాయకుడు'
                            : (_isHindi ? 'आवाज़ सहायक' : 'Voice Assistant'),
                        value: _isTelugu
                            ? 'తెలుగు మాట్లాడటం సక్రియంగా ఉంది'
                            : (_isHindi
                                ? 'हिंदी आवाज सक्षम'
                                : 'Active (Native TTS)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 6. Logout / Switch Account Action Button (>= 56dp height)
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.error),
                      label: Text(
                        _isTelugu
                            ? 'ఖాతా నుండి లాగ్ అవుట్ చేయండి'
                            : (_isHindi
                                ? 'खाते से लॉग आउट करें'
                                : 'Log Out / Switch Account'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    final initials = _farmerName.isNotEmpty
        ? _farmerName
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'RK';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryGreen,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _farmerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          size: 18, color: AppColors.primaryGreen),
                      tooltip: _isTelugu
                          ? 'పేరును సవరించండి'
                          : (_isHindi ? 'नाम संपादित करें' : 'Edit Name'),
                      onPressed: _editNameDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'FID: ${_farmerId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isTelugu
                            ? 'ధృవీకరించబడిన రైతు'
                            : (_isHindi
                                ? 'सत्यापित किसान'
                                : 'Verified Farmer'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    String? badge,
    Color? badgeColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.primaryGreen)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeColor ?? AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
