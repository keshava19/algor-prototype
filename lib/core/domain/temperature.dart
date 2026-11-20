import 'dart:math';

import 'models.dart';

const _seed = 42;
const _noiseAmplitude = 0.3;
const _driftRate = 0.35;
const _decayRate = 0.8;
const _baseTemp = 4.2;
const _excursionTemp = 8.9;
const _floorTemp = 4.5;
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
  int? driftFrom,
  int? acknowledgedAt,
  int? pinFromTick,
}) {
  final base = _baseTemp + _noiseAt(tick);
  if (pinFromTick != null && tick >= pinFromTick) return _excursionTemp;
  if (acknowledgedAt != null && tick >= acknowledgedAt) {
    final decayed = _excursionTemp - _decayRate * (tick - acknowledgedAt);
    return decayed > _floorTemp ? decayed : base;
  }
  if (driftFrom != null && tick >= driftFrom) {
    final drifted = base + _driftRate * (tick - driftFrom);
    return drifted > _excursionTemp ? _excursionTemp : drifted;
  }
  return base;
}

List<TempReading> readingsBetween(
  int from,
  int to, {
  int? driftFrom,
  int? acknowledgedAt,
  int? pinFromTick,
}) => [
  for (var tick = from; tick <= to; tick++)
    TempReading(
      tick,
      temperatureAt(
        tick,
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
