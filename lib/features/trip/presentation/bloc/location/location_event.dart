import 'package:equatable/equatable.dart';
import 'package:riderapp/core/constants/app_constants.dart';
import 'package:riderapp/features/trip/domain/entities/location_point.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeLocationEvent extends LocationEvent {
  const InitializeLocationEvent();
}

class RawLocationReceivedEvent extends LocationEvent {
  final LocationPoint point;

  const RawLocationReceivedEvent(this.point);

  @override
  List<Object?> get props => [point];
}

class UpdateFilterConfigEvent extends LocationEvent {
  final GpsFilterConfig config;

  const UpdateFilterConfigEvent(this.config);

  @override
  List<Object?> get props => [config];
}

class ResetLocationFilterEvent extends LocationEvent {
  const ResetLocationFilterEvent();
}
