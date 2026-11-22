import 'dart:math';

import 'band.dart';
import 'models.dart';

const _seed = 42;
const _noiseAmplitude = 0.3;
const _eOverR = 83144.0 / 8.314462618;

final List<double> _noise = _buildNoise();

List<double> _buildNoise() {
  final random = Random(_seed);
  return List<double>.generate(
    2400,
    (_) => (random.nextDouble() * 2 - 1) * _noiseAmplitude,
  );
}

double _noiseAt(int tick) => _noise[tick % _noise.length];

double temperatureAt(
  int tick, {
  BandProfile band = BandProfiles.vaccine,
  int? driftFrom,
  int? acknowledgedAt,
  int? pinFromTick,
}) {
  final base = band.base + _noiseAt(tick);
  if (pinFromTick != null && tick >= pinFromTick) return band.excursion;
  if (acknowledgedAt != null && tick >= acknowledgedAt) {
    final decayed = band.excursion - band.decayRate * (tick - acknowledgedAt);
    return decayed > band.floor ? decayed : base;
  }
  if (driftFrom != null && tick >= driftFrom) {
    final drifted = base + band.driftRate * (tick - driftFrom);
    return drifted > band.excursion ? band.excursion : drifted;
  }
  return base;
}

List<TempReading> readingsBetween(
  int from,
  int to, {
  BandProfile band = BandProfiles.vaccine,
  int? driftFrom,
  int? acknowledgedAt,
  int? pinFromTick,
}) => [
  for (var tick = from; tick <= to; tick++)
    TempReading(
      tick,
      temperatureAt(
        tick,
        band: band,
        driftFrom: driftFrom,
        acknowledgedAt: acknowledgedAt,
        pinFromTick: pinFromTick,
      ),
    ),
];

double meanKineticTemperature(List<TempReading> readings) {
  if (readings.isEmpty) return 0;
  final sum = readings.fold<double>(
    0,
    (acc, reading) => acc + exp(-_eOverR / (reading.celsius + 273.15)),
  );
  return _eOverR / -log(sum / readings.length) - 273.15;
}
