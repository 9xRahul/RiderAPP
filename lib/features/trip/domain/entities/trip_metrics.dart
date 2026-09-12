import 'package:equatable/equatable.dart';

class TripMetrics extends Equatable {
  final double distanceMeters;
  final double currentSpeedKmh;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final int durationSeconds;
  final int pointsCount;
  final int filteredPointsCount;

  const TripMetrics({
    this.distanceMeters = 0.0,
    this.currentSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
    this.durationSeconds = 0,
    this.pointsCount = 0,
    this.filteredPointsCount = 0,
  });

  TripMetrics copyWith({
    double? distanceMeters,
    double? currentSpeedKmh,
    double? maxSpeedKmh,
    double? avgSpeedKmh,
    int? durationSeconds,
    int? pointsCount,
    int? filteredPointsCount,
  }) {
    return TripMetrics(
      distanceMeters: distanceMeters ?? this.distanceMeters,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      pointsCount: pointsCount ?? this.pointsCount,
      filteredPointsCount: filteredPointsCount ?? this.filteredPointsCount,
    );
  }

  @override
  List<Object?> get props => [
        distanceMeters,
        currentSpeedKmh,
        maxSpeedKmh,
        avgSpeedKmh,
        durationSeconds,
        pointsCount,
        filteredPointsCount,
      ];
}
