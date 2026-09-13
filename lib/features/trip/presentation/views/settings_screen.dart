import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/settings/settings_event.dart';
import '../bloc/settings/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final config = state.gpsConfig;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'RIDE TRACKING & ACCURACY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSliderTile(
                        title: 'Location Accuracy',
                        subtitle: 'Filters out weak signals for a cleaner route',
                        value: config.maxAccuracyMeters,
                        min: 5.0,
                        max: 80.0,
                        divisions: 15,
                        unit: 'm',
                        onChanged: (val) {
                          final updated = GpsFilterConfig(
                            maxAccuracyMeters: val,
                            maxSpeedKmh: config.maxSpeedKmh,
                            maxAccelerationMps2: config.maxAccelerationMps2,
                            minStationaryDistanceMeters: config.minStationaryDistanceMeters,
                            minMovingSpeedKmh: config.minMovingSpeedKmh,
                            enableKalmanFilter: config.enableKalmanFilter,
                            kalmanMeasurementNoise: config.kalmanMeasurementNoise,
                          );
                          context.read<SettingsBloc>().add(UpdateGpsSettingsEvent(updated));
                        },
                      ),
                      const Divider(color: AppColors.surfaceBorder, height: 24),

                      _buildSliderTile(
                        title: 'Speed Jump Filter',
                        subtitle: 'Prevents unrealistic sudden spikes in speed',
                        value: config.maxSpeedKmh,
                        min: 60.0,
                        max: 200.0,
                        divisions: 14,
                        unit: 'km/h',
                        onChanged: (val) {
                          final updated = GpsFilterConfig(
                            maxAccuracyMeters: config.maxAccuracyMeters,
                            maxSpeedKmh: val,
                            maxAccelerationMps2: config.maxAccelerationMps2,
                            minStationaryDistanceMeters: config.minStationaryDistanceMeters,
                            minMovingSpeedKmh: config.minMovingSpeedKmh,
                            enableKalmanFilter: config.enableKalmanFilter,
                            kalmanMeasurementNoise: config.kalmanMeasurementNoise,
                          );
                          context.read<SettingsBloc>().add(UpdateGpsSettingsEvent(updated));
                        },
                      ),
                      const Divider(color: AppColors.surfaceBorder, height: 24),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Smooth Route Line',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Smooths your route on the map for clear tracking',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        value: config.enableKalmanFilter,
                        activeTrackColor: AppColors.cyan,
                        onChanged: (enabled) {
                          final updated = GpsFilterConfig(
                            maxAccuracyMeters: config.maxAccuracyMeters,
                            maxSpeedKmh: config.maxSpeedKmh,
                            maxAccelerationMps2: config.maxAccelerationMps2,
                            minStationaryDistanceMeters: config.minStationaryDistanceMeters,
                            minMovingSpeedKmh: config.minMovingSpeedKmh,
                            enableKalmanFilter: enabled,
                            kalmanMeasurementNoise: config.kalmanMeasurementNoise,
                          );
                          context.read<SettingsBloc>().add(UpdateGpsSettingsEvent(updated));
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'MAP & DISPLAY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Dark Mode Map',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'High-contrast dark map style for easy viewing while riding',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        value: state.isDarkMode,
                        activeTrackColor: AppColors.cyan,
                        onChanged: (isDark) {
                          context.read<SettingsBloc>().add(ChangeMapStyleEvent(isDark));
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_done_rounded, size: 20, color: AppColors.emerald),
                        const SizedBox(width: 8),
                        Text(
                          'Automatic Cloud Backup',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your rides are automatically saved to your account. When you are offline, rides are saved safely on your device and backed up once you reconnect.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cyan.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${value.toStringAsFixed(0)} $unit',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.cyan,
          inactiveColor: AppColors.surfaceBorder,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
