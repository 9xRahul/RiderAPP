import 'dart:async';
import '../../domain/entities/location_point.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource dataSource;

  LocationRepositoryImpl(this.dataSource);

  @override
  Stream<LocationPoint> getLocationStream() {
    return dataSource.getRawLocationStream();
  }

  @override
  Future<LocationPoint> getCurrentLocation() {
    return dataSource.getCurrentLocation();
  }

  @override
  Future<bool> checkAndRequestPermissions() {
    return dataSource.checkAndRequestPermissions();
  }

  @override
  Future<bool> isLocationServiceEnabled() {
    return dataSource.isLocationServiceEnabled();
  }
}
