import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class GetTripHistoryUseCase {
  final TripRepository repository;

  GetTripHistoryUseCase(this.repository);

  Future<List<Trip>> call() {
    return repository.getTripHistory();
  }
}
