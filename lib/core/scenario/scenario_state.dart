import 'dart:typed_data';

import '../domain/band.dart';
import '../domain/fictional_data.dart';
import '../domain/models.dart';
import '../domain/sample_assets.dart';
import '../domain/temperature.dart';

final class ScenarioState {
  const ScenarioState({
    required this.tick,
    required this.lastFeedTick,
    required this.telemetryGap,
    required this.phase,
    required this.band,
    required this.checklist,
    required this.scanned,
    required this.sealNumber,
    required this.sealVerified,
    required this.signature,
    required this.isOffline,
    required this.offlineAuto,
    required this.queue,
    required this.failNextSync,
    required this.epod,
    required this.excursion,
    required this.escalationSecondsLeft,
    required this.escalationDuration,
    required this.driftStartedTick,
    required this.custody,
    required this.eventSeq,
  });

  factory ScenarioState.initial() => ScenarioState(
    tick: initialTick,
    lastFeedTick: initialTick,
    telemetryGap: false,
    phase: TripPhase.driving,
    band: ProductBand.vaccine,
    checklist: defaultChecklist,
    scanned: false,
    sealNumber: '',
    sealVerified: false,
    signature: null,
    isOffline: false,
    offlineAuto: false,
    queue: const [],
    failNextSync: false,
    epod: null,
    excursion: null,
    escalationSecondsLeft: 0,
    escalationDuration: defaultEscalationSeconds,
    driftStartedTick: null,
    custody: const [
      CustodyEvent(
        eventId: 'EVT-001',
        title: 'Dispatched',
        tick: 0,
        detail: 'Mumbai (BOM)',
        source: custodySourceSystem,
      ),
    ],
    eventSeq: 1,
  );

  factory ScenarioState.sampleDelivered({Uint8List? signatureBytes}) =>
      ScenarioState(
        tick: deliveredTick,
        lastFeedTick: deliveredTick,
        telemetryGap: false,
        phase: TripPhase.delivered,
        band: ProductBand.vaccine,
        checklist: [
          for (final item in defaultChecklist)
            item.copyWith(confirmed: true, confirmedTick: 8),
        ],
        scanned: true,
        sealNumber: defaultSealNumber,
        sealVerified: true,
        signature: signatureBytes == null
            ? null
            : (
                bytes: signatureBytes,
                name: consigneeName,
                tick: 1052,
                deliveryNote: null,
              ),
        isOffline: false,
        offlineAuto: false,
        queue: const [
          ChecklistQueued(
            eventId: 'EVT-002',
            status: QueueItemStatus.synced,
            capturedTick: 8,
          ),
          ScanQueued(
            eventId: 'EVT-003',
            status: QueueItemStatus.synced,
            capturedTick: 10,
          ),
          SealPhotoQueued(
            eventId: 'EVT-004',
            status: QueueItemStatus.synced,
            capturedTick: 12,
          ),
        ],
        failNextSync: false,
        epod: EPod(
          consigneeName: consigneeName,
          sealNumber: defaultSealNumber,
          deliveredTick: 1053,
          signatureBytes: signatureBytes,
        ),
        excursion: const ExcursionEvent(
          startedTick: 130,
          reading: 8.9,
          rangeLabel: '2–8',
          location: 'Near Nashik hub · MH 04 KF 4001',
          reasonCode: 'Compressor reset',
          acknowledgedTick: 131,
        ),
        escalationSecondsLeft: 0,
        escalationDuration: defaultEscalationSeconds,
        driftStartedTick: 116,
        custody: canonicalCustody,
        eventSeq: 8,
      );

  final int tick;
  final int lastFeedTick;
  final bool telemetryGap;
  final TripPhase phase;
  final ProductBand band;
  final List<ChecklistEntry> checklist;
  final bool scanned;
  final String sealNumber;
  final bool sealVerified;
  final CapturedSignature? signature;
  final bool isOffline;
  final bool offlineAuto;
  final List<QueueItem> queue;
  final bool failNextSync;
  final EPod? epod;
  final ExcursionEvent? excursion;
  final int escalationSecondsLeft;
  final int escalationDuration;
  final int? driftStartedTick;
  final List<CustodyEvent> custody;
  final int eventSeq;

  BandProfile get bandProfile => BandProfiles.of(band);

  int get staleMinutes => tick - lastFeedTick;

  bool get inDeadZone => tick >= deadZoneStartTick && tick <= deadZoneEndTick;

