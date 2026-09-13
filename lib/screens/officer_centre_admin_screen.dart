import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/procurement_state_service.dart';
import '../services/repositories/repository_provider.dart';
import '../theme/app_colors.dart';

/// Phase E: KisanSetu Procurement Centre Administration & Status Control Screen.
///
/// Designed with INFORMATION → DECIDE → CONTROL philosophy:
/// - Authoritative display of assigned centre location, geographic coordinates, and operational parameters.
/// - Status control: Normal / Open, Delayed, Temporarily Stopped.
/// - Explicit safety confirmation before setting "Temporarily Stopped" to safeguard farmer arrival slots.
/// - Authorized adjustment of Capacity (Qtl/day), Processing Rate (Qtl/hour), and Delay (minutes).
/// - Enforces strict officer-to-centre authorization boundary: modifications flow through repositories and state services.
class OfficerCentreAdminScreen extends StatefulWidget {
  final String officerId;
  final String? centreId;

  const OfficerCentreAdminScreen({
    super.key,
    required this.officerId,
    this.centreId,
  });

  @override
  State<OfficerCentreAdminScreen> createState() =>
      _OfficerCentreAdminScreenState();
}

class _OfficerCentreAdminScreenState extends State<OfficerCentreAdminScreen> {
  final _service = ProcurementStateService();
  late int _capacity;
  late int _processingRate;
  late int _delayMinutes;
  late String _selectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _capacity = _service.centreCapacity;
    _processingRate = _service.configuredProcessingRate;
    _delayMinutes = _service.centreDelayMinutes;
    _selectedStatus = _service.centreStatus;
    _service.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  bool get _isAuthorized {
    final assignedCentre = AuthService.instance.currentCentreId ??
        '11111111-1111-1111-1111-111111111111';
    final target = widget.centreId ?? assignedCentre;
    return target == assignedCentre;
  }

