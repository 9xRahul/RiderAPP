import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riderapp/core/constants/app_constants.dart';
import 'package:riderapp/core/utils/location_filter.dart';
import 'package:riderapp/features/trip/domain/entities/location_point.dart';
import 'package:riderapp/features/trip/domain/repositories/location_repository.dart';
import '../trip/trip_bloc.dart';
import '../trip/trip_event.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository locationRepository;
  final TripBloc tripBloc;
  final LocationFilterPipeline _filterPipeline;

  StreamSubscription<LocationPoint>? _locationSubscription;

  LocationBloc({
    required this.locationRepository,
    required this.tripBloc,
    GpsFilterConfig? filterConfig,
  })  : _filterPipeline = LocationFilterPipeline(config: filterConfig),
        super(LocationState(
          filterConfig: filterConfig ?? const GpsFilterConfig(),
        )) {
    on<InitializeLocationEvent>(_onInitializeLocation);
    on<RawLocationReceivedEvent>(_onRawLocationReceived);
    on<UpdateFilterConfigEvent>(_onUpdateFilterConfig);
    on<ResetLocationFilterEvent>(_onResetLocationFilter);
  }

  Future<void> _onInitializeLocation(
    InitializeLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    final serviceEnabled = await locationRepository.isLocationServiceEnabled();
    final permissionGranted = await locationRepository.checkAndRequestPermissions();

    emit(state.copyWith(
      isServiceEnabled: serviceEnabled,
      isPermissionGranted: permissionGranted,
      isTracking: serviceEnabled && permissionGranted,
    ));

    if (permissionGranted) {
      try {
        final currentPos = await locationRepository.getCurrentLocation();
        add(RawLocationReceivedEvent(currentPos));
      } catch (_) {}

      await _locationSubscription?.cancel();
      _locationSubscription = locationRepository.getLocationStream().listen(
        (point) => add(RawLocationReceivedEvent(point)),
        onError: (_) {},
      );
    }
  }

  void _onRawLocationReceived(
    RawLocationReceivedEvent event,
    Emitter<LocationState> emit,
  ) {
    _handleLocationPoint(event.point, emit);
  }

  void _handleLocationPoint(
    LocationPoint rawPoint,
    Emitter<LocationState> emit,
  ) {
    final validation = _filterPipeline.evaluate(
      rawLat: rawPoint.latitude,
      rawLng: rawPoint.longitude,
      rawAccuracy: rawPoint.accuracyMeters,
      rawSpeedMps: rawPoint.speedKmh / 3.6,
      timestamp: rawPoint.timestamp,
    );

    final GpsSignalQuality quality;
    if (rawPoint.accuracyMeters <= 5.0) {
      quality = GpsSignalQuality.excellent;
    } else if (rawPoint.accuracyMeters <= 15.0) {
      quality = GpsSignalQuality.good;
    } else if (rawPoint.accuracyMeters <= 30.0) {
      quality = GpsSignalQuality.moderate;
    } else {
      quality = GpsSignalQuality.poor;
    }

    final totalReceived = state.totalReceivedCount + 1;

    if (!validation.isValid) {
      emit(state.copyWith(
        rawLocation: rawPoint,
        signalQuality: quality,
        lastFilterMessage: validation.rejectionReason,
        totalReceivedCount: totalReceived,
        totalRejectedCount: state.totalRejectedCount + 1,
      ));
      return;
    }

    final filteredPoint = LocationPoint(
      latitude: validation.filteredLat,
      longitude: validation.filteredLng,
      speedKmh: validation.speedKmh,
      accuracyMeters: rawPoint.accuracyMeters,
      altitude: rawPoint.altitude,
      heading: rawPoint.heading,
      timestamp: rawPoint.timestamp,
      isFiltered: true,
    );

    emit(state.copyWith(
      rawLocation: rawPoint,
      filteredLocation: filteredPoint,
      signalQuality: quality,
      lastFilterMessage: validation.isStationary ? 'Stationary - Jitter Suppressed' : 'Coordinate Accepted',
      totalReceivedCount: totalReceived,
      totalAcceptedCount: state.totalAcceptedCount + 1,
    ));

    tripBloc.add(ProcessNewLocationEvent(
      point: filteredPoint,
      distanceDeltaMeters: validation.distanceDeltaMeters,
      isStationary: validation.isStationary,
    ));
  }

  void _onUpdateFilterConfig(
    UpdateFilterConfigEvent event,
    Emitter<LocationState> emit,
  ) {
    emit(state.copyWith(filterConfig: event.config));
  }

  void _onResetLocationFilter(
    ResetLocationFilterEvent event,
    Emitter<LocationState> emit,
  ) {
    _filterPipeline.reset();
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
