import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class ResumeTripUseCase {
  final TripRepository repository;

  ResumeTripUseCase(this.repository);

  Future<Trip> call(String tripId) {
    return repository.resumeTrip(tripId);
  }
}
