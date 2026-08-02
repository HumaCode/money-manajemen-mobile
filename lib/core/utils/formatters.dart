String formatRupiah(num amount) => 'Rp ${amount.toStringAsFixed(0)}';

const List<String> _monthsIndo = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

const List<String> _daysIndo = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
];

String formatMonthYear(DateTime date) {
  final monthName = _monthsIndo[date.month - 1];
  return '$monthName ${date.year}';
}

String formatDateGroup(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final difference = today.difference(target).inDays;

  final dayName = _daysIndo[date.weekday - 1];
  final monthName = _monthsIndo[date.month - 1];

  if (difference == 0) {
    return 'Hari Ini • ${date.day} $monthName ${date.year}';
  } else if (difference == 1) {
    return 'Kemarin • ${date.day} $monthName ${date.year}';
  }

  return '$dayName, ${date.day} $monthName ${date.year}';
}

String formatDateFull(DateTime date) {
  final dayName = _daysIndo[date.weekday - 1];
  final monthName = _monthsIndo[date.month - 1];
  return '$dayName, ${date.day} $monthName ${date.year}';
}
