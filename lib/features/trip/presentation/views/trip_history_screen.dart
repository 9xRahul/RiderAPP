import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/trip.dart';
import '../bloc/history/history_bloc.dart';
import '../bloc/history/history_event.dart';
import '../bloc/history/history_state.dart';
import 'trip_details_screen.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const LoadTripHistoryEvent());
  }

  void _confirmDeleteTrip(BuildContext context, String tripId) {
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
              context.read<HistoryBloc>().add(DeleteTripEvent(tripId));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: Text(
          'Delete All Rides?',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This will permanently delete all recorded rides from both your phone and cloud backup.',
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
              context.read<HistoryBloc>().add(const ClearHistoryEvent());
            },
            child: const Text('Delete All'),
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
          'Ride History',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Back Up Rides',
            onPressed: () {
              context.read<HistoryBloc>().add(const TriggerSyncEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backing up rides to cloud...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Delete All Rides',
            onPressed: () => _confirmClearHistory(context),
          ),
        ],
      ),
      body: BlocConsumer<HistoryBloc, HistoryState>(
        listener: (context, state) {
          if (state is HistoryLoadedState && state.statusMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.statusMessage!),
                backgroundColor: AppColors.surfaceLight,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HistoryLoadingState) {
            return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
          }

          if (state is HistoryLoadedState) {
            if (state.trips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.route_rounded,
                      size: 64,
                      color: AppColors.textMuted.withAlpha(120),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Rides Yet',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start a ride to track and record your route.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }

            final totalDistanceMeters = state.trips.fold<double>(
              0.0,
              (acc, trip) => acc + trip.metrics.distanceMeters,
            );

            return RefreshIndicator(
              color: AppColors.cyan,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                context.read<HistoryBloc>().add(const LoadTripHistoryEvent());
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total Rides',
                          state.trips.length.toString(),
                          Icons.two_wheeler_rounded,
                          AppColors.cyan,
                        ),
                        Container(width: 1, height: 36, color: AppColors.surfaceBorder),
                        _buildSummaryItem(
                          'Total Distance',
                          Formatters.formatDistance(totalDistanceMeters),
                          Icons.route_rounded,
                          AppColors.emerald,
                        ),
                        Container(width: 1, height: 36, color: AppColors.surfaceBorder),
                        _buildSummaryItem(
                          'Saved on Phone',
                          state.pendingSyncCount.toString(),
                          Icons.cloud_upload_outlined,
                          state.pendingSyncCount > 0 ? AppColors.amber : AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'RECENT RIDES',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...state.trips.map((trip) => _buildTripCard(context, trip)),
                ],
              ),
            );
          }

          if (state is HistoryErrorState) {
            return Center(
              child: Text(
                state.message,
                style: GoogleFonts.inter(color: AppColors.coral),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TripDetailsScreen(trip: trip),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.two_wheeler_rounded,
                          size: 18,
                          color: AppColors.cyan,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.formatTripDateTime(trip.startTime),
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            trip.status.isCompleted ? 'Completed Ride' : 'Active Ride',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: trip.isSynced
                              ? AppColors.emerald.withAlpha(25)
                              : AppColors.amber.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: trip.isSynced
                                ? AppColors.emerald.withAlpha(100)
                                : AppColors.amber.withAlpha(100),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trip.isSynced
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_queue_rounded,
                              size: 12,
                              color: trip.isSynced ? AppColors.emerald : AppColors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trip.isSynced ? 'Backed up' : 'Saved locally',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: trip.isSynced ? AppColors.emerald : AppColors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: AppColors.textMuted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        splashRadius: 18,
                        tooltip: 'Delete Ride',
                        onPressed: () => _confirmDeleteTrip(context, trip.id),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: AppColors.surfaceBorder, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricSnippet('Distance', Formatters.formatDistance(trip.metrics.distanceMeters)),
                  _buildMetricSnippet('Duration', Formatters.formatDuration(trip.metrics.durationSeconds)),
                  _buildMetricSnippet('Max Speed', '${Formatters.formatSpeed(trip.metrics.maxSpeedKmh)} km/h'),
                  _buildMetricSnippet('Avg Speed', '${Formatters.formatSpeed(trip.metrics.avgSpeedKmh)} km/h'),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildMetricSnippet(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
