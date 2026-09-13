import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadTripHistoryEvent extends HistoryEvent {
  const LoadTripHistoryEvent();
}

class TriggerSyncEvent extends HistoryEvent {
  const TriggerSyncEvent();
}

class DeleteTripEvent extends HistoryEvent {
  final String tripId;

  const DeleteTripEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class ClearHistoryEvent extends HistoryEvent {
  const ClearHistoryEvent();
}
