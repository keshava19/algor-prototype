import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/fictional_data.dart';
import '../../../core/scenario/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/util/formatters.dart';

const _checklistThumbs = <String>[
  'assets/images/precool_reefer.png',
  'assets/images/logger_armed.png',
  'assets/images/reefer_door_seal.png',
  'assets/images/reefer_clean.png',
];

class ChecklistStep extends ConsumerWidget {
  const ChecklistStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scenarioControllerProvider);
    final controller = ref.read(scenarioControllerProvider.notifier);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        Text(
          'Pre-trip checklist',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap each row to confirm it before dispatch. Every confirmation is '
          'stamped with user and time.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < state.checklist.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => controller.confirmChecklistRow(index),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          _checklistThumbs[index],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.checklist[index].title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.checklist[index].reading,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            if (state.checklist[index].confirmedTick != null)
                              Text(
                                'captured ${formatClock(state.checklist[index].confirmedTick!)} by $driverName',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        state.checklist[index].confirmed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: state.checklist[index].confirmed
                            ? AppColors.success
                            : theme.colorScheme.outline,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
