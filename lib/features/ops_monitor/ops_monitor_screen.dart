import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/fictional_data.dart';
import '../../core/domain/models.dart';
import '../../core/scenario/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/formatters.dart';
import '../../shared/widgets/call_sheet.dart';
import '../../shared/widgets/map_panel.dart';
import '../../shared/widgets/milestone_timeline.dart';
import '../../shared/widgets/temp_band_chart.dart';
import '../../shared/widgets/temp_readout.dart';

class OpsMonitorScreen extends ConsumerWidget {
  const OpsMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scenarioControllerProvider);
    final theme = Theme.of(context);
    final excursion = state.excursion;
    final active = state.phase == TripPhase.excursionActive;
    final delivered = state.phase == TripPhase.delivered;
    final distanceKm = (state.lastFeedTick / totalTripMinutes * 1405).clamp(
      0,
      1405,
    );
    final recentCustody = state.custody.length <= 4
        ? state.custody
        : state.custody.sublist(state.custody.length - 4);
    final badge = delivered
        ? (
            label: 'FEED CLOSED',
            color: AppColors.success,
            icon: Icons.check_circle,
          )
        : state.telemetryGap
        ? (label: 'FEED STALE', color: AppColors.queued, icon: Icons.wifi_off)
        : (label: 'FEED LIVE', color: AppColors.danger, icon: Icons.circle);
    final stamp = delivered
        ? 'delivered ${formatClock(state.epod?.deliveredTick ?? state.tick)}'
        : state.telemetryGap
        ? 'last received ${formatClock(state.lastFeedTick)}'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live shipment monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch role',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (active && excursion != null) ...[
            _ExcursionBanner(
              phase: state.phase,
              excursion: excursion,
              onCallDriver: () => showCallSheet(
                context,
                title: 'Driver · $driverName',
                subtitle: '$vehiclePlate · simulated call',
                custodyTitle: 'Driver called',
                custodySource: custodySourceControlRoom,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _FeedStrip(
            label: badge.label,
            color: badge.color,
            icon: badge.icon,
            clockLabel: '$scenarioDateLabel · ${formatClock(state.tick)} IST',
            stamp: stamp,
          ),
          if (!active && excursion != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.notifications_none,
                  size: 14,
                  color: AppColors.queued,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Last alert ${formatClock(excursion.startedTick)} · '
                    '${excursion.reading.toStringAsFixed(1)} °C · acknowledged',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              awbLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              laneLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TempReadout(
                    celsius: state.currentTemperature,
                    band: state.bandProfile,
                    phase: state.phase,
                    stale: state.telemetryGap && !delivered,
                    sourceLabel: formatFeedLabel(
                      lastFeedTick: state.lastFeedTick,
                      nowTick: state.tick,
                      stale: state.telemetryGap,
                      finalRecord: delivered,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TempBandChart(
                    readings: ref.watch(chartReadingsProvider),
                    band: state.bandProfile,
                    excursionTick: excursion?.startedTick,
                    height: 130,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.route_outlined,
                        size: 16,
                        color: AppColors.cyan,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${distanceKm.toStringAsFixed(0)} of 1405 km · '
                        '$vehiclePlate',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        'ETA ${formatClock(etaTick)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
            isExcursion: active,
            height: 230,
          ),
          if (!active && excursion != null) ...[
            const SizedBox(height: 12),
            _ExcursionBanner(
              phase: state.phase,
              excursion: excursion,
              onCallDriver: () => showCallSheet(
                context,
                title: 'Driver · $driverName',
                subtitle: '$vehiclePlate · simulated call',
                custodyTitle: 'Driver called',
                custodySource: custodySourceControlRoom,
              ),
            ),
          ],
          if (state.isOffline) ...[
            const SizedBox(height: 12),
            Card(
              color: AppColors.queued.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 18,
                      color: AppColors.queued,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        offlineBanner(state.queue.length),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showCallSheet(
                    context,
                    title: 'Driver · $driverName',
                    subtitle: '$vehiclePlate · simulated call',
                    custodyTitle: 'Driver called',
                    custodySource: custodySourceControlRoom,
                  ),
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Call driver'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => context.go('/client/live'),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Client view'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Latest custody events',
                        style: theme.textTheme.labelLarge,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/client/live'),
                        child: const Text('Full trail'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  MilestoneTimeline(events: recentCustody),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.local_shipping_outlined,
                color: AppColors.cyan,
              ),
              title: const Text('Driver & e-POD app'),
              subtitle: const Text('Offline-first capture workflow'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => context.go('/driver'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedStrip extends StatelessWidget {
  const _FeedStrip({
    required this.label,
    required this.color,
    required this.icon,
    required this.clockLabel,
    this.stamp,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String clockLabel;
  final String? stamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
          if (stamp != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stamp!,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ] else
            const Spacer(),
          Text(
            clockLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExcursionBanner extends StatelessWidget {
  const _ExcursionBanner({
    required this.phase,
    required this.excursion,
    required this.onCallDriver,
  });

  final TripPhase phase;
  final ExcursionEvent excursion;
  final VoidCallback onCallDriver;

  @override
  Widget build(BuildContext context) {
    final active = phase == TripPhase.excursionActive;
    final color = active ? AppColors.danger : AppColors.queued;
    final theme = Theme.of(context);
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  active ? Icons.warning_amber : Icons.task_alt,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    active
                        ? 'Excursion — awaiting driver acknowledgement'
                        : 'Excursion acknowledged',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${excursion.reading.toStringAsFixed(1)} °C — outside the '
              '${excursion.rangeLabel} °C band',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!active) ...[
              const SizedBox(height: 4),
              Text(
                '${excursion.acknowledgedTick == null ? '' : 'Acknowledged ${formatClock(excursion.acknowledgedTick!)} · '}'
                '${excursion.reasonCode ?? ''}'
                '${excursion.note == null ? '' : ' — ${excursion.note}'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (active) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: onCallDriver,
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('Call driver'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
