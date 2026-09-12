import 'package:intl/intl.dart';

class Formatters {
  // Converts total seconds into standard digital timer string format
  static String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  // Converts meters into readable meters or kilometers depending on distance
  static String formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    final km = distanceMeters / 1000.0;
    return '${km.toStringAsFixed(2)} km';
  }

  // Formats speed in kilometers per hour with one decimal point
  static String formatSpeed(double speedKmh) {
    return speedKmh.toStringAsFixed(1);
  }

  // Formats timestamp for display in trip history cards
  static String formatTripDateTime(DateTime dt) {
    final formatter = DateFormat('MMM d, yyyy • h:mm a');
    return formatter.format(dt);
  }

  // Converts date times to UTC ISO 8601 strings for database storage
  static String formatIsoUtc(DateTime dt) {
    return dt.toUtc().toIso8601String();
  }
}
