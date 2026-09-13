import 'dart:math' as math;

/// Geographic coordinates representing farmer or procurement centre location.
class FarmerCoordinates {
  final double latitude;
  final double longitude;

  const FarmerCoordinates({
    required this.latitude,
    required this.longitude,
  });
}

/// Location permission states.
enum LocationPermissionState {
  notRequested,
  granted,
  denied,
}

/// Service managing device location permission and Haversine distance calculation.
class LocationDistanceService {
  LocationDistanceService._();
  static final LocationDistanceService instance = LocationDistanceService._();

  LocationPermissionState _permissionState = LocationPermissionState.notRequested;
  FarmerCoordinates? _currentCoordinates;

  // Default representative coordinates for Punjab farmer (Khanna Kalan)
  static const FarmerCoordinates defaultPunjabCoordinates = FarmerCoordinates(
    latitude: 30.6900,
    longitude: 76.2100,
  );

  LocationPermissionState get permissionState => _permissionState;
  FarmerCoordinates? get currentCoordinates => _currentCoordinates;
  bool get hasLocation => _permissionState == LocationPermissionState.granted && _currentCoordinates != null;

  /// Request location access from farmer.
  Future<LocationPermissionState> requestLocationPermission({bool grant = true}) async {
    if (grant) {
      _permissionState = LocationPermissionState.granted;
      _currentCoordinates ??= defaultPunjabCoordinates;
    } else {
      _permissionState = LocationPermissionState.denied;
      _currentCoordinates = null;
    }
    return _permissionState;
  }

  /// Sets permission and optional coordinates for testing and deterministic validation.
  void setPermissionForTest(LocationPermissionState state, {FarmerCoordinates? coords}) {
    _permissionState = state;
    if (state == LocationPermissionState.granted) {
      _currentCoordinates = coords ?? defaultPunjabCoordinates;
    } else {
      _currentCoordinates = null;
    }
  }

  /// Resets state for automated test runs.
  void resetForTest() {
    _permissionState = LocationPermissionState.notRequested;
    _currentCoordinates = null;
  }

  /// Standard Haversine formula calculating distance in kilometers between two coordinates.
  static double calculateHaversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Returns localized label for distance. Never exposes exact lat/long.
  static String formatDistanceLabel(
    double? distanceKm, {
    required bool isHindi,
    required bool isTelugu,
  }) {
    if (distanceKm == null) {
      if (isTelugu) {
        return 'దూరం అందుబాటులో లేదు — దూరాన్ని చూడటానికి లొకేషన్‌ను ప్రారంభించండి';
      }
      if (isHindi) {
        return 'दूरी अनुपलब्ध — दूरी देखने के लिए स्थान सक्षम करें';
      }
      return 'Distance unavailable — enable location to see distance';
    }

    final formatted = distanceKm.toStringAsFixed(1);
    if (isTelugu) {
      return 'మీ స్థానం నుండి $formatted కి.మీ.';
    }
    if (isHindi) {
      return 'आपके स्थान से $formatted किमी';
    }
    return '$formatted km from your location';
  }
}
