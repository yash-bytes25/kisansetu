/// Model representing an immutable historical weighment adjustment audit record.
class WeighmentAuditEntry {
  final String id;
  final String tokenNumber;
  final String farmerName;
  final String crop;
  final double originalWeight;
  final double updatedWeight;
  final String changedBy;
  final DateTime changedAt;
  final String reason;

  const WeighmentAuditEntry({
    required this.id,
    required this.tokenNumber,
    required this.farmerName,
    required this.crop,
    required this.originalWeight,
    required this.updatedWeight,
    required this.changedBy,
    required this.changedAt,
    required this.reason,
  });

  /// Difference in Quintals: updatedWeight - originalWeight.
  double get difference => updatedWeight - originalWeight;

  /// Discrepancy percentage: ((updated - original) / original) * 100.
  double get differencePercentage => originalWeight > 0
      ? ((updatedWeight - originalWeight) / originalWeight) * 100
      : 0.0;

  /// Formatted date string (e.g. 09 Sep 2026, 11:30 AM).
  String get formattedDateTime {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = changedAt.day.toString().padLeft(2, '0');
    final m = months[changedAt.month - 1];
    final y = changedAt.year;
    final hour = changedAt.hour > 12 ? changedAt.hour - 12 : (changedAt.hour == 0 ? 12 : changedAt.hour);
    final min = changedAt.minute.toString().padLeft(2, '0');
    final ampm = changedAt.hour >= 12 ? 'PM' : 'AM';
    return '$d $m $y, $hour:$min $ampm';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'token_number': tokenNumber,
      'farmer_name': farmerName,
      'crop': crop,
      'original_weight': originalWeight,
      'updated_weight': updatedWeight,
      'changed_by': changedBy,
      'changed_at': changedAt.toIso8601String(),
      'reason': reason,
    };
  }

  factory WeighmentAuditEntry.fromMap(Map<String, dynamic> map) {
    return WeighmentAuditEntry(
      id: map['id']?.toString() ?? 'AUD-${DateTime.now().millisecondsSinceEpoch}',
      tokenNumber: map['token_number']?.toString() ?? map['booking_id']?.toString() ?? 'TK-8492',
      farmerName: map['farmer_name']?.toString() ?? 'Ramesh Kumar',
      crop: map['crop']?.toString() ?? 'Wheat',
      originalWeight: (map['original_weight'] as num?)?.toDouble() ?? (map['previous_weight'] as num?)?.toDouble() ?? 50.0,
      updatedWeight: (map['updated_weight'] as num?)?.toDouble() ?? (map['actual_quantity'] as num?)?.toDouble() ?? 50.2,
      changedBy: map['changed_by']?.toString() ?? 'OFF-101',
      changedAt: DateTime.tryParse(map['changed_at']?.toString() ?? map['weight_changed_at']?.toString() ?? '') ?? DateTime.now(),
      reason: map['reason']?.toString() ?? map['officer_notes']?.toString() ?? 'Scale correction',
    );
  }
}
