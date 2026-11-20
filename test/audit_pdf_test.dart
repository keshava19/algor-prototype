import 'dart:convert';

import 'package:algor_field/core/domain/sample_assets.dart';
import 'package:algor_field/core/scenario/scenario_state.dart';
import 'package:algor_field/features/client_view/audit_pdf_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('audit PDF builds for delivered and in-flight states', (
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

    expect(ascii.decode(delivered.take(4).toList()), '%PDF');
    expect(ascii.decode(inFlight.take(4).toList()), '%PDF');
    expect(delivered.length, greaterThan(20000));
    expect(inFlight.length, greaterThan(10000));
  });
}
