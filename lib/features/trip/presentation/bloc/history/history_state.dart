import 'package:equatable/equatable.dart';
import '../../../domain/entities/trip.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitialState extends HistoryState {
  const HistoryInitialState();
}

class HistoryLoadingState extends HistoryState {
  const HistoryLoadingState();
}

class HistoryLoadedState extends HistoryState {
  final List<Trip> trips;
  final bool isSyncing;
  final int pendingSyncCount;
  final String? statusMessage;

  const HistoryLoadedState({
    required this.trips,
    this.isSyncing = false,
    this.pendingSyncCount = 0,
    this.statusMessage,
  });

  HistoryLoadedState copyWith({
    List<Trip>? trips,
    bool? isSyncing,
    int? pendingSyncCount,
    String? statusMessage,
  }) {
    return HistoryLoadedState(
      trips: trips ?? this.trips,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  List<Object?> get props => [trips, isSyncing, pendingSyncCount, statusMessage];
}

class HistoryErrorState extends HistoryState {
  final String message;

  const HistoryErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
