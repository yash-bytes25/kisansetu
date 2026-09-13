// KisanSetu (SIH26032) - Location Master Service
// Scales administrative boundaries nationwide (28 States + 8 UTs)
// Backed by structured India-wide administrative dataset.

import '../data/india_administrative_hierarchy_data.dart';

/// Administrative location entity for State, District, and Mandal hierarchy.
class LocationItem {
  final String id;
  final String nameEn;
  final String nameHi;
  final String nameTe;

  const LocationItem({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.nameTe,
  });

  String localizedName({required bool isHindi, required bool isTelugu}) {
    if (isTelugu) return nameTe;
    if (isHindi) return nameHi;
    return nameEn;
  }

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      id: json['id'] as String,
      nameEn: (json['name_en'] ?? json['nameEn'] ?? '') as String,
      nameHi: (json['name_hi'] ?? json['nameHi'] ?? '') as String,
      nameTe: (json['name_te'] ?? json['nameTe'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_en': nameEn,
    'name_hi': nameHi,
    'name_te': nameTe,
  };
}

/// Service providing master administrative boundaries for procurement centres.
class LocationMasterService {
  LocationMasterService._();
  static final LocationMasterService instance = LocationMasterService._();

  static List<LocationItem> get states => IndiaAdministrativeData.allStates;

  static Map<String, List<LocationItem>> get districtsByState =>
      IndiaAdministrativeData.districtsByState;

  static Map<String, List<LocationItem>> get mandalsByDistrict =>
      IndiaAdministrativeData.mandalsByDistrict;

  List<LocationItem> getStates() => states;

  List<LocationItem> getDistrictsForState(String stateIdOrName) {
    final matched = states.firstWhere(
      (s) =>
          s.id.toLowerCase() == stateIdOrName.toLowerCase() ||
          s.nameEn.toLowerCase() == stateIdOrName.toLowerCase(),
      orElse: () => states.first,
    );
    return districtsByState[matched.id] ?? [];
  }

  List<LocationItem> getMandalsForDistrict(String districtIdOrName, {String? stateIdOrName}) {
    if (stateIdOrName != null) {
      final matchedState = states.firstWhere(
        (s) =>
            s.id.toLowerCase() == stateIdOrName.toLowerCase() ||
            s.nameEn.toLowerCase() == stateIdOrName.toLowerCase(),
        orElse: () => states.first,
      );
      final dists = districtsByState[matchedState.id] ?? [];
      for (final dist in dists) {
        if (dist.id.toLowerCase() == districtIdOrName.toLowerCase() ||
            dist.nameEn.toLowerCase() == districtIdOrName.toLowerCase()) {
          return mandalsByDistrict[dist.id] ?? [];
        }
      }
    }

    for (final entry in districtsByState.entries) {
      for (final dist in entry.value) {
        if (dist.id.toLowerCase() == districtIdOrName.toLowerCase() ||
            dist.nameEn.toLowerCase() == districtIdOrName.toLowerCase()) {
          return mandalsByDistrict[dist.id] ?? [];
        }
      }
    }
    return mandalsByDistrict[districtIdOrName.toLowerCase()] ?? [];
  }
}
