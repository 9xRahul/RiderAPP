import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/location_point.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_metrics.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_local_datasource.dart';
import '../datasources/trip_remote_datasource.dart';
import '../models/location_point_dto.dart';
import '../models/trip_dto.dart';

class TripRepositoryImpl implements TripRepository {
  final TripLocalDataSource localDataSource;
  final TripRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final Uuid _uuid = const Uuid();

  TripRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  // Creates a new trip entry in local storage and attempts cloud synchronization
  @override
  Future<Trip> startTrip({
    String? tripId,
    String? riderId,
    LocationPoint? initialLocation,
  }) async {
    final effectiveTripId = tripId ?? 'TRIP-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final effectiveRiderId = riderId ?? 'RIDER-101';
    final startTime = DateTime.now();

    final List<LocationPoint> points = [];
    if (initialLocation != null) {
      points.add(initialLocation);
    }

    final initialMetrics = TripMetrics(
      distanceMeters: 0.0,
      currentSpeedKmh: initialLocation?.speedKmh ?? 0.0,
      maxSpeedKmh: initialLocation?.speedKmh ?? 0.0,
      avgSpeedKmh: 0.0,
      durationSeconds: 0,
      pointsCount: points.length,
      filteredPointsCount: 0,
    );

    final trip = Trip(
      id: effectiveTripId,
      riderId: effectiveRiderId,
      startTime: startTime,
      status: TripStatus.active,
      points: points,
      metrics: initialMetrics,
      isSynced: false,
    );

    final tripDto = TripDto.fromEntity(trip);

    await localDataSource.saveActiveTrip(tripDto);

    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        await remoteDataSource.startTrip(tripDto);
      } catch (_) {
        await localDataSource.queuePendingTripSync(tripDto);
      }
    } else {
      await localDataSource.queuePendingTripSync(tripDto);
    }

    return trip;
  }

  // Updates the active trip status to paused in local storage
  @override
  Future<Trip> pauseTrip(String tripId) async {
    final active = await localDataSource.getActiveTrip();
    if (active != null && active.id == tripId) {
      final updated = active.toEntity().copyWith(status: TripStatus.paused);
      final updatedDto = TripDto.fromEntity(updated);
      await localDataSource.saveActiveTrip(updatedDto);
      return updated;
    }
    throw Exception('Trip not found or not active');
  }

  // Restores the active trip status back to running
  @override
  Future<Trip> resumeTrip(String tripId) async {
    final active = await localDataSource.getActiveTrip();
    if (active != null && active.id == tripId) {
      final updated = active.toEntity().copyWith(status: TripStatus.active);
      final updatedDto = TripDto.fromEntity(updated);
      await localDataSource.saveActiveTrip(updatedDto);
      return updated;
    }
    throw Exception('Trip not found');
  }

  // Saves the finalized trip with route metrics and queues cloud sync if offline
  @override
  Future<Trip> endTrip(
    String tripId, {
    LocationPoint? finalLocation,
    TripMetrics? finalMetrics,
  }) async {
    final active = await localDataSource.getActiveTrip();
    Trip currentTrip;

    if (active != null && active.id == tripId) {
      currentTrip = active.toEntity();
    } else {
      final fallback = await localDataSource.getTripById(tripId);
      if (fallback != null) {
        currentTrip = fallback.toEntity();
      } else {
        throw Exception('Trip $tripId not found');
      }
    }

    final points = List<LocationPoint>.from(currentTrip.points);
    if (finalLocation != null) {
      points.add(finalLocation);
    }

    final metrics = finalMetrics ?? currentTrip.metrics;
    final endTime = DateTime.now();

    final completedTrip = currentTrip.copyWith(
      endTime: endTime,
      status: TripStatus.completed,
      points: points,
      metrics: metrics,
    );

    final completedDto = TripDto.fromEntity(completedTrip);

    await localDataSource.saveCompletedTrip(completedDto);
    await localDataSource.clearActiveTrip();

    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        await remoteDataSource.endTrip(completedDto);
        final syncedTrip = completedTrip.copyWith(isSynced: true);
        await localDataSource.saveCompletedTrip(TripDto.fromEntity(syncedTrip));
        await localDataSource.removePendingTripSync(tripId);
        return syncedTrip;
      } catch (_) {
        await localDataSource.queuePendingTripSync(completedDto);
      }
    } else {
      await localDataSource.queuePendingTripSync(completedDto);
    }

    return completedTrip;
  }

  // Appends a new coordinate to active trip and queues upload for background sync
  @override
  Future<void> addLocationPoint(
    String tripId,
    LocationPoint point,
    TripMetrics currentMetrics,
  ) async {
    final activeDto = await localDataSource.getActiveTrip();
    if (activeDto != null && activeDto.id == tripId) {
      final trip = activeDto.toEntity();
      final updatedPoints = List<LocationPoint>.from(trip.points)..add(point);
      final updatedTrip = trip.copyWith(
        points: updatedPoints,
        metrics: currentMetrics,
      );
      await localDataSource.saveActiveTrip(TripDto.fromEntity(updatedTrip));
    }

    final pointDto = LocationPointDto.fromEntity(point);

    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        await remoteDataSource.uploadLocation(tripId, pointDto);
      } catch (_) {
        await localDataSource.queueOfflineLocation(tripId, pointDto);
      }
    } else {
      await localDataSource.queueOfflineLocation(tripId, pointDto);
    }
  }

  // Retrieves any unfinished active trip found in local storage
  @override
  Future<Trip?> getActiveTrip() async {
    final activeDto = await localDataSource.getActiveTrip();
    if (activeDto == null) return null;
    return activeDto.toEntity().copyWith(isRecovered: true);
  }

  // Combines local trip records with cloud history ordered by start time
  @override
  Future<List<Trip>> getTripHistory() async {
    final localDtos = await localDataSource.getCompletedTrips();
    final Map<String, TripDto> tripMap = {
      for (final t in localDtos) t.id: t,
    };

    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        final remoteTrips = await remoteDataSource.getAllTrips();
        for (final remoteTrip in remoteTrips) {
          final localTrip = tripMap[remoteTrip.id];
          if (localTrip != null) {
            final mergedPoints = localTrip.points.isNotEmpty
                ? localTrip.points
                : remoteTrip.points;
            final merged = TripDto(
              id: remoteTrip.id,
              riderId: remoteTrip.riderId,
              startTime: remoteTrip.startTime.isNotEmpty
                  ? remoteTrip.startTime
                  : localTrip.startTime,
              endTime: remoteTrip.endTime ?? localTrip.endTime,
              status: remoteTrip.status,
              points: mergedPoints,
              metrics: remoteTrip.metrics.isNotEmpty
                  ? remoteTrip.metrics
                  : localTrip.metrics,
              isSynced: true,
              isRecovered: false,
            );
            tripMap[remoteTrip.id] = merged;
            await localDataSource.saveCompletedTrip(merged);
          } else {
            final syncedTrip = TripDto(
              id: remoteTrip.id,
              riderId: remoteTrip.riderId,
              startTime: remoteTrip.startTime,
              endTime: remoteTrip.endTime,
              status: remoteTrip.status,
              points: remoteTrip.points,
              metrics: remoteTrip.metrics,
              isSynced: true,
              isRecovered: false,
            );
            tripMap[remoteTrip.id] = syncedTrip;
            await localDataSource.saveCompletedTrip(syncedTrip);
          }
        }
      } catch (_) {}
    }

    final allTrips = tripMap.values.map((dto) => dto.toEntity()).toList();
    allTrips.sort((a, b) => b.startTime.compareTo(a.startTime));
    return allTrips;
  }

  // Fetches a single trip with full route coordinates from local or cloud storage
  @override
  Future<Trip?> getTripById(String tripId) async {
    final localDto = await localDataSource.getTripById(tripId);
    if (localDto != null && localDto.points.isNotEmpty) {
      return localDto.toEntity();
    }

    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        final remoteTrip = await remoteDataSource.getTrip(tripId);
        if (remoteTrip != null) {
          var points = remoteTrip.points;
          if (points.isEmpty) {
            points = await remoteDataSource.getTripLocations(tripId);
          }
          final fullTripDto = TripDto(
            id: remoteTrip.id,
            riderId: remoteTrip.riderId,
            startTime: remoteTrip.startTime,
            endTime: remoteTrip.endTime,
            status: remoteTrip.status,
            points: points.isNotEmpty ? points : (localDto?.points ?? []),
            metrics: remoteTrip.metrics.isNotEmpty
                ? remoteTrip.metrics
                : (localDto?.metrics ?? {}),
            isSynced: true,
          );
          await localDataSource.saveCompletedTrip(fullTripDto);
          return fullTripDto.toEntity();
        }
      } catch (_) {}
    }

    return localDto?.toEntity();
  }

  // Uploads pending offline points and uncommitted trip status updates to Firestore
  @override
  Future<int> syncOfflineTrips() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) return 0;

    int syncedCount = 0;

    final queuedLocations = await localDataSource.getQueuedLocations();
    if (queuedLocations.isNotEmpty) {
      try {
        final count = await remoteDataSource.uploadLocationsBatch(queuedLocations);
        final timestamps = queuedLocations
            .map((e) => e['timestamp'] as String?)
            .whereType<String>()
            .toList();
        await localDataSource.clearQueuedLocations(timestamps);
        syncedCount += count;
      } catch (_) {}
    }

    final pendingTrips = await localDataSource.getPendingTripSyncs();
    for (final tripDto in pendingTrips) {
      try {
        if (tripDto.status == TripStatus.completed.name) {
          await remoteDataSource.endTrip(tripDto);
        } else {
          await remoteDataSource.startTrip(tripDto);
        }
        await localDataSource.removePendingTripSync(tripDto.id);

        final existing = await localDataSource.getTripById(tripDto.id);
        if (existing != null) {
          final updated = TripDto.fromEntity(existing.toEntity().copyWith(isSynced: true));
          await localDataSource.saveCompletedTrip(updated);
        }
        syncedCount++;
      } catch (_) {}
    }

    return syncedCount;
  }

  // Deletes a trip record from both local cache and remote database
  @override
  Future<void> deleteTrip(String tripId) async {
    await localDataSource.deleteTrip(tripId);

    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        await remoteDataSource.deleteTrip(tripId);
      } catch (_) {}
    }
  }

  // Removes all stored trip history from both local storage and remote database
  @override
  Future<void> clearHistory() async {
    await localDataSource.clearAll();

    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        await remoteDataSource.deleteAllTrips();
      } catch (_) {}
    }
  }
}
