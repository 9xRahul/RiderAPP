import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/location_point_dto.dart';
import '../models/trip_dto.dart';

abstract class TripLocalDataSource {
  Future<void> saveActiveTrip(TripDto trip);
  Future<TripDto?> getActiveTrip();
  Future<void> clearActiveTrip();

  Future<void> saveCompletedTrip(TripDto trip);
  Future<List<TripDto>> getCompletedTrips();
  Future<TripDto?> getTripById(String tripId);

  Future<void> queueOfflineLocation(String tripId, LocationPointDto point);
  Future<List<Map<String, dynamic>>> getQueuedLocations();
  Future<void> clearQueuedLocations(List<String> pointIdsOrTimestamps);

  Future<void> queuePendingTripSync(TripDto trip);
  Future<List<TripDto>> getPendingTripSyncs();
  Future<void> removePendingTripSync(String tripId);
  Future<void> deleteTrip(String tripId);
  Future<void> clearAll();
}

class TripLocalDataSourceImpl implements TripLocalDataSource {
  final SharedPreferences _prefs;

  TripLocalDataSourceImpl(this._prefs);

  // Persists currently running trip state to survive app restarts
  @override
  Future<void> saveActiveTrip(TripDto trip) async {
    final jsonStr = jsonEncode(trip.toJson());
    await _prefs.setString(AppConstants.keyActiveTrip, jsonStr);
  }

  // Loads the stored active trip if one was in progress
  @override
  Future<TripDto?> getActiveTrip() async {
    final jsonStr = _prefs.getString(AppConstants.keyActiveTrip);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return TripDto.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // Clears the active trip key once ride completes
  @override
  Future<void> clearActiveTrip() async {
    await _prefs.remove(AppConstants.keyActiveTrip);
  }

  // Adds or updates a finalized trip record in the local history list
  @override
  Future<void> saveCompletedTrip(TripDto trip) async {
    final trips = await getCompletedTrips();
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index >= 0) {
      trips[index] = trip;
    } else {
      trips.insert(0, trip);
    }
    final encoded = jsonEncode(trips.map((t) => t.toJson()).toList());
    await _prefs.setString(AppConstants.keyTripHistory, encoded);
  }

  // Reads all locally stored completed trips
  @override
  Future<List<TripDto>> getCompletedTrips() async {
    final raw = _prefs.getString(AppConstants.keyTripHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final List<TripDto> trips = [];
      for (final item in decoded) {
        if (item is Map) {
          try {
            trips.add(TripDto.fromJson(item));
          } catch (_) {}
        }
      }
      return trips;
    } catch (_) {
      return [];
    }
  }

  // Fetches a single trip by ID from active or completed cache
  @override
  Future<TripDto?> getTripById(String tripId) async {
    final active = await getActiveTrip();
    if (active != null && active.id == tripId) return active;

    final history = await getCompletedTrips();
    try {
      return history.firstWhere((t) => t.id == tripId);
    } catch (_) {
      return null;
    }
  }

  // Stores a location fix locally when network is unavailable
  @override
  Future<void> queueOfflineLocation(String tripId, LocationPointDto point) async {
    final queue = await getQueuedLocations();
    final item = point.toJson(tripId: tripId);
    queue.add(item);
    await _prefs.setString(AppConstants.keyOfflineQueue, jsonEncode(queue));
  }

  // Reads the list of pending offline location points
  @override
  Future<List<Map<String, dynamic>>> getQueuedLocations() async {
    final raw = _prefs.getString(AppConstants.keyOfflineQueue);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // Removes successfully synchronized location points from the offline queue
  @override
  Future<void> clearQueuedLocations(List<String> timestamps) async {
    final queue = await getQueuedLocations();
    queue.removeWhere((item) => timestamps.contains(item['timestamp'] as String?));
    await _prefs.setString(AppConstants.keyOfflineQueue, jsonEncode(queue));
  }

  @override
  Future<void> queuePendingTripSync(TripDto trip) async {
    final pending = await getPendingTripSyncs();
    final index = pending.indexWhere((t) => t.id == trip.id);
    if (index >= 0) {
      pending[index] = trip;
    } else {
      pending.add(trip);
    }
    await _prefs.setString(
      AppConstants.keyPendingTripSyncs,
      jsonEncode(pending.map((t) => t.toJson()).toList()),
    );
  }

  @override
  Future<List<TripDto>> getPendingTripSyncs() async {
    final raw = _prefs.getString(AppConstants.keyPendingTripSyncs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final List<TripDto> pending = [];
      for (final item in decoded) {
        if (item is Map) {
          try {
            pending.add(TripDto.fromJson(item));
          } catch (_) {}
        }
      }
      return pending;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> removePendingTripSync(String tripId) async {
    final pending = await getPendingTripSyncs();
    pending.removeWhere((t) => t.id == tripId);
    await _prefs.setString(
      AppConstants.keyPendingTripSyncs,
      jsonEncode(pending.map((t) => t.toJson()).toList()),
    );
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    final trips = await getCompletedTrips();
    trips.removeWhere((t) => t.id == tripId);
    final encoded = jsonEncode(trips.map((t) => t.toJson()).toList());
    await _prefs.setString(AppConstants.keyTripHistory, encoded);
    await removePendingTripSync(tripId);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(AppConstants.keyActiveTrip);
    await _prefs.remove(AppConstants.keyTripHistory);
    await _prefs.remove(AppConstants.keyOfflineQueue);
    await _prefs.remove(AppConstants.keyPendingTripSyncs);
  }
}