  double get currentTemperature => temperatureAt(
    lastFeedTick,
    band: bandProfile,
    driftFrom: driftStartedTick,
    acknowledgedAt: excursion?.acknowledgedTick,
    pinFromTick: phase == TripPhase.excursionActive
        ? excursion?.startedTick
        : null,
  );

  bool get canDeliver =>
      signature != null &&
      !isOffline &&
      queue.length == 3 &&
      (phase == TripPhase.driving ||
          phase == TripPhase.excursionAcknowledged) &&
      queue.every((item) => item.status == QueueItemStatus.synced);

  ScenarioState copyWith({
    int? tick,
    int? lastFeedTick,
    bool? telemetryGap,
    TripPhase? phase,
    ProductBand? band,
    List<ChecklistEntry>? checklist,
    bool? scanned,
    String? sealNumber,
    bool? sealVerified,
    CapturedSignature? signature,
    bool? isOffline,
    bool? offlineAuto,
    List<QueueItem>? queue,
    bool? failNextSync,
    EPod? epod,
    ExcursionEvent? excursion,
    int? escalationSecondsLeft,
    int? escalationDuration,
    int? driftStartedTick,
    List<CustodyEvent>? custody,
    int? eventSeq,
    bool clearExcursion = false,
  }) => ScenarioState(
    tick: tick ?? this.tick,
    lastFeedTick: lastFeedTick ?? this.lastFeedTick,
    telemetryGap: telemetryGap ?? this.telemetryGap,
    phase: phase ?? this.phase,
    band: band ?? this.band,
    checklist: checklist ?? this.checklist,
    scanned: scanned ?? this.scanned,
    sealNumber: sealNumber ?? this.sealNumber,
    sealVerified: sealVerified ?? this.sealVerified,
    signature: signature ?? this.signature,
    isOffline: isOffline ?? this.isOffline,
    offlineAuto: offlineAuto ?? this.offlineAuto,
    queue: queue ?? this.queue,
    failNextSync: failNextSync ?? this.failNextSync,
    epod: epod ?? this.epod,
    excursion: clearExcursion ? null : (excursion ?? this.excursion),
    escalationSecondsLeft: escalationSecondsLeft ?? this.escalationSecondsLeft,
    escalationDuration: escalationDuration ?? this.escalationDuration,
    driftStartedTick: driftStartedTick ?? this.driftStartedTick,
    custody: custody ?? this.custody,
    eventSeq: eventSeq ?? this.eventSeq,
  );

  ScenarioState nextTick() {
    if (phase == TripPhase.delivered) return this;
    final next = tick + 1;
    return copyWith(
      tick: next,
      lastFeedTick: telemetryGap ? lastFeedTick : next,
    )._corridorStep()._syncStep()._escalationStep()._autoDeliver();
  }

  String _nextEventId() => 'EVT-${(eventSeq + 1).toString().padLeft(3, '0')}';

  ScenarioState _appendCustody(
    String title, {
    String? detail,
    int? atTick,
    String source = custodySourceDriver,
    String? actor,
  }) {
    final id = _nextEventId();
    return copyWith(
      eventSeq: eventSeq + 1,
      custody: [
        ...custody,
        CustodyEvent(
          eventId: id,
          title: title,
          tick: atTick ?? tick,
          detail: detail,
          source: source,
          actor: actor,
        ),
      ],
    );
  }

  ScenarioState confirmChecklistRow(int index) {
    if (phase == TripPhase.delivered) return this;
    final updated = [...checklist];
    if (index < 0 || index >= updated.length) return this;
    if (updated[index].confirmed) return this;
    updated[index] = updated[index].copyWith(
      confirmed: true,
      confirmedTick: tick,
    );
    return copyWith(checklist: updated);
  }

  ScenarioState completeChecklist() {
    if (phase == TripPhase.delivered) return this;
    if (!checklist.every((item) => item.confirmed)) return this;
    if (queue.any((item) => item is ChecklistQueued)) return this;
    final id = _nextEventId();
    return copyWith(
      eventSeq: eventSeq + 1,
      queue: [
        ...queue,
        ChecklistQueued(
          eventId: id,
          status: QueueItemStatus.pending,
          capturedTick: tick,
        ),
      ],
      custody: [
        ...custody,
        CustodyEvent(
          eventId: id,
          title: 'Pre-trip checklist confirmed',
          tick: tick,
          source: custodySourceDriver,
          actor: driverName,
        ),
      ],
    );
  }

