import 'package:algor_field/core/domain/fictional_data.dart';
import 'package:algor_field/core/scenario/providers.dart';
import 'package:algor_field/core/scenario/scenario_controller.dart';
import 'package:algor_field/core/theme/app_theme.dart';
import 'package:algor_field/features/client_view/client_shipment_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness({required bool sample}) => ProviderScope(
  overrides: [
    scenarioControllerProvider.overrideWith(
      () => ScenarioController(autoStartTicker: false),
    ),
  ],
  child: MaterialApp(
    theme: buildAppTheme(),
    home: ClientShipmentDetail(sample: sample),
  ),
);

void main() {
  testWidgets('sample detail reads as a final record', (tester) async {
    await tester.pumpWidget(harness(sample: true));
    await tester.pumpAndSettle();

    expect(find.text('Sample delivery'), findsOneWidget);
    expect(find.text('Delivery pack'), findsOneWidget);
    expect(find.text('Final record · delivered 21:48 IST'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Seal verified · SL-2291'), findsOneWidget);
    expect(find.byTooltip(downloadAuditPdfLabel), findsOneWidget);
  });

  testWidgets('live detail stays a live shipment in transit', (tester) async {
    await tester.pumpWidget(harness(sample: false));
    await tester.pumpAndSettle();

    expect(find.text('Live shipment'), findsOneWidget);
    expect(find.text('Delivery pack'), findsOneWidget);
    expect(find.text('In transit'), findsOneWidget);
    expect(find.textContaining('Final record'), findsNothing);
    expect(find.textContaining('ETA 22:45'), findsOneWidget);
  });

  testWidgets('custody rows expand to event id, actor and source', (
    tester,
  ) async {
    await tester.pumpWidget(harness(sample: true));
    await tester.pumpAndSettle();

    final row = find.text('AWB scanned');
    await tester.dragUntilVisible(
      row,
      find.byType(ListView).first,
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('Event ID'), findsOneWidget);
    expect(find.text('EVT-003'), findsOneWidget);
    expect(find.text('Actor'), findsOneWidget);
    expect(find.text('S. Pawar'), findsWidgets);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Driver app'), findsOneWidget);
  });

  testWidgets('app bar PDF action drives the share path', (tester) async {
    await tester.pumpWidget(harness(sample: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(downloadAuditPdfLabel));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1200)),
    );
    await tester.pumpAndSettle();

    expect(find.text(pdfFailedLabel), findsOneWidget);
  });
}
