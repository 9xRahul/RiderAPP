import '../repositories/trip_repository.dart';

class SyncOfflineTripsUseCase {
  final TripRepository repository;

  SyncOfflineTripsUseCase(this.repository);

  Future<int> call() {
    return repository.syncOfflineTrips();
  }
}
