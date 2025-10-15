String getWeight(double wInKg, String unit) {
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
