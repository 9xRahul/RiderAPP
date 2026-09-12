# Rider Tracker - Real-Time Trip & GPS Telemetry Mobile Application

A production-grade Flutter mobile application designed for motorcycle and bicycle riders to track active trips with real-time GPS telemetry, noise and jump filtering, Firebase Firestore synchronization, and state recovery for terminated app scenarios.

Built following **Clean Architecture**, **BLoC (separate Bloc, Event, and State files)**, and a modern telemetry user interface.

---

## Features

- **Trip Lifecycle Management**: Start and End trip actions with live status tracking (Ready, Active, Paused, Completed).
- **Real-Time Telemetry**: Live speedometer gauge, total distance travelled, instantaneous speed, highest recorded speed, and average speed.
- **GPS Noise & Jump Filter Pipeline**: Evaluates incoming hardware GPS fixes to discard teleportation jumps, filter poor horizontal accuracy, suppress stationary jitter at traffic stops, and apply 2D Kalman coordinate smoothing.
- **Interactive OpenStreetMap Route View**: High-contrast dark Carto vector tiles with glowing polyline trails, rider heading indicator, and animated radar pulse.
- **Firebase Firestore Backend Sync**: Automatically uploads trips and location points to Firebase Cloud Firestore collections (`trips` and `trips/{tripId}/locations`).
- **Offline-First Resilience**: Continues recording location points when there is no internet connection. When network connectivity is restored, queued data is synced automatically with batch commits.
- **Terminated App State Recovery**: Continuously persists active ride state to local disk. If the application is killed by the OS or the phone reboots during an active ride, relaunching the app detects and resumes the session.
- **Post-Ride Analytics**: Summary screen with trip statistics, waypoint inspection, and an interactive speed profile chart.

---

