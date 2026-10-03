/// Data for one specific package, never dosing advice.
class MedicationProduct {
  const MedicationProduct({
    required this.name,
    required this.strength,
    required this.pharmaceuticalForm,
    required this.packageDescription,
    required this.packageQuantity,
    required this.packageUnit,
    required this.gtin,
  });

  final String name;
  final String strength;
  final String pharmaceuticalForm;
  final String packageDescription;
  final double? packageQuantity;
  final String? packageUnit;
  // Canonical, checksum-validated GTIN-14. Null for manual entry.
  final String? gtin;

  String get displayName =>
      [name, strength].where((s) => s.isNotEmpty).join(' ');

  factory MedicationProduct.fromJson(Map<String, dynamic> json) =>
      MedicationProduct(
        name: json['name'] as String,
        strength: json['strength'] as String,
        pharmaceuticalForm: json['pharmaceuticalForm'] as String,
        packageDescription: json['packageDescription'] as String,
        packageQuantity: (json['packageQuantity'] as num?)?.toDouble(),
        packageUnit: json['packageUnit'] as String?,
        gtin: json['gtin'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'strength': strength,
    'pharmaceuticalForm': pharmaceuticalForm,
    'packageDescription': packageDescription,
    'packageQuantity': packageQuantity,
    'packageUnit': packageUnit,
    'gtin': gtin,
  };
}

/// Stock belongs to the medication, not to each scheduled dose.
class MedicationStock {
  const MedicationStock({
    required this.product,
    required this.instruction,
    this.ownedPackages,
    this.looseUnits,
  });

  final MedicationProduct product;
  // Entered by the user; never parsed into a recommended dose.
  final String instruction;
  final int? ownedPackages;
  final double? looseUnits;

  double? get totalUnits {
    if (ownedPackages == null && looseUnits == null) return null;
    if ((ownedPackages ?? 0) > 0 && product.packageQuantity == null) {
      return null;
    }
    return (ownedPackages ?? 0) * (product.packageQuantity ?? 0) +
        (looseUnits ?? 0);
  }
}

class MedicationDose {
  MedicationDose({
    required this.id,
    required this.time,
    required this.name,
    required this.instruction,
    this.product,
    this.isTaken = false,
  });

  final String id;
  final String time;
  final String name;
  final String instruction;
  final MedicationProduct? product;
  bool isTaken;
}
