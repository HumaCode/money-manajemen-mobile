import 'dart:async';
import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';

enum DynamicToastType { success, error, warning, info }

class DynamicIslandToast {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    DynamicToastType type = DynamicToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _timer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (context) => _DynamicIslandWidget(
        message: message,
        title: title,
        type: type,
        onDismiss: () => dismiss(),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, () {
      dismiss();
    });
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _DynamicIslandWidget extends StatefulWidget {
  final String message;
  final String? title;
  final DynamicToastType type;
  final VoidCallback onDismiss;

  const _DynamicIslandWidget({
    required this.message,
    this.title,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_DynamicIslandWidget> createState() => _DynamicIslandWidgetState();
}

class _DynamicIslandWidgetState extends State<_DynamicIslandWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _neonColor {
    switch (widget.type) {
      case DynamicToastType.success:
        return const Color(0xFF00FFA3); // Neon Green / Mint
      case DynamicToastType.error:
        return const Color(0xFFFF3366); // Neon Red / Pink
      case DynamicToastType.warning:
        return const Color(0xFFFFB800); // Neon Amber / Yellow
      case DynamicToastType.info:
        return const Color(0xFF00E5FF); // Neon Cyan / Blue
    }
  }

  IconData get _iconData {
    switch (widget.type) {
      case DynamicToastType.success:
        return Icons.check_circle_rounded;
      case DynamicToastType.error:
        return Icons.error_rounded;
      case DynamicToastType.warning:
        return Icons.warning_amber_rounded;
      case DynamicToastType.info:
        return Icons.info_rounded;
    }
  }

  String get _defaultTitle {
    switch (widget.type) {
      case DynamicToastType.success:
        return 'Berhasil';
      case DynamicToastType.error:
        return 'Gagal';
      case DynamicToastType.warning:
        return 'Peringatan';
      case DynamicToastType.info:
        return 'Informasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final neon = _neonColor;

    return Positioned(
      top: topPadding + 6,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F1D).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: neon.withOpacity(0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          // Neon Outer Glow
                          BoxShadow(
                            color: neon.withOpacity(0.5 * _expandAnimation.value),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Glowing Icon container
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: neon.withOpacity(0.15),
                              boxShadow: [
                                BoxShadow(
                                  color: neon.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              _iconData,
                              color: neon,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Text Content
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title ?? _defaultTitle,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: neon,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.textMuted.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
