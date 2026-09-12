import '../../domain/entities/location_point.dart';

class LocationPointDto {
  final double latitude;
  final double longitude;
  final double speed;
  final double accuracy;
  final double? altitude;
  final double? heading;
  final String timestamp;
  final bool? isFiltered;

  LocationPointDto({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    this.altitude,
    this.heading,
    required this.timestamp,
    this.isFiltered,
  });

  factory LocationPointDto.fromEntity(LocationPoint entity) {
    return LocationPointDto(
      latitude: entity.latitude,
      longitude: entity.longitude,
      speed: entity.speedKmh,
      accuracy: entity.accuracyMeters,
      altitude: entity.altitude,
      heading: entity.heading,
      timestamp: entity.timestamp.toUtc().toIso8601String(),
      isFiltered: entity.isFiltered,
    );
  }

  LocationPoint toEntity() {
    DateTime parsedTime;
    try {
      parsedTime = DateTime.parse(timestamp).toLocal();
    } catch (_) {
      parsedTime = DateTime.now();
    }
    return LocationPoint(
      latitude: latitude,
      longitude: longitude,
      speedKmh: speed,
      accuracyMeters: accuracy,
      altitude: altitude,
      heading: heading,
      timestamp: parsedTime,
      isFiltered: isFiltered ?? false,
    );
  }

  Map<String, dynamic> toJson({String? tripId}) {
    final map = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'accuracy': accuracy,
      'timestamp': timestamp,
    };
    if (tripId != null) map['tripId'] = tripId;
    if (altitude != null) map['altitude'] = altitude;
    if (heading != null) map['heading'] = heading;
    if (isFiltered != null) map['isFiltered'] = isFiltered;
    return map;
  }

  factory LocationPointDto.fromJson(Map<dynamic, dynamic> json) {
    String effectiveTimestamp;
    final rawTs = json['timestamp'];
    if (rawTs is String) {
      effectiveTimestamp = rawTs;
    } else if (rawTs != null) {
      try {
        if (rawTs.runtimeType.toString().contains('Timestamp')) {
          effectiveTimestamp = (rawTs as dynamic).toDate().toUtc().toIso8601String();
        } else {
          effectiveTimestamp = rawTs.toString();
        }
      } catch (_) {
        effectiveTimestamp = DateTime.now().toUtc().toIso8601String();
      }
    } else {
      effectiveTimestamp = DateTime.now().toUtc().toIso8601String();
    }

    final latNum = json['latitude'] ?? json['lat'];
    final lngNum = json['longitude'] ?? json['lng'];
    final speedNum = json['speed'] ?? json['speedKmh'];
    final accNum = json['accuracy'] ?? json['accuracyMeters'];

    return LocationPointDto(
      latitude: (latNum as num?)?.toDouble() ?? 0.0,
      longitude: (lngNum as num?)?.toDouble() ?? 0.0,
      speed: (speedNum as num?)?.toDouble() ?? 0.0,
      accuracy: (accNum as num?)?.toDouble() ?? 0.0,
      altitude: (json['altitude'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      timestamp: effectiveTimestamp,
      isFiltered: json['isFiltered'] as bool?,
    );
  }
}
