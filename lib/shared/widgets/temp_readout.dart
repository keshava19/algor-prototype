import 'package:flutter/material.dart';

import '../../core/domain/band.dart';
import '../../core/domain/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/formatters.dart';
import 'status_chip.dart';

class TempReadout extends StatelessWidget {
  const TempReadout({
    super.key,
    required this.celsius,
    required this.band,
    required this.phase,
    required this.sourceLabel,
    this.stale = false,
    this.showChip = true,
  });

  final double celsius;
  final BandProfile band;
  final TripPhase phase;
  final String sourceLabel;
  final bool stale;
  final bool showChip;

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
            if (showChip) StatusChip(phase: phase),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bandLeft = (band.min - band.axisMin) / band.axisSpan * width;
            final bandWidth = (band.max - band.min) / band.axisSpan * width;
            final markerLeft =
                ((celsius - band.axisMin) / band.axisSpan).clamp(0.0, 1.0) *
                width;
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
                    left: (markerLeft - 5).clamp(0.0, width - 10),
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 12,
                      decoration: BoxDecoration(
                        color: stale ? AppColors.queued : AppColors.cyan,
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
          'Band ${band.rangeLabel} °C · set-point ${formatTemp(band.setPoint)}',
          style: TextStyle(
            fontSize: 11,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              stale ? Icons.wifi_off : Icons.sensors,
              size: 12,
              color: stale ? AppColors.queued : AppColors.success,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                sourceLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: stale
                      ? AppColors.queued
                      : scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
