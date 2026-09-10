/// Model representing a government procurement centre.
class ProcurementCentre {
  final String id;
  final String name;
  final String subLocation;
  final String status;
  final bool isNormal;
  final String distance;
  final double distanceKm;
  final String queueStatus;
  final String queueEstimate;
  final int todayQueueCount;
  final int estimatedWaitMinutes;
  final int capacity;
  final int processingRatePerHour;

  const ProcurementCentre({
    required this.id,
    required this.name,
    required this.subLocation,
    required this.status,
    required this.isNormal,
    required this.distance,
    required this.distanceKm,
    required this.queueStatus,
    required this.queueEstimate,
    required this.todayQueueCount,
    required this.estimatedWaitMinutes,
    required this.capacity,
    required this.processingRatePerHour,
  });

  ProcurementCentre copyWith({
    String? id,
    String? name,
    String? subLocation,
    String? status,
    bool? isNormal,
    String? distance,
    double? distanceKm,
    String? queueStatus,
    String? queueEstimate,
    int? todayQueueCount,
    int? estimatedWaitMinutes,
    int? capacity,
    int? processingRatePerHour,
  }) {
    return ProcurementCentre(
      id: id ?? this.id,
      name: name ?? this.name,
      subLocation: subLocation ?? this.subLocation,
      status: status ?? this.status,
      isNormal: isNormal ?? this.isNormal,
      distance: distance ?? this.distance,
      distanceKm: distanceKm ?? this.distanceKm,
      queueStatus: queueStatus ?? this.queueStatus,
      queueEstimate: queueEstimate ?? this.queueEstimate,
      todayQueueCount: todayQueueCount ?? this.todayQueueCount,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      capacity: capacity ?? this.capacity,
      processingRatePerHour: processingRatePerHour ?? this.processingRatePerHour,
    );
  }

  static List<ProcurementCentre> getMockCentres() {
    return const [
      ProcurementCentre(
        id: 'centre_1',
        name: 'Example Procurement Centre',
        subLocation: 'Mandi Samiti, Block A',
        status: 'Open • Normal',
        isNormal: true,
        distance: '4.2 km',
        distanceKm: 4.2,
        queueStatus: 'Low',
        queueEstimate: 'est. 15-20 min',
        todayQueueCount: 12,
        estimatedWaitMinutes: 20,
        capacity: 100,
        processingRatePerHour: 15,
      ),
      ProcurementCentre(
        id: 'centre_2',
        name: 'Nearby Procurement Centre',
        subLocation: 'Rural Warehouse #3',
        status: 'Open • Normal',
        isNormal: true,
        distance: '5.0 km',
        distanceKm: 5.0,
        queueStatus: 'Moderate',
        queueEstimate: 'est. 20 min',
        todayQueueCount: 14,
        estimatedWaitMinutes: 20,
        capacity: 90,
        processingRatePerHour: 12,
      ),
      ProcurementCentre(
        id: 'centre_3',
        name: 'APMC Hub North',
        subLocation: 'APMC Sector 9 Yard',
        status: 'Open • Normal',
        isNormal: true,
        distance: '8.5 km',
        distanceKm: 8.5,
        queueStatus: 'Low',
        queueEstimate: 'est. 15 min',
        todayQueueCount: 8,
        estimatedWaitMinutes: 15,
        capacity: 120,
        processingRatePerHour: 18,
      ),
      ProcurementCentre(
        id: 'centre_4',
        name: 'Regional Grain Silo',
        subLocation: 'State Warehouse Complex',
        status: 'Open • Normal',
        isNormal: true,
        distance: '11.2 km',
        distanceKm: 11.2,
        queueStatus: 'Low',
        queueEstimate: 'est. 25 min',
        todayQueueCount: 16,
        estimatedWaitMinutes: 25,
        capacity: 150,
        processingRatePerHour: 20,
      ),
      ProcurementCentre(
        id: 'centre_5',
        name: 'Cooperative Depot West',
        subLocation: 'Kisan Bhawan Road',
        status: 'Open • Normal',
        isNormal: true,
        distance: '14.0 km',
        distanceKm: 14.0,
        queueStatus: 'Moderate',
        queueEstimate: 'est. 30 min',
        todayQueueCount: 22,
        estimatedWaitMinutes: 30,
        capacity: 110,
        processingRatePerHour: 14,
      ),
    ];
  }
}
