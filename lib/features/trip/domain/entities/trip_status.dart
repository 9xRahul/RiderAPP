enum TripStatus {
  idle,
  active,
  paused,
  completed;

  bool get isIdle => this == TripStatus.idle;
  bool get isActive => this == TripStatus.active;
  bool get isPaused => this == TripStatus.paused;
  bool get isCompleted => this == TripStatus.completed;

  String get displayName {
    switch (this) {
      case TripStatus.idle:
        return 'Ready';
      case TripStatus.active:
        return 'Tracking Active';
      case TripStatus.paused:
        return 'Paused';
      case TripStatus.completed:
        return 'Completed';
    }
  }
}
