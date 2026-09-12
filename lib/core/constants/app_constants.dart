import 'package:latlong2/latlong.dart';

class AppConstants {
  static const String appName = 'Rider Tracker';
  static const String appVersion = '1.0.0';

  static const String keyActiveTrip = 'active_trip_state';
  static const String keyTripHistory = 'completed_trips_history';
  static const String keyOfflineQueue = 'offline_points_queue';
  static const String keyPendingTripSyncs = 'pending_trip_syncs';
  static const String keyGpsConfig = 'gps_filter_settings';
  static const String keyThemeMode = 'app_theme_mode';
  static const String keyBackendUrl = 'backend_api_url';

  static const LatLng defaultLocation = LatLng(37.7749, -122.4194);
  static const double defaultZoom = 16.5;

  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> mapSubdomains = [];
}

class GpsFilterConfig {
  final double maxAccuracyMeters;
  final double maxSpeedKmh;
  final double maxAccelerationMps2;
  final double minStationaryDistanceMeters;
  final double minMovingSpeedKmh;
  final bool enableKalmanFilter;
  final double kalmanMeasurementNoise;

  const GpsFilterConfig({
    this.maxAccuracyMeters = 30.0,
    this.maxSpeedKmh = 140.0,
    this.maxAccelerationMps2 = 8.5,
    this.minStationaryDistanceMeters = 5.0,
    this.minMovingSpeedKmh = 2.5,
    this.enableKalmanFilter = true,
    this.kalmanMeasurementNoise = 3.0,
  });

  Map<String, dynamic> toJson() => {
    'maxAccuracyMeters': maxAccuracyMeters,
    'maxSpeedKmh': maxSpeedKmh,
    'maxAccelerationMps2': maxAccelerationMps2,
    'minStationaryDistanceMeters': minStationaryDistanceMeters,
    'minMovingSpeedKmh': minMovingSpeedKmh,
    'enableKalmanFilter': enableKalmanFilter,
    'kalmanMeasurementNoise': kalmanMeasurementNoise,
  };

  factory GpsFilterConfig.fromJson(Map<String, dynamic> json) {
    return GpsFilterConfig(
      maxAccuracyMeters:
          (json['maxAccuracyMeters'] as num?)?.toDouble() ?? 30.0,
      maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble() ?? 140.0,
      maxAccelerationMps2:
          (json['maxAccelerationMps2'] as num?)?.toDouble() ?? 8.5,
      minStationaryDistanceMeters:
          (json['minStationaryDistanceMeters'] as num?)?.toDouble() ?? 5.0,
      minMovingSpeedKmh: (json['minMovingSpeedKmh'] as num?)?.toDouble() ?? 2.5,
      enableKalmanFilter: json['enableKalmanFilter'] as bool? ?? true,
      kalmanMeasurementNoise:
          (json['kalmanMeasurementNoise'] as num?)?.toDouble() ?? 3.0,
    );
  }
}
