/// Fungsi murni: format tanggal ke string ramah pengguna.
/// Bisa di-unit-test tanpa widget.
String formatDate(DateTime date) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Fungsi murni: format waktu relatif (misal: "2 jam lalu").
String formatRelativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays} hari lalu';
  if (diff.inHours > 0) return '${diff.inHours} jam lalu';
  if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
  return 'baru saja';
}

/// Fungsi murni: parsing data payload menjadi route.
/// Bisa di-unit-test tanpa Firebase.
String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route'] as String? ?? '/';
  return route.startsWith('/') ? route : '/$route';
}