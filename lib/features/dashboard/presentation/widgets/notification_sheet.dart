import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final IconData icon;
  final Color iconColor;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
  });
}

class NotificationSheet extends StatefulWidget {
  final List<NotificationItem> initialNotifications;
  final VoidCallback onAllRead;

  const NotificationSheet({
    super.key,
    required this.initialNotifications,
    required this.onAllRead,
  });

  static Future<void> show(
    BuildContext context, {
    required List<NotificationItem> notifications,
    required VoidCallback onAllRead,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NotificationSheet(
        initialNotifications: notifications,
        onAllRead: onAllRead,
      ),
    );
  }

  @override
  State<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<NotificationSheet> {
  late List<NotificationItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialNotifications);
  }

  void _markAllRead() {
    setState(() {
      for (var item in _items) {
        item.isRead = true;
      }
    });
    widget.onAllRead();
  }

  void _toggleRead(NotificationItem item) {
    setState(() {
      item.isRead = true;
    });
    if (!_items.any((n) => !n.isRead)) {
      widget.onAllRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((n) => !n.isRead).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0D161F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF1E3042), width: 1.5)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Pusat Notifikasi',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '$unreadCount baru',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (unreadCount > 0)
                  GestureDetector(
                    onTap: _markAllRead,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Text(
                        'Tandai Dibaca',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 52, color: AppColors.textSecondary),
                        SizedBox(height: 14),
                        Text(
                          'Belum Ada Notifikasi Baru',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return GestureDetector(
                        onTap: () => _toggleRead(item),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? const Color(0xFF121D28)
                                : const Color(0xFF182837),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: item.isRead
                                  ? const Color(0xFF1E3042)
                                  : AppColors.accent.withValues(alpha: 0.4),
                              width: item.isRead ? 1 : 1.4,
                            ),
                            boxShadow: item.isRead
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(alpha: 0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item.iconColor.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: item.iconColor.withValues(alpha: 0.4),
                                    width: 1.2,
                                  ),
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 22,
                                  color: item.iconColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              fontSize: 14.5,
                                              fontWeight: item.isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: AppColors.accent,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.accent
                                                      .withValues(alpha: 0.8),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.message,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 13,
                                        color: item.isRead
                                            ? AppColors.textSecondary
                                            : const Color(0xFFD0D7DE),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 13,
                                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          formatDateGroup(item.time),
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
