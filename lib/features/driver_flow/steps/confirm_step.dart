import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/fictional_data.dart';
import '../../../core/domain/models.dart';
import '../../../core/scenario/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/formatters.dart';
import '../../../shared/widgets/sync_queue_sheet.dart';

class ConfirmStep extends ConsumerWidget {
  const ConfirmStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scenarioControllerProvider);
    final theme = Theme.of(context);
    final delivered = state.phase == TripPhase.delivered;
    final signature = state.signature;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        Text(
          delivered ? 'Delivery complete' : 'e-POD capture',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          delivered
              ? 'Proof of delivery was generated on the device and sent to '
                    'the audit trail.'
              : 'The e-POD generates automatically once the signature is '
                    'captured and every queued item has synced.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      delivered
                          ? Icons.verified
                          : state.isOffline
                          ? Icons.cloud_off
                          : Icons.hourglass_top,
                      color: delivered
                          ? AppColors.success
                          : state.isOffline
                          ? AppColors.queued
                          : AppColors.cyan,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        delivered
                            ? 'e-POD generated · ${formatClock(state.epod!.deliveredTick)}'
                            : state.isOffline
                            ? epodHeldLabel
                            : 'Waiting for network confirmation',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MetaRow(label: 'AWB', value: awbNumber),
                _MetaRow(label: 'Consignee', value: consigneeName),
                _MetaRow(label: 'Seal', value: state.sealNumber),
                if (signature != null)
                  _MetaRow(
                    label: 'Signed',
                    value: '${signature.name} · ${formatClock(signature.tick)}',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Capture queue', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SyncQueueSheet(queue: state.queue),
          ),
        ),
        if (delivered) ...[
          const SizedBox(height: 12),
          Card(
            color: AppColors.success.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deliveredLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consignee acknowledged receipt. Invoice hand-off is '
                    'ready from the client view.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 84,
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