  ScenarioState confirmScan() {
    if (scanned || phase == TripPhase.delivered) return this;
    final id = _nextEventId();
    return copyWith(
      scanned: true,
      eventSeq: eventSeq + 1,
      queue: [
        ...queue,
        ScanQueued(
          eventId: id,
          status: QueueItemStatus.pending,
          capturedTick: tick,
        ),
      ],
      custody: [
        ...custody,
        CustodyEvent(
          eventId: id,
          title: 'AWB scanned',
          tick: tick,
          detail: awbLabel,
          source: custodySourceDriver,
          actor: driverName,
        ),
      ],
    );
  }

  ScenarioState confirmSeal(String number) {
    if (sealVerified || phase == TripPhase.delivered) return this;
    final id = _nextEventId();
    return copyWith(
      sealNumber: number,
      sealVerified: true,
      eventSeq: eventSeq + 1,
      queue: [
        ...queue,
        SealPhotoQueued(
          eventId: id,
          status: QueueItemStatus.pending,
          capturedTick: tick,
        ),
      ],
      custody: [
        ...custody,
        CustodyEvent(
          eventId: id,
          title: 'Seal verified',
          tick: tick,
          detail: number,
          source: custodySourceDriver,
          actor: driverName,
        ),
      ],
    );
  }

  ScenarioState captureSignature(
    Uint8List bytes,
    String name, {
    String? deliveryNote,
  }) {
    if (bytes.isEmpty || phase == TripPhase.delivered) return this;
    final note = deliveryNote?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final captured = (
      bytes: bytes,
      name: name,
      tick: tick,
      deliveryNote: hasNote ? note : null,
    );
    if (!hasNote) return copyWith(signature: captured);
    final id = _nextEventId();
    return copyWith(
      signature: captured,
      eventSeq: eventSeq + 1,
      custody: [
        ...custody,
        CustodyEvent(
          eventId: id,
          title: 'Delivery note',
          tick: tick,
          detail: note,
          source: custodySourceDriver,
          actor: consigneeName,
        ),
      ],
    );
  }

  ScenarioState setOffline(bool value) =>
      copyWith(isOffline: value, offlineAuto: inDeadZone);

  ScenarioState setBand(ProductBand value) => copyWith(band: value);

  ScenarioState setTelemetryGap(bool value) =>
      copyWith(telemetryGap: value, lastFeedTick: value ? lastFeedTick : tick);

  ScenarioState armSyncFailure() => copyWith(failNextSync: true);

  ScenarioState retryItem(String eventId) {
    final index = queue.indexWhere(
      (item) =>
          item.eventId == eventId && item.status == QueueItemStatus.failed,
    );
    if (index < 0) return this;
    final updated = [...queue];
    updated[index] = updated[index].withStatus(QueueItemStatus.pending);
    return copyWith(queue: updated);
  }

  ScenarioState startDrift() {
    if (phase != TripPhase.driving || driftStartedTick != null) return this;
    return copyWith(driftStartedTick: tick);
  }

  ScenarioState triggerExcursion() {
    if (phase != TripPhase.driving) return this;
    final jumpTick = tick < excursionJumpTick ? excursionJumpTick : tick;
    final driftFrom = driftStartedTick ?? (jumpTick > 14 ? jumpTick - 14 : 0);
    final id = _nextEventId();
    return copyWith(
      tick: jumpTick,
      lastFeedTick: jumpTick,
      phase: TripPhase.excursionActive,
      driftStartedTick: driftFrom,
      eventSeq: eventSeq + 1,
      excursion: ExcursionEvent(
        startedTick: jumpTick,
        reading: bandProfile.excursion,
        rangeLabel: bandProfile.rangeLabel,
        location: excursionLocation,
      ),
      escalationSecondsLeft: escalationDuration,
      custody: [
        ...custody,
        CustodyEvent(
          eventId: id,
          title: 'Excursion detected',
          tick: jumpTick,
          detail:
              '${bandProfile.excursion.toStringAsFixed(1)} °C near Nashik hub',
          source: custodySourceSensor,
        ),
      ],
    )._corridorStep();
  }

  ScenarioState acknowledge({
    String reasonCode = 'Driver acknowledged',
    String? note,
  }) {
    if (phase != TripPhase.excursionActive) return this;
    final trimmedNote = note?.trim();
    final id = _nextEventId();
    return copyWith(
      phase: TripPhase.excursionAcknowledged,
      eventSeq: eventSeq + 1,
      excursion: excursion!.copyWith(
        reasonCode: reasonCode,
        note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
        acknowledgedTick: tick,
      ),
      escalationSecondsLeft: 0,
      custody: [
        ...custody,
        CustodyEvent(
          eventId: id,
          title: 'Excursion acknowledged',
          tick: tick,
          detail: trimmedNote == null || trimmedNote.isEmpty
              ? reasonCode
              : '$reasonCode — $trimmedNote',
          source: custodySourceDriver,
          actor: driverName,
        ),
      ],
    );
  }

