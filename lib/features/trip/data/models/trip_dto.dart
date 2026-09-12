import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_metrics.dart';
import '../../domain/entities/trip_status.dart';
import 'location_point_dto.dart';

class TripDto {
  final String id;
  final String riderId;
  final String startTime;
  final String? endTime;
  final String status;
  final List<LocationPointDto> points;
  final Map<String, dynamic> metrics;
  final bool isSynced;
  final bool isRecovered;

  TripDto({
    required this.id,
    required this.riderId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.points,
    required this.metrics,
    this.isSynced = false,
    this.isRecovered = false,
  });

  factory TripDto.fromEntity(Trip entity) {
    return TripDto(
      id: entity.id,
      riderId: entity.riderId,
      startTime: entity.startTime.toUtc().toIso8601String(),
      endTime: entity.endTime?.toUtc().toIso8601String(),
      status: entity.status.name,
      points: entity.points.map((p) => LocationPointDto.fromEntity(p)).toList(),
      metrics: {
        'distanceMeters': entity.metrics.distanceMeters,
        'currentSpeedKmh': entity.metrics.currentSpeedKmh,
        'maxSpeedKmh': entity.metrics.maxSpeedKmh,
        'avgSpeedKmh': entity.metrics.avgSpeedKmh,
        'durationSeconds': entity.metrics.durationSeconds,
        'pointsCount': entity.metrics.pointsCount,
        'filteredPointsCount': entity.metrics.filteredPointsCount,
      },
      isSynced: entity.isSynced,
      isRecovered: entity.isRecovered,
    );
  }

  Trip toEntity() {
    final statusEnum = TripStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => TripStatus.idle,
    );

    DateTime parsedStart;
    try {
      parsedStart = DateTime.parse(startTime).toLocal();
    } catch (_) {
      parsedStart = DateTime.now();
    }

    DateTime? parsedEnd;
    if (endTime != null && endTime!.isNotEmpty) {
      try {
        parsedEnd = DateTime.parse(endTime!).toLocal();
      } catch (_) {
        parsedEnd = null;
      }
    }

    return Trip(
      id: id,
      riderId: riderId,
      startTime: parsedStart,
      endTime: parsedEnd,
      status: statusEnum,
      points: points.map((p) => p.toEntity()).toList(),
      metrics: TripMetrics(
        distanceMeters: (metrics['distanceMeters'] as num?)?.toDouble() ?? 0.0,
        currentSpeedKmh: (metrics['currentSpeedKmh'] as num?)?.toDouble() ?? 0.0,
        maxSpeedKmh: (metrics['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
        avgSpeedKmh: (metrics['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0,
        durationSeconds: (metrics['durationSeconds'] as num?)?.toInt() ?? 0,
        pointsCount: (metrics['pointsCount'] as num?)?.toInt() ?? points.length,
        filteredPointsCount:
            (metrics['filteredPointsCount'] as num?)?.toInt() ?? 0,
      ),
      isSynced: isSynced,
      isRecovered: isRecovered,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': id,
        'riderId': riderId,
        'startTime': startTime,
        'endTime': endTime,
        'status': status,
        'points': points.map((p) => p.toJson()).toList(),
        'metrics': metrics,
        'isSynced': isSynced,
        'isRecovered': isRecovered,
      };

  factory TripDto.fromJson(Map<dynamic, dynamic> json, [String? docId]) {
    final rawId = json['id'] ?? json['tripId'] ?? docId ?? '';
    final effectiveId = rawId.toString();

    String effectiveStartTime;
    final rawStartTime = json['startTime'];
    if (rawStartTime is String) {
      effectiveStartTime = rawStartTime;
    } else if (rawStartTime != null) {
      try {
        if (rawStartTime.runtimeType.toString().contains('Timestamp')) {
          effectiveStartTime =
              (rawStartTime as dynamic).toDate().toUtc().toIso8601String();
        } else {
          effectiveStartTime = rawStartTime.toString();
        }
      } catch (_) {
        effectiveStartTime = DateTime.now().toUtc().toIso8601String();
      }
    } else {
      effectiveStartTime = DateTime.now().toUtc().toIso8601String();
    }

    String? effectiveEndTime;
    final rawEndTime = json['endTime'];
    if (rawEndTime is String) {
      effectiveEndTime = rawEndTime;
    } else if (rawEndTime != null) {
      try {
        if (rawEndTime.runtimeType.toString().contains('Timestamp')) {
          effectiveEndTime =
              (rawEndTime as dynamic).toDate().toUtc().toIso8601String();
        } else {
          effectiveEndTime = rawEndTime.toString();
        }
      } catch (_) {
        effectiveEndTime = null;
      }
    }

    final rawMetrics = json['metrics'];
    final Map<String, dynamic> metricsMap = rawMetrics is Map
        ? rawMetrics.map((k, v) => MapEntry(k.toString(), v))
        : {};

    final rawPoints = json['points'];
    final List<LocationPointDto> pointsList = [];
    if (rawPoints is List) {
      for (final p in rawPoints) {
        if (p is Map) {
          try {
            pointsList.add(LocationPointDto.fromJson(p));
          } catch (_) {}
        }
      }
    }

    return TripDto(
      id: effectiveId,
      riderId: json['riderId'] as String? ?? 'RIDER-01',
      startTime: effectiveStartTime,
      endTime: effectiveEndTime,
      status: json['status'] as String? ?? 'completed',
      points: pointsList,
      metrics: metricsMap,
      isSynced: json['isSynced'] as bool? ?? false,
      isRecovered: json['isRecovered'] as bool? ?? false,
    );
  }
}
