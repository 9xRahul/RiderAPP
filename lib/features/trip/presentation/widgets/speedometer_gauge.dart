import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class SpeedometerGauge extends StatelessWidget {
  final double currentSpeedKmh;
  final double maxSpeedKmh;
  final double maxGaugeLimit;

  const SpeedometerGauge({
    super.key,
    required this.currentSpeedKmh,
    required this.maxSpeedKmh,
    this.maxGaugeLimit = 140.0,
  });

  @override
  Widget build(BuildContext context) {
    final speedColor = AppColors.getSpeedColor(currentSpeedKmh);

    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: currentSpeedKmh),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (context, animatedSpeed, child) {
              return CustomPaint(
                size: const Size(220, 180),
                painter: _SpeedometerPainter(
                  currentSpeed: animatedSpeed,
                  maxSpeed: maxSpeedKmh,
                  maxGaugeLimit: maxGaugeLimit,
                  speedColor: speedColor,
                ),
              );
            },
          ),
          Positioned(
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentSpeedKmh.toStringAsFixed(0),
                  style: GoogleFonts.outfit(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: speedColor,
                        boxShadow: [
                          BoxShadow(
                            color: speedColor.withAlpha(180),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'KM/H',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double currentSpeed;
  final double maxSpeed;
  final double maxGaugeLimit;
  final Color speedColor;

  _SpeedometerPainter({
    required this.currentSpeed,
    required this.maxSpeed,
    required this.maxGaugeLimit,
    required this.speedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = size.width * 0.44;

    const startAngle = 135.0 * (math.pi / 180.0);
    const sweepAngle = 270.0 * (math.pi / 180.0);

    final bgPaint = Paint()
      ..color = AppColors.surfaceBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final progressRatio = (currentSpeed / maxGaugeLimit).clamp(0.0, 1.0);
    final activeSweep = sweepAngle * progressRatio;

    if (activeSweep > 0) {
      final activePaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: const [
            AppColors.emerald,
            AppColors.cyan,
            AppColors.amber,
            AppColors.coral,
          ],
          transform: GradientRotation(startAngle),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;

      final glowPaint = Paint()
        ..color = speedColor.withAlpha(90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        glowPaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }

    if (maxSpeed > 0) {
      final maxRatio = (maxSpeed / maxGaugeLimit).clamp(0.0, 1.0);
      final maxAngle = startAngle + (sweepAngle * maxRatio);

      final p1 = Offset(
        center.dx + (radius - 8) * math.cos(maxAngle),
        center.dy + (radius - 8) * math.sin(maxAngle),
      );
      final p2 = Offset(
        center.dx + (radius + 8) * math.cos(maxAngle),
        center.dy + (radius + 8) * math.sin(maxAngle),
      );

      final tickPaint = Paint()
        ..color = AppColors.coral
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, tickPaint);
    }

    for (int i = 0; i <= 6; i++) {
      final tickAngle = startAngle + (sweepAngle * (i / 6.0));
      final dotPos = Offset(
        center.dx + (radius - 18) * math.cos(tickAngle),
        center.dy + (radius - 18) * math.sin(tickAngle),
      );

      final dotPaint = Paint()
        ..color = AppColors.textMuted.withAlpha(120)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(dotPos, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.currentSpeed != currentSpeed ||
        oldDelegate.maxSpeed != maxSpeed ||
        oldDelegate.speedColor != speedColor;
  }
}
