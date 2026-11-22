enum ProductBand { vaccine, blood, crt, frozen }

final class BandProfile {
  const BandProfile({
    required this.band,
    required this.chipLabel,
    required this.productLabel,
    required this.rangeLabel,
    required this.min,
    required this.max,
    required this.setPoint,
    required this.base,
    required this.excursion,
    required this.floor,
    required this.driftRate,
    required this.decayRate,
    required this.axisMin,
    required this.axisMax,
    required this.axisInterval,
  });

  final ProductBand band;
  final String chipLabel;
  final String productLabel;
  final String rangeLabel;
  final double min;
  final double max;
  final double setPoint;
  final double base;
  final double excursion;
  final double floor;
  final double driftRate;
  final double decayRate;
  final double axisMin;
  final double axisMax;
  final double axisInterval;

  double get axisSpan => axisMax - axisMin;

  String get excursionTitle => excursionTitleFor(excursion);

  String excursionTitleFor(double reading) =>
      'Reefer ${reading.toStringAsFixed(1)} °C — outside $rangeLabel °C band';
}

abstract final class BandProfiles {
  static const vaccine = BandProfile(
    band: ProductBand.vaccine,
    chipLabel: 'Vaccine 2–8 °C',
    productLabel: 'Pharma · 2–8 °C',
    rangeLabel: '2–8',
    min: 2,
    max: 8,
    setPoint: 4,
    base: 4.2,
    excursion: 8.9,
    floor: 4.5,
    driftRate: 0.35,
    decayRate: 0.8,
    axisMin: 0,
    axisMax: 10,
    axisInterval: 2,
  );

  static const blood = BandProfile(
    band: ProductBand.blood,
    chipLabel: 'Blood 1–6 °C',
    productLabel: 'Blood products · 1–6 °C',
    rangeLabel: '1–6',
    min: 1,
    max: 6,
    setPoint: 4,
    base: 3.5,
    excursion: 7.1,
    floor: 3.0,
    driftRate: 0.26,
    decayRate: 0.7,
    axisMin: 0,
    axisMax: 8,
    axisInterval: 2,
  );

  static const crt = BandProfile(
    band: ProductBand.crt,
    chipLabel: 'CRT 15–25 °C',
    productLabel: 'Controlled room temp · 15–25 °C',
    rangeLabel: '15–25',
    min: 15,
    max: 25,
    setPoint: 20,
    base: 20.4,
    excursion: 26.9,
    floor: 20.0,
    driftRate: 0.46,
    decayRate: 0.95,
    axisMin: 10,
    axisMax: 30,
    axisInterval: 5,
  );

  static const frozen = BandProfile(
    band: ProductBand.frozen,
    chipLabel: 'Frozen -30 to -20 °C',
    productLabel: 'Frozen reagents · -30 to -20 °C',
    rangeLabel: '-30 to -20',
    min: -30,
    max: -20,
    setPoint: -25,
    base: -24.3,
    excursion: -18.2,
    floor: -23.5,
    driftRate: 0.44,
    decayRate: 0.85,
    axisMin: -35,
    axisMax: -10,
    axisInterval: 5,
  );

  static const all = [vaccine, blood, crt, frozen];

  static BandProfile of(ProductBand band) => switch (band) {
    ProductBand.vaccine => vaccine,
    ProductBand.blood => blood,
    ProductBand.crt => crt,
    ProductBand.frozen => frozen,
  };
}
