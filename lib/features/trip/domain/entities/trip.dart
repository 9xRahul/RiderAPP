import 'package:equatable/equatable.dart';
import 'location_point.dart';
import 'trip_metrics.dart';
import 'trip_status.dart';

class Trip extends Equatable {
  final String id;
  final String riderId;
  final DateTime startTime;
  final DateTime? endTime;
  final TripStatus status;
  final List<LocationPoint> points;
  final TripMetrics metrics;
  final bool isSynced;
  final bool isRecovered;

  const Trip({
    required this.id,
    required this.riderId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.points,
    required this.metrics,
    this.isSynced = false,
    this.isRecovered = false,
  });

  Trip copyWith({
    String? id,
    String? riderId,
    DateTime? startTime,
    DateTime? endTime,
    TripStatus? status,
    List<LocationPoint>? points,
    TripMetrics? metrics,
    bool? isSynced,
    bool? isRecovered,
  }) {
    return Trip(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      points: points ?? this.points,
      metrics: metrics ?? this.metrics,
      isSynced: isSynced ?? this.isSynced,
      isRecovered: isRecovered ?? this.isRecovered,
    );
  }

  @override
  List<Object?> get props => [
        id,
        riderId,
        startTime,
        endTime,
        status,
        points,
        metrics,
        isSynced,
        isRecovered,
      ];
}
