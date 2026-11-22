import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/band.dart';
import '../../core/domain/fictional_data.dart';
import '../../core/domain/models.dart';
import '../../core/scenario/providers.dart';
import '../../core/util/formatters.dart';

Future<void> showDemoTray(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const DemoTray(),
);

class DemoTray extends ConsumerWidget {
  const DemoTray({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scenarioControllerProvider);
    final controller = ref.read(scenarioControllerProvider.notifier);
    final theme = Theme.of(context);

    void close() => Navigator.of(context).pop();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Demo controls', style: theme.textTheme.titleMedium),
            Text(
              'Scenario ${formatClock(state.tick)} · '
              '${switch (state.phase) {
                TripPhase.driving => 'in transit',
                TripPhase.excursionActive => 'excursion active',
                TripPhase.excursionAcknowledged => 'acknowledged',
                TripPhase.delivered => 'delivered',
              }}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),
            _SectionLabel(label: 'Network', theme: theme),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(offlineToggleLabel),
              subtitle: const Text('Driver evidence queue only'),
              value: state.isOffline,
              onChanged: controller.setOffline,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(telemetryGapLabel),
              subtitle: const Text(
                'Freezes the sensor feed; readings and map go stale',
              ),
              value: state.telemetryGap,
              onChanged: controller.setTelemetryGap,
            ),
            const SizedBox(height: 6),
            _SectionLabel(label: 'Actions', theme: theme),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Reset'),
                  onPressed: () {
                    controller.reset();
                    close();
                    context.go('/');
                  },
                ),
                ActionChip(
                  label: const Text('Start drift'),
                  onPressed:
                      state.driftStartedTick == null &&
                          state.phase == TripPhase.driving
                      ? controller.startDrift
                      : null,
                ),
                ActionChip(
                  label: const Text('Trigger excursion'),
                  onPressed: state.phase == TripPhase.driving
                      ? () {
                          controller.triggerExcursion();
                          close();
                        }
                      : null,
                ),
                ActionChip(
                  label: const Text('Jump to out-for-delivery'),
                  onPressed:
                      state.phase != TripPhase.delivered &&
                          state.phase != TripPhase.excursionActive
                      ? () {
                          controller.jumpToOutForDelivery();
                          close();
                          context.go('/driver');
                        }
                      : null,
                ),
                ActionChip(
                  label: const Text('Jump to delivered'),
                  onPressed: state.phase == TripPhase.delivered
                      ? null
                      : () {
                          controller.jumpToDelivered();
                          close();
                          context.go('/client/live');
                        },
                ),
                ActionChip(
                  label: Text(
                    state.failNextSync ? 'Failure armed' : failNextSyncLabel,
                  ),
                  onPressed: state.failNextSync
                      ? null
                      : controller.armSyncFailure,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionLabel(label: 'Product band (preview)', theme: theme),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final profile in BandProfiles.all)
                  ChoiceChip(
                    label: Text(profile.chipLabel),
                    selected: state.band == profile.band,
                    onSelected: (_) => controller.setBand(profile.band),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Switches the live feed and report band. Captured timestamps '
              'and checklist readings keep their original values.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            _SectionLabel(label: 'Escalation countdown', theme: theme),
            const SizedBox(height: 6),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: defaultEscalationSeconds,
                  label: Text('2:00'),
                ),
                ButtonSegment(
                  value: demoEscalationSeconds,
                  label: Text('0:30'),
                ),
              ],
              selected: {state.escalationDuration},
              onSelectionChanged: state.phase == TripPhase.excursionActive
                  ? null
                  : (selection) =>
                        controller.setEscalationDuration(selection.first),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo controls never rewrite captured records.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 2),
    child: Text(label, style: theme.textTheme.labelLarge),
  );
}
