String getWeightString(double wInKg, String unit) {
  String actualWeight;
  switch (unit) {
    case 'kg':
      actualWeight = wInKg.toStringAsFixed(1);
    case 'lbs':
      final lbs = wInKg * 2.20462;
      final roundedToHalf = (lbs * 2).roundToDouble() / 2.0;
      actualWeight = roundedToHalf.toStringAsFixed(1);
    default:
      actualWeight = wInKg.toStringAsFixed(1);
  }
  return "$actualWeight $unit";
}

double toKg(double weight, String unit) {
  switch (unit) {
    case 'kg':
      return weight;
    case 'lbs':
      final kg = weight / 2.20462;
      final roundedToHalf = (kg * 2).roundToDouble() / 2.0;
      return roundedToHalf;
    default:
      return weight;
  }
}

double getWeight(double wInKg, String unit) {
  switch (unit) {
    case 'kg':
      return wInKg;
    case 'lbs':
      final lbs = wInKg * 2.20462;
      final roundedToHalf = (lbs * 2).roundToDouble() / 2.0;
      return roundedToHalf;
    default:
      return wInKg;
  }
}