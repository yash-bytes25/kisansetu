import 'package:flutter/material.dart';

/// Categories of crops supported in the KisanSetu procurement catalogue.
enum CropCategory {
  cereals,
  pulses,
  oilseeds,
  commercial;

  String localizedName({bool isHindi = false, bool isTelugu = false}) {
    switch (this) {
      case CropCategory.cereals:
        return isTelugu ? 'ధాన్యాలు' : (isHindi ? 'अनाज' : 'Cereals');
      case CropCategory.pulses:
        return isTelugu ? 'పప్పుధాన్యాలు' : (isHindi ? 'दलहन' : 'Pulses');
      case CropCategory.oilseeds:
        return isTelugu ? 'నూనెగింజలు' : (isHindi ? 'तिलहन' : 'Oilseeds');
      case CropCategory.commercial:
        return isTelugu ? 'వాణిజ్య పంటలు' : (isHindi ? 'व्यावसायिक' : 'Commercial');
    }
  }
}

/// Data model representing an agricultural produce crop in KisanSetu.
class CropModel {
  final String cropId;
  final String cropName;
  final String nameHi;
  final String nameTe;
  final CropCategory category;
  final IconData icon;
  final double defaultQuantityQuintals;

  const CropModel({
    required this.cropId,
    required this.cropName,
    required this.nameHi,
    required this.nameTe,
    required this.category,
    required this.icon,
    this.defaultQuantityQuintals = 50.0,
  });

  /// Shorthand getters for id and name
  String get id => cropId;
  String get name => cropName;

  /// Returns the crop name localized to Telugu, Hindi, or English.
  String localizedName({bool isHindi = false, bool isTelugu = false}) {
    if (isTelugu) return nameTe;
    if (isHindi) return nameHi;
    return cropName;
  }

  /// Returns the category name localized.
  String localizedCategory({bool isHindi = false, bool isTelugu = false}) {
    return category.localizedName(isHindi: isHindi, isTelugu: isTelugu);
  }

  Map<String, dynamic> toMap() {
    return {
      'crop_id': cropId,
      'crop_name': cropName,
      'name_hi': nameHi,
      'name_te': nameTe,
      'category': category.name,
      'default_quantity': defaultQuantityQuintals,
    };
  }

  factory CropModel.fromMap(Map<String, dynamic> map) {
    return CropModel(
      cropId: map['crop_id'] as String? ?? 'wheat',
      cropName: map['crop_name'] as String? ?? 'Wheat',
      nameHi: map['name_hi'] as String? ?? 'गेहूं',
      nameTe: map['name_te'] as String? ?? 'గోధుమలు',
      category: CropCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => CropCategory.cereals,
      ),
      icon: Icons.grass_rounded,
      defaultQuantityQuintals:
          (map['default_quantity'] as num?)?.toDouble() ?? 50.0,
    );
  }

  CropModel copyWith({
    String? cropId,
    String? cropName,
    String? nameHi,
    String? nameTe,
    CropCategory? category,
    IconData? icon,
    double? defaultQuantityQuintals,
  }) {
    return CropModel(
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      nameHi: nameHi ?? this.nameHi,
      nameTe: nameTe ?? this.nameTe,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      defaultQuantityQuintals:
          defaultQuantityQuintals ?? this.defaultQuantityQuintals,
    );
  }
}
