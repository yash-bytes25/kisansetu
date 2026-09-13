/// Result of a procurement payment calculation.
class PaymentCalculationResult {
  final double acceptedQuantity;
  final double ratePerQuintal;
  final double grossAmount;
  final double deductions;
  final double netPayable;
  final String crop;
  final String qualityGrade;
  final bool isSimulated;

  const PaymentCalculationResult({
    required this.acceptedQuantity,
    required this.ratePerQuintal,
    required this.grossAmount,
    required this.deductions,
    required this.netPayable,
    required this.crop,
    required this.qualityGrade,
    this.isSimulated = true,
  });
}

/// Service dedicated to transparent procurement pricing and MSP calculations.
///
/// MSP rates are official reference benchmarks based on Government of India
/// Cabinet Committee on Economic Affairs (CCEA) Minimum Support Prices (Kharif / Rabi 2024-25).
/// Payment calculations and statuses are simulated prototypes for SIH demonstration
/// and do not connect to live banking clearinghouses or direct financial institutions.
class PaymentCalculationService {
  /// Reference benchmark MSP rates per quintal (CCEA 2024-25).
  /// Clearly labeled as simulated reference benchmark data.
  static const Map<String, double> mockMspRates = {
    'wheat': 2275.0,
    'paddy': 2300.0,
    'rice': 2300.0,
    'maize': 2090.0,
    'jowar': 3180.0,
    'bajra': 2500.0,
    'ragi': 3846.0,
    'gram': 5440.0,
    'chickpea': 5440.0,
    'tur': 7000.0,
    'arhar': 7000.0,
    'mustard': 5650.0,
    'soybean': 4600.0,
    'barley': 1850.0,
    'moong': 8558.0,
    'urad': 7400.0,
    'masoor': 6425.0,
    'peas': 5440.0,
    'groundnut': 6783.0,
    'sunflower': 7280.0,
    'sesame': 9267.0,
    'safflower': 5800.0,
    'cotton': 7121.0,
    'jute': 5335.0,
    'sugarcane': 340.0,
    'copra': 11160.0,

    // Hindi names
    'गेहूं': 2275.0,
    'धान': 2300.0,
    'चावल': 2300.0,
    'मक्का': 2090.0,
    'ज्वार': 3180.0,
    'बाजरा': 2500.0,
    'रागी': 3846.0,
    'चना': 5440.0,
    'तूर': 7000.0,
    'अरहर': 7000.0,
    'सरसों': 5650.0,
    'सोयाबीन': 4600.0,
    'जौ': 1850.0,
    'मूंग': 8558.0,
    'उड़द': 7400.0,
    'मसूर': 6425.0,
    'मटर': 5440.0,
    'मूंगफली': 6783.0,
    'सूरजमुखी': 7280.0,
    'तिल': 9267.0,
    'कुसुम': 5800.0,
    'कपास': 7121.0,
    'जूट': 5335.0,
    'गन्ना': 340.0,
    'खोपरा': 11160.0,

    // Telugu names
    'గోధుమలు': 2275.0,
    'వరి': 2300.0,
    'బియ్యం': 2300.0,
    'మొక్కజొన్న': 2090.0,
    'జొన్నలు': 3180.0,
    'సజ్జలు': 2500.0,
    'రాగులు': 3846.0,
    'శనగలు': 5440.0,
    'కందులు': 7000.0,
    'ఆవాలు': 5650.0,
    'సోయాబీన్': 4600.0,
    'బార్లీ': 1850.0,
    'పెసలు': 8558.0,
    'మినుములు': 7400.0,
    'ఎర్ర కందులు': 6425.0,
    'బఠానీలు': 5440.0,
    'వేరుశెనగ': 6783.0,
    'పొద్దుతిరుగుడు': 7280.0,
    'నువ్వులు': 9267.0,
    'కుసుమ': 5800.0,
    'పత్తి': 7121.0,
    'జనపనార': 5335.0,
    'చెరకు': 340.0,
    'కొబ్బరి': 11160.0,
  };

  /// Returns the MSP rate for a crop, or standard 2275.0 fallback
  static double getMspRate(String crop) {
    final clean = crop.toLowerCase().trim();
    for (final entry in mockMspRates.entries) {
      if (clean.contains(entry.key.toLowerCase()) || entry.key.toLowerCase().contains(clean)) {
        return entry.value;
      }
    }
    return 2275.0;
  }

  /// Calculates gross value, deductions, and net payable amount.
  ///
  /// Example:
  /// - Accepted Quantity: 50.2 Quintals
  /// - Mock MSP: ₹2,275 / Quintal
  /// - Gross Amount: ₹1,14,205
  /// - Deductions: ₹0
  /// - Net Payable: ₹1,14,205
  static PaymentCalculationResult calculate({
    required double acceptedQuantity,
    required String crop,
    String qualityGrade = 'FAQ',
    double deductions = 0.0,
  }) {
    final rate = getMspRate(crop);

    // Optional grade adjustments (Grade A premium, Grade B small discount if desired, default 1.0)
    double gradeMultiplier = 1.0;
    if (qualityGrade == 'Grade A') {
      gradeMultiplier = 1.0;
    } else if (qualityGrade == 'Grade B') {
      gradeMultiplier = 0.98;
    }

    final effectiveRate = rate * gradeMultiplier;
    final gross = acceptedQuantity * effectiveRate;
    final net = (gross - deductions) > 0 ? (gross - deductions) : 0.0;

    return PaymentCalculationResult(
      acceptedQuantity: acceptedQuantity,
      ratePerQuintal: effectiveRate,
      grossAmount: gross,
      deductions: deductions,
      netPayable: net,
      crop: crop,
      qualityGrade: qualityGrade,
      isSimulated: true,
    );
  }

  /// Formats currency to standard Indian Rupee representation (e.g. ₹1,14,205)
  static String formatCurrency(double amount) {
    final rounded = amount.round();
    final str = rounded.toString();
    if (str.length <= 3) return '₹$str';

    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);

    // Group pairs from right to left
    final regExp = RegExp(r'(\d+?)(?=(\d{2})+$)');
    final formattedRest = rest.replaceAllMapped(regExp, (m) => '${m[1]},');

    return '₹$formattedRest,$lastThree';
  }
}
