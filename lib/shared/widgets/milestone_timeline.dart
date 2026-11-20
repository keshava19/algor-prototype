import 'package:flutter/material.dart';

import '../../core/domain/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/formatters.dart';

class MilestoneTimeline extends StatelessWidget {
  const MilestoneTimeline({super.key, required this.events});

  final List<CustodyEvent> events;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ordered = events.reversed.toList();
    return Column(
      children: [
        for (var index = 0; index < ordered.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: index == 0 ? AppColors.cyan : scheme.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (index != ordered.length - 1)
                      Container(
                        width: 2,
                        height: 26,
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ordered[index].title,
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (ordered[index].detail != null)
                        Text(
                          ordered[index].detail!,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  formatClock(ordered[index].tick),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
