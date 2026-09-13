import 'package:flutter/material.dart';
import '../models/crop_model.dart';

/// Centralized crop catalogue service for KisanSetu.
///
/// Fully extensible and decoupled from UI components.
/// Supports search by English, Hindi, and Telugu names as well as category filtering.
class CropCatalogueService {
  static const CropCatalogueService instance = CropCatalogueService._();
  const CropCatalogueService._();

  /// The 10 primary selectable crops shown by default on the Select Crop screen:
  /// 1. Paddy (Rice)
  /// 2. Wheat
  /// 3. Maize (Corn)
  /// 4. Jowar (Sorghum)
  /// 5. Bajra (Pearl Millet)
  /// 6. Ragi (Finger Millet)
  /// 7. Red Gram (Tur / Arhar)
  /// 8. Green Gram (Moong)
  /// 9. Black Gram (Urad)
  /// 10. Bengal Gram (Chana)
  static const List<CropModel> default10Crops = [
    // 1. Wheat
    CropModel(
      cropId: 'wheat',
      cropName: 'Wheat',
      nameHi: 'गेहूं',
      nameTe: 'గోధుమలు',
      category: CropCategory.cereals,
      icon: Icons.grass_rounded,
      defaultQuantityQuintals: 50.0,
    ),
    // 2. Paddy (Rice)
    CropModel(
      cropId: 'paddy',
      cropName: 'Paddy (Rice)',
      nameHi: 'धान / चावल',
      nameTe: 'వరి / బియ్యం',
      category: CropCategory.cereals,
      icon: Icons.grain_rounded,
      defaultQuantityQuintals: 65.0,
    ),
    // 3. Maize (Corn)
    CropModel(
      cropId: 'maize',
      cropName: 'Maize (Corn)',
      nameHi: 'मक्का',
      nameTe: 'మొక్కజొన్న',
      category: CropCategory.cereals,
      icon: Icons.spa_rounded,
      defaultQuantityQuintals: 40.0,
    ),
    // 4. Jowar (Sorghum)
    CropModel(
      cropId: 'jowar',
      cropName: 'Jowar (Sorghum)',
      nameHi: 'ज्वार',
      nameTe: 'జొన్నలు',
      category: CropCategory.cereals,
      icon: Icons.eco_rounded,
      defaultQuantityQuintals: 35.0,
    ),
    // 5. Bajra (Pearl Millet)
    CropModel(
      cropId: 'bajra',
      cropName: 'Bajra (Pearl Millet)',
      nameHi: 'बाजरा',
      nameTe: 'సజ్జలు',
      category: CropCategory.cereals,
      icon: Icons.agriculture_rounded,
      defaultQuantityQuintals: 35.0,
    ),
    // 6. Ragi (Finger Millet)
    CropModel(
      cropId: 'ragi',
      cropName: 'Ragi (Finger Millet)',
      nameHi: 'रागी',
      nameTe: 'రాగులు',
      category: CropCategory.cereals,
      icon: Icons.grain_rounded,
      defaultQuantityQuintals: 25.0,
    ),
    // 7. Bengal Gram (Chana)
    CropModel(
      cropId: 'gram',
      cropName: 'Bengal Gram (Chana)',
      nameHi: 'चना',
      nameTe: 'శనగలు',
      category: CropCategory.pulses,
      icon: Icons.egg_alt_rounded,
      defaultQuantityQuintals: 30.0,
    ),
    // 8. Red Gram (Tur / Arhar)
    CropModel(
      cropId: 'tur',
      cropName: 'Red Gram (Tur / Arhar)',
      nameHi: 'तूर / अरहर',
      nameTe: 'కందులు',
      category: CropCategory.pulses,
      icon: Icons.circle_rounded,
      defaultQuantityQuintals: 25.0,
    ),
    // 9. Mustard
    CropModel(
      cropId: 'mustard',
      cropName: 'Mustard',
      nameHi: 'सरसों',
      nameTe: 'ఆవాలు',
      category: CropCategory.oilseeds,
      icon: Icons.flare_rounded,
      defaultQuantityQuintals: 30.0,
    ),
    // 10. Soybean
    CropModel(
      cropId: 'soybean',
      cropName: 'Soybean',
      nameHi: 'सोयाबीन',
      nameTe: 'సోయాబీన్',
      category: CropCategory.oilseeds,
      icon: Icons.filter_vintage_rounded,
      defaultQuantityQuintals: 45.0,
    ),
  ];

