import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpaceBackground extends StatefulWidget {
  final Widget child;

  const SpaceBackground({
    super.key,
    required this.child,
  });

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    for (int i = 0; i < 90; i++) {
      _stars.add(_Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2.5 + 0.5,
        twinkleSpeed: _random.nextDouble() * 3 + 1,
        opacityOffset: _random.nextDouble() * pi * 2,
        color: i % 5 == 0
            ? AppColors.nebulaCyan
            : i % 7 == 0
                ? AppColors.spaceViolet
                : i % 11 == 0
                    ? AppColors.starlightBlue
                    : Colors.white,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Deep space void gradient
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
            ),
            // Glowing cosmic nebula clouds
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.spaceViolet.withValues(alpha: 0.28),
                      AppColors.spaceViolet.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -120,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.nebulaCyan.withValues(alpha: 0.20),
                      AppColors.starlightBlue.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 300,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.supernovaPink.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Dynamic Starfield Painter
            CustomPaint(
              painter: _StarfieldPainter(
                stars: _stars,
                progress: _controller.value,
              ),
            ),
            // Foreground Content
            widget.child,
          ],
        );
      },
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;
  final double opacityOffset;
  final Color color;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.opacityOffset,
    required this.color,
  });
}

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress;

  _StarfieldPainter({
    required this.stars,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final dx = star.x * size.width;
      final dy = (star.y + progress * 0.02) % 1.0 * size.height;

      final opacity = ((sin(progress * pi * 2 * star.twinkleSpeed + star.opacityOffset) + 1) / 2) * 0.75 + 0.25;

      final paint = Paint()
        ..color = star.color.withValues(alpha: opacity)
        ..maskFilter = star.size > 2.0 ? const MaskFilter.blur(BlurStyle.normal, 1.5) : null;

      canvas.drawCircle(Offset(dx, dy), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) => true;
}
