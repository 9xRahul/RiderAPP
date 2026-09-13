import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riderapp/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../location/location_bloc.dart';
import '../location/location_event.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SharedPreferences prefs;
  final LocationBloc locationBloc;

  SettingsBloc({
    required this.prefs,
    required this.locationBloc,
  }) : super(const SettingsState()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateGpsSettingsEvent>(_onUpdateGpsSettings);
    on<ChangeMapStyleEvent>(_onChangeMapStyle);
  }

  void _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) {
    try {
      final configJson = prefs.getString(AppConstants.keyGpsConfig);
      GpsFilterConfig config = const GpsFilterConfig();
      if (configJson != null && configJson.isNotEmpty) {
        config = GpsFilterConfig.fromJson(jsonDecode(configJson));
      }

      final isDark = prefs.getBool(AppConstants.keyThemeMode) ?? true;

      emit(SettingsState(
        gpsConfig: config,
        isDarkMode: isDark,
        isLoaded: true,
      ));

      locationBloc.add(UpdateFilterConfigEvent(config));
    } catch (_) {
      emit(state.copyWith(isLoaded: true));
    }
  }

  Future<void> _onUpdateGpsSettings(
    UpdateGpsSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(gpsConfig: event.config));
    await prefs.setString(
      AppConstants.keyGpsConfig,
      jsonEncode(event.config.toJson()),
    );
    locationBloc.add(UpdateFilterConfigEvent(event.config));
  }

  Future<void> _onChangeMapStyle(
    ChangeMapStyleEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isDarkMode: event.isDarkMode));
    await prefs.setBool(AppConstants.keyThemeMode, event.isDarkMode);
  }
}
