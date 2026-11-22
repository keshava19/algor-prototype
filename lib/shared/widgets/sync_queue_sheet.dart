import 'package:flutter/material.dart';

import '../../core/domain/models.dart';
import '../../core/theme/app_theme.dart';

class SyncQueueSheet extends StatelessWidget {
  const SyncQueueSheet({super.key, required this.queue, this.onRetry});

  final List<QueueItem> queue;
  final ValueChanged<String>? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in queue)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  switch (item.status) {
                    QueueItemStatus.pending => Icons.schedule,
                    QueueItemStatus.syncing => Icons.sync,
                    QueueItemStatus.synced => Icons.check_circle,
                    QueueItemStatus.failed => Icons.error_outline,
                  },
                  size: 16,
                  color: switch (item.status) {
                    QueueItemStatus.pending => AppColors.queued,
                    QueueItemStatus.syncing => AppColors.cyan,
                    QueueItemStatus.synced => AppColors.success,
                    QueueItemStatus.failed => AppColors.danger,
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label, style: const TextStyle(fontSize: 13)),
                      Text(
                        '${item.eventId} · ${_statusLabel(item.status)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: item.status == QueueItemStatus.failed
                              ? AppColors.danger
                              : scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.status == QueueItemStatus.failed && onRetry != null)
                  TextButton(
                    onPressed: () => onRetry!(item.eventId),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        if (queue.isEmpty)
          Text(
            'No captures queued',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
      ],
    );
  }

  String _statusLabel(QueueItemStatus status) => switch (status) {
    QueueItemStatus.pending => 'pending',
    QueueItemStatus.syncing => 'syncing',
    QueueItemStatus.synced => 'synced',
    QueueItemStatus.failed => 'failed',
  };
}
