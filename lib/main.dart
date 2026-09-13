import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/network/network_info.dart';
import 'core/theme/app_theme.dart';
import 'features/trip/data/datasources/location_datasource.dart';
import 'features/trip/data/datasources/trip_local_datasource.dart';
import 'features/trip/data/datasources/trip_remote_datasource.dart';
import 'features/trip/data/repositories/location_repository_impl.dart';
import 'features/trip/data/repositories/trip_repository_impl.dart';
import 'features/trip/domain/usecases/add_location_usecase.dart';
import 'features/trip/domain/usecases/end_trip_usecase.dart';
import 'features/trip/domain/usecases/get_active_trip_usecase.dart';
import 'features/trip/domain/usecases/get_trip_history_usecase.dart';
import 'features/trip/domain/usecases/pause_trip_usecase.dart';
import 'features/trip/domain/usecases/resume_trip_usecase.dart';
import 'features/trip/domain/usecases/start_trip_usecase.dart';
import 'features/trip/domain/usecases/sync_offline_trips_usecase.dart';
import 'features/trip/presentation/bloc/history/history_bloc.dart';
import 'features/trip/presentation/bloc/location/location_bloc.dart';
import 'features/trip/presentation/bloc/settings/settings_bloc.dart';
import 'features/trip/presentation/bloc/settings/settings_event.dart';
import 'features/trip/presentation/bloc/trip/trip_bloc.dart';
import 'features/trip/presentation/views/live_tracking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {}

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090D16),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final sharedPreferences = await SharedPreferences.getInstance();

  final networkInfo = NetworkInfoImpl();

  final localDataSource = TripLocalDataSourceImpl(sharedPreferences);
  final remoteDataSource = FirebaseTripRemoteDataSource();
  final locationDataSource = LocationDataSourceImpl();

  final tripRepository = TripRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    networkInfo: networkInfo,
  );
  final locationRepository = LocationRepositoryImpl(locationDataSource);

  final startTripUseCase = StartTripUseCase(tripRepository);
  final pauseTripUseCase = PauseTripUseCase(tripRepository);
  final resumeTripUseCase = ResumeTripUseCase(tripRepository);
  final endTripUseCase = EndTripUseCase(tripRepository);
  final addLocationUseCase = AddLocationUseCase(tripRepository);
  final getActiveTripUseCase = GetActiveTripUseCase(tripRepository);
  final getTripHistoryUseCase = GetTripHistoryUseCase(tripRepository);
  final syncOfflineTripsUseCase = SyncOfflineTripsUseCase(tripRepository);

  runApp(
    RiderApp(
      sharedPreferences: sharedPreferences,
      networkInfo: networkInfo,
      tripRepository: tripRepository,
      locationRepository: locationRepository,
      startTripUseCase: startTripUseCase,
      pauseTripUseCase: pauseTripUseCase,
      resumeTripUseCase: resumeTripUseCase,
      endTripUseCase: endTripUseCase,
      addLocationUseCase: addLocationUseCase,
      getActiveTripUseCase: getActiveTripUseCase,
      getTripHistoryUseCase: getTripHistoryUseCase,
      syncOfflineTripsUseCase: syncOfflineTripsUseCase,
    ),
  );
}

class RiderApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  final NetworkInfo networkInfo;
  final TripRepositoryImpl tripRepository;
  final LocationRepositoryImpl locationRepository;
  final StartTripUseCase startTripUseCase;
  final PauseTripUseCase pauseTripUseCase;
  final ResumeTripUseCase resumeTripUseCase;
  final EndTripUseCase endTripUseCase;
  final AddLocationUseCase addLocationUseCase;
  final GetActiveTripUseCase getActiveTripUseCase;
  final GetTripHistoryUseCase getTripHistoryUseCase;
  final SyncOfflineTripsUseCase syncOfflineTripsUseCase;

  const RiderApp({
    super.key,
    required this.sharedPreferences,
    required this.networkInfo,
    required this.tripRepository,
    required this.locationRepository,
    required this.startTripUseCase,
    required this.pauseTripUseCase,
    required this.resumeTripUseCase,
    required this.endTripUseCase,
    required this.addLocationUseCase,
    required this.getActiveTripUseCase,
    required this.getTripHistoryUseCase,
    required this.syncOfflineTripsUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TripBloc>(
          create: (context) => TripBloc(
            startTripUseCase: startTripUseCase,
            pauseTripUseCase: pauseTripUseCase,
            resumeTripUseCase: resumeTripUseCase,
            endTripUseCase: endTripUseCase,
            addLocationUseCase: addLocationUseCase,
            getActiveTripUseCase: getActiveTripUseCase,
          ),
        ),
        BlocProvider<LocationBloc>(
          create: (context) => LocationBloc(
            locationRepository: locationRepository,
            tripBloc: context.read<TripBloc>(),
          ),
        ),
        BlocProvider<HistoryBloc>(
          create: (context) => HistoryBloc(
            getTripHistoryUseCase: getTripHistoryUseCase,
            syncOfflineTripsUseCase: syncOfflineTripsUseCase,
            tripRepository: tripRepository,
            networkInfo: networkInfo,
          ),
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(
            prefs: sharedPreferences,
            locationBloc: context.read<LocationBloc>(),
          )..add(const LoadSettingsEvent()),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const LiveTrackingScreen(),
      ),
    );
  }
}
