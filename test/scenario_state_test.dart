import 'dart:typed_data';

import 'package:algor_field/core/domain/fictional_data.dart';
import 'package:algor_field/core/domain/models.dart';
import 'package:algor_field/core/scenario/scenario_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial state starts at 05:00 with one baked custody event', () {
    final state = ScenarioState.initial();
    expect(state.tick, initialTick);
    expect(state.phase, TripPhase.driving);
    expect(state.custody, hasLength(1));
    expect(state.currentTemperature, inInclusiveRange(3.9, 4.5));
  });

  test('offline captures queue without promoting', () {
    var state = ScenarioState.initial();
    for (var index = 0; index < state.checklist.length; index++) {
      state = state.confirmChecklistRow(index);
    }
    state = state.completeChecklist().confirmScan().setOffline(true);
    expect(state.queue, hasLength(2));
    for (var tick = 0; tick < 10; tick++) {
      state = state.nextTick();
    }
    expect(
      state.queue.every((item) => item.status == QueueItemStatus.pending),
      isTrue,
    );
    expect(state.scanned, isTrue);
  });

  test('online sync promotes exactly one status per tick', () {
    var state = ScenarioState.initial();
    for (var index = 0; index < state.checklist.length; index++) {
      state = state.confirmChecklistRow(index);
    }
    state = state.completeChecklist();
    final tickBefore = state.tick;
    state = state.nextTick();
    expect(state.tick, tickBefore + 1);
    expect(state.queue.single.status, QueueItemStatus.syncing);
    state = state.nextTick();
    expect(state.queue.single.status, QueueItemStatus.synced);
  });

  test('excursion jump lands at 06:25 near Nashik and escalates on expiry', () {
    var state = ScenarioState.initial().triggerExcursion();
    expect(state.tick, 130);
    expect(state.phase, TripPhase.excursionActive);
    expect(state.excursion?.location, excursionLocation);
    expect(state.currentTemperature, 8.9);
    for (var tick = 0; tick < defaultEscalationSeconds; tick++) {
      state = state.nextTick();
    }
    expect(state.excursion?.escalated, isTrue);
    expect(state.escalationSecondsLeft, 0);
    expect(
      state.custody.any((event) => event.title.contains('Escalated')),
      isTrue,
    );
    state = state.acknowledge(note: 'Compressor restarted');
    expect(state.phase, TripPhase.excursionAcknowledged);
    expect(state.excursion?.acknowledgedTick, 130 + defaultEscalationSeconds);
    expect(state.excursion?.note, 'Compressor restarted');
  });

  test('signature plus synced captures triggers automatic delivery', () {
    var state = ScenarioState.initial();
    for (var index = 0; index < state.checklist.length; index++) {
      state = state.confirmChecklistRow(index);
    }
    state = state
        .completeChecklist()
        .confirmScan()
        .confirmSeal(defaultSealNumber)
        .captureSignature(Uint8List.fromList([1, 2, 3]), consigneeName);
    expect(state.canDeliver, isFalse);
    for (var tick = 0; tick < 8; tick++) {
      state = state.nextTick();
    }
    expect(state.phase, TripPhase.delivered);
    expect(state.epod, isNotNull);
    expect(state.epod?.deliveredTick, state.tick);
    expect(state.custody.last.title, contains('e-POD generated'));
  });

  test('sample delivery is complete and current temperature is in band', () {
    final state = ScenarioState.sampleDelivered();
    expect(state.phase, TripPhase.delivered);
    expect(state.epod?.sealNumber, defaultSealNumber);
    expect(state.currentTemperature, inInclusiveRange(3.9, 4.5));
    expect(state.custody.last.title, contains('e-POD generated'));
    expect(state.epod?.deliveredTick, deliveredTick);
  });
}
