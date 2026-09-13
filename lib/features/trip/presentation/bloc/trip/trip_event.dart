import 'package:equatable/equatable.dart';
import '../../../domain/entities/location_point.dart';

abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object?> get props => [];
}

class CheckActiveTripEvent extends TripEvent {
  const CheckActiveTripEvent();
}

class StartTripEvent extends TripEvent {
  final String? riderId;
  final LocationPoint? initialLocation;

  const StartTripEvent({this.riderId, this.initialLocation});

  @override
  List<Object?> get props => [riderId, initialLocation];
}

class PauseTripEvent extends TripEvent {
  const PauseTripEvent();
}

class ResumeTripEvent extends TripEvent {
  const ResumeTripEvent();
}

class EndTripEvent extends TripEvent {
  final LocationPoint? finalLocation;

  const EndTripEvent({this.finalLocation});

  @override
  List<Object?> get props => [finalLocation];
}

class ProcessNewLocationEvent extends TripEvent {
  final LocationPoint point;
  final double distanceDeltaMeters;
  final bool isStationary;

  const ProcessNewLocationEvent({
    required this.point,
    required this.distanceDeltaMeters,
    required this.isStationary,
  });

  @override
  List<Object?> get props => [point, distanceDeltaMeters, isStationary];
}

class TripTimerTickEvent extends TripEvent {
  const TripTimerTickEvent();
}

class ResetTripToIdleEvent extends TripEvent {
  const ResetTripToIdleEvent();
}
