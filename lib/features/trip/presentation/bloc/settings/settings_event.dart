import 'package:equatable/equatable.dart';
import 'package:riderapp/core/constants/app_constants.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class UpdateGpsSettingsEvent extends SettingsEvent {
  final GpsFilterConfig config;

  const UpdateGpsSettingsEvent(this.config);

  @override
  List<Object?> get props => [config];
}

class ChangeMapStyleEvent extends SettingsEvent {
  final bool isDarkMode;

  const ChangeMapStyleEvent(this.isDarkMode);

  @override
  List<Object?> get props => [isDarkMode];
}
