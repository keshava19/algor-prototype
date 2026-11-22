import 'package:algor_field/core/scenario/providers.dart';
import 'package:algor_field/core/scenario/scenario_controller.dart';
import 'package:algor_field/core/theme/app_theme.dart';
import 'package:algor_field/features/driver_flow/driver_flow_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signature/signature.dart';

Widget harness() => ProviderScope(
  overrides: [
    scenarioControllerProvider.overrideWith(
      () => ScenarioController(autoStartTicker: false),
    ),
  ],
  child: MaterialApp(theme: buildAppTheme(), home: const DriverFlowScreen()),
);

Future<void> tapText(WidgetTester tester, String label) async {
  final finder = find.text(label);
  for (var attempt = 0; attempt < 6 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -160));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('driver completes five steps and auto-generates the e-POD', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 5'), findsOneWidget);

    for (final title in [
      'Pre-cooled to set-point',
      'Logger armed',
      'Dock seal intact',
      'Reefer clean',
    ]) {
      await tapText(tester, title);
    }

    await tapText(tester, 'Continue');
    expect(find.text('Step 2 of 5'), findsOneWidget);

    final scanButton = find.text('Tap to scan');
    await tester.ensureVisible(scanButton);
    await tester.tap(scanButton);
    await tester.pump();
    expect(find.text('Scanning…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    expect(find.text('AWB 172-45678901'), findsOneWidget);

    await tapText(tester, 'Continue');
    expect(find.text('Step 3 of 5'), findsOneWidget);

    await tapText(tester, 'Capture seal photo');
    expect(find.text('Seal photo captured'), findsOneWidget);
    await tapText(tester, 'Seal verified');
    await tapText(tester, 'Continue');
    expect(find.text('Step 4 of 5'), findsOneWidget);

    final signature = find.byType(Signature);
    final rect = tester.getRect(signature);
    final gesture = await tester.startGesture(
      rect.centerLeft + const Offset(36, 40),
    );
    await tester.pump();
    for (final delta in const [
      Offset(40, 12),
      Offset(40, -18),
      Offset(40, 24),
      Offset(30, -10),
    ]) {
      await gesture.moveBy(delta);
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    final doneFinder = find.text('Done');
    if (doneFinder.evaluate().isEmpty) {
      await tester.fling(
        find.text('Consignee signature'),
        const Offset(0, -600),
        1500,
      );
      await tester.pumpAndSettle();
    }
    final doneButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Done'),
    );
    expect(doneButton.onPressed, isNotNull);
    await tester.ensureVisible(doneFinder);
    await tester.tap(doneFinder);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pumpAndSettle();
    final signedContainer = ProviderScope.containerOf(
      tester.element(find.byType(DriverFlowScreen)),
    );
    expect(
      signedContainer.read(scenarioControllerProvider).signature,
      isNotNull,
    );
    expect(find.textContaining('Signed by R. Menon'), findsOneWidget);

    final element = tester.element(find.byType(DriverFlowScreen));
    final container = ProviderScope.containerOf(element);
    final controller = container.read(scenarioControllerProvider.notifier);
    for (var tick = 0; tick < 10; tick++) {
      controller.advanceTick();
    }
    await tester.pumpAndSettle();

    await tapText(tester, 'Continue');
    expect(find.text('Step 5 of 5'), findsOneWidget);
    expect(find.text('Delivery complete'), findsOneWidget);
    expect(find.textContaining('e-POD generated'), findsWidgets);
  });

  testWidgets('offline banner reports the live queue count', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(
      find.text('Offline mode: highway dead zone — 0 items queued, will sync'),
      findsOneWidget,
    );
  });
}
