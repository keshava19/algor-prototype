import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/band.dart';
import '../../core/domain/fictional_data.dart';
import '../../core/domain/models.dart';
import '../../core/scenario/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/formatters.dart';
import '../../shared/widgets/call_sheet.dart';
import '../../shared/widgets/countdown_ring.dart';
import 'log_action_sheet.dart';

class ExcursionOverlay extends ConsumerWidget {
  const ExcursionOverlay({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scenarioControllerProvider);
    final visible = enabled && state.phase == TripPhase.excursionActive;
    final smsSent =
        state.excursion != null &&
        state.custody.any(
          (event) =>
              event.title == 'Control room SMS sent' &&
              event.tick >= state.excursion!.startedTick,
        );
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: visible
            ? _ExcursionCard(
                secondsLeft: state.escalationSecondsLeft,
                totalSeconds: state.escalationDuration,
                escalated: state.excursion?.escalated ?? false,
                tick: state.tick,
                band: state.bandProfile,
                smsSent: smsSent,
                onAcknowledge: () =>
                    ref.read(scenarioControllerProvider.notifier).acknowledge(),
                onLogAction: () => showLogActionSheet(context),
                onCall: () => showCallSheet(
                  context,
                  title: 'Control room',
                  subtitle: 'Algor control room · simulated call',
                  custodyTitle: 'Control room called',
                ),
                onSms: () => ref
                    .read(scenarioControllerProvider.notifier)
                    .smsControlRoom(),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _ExcursionCard extends StatelessWidget {
  const _ExcursionCard({
    required this.secondsLeft,
    required this.totalSeconds,
    required this.escalated,
    required this.tick,
    required this.band,
    required this.smsSent,
    required this.onAcknowledge,
    required this.onLogAction,
    required this.onCall,
    required this.onSms,
  });

  final int secondsLeft;
  final int totalSeconds;
  final bool escalated;
  final int tick;
  final BandProfile band;
  final bool smsSent;
  final VoidCallback onAcknowledge;
  final VoidCallback onLogAction;
  final VoidCallback onCall;
  final VoidCallback onSms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: AppColors.navy.withValues(alpha: 0.88),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.55),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.thermostat,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Temperature excursion',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              formatClock(tick),
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    band.excursionTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    excursionLocation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CountdownRing(
                        secondsLeft: secondsLeft,
                        totalSeconds: totalSeconds,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              escalated
                                  ? 'Escalated — control room notified'
                                  : 'Escalates in ${formatCountdown(secondsLeft)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: escalated
                                    ? AppColors.danger
                                    : AppColors.queued,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Acknowledge to record who responded and when. '
                              'The reading and action join the audit trail.',
                              style: theme.textTheme.bodySmall?.copyWith(
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
                  const SizedBox(height: 18),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onAcknowledge,
                    child: const Text(acknowledgeLabel),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onLogAction,
                    child: const Text(logActionLabel),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: const Text(callControlRoomLabel),
                  ),
                  TextButton.icon(
                    onPressed: smsSent ? null : onSms,
                    icon: Icon(
                      smsSent ? Icons.check : Icons.sms_outlined,
                      size: 18,
                    ),
                    label: Text(smsSent ? smsSentLabel : smsControlRoomLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
