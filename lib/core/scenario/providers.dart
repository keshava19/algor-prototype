import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../domain/route.dart';
import '../domain/temperature.dart';
import 'scenario_controller.dart';
import 'scenario_state.dart';

final scenarioControllerProvider =
    NotifierProvider<ScenarioController, ScenarioState>(ScenarioController.new);

final truckPositionProvider = Provider<({double lat, double lng})>(
  (ref) => positionOnRoute(ref.watch(scenarioControllerProvider).tick),
);

final chartReadingsProvider = Provider<List<TempReading>>((ref) {
  final state = ref.watch(scenarioControllerProvider);
  final fromTick = state.tick - 59 < 0 ? 0 : state.tick - 59;
  return readingsBetween(
    fromTick,
    state.tick,
    driftFrom: state.driftStartedTick,
    acknowledgedAt: state.excursion?.acknowledgedTick,
    pinFromTick: state.phase == TripPhase.excursionActive
        ? state.excursion?.startedTick
        : null,
  );
});
