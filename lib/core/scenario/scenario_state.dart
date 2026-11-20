import 'dart:typed_data';

import '../domain/fictional_data.dart';
import '../domain/models.dart';
import '../domain/sample_assets.dart';
import '../domain/temperature.dart';

final class ScenarioState {
  const ScenarioState({
    required this.tick,
    required this.phase,
    required this.checklist,
    required this.scanned,
    required this.sealNumber,
    required this.sealVerified,
    required this.signature,
    required this.isOffline,
    required this.queue,
    required this.epod,
    required this.excursion,
    required this.escalationSecondsLeft,
    required this.escalationDuration,
    required this.driftStartedTick,
    required this.custody,
  });

  factory ScenarioState.initial() => ScenarioState(
    tick: initialTick,
    phase: TripPhase.driving,
    checklist: defaultChecklist,
    scanned: false,
    sealNumber: '',
    sealVerified: false,
    signature: null,
    isOffline: false,
    queue: const [],
    epod: null,
    excursion: null,
    escalationSecondsLeft: 0,
    escalationDuration: defaultEscalationSeconds,
    driftStartedTick: null,
    custody: const [
      CustodyEvent(title: 'Dispatched', tick: 0, detail: 'Mumbai (BOM)'),
    ],
  );

  factory ScenarioState.sampleDelivered({Uint8List? signatureBytes}) =>
      ScenarioState(
        tick: deliveredTick,
        phase: TripPhase.delivered,
        checklist: [
          for (final item in defaultChecklist)
            item.copyWith(confirmed: true, confirmedTick: 8),
        ],
        scanned: true,
        sealNumber: defaultSealNumber,
        sealVerified: true,
        signature: signatureBytes == null
            ? null
            : (bytes: signatureBytes, name: consigneeName, tick: 1052),
        isOffline: false,
        queue: const [
          ChecklistQueued(status: QueueItemStatus.synced, capturedTick: 8),
          ScanQueued(status: QueueItemStatus.synced, capturedTick: 10),
          SealPhotoQueued(status: QueueItemStatus.synced, capturedTick: 12),
        ],
        epod: EPod(
          consigneeName: consigneeName,
          sealNumber: defaultSealNumber,
          deliveredTick: 1053,
          signatureBytes: signatureBytes,
        ),
        excursion: const ExcursionEvent(
          startedTick: 130,
          location: 'Near Nashik hub · MH 04 KF 4001',
          reasonCode: 'Compressor reset',
          acknowledgedTick: 131,
        ),
        escalationSecondsLeft: 0,
        escalationDuration: defaultEscalationSeconds,
        driftStartedTick: 116,
        custody: canonicalCustody,
      );

  final int tick;
  final TripPhase phase;
  final List<ChecklistEntry> checklist;
  final bool scanned;
  final String sealNumber;
  final bool sealVerified;
  final CapturedSignature? signature;
  final bool isOffline;
  final List<QueueItem> queue;
  final EPod? epod;
  final ExcursionEvent? excursion;
  final int escalationSecondsLeft;
  final int escalationDuration;
  final int? driftStartedTick;
  final List<CustodyEvent> custody;

