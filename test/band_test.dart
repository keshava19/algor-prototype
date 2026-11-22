import 'package:algor_field/core/domain/band.dart';
import 'package:algor_field/core/domain/temperature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every band stays deterministic and inside its range at baseline', () {
    for (final band in BandProfiles.all) {
      final first = temperatureAt(45, band: band);
      final second = temperatureAt(45, band: band);
      expect(first, second, reason: band.productLabel);
      expect(first, greaterThanOrEqualTo(band.min), reason: band.productLabel);
      expect(first, lessThanOrEqualTo(band.max), reason: band.productLabel);
    }
  });

  test('every band pins at its excursion value and decays home', () {
    for (final band in BandProfiles.all) {
      expect(
        temperatureAt(500, band: band, pinFromTick: 130),
        band.excursion,
        reason: band.productLabel,
      );
      final recovered = temperatureAt(160, band: band, acknowledgedAt: 131);
      expect(recovered, greaterThanOrEqualTo(band.min));
      expect(recovered, lessThanOrEqualTo(band.max));
    }
  });

  test('axis ranges contain the band and the excursion peak', () {
    for (final band in BandProfiles.all) {
      expect(band.axisMin, lessThan(band.min), reason: band.productLabel);
      expect(band.axisMax, greaterThan(band.max), reason: band.productLabel);
      expect(
        band.excursion,
        inInclusiveRange(band.axisMin, band.axisMax),
        reason: band.productLabel,
      );
    }
  });

  test('vaccine rendering keeps the dossier wording and 2–8 range', () {
    expect(
      BandProfiles.vaccine.excursionTitle,
      'Reefer 8.9 °C — outside 2–8 °C band',
    );
  });
}
