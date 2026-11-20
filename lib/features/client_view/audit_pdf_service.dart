import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/domain/fictional_data.dart';
import '../../core/domain/models.dart';
import '../../core/domain/temperature.dart';
import '../../core/scenario/scenario_state.dart';
import '../../core/util/formatters.dart';

const auditPdfFileName = 'algor-field-audit-172-45678901.pdf';

final _navy = PdfColor.fromInt(0xFF0A2540);
final _cyan = PdfColor.fromInt(0xFF00C2D1);
final _grey = PdfColor.fromInt(0xFF5B6B7C);
final _success = PdfColor.fromInt(0xFF22C55E);
final _danger = PdfColor.fromInt(0xFFE5484D);

Future<(pw.Font, pw.Font)>? _fonts;

Future<(pw.Font, pw.Font)> _loadFonts() => _fonts ??= () async {
  final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
  return (pw.Font.ttf(regular), pw.Font.ttf(bold));
}();

List<TempReading> fullTripReadings(ScenarioState state) => readingsBetween(
  0,
  state.tick,
  driftFrom: state.driftStartedTick,
  acknowledgedAt: state.excursion?.acknowledgedTick,
  pinFromTick: state.phase == TripPhase.excursionActive
      ? state.excursion?.startedTick
      : null,
);

Future<void> shareAuditPdf(ScenarioState state) async {
  final bytes = await buildAuditPdf(state);
  await Printing.sharePdf(bytes: bytes, filename: auditPdfFileName);
}

Future<Uint8List> buildAuditPdf(ScenarioState state) async {
  final (regular, bold) = await _loadFonts();
  final theme = pw.ThemeData.withFont(base: regular, bold: bold);
  final readings = fullTripReadings(state);
  final doc = pw.Document(theme: theme);
  final generatedAt = formatDateTime(state.tick);

  pw.Widget footer(pw.Context context) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 10),
    padding: const pw.EdgeInsets.only(top: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: PdfColors.grey300, width: 0.6),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          conceptFooterText,
          style: pw.TextStyle(fontSize: 7, color: _grey),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 7, color: _grey),
        ),
      ],
    ),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 34),
      footer: footer,
      build: (context) => [
        _header(state),
        pw.SizedBox(height: 18),
        _sectionTitle('Shipment'),
        _keyValueTable([
          ('AWB', awbNumber),
          ('Lane', laneLabel.replaceAll('→', '–')),
          ('Product', productLabel),
          ('Vehicle', vehiclePlate),
          ('Driver', driverName),
          ('Consignee', consigneeHub),
          (
            'Seal',
            state.sealNumber.isEmpty ? defaultSealNumber : state.sealNumber,
          ),
          ('Logger', '$loggerId · calibrated Oct 2026'),
          ('Status', _phaseLabel(state.phase)),
        ]),
        pw.SizedBox(height: 18),
        _sectionTitle('Temperature history — full trip'),
        _statsRow(readings),
        pw.SizedBox(height: 10),
        _curve(readings),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Start ${formatClock(0)} · End ${formatClock(state.tick)} · '
              'green band 2–8 °C',
              style: pw.TextStyle(fontSize: 7.5, color: _grey),
            ),
            pw.Text(
              'MKT ${formatTemp(meanKineticTemperature(readings))}',
              style: pw.TextStyle(fontSize: 7.5, color: _grey),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        _sectionTitle('Excursion record'),
        _excursionTable(state),
        pw.SizedBox(height: 18),
        _sectionTitle('Custody trail'),
        _custodyTable(state),
        if (state.phase == TripPhase.delivered) ...[
          pw.NewPage(),
          _sectionTitle('Electronic proof of delivery'),
          _epodBlock(state),
          pw.SizedBox(height: 22),
          _sectionTitle('Capture verification'),
          _captureTable(state),
          pw.SizedBox(height: 22),
          _sectionTitle('Report notes'),
          for (final note in const [
            'Temperature readings are recorded every scenario minute and '
                'plotted across the full trip.',
            'Custody events are append-only; each entry records the actor, '
                'action and scenario timestamp.',
            'The consignee signature and e-POD are generated on the driver '
                'device and queued until connectivity returns.',
          ])
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 12,
                    child: pw.Text(
                      '–',
                      style: pw.TextStyle(fontSize: 9, color: _grey),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      note,
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: _grey,
                        lineSpacing: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF2F6F9),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            'Concept document prepared for Algor Supply Chain Solutions. '
            'This report supports GDP documentation; it is not a certificate '
            'of compliance. Shipment, driver, vehicle and consignee details '
            'are fictional. Generated $generatedAt IST.',
            style: pw.TextStyle(fontSize: 8, color: _grey, lineSpacing: 1.4),
          ),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _header(ScenarioState state) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ALGOR FIELD (CONCEPT)',
              style: pw.TextStyle(
                fontSize: 9,
                letterSpacing: 1.6,
                color: _cyan,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Shipment audit summary',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              awbLabel,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
              ),
            ),
            pw.Text(
              '$scenarioDateLabel · Mumbai – Delhi',
              style: pw.TextStyle(fontSize: 8.5, color: _grey),
            ),
          ],
        ),
      ],
    ),
    pw.SizedBox(height: 8),
    pw.Container(height: 2, color: _navy),
    pw.SizedBox(height: 2),
    pw.Container(height: 2, color: _cyan),
  ],
);

