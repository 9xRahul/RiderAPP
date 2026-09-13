# RiderAPP - Real-Time GPS Tracking & Telemetry Mobile Application

RiderAPP is a high-performance Flutter mobile application built for motorcycle and bicycle riders. It tracks active trips with real-time GPS telemetry, speedometer readouts, multi-stage GPS jump filtering, offline-first local caching, and cloud synchronization with Firebase Cloud Firestore.

---

## Why OpenStreetMap (OSM) Instead of Google Maps

We used **OpenStreetMap via `flutter_map`** rather than Google Maps for the following reasons:

1. **No API Keys or Billing Setup**: Google Maps requires setting up a Google Cloud Console project, enabling billing, generating platform keys, and configuring Android/iOS manifests. Missing or invalid keys result in blank screens. `flutter_map` works immediately after cloning with zero setup.
2. **Pure Flutter Canvas Rendering**: Google Maps relies on native platform views (`AndroidView`/`UiKitView`), which add synchronization overhead and can stutter when updating high-frequency GPS points. `flutter_map` renders inside Flutter's native canvas for smooth 60 FPS map and marker rendering.
3. **Cross-Platform Compatibility**: Runs out of the box on Android, iOS, Web, Windows, macOS, and Linux without platform view configuration.
4. **Tile Customization & Offline Support**: Allows using free dark-mode map tiles (CartoDB Dark Matter, OSM Standard) and caching tiles locally for low-connectivity routes.

---

## Core Technologies & System Architecture

### 1. Backend & Cloud Synchronization (Firebase Cloud Firestore)
The application integrates with Firebase Cloud Firestore for real-time cloud persistence:

* **`trips` Collection**: Stores trip session documents (`trips/{tripId}`). Each document stores trip identifiers, rider ID, start and end timestamps, status (`active`, `paused`, `completed`), and aggregated metrics (total distance in meters, top speed, average speed, duration, and coordinate count).
* **`trips/{tripId}/locations` Sub-collection**: Stores chronological GPS waypoint documents (`latitude`, `longitude`, `speed`, `accuracy`, `altitude`, `heading`, `timestamp`).
* **Batch Uploads & Synchronization**: Location points are batched up to 450 documents per Firestore write batch for network efficiency and write cost optimization.

### 2. Local Storage & Crash Recovery (`SharedPreferences`)
Local storage serves as the primary source of truth to ensure the app works with zero latency and full offline capability:

* **Active Trip Persistence**: On every accepted GPS point, the entire active trip state (route points, distance, timer duration, current speed) is committed to local disk storage (`key: active_trip`).
* **Terminated App State Recovery**: If the operating system terminates the app, the battery dies, or the phone reboots mid-ride, reopening the app detects the ongoing session (`CheckActiveTripEvent`) and restores the exact distance, duration, waypoints, and tracking state with zero data loss.
* **Offline Location Queue**: When riding without internet, location waypoints and trip lifecycle events are appended to a persistent offline queue (`key: offline_location_queue`).
* **Automatic Background Sync**: `connectivity_plus` monitors internet status. When network connectivity is restored, `HistoryBloc` automatically flushes the offline queue and uploads pending trips to Firestore.

### 3. Real-Time GPS Tracking & Background Service (`geolocator`)
* **Foreground Service (Android)**: Configured with `ForegroundNotificationConfig` to run a continuous Android foreground service with an ongoing notification ("Ride in Progress") and CPU wake lock (`WAKE_LOCK`) so tracking never pauses when the screen is turned off.
* **Background Location (iOS)**: Configured with `AppleSettings` using automotive navigation mode (`ActivityType.automotiveNavigation`), persistent background location indicator, and background execution modes (`UIBackgroundModes: location, fetch, processing`).
* **Location Frequency**: Configured for high navigation accuracy with a distance filter of 0 meters to receive all raw sensor updates for mathematical filter evaluation.

### 4. GPS Noise & Jitter Filtering Pipeline (`LocationFilterPipeline`)
Raw mobile GPS hardware is susceptible to signal multipath reflections near buildings, sensor noise, and stationary drift. All incoming fixes are evaluated through a four-stage pipeline:

* **Horizontal Accuracy Filter**: Rejects fixes with horizontal accuracy error greater than 30 meters.
* **Speed Spike & Teleportation Rejection**: Calculates the implied velocity between the previous valid point and the new point using the Haversine formula ($\text{Speed} = \Delta \text{Distance} / \Delta \text{Time}$). If implied speed exceeds 140 km/h, the point is discarded as a teleportation jump.
* **Stationary Drift Clamping**: When parked or stopped at traffic lights (speed under 1.8 km/h and distance delta under 3.0 meters), the vehicle is treated as stationary and distance delta is clamped to 0.0 meters, preventing odometer creep.
* **Multipath Position Jump Rejection**: If the hardware speed sensor indicates 0.0 km/h but the coordinates jump more than 8 meters, the fix is flagged as an indoor signal bounce and discarded.
* **Kalman Filtering (`LocationKalmanFilter` & `SpeedKalmanFilter`)**: 1D Kalman state update filters smooth coordinate transitions and speed values to eliminate jitter from the speedometer gauge and route polyline.

### 5. Mathematical Calculations (`DistanceCalculator`)
* **Haversine Formula**: Computes great-circle distances in meters between two latitude/longitude coordinates accounting for earth curvature ($R = 6,371,000\text{ m}$).
* **Bearing Calculation**: Computes forward azimuth angle (0 to 360 degrees) between coordinates to rotate the rider directional navigation arrow on the map.

