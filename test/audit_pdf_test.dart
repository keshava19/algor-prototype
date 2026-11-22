import 'dart:convert';

import 'package:algor_field/core/domain/band.dart';
import 'package:algor_field/core/domain/sample_assets.dart';
import 'package:algor_field/core/scenario/scenario_state.dart';
import 'package:algor_field/features/client_view/audit_pdf_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('audit PDF builds for delivered, in-flight and preview states', (
    tester,
  ) async {
    final signature = await rootBundle.load(
      'assets/images/signature_sample.png',
    );
    SampleAssets.signaturePng = signature.buffer.asUint8List();

    final delivered = await buildAuditPdf(
      ScenarioState.sampleDelivered(signatureBytes: SampleAssets.signaturePng),
    );
    final inFlight = await buildAuditPdf(
      ScenarioState.initial().triggerExcursion().nextTick(),
    );
    final crt = await buildAuditPdf(
      ScenarioState.initial()
          .setBand(ProductBand.crt)
          .triggerExcursion()
          .nextTick(),
    );
    final stale = await buildAuditPdf(
      ScenarioState.initial().setTelemetryGap(true).nextTick().nextTick(),
    );

    for (final pdf in [delivered, inFlight, crt, stale]) {
      expect(ascii.decode(pdf.take(4).toList()), '%PDF');
      expect(pdf.length, greaterThan(10000));
    }
    expect(delivered.length, greaterThan(20000));
  });
}
