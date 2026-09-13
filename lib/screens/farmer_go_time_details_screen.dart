import 'package:flutter/material.dart';
import '../models/farmer_dashboard_data.dart';
import '../services/procurement_state_service.dart';
import '../services/queue_prediction_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_alternative_centres_screen.dart';
import '../services/auth_service.dart';

/// Flagship decision-support screen detailing "When Should I Go?".
///
/// Features explainable calculations, live state listening,
/// journey timeline, and accessible trilingual guidance.
class FarmerGoTimeDetailsScreen extends StatefulWidget {
  final FarmerDashboardData data;
  final bool isHindi;
  final bool isTelugu;

  const FarmerGoTimeDetailsScreen({
    super.key,
    required this.data,
    required this.isHindi,
    this.isTelugu = false,
  });

  @override
  State<FarmerGoTimeDetailsScreen> createState() =>
      _FarmerGoTimeDetailsScreenState();
}

class _FarmerGoTimeDetailsScreenState extends State<FarmerGoTimeDetailsScreen> {
  bool get _isHindi => widget.isHindi;
  bool get _isTelugu => widget.isTelugu;

  late FarmerDashboardData _currentData;
  final _stateService = ProcurementStateService();

  @override
  void initState() {
    super.initState();
    _currentData = _stateService.farmerData;
    _stateService.addListener(_onStateUpdated);
  }

  @override
  void dispose() {
    _stateService.removeListener(_onStateUpdated);
    super.dispose();
  }

