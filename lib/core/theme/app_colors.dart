import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF090D16);
  static const Color backgroundSecondary = Color(0xFF101726);
  static const Color surface = Color(0xFF161F33);
  static const Color surfaceLight = Color(0xFF1E2B45);
  static const Color surfaceBorder = Color(0xFF243452);

  static const Color cyan = Color(0xFF00E5FF);
  static const Color cyanGlow = Color(0x3300E5FF);
  static const Color emerald = Color(0xFF00E676);
  static const Color emeraldGlow = Color(0x3300E676);
  static const Color amber = Color(0xFFFFB300);
  static const Color amberGlow = Color(0x33FFB300);
  static const Color coral = Color(0xFFFF3D71);
  static const Color coralGlow = Color(0x33FF3D71);
  static const Color purple = Color(0xFF7C4DFF);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeRideGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient stopGradient = LinearGradient(
    colors: [Color(0xFFFF3D71), Color(0xFFD50000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161F33), Color(0xFF101726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color getSpeedColor(double speedKmh) {
    if (speedKmh <= 0.5) return textMuted;
    if (speedKmh < 30) return emerald;
    if (speedKmh < 60) return cyan;
    if (speedKmh < 90) return amber;
    return coral;
  }

  static Color getAccuracyColor(double accuracyMeters) {
    if (accuracyMeters <= 5.0) return emerald;
    if (accuracyMeters <= 15.0) return cyan;
    if (accuracyMeters <= 30.0) return amber;
    return coral;
  }
}
