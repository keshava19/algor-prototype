import 'package:algor_field/core/scenario/providers.dart';
import 'package:algor_field/core/scenario/scenario_controller.dart';
import 'package:algor_field/core/theme/app_theme.dart';
import 'package:algor_field/features/driver_flow/driver_flow_screen.dart';
import 'package:algor_field/features/driver_flow/steps/checklist_step.dart';
import 'package:algor_field/features/driver_flow/steps/signature_step.dart';
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

Future<void> completeFirstThreeSteps(WidgetTester tester) async {
  for (final title in [
    'Pre-cooled to set-point',
    'Logger armed',
    'Dock seal intact',
    'Reefer clean',
  ]) {
    await tapText(tester, title);
  }
  await tapText(tester, 'Continue');
  final scanButton = find.text('Tap to scan');
  await tester.ensureVisible(scanButton);
  await tester.tap(scanButton);
  await tester.pump();
  expect(find.text('Scanning…'), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 1400));
  await tester.pumpAndSettle();
  await tapText(tester, 'Continue');
  await tapText(tester, 'Capture seal photo');
  await tapText(tester, 'Seal verified');
  await tapText(tester, 'Continue');
  expect(find.text('Step 4 of 5'), findsOneWidget);
}

Future<void> drawSignature(WidgetTester tester) async {
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
}

Future<void> tapDone(WidgetTester tester) async {
  final done = find.widgetWithText(FilledButton, 'Done');
  expect(done, findsOneWidget);
  await tester.tap(done);
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await tester.pumpAndSettle();
}

ScenarioController controllerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(DriverFlowScreen)))
        .read(scenarioControllerProvider.notifier);

void main() {
  testWidgets('driver completes five steps and auto-generates the e-POD', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(4));

    await completeFirstThreeSteps(tester);
    await drawSignature(tester);
    await tapDone(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DriverFlowScreen)),
    );
    expect(container.read(scenarioControllerProvider).signature, isNotNull);
    expect(find.textContaining('Signed by R. Menon'), findsOneWidget);
    expect(find.text('Signature captured · 0 of 3 synced'), findsOneWidget);

    final controller = controllerOf(tester);
    for (var tick = 0; tick < 10; tick++) {
      controller.advanceTick();
    }
    await tester.pumpAndSettle();

    expect(find.text('Step 5 of 5'), findsOneWidget);
    expect(find.text('Delivery complete'), findsOneWidget);
    expect(find.textContaining('e-POD generated'), findsWidgets);
  });

  testWidgets('manual continue still advances before the e-POD fires', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await completeFirstThreeSteps(tester);
    await drawSignature(tester);
    await tapDone(tester);

    await tapText(tester, 'Continue');
    expect(find.text('Step 5 of 5'), findsOneWidget);
    expect(find.text('Waiting for network confirmation'), findsOneWidget);
  });

  testWidgets('failed sync surfaces in the footer and retry drains it', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await completeFirstThreeSteps(tester);
    await drawSignature(tester);
    await tapDone(tester);

    final controller = controllerOf(tester);
    for (var tick = 0; tick < 2; tick++) {
      controller.advanceTick();
    }
    await tester.pumpAndSettle();
    expect(find.text('Signature captured · 1 of 3 synced'), findsOneWidget);

    controller.armSyncFailure();
    controller.advanceTick();
    await tester.pumpAndSettle();
    expect(find.text('Sync failed'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Sync failed'), findsNothing);
    expect(find.text('Signature captured · 1 of 3 synced'), findsOneWidget);

    for (var tick = 0; tick < 10; tick++) {
      controller.advanceTick();
    }
    await tester.pumpAndSettle();
    expect(find.text('Step 5 of 5'), findsOneWidget);
  });

  testWidgets('Done stays visible without scrolling on a short viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1500);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scenarioControllerProvider.overrideWith(
            () => ScenarioController(autoStartTicker: false),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: SignatureStep()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final done = find.widgetWithText(FilledButton, 'Done');
    expect(done, findsOneWidget);
    expect(tester.getBottomRight(done).dy, lessThanOrEqualTo(500));
  });

  testWidgets('short viewports can still reach every checklist row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1500);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scenarioControllerProvider.overrideWith(
            () => ScenarioController(autoStartTicker: false),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: ChecklistStep()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNWidgets(4));
    await tester.scrollUntilVisible(
      find.text('Reefer clean'),
      120,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Reefer clean'), findsOneWidget);
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
