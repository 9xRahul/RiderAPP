import 'package:equatable/equatable.dart';
import 'package:riderapp/core/constants/app_constants.dart';

class SettingsState extends Equatable {
  final GpsFilterConfig gpsConfig;
  final bool isDarkMode;
  final bool isLoaded;

  const SettingsState({
    this.gpsConfig = const GpsFilterConfig(),
    this.isDarkMode = true,
    this.isLoaded = false,
  });

  SettingsState copyWith({
    GpsFilterConfig? gpsConfig,
    bool? isDarkMode,
    bool? isLoaded,
  }) {
    return SettingsState(
      gpsConfig: gpsConfig ?? this.gpsConfig,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [
        gpsConfig,
        isDarkMode,
        isLoaded,
      ];
}
