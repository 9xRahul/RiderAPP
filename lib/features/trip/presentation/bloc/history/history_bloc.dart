import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riderapp/core/network/network_info.dart';
import 'package:riderapp/features/trip/domain/repositories/trip_repository.dart';
import 'package:riderapp/features/trip/domain/usecases/get_trip_history_usecase.dart';
import 'package:riderapp/features/trip/domain/usecases/sync_offline_trips_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetTripHistoryUseCase getTripHistoryUseCase;
  final SyncOfflineTripsUseCase syncOfflineTripsUseCase;
  final TripRepository tripRepository;
  final NetworkInfo networkInfo;

  StreamSubscription<bool>? _connectivitySubscription;

  HistoryBloc({
    required this.getTripHistoryUseCase,
    required this.syncOfflineTripsUseCase,
    required this.tripRepository,
    required this.networkInfo,
  }) : super(const HistoryInitialState()) {
    on<LoadTripHistoryEvent>(_onLoadTripHistory);
    on<TriggerSyncEvent>(_onTriggerSync);
    on<DeleteTripEvent>(_onDeleteTrip);
    on<ClearHistoryEvent>(_onClearHistory);

    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((connected) {
      if (connected) {
        add(const TriggerSyncEvent());
      }
    });
  }

  Future<void> _onLoadTripHistory(
    LoadTripHistoryEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoadingState());
    try {
      final trips = await getTripHistoryUseCase();
      final pendingCount = trips.where((t) => !t.isSynced).length;

      emit(HistoryLoadedState(
        trips: trips,
        pendingSyncCount: pendingCount,
      ));
    } catch (_) {
      emit(const HistoryErrorState('Unable to load ride history.'));
    }
  }

  Future<void> _onTriggerSync(
    TriggerSyncEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is HistoryLoadedState) {
      emit(currentState.copyWith(isSyncing: true));
    }

    try {
      final syncedCount = await syncOfflineTripsUseCase();
      final trips = await getTripHistoryUseCase();
      final pendingCount = trips.where((t) => !t.isSynced).length;

      emit(HistoryLoadedState(
        trips: trips,
        isSyncing: false,
        pendingSyncCount: pendingCount,
        statusMessage: syncedCount > 0
            ? 'Backed up $syncedCount ${syncedCount == 1 ? 'ride' : 'rides'} successfully'
            : 'All rides are up to date',
      ));
    } catch (_) {
      if (state is HistoryLoadedState) {
        emit((state as HistoryLoadedState).copyWith(
          isSyncing: false,
          statusMessage: 'Backup paused. Will sync automatically when online.',
        ));
      }
    }
  }

  Future<void> _onDeleteTrip(
    DeleteTripEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is HistoryLoadedState) {
      final updatedTrips =
          currentState.trips.where((t) => t.id != event.tripId).toList();
      final pendingCount = updatedTrips.where((t) => !t.isSynced).length;
      emit(currentState.copyWith(
        trips: updatedTrips,
        pendingSyncCount: pendingCount,
        statusMessage: 'Ride deleted',
      ));
    }

    try {
      await tripRepository.deleteTrip(event.tripId);
    } catch (_) {
      final trips = await getTripHistoryUseCase();
      final pendingCount = trips.where((t) => !t.isSynced).length;
      emit(HistoryLoadedState(
        trips: trips,
        pendingSyncCount: pendingCount,
        statusMessage: 'Unable to delete ride',
      ));
    }
  }

  Future<void> _onClearHistory(
    ClearHistoryEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoadingState());
    try {
      await tripRepository.clearHistory();
      emit(const HistoryLoadedState(
        trips: [],
        pendingSyncCount: 0,
        statusMessage: 'All rides deleted',
      ));
    } catch (_) {
      emit(const HistoryErrorState('Unable to clear ride history.'));
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