  /// Phase 23: The 10 prominent high-relevance crops:
  /// 1. Paddy / Rice
  /// 2. Maize
  /// 3. Red Gram / Tur
  /// 4. Green Gram / Moong
  /// 5. Black Gram / Urad
  /// 6. Wheat
  /// 7. Groundnut
  /// 8. Sunflower
  /// 9. Cotton
  /// 10. Sugarcane
  static List<CropModel> get prominent10Crops => [
        findById('paddy')!,
        findById('maize')!,
        findById('tur')!,
        findById('moong')!,
        findById('urad')!,
        findById('wheat')!,
        findById('groundnut')!,
        findById('sunflower')!,
        findById('cotton')!,
        findById('sugarcane')!,
      ];

  /// Phase 23: The remaining 13 crops from the 23-crop catalogue.
  static List<CropModel> get otherCrops {
    final prominentIds = prominent10Crops.map((c) => c.cropId).toSet();
    return allCrops.where((c) => !prominentIds.contains(c.cropId)).toList();
  }

  static const List<CropModel> allCrops = [
    // --- 10 Primary Crops ---
    ...default10Crops,

    // --- Additional Cereals (1) ---
    CropModel(
      cropId: 'barley',
      cropName: 'Barley',
      nameHi: 'जौ',
      nameTe: 'బార్లీ',
      category: CropCategory.cereals,
      icon: Icons.grass_rounded,
      defaultQuantityQuintals: 30.0,
    ),

    // --- Additional Pulses (4) ---
    CropModel(
      cropId: 'moong',
      cropName: 'Green Gram (Moong)',
      nameHi: 'मूंग',
      nameTe: 'పెసలు',
      category: CropCategory.pulses,
      icon: Icons.brightness_1_rounded,
      defaultQuantityQuintals: 20.0,
    ),
    CropModel(
      cropId: 'urad',
      cropName: 'Black Gram (Urad)',
      nameHi: 'उड़द',
      nameTe: 'మినుములు',
      category: CropCategory.pulses,
      icon: Icons.trip_origin_rounded,
      defaultQuantityQuintals: 20.0,
    ),
    CropModel(
      cropId: 'masoor',
      cropName: 'Masoor',
      nameHi: 'मसूर',
      nameTe: 'ఎర్ర కందులు',
      category: CropCategory.pulses,
      icon: Icons.circle_outlined,
      defaultQuantityQuintals: 20.0,
    ),
    CropModel(
      cropId: 'peas',
      cropName: 'Peas',
      nameHi: 'मटर',
      nameTe: 'బఠానీలు',
      category: CropCategory.pulses,
      icon: Icons.lens_rounded,
      defaultQuantityQuintals: 25.0,
    ),

    // --- Oilseeds (4) ---
    CropModel(
      cropId: 'groundnut',
      cropName: 'Groundnut',
      nameHi: 'मूंगफली',
      nameTe: 'వేరుశెనగ',
      category: CropCategory.oilseeds,
      icon: Icons.scatter_plot_rounded,
      defaultQuantityQuintals: 40.0,
    ),
    CropModel(
      cropId: 'sunflower',
      cropName: 'Sunflower',
      nameHi: 'सूरजमुखी',
      nameTe: 'పొద్దుతిరుగుడు',
      category: CropCategory.oilseeds,
      icon: Icons.wb_sunny_rounded,
      defaultQuantityQuintals: 25.0,
    ),
    CropModel(
      cropId: 'sesame',
      cropName: 'Sesame',
      nameHi: 'तिल',
      nameTe: 'నువ్వులు',
      category: CropCategory.oilseeds,
      icon: Icons.grain_rounded,
      defaultQuantityQuintals: 15.0,
    ),
    CropModel(
      cropId: 'safflower',
      cropName: 'Safflower',
      nameHi: 'कुसुम',
      nameTe: 'కుసుమ',
      category: CropCategory.oilseeds,
      icon: Icons.local_florist_rounded,
      defaultQuantityQuintals: 20.0,
    ),

    // --- Commercial (4) ---
    CropModel(
      cropId: 'cotton',
      cropName: 'Cotton',
      nameHi: 'कपास',
      nameTe: 'పత్తి',
      category: CropCategory.commercial,
      icon: Icons.cloud_queue_rounded,
      defaultQuantityQuintals: 50.0,
    ),
    CropModel(
      cropId: 'jute',
      cropName: 'Jute',
      nameHi: 'जूट',
      nameTe: 'జనపనార',
      category: CropCategory.commercial,
      icon: Icons.line_weight_rounded,
      defaultQuantityQuintals: 40.0,
    ),
    CropModel(
      cropId: 'sugarcane',
      cropName: 'Sugarcane',
      nameHi: 'गन्ना',
      nameTe: 'చెరకు',
      category: CropCategory.commercial,
      icon: Icons.view_week_rounded,
      defaultQuantityQuintals: 100.0,
    ),
    CropModel(
      cropId: 'copra',
      cropName: 'Copra',
      nameHi: 'खोपरा',
      nameTe: 'కొబ్బరి',
      category: CropCategory.commercial,
      icon: Icons.radio_button_checked_rounded,
      defaultQuantityQuintals: 25.0,
    ),
  ];

