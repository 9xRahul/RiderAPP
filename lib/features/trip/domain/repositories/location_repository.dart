import '../entities/location_point.dart';

abstract class LocationRepository {
  Stream<LocationPoint> getLocationStream();
  Future<LocationPoint> getCurrentLocation();
  Future<bool> checkAndRequestPermissions();
  Future<bool> isLocationServiceEnabled();
}
