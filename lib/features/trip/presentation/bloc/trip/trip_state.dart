import 'package:equatable/equatable.dart';
import '../../../domain/entities/location_point.dart';
import '../../../domain/entities/trip.dart';
import '../../../domain/entities/trip_metrics.dart';
import '../../../domain/entities/trip_status.dart';

abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

class TripInitialState extends TripState {
  const TripInitialState();
}

class TripLoadingState extends TripState {
  final String message;

  const TripLoadingState([this.message = 'Loading...']);

  @override
  List<Object?> get props => [message];
}

class TripActiveState extends TripState {
  final Trip trip;
  final TripMetrics metrics;
  final TripStatus status;
  final List<LocationPoint> points;
  final LocationPoint? lastPoint;
  final bool isRecovered;

  const TripActiveState({
    required this.trip,
    required this.metrics,
    required this.status,
    required this.points,
    this.lastPoint,
    this.isRecovered = false,
  });

  TripActiveState copyWith({
    Trip? trip,
    TripMetrics? metrics,
    TripStatus? status,
    List<LocationPoint>? points,
    LocationPoint? lastPoint,
    bool? isRecovered,
  }) {
    return TripActiveState(
      trip: trip ?? this.trip,
      metrics: metrics ?? this.metrics,
      status: status ?? this.status,
      points: points ?? this.points,
      lastPoint: lastPoint ?? this.lastPoint,
      isRecovered: isRecovered ?? this.isRecovered,
    );
  }

  @override
  List<Object?> get props => [
        trip,
        metrics,
        status,
        points,
        lastPoint,
        isRecovered,
      ];
}

class TripCompletedState extends TripState {
  final Trip trip;

  const TripCompletedState(this.trip);

  @override
  List<Object?> get props => [trip];
}

class TripErrorState extends TripState {
  final String message;

  const TripErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