  Future<void> _handleStatusChange(String newStatus) async {
    if (!_isAuthorized) {
      _showUnauthorizedWarning();
      return;
    }

    if (newStatus == 'Temporarily Stopped' || newStatus.contains('Stopped')) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text('Confirm Centre Suspension',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: const Text(
            'Stopping this centre may affect upcoming farmer arrivals and slots.\n\nFarmer Go-Time will immediately advise farmers to hold departure or divert to alternative nearby centres.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Stop Centre Operations'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() {
      _selectedStatus = newStatus;
    });

    _service.setCentreStatus(newStatus);

    final targetId = widget.centreId ??
        AuthService.instance.currentCentreId ??
        '11111111-1111-1111-1111-111111111111';

    await RepositoryProvider.centre.updateCentreOperations(
      centreId: targetId,
      operatingStatus: newStatus,
      delayMinutes: _delayMinutes,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Centre operating status updated to "$newStatus".'),
          backgroundColor: newStatus.contains('Stopped')
              ? AppColors.error
              : AppColors.primaryGreen,
        ),
      );
    }
  }

  Future<void> _saveOperationalParameters() async {
    if (!_isAuthorized) {
      _showUnauthorizedWarning();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final targetId = widget.centreId ??
        AuthService.instance.currentCentreId ??
        '11111111-1111-1111-1111-111111111111';

    await RepositoryProvider.centre.updateCentreOperations(
      centreId: targetId,
      capacity: _capacity,
      processingRatePerHour: _processingRate,
      delayMinutes: _delayMinutes,
      operatingStatus: _selectedStatus,
    );

    _service.updateCentreParameters(
      capacity: _capacity,
      processingRatePerHour: _processingRate,
      delayMinutes: _delayMinutes,
      operatingStatus: _selectedStatus,
    );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Centre parameters updated. Queue intelligence and Farmer Go-Time recalculated.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }
  }

  void _showUnauthorizedWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Authorization Denied: You are only permitted to configure your assigned procurement centre.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignedCentreId = widget.centreId ??
        AuthService.instance.currentCentreId ??
        '11111111-1111-1111-1111-111111111111';

    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Dashboard',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Procurement Centre Administration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gpp_bad_rounded,
                    size: 56, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'Access Restricted',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You are not authorized to configure operations for this procurement centre. Centre administrators and officers may only manage their officially assigned centre.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Return to Assigned Centre'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Dashboard',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: AppColors.secondary, size: 22),
            SizedBox(width: 8),
            Text(
              'Procurement Centre Administration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.cardBorder, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Officer Authorization Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isAuthorized
                    ? AppColors.primaryContainer.withValues(alpha: 0.4)
                    : AppColors.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isAuthorized
                      ? AppColors.primaryGreen.withValues(alpha: 0.4)
                      : AppColors.error,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAuthorized
                        ? Icons.verified_user_rounded
                        : Icons.gpp_bad_rounded,
                    color: _isAuthorized
                        ? AppColors.primaryGreen
                        : AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAuthorized
                              ? 'Authorized Officer: ${widget.officerId}'
                              : 'UNAUTHORIZED ACCESS ATTEMPT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _isAuthorized
                                ? AppColors.textPrimary
                                : AppColors.error,
                          ),
                        ),
                        Text(
                          _isAuthorized
                              ? 'Assigned Centre Scope: ${_service.centreName} ($assignedCentreId)'
                              : 'Officer ${widget.officerId} is not assigned to centre $assignedCentreId.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Location & Identity Card (Requirement 12)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: AppColors.secondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Centre Location & Geolocation',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildLocationGrid(),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Operating Status Segmented Control (Requirement 10)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.power_settings_new_rounded,
                          color: AppColors.secondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Operating Status & Operational Controls',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildStatusOption(
                        title: 'Normal / Open',
                        desc: 'Dock operations active & intake normal',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.primaryGreen,
                        value: 'Open • Normal',
                      ),
                      _buildStatusOption(
                        title: 'Delayed',
                        desc: 'Heavy traffic or slow dock clearance',
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.warning,
                        value: 'Temporarily Delayed',
                      ),
                      _buildStatusOption(
                        title: 'Temporarily Stopped',
                        desc: 'Intake halted • Weather or maintenance',
                        icon: Icons.pause_circle_filled_rounded,
                        color: AppColors.error,
                        value: 'Temporarily Stopped',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Operational Parameters Sliders / Steppers (Requirement 9 & 11)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed_rounded,
                          color: AppColors.secondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Operational Parameters',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Parameter 1: Centre Daily Capacity
                  _buildStepperRow(
                    title: 'Daily Centre Capacity',
                    subtitle: 'Intake dock ceiling in Quintals / day',
                    value: '$_capacity Qtl',
                    onMinus: _capacity > 50
                        ? () => setState(() => _capacity -= 10)
                        : null,
                    onPlus: () => setState(() => _capacity += 10),
                  ),
                  const Divider(height: 24),

                  // Parameter 2: Processing Rate (Qtl / hour)
                  _buildStepperRow(
                    title: 'Processing Rate (Qtl/hr)',
                    subtitle: 'Weighment & intake rate per hour',
                    value: '$_processingRate Qtl/hr',
                    onMinus: _processingRate > 5
                        ? () => setState(() => _processingRate -= 1)
                        : null,
                    onPlus: () => setState(() => _processingRate += 1),
                  ),
                  const Divider(height: 24),

                  // Parameter 3: Delay Minutes
                  _buildStepperRow(
                    title: 'Dock Delay (min)',
                    subtitle: 'Operational delay added to farmer wait estimates',
                    value: '$_delayMinutes min',
                    onMinus: _delayMinutes > 0
                        ? () => setState(
                            () => _delayMinutes = (_delayMinutes - 5).clamp(0, 120))
                        : null,
                    onPlus: () => setState(
                        () => _delayMinutes = (_delayMinutes + 5).clamp(0, 120)),
                  ),
                  const Divider(height: 24),

                  // Current Load Readout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Capacity Utilization',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Derived from active bookings and waiting queue',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_service.centreCapacityPercent}% Load',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('btn_save_centre_operations'),
                      onPressed:
                          _isSaving ? null : _saveOperationalParameters,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isSaving
                            ? 'SAVING CONFIGURATION...'
                            : 'SAVE OPERATIONAL PARAMETERS',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildInfoTile('Centre Name', _service.centreName)),
            const SizedBox(width: 12),
            Expanded(child: _buildInfoTile('State:', 'Punjab')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildInfoTile('District:', 'Ludhiana')),
            const SizedBox(width: 12),
            Expanded(child: _buildInfoTile('Mandal:', 'Khanna')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                'Latitude:',
                '30.7050° N',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoTile(
                'Longitude:',
                '76.2217° E',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required String value,
  }) {
    final isSelected = _selectedStatus == value ||
        (_service.centreStatus.contains(title));

    return InkWell(
      onTap: () => _handleStatusChange(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperRow({
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              color: AppColors.secondary,
              onPressed: onMinus,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: AppColors.secondary,
              onPressed: onPlus,
            ),
          ],
        ),
      ],
    );
  }
}
