import 'package:algor_field/core/domain/temperature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('baseline readings stay deterministic and near set-point', () {
    final first = temperatureAt(45);
    final second = temperatureAt(45);
    expect(first, second);
    expect(first, greaterThanOrEqualTo(3.9));
    expect(first, lessThanOrEqualTo(4.5));
  });

  test('excursion pin holds the peak reading', () {
    expect(temperatureAt(130, pinFromTick: 130), 8.9);
    expect(temperatureAt(500, pinFromTick: 130), 8.9);
  });

  test('drift ramps and clamps at the peak', () {
    final early = temperatureAt(120, driftFrom: 116);
    final capped = temperatureAt(200, driftFrom: 116);
    expect(early, greaterThan(temperatureAt(120)));
    expect(capped, 8.9);
  });

  test('acknowledged excursion decays back into the band', () {
    final justAfter = temperatureAt(132, acknowledgedAt: 131);
    final recovered = temperatureAt(150, acknowledgedAt: 131);
    expect(justAfter, lessThan(8.9));
    expect(justAfter, greaterThan(4.5));
    expect(recovered, inInclusiveRange(3.9, 4.5));
  });

  test('readingsBetween returns one reading per scenario minute', () {
    final readings = readingsBetween(10, 40);
    expect(readings, hasLength(31));
    expect(readings.first.tick, 10);
    expect(readings.last.tick, 40);
  });

  test('MKT weights the warm tail above the arithmetic mean', () {
    final readings = readingsBetween(
      100,
      160,
      driftFrom: 116,
      acknowledgedAt: 140,
    );
    final mean =
        readings.map((r) => r.celsius).reduce((a, b) => a + b) /
        readings.length;
    expect(meanKineticTemperature(readings), greaterThan(mean));
  });
}
