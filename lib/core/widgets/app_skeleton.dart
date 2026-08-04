import 'package:flutter/material.dart';

class AppSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? shapeBorder;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shapeBorder,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: ShapeDecoration(
            color: Color.lerp(
              const Color(0xFF1E293B),
              const Color(0xFF334155),
              _animation.value,
            ),
            shape: widget.shapeBorder ??
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
          ),
        );
      },
    );
  }
}