pw.Widget _sectionTitle(String title) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 6),
  child: pw.Text(
    title.toUpperCase(),
    style: pw.TextStyle(
      fontSize: 9,
      letterSpacing: 1.1,
      fontWeight: pw.FontWeight.bold,
      color: _navy,
    ),
  ),
);

pw.Widget _keyValueTable(List<(String, String)> rows) {
  final cells = <pw.Widget>[];
  for (var index = 0; index < rows.length; index += 2) {
    final left = rows[index];
    final right = index + 1 < rows.length ? rows[index + 1] : null;
    cells.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _keyValue(left.$1, left.$2)),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: right == null
                ? pw.SizedBox()
                : _keyValue(right.$1, right.$2),
          ),
        ],
      ),
    );
  }
  return pw.Column(children: cells);
}

pw.Widget _keyValue(String key, String value) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 3),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 62,
        child: pw.Text(key, style: pw.TextStyle(fontSize: 8.5, color: _grey)),
      ),
      pw.Expanded(
        child: pw.Text(
          value,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.black),
        ),
      ),
    ],
  ),
);

pw.Widget _statsRow(List<TempReading> readings) {
  final values = [for (final reading in readings) reading.celsius];
  final minTemp = values.reduce(min);
  final maxTemp = values.reduce(max);
  final mean = values.reduce((a, b) => a + b) / values.length;
  final inBand = values.where((value) => value >= bandMin && value <= bandMax);
  final percent = values.isEmpty ? 0.0 : inBand.length / values.length * 100;
  return pw.Row(
    children: [
      for (final stat in [
        ('Min', formatTemp(minTemp)),
        ('Max', formatTemp(maxTemp)),
        ('Mean', formatTemp(mean)),
        ('MKT', formatTemp(meanKineticTemperature(readings))),
        ('In band', '${percent.toStringAsFixed(1)}%'),
      ])
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(right: 6),
            padding: const pw.EdgeInsets.symmetric(vertical: 7),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF2F6F9),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  stat.$1,
                  style: pw.TextStyle(fontSize: 7, color: _grey),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  stat.$2,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

pw.Widget _curve(List<TempReading> readings) {
  final step = max(1, (readings.length / 240).ceil());
  final points = [
    for (var index = 0; index < readings.length; index += step) readings[index],
  ];
  if (points.isEmpty || points.last.tick != readings.last.tick) {
    points.add(readings.last);
  }
  return pw.Container(
    height: 150,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
      borderRadius: pw.BorderRadius.circular(5),
    ),
    padding: const pw.EdgeInsets.fromLTRB(28, 8, 10, 18),
    child: pw.CustomPaint(
      size: const PdfPoint(470, 120),
      painter: (canvas, size) {
        final width = size.x;
        final height = size.y;
        double xFor(int index) =>
            points.length == 1 ? 0 : index / (points.length - 1) * width;
        double yFor(double celsius) => celsius / 10 * height;

        canvas.setFillColor(PdfColor.fromInt(0xFFE7F8EE));
        canvas.drawRect(0, yFor(bandMin), width, yFor(bandMax) - yFor(bandMin));
        canvas.fillPath();

        canvas.setStrokeColor(PdfColors.grey400);
        canvas.setLineWidth(0.5);
        for (var celsius = 0; celsius <= 10; celsius += 2) {
          canvas.moveTo(0, yFor(celsius.toDouble()));
          canvas.lineTo(width, yFor(celsius.toDouble()));
        }
        canvas.strokePath();

        canvas.setStrokeColor(PdfColor.fromInt(0xFFB6C5D2));
        canvas.setLineWidth(0.7);
        for (final celsius in [bandMin, bandMax]) {
          canvas.moveTo(0, yFor(celsius));
          canvas.lineTo(width, yFor(celsius));
        }
        canvas.strokePath();

        canvas.setColor(_cyan);
        canvas.setLineWidth(1.6);
        canvas.moveTo(xFor(0), yFor(points.first.celsius));
        for (var index = 1; index < points.length; index++) {
          canvas.lineTo(xFor(index), yFor(points[index].celsius));
        }
        canvas.strokePath();

        canvas.setFillColor(_danger);
        for (var index = 0; index < points.length; index++) {
          final reading = points[index];
          if (reading.celsius > bandMax) {
            canvas.drawEllipse(xFor(index), yFor(reading.celsius), 2.2, 2.2);
            canvas.fillPath();
          }
        }
      },
    ),
  );
}

pw.Widget _excursionTable(ScenarioState state) {
  final excursion = state.excursion;
  if (excursion == null) {
    return pw.Text(
      'No excursion recorded. The shipment remained inside the 2–8 °C band.',
      style: pw.TextStyle(fontSize: 9, color: _grey),
    );
  }
  return _keyValueTable([
    ('Detected', '${formatClock(excursion.startedTick)} IST'),
    ('Reading', '${excursionTemp.toStringAsFixed(1)} °C'),
    ('Location', excursion.location),
    (
      'Acknowledged',
      excursion.acknowledgedTick == null
          ? 'Pending'
          : '${formatClock(excursion.acknowledgedTick!)} IST',
    ),
    ('Action', excursion.reasonCode ?? 'Pending'),
    ('Note', excursion.note ?? '—'),
    ('Escalation', excursion.escalated ? 'Control room notified' : 'None'),
  ]);
}

pw.Widget _custodyTable(ScenarioState state) => pw.Table(
  border: pw.TableBorder(
    horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
  ),
  columnWidths: const {
    0: pw.FixedColumnWidth(52),
    1: pw.FlexColumnWidth(1.6),
    2: pw.FlexColumnWidth(2.4),
  },
  children: [
    for (final event in state.custody)
      pw.TableRow(
        children: [
          _cell(formatClock(event.tick), grey: true),
          _cell(event.title),
          _cell(event.detail ?? '—', grey: true),
        ],
      ),
  ],
);

pw.Widget _cell(String text, {bool grey = false}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 4),
  child: pw.Text(
    text,
    style: pw.TextStyle(fontSize: 8.5, color: grey ? _grey : PdfColors.black),
  ),
);

