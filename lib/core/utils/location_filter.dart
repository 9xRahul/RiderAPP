import '../constants/app_constants.dart';
import 'distance_calculator.dart';
import 'kalman_filter.dart';

// Holds the result of a GPS point evaluation with filtered coordinates and status
class LocationValidationResult {
  final bool isValid;
  final bool isStationary;
  final double filteredLat;
  final double filteredLng;
  final double speedKmh;
  final double distanceDeltaMeters;
  final String? rejectionReason;

  const LocationValidationResult({
    required this.isValid,
    required this.isStationary,
    required this.filteredLat,
    required this.filteredLng,
    required this.speedKmh,
    required this.distanceDeltaMeters,
    this.rejectionReason,
  });

  // Creates a rejected result with the original coordinates for logging
  factory LocationValidationResult.rejected(
    String reason, {
    required double lat,
    required double lng,
  }) {
    return LocationValidationResult(
      isValid: false,
      isStationary: false,
      filteredLat: lat,
      filteredLng: lng,
      speedKmh: 0.0,
      distanceDeltaMeters: 0.0,
      rejectionReason: reason,
    );
  }
}

// Multi-stage GPS filter pipeline that removes invalid fixes and smooths coordinates
class LocationFilterPipeline {
  final GpsFilterConfig config;
  final LocationKalmanFilter _kalmanPosFilter;
  final SpeedKalmanFilter _kalmanSpeedFilter;

  double? _lastValidLat;
  double? _lastValidLng;
  double _lastValidSpeedKmh = 0.0;
  DateTime? _lastValidTimestamp;

  LocationFilterPipeline({GpsFilterConfig? config})
      : config = config ?? const GpsFilterConfig(),
        _kalmanPosFilter = LocationKalmanFilter(
          processNoise: config?.kalmanMeasurementNoise ?? 3.0,
        ),
        _kalmanSpeedFilter = SpeedKalmanFilter();

  // Clears historical tracking state and Kalman estimates
  void reset() {
    _lastValidLat = null;
    _lastValidLng = null;
    _lastValidSpeedKmh = 0.0;
    _lastValidTimestamp = null;
    _kalmanPosFilter.reset();
    _kalmanSpeedFilter.reset();
  }

