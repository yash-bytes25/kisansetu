import 'package:flutter/material.dart';
import '../models/alternative_centre_recommendation.dart';
import '../services/connectivity_service.dart';
import '../services/procurement_state_service.dart';

/// Screen allowing a farmer to browse, compare, and switch to alternative procurement centres
/// when their current centre is overloaded, delayed, or temporarily paused.
class FarmerAlternativeCentresScreen extends StatefulWidget {
  final bool isHindi;
  final bool isTelugu;

  const FarmerAlternativeCentresScreen({
    super.key,
    this.isHindi = false,
    this.isTelugu = false,
  });

  @override
  State<FarmerAlternativeCentresScreen> createState() =>
      _FarmerAlternativeCentresScreenState();
}

class _FarmerAlternativeCentresScreenState
    extends State<FarmerAlternativeCentresScreen> {
  AlternativeCentreRecommendation? _selectedRecommendation;

  @override
  Widget build(BuildContext context) {
    final state = ProcurementStateService();
    final currentCentre = state.centreName;
    final currentStatus = state.centreStatus;
    final currentDelay = state.centreDelayMinutes;
    final currentWait = state.farmerData.expectedWaitMinutes;
    final currentLoad = state.centreCapacityPercent;
    final alternatives = state.alternativeCentres;
    final crop = state.farmerData.cropName;
    final quantity = state.farmerData.quantity;

    final isHindi = widget.isHindi;
    final isTelugu = widget.isTelugu;

    final title = isTelugu
        ? 'ప్రత్యామ్నాయ సేకరణ కేంద్రాలు'
        : isHindi
            ? 'वैकल्पिक खरीद केंद्र'
            : 'Alternative Procurement Centres';

    final subtitle = isTelugu
        ? 'మీ కేంద్రంలో ఆలస్యం లేదా రద్దీ ఉంది. తక్కువ నిరీక్షణ సమయం ఉన్న సమీప కేంద్రాన్ని ఎంచుకోండి.'
        : isHindi
            ? 'आपके केंद्र में देरी या भीड़ है। कम प्रतीक्षा समय वाले नजदीकी केंद्र का चयन करें।'
            : 'Your current centre has high wait time or delays. Choose a nearby centre with faster processing.';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE65100),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isTelugu
                                ? 'ప్రస్తుత కేంద్ర స్థితి'
                                : isHindi
                                    ? 'वर्तमान केंद्र की स्थिति'
                                    : 'Current Centre Status',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$currentCentre • $currentStatus',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTelugu
                          ? 'నిరీక్షణ: $currentWait నిమిషాలు • లోడ్: $currentLoad% • అదనపు ఆలస్యం: $currentDelay నిమిషాలు'
                          : isHindi
                              ? 'प्रतीक्षा: $currentWait मिनट • लोड: $currentLoad% • अतिरिक्त देरी: $currentDelay मिनट'
                              : 'Wait: $currentWait min • Load: $currentLoad% • Extra delay: $currentDelay min',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF546E7A),
                      ),
                    ),
                    if (crop.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        isTelugu
                            ? 'ఎంచుకున్న పంట: $crop ($quantity)'
                            : isHindi
                                ? 'चयनित फसल: $crop ($quantity)'
                                : 'Selected Produce: $crop ($quantity)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Recommendations Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTelugu
                        ? 'సిఫార్సు చేయబడిన సమీప కేంద్రాలు'
                        : isHindi
                            ? 'सिफारिश किए गए नजदीकी केंद्र'
                            : 'Recommended Nearby Centres',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${alternatives.length} ${isTelugu ? 'ఎంపికలు' : isHindi ? 'विकल्प' : 'options'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (alternatives.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      isTelugu
                          ? 'సమీపంలో ప్రత్యామ్నాయ కేంద్రాలు అందుబాటులో లేవు.'
                          : isHindi
                              ? 'आस-पास कोई वैकल्पिक केंद्र उपलब्ध नहीं है।'
                              : 'No alternative centres available nearby at this time.',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...alternatives.map((rec) => _buildCentreCard(
                      context,
                      rec,
                      isHindi: isHindi,
                      isTelugu: isTelugu,
                    )),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCentreCard(
    BuildContext context,
    AlternativeCentreRecommendation rec, {
    required bool isHindi,
    required bool isTelugu,
  }) {
    final centre = rec.centre;
    final isSelected = _selectedRecommendation?.centre.id == centre.id;
    final isTop = rec.isTopPick;

    return Card(
      key: Key('centre_card_${centre.id}'),
      margin: const EdgeInsets.only(bottom: 14),
      elevation: isSelected ? 4 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF2E7D32)
              : isTop
                  ? const Color(0xFF66BB6A)
                  : Colors.grey.shade300,
          width: isSelected ? 2.2 : (isTop ? 1.5 : 1),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _selectedRecommendation = rec;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title + Top Pick Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          centre.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          centre.subLocation,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isTop)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isTelugu
                            ? 'ఉత్తమ ఎంపిక'
                            : isHindi
                                ? 'शीर्ष विकल्प'
                                : 'Top Pick',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Metrics Row: Distance | Wait Time | Load | Status
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _metricPill(
                    icon: Icons.navigation_outlined,
                    label: '${rec.distanceKm.toStringAsFixed(1)} km',
                    color: const Color(0xFF1565C0),
                  ),
                  _metricPill(
                    icon: Icons.access_time_rounded,
                    label: '${rec.estimatedWaitMinutes} min wait',
                    color: rec.estimatedWaitMinutes <= 20
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                  _metricPill(
                    icon: Icons.pie_chart_outline_rounded,
                    label: '${rec.capacityPercent}% load',
                    color: rec.capacityPercent <= 60
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                  _metricPill(
                    icon: Icons.event_available_rounded,
                    label: 'Slot: ${rec.nextAvailableSlot}',
                    color: const Color(0xFF4527A0),
                  ),
                  _metricPill(
                    icon: Icons.circle,
                    label: rec.operatingStatus,
                    color: rec.operatingStatus == 'Open'
                        ? const Color(0xFF2E7D32)
                        : Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Highlighted Reason Box
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rec.localizedReason(isHindi: isHindi, isTelugu: isTelugu),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF33691E),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: Key('btn_select_centre_${centre.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    isTelugu
                        ? 'ఈ కేంద్రానికి మారండి'
                        : isHindi
                            ? 'इस केंद्र पर जाएं'
                            : 'Select This Centre',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    _showConfirmationDialog(
                      context,
                      rec,
                      isHindi: isHindi,
                      isTelugu: isTelugu,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    AlternativeCentreRecommendation rec, {
    required bool isHindi,
    required bool isTelugu,
  }) {
    final state = ProcurementStateService();
    final oldCentre = state.centreName;
    final newCentre = rec.centre.name;
    final newSlot = rec.nextAvailableSlot;

    final dialogTitle = isTelugu
        ? 'కేంద్రం మార్పు ధృవీకరణ'
        : isHindi
            ? 'केंद्र परिवर्तन की पुष्टि'
            : 'Confirm Centre Switch';

    final message = isTelugu
        ? 'మీరు మీ బుకింగ్‌ను "$oldCentre" నుండి "$newCentre" కు మార్చాలనుకుంటున్నారా?\nకొత్త స్లాట్: $newSlot'
        : isHindi
            ? 'क्या आप अपनी बुकिंग "$oldCentre" से बदलकर "$newCentre" करना चाहते हैं?\nनया स्लॉट: $newSlot'
            : 'Are you sure you want to transfer your booking from "$oldCentre" to "$newCentre"?\nNew Slot: $newSlot';

    final confirmBtn = isTelugu
        ? 'ధృవీకరించండి'
        : isHindi
            ? 'पुष्टि करें'
            : 'Confirm Switch';

    final cancelBtn = isTelugu
        ? 'రద్దు చేయండి'
        : isHindi
            ? 'रद्द करें'
            : 'Cancel';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded,
                color: Color(0xFF2E7D32), size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dialogTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ${rec.distanceKm.toStringAsFixed(1)} km | ~${rec.estimatedWaitMinutes} min wait',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '• ${isTelugu ? 'QR కోడ్ మరియు టోకెన్ కొత్త కేంద్రం కోసం స్వయంచాలకంగా చెల్లుబాటు అవుతాయి.' : isHindi ? 'क्यूआर कोड और टोकन नए केंद्र के लिए मान्य रहेंगे।' : 'QR pass and token will automatically update for check-in.'}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(cancelBtn,
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_centre_switch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (!AppConnectivityService.instance.isOnline) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isTelugu
                          ? 'ఆఫ్‌లైన్‌లో ఉన్నప్పుడు కేంద్రాన్ని మార్చడం సాధ్యం కాదు.'
                          : (isHindi
                              ? 'ऑफ़लाइन होने पर केंद्र बदलना संभव नहीं है।'
                              : 'Centre switching is blocked while offline. Please connect to the internet.'),
                    ),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
                return;
              }
              Navigator.of(dialogCtx).pop();

              // Explicitly perform switch upon farmer confirmation
              state.switchFarmerProcurementCentre(
                newCentre: rec.centre,
                newSlot: newSlot,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isTelugu
                        ? 'సేకరణ కేంద్రం $newCentre కు విజయవంతంగా మార్చబడింది!'
                        : isHindi
                            ? 'खरीद केंद्र सफलतापूर्वक $newCentre में बदल दिया गया!'
                            : 'Procurement centre successfully changed to $newCentre!',
                  ),
                  backgroundColor: const Color(0xFF1B5E20),
                  duration: const Duration(seconds: 3),
                ),
              );

              // Navigate back to dashboard
              Navigator.of(context).pop();
            },
            child: Text(confirmBtn,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
