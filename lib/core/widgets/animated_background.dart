import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Floating glow blobs + subtle dot grid background.
/// Used behind splash / login for a modern, alive feel.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Stack(
        children: [
          // Dot grid texture
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          // Floating blobs
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * 2 * math.pi;
              return Stack(
                children: [
                  _blob(
                    top: size.height * 0.10 + math.sin(t) * 24,
                    left: size.width * 0.15 + math.cos(t * 0.8) * 18,
                    size: size.width * 0.75,
                    color: AppColors.accent.withOpacity(0.16),
                  ),
                  _blob(
                    top: size.height * 0.55 + math.cos(t * 0.6) * 30,
                    left: size.width * 0.55 + math.sin(t * 0.9) * 22,
                    size: size.width * 0.65,
                    color: AppColors.info.withOpacity(0.10),
                  ),
                  _blob(
                    top: size.height * 0.75 - math.sin(t * 0.5) * 20,
                    left: -size.width * 0.2,
                    size: size.width * 0.55,
                    color: AppColors.purple.withOpacity(0.10),
                  ),
                ],
              );
            },
          ),

          widget.child,
        ],
      ),
    );
  }

  Widget _blob({
    required double top,
    required double left,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
