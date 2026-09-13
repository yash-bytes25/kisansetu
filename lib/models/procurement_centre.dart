import '../services/location_distance_service.dart';

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

  // Extended Location & Operational Attributes
  final String state;
  final String district;
  final String mandal;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? operatingStatus;
  final int? currentLoadPercent;
  final int? availableSlotsCount;
  final List<String> supportedCrops;

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
    this.state = 'Punjab',
    this.district = 'Ludhiana',
    this.mandal = 'Khanna',
    this.address,
    this.latitude,
    this.longitude,
    this.operatingStatus,
    this.currentLoadPercent,
    this.availableSlotsCount = 10,
    this.supportedCrops = const ['Wheat', 'Paddy (Rice)', 'Mustard', 'Cotton'],
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
    String? state,
    String? district,
    String? mandal,
    String? address,
    double? latitude,
    double? longitude,
    String? operatingStatus,
    int? currentLoadPercent,
    int? availableSlotsCount,
    List<String>? supportedCrops,
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
      state: state ?? this.state,
      district: district ?? this.district,
      mandal: mandal ?? this.mandal,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      operatingStatus: operatingStatus ?? this.operatingStatus,
      currentLoadPercent: currentLoadPercent ?? this.currentLoadPercent,
      availableSlotsCount: availableSlotsCount ?? this.availableSlotsCount,
      supportedCrops: supportedCrops ?? this.supportedCrops,
    );
  }

  /// Whether this centre is actively operational (not stopped or unavailable).
  bool get isOperational {
    final s = (operatingStatus ?? status).toLowerCase();
    return !s.contains('stopped') &&
        !s.contains('closed') &&
        !s.contains('unavailable') &&
        !s.contains('maintenance');
  }

  /// Calculates real-time distance in km to this centre using Haversine formula.
  double? calculateDistanceKmFrom(double? farmerLat, double? farmerLng) {
    if (farmerLat == null || farmerLng == null || latitude == null || longitude == null) {
      return null;
    }
    return LocationDistanceService.calculateHaversineDistanceKm(
      farmerLat,
      farmerLng,
      latitude!,
      longitude!,
    );
  }

  /// Intelligent recommendation comparator:
  /// 1. Operating/open status (open/normal first)
  /// 2. Lower estimated waiting time (ascending)
  /// 3. Available slots (descending)
  /// 4. Lower centre load/congestion (ascending)
  /// 5. Shorter distance (ascending)
  static int compareRecommendation(
    ProcurementCentre a,
    ProcurementCentre b, {
    double? farmerLat,
    double? farmerLng,
  }) {
    // 1. Operating/open status
    final aOpen = a.isNormal || a.status.toLowerCase().contains('open');
    final bOpen = b.isNormal || b.status.toLowerCase().contains('open');
    if (aOpen != bOpen) return aOpen ? -1 : 1;

    // 2. Lower estimated waiting time
    if (a.estimatedWaitMinutes != b.estimatedWaitMinutes) {
      return a.estimatedWaitMinutes.compareTo(b.estimatedWaitMinutes);
    }

    // 3. Available slots (more available slots preferred)
    final aSlots = a.availableSlotsCount ?? 0;
    final bSlots = b.availableSlotsCount ?? 0;
    if (aSlots != bSlots) {
      return bSlots.compareTo(aSlots);
    }

    // 4. Lower centre load / congestion
    final aLoad = a.currentLoadPercent ?? a.todayQueueCount;
    final bLoad = b.currentLoadPercent ?? b.todayQueueCount;
    if (aLoad != bLoad) {
      return aLoad.compareTo(bLoad);
    }

    // 5. Shorter distance
    final aDist = a.calculateDistanceKmFrom(farmerLat, farmerLng) ?? a.distanceKm;
    final bDist = b.calculateDistanceKmFrom(farmerLat, farmerLng) ?? b.distanceKm;
    return aDist.compareTo(bDist);
  }

  static List<ProcurementCentre> getMockCentres() {
    return const [
      ProcurementCentre(
        id: 'centre_1',
        name: 'Example Procurement Centre',
        subLocation: 'Mandi Samiti, Block A',
        address: 'Mandi Samiti, Block A, GT Road, Khanna',
        state: 'Punjab',
        district: 'Ludhiana',
        mandal: 'Khanna',
        latitude: 30.7050,
        longitude: 76.2217,
        status: 'Open • Normal',
        operatingStatus: 'Open • Normal',
        isNormal: true,
        distance: '4.2 km',
        distanceKm: 4.2,
        queueStatus: 'Low',
        queueEstimate: 'est. 15-20 min',
        todayQueueCount: 12,
        estimatedWaitMinutes: 20,
        capacity: 100,
        processingRatePerHour: 15,
        currentLoadPercent: 40,
        availableSlotsCount: 12,
      ),
      ProcurementCentre(
        id: 'centre_2',
        name: 'Nearby Procurement Centre',
        subLocation: 'Rural Warehouse #3',
        address: 'Rural Warehouse #3, Rahon Road, Khanna',
        state: 'Punjab',
        district: 'Ludhiana',
        mandal: 'Khanna',
        latitude: 30.7250,
        longitude: 76.2400,
        status: 'Open • Normal',
        operatingStatus: 'Open • Normal',
        isNormal: true,
        distance: '5.0 km',
        distanceKm: 5.0,
        queueStatus: 'Moderate',
        queueEstimate: 'est. 20 min',
        todayQueueCount: 14,
        estimatedWaitMinutes: 20,
        capacity: 90,
        processingRatePerHour: 12,
        currentLoadPercent: 65,
        availableSlotsCount: 8,
      ),
      ProcurementCentre(
        id: 'centre_3',
        name: 'APMC Hub North',
        subLocation: 'APMC Sector 9 Yard',
        address: 'APMC Sector 9 Yard, Ludhiana East',
        state: 'Punjab',
        district: 'Ludhiana',
        mandal: 'Ludhiana East',
        latitude: 30.7400,
        longitude: 76.2600,
        status: 'Open • Normal',
        operatingStatus: 'Open • Normal',
        isNormal: true,
        distance: '8.5 km',
        distanceKm: 8.5,
        queueStatus: 'Low',
        queueEstimate: 'est. 15 min',
        todayQueueCount: 8,
        estimatedWaitMinutes: 15,
        capacity: 120,
        processingRatePerHour: 18,
        currentLoadPercent: 35,
        availableSlotsCount: 15,
      ),
      ProcurementCentre(
        id: 'centre_4',
        name: 'Regional Grain Silo',
        subLocation: 'State Warehouse Complex',
        address: 'State Warehouse Complex, Samrala',
        state: 'Punjab',
        district: 'Ludhiana',
        mandal: 'Samrala',
        latitude: 30.8333,
        longitude: 76.1833,
        status: 'Open • Normal',
        operatingStatus: 'Open • Normal',
        isNormal: true,
        distance: '11.2 km',
        distanceKm: 11.2,
        queueStatus: 'Low',
        queueEstimate: 'est. 25 min',
        todayQueueCount: 16,
        estimatedWaitMinutes: 25,
        capacity: 150,
        processingRatePerHour: 20,
        currentLoadPercent: 50,
        availableSlotsCount: 10,
      ),
      ProcurementCentre(
        id: 'centre_5',
        name: 'Cooperative Depot West',
        subLocation: 'Kisan Bhawan Road',
        address: 'Kisan Bhawan Road, Nabha, Patiala',
        state: 'Punjab',
        district: 'Patiala',
        mandal: 'Nabha',
        latitude: 30.3700,
        longitude: 76.1500,
        status: 'Open • Normal',
        operatingStatus: 'Open • Normal',
        isNormal: true,
        distance: '14.0 km',
        distanceKm: 14.0,
        queueStatus: 'Moderate',
        queueEstimate: 'est. 30 min',
        todayQueueCount: 22,
        estimatedWaitMinutes: 30,
        capacity: 110,
        processingRatePerHour: 14,
        currentLoadPercent: 70,
        availableSlotsCount: 6,
      ),
      ProcurementCentre(
        id: 'centre_6',
        name: 'Telangana Agro Hub',
        subLocation: 'Market Yard Gate 2',
        address: 'Market Yard Gate 2, Rajendranagar',
        state: 'Telangana',
        district: 'Rangareddy',
        mandal: 'Rajendranagar',
        latitude: 17.3180,
        longitude: 78.4060,
        status: 'Open • Normal',
        operatingStatus: 'Open • Normal',
        isNormal: true,
        distance: '6.5 km',
        distanceKm: 6.5,
        queueStatus: 'Low',
        queueEstimate: 'est. 15 min',
        todayQueueCount: 10,
        estimatedWaitMinutes: 15,
        capacity: 140,
        processingRatePerHour: 18,
        currentLoadPercent: 30,
        availableSlotsCount: 16,
      ),
      ProcurementCentre(
        id: 'centre_7',
        name: 'Karnal Mandi Samiti',
        subLocation: 'Grain Market Complex',
        address: 'Grain Market Complex, Karnal',
        state: 'Haryana',
        district: 'Karnal',
        mandal: 'Karnal',
        latitude: 29.6857,
        longitude: 76.9905,
        status: 'Open • Normal',
        operatingStatus: 'Open • Normal',
        isNormal: true,
        distance: '3.8 km',
        distanceKm: 3.8,
        queueStatus: 'Low',
        queueEstimate: 'est. 20 min',
        todayQueueCount: 15,
        estimatedWaitMinutes: 20,
        capacity: 130,
        processingRatePerHour: 16,
        currentLoadPercent: 45,
        availableSlotsCount: 11,
      ),
    ];
  }
}

