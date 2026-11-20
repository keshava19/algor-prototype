import 'package:flutter/material.dart';

import '../../core/domain/models.dart';
import '../../core/theme/app_theme.dart';

class SyncQueueSheet extends StatelessWidget {
  const SyncQueueSheet({super.key, required this.queue});

  final List<QueueItem> queue;

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
                  },
                  size: 16,
                  color: switch (item.status) {
                    QueueItemStatus.pending => AppColors.queued,
                    QueueItemStatus.syncing => AppColors.cyan,
                    QueueItemStatus.synced => AppColors.success,
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.label, style: const TextStyle(fontSize: 13)),
                ),
                Text(
                  item.status.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
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
}
