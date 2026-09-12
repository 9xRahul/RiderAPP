import '../repositories/trip_repository.dart';

class DeleteTripUseCase {
  final TripRepository repository;

  DeleteTripUseCase(this.repository);

  Future<void> call(String tripId) {
    return repository.deleteTrip(tripId);
  }
}
