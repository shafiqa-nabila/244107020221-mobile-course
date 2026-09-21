import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model data statistik
class StatItem {
  const StatItem({required this.label, required this.value});
  final String label;
  final String value;
}

// Notifier untuk mengambil data statistik secara async
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  // build() dijalankan pertama kali provider diakses
  @override
  Future<List<StatItem>> build() async {
    return _fetchStats();
  }

  // Simulasi pengambilan data dari server
  Future<List<StatItem>> _fetchStats() async {
    await Future.delayed(const Duration(seconds: 2));

    // Simulasi gagal 30%
    final random = Random();
    if (random.nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik');
    }

    // Kembalikan data sukses
    return const [
      StatItem(label: 'Total Mahasiswa', value: '1.234'),
      StatItem(label: 'Rata-rata IPK', value: '3.45'),
      StatItem(label: 'Kehadiran', value: '92%'),
    ];
  }

  // Method untuk refresh (dipanggil dari tombol retry)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchStats);
  }
}

// Provider dengan tipe eksplisit
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);