  ScenarioState callControlRoom() => recordCall('Control room called');

  ScenarioState recordCall(
    String title, {
    String source = custodySourceDriver,
    String? actor,
  }) => _appendCustody(
    title,
    detail: controlRoomNote,
    source: source,
    actor: actor,
  );

  ScenarioState smsControlRoom() => _appendCustody(
    'Control room SMS sent',
    detail: smsControlRoomNote,
    actor: driverName,
  );

  ScenarioState setEscalationDuration(int seconds) {
    if (phase == TripPhase.excursionActive) return this;
    return copyWith(escalationDuration: seconds);
  }

  ScenarioState jumpToOutForDelivery() {
    if (phase == TripPhase.delivered ||
        phase == TripPhase.excursionActive ||
        epod != null) {
      return this;
    }
    final jumpTick = tick < outForDeliveryTick ? outForDeliveryTick : tick;
    final id = _nextEventId();
    return copyWith(
      tick: jumpTick,
      lastFeedTick: jumpTick,
      telemetryGap: false,
      eventSeq: eventSeq + 1,
      custody: [
        ...custody,
        CustodyEvent(
          eventId: id,
          title: 'Out for delivery',
          tick: jumpTick,
          source: custodySourceDriver,
          actor: driverName,
        ),
      ],
    )._corridorStep();
  }

  ScenarioState jumpToDelivered() {
    if (phase == TripPhase.delivered) return this;
    return ScenarioState.sampleDelivered(
      signatureBytes: SampleAssets.signaturePng,
    );
  }

  ScenarioState _corridorStep() {
    final auto = inDeadZone;
    if (auto == offlineAuto) return this;
    return copyWith(isOffline: auto, offlineAuto: auto)._appendCustody(
      auto ? 'Entered dead zone' : 'Back in coverage — syncing',
      detail: auto
          ? 'Ghat section — no data coverage'
          : 'Evidence queue draining',
      source: custodySourceSystem,
    );
  }

  ScenarioState _syncStep() {
    if (isOffline) return this;
    final syncingIndex = queue.indexWhere(
      (item) => item.status == QueueItemStatus.syncing,
    );
    if (syncingIndex >= 0) {
      final updated = [...queue];
      updated[syncingIndex] = updated[syncingIndex].withStatus(
        QueueItemStatus.synced,
      );
      return copyWith(queue: updated);
    }
    final pendingIndex = queue.indexWhere(
      (item) => item.status == QueueItemStatus.pending,
    );
    if (pendingIndex >= 0) {
      final updated = [...queue];
      if (failNextSync) {
        updated[pendingIndex] = updated[pendingIndex].withStatus(
          QueueItemStatus.failed,
        );
        return copyWith(queue: updated, failNextSync: false);
      }
      updated[pendingIndex] = updated[pendingIndex].withStatus(
        QueueItemStatus.syncing,
      );
      return copyWith(queue: updated);
    }
    return this;
  }

  ScenarioState _escalationStep() {
    if (phase != TripPhase.excursionActive) return this;
    if (escalationSecondsLeft > 1) {
      return copyWith(escalationSecondsLeft: escalationSecondsLeft - 1);
    }
    if (excursion!.escalated) {
      return copyWith(escalationSecondsLeft: 0);
    }
    return copyWith(
      escalationSecondsLeft: 0,
      excursion: excursion!.copyWith(escalated: true),
    )._appendCustody(
      'Escalated — control room notified',
      source: custodySourceSystem,
    );
  }

  ScenarioState _autoDeliver() {
    if (phase == TripPhase.delivered) return this;
    if (!canDeliver) return this;
    final id = _nextEventId();
    return copyWith(
      phase: TripPhase.delivered,
      eventSeq: eventSeq + 1,
      epod: EPod(
        consigneeName: consigneeName,
        sealNumber: sealNumber,
        deliveredTick: tick,
        signatureBytes: signature!.bytes,
        deliveryNote: signature!.deliveryNote,
      ),
      custody: [
        ...custody,
        CustodyEvent(
          eventId: id,
          title: 'Delivered · e-POD generated · Sent for invoicing',
          tick: tick,
          source: custodySourceSystem,
        ),
      ],
    );
  }
}
