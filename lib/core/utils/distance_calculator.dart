import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class DistanceCalculator {
  static const double earthRadiusMeters = 6371000.0;

  // Uses the Haversine formula to calculate distance in meters between two GPS points
  static double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final dLat = _degToRad(endLat - startLat);
    final dLng = _degToRad(endLng - startLng);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(startLat)) *
            math.cos(_degToRad(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  // Convenience helper when working directly with LatLng objects
  static double distanceBetweenLatLng(LatLng from, LatLng to) {
    return distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  // Calculates the compass bearing in degrees between two points
  static double bearingBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final lat1 = _degToRad(startLat);
    final lat2 = _degToRad(endLat);
    final dLng = _degToRad(endLng - startLng);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = (bearingRad * 180.0 / math.pi + 360.0) % 360.0;
    return bearingDeg;
  }

  // Converts angles from degrees to radians for trigonometric math
  static double _degToRad(double degree) => degree * (math.pi / 180.0);
}
