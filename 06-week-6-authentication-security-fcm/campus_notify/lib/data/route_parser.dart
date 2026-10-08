/// Fungsi murni: parsing data payload menjadi route.
/// Bisa di-unit-test tanpa Firebase.
///
/// Aturan:
/// - Kalau `route` tidak ada, kembalikan `/`.
/// - Kalau `route` tidak diawali `/`, tambahkan `/`.
String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route'] as String? ?? '/';
  return route.startsWith('/') ? route : '/$route';
}