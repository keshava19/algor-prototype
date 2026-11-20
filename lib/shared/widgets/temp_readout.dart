import 'package:flutter/material.dart';

import '../../core/domain/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/formatters.dart';
import 'status_chip.dart';

class TempReadout extends StatelessWidget {
  const TempReadout({
    super.key,
    required this.celsius,
    required this.bandMin,
    required this.bandMax,
    required this.phase,
  });

  final double celsius;
  final double bandMin;
  final double bandMax;
  final TripPhase phase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              formatTemp(celsius),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            const Spacer(),
            StatusChip(phase: phase),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bandLeft = bandMin / 10 * width;
            final bandWidth = (bandMax - bandMin) / 10 * width;
            final markerLeft = (celsius / 10).clamp(0.0, 1.0) * width;
            return SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 2,
                    bottom: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: bandLeft,
                    width: bandWidth,
                    top: 2,
                    bottom: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: markerLeft - 5,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.cyan,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: AppColors.navy, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Band ${bandMin.toStringAsFixed(0)}–${bandMax.toStringAsFixed(0)} °C · '
          'set-point 4.0 °C',
          style: TextStyle(
            fontSize: 11,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