pw.Widget _captureTable(ScenarioState state) {
  int? queueTick<T extends QueueItem>() {
    for (final item in state.queue) {
      if (item is T) return item.capturedTick;
    }
    return null;
  }

  String stamp(int? tick) =>
      tick == null ? 'Pending' : '${formatClock(tick)} IST';

  final confirmedTicks = [
    for (final entry in state.checklist)
      if (entry.confirmedTick != null) entry.confirmedTick!,
  ];
  final checklistDone =
      confirmedTicks.length == state.checklist.length &&
      confirmedTicks.isNotEmpty;
  final checklistStamp = checklistDone
      ? stamp(confirmedTicks.reduce(min))
      : '${confirmedTicks.length} of ${state.checklist.length}';

  final rows = <(String, String, String)>[
    (
      'Pre-trip checklist',
      checklistDone ? checklistStamp : 'Incomplete',
      '${confirmedTicks.length} of ${state.checklist.length} rows confirmed',
    ),
    (
      'AWB scan',
      stamp(queueTick<ScanQueued>()),
      state.scanned ? awbNumber : 'Not scanned',
    ),
    (
      'Seal photo',
      stamp(queueTick<SealPhotoQueued>()),
      state.sealVerified ? 'Seal ${state.sealNumber}' : 'Not captured',
    ),
    (
      'Consignee signature',
      stamp(state.signature?.tick),
      state.signature?.name ?? 'Not captured',
    ),
    (
      'e-POD',
      stamp(state.epod?.deliveredTick),
      state.epod == null ? 'Not generated' : 'Sent for invoicing',
    ),
  ];

  return pw.Table(
    border: pw.TableBorder(
      horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    ),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.4),
      1: pw.FixedColumnWidth(80),
      2: pw.FlexColumnWidth(1.8),
    },
    children: [
      for (final row in rows)
        pw.TableRow(
          children: [
            _cell(row.$1),
            _cell(row.$2, grey: true),
            _cell(row.$3, grey: true),
          ],
        ),
    ],
  );
}

pw.Widget _epodBlock(ScenarioState state) {
  final epod = state.epod;
  final signature = epod?.signatureBytes ?? state.signature?.bytes;
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _success, width: 0.8),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Delivered · e-POD generated',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _success,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Received by ${epod?.consigneeName ?? consigneeName}',
                style: pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                epod == null
                    ? 'Time pending'
                    : '${formatDateTime(epod.deliveredTick)} IST',
                style: pw.TextStyle(fontSize: 8.5, color: _grey),
              ),
              pw.Text(
                'Seal ${epod?.sealNumber ?? defaultSealNumber} verified at dispatch',
                style: pw.TextStyle(fontSize: 8.5, color: _grey),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        if (signature != null)
          pw.Container(
            width: 150,
            height: 64,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
            ),
            child: pw.Image(pw.MemoryImage(signature), fit: pw.BoxFit.contain),
          ),
      ],
    ),
  );
}

String _phaseLabel(TripPhase phase) => switch (phase) {
  TripPhase.driving => 'In transit',
  TripPhase.excursionActive => 'Excursion active',
  TripPhase.excursionAcknowledged => 'Excursion acknowledged',
  TripPhase.delivered => 'Delivered',
};
