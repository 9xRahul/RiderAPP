import '../entities/location_point.dart';
import '../entities/trip.dart';
import '../entities/trip_metrics.dart';
import '../repositories/trip_repository.dart';

class EndTripUseCase {
  final TripRepository repository;

  EndTripUseCase(this.repository);

  Future<Trip> call(
    String tripId, {
    LocationPoint? finalLocation,
    TripMetrics? finalMetrics,
  }) {
    return repository.endTrip(
      tripId,
      finalLocation: finalLocation,
      finalMetrics: finalMetrics,
    );
  }
}
