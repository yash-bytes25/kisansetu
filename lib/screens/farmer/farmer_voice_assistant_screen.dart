// KisanSetu (SIH26032) - Voice-First Assistant Screen
// Clean premium GREEN + WHITE KisanSetu agricultural theme.
// Dedicated full-screen voice-first interface: NOT a chatbox and NOT a text conversation UI.
// Tagline: "Speak. Understand. Confirm. Act."

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/procurement_centre.dart';
import '../../models/voice/voice_intent.dart';
import '../../models/voice/voice_message.dart';
import '../../services/app_preferences_service.dart';
import '../../services/procurement_state_service.dart';
import '../../services/voice/voice_assistant_service.dart';
import '../farmer_smart_slot_screen.dart';

class FarmerVoiceAssistantScreen extends StatefulWidget {
  final bool isHindi;
  final bool isTelugu;
  final VoiceAssistantMode initialMode;

  const FarmerVoiceAssistantScreen({
    super.key,
    this.isHindi = false,
    this.isTelugu = false,
    this.initialMode = VoiceAssistantMode.ask,
  });

  @override
  State<FarmerVoiceAssistantScreen> createState() =>
      _FarmerVoiceAssistantScreenState();
}

class _FarmerVoiceAssistantScreenState extends State<FarmerVoiceAssistantScreen>
    with TickerProviderStateMixin {
  final VoiceAssistantService _voiceService = VoiceAssistantService.instance;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  late bool _isHindi;
  late bool _isTelugu;
  late String _voiceLocale;
  String? _lastAssistantSpeech;

  // Agricultural Palette Constants
  static const Color _primaryGreen = Color(0xFF168A3A);
  static const Color _darkGreen = Color(0xFF0B5D2A);
  static const Color _lightGreen = Color(0xFFEAF7ED);
  static const Color _borderColor = Color(0xFFD5EED8);
  static const Color _charcoalText = Color(0xFF1B3D2F);

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi || AppPreferencesService.instance.isHindi;
    _isTelugu = widget.isTelugu || AppPreferencesService.instance.isTelugu;
    _voiceLocale = AppPreferencesService.instance.voiceLocale;

    _voiceService.session.setMode(widget.initialMode);
    _voiceService.session.setVoiceLanguage(_voiceLocale);
    _voiceService.addListener(_onVoiceStateChanged);

    // Microphone concentric rings pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Audio waveform animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    // Auto-start listening on screen entry to emphasize voice-first interaction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_voiceService.isListening) {
        _voiceService.startListening();
      }
    });
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceStateChanged);
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onVoiceStateChanged() {
    if (!mounted) return;
    final msgs = _voiceService.session.messages;
    if (msgs.isNotEmpty) {
      final last = msgs.lastWhere(
        (m) => m.sender == VoiceSender.assistant,
        orElse: () => msgs.last,
      );
      if (last.sender == VoiceSender.assistant) {
        _lastAssistantSpeech = last.text;
      }
    }
    setState(() {});
  }

  void _toggleListening() {
    if (_voiceService.isListening) {
      _voiceService.stopListening();
    } else {
      _voiceService.startListening();
    }
  }

  void _handleQuickAction(String actionPrompt) {
    _voiceService.processUserInput(actionPrompt);
  }

  Future<void> _handleConfirm() async {
    final res = await _voiceService.confirmAction();
    if (res.isSuccess && mounted) {
      if (res.navigateRoute == 'smart_slot') {
        final state = ProcurementStateService.instance;
        final centre = ProcurementCentre.getMockCentres().firstWhere(
          (c) => c.name == state.farmerData.centreName,
          orElse: () => ProcurementCentre.getMockCentres().first,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FarmerSmartSlotScreen(
              selectedCentre: centre,
              currentData: state.farmerData,
              isHindi: _isHindi,
              isTelugu: _isTelugu,
            ),
          ),
        );
      }
    }
  }

  void _handleChange() {
    _voiceService.processUserInput('Change quantity or crop');
  }

  void _handleCancel() {
    _voiceService.cancelAction();
  }

  void _changeLanguage(String localeCode) {
    final short = localeCode.startsWith('te')
        ? 'te'
        : (localeCode.startsWith('hi') ? 'hi' : 'en');
    setState(() {
      _voiceLocale = localeCode;
      _isHindi = short == 'hi';
      _isTelugu = short == 'te';
    });
    AppPreferencesService.instance.setVoiceLanguage(short);
    _voiceService.session.setVoiceLanguage(localeCode);
  }

  String _getLanguageLabel() {
    if (_isTelugu) return 'తెలుగు';
    if (_isHindi) return 'हिंदी';
    return 'English';
  }

  @override
  Widget build(BuildContext context) {
    final activeIntent = _voiceService.session.currentIntent;
    final showConfirmation = activeIntent != null && activeIntent.requiresConfirmation;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF9FCF9),
              Color(0xFFEAF7ED),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle agricultural leaf/field contours at bottom corners
            Positioned.fill(
              child: CustomPaint(
                painter: AgriculturalCornerPainter(),
              ),
            ),

            // Safe Area Layout
            SafeArea(
              child: Column(
                children: [
                  // 1. Header Bar
                  _buildHeader(),

                  const SizedBox(height: 6),

                  // 2. Center Segmented Navigation (ASK | DO | EXPLAIN)
                  _buildSegmentedNav(),

                  // 3. Dominant Main Voice Experience
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 18),

                                // Dominant Central Microphone, 4 Concentric Rings & Symmetrical Waveforms
                                _buildDominantVoiceCenter(),

                                const SizedBox(height: 20),

                                // Small Elegant Floating Spoken Response Card
                                if (_lastAssistantSpeech != null &&
                                    _lastAssistantSpeech!.isNotEmpty &&
                                    !showConfirmation)
                                  _buildSpokenResponseCard(_lastAssistantSpeech!),

                                // Safe Confirmation Card (Appears only on actionable requests)
                                if (showConfirmation)
                                  _buildConfirmationCard(activeIntent),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. Quick Actions Horizontal Scrollable Row
                  _buildQuickActionsRow(),

                  const SizedBox(height: 14),

                  // 5. Bottom Control ("Stop Listening" / "Start Listening")
                  _buildBottomControlButton(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. HEADER
  // ==========================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Top-left Back Arrow
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: _primaryGreen, size: 26),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
          ),

          // KisanSetu Leaf Logo
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _lightGreen,
              shape: BoxShape.circle,
              border: Border.all(color: _borderColor),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: _primaryGreen,
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          // Title: "KisanSetu Voice Assistant" & Subtitle: "Speak. Understand. Confirm. Act."
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'KisanSetu Voice Assistant',
                  style: TextStyle(
                    color: _charcoalText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Speak. Understand. Confirm. Act.',
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Top-Right Language Selector with Globe Icon and Current Language
          _buildLanguageSelector(),
        ],
      ),
    );
  }

  // ==========================================
  // TOP-RIGHT LANGUAGE SELECTOR
  // ==========================================
  Widget _buildLanguageSelector() {
    return PopupMenuButton<String>(
      tooltip: 'Select Language',
      onSelected: _changeLanguage,
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderColor),
      ),
      elevation: 4,
      color: Colors.white,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'en-IN',
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: _primaryGreen, size: 18),
              SizedBox(width: 8),
              Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'hi-IN',
          child: Row(
            children: [
              Icon(Icons.translate_rounded, color: _primaryGreen, size: 18),
              SizedBox(width: 8),
              Text('हिंदी (Hindi)', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'te-IN',
          child: Row(
            children: [
              Icon(Icons.translate_rounded, color: _primaryGreen, size: 18),
              SizedBox(width: 8),
              Text('తెలుగు (Telugu)', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _lightGreen,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, color: _primaryGreen, size: 18),
            const SizedBox(width: 5),
            Text(
              _getLanguageLabel(),
              style: const TextStyle(
                color: _primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: _primaryGreen, size: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. CENTER SEGMENTED NAVIGATION: ASK | DO | EXPLAIN
  // ==========================================
  Widget _buildSegmentedNav() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _lightGreen,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNavTabItem('ASK', VoiceAssistantMode.ask),
            _buildNavTabItem('DO', VoiceAssistantMode.doAction),
            _buildNavTabItem('EXPLAIN', VoiceAssistantMode.explain),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTabItem(String label, VoiceAssistantMode mode) {
    final isSelected = _voiceService.session.mode == mode;
    return GestureDetector(
      onTap: () {
        _voiceService.session.setMode(mode);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.32),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _primaryGreen,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. MAIN VOICE EXPERIENCE (MICROPHONE DOMINANT)
  // ==========================================
  Widget _buildDominantVoiceCenter() {
    final isListening = _voiceService.isListening;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Symmetrical Waveform + 4 Concentric Rings + Dark Green Center Microphone Button
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Symmetrical animated audio waveforms extending left and right
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: SymmetricalWaveformPainter(
                        animationValue: _waveController.value,
                        isActive: isListening,
                      ),
                    );
                  },
                ),
              ),

              // 4 Subtle Animated Concentric Green Rings
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(240, 240),
                    painter: FourConcentricRingsPainter(
                      pulseFactor: isListening ? _pulseAnimation.value : 1.0,
                      isActive: isListening,
                    ),
                  );
                },
              ),

              // Large Circular Dark-Green Microphone Button in the Center
              GestureDetector(
                key: const Key('btn_voice_mic'),
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _darkGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withValues(alpha: isListening ? 0.45 : 0.25),
                        blurRadius: isListening ? 26 : 14,
                        spreadRadius: isListening ? 4 : 1,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Three small green listening indicator dots below microphone
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final delay = index * 0.33;
                final wave = math.sin((_pulseController.value + delay) * math.pi * 2);
                final opacity = isListening ? (0.35 + 0.65 * (wave + 1) / 2).clamp(0.2, 1.0) : 0.25;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),

        const SizedBox(height: 10),

        // Display: "Listening..." when listening, "Tap to speak" when paused
        Text(
          isListening ? 'Listening...' : 'Tap to speak',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isListening ? _primaryGreen : const Color(0xFF43A047),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FLOATING SPOKEN RESPONSE CARD (NO CHAT UI)
  // ==========================================
  Widget _buildSpokenResponseCard(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 640),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: _lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: _primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _charcoalText,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CONFIRMATION CARD (EXPLICIT SAFETY MODAL)
  // ==========================================
  Widget _buildConfirmationCard(VoiceIntent intent) {
    final crop = intent.crop ?? 'Wheat';
    final qty = intent.quantity?.toStringAsFixed(0) ?? '50';
    final date = intent.date ?? 'Tomorrow';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      constraints: const BoxConstraints(maxWidth: 640),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                  color: _primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isTelugu
                    ? 'నేను అర్థం చేసుకున్నాను'
                    : (_isHindi ? 'मैंने समझा (पुष्टि करें)' : 'I understood (Confirmation)'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildEntityBadge('Crop', crop),
              _buildEntityBadge('Quantity', '$qty ${intent.quantityUnit}'),
              _buildEntityBadge('Date', date),
              _buildEntityBadge('Centre', 'Khanna Grain Market'),
              _buildEntityBadge('Recommended Slot', '11:30 AM (Good)'),
            ],
          ),
          const SizedBox(height: 18),
          // Action Buttons: [CONFIRM & CONTINUE], [CHANGE], [CANCEL]
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              key: const Key('btn_voice_confirm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: _handleConfirm,
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: Text(
                _isTelugu
                    ? 'ధృవీకరించి కొనసాగండి'
                    : (_isHindi ? 'पुष्टि करें और आगे बढ़ें' : 'CONFIRM & CONTINUE'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('btn_voice_change'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryGreen,
                    side: const BorderSide(color: _borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _handleChange,
                  child: Text(
                    _isTelugu ? 'మార్చండి' : (_isHindi ? 'बदलें' : 'CHANGE'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  key: const Key('btn_voice_cancel'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _handleCancel,
                  child: Text(
                    _isTelugu ? 'రద్దు' : (_isHindi ? 'रद्द करें' : 'CANCEL'),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntityBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: Color(0xFF558B2F), fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: _charcoalText, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. QUICK ACTIONS ROW
  // ==========================================
  Widget _buildQuickActionsRow() {
    final actions = [
      _QuickActionData(
        title: 'Book a slot',
        prompt: 'I want to sell 50 kg wheat tomorrow.',
        icon: Icons.calendar_month_rounded,
      ),
      _QuickActionData(
        title: 'Where is my token?',
        prompt: 'Where is my token?',
        icon: Icons.confirmation_number_rounded,
      ),
      _QuickActionData(
        title: 'When is my token?',
        prompt: 'When is my token?',
        icon: Icons.access_time_rounded,
      ),
      _QuickActionData(
        title: 'How many people are ahead?',
        prompt: 'How many people are ahead?',
        icon: Icons.people_alt_rounded,
      ),
      _QuickActionData(
        title: 'When should I leave?',
        prompt: 'When should I leave?',
        icon: Icons.departure_board_rounded,
      ),
      _QuickActionData(
        title: 'Payment status',
        prompt: 'Payment status',
        icon: Icons.payment_rounded,
      ),
      _QuickActionData(
        title: 'Which centre should I go to?',
        prompt: 'Which centre should I go to?',
        icon: Icons.location_on_rounded,
      ),
      _QuickActionData(
        title: 'I want to sell 50 kg wheat tomorrow.',
        prompt: 'I want to sell 50 kg wheat tomorrow.',
        icon: Icons.grass_rounded,
      ),
    ];

    return SizedBox(
      height: 46,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: actions.map((item) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                elevation: 0,
                pressElevation: 1,
                backgroundColor: Colors.white,
                side: const BorderSide(color: _borderColor, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                avatar: Icon(item.icon, color: _primaryGreen, size: 16),
                label: Text(
                  item.title,
                  style: const TextStyle(
                    color: _primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                onPressed: () => _handleQuickAction(item.prompt),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // 5. BOTTOM CONTROL BUTTON: STOP / START LISTENING
  // ==========================================
  Widget _buildBottomControlButton() {
    final isListening = _voiceService.isListening;
    return Center(
      child: ElevatedButton.icon(
        key: const Key('btn_voice_bottom_control'),
        onPressed: _toggleListening,
        icon: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_rounded,
          color: _primaryGreen,
          size: 22,
        ),
        label: Text(
          isListening ? 'Stop Listening' : 'Start Listening',
          style: const TextStyle(
            color: _primaryGreen,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightGreen,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: _borderColor, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _QuickActionData {
  final String title;
  final String prompt;
  final IconData icon;

  const _QuickActionData({
    required this.title,
    required this.prompt,
    required this.icon,
  });
}

// ==========================================
// CUSTOM PAINTER: 4 CONCENTRIC RINGS
// ==========================================
class FourConcentricRingsPainter extends CustomPainter {
  final double pulseFactor;
  final bool isActive;

  FourConcentricRingsPainter({
    required this.pulseFactor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final paint1 = Paint()
      ..color = const Color(0xFF168A3A).withValues(alpha: isActive ? 0.22 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paint2 = Paint()
      ..color = const Color(0xFF168A3A).withValues(alpha: isActive ? 0.14 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final paint3 = Paint()
      ..color = const Color(0xFF168A3A).withValues(alpha: isActive ? 0.08 : 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final paint4 = Paint()
      ..color = const Color(0xFF168A3A).withValues(alpha: isActive ? 0.04 : 0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final baseRadius = 54.0;
    final r1 = (baseRadius + 14.0) * pulseFactor;
    final r2 = (baseRadius + 36.0) * pulseFactor;
    final r3 = (baseRadius + 60.0) * pulseFactor;
    final r4 = (baseRadius + 84.0) * pulseFactor;

    canvas.drawCircle(center, r1, paint1);
    canvas.drawCircle(center, r2, paint2);
    canvas.drawCircle(center, r3, paint3);
    canvas.drawCircle(center, r4, paint4);
  }

  @override
  bool shouldRepaint(covariant FourConcentricRingsPainter oldDelegate) {
    return oldDelegate.pulseFactor != pulseFactor || oldDelegate.isActive != isActive;
  }
}

// ==========================================
// CUSTOM PAINTER: SYMMETRICAL AUDIO WAVEFORMS
// ==========================================
class SymmetricalWaveformPainter extends CustomPainter {
  final double animationValue;
  final bool isActive;

  SymmetricalWaveformPainter({
    required this.animationValue,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF168A3A).withValues(alpha: isActive ? 0.72 : 0.22)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    const barCount = 11;
    const barSpacing = 7.0;
    const centerOffset = 62.0;

    for (int i = 0; i < barCount; i++) {
      final factor = math.sin((animationValue * math.pi * 2) + (i * 0.45));
      final dynamicHeight = isActive ? (8.0 + 26.0 * (factor.abs())) : 6.0;

      // Left bars
      final leftX = center.dx - centerOffset - (i * barSpacing);
      if (leftX > 16) {
        canvas.drawLine(
          Offset(leftX, center.dy - dynamicHeight / 2),
          Offset(leftX, center.dy + dynamicHeight / 2),
          paint,
        );
      }

      // Right symmetrical bars
      final rightX = center.dx + centerOffset + (i * barSpacing);
      if (rightX < size.width - 16) {
        canvas.drawLine(
          Offset(rightX, center.dy - dynamicHeight / 2),
          Offset(rightX, center.dy + dynamicHeight / 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SymmetricalWaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.isActive != isActive;
  }
}

// ==========================================
// CUSTOM PAINTER: AGRICULTURAL CORNER CONTOURS
// ==========================================
class AgriculturalCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF168A3A).withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    // Bottom-Left subtle organic contour
    final pathLeft = Path();
    pathLeft.moveTo(0, size.height);
    pathLeft.lineTo(0, size.height - 110);
    pathLeft.quadraticBezierTo(
      size.width * 0.18,
      size.height - 90,
      size.width * 0.28,
      size.height,
    );
    pathLeft.close();
    canvas.drawPath(pathLeft, paint);

    // Bottom-Right subtle organic contour
    final pathRight = Path();
    pathRight.moveTo(size.width, size.height);
    pathRight.lineTo(size.width, size.height - 130);
    pathRight.quadraticBezierTo(
      size.width * 0.82,
      size.height - 100,
      size.width * 0.70,
      size.height,
    );
    pathRight.close();
    canvas.drawPath(pathRight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
