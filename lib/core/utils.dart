enum WeightUnit { kg, lb, g, unit }

class WeightConverter {
  static double toKg(double lbs) => lbs * 0.453592;
  static double toLbs(double kgs) => kgs * 2.20462;
  static double toLb(double kgs) => toLbs(kgs);
  static double fromG(double g) => g / 1000;
  static double toG(double kg) => kg * 1000;

  static double convert({
    required double value,
    required WeightUnit from,
    required WeightUnit to,
  }) {
    if (from == to) return value;
    
    // Normalize to KG first
    double kg;
    switch (from) {
      case WeightUnit.kg: kg = value; break;
      case WeightUnit.lb: kg = toKg(value); break;
      case WeightUnit.g: kg = fromG(value); break;
      case WeightUnit.unit: kg = value; break; // Units stay as is
    }

    // Convert to target
    switch (to) {
      case WeightUnit.kg: return kg;
      case WeightUnit.lb: return toLbs(kg);
      case WeightUnit.g: return toG(kg);
      case WeightUnit.unit: return kg;
    }
  }

  static String formatShort(double weight, {String? unit}) {
    final lowerUnit = unit?.toLowerCase();
    if (lowerUnit == 'unit' || lowerUnit == 'qty' || lowerUnit == 'pcs') {
      final isInt = weight == weight.roundToDouble();
      return '${isInt ? weight.toStringAsFixed(0) : weight.toStringAsFixed(1)} pcs';
    }
    if (lowerUnit == 'lb' || lowerUnit == 'lbs') {
      final lbs = toLbs(weight);
      final isInt = lbs == lbs.roundToDouble();
      return '${isInt ? lbs.toStringAsFixed(0) : lbs.toStringAsFixed(1)} lb';
    }
    if (lowerUnit == 'g') {
      final grams = toG(weight);
      return '${grams.toStringAsFixed(0)}g';
    }
    if (lowerUnit != null && lowerUnit != 'kg' && lowerUnit != 't') {
      final isInt = weight == weight.roundToDouble();
      return '${isInt ? weight.toStringAsFixed(0) : weight.toStringAsFixed(1)} $unit';
    }
    if (weight >= 1000) {
      return '${(weight / 1000).toStringAsFixed(1)}t';
    }
    final isInt = weight == weight.roundToDouble();
    return '${isInt ? weight.toStringAsFixed(0) : weight.toStringAsFixed(1)}kg';
  }
}

class IdGenerator {
  static String generate({String prefix = 'ID'}) {
    final now = DateTime.now();
    final dateStr = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final random = (100 + (now.microsecond % 900)).toString();
    return '$prefix-$dateStr-$timeStr-$random';
  }
}
