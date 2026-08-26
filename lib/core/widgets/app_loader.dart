import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';

class AppLoader extends StatefulWidget {
  final String message;
  final double size;
  final IconData? icon;
  final Color? iconColor;

  const AppLoader({
    super.key,
    this.message = 'Memuat data...',
    this.size = 70.0,
    this.icon,
    this.iconColor,
  });

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size + 24,
            height: widget.size + 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulsing Glow Aura
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: widget.size + 10,
                        height: widget.size + 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 25,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Rotating Gradient Spinner Ring
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _GradientSpinnerPainter(
                          gradientColors: const [
                            AppColors.primary,
                            AppColors.accent,
                            Colors.transparent,
                          ],
                          strokeWidth: 3.5,
                        ),
                      ),
                    );
                  },
                ),

                // Inner Glassy Core with Floating Icon
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: widget.size * 0.58,
                    height: widget.size * 0.58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgCard,
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon ?? Icons.show_chart_rounded,
                      color: widget.iconColor ?? AppColors.primary,
                      size: widget.size * 0.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              widget.message,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradientSpinnerPainter extends CustomPainter {
  final List<Color> gradientColors;
  final double strokeWidth;

  _GradientSpinnerPainter({
    required this.gradientColors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: 0,
        endAngle: math.pi * 1.5,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      0,
      math.pi * 1.6,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientSpinnerPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gradientColors != gradientColors;
  }
}
