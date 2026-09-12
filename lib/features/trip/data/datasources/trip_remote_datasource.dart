import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/location_point_dto.dart';
import '../models/trip_dto.dart';

abstract class TripRemoteDataSource {
  Future<bool> startTrip(TripDto trip);
  Future<bool> uploadLocation(String tripId, LocationPointDto location);
  Future<int> uploadLocationsBatch(List<Map<String, dynamic>> queuedLocations);
  Future<bool> endTrip(TripDto trip);
  Future<TripDto?> getTrip(String tripId);
  Future<List<TripDto>> getAllTrips();
  Future<List<LocationPointDto>> getTripLocations(String tripId);
  Future<bool> deleteTrip(String tripId);
  Future<bool> deleteAllTrips();
}

class FirebaseTripRemoteDataSource implements TripRemoteDataSource {
  FirebaseFirestore? _firestoreInstance;
  bool _isFirebaseInitialized = false;

  FirebaseTripRemoteDataSource({FirebaseFirestore? firestore})
      : _firestoreInstance = firestore {
    _initFirebase();
  }

  bool get isFirebaseInitialized => _isFirebaseInitialized;

  Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance ??= FirebaseFirestore.instance;
        _isFirebaseInitialized = true;
      }
    } catch (_) {
      _isFirebaseInitialized = false;
    }
  }

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance = FirebaseFirestore.instance;
        _isFirebaseInitialized = true;
        return _firestoreInstance;
      }
    } catch (_) {
      _isFirebaseInitialized = false;
    }
    return null;
  }

  @override
  Future<bool> startTrip(TripDto trip) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      await firestore.collection('trips').doc(trip.id).set({
        'tripId': trip.id,
        'id': trip.id,
        'riderId': trip.riderId,
        'startTime': trip.startTime,
        'status': trip.status,
        'metrics': trip.metrics,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> uploadLocation(String tripId, LocationPointDto location) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      final docId = location.timestamp.replaceAll(':', '-');
      await firestore
          .collection('trips')
          .doc(tripId)
          .collection('locations')
          .doc(docId)
          .set(location.toJson(tripId: tripId));

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int> uploadLocationsBatch(List<Map<String, dynamic>> queuedLocations) async {
    final firestore = _firestore;
    if (firestore == null || queuedLocations.isEmpty) return 0;

    try {
      final batch = firestore.batch();
      int count = 0;

      for (final payload in queuedLocations) {
        final tripId = payload['tripId'] as String? ?? 'UNKNOWN';
        final timestamp = payload['timestamp'] as String? ??
            DateTime.now().toUtc().toIso8601String();
        final docId = timestamp.replaceAll(':', '-');

        final docRef = firestore
            .collection('trips')
            .doc(tripId)
            .collection('locations')
            .doc(docId);

        batch.set(docRef, payload, SetOptions(merge: true));
        count++;

        if (count >= 450) break;
      }

      await batch.commit();
      return count;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<bool> endTrip(TripDto trip) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      await firestore.collection('trips').doc(trip.id).set({
        'tripId': trip.id,
        'id': trip.id,
        'riderId': trip.riderId,
        'startTime': trip.startTime,
        'endTime': trip.endTime,
        'status': trip.status,
        'metrics': trip.metrics,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<TripDto?> getTrip(String tripId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('trips').doc(tripId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return TripDto.fromJson(data, doc.id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TripDto>> getAllTrips() async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await firestore
            .collection('trips')
            .orderBy('updatedAt', descending: true)
            .get();
      } catch (_) {
        snapshot = await firestore.collection('trips').get();
      }

      final List<TripDto> trips = [];
      for (final doc in snapshot.docs) {
        if (doc.exists && doc.data().isNotEmpty) {
          try {
            final tripDto = TripDto.fromJson(doc.data(), doc.id);
            if (tripDto.id.isNotEmpty) {
              trips.add(tripDto);
            }
          } catch (_) {}
        }
      }
      return trips;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<LocationPointDto>> getTripLocations(String tripId) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('trips')
          .doc(tripId)
          .collection('locations')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => LocationPointDto.fromJson(doc.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> deleteTrip(String tripId) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      final locationsSnapshot = await firestore
          .collection('trips')
          .doc(tripId)
          .collection('locations')
          .get();

      if (locationsSnapshot.docs.isNotEmpty) {
        final batch = firestore.batch();
        for (final locDoc in locationsSnapshot.docs) {
          batch.delete(locDoc.reference);
        }
        await batch.commit();
      }

      await firestore.collection('trips').doc(tripId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteAllTrips() async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      final tripsSnapshot = await firestore.collection('trips').get();
      for (final tripDoc in tripsSnapshot.docs) {
        final locationsSnapshot =
            await tripDoc.reference.collection('locations').get();
        if (locationsSnapshot.docs.isNotEmpty) {
          final batch = firestore.batch();
          for (final locDoc in locationsSnapshot.docs) {
            batch.delete(locDoc.reference);
          }
          await batch.commit();
        }
        await tripDoc.reference.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