### 6. State Management & Clean Architecture (`flutter_bloc`)
The application is structured into four distinct layers:

* **Domain Layer**: Pure business logic containing entity models (`Trip`, `LocationPoint`, `TripMetrics`, `TripStatus`), repository contracts, and isolated use cases with zero external framework dependencies.
* **Data Layer**: Data source implementations for local disk (`TripLocalDataSourceImpl`), remote Firestore (`FirebaseTripRemoteDataSource`), GPS hardware streams (`LocationDataSourceImpl`), and repository implementations with offline sync logic.
* **Presentation Layer**: BLoC pattern for unidirectional data flow:
  * `TripBloc`: Handles ride lifecycle (start, pause, resume, end, timer ticks, metric updates).
  * `LocationBloc`: Manages GPS permissions, service availability, and real-time accuracy chip status.
  * `HistoryBloc`: Manages past rides, route details, and cloud synchronization.
  * `SettingsBloc`: Allows tuning GPS filter thresholds, Kalman smoothing toggles, and map tile themes.
* **UI & Custom Graphics**: Custom-painted radial speedometer gauge (`CustomPainter`), glassmorphic telemetry cards, interactive speed vs. time charts (`fl_chart`), and animated OpenStreetMap layer.

---

## Project Structure

* **`lib/`**
  * `main.dart` — Application entry point and dependency injection setup
  * **`core/`**
    * **`constants/`** — `app_constants.dart` (app thresholds, tile URLs, storage keys)
    * **`errors/`** — `failures.dart` (failure and error handling)
    * **`network/`** — `network_info.dart` (connectivity status monitoring)
    * **`theme/`** — `app_colors.dart`, `app_theme.dart` (HUD dark theme and color palette)
    * **`utils/`** — `distance_calculator.dart`, `kalman_filter.dart`, `location_filter.dart`, `formatters.dart`
  * **`features/trip/`**
    * **`domain/`**
      * **`entities/`** — `location_point.dart`, `trip.dart`, `trip_metrics.dart`, `trip_status.dart`
      * **`repositories/`** — `location_repository.dart`, `trip_repository.dart`
      * **`usecases/`** — `start_trip_usecase.dart`, `pause_trip_usecase.dart`, `resume_trip_usecase.dart`, `end_trip_usecase.dart`, `add_location_usecase.dart`, `get_active_trip_usecase.dart`, `get_trip_history_usecase.dart`, `delete_trip_usecase.dart`, `sync_offline_trips_usecase.dart`
    * **`data/`**
      * **`datasources/`** — `location_datasource.dart`, `trip_local_datasource.dart`, `trip_remote_datasource.dart`
      * **`models/`** — `location_point_dto.dart`, `trip_dto.dart`
      * **`repositories/`** — `location_repository_impl.dart`, `trip_repository_impl.dart`
    * **`presentation/`**
      * **`bloc/`** — `trip/`, `location/`, `history/`, `settings/`
      * **`views/`** — `live_tracking_screen.dart`, `settings_screen.dart`, `trip_details_screen.dart`, `trip_history_screen.dart`, `trip_summary_screen.dart`
      * **`widgets/`** — `gps_accuracy_chip.dart`, `live_map_view.dart`, `metric_card.dart`, `speed_chart_widget.dart`, `speedometer_gauge.dart`, `sync_status_badge.dart`, `trip_control_button.dart`

---

## Dependencies and Packages Used

- flutter_bloc (version 8.1.6): State management separating UI from business logic
- equatable (version 2.0.5): Value equality for states and events to avoid unnecessary rebuilds
- geolocator (version 13.0.2): High frequency GPS position streaming and background service execution
- flutter_map (version 7.0.2): Canvas rendered OpenStreetMap view with custom polylines and markers
- latlong2 (version 0.9.1): Latitude and longitude coordinate math utilities
- firebase_core (version 3.6.0): Initializing Firebase application infrastructure
- cloud_firestore (version 5.4.4): Cloud database for trip history storage and real-time synchronization
- shared_preferences (version 2.3.2): Local disk key-value store for offline persistence and crash recovery
- connectivity_plus (version 6.0.5): Monitoring online and offline network transitions for automatic sync
- fl_chart (version 0.69.0): Drawing interactive speed vs time post-ride analytics charts
- google_fonts (version 6.2.1): Telemetry typography with Outfit and JetBrains Mono
- intl (version 0.19.0): Date, time, and timestamp formatting for ride cards and summaries
- uuid (version 4.5.1): Generating unique trip identifiers
- path_provider (version 2.1.4): Locating device file storage directories
- http (version 1.2.2): HTTP client for remote tile fetching
- cupertino_icons (version 1.0.8): Standard iOS and Android iconography

---

## How to Run Locally

### Prerequisites
* Flutter SDK (`>=3.13.0`)
* Dart SDK (`>=3.13.0`)
* Android Studio, Xcode, or VS Code

### Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/9xRahul/RiderAPP.git
   cd RiderAPP
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify static analysis**:
   ```bash
   flutter analyze
   ```

4. **Launch the application**:
   ```bash
   # Android / iOS
   flutter run

   # Windows Desktop
   flutter run -d windows

   # Chrome Web
   flutter run -d chrome
   ```
