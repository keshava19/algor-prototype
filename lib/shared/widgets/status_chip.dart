import 'package:flutter/material.dart';

import '../../core/domain/models.dart';
import '../../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.phase});

  final TripPhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      TripPhase.driving => ('In transit', AppColors.cyan),
      TripPhase.excursionActive => ('Excursion!', AppColors.danger),
      TripPhase.excursionAcknowledged => (
        'Excursion acknowledged',
        AppColors.queued,
      ),
      TripPhase.delivered => ('Delivered', AppColors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
