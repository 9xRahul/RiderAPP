import '../entities/location_point.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class StartTripUseCase {
  final TripRepository repository;

  StartTripUseCase(this.repository);

  Future<Trip> call({
    String? tripId,
    String? riderId,
    LocationPoint? initialLocation,
  }) {
    return repository.startTrip(
      tripId: tripId,
      riderId: riderId,
      initialLocation: initialLocation,
    );
  }
}
