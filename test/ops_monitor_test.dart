import 'package:algor_field/core/domain/band.dart';
import 'package:algor_field/core/domain/fictional_data.dart';
import 'package:algor_field/core/scenario/providers.dart';
import 'package:algor_field/core/scenario/scenario_controller.dart';
import 'package:algor_field/core/theme/app_theme.dart';
import 'package:algor_field/features/about/about_concept_sheet.dart';
import 'package:algor_field/features/ops_monitor/ops_monitor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget harness() {
  final router = GoRouter(
    initialLocation: '/ops',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('role-picker')),
      ),
      GoRoute(path: '/ops', builder: (_, _) => const OpsMonitorScreen()),
    ],
  );
  return ProviderScope(
    overrides: [
      scenarioControllerProvider.overrideWith(
        () => ScenarioController(autoStartTicker: false),
      ),
    ],
    child: MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
  );
}

ScenarioController controllerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(OpsMonitorScreen)))
        .read(scenarioControllerProvider.notifier);

void main() {
  testWidgets('active excursion pins the alert first with a primary call', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    controllerOf(tester).triggerExcursion();
    await tester.pumpAndSettle();

    expect(
      find.text('Excursion — awaiting driver acknowledgement'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Call driver'), findsOneWidget);
    final alertTop = tester
        .getTopLeft(find.text('Excursion — awaiting driver acknowledgement'))
        .dy;
    final packTop = tester.getTopLeft(find.text(awbLabel)).dy;
    expect(alertTop, lessThan(packTop));
    expect(
      find.textContaining('8.9 °C — outside the 2–8 °C band'),
      findsOneWidget,
    );
  });

  testWidgets('feed strip and last alert survive resolution', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(find.text('FEED LIVE'), findsOneWidget);

    final controller = controllerOf(tester);
    controller.setTelemetryGap(true);
    await tester.pumpAndSettle();
    expect(find.text('FEED STALE'), findsOneWidget);
    expect(find.textContaining('last received'), findsWidgets);

    controller.setTelemetryGap(false);
    controller.triggerExcursion();
    controller.acknowledge();
    await tester.pumpAndSettle();
    expect(
      find.text('Last alert 06:25 · 8.9 °C · acknowledged'),
      findsOneWidget,
    );

    controller.setBand(ProductBand.crt);
    await tester.pumpAndSettle();
    expect(
      find.text('Last alert 06:25 · 8.9 °C · acknowledged'),
      findsOneWidget,
    );

    controller.jumpToDelivered();
    await tester.pumpAndSettle();
    expect(find.text('FEED CLOSED'), findsOneWidget);
    expect(find.textContaining('delivered 21:48'), findsOneWidget);
  });

  testWidgets('switch role returns to the role picker', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Switch role'));
    await tester.pumpAndSettle();
    expect(find.text('role-picker'), findsOneWidget);
  });

  testWidgets('about sheet explains the presenter control', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: AboutConceptSheet()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Presenter tip — long-press the footer for scenario controls.'),
      findsOneWidget,
    );
    expect(find.textContaining('DPDP obligations in mind'), findsOneWidget);
  });
}