  /// Filters crops by category.
  static List<CropModel> getCropsByCategory(CropCategory? category) {
    if (category == null) return allCrops;
    return allCrops.where((c) => c.category == category).toList();
  }

  /// Searches crops by matching query against English, Hindi, Telugu names or category.
  static List<CropModel> searchCrops(String query, {CropCategory? category}) {
    final list = getCropsByCategory(category);
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return list;

    final simplifiedQuery = cleanQuery.replaceAll(RegExp(r'[\(\)/-]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    return list.where((crop) {
      final cEn = crop.cropName.toLowerCase();
      final cHi = crop.nameHi.toLowerCase();
      final cTe = crop.nameTe.toLowerCase();
      final cCat = crop.category.name.toLowerCase();
      final cId = crop.cropId.toLowerCase();

      return cEn.contains(cleanQuery) ||
          cHi.contains(cleanQuery) ||
          cTe.contains(cleanQuery) ||
          cCat.contains(cleanQuery) ||
          cId.contains(cleanQuery) ||
          cEn.toLowerCase().contains(simplifiedQuery) ||
          simplifiedQuery.contains(cId);
    }).toList();
  }

  /// Finds a crop by ID or fallback to first match.
  static CropModel? findById(String cropId) {
    try {
      return allCrops.firstWhere(
        (c) => c.cropId.toLowerCase() == cropId.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Finds a crop by name (English, Hindi, or Telugu) with prioritized matching.
  static CropModel? findByName(String name) {
    final clean = name.toLowerCase().trim();
    if (clean.isEmpty) return null;

    final simplified = clean.replaceAll(RegExp(r'[\(\)/-]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    // Priority 1: Exact cropId, exact cropName, or exact Hindi/Telugu name
    for (final c in allCrops) {
      if (c.cropId.toLowerCase() == clean) return c;
      if (c.cropName.toLowerCase() == clean) return c;
      if (c.nameHi.toLowerCase() == clean) return c;
      if (c.nameTe.toLowerCase() == clean) return c;
    }

    // Priority 2: Exact simplified string match
    for (final c in allCrops) {
      final cSimp = c.cropName.toLowerCase().replaceAll(RegExp(r'[\(\)/-]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cSimp == simplified) return c;
    }

    // Priority 3: Word boundary / token match (e.g. 'Gram' matches 'Bengal Gram (Chana)' with cropId 'gram')
    for (final c in allCrops) {
      if (c.cropId.toLowerCase() == simplified) return c;
      final words = c.cropName.toLowerCase().replaceAll(RegExp(r'[\(\)/-]'), ' ').split(RegExp(r'\s+'));
      if (words.contains(simplified)) return c;
    }

    // Priority 4: Substring contains
    for (final c in allCrops) {
      final cEn = c.cropName.toLowerCase();
      final cHi = c.nameHi.toLowerCase();
      final cTe = c.nameTe.toLowerCase();
      final cId = c.cropId.toLowerCase();

      if (cEn.contains(clean) || clean.contains(cEn)) return c;
      if (clean.contains(cId) || cId.contains(clean)) return c;
      if (cHi.isNotEmpty && (cHi.contains(clean) || clean.contains(cHi))) return c;
      if (cTe.isNotEmpty && (cTe.contains(clean) || clean.contains(cTe))) return c;
    }

    return null;
  }

  // Instance delegations for convenience
  List<CropModel> get crops => allCrops;
  List<CropModel> searchCropsInstance(String query, {CropCategory? category}) =>
      searchCrops(query, category: category);
  CropModel? findByIdInstance(String cropId) => findById(cropId);
  CropModel? findByNameInstance(String name) => findByName(name);
}
