import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/trip.dart';
import '../bloc/history/history_bloc.dart';
import '../bloc/history/history_event.dart';
import '../widgets/live_map_view.dart';
import '../widgets/metric_card.dart';
import '../widgets/speed_chart_widget.dart';

class TripDetailsScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Text(
          'Delete Ride?',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This will permanently delete this ride from your phone and cloud backup.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<HistoryBloc>().add(DeleteTripEvent(trip.id));
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          Formatters.formatTripDateTime(trip.startTime),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Ride',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: LiveMapView(
                  points: trip.points,
                  isTracking: false,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Distance',
                    value: Formatters.formatDistance(trip.metrics.distanceMeters),
                    unit: '',
                    icon: Icons.route_rounded,
                    accentColor: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    label: 'Duration',
                    value: Formatters.formatDuration(trip.metrics.durationSeconds),
                    unit: '',
                    icon: Icons.timer_outlined,
                    accentColor: AppColors.emerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Max Speed',
                    value: Formatters.formatSpeed(trip.metrics.maxSpeedKmh),
                    unit: 'km/h',
                    icon: Icons.flash_on_rounded,
                    accentColor: AppColors.coral,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    label: 'Avg Speed',
                    value: Formatters.formatSpeed(trip.metrics.avgSpeedKmh),
                    unit: 'km/h',
                    icon: Icons.speed_rounded,
                    accentColor: AppColors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: SpeedChartWidget(
                points: trip.points,
                maxSpeed: trip.metrics.maxSpeedKmh,
                avgSpeed: trip.metrics.avgSpeedKmh,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'ROUTE TIMELINE (${trip.points.length} POINTS)',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            Material(
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.surfaceBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trip.points.length > 20 ? 20 : trip.points.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.surfaceBorder,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final pt = trip.points[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      'Point #${index + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Speed: ${pt.speedKmh.toStringAsFixed(1)} km/h',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    trailing: Text(
                      '${pt.timestamp.hour.toString().padLeft(2, '0')}:${pt.timestamp.minute.toString().padLeft(2, '0')}:${pt.timestamp.second.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
