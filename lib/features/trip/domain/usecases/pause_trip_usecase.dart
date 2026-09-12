import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class PauseTripUseCase {
  final TripRepository repository;

  PauseTripUseCase(this.repository);

  Future<Trip> call(String tripId) {
    return repository.pauseTrip(tripId);
  }
}
