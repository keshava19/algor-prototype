import 'dart:typed_data';

import 'package:algor_field/core/domain/band.dart';
import 'package:algor_field/core/domain/fictional_data.dart';
import 'package:algor_field/core/domain/models.dart';
import 'package:algor_field/core/scenario/scenario_state.dart';
import 'package:flutter_test/flutter_test.dart';

ScenarioState afterDeadZone() => ScenarioState.initial().copyWith(
  tick: deadZoneEndTick + 1,
  lastFeedTick: deadZoneEndTick + 1,
);

void main() {
  test('initial state starts at 05:00 with one baked custody event', () {
    final state = ScenarioState.initial();
    expect(state.tick, initialTick);
    expect(state.phase, TripPhase.driving);
    expect(state.custody, hasLength(1));
    expect(state.currentTemperature, inInclusiveRange(3.9, 4.5));
    expect(state.isOffline, isFalse);
    expect(state.inDeadZone, isFalse);
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
    var state = afterDeadZone();
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
    var state = afterDeadZone();
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

  test('telemetry gap freezes the feed and resumes on catch-up', () {
    final state = ScenarioState.initial().setTelemetryGap(true);
    final frozenTemp = state.currentTemperature;
    var advanced = state;
    for (var tick = 0; tick < 5; tick++) {
      advanced = advanced.nextTick();
    }
    expect(advanced.tick, state.tick + 5);
    expect(advanced.lastFeedTick, state.lastFeedTick);
    expect(advanced.currentTemperature, frozenTemp);
    expect(advanced.staleMinutes, 5);

    final resumed = advanced.setTelemetryGap(false);
    expect(resumed.lastFeedTick, resumed.tick);
    expect(resumed.staleMinutes, 0);
  });

  test('triggering an excursion refreshes the sensor feed', () {
    final state = ScenarioState.initial().setTelemetryGap(true);
    final excursion = state.triggerExcursion();
    expect(excursion.lastFeedTick, excursionJumpTick);
    expect(excursion.telemetryGap, isTrue);
  });

  test('failed sync blocks delivery until the item is retried', () {
    var state = afterDeadZone();
    for (var index = 0; index < state.checklist.length; index++) {
      state = state.confirmChecklistRow(index);
    }
    state = state
        .completeChecklist()
        .confirmScan()
        .confirmSeal(defaultSealNumber)
        .captureSignature(Uint8List.fromList([1, 2, 3]), consigneeName)
        .armSyncFailure();

    state = state.nextTick();
    final failed = state.queue.where(
      (item) => item.status == QueueItemStatus.failed,
    );
    expect(failed, hasLength(1));
    expect(state.failNextSync, isFalse);
    expect(state.canDeliver, isFalse);

    state = state.retryItem(failed.single.eventId);
    expect(
      state.queue
          .singleWhere((item) => item.eventId == failed.single.eventId)
          .status,
      QueueItemStatus.pending,
    );

    for (var tick = 0; tick < 12; tick++) {
      state = state.nextTick();
    }
    expect(state.phase, TripPhase.delivered);
    expect(state.epod, isNotNull);
  });

  test('driver actions carry unique event ids shared with custody', () {
    var state = ScenarioState.initial();
    for (var index = 0; index < state.checklist.length; index++) {
      state = state.confirmChecklistRow(index);
    }
    state = state.completeChecklist().confirmScan().confirmSeal(
      defaultSealNumber,
    );

    final queueIds = state.queue.map((item) => item.eventId).toList();
    final custodyIds = state.custody.map((event) => event.eventId).toList();

    expect(queueIds.toSet(), hasLength(queueIds.length));
    expect(custodyIds.toSet(), hasLength(custodyIds.length));
    for (final id in [...queueIds, ...custodyIds]) {
      expect(id, matches(RegExp(r'^EVT-\d{3}$')));
    }
    for (final item in state.queue) {
      expect(
        state.custody.any((event) => event.eventId == item.eventId),
        isTrue,
      );
    }
  });

  test('band preview re-anchors the feed without rewriting history', () {
    final vaccine = ScenarioState.initial();
    final frozen = vaccine.setBand(ProductBand.frozen);
    expect(frozen.bandProfile.productLabel, contains('Frozen'));
    expect(frozen.currentTemperature, inInclusiveRange(-30, -20));
    expect(frozen.checklist.first.reading, vaccine.checklist.first.reading);
    expect(frozen.tick, vaccine.tick);
  });

  test('excursion reading stays frozen across a band preview', () {
    final detected = ScenarioState.initial().triggerExcursion();
    final recorded = detected.excursion!.reading;
    final preview = detected.setBand(ProductBand.crt);
    expect(recorded, 8.9);
    expect(preview.excursion?.reading, recorded);
    expect(preview.currentTemperature, BandProfiles.crt.excursion);
    final detectedEvent = preview.custody.firstWhere(
      (event) => event.title == 'Excursion detected',
    );
    expect(detectedEvent.detail, '8.9 °C near Nashik hub');
  });

  test('the scripted dead zone opens and closes on its own', () {
    var state = ScenarioState.initial();
    while (state.tick < deadZoneStartTick) {
      state = state.nextTick();
    }
    expect(state.tick, deadZoneStartTick);
    expect(state.isOffline, isTrue);
    expect(state.custody.last.title, 'Entered dead zone');
    expect(state.custody.last.source, custodySourceSystem);

    while (state.inDeadZone) {
      state = state.nextTick();
    }
    expect(state.tick, deadZoneEndTick + 1);
    expect(state.isOffline, isFalse);
    expect(state.custody.last.title, 'Back in coverage — syncing');
    expect(state.custody.last.source, custodySourceSystem);
  });

  test('corridor boundaries reconcile across the demo jumps', () {
    final jumped = ScenarioState.initial().triggerExcursion();
    expect(jumped.tick, excursionJumpTick);
    expect(jumped.isOffline, isTrue);
    expect(
      jumped.custody.any((event) => event.title == 'Entered dead zone'),
      isTrue,
    );

    var driving = ScenarioState.initial();
    while (driving.tick < deadZoneStartTick) {
      driving = driving.nextTick();
    }
    final out = driving.jumpToOutForDelivery();
    expect(out.tick, outForDeliveryTick);
    expect(out.isOffline, isFalse);
    expect(out.custody.last.title, 'Back in coverage — syncing');
  });

  test('a manual override holds until the next corridor boundary', () {
    var state = ScenarioState.initial();
    while (state.tick < deadZoneStartTick) {
      state = state.nextTick();
    }
    expect(state.isOffline, isTrue);

    state = state.setOffline(false);
    expect(state.isOffline, isFalse);
    final next = state.nextTick();
    expect(next.isOffline, isFalse);
    expect(next.offlineAuto, isTrue);

    while (state.inDeadZone) {
      state = state.nextTick();
    }
    expect(state.tick, deadZoneEndTick + 1);
    expect(state.isOffline, isFalse);
    expect(state.custody.last.title, 'Back in coverage — syncing');
  });

  test('delivery note is captured and carried onto the e-POD', () {
    var state = afterDeadZone();
    for (var index = 0; index < state.checklist.length; index++) {
      state = state.confirmChecklistRow(index);
    }
    state = state
        .completeChecklist()
        .confirmScan()
        .confirmSeal(defaultSealNumber)
        .captureSignature(
          Uint8List.fromList([1, 2, 3]),
          consigneeName,
          deliveryNote: 'Access delay',
        );
    expect(
      state.custody.any((event) => event.title == 'Delivery note'),
      isTrue,
    );
    for (var tick = 0; tick < 8; tick++) {
      state = state.nextTick();
    }
    expect(state.epod?.deliveryNote, 'Access delay');
  });
}
