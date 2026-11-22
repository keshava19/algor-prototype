import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/fictional_data.dart';
import '../../core/domain/band.dart';
import '../../core/domain/models.dart';
import '../../core/domain/sample_assets.dart';
import '../../core/domain/temperature.dart';
import '../../core/scenario/providers.dart';
import '../../core/scenario/scenario_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/formatters.dart';
import '../../shared/widgets/map_panel.dart';
import '../../shared/widgets/milestone_timeline.dart';
import '../../shared/widgets/temp_band_chart.dart';
import '../../shared/widgets/temp_readout.dart';
import 'audit_pdf_service.dart';

class ClientShipmentDetail extends ConsumerWidget {
  const ClientShipmentDetail({super.key, required this.sample});

  final bool sample;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveState = ref.watch(scenarioControllerProvider);
    final state = sample
        ? ScenarioState.sampleDelivered(
            signatureBytes: SampleAssets.signaturePng,
          )
        : liveState;
    final theme = Theme.of(context);
    final band = state.bandProfile;
    final fullSeries = fullTripReadings(state);
    final chartSeries = sample
        ? _downsample(fullSeries, 120)
        : ref.watch(chartReadingsProvider);
    final excursion = state.excursion;
    final delivered = state.phase == TripPhase.delivered;

    return Scaffold(
      appBar: AppBar(
        title: Text(sample ? 'Sample delivery' : 'Live shipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'Shipment list',
            onPressed: () => context.go('/client'),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Role picker',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AWB $awbNumber',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$laneLabel · ${band.productLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (state.sealVerified)
                          _MetaBadge(
                            icon: Icons.verified_outlined,
                            text: 'Seal verified · ${state.sealNumber}',
                            color: AppColors.success,
                          ),
                        _MetaBadge(
                          icon: Icons.science_outlined,
                          text: '$loggerId · $loggerCalibration',
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        if (!delivered)
                          _MetaBadge(
                            icon: Icons.schedule,
                            text:
                                'ETA ${formatClock(etaTick)} · '
                                '${formatRemaining(state.tick)}',
                            color: AppColors.cyan,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sample ? 'Temperature record' : 'Live temperature',
                        style: theme.textTheme.labelLarge,
                      ),
                      const Spacer(),
                      Text(
                        sample
                            ? '${formatClock(0)} – ${formatClock(state.lastFeedTick)}'
                            : 'trailing 60 min',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TempReadout(
                    celsius: state.currentTemperature,
                    band: band,
                    phase: state.phase,
                    stale: state.telemetryGap && !delivered,
                    sourceLabel: formatFeedLabel(
                      lastFeedTick: state.lastFeedTick,
                      nowTick: state.tick,
                      stale: state.telemetryGap && !delivered,
                      finalRecord: delivered,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TempBandChart(
                    readings: chartSeries,
                    band: band,
                    excursionTick: excursion?.startedTick,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Stat(
                        label: 'Min',
                        value: formatTemp(
                          fullSeries.map((r) => r.celsius).reduce(min),
                        ),
                      ),
                      _Stat(
                        label: 'Max',
                        value: formatTemp(
                          fullSeries.map((r) => r.celsius).reduce(max),
                        ),
                      ),
                      _Stat(
                        label: 'In band',
                        value:
                            '${_inBandPercent(fullSeries, band).toStringAsFixed(1)}%',
                      ),
                      _Stat(
                        label: 'MKT',
                        value: formatTemp(meanKineticTemperature(fullSeries)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          MapPanel(
            truckPosition: ref.watch(truckPositionProvider),
            isExcursion: state.phase == TripPhase.excursionActive,
            height: 220,
          ),
          if (excursion != null) ...[
            const SizedBox(height: 12),
            Card(
              color: state.phase == TripPhase.excursionActive
                  ? AppColors.danger.withValues(alpha: 0.12)
                  : AppColors.queued.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          state.phase == TripPhase.excursionActive
                              ? Icons.warning_amber
                              : Icons.task_alt,
                          size: 18,
                          color: state.phase == TripPhase.excursionActive
                              ? AppColors.danger
                              : AppColors.queued,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.phase == TripPhase.excursionActive
                                ? 'Excursion in progress'
                                : 'Excursion acknowledged',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          formatClock(excursion.startedTick),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      excursion.location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    if (excursion.acknowledgedTick != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Acknowledged ${formatClock(excursion.acknowledgedTick!)}'
                          ' · ${excursion.reasonCode ?? 'Driver acknowledged'}'
                          '${excursion.note == null ? '' : ' — ${excursion.note}'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Custody trail', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  MilestoneTimeline(events: state.custody),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (delivered && state.epod != null)
            _EPodCard(epod: state.epod!, state: state)
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.draw_outlined,
                      size: 18,
                      color: AppColors.cyan,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Proof of delivery appears here after the consignee '
                        'signs. The e-POD is generated on the device.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          _AuditPdfButton(state: state),
          const SizedBox(height: 10),
          Text(
            'The PDF includes the full temperature curve, custody trail and '
            'e-POD. It supports GDP documentation and is not a certificate of '
            'compliance. All values are simulated.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _EPodCard extends StatelessWidget {
  const _EPodCard({required this.epod, required this.state});

  final EPod epod;
  final ScenarioState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final signature = epod.signatureBytes ?? state.signature?.bytes;
    return Card(
      color: AppColors.success.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'e-POD generated',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const Spacer(),
                Text(
                  formatClock(epod.deliveredTick),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Received by', value: epod.consigneeName),
            _InfoRow(label: 'Location', value: consigneeHub),
            _InfoRow(label: 'Seal', value: epod.sealNumber),
            if (epod.deliveryNote != null)
              _InfoRow(label: 'Delivery note', value: epod.deliveryNote!),
            if (signature != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 84,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.memory(signature, fit: BoxFit.contain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AuditPdfButton extends StatefulWidget {
  const _AuditPdfButton({required this.state});

  final ScenarioState state;

  @override
  State<_AuditPdfButton> createState() => _AuditPdfButtonState();
}

class _AuditPdfButtonState extends State<_AuditPdfButton> {
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      await shareAuditPdf(widget.state);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not prepare the PDF — try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _busy ? null : _share,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      label: Text(_busy ? 'Preparing PDF…' : downloadAuditPdfLabel),
    );
  }
}

double _inBandPercent(List<TempReading> readings, BandProfile band) {
  if (readings.isEmpty) return 0;
  final inBand = readings.where(
    (reading) => reading.celsius >= band.min && reading.celsius <= band.max,
  );
  return inBand.length / readings.length * 100;
}

List<TempReading> _downsample(List<TempReading> readings, int target) {
  if (readings.length <= target) return readings;
  final step = (readings.length / target).ceil();
  final sampled = [
    for (var index = 0; index < readings.length; index += step) readings[index],
  ];
  if (sampled.last.tick != readings.last.tick) sampled.add(readings.last);
  return sampled;
}
