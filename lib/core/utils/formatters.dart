import 'package:flutter/services.dart';

String formatRupiah(num amount) {
  final isNegative = amount < 0;
  final absAmount = amount.abs().toInt();
  final str = absAmount.toString();

  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(str[i]);
  }

  final formatted = buffer.toString();
  return isNegative ? '-Rp $formatted' : 'Rp $formatted';
}

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

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static String formatNumberWithDots(String str) {
    final cleanText = str.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      if (i > 0 && (cleanText.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(cleanText[i]);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = formatNumberWithDots(cleanText);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