## Clean Architecture Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # Configuration thresholds, tile URLs, storage keys
│   ├── errors/
│   │   └── failures.dart               # Domain failure definitions
│   ├── network/
│   │   └── network_info.dart           # Reactive connectivity check (connectivity_plus)
│   ├── theme/
│   │   ├── app_colors.dart             # High-contrast HUD telemetry color palette
│   │   └── app_theme.dart              # Typography & Material 3 Dark theme setup
│   └── utils/
│       ├── distance_calculator.dart    # Haversine geodesic distance & bearing math
│       ├── formatters.dart             # Time, speed, and distance formatting
│       ├── kalman_filter.dart          # 2D Kalman position & speed smoothing
│       └── location_filter.dart        # Multi-stage GPS jump and jitter rejection engine
│
├── features/trip/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── location_datasource.dart      # Geolocator stream & background configuration
│   │   │   ├── trip_local_datasource.dart    # Local persistence & crash recovery queue
│   │   │   └── trip_remote_datasource.dart   # Firebase Cloud Firestore remote datasource
│   │   ├── models/
│   │   │   ├── location_point_dto.dart       # JSON/Firestore serialization
│   │   │   └── trip_dto.dart                 # Trip DTO serialization
│   │   └── repositories/
│   │       ├── location_repository_impl.dart # Concrete location repository
│   │       └── trip_repository_impl.dart     # Concrete trip repository with sync logic
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── location_point.dart     # Location coordinate entity
│   │   │   ├── trip.dart               # Trip session entity
│   │   │   ├── trip_metrics.dart       # Aggregated metrics (distance, speeds, duration)
│   │   │   └── trip_status.dart        # Trip state enum (idle, active, paused, completed)
│   │   ├── repositories/
│   │   │   ├── location_repository.dart# Location contract
│   │   │   └── trip_repository.dart    # Trip contract
│   │   └── usecases/
│   │       ├── add_location_usecase.dart
│   │       ├── end_trip_usecase.dart
│   │       ├── get_active_trip_usecase.dart
│   │       ├── get_trip_history_usecase.dart
│   │       ├── pause_trip_usecase.dart
│   │       ├── resume_trip_usecase.dart
│   │       ├── start_trip_usecase.dart
│   │       └── sync_offline_trips_usecase.dart
│   │
│   └── presentation/
│       ├── bloc/
│       │   ├── history/                # history_bloc.dart, history_event.dart, history_state.dart
│       │   ├── location/               # location_bloc.dart, location_event.dart, location_state.dart
│       │   ├── settings/               # settings_bloc.dart, settings_event.dart, settings_state.dart
│       │   └── trip/                   # trip_bloc.dart, trip_event.dart, trip_state.dart
│       ├── views/
│       │   ├── live_tracking_screen.dart # Main rider HUD with map and speedometer
│       │   ├── settings_screen.dart      # GPS filter tuning and map styles
│       │   ├── trip_details_screen.dart  # Historical route replay & waypoint inspection
│       │   ├── trip_history_screen.dart  # Ride logs and offline sync status
│       │   └── trip_summary_screen.dart  # Post-ride summary & speed profile chart
│       └── widgets/
│           ├── gps_accuracy_chip.dart        # Real-time satellite health indicator
│           ├── live_map_view.dart            # FlutterMap with custom marker & route trail
│           ├── metric_card.dart              # Glassmorphic telemetry stat tiles
│           ├── speed_chart_widget.dart       # Interactive speed profile graph
│           ├── speedometer_gauge.dart        # Custom painted arc speedometer
│           ├── sync_status_badge.dart        # Cloud sync state pill
│           └── trip_control_button.dart      # Action buttons (Start, Pause, Resume, End)
│
└── main.dart                           # App bootstrap & dependency injection
```

---

## GPS Accuracy & Noise Filtering

Raw mobile GPS readings regularly exhibit noise, multipath reflections from tall buildings, and stationary jitter. This application routes all incoming hardware fixes through `LocationFilterPipeline`:

1. **Horizontal Accuracy Cutoff**: Fixes with horizontal error exceeding the threshold (default `30.0m`, configurable in Settings) are rejected immediately.
2. **Teleportation / Jump Rejection**: When a coordinate is received, the physical velocity between the previous valid coordinate and the new point is calculated:
   $$\text{Speed}_{\text{implied}} = \frac{\text{HaversineDistance}(P_{n-1}, P_n)}{t_n - t_{n-1}}$$
   If $\text{Speed}_{\text{implied}} > \text{MaxSpeedLimit}$ (default `140 km/h`), the coordinate is marked as a multipath jump and discarded without corrupting distance or top speed.
3. **Stationary Jitter Suppression**: At traffic stops or when parked, mobile GPS hardware can fluctuate by $0.5 - 2\text{m}$. If delta distance is $< 3.0\text{m}$ and velocity is $< 1.8\text{ km/h}$, the vehicle is treated as stationary and $0.0\text{ m}$ is added to distance.
4. **2D Kalman Position Smoothing**: Validated coordinates are smoothed using a two-dimensional Kalman filter that balances measurement noise covariance against dynamic process noise for fluid map tracking.

---

## Foreground, Background & Terminated Tracking

### 1. Foreground Tracking
- Uses `Geolocator.getPositionStream` with `LocationAccuracy.bestForNavigation` and `distanceFilter: 0` to receive all raw hardware readings for filter validation.

### 2. Background Tracking
- **Android**:
  - Configured with `ForegroundNotificationConfig` within `geolocator_android`.
  - Runs an Android Foreground Service with an ongoing notification (`Rider Tracker Active`) and partial `WAKELOCK`.
  - Declared permissions in `AndroidManifest.xml`:
    - `ACCESS_FINE_LOCATION`
    - `ACCESS_BACKGROUND_LOCATION`
    - `FOREGROUND_SERVICE`
    - `FOREGROUND_SERVICE_LOCATION`
    - `WAKE_LOCK`
- **iOS**:
  - Configured with `AppleSettings` (`activityType: ActivityType.automotiveNavigation`, `pauseLocationUpdatesAutomatically: false`, and `showBackgroundLocationIndicator: true`).
  - Declared keys in `Info.plist`:
    - `UIBackgroundModes`: `location`, `fetch`, `processing`
    - `NSLocationAlwaysAndWhenInUseUsageDescription`
    - `NSLocationWhenInUseUsageDescription`

### 3. Terminated App Recovery
- All trip updates, timestamps, waypoints, and distance calculations are committed to local disk storage (`TripLocalDataSource`) as each point is accepted.
- If the operating system terminates the application or the device reboots during an active ride, relaunching the application detects the ongoing session (`CheckActiveTripEvent`) and restores the exact distance, duration, waypoints, and tracking state.

---

## Firebase Cloud Firestore Integration

The application synchronizes data directly with Firebase Firestore:

### 1. `trips` Collection
Each document (`trips/{tripId}`) contains:
```json
{
  "tripId": "TRIP-1001",
  "riderId": "RIDER-101",
  "startTime": "2026-09-08T10:15:23Z",
  "endTime": "2026-09-08T10:45:00Z",
  "status": "completed",
  "metrics": {
    "distanceMeters": 14250.0,
    "currentSpeedKmh": 0.0,
    "maxSpeedKmh": 68.5,
    "avgSpeedKmh": 32.4,
    "durationSeconds": 1777,
    "pointsCount": 145
  },
  "updatedAt": "2026-09-08T10:45:00Z"
}
```

### 2. `trips/{tripId}/locations` Sub-collection
Individual location waypoints:
```json
{
  "tripId": "TRIP-1001",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "speed": 42.5,
  "accuracy": 8.2,
  "timestamp": "2026-09-08T10:15:23Z"
}
```

### Offline Queue & Automatic Batch Sync:
- When offline, coordinates and trip lifecycle events are saved in the local queue.
- `HistoryBloc` monitors `connectivity_plus`. When internet connectivity returns, the queued points are batched and committed to Firestore with idempotency protection.

---

## Instructions for Testing Edge Cases

### 1. Testing GPS Teleportation Jump Rejection
- When riding near overpasses or high-rises where GPS multipath spikes occur, coordinates that imply impossible velocity ($> 140\text{ km/h}$) are filtered out; total distance and max speed remain accurate.

### 2. Testing Stationary Drift at Stops
- Start a trip and remain stationary at a red light for 2-3 minutes.
- Notice that despite micro-oscillations in raw coordinates reported by hardware, the distance counter does not drift.

### 3. Testing App Termination Recovery
1. Start an active trip and record a short distance.
2. Force-close the application from recent apps or reboot the device.
3. Relaunch the application.
4. The active trip is restored with an on-screen confirmation banner, preserving all recorded points and distance.

### 4. Testing Offline Mode & Cloud Sync
1. Switch the device to Airplane Mode or turn off Wi-Fi/Cellular data.
2. Start and complete a trip. The status badge displays `Offline (Pending)`.
3. Turn Airplane Mode off.
4. The app automatically detects connectivity and flushes the queue, updating the badge to `Cloud Synced`.

---

## Setup & Running Locally

### Prerequisites
- Flutter SDK `^3.13.0` (Dart `^3.13.0`)
- Android Studio / Xcode

### Installation & Run

1. Clone and navigate to the project directory:
   ```bash
   cd riderapp
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run automated unit and widget tests:
   ```bash
   flutter test
   ```

4. Run static code analysis:
   ```bash
   flutter analyze
   ```

5. Launch on physical device or emulator:
   ```bash
   # Android / iOS
   flutter run

   # Desktop (Windows)
   flutter run -d windows

   # Chrome Web
   flutter run -d chrome
   ```
