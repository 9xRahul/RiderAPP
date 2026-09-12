import 'dart:math' as math;

// Smooths noisy GPS latitude and longitude readings using a 1D Kalman filter
class LocationKalmanFilter {
  final double processNoise;

  double? _lat;
  double? _lng;
  double _variance = -1.0;
  int? _lastTimestampMs;

  LocationKalmanFilter({this.processNoise = 3.0});

  void reset() {
    _lat = null;
    _lng = null;
    _variance = -1.0;
    _lastTimestampMs = null;
  }

  // Updates coordinate estimates by balancing sensor accuracy against elapsed time noise
  List<double> filter({
    required double lat,
    required double lng,
    required double accuracyMeters,
    required int timestampMs,
  }) {
    final accuracy = accuracyMeters < 1.0 ? 1.0 : accuracyMeters;

    if (_variance < 0 || _lat == null || _lng == null || _lastTimestampMs == null) {
      _lat = lat;
      _lng = lng;
      _variance = accuracy * accuracy;
      _lastTimestampMs = timestampMs;
      return [lat, lng];
    }

    final dt = (timestampMs - _lastTimestampMs!) / 1000.0;
    _lastTimestampMs = timestampMs;

    if (dt > 0) {
      _variance += dt * processNoise * processNoise;
    }

    final r = accuracy * accuracy;
    final k = _variance / (_variance + r);

    _lat = _lat! + k * (lat - _lat!);
    _lng = _lng! + k * (lng - _lng!);
    _variance = (1.0 - k) * _variance;

    return [_lat!, _lng!];
  }

  double? get currentLat => _lat;
  double? get currentLng => _lng;
}

// Smooths instant speed readings to prevent jumpy gauge needle movements
class SpeedKalmanFilter {
  double _speed = 0.0;
  double _variance = 4.0;
  final double _processNoise = 1.5;

  void reset() {
    _speed = 0.0;
    _variance = 4.0;
  }

  // Applies Kalman gain to filter out GPS speed measurement noise
  double filter(double measuredSpeed, double accuracy) {
    if (measuredSpeed < 0) measuredSpeed = 0.0;
    final r = math.max(1.0, accuracy * 0.5);

    _variance += _processNoise;
    final k = _variance / (_variance + r);
    _speed = _speed + k * (measuredSpeed - _speed);
    _variance = (1.0 - k) * _variance;

    return math.max(0.0, _speed);
  }
}
