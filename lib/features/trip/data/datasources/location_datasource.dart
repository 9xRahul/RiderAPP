import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location_point.dart';

abstract class LocationDataSource {
  Stream<LocationPoint> getRawLocationStream();
  Future<LocationPoint> getCurrentLocation();
  Future<bool> checkAndRequestPermissions();
  Future<bool> isLocationServiceEnabled();
}

class LocationDataSourceImpl implements LocationDataSource {
  // Streams high frequency GPS positions with platform specific background service settings
  @override
  Stream<LocationPoint> getRawLocationStream() {
    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Recording your route in the background',
          notificationTitle: 'Ride in Progress',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings).map(
      (pos) => LocationPoint(
        latitude: pos.latitude,
        longitude: pos.longitude,
        speedKmh: pos.speed >= 0 ? pos.speed * 3.6 : 0.0,
        accuracyMeters: pos.accuracy,
        altitude: pos.altitude,
        heading: pos.heading,
        timestamp: pos.timestamp,
      ),
    );
  }

  // Reads the single current device coordinate using high accuracy mode
  @override
  Future<LocationPoint> getCurrentLocation() async {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return LocationPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      speedKmh: pos.speed >= 0 ? pos.speed * 3.6 : 0.0,
      accuracyMeters: pos.accuracy,
      altitude: pos.altitude,
      heading: pos.heading,
      timestamp: pos.timestamp,
    );
  }

  // Prompts the user for foreground and background GPS location permissions
  @override
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Checks if device location hardware is active
  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}
