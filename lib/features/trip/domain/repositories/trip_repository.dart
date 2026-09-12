import '../entities/location_point.dart';
import '../entities/trip.dart';
import '../entities/trip_metrics.dart';

abstract class TripRepository {
  Future<Trip> startTrip({
    String? tripId,
    String? riderId,
    LocationPoint? initialLocation,
  });

  Future<Trip> pauseTrip(String tripId);

  Future<Trip> resumeTrip(String tripId);

  Future<Trip> endTrip(
    String tripId, {
    LocationPoint? finalLocation,
    TripMetrics? finalMetrics,
  });

  Future<void> addLocationPoint(String tripId, LocationPoint point, TripMetrics currentMetrics);

  Future<Trip?> getActiveTrip();

  Future<List<Trip>> getTripHistory();

  Future<Trip?> getTripById(String tripId);

  Future<int> syncOfflineTrips();

  Future<void> deleteTrip(String tripId);

  Future<void> clearHistory();
}