  void _onStateUpdated() {
    if (mounted) {
      setState(() {
        _currentData = _stateService.farmerData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _currentData;
    final rec = data.recommendation;

    Color bannerColor = AppColors.primaryContainer;
    Color iconColor = AppColors.primaryGreen;
    IconData recIcon = Icons.directions_walk_rounded;
    String recTitle;
    String recSubtitle;

    switch (rec) {
      case GoTimeRecommendation.centreTemporarilyStopped:
        bannerColor = AppColors.errorContainer;
        iconColor = AppColors.error;
        recIcon = Icons.pause_circle_filled_rounded;
        recTitle = _isTelugu
            ? 'సేకరణ నిలిపివేయబడింది'
            : (_isHindi
                ? 'खरीद प्रक्रिया रुकी हुई है'
                : 'PROCUREMENT STOPPED');
        recSubtitle = _isTelugu
            ? 'కేంద్రంలో సేవలు తాత్కాలికంగా ఆగాయి. దయచేసి ప్రయాణించవద్దు.'
            : (_isHindi
                ? 'केंद्र पर खरीद अस्थायी रूप से बंद है। कृपया अभी न निकलें।'
                : 'Do not travel yet. Processing is temporarily paused.');
        break;
      case GoTimeRecommendation.delay:
        bannerColor = AppColors.errorContainer;
        iconColor = Colors.deepOrange;
        recIcon = Icons.schedule_rounded;
        recTitle = _isTelugu
            ? 'కేంద్రం ఆలస్యమైంది'
            : (_isHindi ? 'केंद्र विलंबित है' : 'CENTRE DELAYED');
        recSubtitle = _isTelugu
            ? 'కొత్త ప్రయాణ సమయం: ${data.recommendedDepartureTime}'
            : (_isHindi
                ? 'नया प्रस्थान समय: ${data.recommendedDepartureTime}'
                : 'Updated departure: ${data.recommendedDepartureTime}');
        break;
      case GoTimeRecommendation.wait:
        bannerColor = AppColors.errorContainer;
        iconColor = AppColors.warning;
        recIcon = Icons.hourglass_top_rounded;
        recTitle = _isTelugu
            ? 'కాసేపు వేచి ఉండండి'
            : (_isHindi ? 'थोड़ा प्रतीक्षा करें' : 'WAIT A LITTLE');
        recSubtitle = _isTelugu
            ? 'కేంద్రంలో రద్దీగా ఉంది. సూచించిన రాక సమయం: ${data.waitRecommendedArrival}'
            : (_isHindi
                ? 'केंद्र व्यस्त है। अनुशंसित आगमन: ${data.waitRecommendedArrival}'
                : 'Centre is busy. Recommended arrival: ${data.waitRecommendedArrival}');
        break;
      case GoTimeRecommendation.slotApproaching:
        bannerColor = AppColors.primaryContainer;
        iconColor = AppColors.primaryGreen;
        recIcon = Icons.notifications_active_rounded;
        recTitle = _isTelugu
            ? 'స్లాట్ సమయం సమీపించింది'
            : (_isHindi ? 'स्लॉट निकट है' : 'SLOT APPROACHING');
        recSubtitle = _isTelugu
            ? 'గేట్ వద్దకు బయలుదేరండి: ${data.recommendedDepartureTime}'
            : (_isHindi
                ? 'गेट के लिए निकलें: ${data.recommendedDepartureTime}'
                : 'Leave for gate: ${data.recommendedDepartureTime}');
        break;
      case GoTimeRecommendation.checkInRequired:
        bannerColor = AppColors.primaryContainer;
        iconColor = AppColors.primaryGreen;
        recIcon = Icons.how_to_reg_rounded;
        recTitle = _isTelugu
            ? 'గేట్ వద్ద చెక్-ఇన్ చేయండి'
            : (_isHindi ? 'गेट पर चेक-इन करें' : 'CHECK-IN REQUIRED');
        recSubtitle = _isTelugu
            ? 'మీ టోకెన్ సిద్ధంగా ఉంది. గేట్ వద్ద డిజిటల్ QR పాస్ చూపించండి.'
            : (_isHindi
                ? 'गेट पर डिजिटल क्यूआर पास स्कैन करवाएं।'
                : 'Present your digital QR pass at the entrance gate.');
        break;
      case GoTimeRecommendation.goNow:
        bannerColor = AppColors.primaryContainer;
        iconColor = AppColors.primaryGreen;
        recIcon = Icons.directions_walk_rounded;
        recTitle = _isTelugu
            ? 'బయలుదేరడానికి మంచి సమయం'
            : (_isHindi ? 'निकलने का सही समय' : 'GOOD TIME TO LEAVE');
        recSubtitle = _isTelugu
            ? 'బయలుదేరండి: ${data.recommendedDepartureTime}'
            : (_isHindi
                ? 'प्रस्थान करें: ${data.recommendedDepartureTime}'
                : 'Leave at: ${data.recommendedDepartureTime}');
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isTelugu
              ? 'బయలుదేరే సమయ వివరాలు'
              : (_isHindi ? 'प्रस्थान समय विवरण' : 'Departure Details'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Dashboard',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Recommendation Banner Card
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: iconColor.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: bannerColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(recIcon, size: 32, color: iconColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recTitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: iconColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  recSubtitle,
                                  style: AppTextStyles.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _isTelugu
                            ? 'మీ సేకరణ వంతు సుమారు ${data.expectedTurnTime} వద్ద అంచనా వేయబడింది.'
                            : (_isHindi
                                ? 'आपकी खरीद की बारी लगभग ${data.expectedTurnTime} पर आएगी।'
                                : 'Your procurement turn is estimated around ${data.expectedTurnTime}.'),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Journey Timetable Step Sequence
              Text(
                _isTelugu
                    ? 'ప్రయాణ సమయ పట్టిక'
                    : (_isHindi ? 'यात्रा समय सारणी' : 'Journey Timetable'),
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 10),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTimelineItem(
                        icon: Icons.home_rounded,
                        time: data.recommendedDepartureTime,
                        title: _isTelugu
                            ? 'ఇంటి నుండి బయలుదేరండి'
                            : (_isHindi ? 'घर से प्रस्थान' : 'Depart from Home'),
                        subtitle: _isTelugu
                            ? 'ప్రయాణ సమయం సుమారు ${data.travelTimeMinutes} నిమిషాలు'
                            : (_isHindi
                                ? 'यात्रा समय लगभग ${data.travelTimeMinutes} मिनट'
                                : 'Estimated travel time: ${data.travelTimeMinutes} mins'),
                        isFirst: true,
                        isComplete: false,
                        isActive: true,
                      ),
                      _buildTimelineItem(
                        icon: Icons.login_rounded,
                        time: data.waitRecommendedArrival,
                        title: _isTelugu
                            ? 'సేకరణ కేంద్రం వద్దకు చేరుకోండి'
                            : (_isHindi ? 'केंद्र पर आगमन' : 'Arrive at Mandi Gate'),
                        subtitle: _isTelugu
                            ? 'గేట్ #2 వద్ద QR పాస్ స్కాన్ చేయించండి'
                            : (_isHindi
                                ? 'गेट नंबर 2 पर क्यूआर पास दिखाएं'
                                : 'Show digital QR pass at gate #2'),
                        isComplete: false,
                        isActive: false,
                      ),
                      _buildTimelineItem(
                        icon: Icons.how_to_reg_rounded,
                        time: data.expectedTurnTime,
                        title: _isTelugu
                            ? 'మీ సేకరణ వంతు / నాణ్యత తనిఖీ'
                            : (_isHindi ? 'आपकी बारी / जांच' : 'Procurement Turn'),
                        subtitle: _isTelugu
                            ? 'నమూనా సేకరణ మరియు ధర్మకాంటా తూకం'
                            : (_isHindi
                                ? 'सैंपलिंग एवं धर्मकांटा वजन'
                                : 'Sampling & weighment dock'),
                        isLast: true,
                        isComplete: false,
                        isActive: false,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Feature 7: "Why this recommendation?" Explainable factors & How is this calculated?
              Text(
                _isTelugu
                    ? 'ఈ సిఫార్సుకు కారణం ఏమిటి?'
                    : (_isHindi
                        ? 'यह सिफारिश क्यों की गई?'
                        : 'Why this recommendation?'),
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _isTelugu
                    ? 'ఎలా లెక్కించబడుతుంది? (How is this calculated?)'
                    : (_isHindi
                        ? 'यह गणना कैसे की जाती है? (How is this calculated?)'
                        : 'How is this calculated?'),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isTelugu
                    ? 'మీ సిఫార్సు ప్రస్తుత క్యూ, కేంద్రం లోడ్, సగటు ప్రాసెసింగ్ సమయం మరియు మీ ప్రయాణ సమయాన్ని పరిగణనలోకి తీసుకుంటుంది. Your recommendation considers the current queue, centre load, average processing rate, and your estimated travel time.'
                    : (_isHindi
                        ? 'आपकी सिफारिश वर्तमान कतार, केंद्र भार, औसत प्रसंस्करण दर और आपके अनुमानित यात्रा समय को ध्यान में रखती है। Your recommendation considers the current queue, centre load, average processing rate, and your estimated travel time.'
                        : 'Your recommendation considers the current queue, centre load, average processing rate, and your estimated travel time.'),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 10),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildFactorRow(
                        icon: Icons.people_outline_rounded,
                        label: _isTelugu
                            ? 'క్యూలో ముందున్న రైతులు'
                            : (_isHindi ? 'कतार में आगे किसान' : 'Farmers Ahead'),
                        value: '${data.peopleAhead} farmers',
                      ),
                      const Divider(height: 16),
                      _buildFactorRow(
                        icon: Icons.timer_outlined,
                        label: _isTelugu
                            ? 'సగటు ప్రాసెసింగ్ సమయం'
                            : (_isHindi ? 'औसत प्रसंस्करण समय' : 'Avg Processing Rate'),
                        value: '~${data.averageProcessingMinutes} min / farmer',
                      ),
                      const Divider(height: 16),
                      _buildFactorRow(
                        icon: Icons.info_outline_rounded,
                        label: _isTelugu
                            ? 'కేంద్రం పరిస్థితి'
                            : (_isHindi ? 'केंद्र स्थिति' : 'Operating Status'),
                        value: data.centreStatus,
                      ),
                      const Divider(height: 16),
                      _buildFactorRow(
                        icon: Icons.speed_rounded,
                        label: _isTelugu
                            ? 'కేంద్రం ప్రస్తుత లోడ్'
                            : (_isHindi ? 'वर्तमान केंद्र भार' : 'Centre Capacity Load'),
                        value: '${data.centreLoadPercentage}%',
                      ),
                      const Divider(height: 16),
                      _buildFactorRow(
                        icon: Icons.directions_car_outlined,
                        label: _isTelugu
                            ? 'అంచనా ప్రయాణ సమయం'
                            : (_isHindi ? 'अनुमानित यात्रा समय' : 'Estimated Travel Time'),
                        value: '${data.travelTimeMinutes} minutes',
                      ),
                      const Divider(height: 16),
                      _buildFactorRow(
                        icon: Icons.event_available_rounded,
                        label: _isTelugu
                            ? 'బుక్ చేసిన స్లాట్'
                            : (_isHindi ? 'बुक किया गया स्लॉट' : 'Booked Slot Time'),
                        value: data.bookedSlotTime ?? '11:30 AM',
                      ),
                      if (data.delayMinutes > 0) ...[
                        const Divider(height: 16),
                        _buildFactorRow(
                          icon: Icons.warning_amber_rounded,
                          label: _isTelugu
                              ? 'ప్రస్తుత కేంద్ర ఆలస్యం'
                              : (_isHindi ? 'वर्तमान केंद्र विलंब' : 'Active Centre Delay'),
                          value: '+${data.delayMinutes} minutes',
                          highlightColor: Colors.deepOrange,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. Queue Simulation Action (Strictly restricted to Officer in Demo Mode)
              if (AuthService.instance.isOfficer && AuthService.instance.isDemoMode) ...[
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _stateService.simulateNextQueueStep();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isTelugu
                                ? 'క్యూ అప్‌డేట్ చేయబడింది: ${_stateService.farmerData.peopleAhead} మంది ముందున్నారు'
                                : (_isHindi
                                    ? 'कतार अपडेट हुई: ${_stateService.farmerData.peopleAhead} लोग आगे हैं'
                                    : 'Queue advanced: ${_stateService.farmerData.peopleAhead} people ahead'),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fast_forward_rounded, size: 22),
                    label: Text(
                      _isTelugu
                          ? 'సిమ్యులేట్ క్యూ మార్పు (${data.peopleAhead} ముందు)'
                          : (_isHindi
                              ? 'कतार परिवर्तन सिमुलेट करें (${data.peopleAhead} आगे)'
                              : 'Simulate Queue Step (${data.peopleAhead} ahead)'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (data.recommendation == GoTimeRecommendation.delay ||
                  data.recommendation ==
                      GoTimeRecommendation.centreTemporarilyStopped ||
                  data.recommendation == GoTimeRecommendation.wait ||
                  data.centreLoadPercentage >= 85 ||
                  data.expectedWaitMinutes >= 45) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    key: const Key('btn_find_better_centre_details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => FarmerAlternativeCentresScreen(
                            isHindi: _isHindi,
                            isTelugu: _isTelugu,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 22),
                    label: Text(
                      _isTelugu
                          ? 'మంచి కేంద్రాన్ని కనుగొనండి (Find Better Centre)'
                          : (_isHindi
                              ? 'बेहतर केंद्र खोजें (Find Better Centre)'
                              : 'Find Better Centre (Nearby Alternatives)'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String time,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
    bool isComplete = false,
    bool isActive = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryGreen
                    : AppColors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGreen,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : AppColors.primaryGreen,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppColors.cardBorder,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.primaryGreen : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFactorRow({
    required IconData icon,
    required String label,
    required String value,
    Color? highlightColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: highlightColor ?? AppColors.primaryDark),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: highlightColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
