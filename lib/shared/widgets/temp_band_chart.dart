import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/domain/band.dart';
import '../../core/domain/models.dart';
import '../../core/theme/app_theme.dart';

class TempBandChart extends StatelessWidget {
  const TempBandChart({
    super.key,
    required this.readings,
    required this.band,
    this.excursionTick,
    this.height = 150,
  });

  final List<TempReading> readings;
  final BandProfile band;
  final int? excursionTick;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = [
      for (var index = 0; index < readings.length; index++)
        FlSpot(index.toDouble(), readings[index].celsius),
    ];
    final excursionIndex = excursionTick == null
        ? null
        : readings.indexWhere((reading) => reading.tick == excursionTick);
    final excursionSpot = excursionIndex == null || excursionIndex < 0
        ? null
        : FlSpot(excursionIndex.toDouble(), readings[excursionIndex].celsius);
    final maxX = readings.length <= 1 ? 1.0 : readings.length - 1.0;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: band.axisMin,
          maxY: band.axisMax,
          clipData: const FlClipData.all(),
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                y1: band.min,
                y2: band.max,
                color: AppColors.success.withValues(alpha: 0.14),
              ),
            ],
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: band.axisInterval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.25),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: band.axisInterval,
                reservedSize: 34,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: AppColors.cyan,
              barWidth: 2.4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            if (excursionSpot != null)
              LineChartBarData(
                spots: [excursionSpot],
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.danger,
                        strokeWidth: 2,
                        strokeColor: AppColors.navy,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
