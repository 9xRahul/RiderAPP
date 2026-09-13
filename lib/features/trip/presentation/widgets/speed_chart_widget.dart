import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/location_point.dart';

class SpeedChartWidget extends StatelessWidget {
  final List<LocationPoint> points;
  final double maxSpeed;
  final double avgSpeed;

  const SpeedChartWidget({
    super.key,
    required this.points,
    required this.maxSpeed,
    required this.avgSpeed,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text(
          'No speed data available',
          style: GoogleFonts.inter(color: AppColors.textMuted),
        ),
      );
    }

    final sampledPoints = _samplePoints(points, maxSamples: 50);

    final spots = sampledPoints.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.speedKmh);
    }).toList();

    final maxY = ((maxSpeed * 1.2).ceilToDouble()).clamp(20.0, 180.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SPEED PROFILE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Row(
              children: [
                _buildLegendItem('Avg: ${avgSpeed.toStringAsFixed(1)} km/h', AppColors.cyan),
                const SizedBox(width: 12),
                _buildLegendItem('Max: ${maxSpeed.toStringAsFixed(1)} km/h', AppColors.coral),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: AppColors.surfaceBorder,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: maxY / 4,
                    getTitlesWidget: (val, meta) => Text(
                      val.toInt().toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (spots.length - 1).toDouble().clamp(1.0, double.infinity),
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: AppColors.cyan,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyan.withAlpha(80),
                        AppColors.cyan.withAlpha(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  List<LocationPoint> _samplePoints(List<LocationPoint> list, {required int maxSamples}) {
    if (list.length <= maxSamples) return list;
    final step = list.length / maxSamples;
    final result = <LocationPoint>[];
    for (int i = 0; i < maxSamples; i++) {
      final index = (i * step).floor().clamp(0, list.length - 1);
      result.add(list[index]);
    }
    return result;
  }
}
