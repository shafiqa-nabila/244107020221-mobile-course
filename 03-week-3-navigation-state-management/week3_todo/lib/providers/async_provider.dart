import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simulasi fetch data dari server (butuh 2 detik)
Future<String> fetchData() async {
  await Future.delayed(const Duration(seconds: 2));
  return 'Data berhasil dimuat!';
  // throw Exception('Gagal terhubung ke server');
}

// Provider FutureProvider untuk mengambil data
final dataProvider = FutureProvider<String>((ref) async {
  return fetchData();
});