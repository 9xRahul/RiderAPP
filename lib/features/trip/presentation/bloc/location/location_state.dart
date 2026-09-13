import 'package:equatable/equatable.dart';
import 'package:riderapp/core/constants/app_constants.dart';
import 'package:riderapp/features/trip/domain/entities/location_point.dart';

enum GpsSignalQuality {
  unknown,
  poor,
  moderate,
  good,
  excellent;

  String get label {
    switch (this) {
      case GpsSignalQuality.unknown:
        return 'Finding Location...';
      case GpsSignalQuality.poor:
        return 'Weak Signal';
      case GpsSignalQuality.moderate:
        return 'Fair Signal';
      case GpsSignalQuality.good:
        return 'Good Signal';
      case GpsSignalQuality.excellent:
        return 'Strong Signal';
    }
  }
}

class LocationState extends Equatable {
  final bool isPermissionGranted;
  final bool isServiceEnabled;
  final bool isTracking;
  final LocationPoint? rawLocation;
  final LocationPoint? filteredLocation;
  final GpsSignalQuality signalQuality;
  final GpsFilterConfig filterConfig;
  final String? lastFilterMessage;
  final int totalReceivedCount;
  final int totalAcceptedCount;
  final int totalRejectedCount;

  const LocationState({
    this.isPermissionGranted = false,
    this.isServiceEnabled = false,
    this.isTracking = false,
    this.rawLocation,
    this.filteredLocation,
    this.signalQuality = GpsSignalQuality.unknown,
    this.filterConfig = const GpsFilterConfig(),
    this.lastFilterMessage,
    this.totalReceivedCount = 0,
    this.totalAcceptedCount = 0,
    this.totalRejectedCount = 0,
  });

  LocationState copyWith({
    bool? isPermissionGranted,
    bool? isServiceEnabled,
    bool? isTracking,
    LocationPoint? rawLocation,
    LocationPoint? filteredLocation,
    GpsSignalQuality? signalQuality,
    GpsFilterConfig? filterConfig,
    String? lastFilterMessage,
    int? totalReceivedCount,
    int? totalAcceptedCount,
    int? totalRejectedCount,
  }) {
    return LocationState(
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isServiceEnabled: isServiceEnabled ?? this.isServiceEnabled,
      isTracking: isTracking ?? this.isTracking,
      rawLocation: rawLocation ?? this.rawLocation,
      filteredLocation: filteredLocation ?? this.filteredLocation,
      signalQuality: signalQuality ?? this.signalQuality,
      filterConfig: filterConfig ?? this.filterConfig,
      lastFilterMessage: lastFilterMessage ?? this.lastFilterMessage,
      totalReceivedCount: totalReceivedCount ?? this.totalReceivedCount,
      totalAcceptedCount: totalAcceptedCount ?? this.totalAcceptedCount,
      totalRejectedCount: totalRejectedCount ?? this.totalRejectedCount,
    );
  }

  @override
  List<Object?> get props => [
        isPermissionGranted,
        isServiceEnabled,
        isTracking,
        rawLocation,
        filteredLocation,
        signalQuality,
        filterConfig,
        lastFilterMessage,
        totalReceivedCount,
        totalAcceptedCount,
        totalRejectedCount,
      ];
}
