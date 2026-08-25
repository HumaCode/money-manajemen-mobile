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
    bool? isLoading,
    Duration? duration,
  }) {
    _timer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final effectiveDuration = duration ??
        (message.length > 50
            ? const Duration(seconds: 5)
            : const Duration(seconds: 3));

    final entry = OverlayEntry(
      builder: (context) => _DynamicIslandWidget(
        message: message,
        title: title,
        type: type,
        isLoading: isLoading,
        onDismiss: () => dismiss(),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _timer = Timer(effectiveDuration, () {
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
  final bool? isLoading;
  final VoidCallback onDismiss;

  const _DynamicIslandWidget({
    required this.message,
    this.title,
    required this.type,
    this.isLoading,
    required this.onDismiss,
  });

  @override
  State<_DynamicIslandWidget> createState() => _DynamicIslandWidgetState();
}

class _DynamicIslandWidgetState extends State<_DynamicIslandWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _spinController;
  late AnimationController _pulseController;

  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool get _isSyncingOrDownloading {
    if (widget.isLoading == true) return true;
    final text = '${widget.title ?? ''} ${widget.message}'.toLowerCase();
    return text.contains('unduh') ||
        text.contains('sinkron') ||
        text.contains('sync') ||
        text.contains('download') ||
        text.contains('memuat') ||
        text.contains('loading');
  }

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

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    if (_isSyncingOrDownloading) {
      _spinController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _spinController.dispose();
    _pulseController.dispose();
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
    if (_isSyncingOrDownloading) {
      return Icons.sync_rounded;
    }
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
    if (_isSyncingOrDownloading) {
      return 'Menyinkronkan Data...';
    }
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

  Widget _buildIcon(Color neon) {
    if (_isSyncingOrDownloading) {
      return AnimatedBuilder(
        animation: Listenable.merge([_spinController, _pulseController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neon.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: neon.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: RotationTransition(
                turns: _spinController,
                child: Icon(
                  _iconData,
                  color: neon,
                  size: 20,
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: neon.withValues(alpha: 0.15),
        boxShadow: [
          BoxShadow(
            color: neon.withValues(alpha: 0.4),
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
    );
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
                        color: const Color(0xFF0A0F1D).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: neon.withValues(alpha: 0.85),
                          width: 1.5,
                        ),
                        boxShadow: [
                          // Neon Outer Glow
                          BoxShadow(
                            color: neon.withValues(alpha: 0.5 * _expandAnimation.value),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated Glowing Icon Container
                          _buildIcon(neon),
                          const SizedBox(width: 12),

                          // Text Content & Optional Sync Loader Bar
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
                                  maxLines: 10,
                                  overflow: TextOverflow.visible,
                                ),
                                if (_isSyncingOrDownloading) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      minHeight: 3,
                                      backgroundColor: neon.withValues(alpha: 0.15),
                                      valueColor: AlwaysStoppedAnimation<Color>(neon),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.textMuted.withValues(alpha: 0.7),
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
