import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/location_point.dart';
import '../../../domain/entities/trip_status.dart';
import '../../../domain/usecases/add_location_usecase.dart';
import '../../../domain/usecases/end_trip_usecase.dart';
import '../../../domain/usecases/get_active_trip_usecase.dart';
import '../../../domain/usecases/pause_trip_usecase.dart';
import '../../../domain/usecases/resume_trip_usecase.dart';
import '../../../domain/usecases/start_trip_usecase.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  final StartTripUseCase startTripUseCase;
  final PauseTripUseCase pauseTripUseCase;
  final ResumeTripUseCase resumeTripUseCase;
  final EndTripUseCase endTripUseCase;
  final AddLocationUseCase addLocationUseCase;
  final GetActiveTripUseCase getActiveTripUseCase;

  Timer? _durationTimer;

  TripBloc({
    required this.startTripUseCase,
    required this.pauseTripUseCase,
    required this.resumeTripUseCase,
    required this.endTripUseCase,
    required this.addLocationUseCase,
    required this.getActiveTripUseCase,
  }) : super(const TripInitialState()) {
    on<CheckActiveTripEvent>(_onCheckActiveTrip);
    on<StartTripEvent>(_onStartTrip);
    on<PauseTripEvent>(_onPauseTrip);
    on<ResumeTripEvent>(_onResumeTrip);
    on<EndTripEvent>(_onEndTrip);
    on<ProcessNewLocationEvent>(_onProcessNewLocation);
    on<TripTimerTickEvent>(_onTripTimerTick);
    on<ResetTripToIdleEvent>(_onResetTripToIdle);
  }

  // Recovers uncompleted ride state if the app was closed during an active trip
  Future<void> _onCheckActiveTrip(
    CheckActiveTripEvent event,
    Emitter<TripState> emit,
  ) async {
    try {
      final activeTrip = await getActiveTripUseCase();
      if (activeTrip != null && (activeTrip.status.isActive || activeTrip.status.isPaused)) {
        emit(TripActiveState(
          trip: activeTrip,
          metrics: activeTrip.metrics,
          status: activeTrip.status,
          points: activeTrip.points,
          lastPoint: activeTrip.points.isNotEmpty ? activeTrip.points.last : null,
          isRecovered: true,
        ));

        if (activeTrip.status.isActive) {
          _startTimer();
        }
      }
    } catch (_) {}
  }

  // Initializes a new trip session and begins the duration timer
  Future<void> _onStartTrip(
    StartTripEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripLoadingState('Starting ride...'));
    try {
      final trip = await startTripUseCase(
        riderId: event.riderId,
        initialLocation: event.initialLocation,
      );

      _startTimer();

      emit(TripActiveState(
        trip: trip,
        metrics: trip.metrics,
        status: TripStatus.active,
        points: trip.points,
        lastPoint: event.initialLocation,
        isRecovered: false,
      ));
    } catch (_) {
      emit(const TripErrorState('Unable to start ride. Please ensure location is enabled.'));
    }
  }

  // Pauses ride tracking and stops the duration timer
  Future<void> _onPauseTrip(
    PauseTripEvent event,
    Emitter<TripState> emit,
  ) async {
    final currentState = state;
    if (currentState is TripActiveState && currentState.status.isActive) {
      _stopTimer();
      try {
        final updatedTrip = await pauseTripUseCase(currentState.trip.id);
        emit(currentState.copyWith(
          trip: updatedTrip,
          status: TripStatus.paused,
        ));
      } catch (_) {
        emit(const TripErrorState('Unable to pause ride. Please try again.'));
      }
    }
  }

  // Resumes ride tracking and restarts the duration timer
  Future<void> _onResumeTrip(
    ResumeTripEvent event,
    Emitter<TripState> emit,
  ) async {
    final currentState = state;
    if (currentState is TripActiveState && currentState.status.isPaused) {
      try {
        final updatedTrip = await resumeTripUseCase(currentState.trip.id);
        _startTimer();
        emit(currentState.copyWith(
          trip: updatedTrip,
          status: TripStatus.active,
        ));
      } catch (_) {
        emit(const TripErrorState('Unable to resume ride. Please try again.'));
      }
    }
  }

  // Finalizes ride data calculates final summary and saves the completed trip
  Future<void> _onEndTrip(
    EndTripEvent event,
    Emitter<TripState> emit,
  ) async {
    final currentState = state;
    if (currentState is TripActiveState) {
      _stopTimer();
      emit(const TripLoadingState('Saving your ride...'));
      try {
        final completedTrip = await endTripUseCase(
          currentState.trip.id,
          finalLocation: event.finalLocation,
          finalMetrics: currentState.metrics,
        );
        emit(TripCompletedState(completedTrip));
      } catch (_) {
        emit(const TripErrorState('Unable to save ride. Please try again.'));
      }
    }
  }

  // Updates real time distance speed and route points when receiving validated GPS coordinates
  Future<void> _onProcessNewLocation(
    ProcessNewLocationEvent event,
    Emitter<TripState> emit,
  ) async {
    final currentState = state;
    if (currentState is TripActiveState && currentState.status.isActive) {
      final point = event.point;

      if (event.isStationary) {
        final updatedMetrics = currentState.metrics.copyWith(
          currentSpeedKmh: 0.0,
        );

        emit(currentState.copyWith(
          metrics: updatedMetrics,
          lastPoint: point,
        ));
        return;
      }

      final distanceDelta = event.distanceDeltaMeters;
      final updatedDistance = currentState.metrics.distanceMeters + distanceDelta;
      final updatedCurrentSpeed = point.speedKmh < 1.0 ? 0.0 : point.speedKmh;
      final updatedMaxSpeed = updatedCurrentSpeed > currentState.metrics.maxSpeedKmh
          ? updatedCurrentSpeed
          : currentState.metrics.maxSpeedKmh;

      final durationSeconds = currentState.metrics.durationSeconds;
      final avgSpeed = (durationSeconds > 0 && updatedDistance > 10.0)
          ? (updatedDistance / durationSeconds) * 3.6
          : 0.0;

      final updatedMetrics = currentState.metrics.copyWith(
        distanceMeters: updatedDistance,
        currentSpeedKmh: updatedCurrentSpeed,
        maxSpeedKmh: updatedMaxSpeed,
        avgSpeedKmh: avgSpeed,
        pointsCount: currentState.metrics.pointsCount + 1,
      );

      final updatedPoints = List<LocationPoint>.from(currentState.points)..add(point);
      final updatedTrip = currentState.trip.copyWith(
        points: updatedPoints,
        metrics: updatedMetrics,
      );

      emit(currentState.copyWith(
        trip: updatedTrip,
        metrics: updatedMetrics,
        points: updatedPoints,
        lastPoint: point,
      ));

      unawaited(addLocationUseCase(
        currentState.trip.id,
        point,
        updatedMetrics,
      ));
    }
  }

  // Increments elapsed ride duration every second and updates average speed
  void _onTripTimerTick(
    TripTimerTickEvent event,
    Emitter<TripState> emit,
  ) {
    final currentState = state;
    if (currentState is TripActiveState && currentState.status.isActive) {
      final newDuration = currentState.metrics.durationSeconds + 1;
      final newAvgSpeed = (newDuration > 0 && currentState.metrics.distanceMeters > 10.0)
          ? (currentState.metrics.distanceMeters / newDuration) * 3.6
          : 0.0;

      final updatedMetrics = currentState.metrics.copyWith(
        durationSeconds: newDuration,
        avgSpeedKmh: newAvgSpeed,
      );

      emit(currentState.copyWith(
        metrics: updatedMetrics,
        trip: currentState.trip.copyWith(metrics: updatedMetrics),
      ));
    }
  }

  void _onResetTripToIdle(
    ResetTripToIdleEvent event,
    Emitter<TripState> emit,
  ) {
    _stopTimer();
    emit(const TripInitialState());
  }

  void _startTimer() {
    _stopTimer();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const TripTimerTickEvent());
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
