import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class LocationPoint extends Equatable {
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double accuracyMeters;
  final double? altitude;
  final double? heading;
  final DateTime timestamp;
  final bool isFiltered;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.accuracyMeters,
    this.altitude,
    this.heading,
    required this.timestamp,
    this.isFiltered = false,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    double? speedKmh,
    double? accuracyMeters,
    double? altitude,
    double? heading,
    DateTime? timestamp,
    bool? isFiltered,
  }) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedKmh: speedKmh ?? this.speedKmh,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      isFiltered: isFiltered ?? this.isFiltered,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        speedKmh,
        accuracyMeters,
        altitude,
        heading,
        timestamp,
        isFiltered,
      ];
}