  double get currentTemperature => temperatureAt(
    tick,
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
    TripPhase? phase,
    List<ChecklistEntry>? checklist,
    bool? scanned,
    String? sealNumber,
    bool? sealVerified,
    CapturedSignature? signature,
    bool? isOffline,
    List<QueueItem>? queue,
    EPod? epod,
    ExcursionEvent? excursion,
    int? escalationSecondsLeft,
    int? escalationDuration,
    int? driftStartedTick,
    List<CustodyEvent>? custody,
    bool clearExcursion = false,
  }) => ScenarioState(
    tick: tick ?? this.tick,
    phase: phase ?? this.phase,
    checklist: checklist ?? this.checklist,
    scanned: scanned ?? this.scanned,
    sealNumber: sealNumber ?? this.sealNumber,
    sealVerified: sealVerified ?? this.sealVerified,
    signature: signature ?? this.signature,
    isOffline: isOffline ?? this.isOffline,
    queue: queue ?? this.queue,
    epod: epod ?? this.epod,
    excursion: clearExcursion ? null : (excursion ?? this.excursion),
    escalationSecondsLeft: escalationSecondsLeft ?? this.escalationSecondsLeft,
    escalationDuration: escalationDuration ?? this.escalationDuration,
    driftStartedTick: driftStartedTick ?? this.driftStartedTick,
    custody: custody ?? this.custody,
  );

  ScenarioState nextTick() {
    if (phase == TripPhase.delivered) return this;
    return copyWith(tick: tick + 1)
        ._syncStep()
        ._escalationStep()
        ._autoDeliver();
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
    return copyWith(
      queue: [
        ...queue,
        ChecklistQueued(status: QueueItemStatus.pending, capturedTick: tick),
      ],
      custody: [
        ...custody,
        CustodyEvent(title: 'Pre-trip checklist confirmed', tick: tick),
      ],
    );
  }

  ScenarioState confirmScan() {
    if (scanned || phase == TripPhase.delivered) return this;
    return copyWith(
      scanned: true,
      queue: [
        ...queue,
        ScanQueued(status: QueueItemStatus.pending, capturedTick: tick),
      ],
      custody: [
        ...custody,
        CustodyEvent(title: 'AWB scanned', tick: tick, detail: awbLabel),
      ],
    );
  }

  ScenarioState confirmSeal(String number) {
    if (sealVerified || phase == TripPhase.delivered) return this;
    return copyWith(
      sealNumber: number,
      sealVerified: true,
      queue: [
        ...queue,
        SealPhotoQueued(status: QueueItemStatus.pending, capturedTick: tick),
      ],
      custody: [
        ...custody,
        CustodyEvent(title: 'Seal verified', tick: tick, detail: number),
      ],
    );
  }

  ScenarioState captureSignature(Uint8List bytes, String name) {
    if (bytes.isEmpty || phase == TripPhase.delivered) return this;
    return copyWith(signature: (bytes: bytes, name: name, tick: tick));
  }

  ScenarioState setOffline(bool value) => copyWith(isOffline: value);

  ScenarioState startDrift() {
    if (phase != TripPhase.driving || driftStartedTick != null) return this;
    return copyWith(driftStartedTick: tick);
  }

  ScenarioState triggerExcursion() {
    if (phase != TripPhase.driving) return this;
    final jumpTick = tick < excursionJumpTick ? excursionJumpTick : tick;
    final driftFrom = driftStartedTick ?? (jumpTick > 14 ? jumpTick - 14 : 0);
    return copyWith(
      tick: jumpTick,
      phase: TripPhase.excursionActive,
      driftStartedTick: driftFrom,
      excursion: ExcursionEvent(
        startedTick: jumpTick,
        location: excursionLocation,
      ),
      escalationSecondsLeft: escalationDuration,
      custody: [
        ...custody,
        CustodyEvent(
          title: 'Excursion detected',
          tick: jumpTick,
          detail: '8.9 °C near Nashik hub',
        ),
      ],
    );
  }

  ScenarioState acknowledge({
    String reasonCode = 'Driver acknowledged',
    String? note,
  }) {
    if (phase != TripPhase.excursionActive) return this;
    final trimmedNote = note?.trim();
    return copyWith(
      phase: TripPhase.excursionAcknowledged,
      excursion: excursion!.copyWith(
        reasonCode: reasonCode,
        note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
        acknowledgedTick: tick,
      ),
      escalationSecondsLeft: 0,
      custody: [
        ...custody,
        CustodyEvent(
          title: 'Excursion acknowledged',
          tick: tick,
          detail: trimmedNote == null || trimmedNote.isEmpty
              ? reasonCode
              : '$reasonCode — $trimmedNote',
        ),
      ],
    );
  }

  ScenarioState callControlRoom() => recordCall('Control room called');

  ScenarioState recordCall(String title) => copyWith(
    custody: [
      ...custody,
      CustodyEvent(title: title, tick: tick, detail: controlRoomNote),
    ],
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
    return copyWith(
      tick: jumpTick,
      custody: [
        ...custody,
        CustodyEvent(title: 'Out for delivery', tick: jumpTick),
      ],
    );
  }

  ScenarioState jumpToDelivered() {
    if (phase == TripPhase.delivered) return this;
    return ScenarioState.sampleDelivered(
      signatureBytes: SampleAssets.signaturePng,
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
      custody: [
        ...custody,
        CustodyEvent(title: 'Escalated — control room notified', tick: tick),
      ],
    );
  }

  ScenarioState _autoDeliver() {
    if (phase == TripPhase.delivered) return this;
    if (!canDeliver) return this;
    return copyWith(
      phase: TripPhase.delivered,
      epod: EPod(
        consigneeName: consigneeName,
        sealNumber: sealNumber,
        deliveredTick: tick,
        signatureBytes: signature!.bytes,
      ),
      custody: [
        ...custody,
        CustodyEvent(
          title: 'Delivered · e-POD generated · Sent for invoicing',
          tick: tick,
        ),
      ],
    );
  }
}