  // Evaluates a new GPS fix against accuracy limits speed spikes and stationary jitter
  LocationValidationResult evaluate({
    required double rawLat,
    required double rawLng,
    required double rawAccuracy,
    required double rawSpeedMps,
    required DateTime timestamp,
  }) {
    if (rawAccuracy > config.maxAccuracyMeters) {
      return LocationValidationResult.rejected(
        'Accuracy too low (${rawAccuracy.toStringAsFixed(1)}m > ${config.maxAccuracyMeters}m)',
        lat: rawLat,
        lng: rawLng,
      );
    }

    final bool hasHardwareSpeed = rawSpeedMps >= 0;
    final reportedSpeedKmh = hasHardwareSpeed ? rawSpeedMps * 3.6 : 0.0;

    if (_lastValidLat == null ||
        _lastValidLng == null ||
        _lastValidTimestamp == null) {
      final smoothed = config.enableKalmanFilter
          ? _kalmanPosFilter.filter(
              lat: rawLat,
              lng: rawLng,
              accuracyMeters: rawAccuracy,
              timestampMs: timestamp.millisecondsSinceEpoch,
            )
          : [rawLat, rawLng];

      final initialSpeed =
          reportedSpeedKmh < config.minMovingSpeedKmh ? 0.0 : reportedSpeedKmh;

      _lastValidLat = smoothed[0];
      _lastValidLng = smoothed[1];
      _lastValidSpeedKmh = initialSpeed;
      _lastValidTimestamp = timestamp;

      return LocationValidationResult(
        isValid: true,
        isStationary: initialSpeed == 0.0,
        filteredLat: smoothed[0],
        filteredLng: smoothed[1],
        speedKmh: initialSpeed,
        distanceDeltaMeters: 0.0,
      );
    }

    final timeDeltaSeconds =
        timestamp.difference(_lastValidTimestamp!).inMilliseconds / 1000.0;

    if (timeDeltaSeconds <= 0.1) {
      return LocationValidationResult.rejected(
        'Time delta too small (${timeDeltaSeconds.toStringAsFixed(2)}s)',
        lat: rawLat,
        lng: rawLng,
      );
    }

    final rawDistanceDelta = DistanceCalculator.distanceBetween(
      _lastValidLat!,
      _lastValidLng!,
      rawLat,
      rawLng,
    );

    final impliedSpeedKmh = (rawDistanceDelta / timeDeltaSeconds) * 3.6;

    if (impliedSpeedKmh > config.maxSpeedKmh) {
      return LocationValidationResult.rejected(
        'Implied speed spike (${impliedSpeedKmh.toStringAsFixed(1)} km/h)',
        lat: rawLat,
        lng: rawLng,
      );
    }

    if (hasHardwareSpeed &&
        reportedSpeedKmh < config.minMovingSpeedKmh &&
        rawDistanceDelta > 8.0) {
      return LocationValidationResult.rejected(
        'Multipath position jump while stationary (${rawDistanceDelta.toStringAsFixed(1)}m)',
        lat: rawLat,
        lng: rawLng,
      );
    }

    final speedDeltaKmh = (impliedSpeedKmh - _lastValidSpeedKmh).abs();
    final accelerationMps2 = (speedDeltaKmh / 3.6) / timeDeltaSeconds;
    if (timeDeltaSeconds < 3.0 &&
        accelerationMps2 > config.maxAccelerationMps2 &&
        rawDistanceDelta > 5.0) {
      return LocationValidationResult.rejected(
        'Excessive acceleration (${accelerationMps2.toStringAsFixed(1)} m/s2)',
        lat: rawLat,
        lng: rawLng,
      );
    }

    final isStationary = (hasHardwareSpeed &&
            reportedSpeedKmh < config.minMovingSpeedKmh &&
            rawDistanceDelta <= 8.0) ||
        rawDistanceDelta < config.minStationaryDistanceMeters ||
        impliedSpeedKmh < config.minMovingSpeedKmh;

    if (isStationary) {
      _lastValidSpeedKmh = 0.0;
      _lastValidTimestamp = timestamp;
      _kalmanSpeedFilter.reset();
      return LocationValidationResult(
        isValid: true,
        isStationary: true,
        filteredLat: _lastValidLat!,
        filteredLng: _lastValidLng!,
        speedKmh: 0.0,
        distanceDeltaMeters: 0.0,
      );
    }

    final effectiveSpeed = hasHardwareSpeed
        ? (reportedSpeedKmh < config.minMovingSpeedKmh ? 0.0 : reportedSpeedKmh)
        : impliedSpeedKmh;

    final smoothed = config.enableKalmanFilter
        ? _kalmanPosFilter.filter(
            lat: rawLat,
            lng: rawLng,
            accuracyMeters: rawAccuracy,
            timestampMs: timestamp.millisecondsSinceEpoch,
          )
        : [rawLat, rawLng];

    final filteredSpeed = config.enableKalmanFilter
        ? _kalmanSpeedFilter.filter(effectiveSpeed, rawAccuracy)
        : effectiveSpeed;

    final sanitizedSpeed =
        filteredSpeed < config.minMovingSpeedKmh ? 0.0 : filteredSpeed;

    final filteredDistanceDelta = DistanceCalculator.distanceBetween(
      _lastValidLat!,
      _lastValidLng!,
      smoothed[0],
      smoothed[1],
    );

    final sanitizedDistanceDelta =
        filteredDistanceDelta < config.minStationaryDistanceMeters
            ? 0.0
            : filteredDistanceDelta;

    _lastValidLat = smoothed[0];
    _lastValidLng = smoothed[1];
    _lastValidSpeedKmh = sanitizedSpeed;
    _lastValidTimestamp = timestamp;

    return LocationValidationResult(
      isValid: true,
      isStationary: sanitizedSpeed == 0.0 && sanitizedDistanceDelta == 0.0,
      filteredLat: smoothed[0],
      filteredLng: smoothed[1],
      speedKmh: sanitizedSpeed,
      distanceDeltaMeters: sanitizedDistanceDelta,
    );
  }
}
