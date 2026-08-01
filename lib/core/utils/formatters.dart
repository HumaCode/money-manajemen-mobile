String formatRupiah(num amount) => 'Rp ${amount.toStringAsFixed(0)}';

String formatMonthYear(DateTime date) => '${date.month}/${date.year}';

String formatDateGroup(DateTime date) => '${date.day}/${date.month}/${date.year}';
