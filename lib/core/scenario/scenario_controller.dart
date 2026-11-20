import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scenario_state.dart';

final class ScenarioController extends Notifier<ScenarioState> {
  ScenarioController({this.autoStartTicker = true});

  final bool autoStartTicker;
  Timer? _ticker;

  @override
  ScenarioState build() {
    if (autoStartTicker) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => advanceTick(),
      );
      ref.onDispose(() => _ticker?.cancel());
    }
    return ScenarioState.initial();
  }

  void advanceTick() => state = state.nextTick();

  void confirmChecklistRow(int index) =>
      state = state.confirmChecklistRow(index);

  void completeChecklist() => state = state.completeChecklist();

  void confirmScan() => state = state.confirmScan();

  void confirmSeal(String number) => state = state.confirmSeal(number);

  void captureSignature(Uint8List bytes, String name) =>
      state = state.captureSignature(bytes, name);

  void setOffline(bool value) => state = state.setOffline(value);

  void startDrift() => state = state.startDrift();

  void triggerExcursion() => state = state.triggerExcursion();

  void acknowledge({String reasonCode = 'Driver acknowledged', String? note}) =>
      state = state.acknowledge(reasonCode: reasonCode, note: note);

  void callControlRoom() => state = state.callControlRoom();

  void recordCall(String title) => state = state.recordCall(title);

  void setEscalationDuration(int seconds) =>
      state = state.setEscalationDuration(seconds);

  void jumpToOutForDelivery() => state = state.jumpToOutForDelivery();

  void jumpToDelivered() => state = state.jumpToDelivered();

  void reset() => state = ScenarioState.initial();
}
