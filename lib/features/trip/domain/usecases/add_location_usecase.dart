import '../entities/location_point.dart';
import '../entities/trip_metrics.dart';
import '../repositories/trip_repository.dart';

class AddLocationUseCase {
  final TripRepository repository;

  AddLocationUseCase(this.repository);

  Future<void> call(
    String tripId,
    LocationPoint point,
    TripMetrics currentMetrics,
  ) {
    return repository.addLocationPoint(tripId, point, currentMetrics);
  }
}
