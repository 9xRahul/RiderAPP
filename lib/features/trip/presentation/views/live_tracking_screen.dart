import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/trip_status.dart';
import '../bloc/history/history_bloc.dart';
import '../bloc/history/history_event.dart';
import '../bloc/history/history_state.dart';
import '../bloc/location/location_bloc.dart';
import '../bloc/location/location_event.dart';
import '../bloc/location/location_state.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/settings/settings_state.dart';
import '../bloc/trip/trip_bloc.dart';
import '../bloc/trip/trip_event.dart';
import '../bloc/trip/trip_state.dart';
import '../widgets/gps_accuracy_chip.dart';
import '../widgets/live_map_view.dart';
import '../widgets/metric_card.dart';
import '../widgets/speedometer_gauge.dart';
import '../widgets/sync_status_badge.dart';
import '../widgets/trip_control_button.dart';
import 'settings_screen.dart';
import 'trip_history_screen.dart';
import 'trip_summary_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  bool _isMapExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<LocationBloc>().add(const InitializeLocationEvent());
    context.read<TripBloc>().add(const CheckActiveTripEvent());
    context.read<HistoryBloc>().add(const LoadTripHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, tripState) {
        if (tripState is TripCompletedState) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripSummaryScreen(trip: tripState.trip),
            ),
          );
        } else if (tripState is TripActiveState && tripState.isRecovered) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your active ride was restored'),
              backgroundColor: AppColors.cyan,
              duration: Duration(seconds: 4),
            ),
          );
        } else if (tripState is TripErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tripState.message),
              backgroundColor: AppColors.coral,
            ),
          );
        }
      },
      builder: (context, tripState) {
        final currentMetrics = tripState is TripActiveState
            ? tripState.metrics
            : null;
        final currentStatus = tripState is TripActiveState
            ? tripState.status
            : TripStatus.idle;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: BlocBuilder<LocationBloc, LocationState>(
              builder: (context, locationState) {
                return BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, settingsState) {
                    return BlocBuilder<HistoryBloc, HistoryState>(
                      builder: (context, historyState) {
                        final pendingSync = historyState is HistoryLoadedState
                            ? historyState.pendingSyncCount
                            : 0;
                        final isSyncing = historyState is HistoryLoadedState
                            ? historyState.isSyncing
                            : false;

                        return Stack(
                          children: [
                            Column(
                              children: [
                                _buildTopBar(
                                  context: context,
                                  locationState: locationState,
                                  isSyncing: isSyncing,
                                  pendingSyncCount: pendingSync,
                                ),

                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  height: _isMapExpanded
                                      ? MediaQuery.of(context).size.height * 0.58
                                      : 220,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.surfaceBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(100),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Stack(
                                      children: [
                                        LiveMapView(
                                          points: tripState is TripActiveState
                                              ? tripState.points
                                              : [],
                                          currentLocation: locationState.filteredLocation,
                                          isDarkMode: settingsState.isDarkMode,
                                          isTracking: currentStatus.isActive,
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _isMapExpanded = !_isMapExpanded;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.surface.withAlpha(220),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: AppColors.surfaceBorder),
                                              ),
                                              child: Icon(
                                                _isMapExpanded
                                                    ? Icons.unfold_less_rounded
                                                    : Icons.unfold_more_rounded,
                                                size: 18,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      children: [
                                        SpeedometerGauge(
                                          currentSpeedKmh: currentStatus.isPaused
                                              ? 0.0
                                              : (currentMetrics?.currentSpeedKmh ??
                                                  (locationState.filteredLocation?.speedKmh ?? 0.0)),
                                          maxSpeedKmh: currentMetrics?.maxSpeedKmh ?? 0.0,
                                        ),

                                        const SizedBox(height: 14),

                                        Row(
                                          children: [
                                            Expanded(
                                              child: MetricCard(
                                                label: 'Distance',
                                                value: Formatters.formatDistance(
                                                  currentMetrics?.distanceMeters ?? 0.0,
                                                ),
                                                unit: '',
                                                icon: Icons.route_rounded,
                                                accentColor: AppColors.cyan,
                                                isHighlight: true,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: MetricCard(
                                                label: 'Duration',
                                                value: Formatters.formatDuration(
                                                  currentMetrics?.durationSeconds ?? 0,
                                                ),
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
                                                value: Formatters.formatSpeed(
                                                  currentMetrics?.maxSpeedKmh ?? 0.0,
                                                ),
                                                unit: 'km/h',
                                                icon: Icons.flash_on_rounded,
                                                accentColor: AppColors.coral,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: MetricCard(
                                                label: 'Avg Speed',
                                                value: Formatters.formatSpeed(
                                                  currentMetrics?.avgSpeedKmh ?? 0.0,
                                                ),
                                                unit: 'km/h',
                                                icon: Icons.speed_rounded,
                                                accentColor: AppColors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                  child: TripControlButton(
                                    status: currentStatus,
                                    onStart: () {
                                      context.read<TripBloc>().add(StartTripEvent(
                                        initialLocation: locationState.filteredLocation,
                                      ));
                                    },
                                    onPause: () {
                                      context.read<TripBloc>().add(const PauseTripEvent());
                                    },
                                    onResume: () {
                                      context.read<TripBloc>().add(const ResumeTripEvent());
                                    },
                                    onEnd: () {
                                      context.read<TripBloc>().add(EndTripEvent(
                                        finalLocation: locationState.filteredLocation,
                                      ));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar({
    required BuildContext context,
    required LocationState locationState,
    required bool isSyncing,
    required int pendingSyncCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GpsAccuracyChip(
            quality: locationState.signalQuality,
            accuracyMeters: locationState.filteredLocation?.accuracyMeters,
          ),

          Row(
            children: [
              SyncStatusBadge(
                isOnline: true,
                isSyncing: isSyncing,
                pendingCount: pendingSyncCount,
                onTap: () {
                  context.read<HistoryBloc>().add(const TriggerSyncEvent());
                },
              ),
              const SizedBox(width: 8),

              IconButton.filledTonal(
                icon: const Icon(Icons.history_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TripHistoryScreen(),
                    ),
                  );
                },
                tooltip: 'Ride History',
              ),
              const SizedBox(width: 6),

              IconButton.filledTonal(
                icon: const Icon(Icons.tune_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                tooltip: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
