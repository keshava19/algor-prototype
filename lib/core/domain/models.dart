import 'dart:typed_data';

enum TripPhase { driving, excursionActive, excursionAcknowledged, delivered }

enum QueueItemStatus { pending, syncing, synced }

typedef CapturedSignature = ({Uint8List bytes, String name, int tick});

sealed class QueueItem {
  const QueueItem({required this.status, required this.capturedTick});

  final QueueItemStatus status;
  final int capturedTick;

  String get label;

  QueueItem withStatus(QueueItemStatus status);
}

final class ChecklistQueued extends QueueItem {
  const ChecklistQueued({required super.status, required super.capturedTick});

  @override
  String get label => 'Pre-trip checklist';

  @override
  QueueItem withStatus(QueueItemStatus status) =>
      ChecklistQueued(status: status, capturedTick: capturedTick);
}

final class ScanQueued extends QueueItem {
  const ScanQueued({required super.status, required super.capturedTick});

  @override
  String get label => 'AWB scan';

  @override
  QueueItem withStatus(QueueItemStatus status) =>
      ScanQueued(status: status, capturedTick: capturedTick);
}

final class SealPhotoQueued extends QueueItem {
  const SealPhotoQueued({required super.status, required super.capturedTick});

  @override
  String get label => 'Seal photo';

  @override
  QueueItem withStatus(QueueItemStatus status) =>
      SealPhotoQueued(status: status, capturedTick: capturedTick);
}

final class ChecklistEntry {
  const ChecklistEntry({
    required this.title,
    required this.reading,
    this.confirmed = false,
    this.confirmedTick,
  });

  final String title;
  final String reading;
  final bool confirmed;
  final int? confirmedTick;

  ChecklistEntry copyWith({bool? confirmed, int? confirmedTick}) =>
      ChecklistEntry(
        title: title,
        reading: reading,
        confirmed: confirmed ?? this.confirmed,
        confirmedTick: confirmedTick ?? this.confirmedTick,
      );
}

final class CustodyEvent {
  const CustodyEvent({required this.title, required this.tick, this.detail});

  final String title;
  final int tick;
  final String? detail;
}

final class ExcursionEvent {
  const ExcursionEvent({
    required this.startedTick,
    required this.location,
    this.reasonCode,
    this.note,
    this.acknowledgedTick,
    this.escalated = false,
  });

  final int startedTick;
  final String location;
  final String? reasonCode;
  final String? note;
  final int? acknowledgedTick;
  final bool escalated;

  ExcursionEvent copyWith({
    String? reasonCode,
    String? note,
    int? acknowledgedTick,
    bool? escalated,
  }) => ExcursionEvent(
    startedTick: startedTick,
    location: location,
    reasonCode: reasonCode ?? this.reasonCode,
    note: note ?? this.note,
    acknowledgedTick: acknowledgedTick ?? this.acknowledgedTick,
    escalated: escalated ?? this.escalated,
  );
}

final class TempReading {
  const TempReading(this.tick, this.celsius);

  final int tick;
  final double celsius;
}

final class EPod {
  const EPod({
    required this.consigneeName,
    required this.sealNumber,
    required this.deliveredTick,
    this.signatureBytes,
  });

  final String consigneeName;
  final String sealNumber;
  final int deliveredTick;
  final Uint8List? signatureBytes;
}
