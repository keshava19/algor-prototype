import 'package:algor_field/core/scenario/providers.dart';
import 'package:algor_field/core/scenario/scenario_controller.dart';
import 'package:algor_field/features/excursion/excursion_push_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('push banner appears on the excursion transition and hides', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        scenarioControllerProvider.overrideWith(
          () => ScenarioController(autoStartTicker: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ExcursionPushBanner(enabled: true)),
        ),
      ),
    );
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );

    container.read(scenarioControllerProvider.notifier).triggerExcursion();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ALGOR FIELD · EXCURSION ALERT'), findsOneWidget);
    expect(find.text('Reefer 8.9 °C — outside 2–8 °C band'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 300));
    final opacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );
    expect(opacity.opacity, 0);
  });
}
