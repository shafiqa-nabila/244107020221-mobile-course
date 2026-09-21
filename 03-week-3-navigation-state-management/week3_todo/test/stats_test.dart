import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/providers/stats_provider.dart';

void main() {
  test('StatsNotifier mengembalikan 3 item pada kondisi sukses', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Panggil provider dan tunggu selesai
    final result = await container.read(statsProvider.future);

    expect(result.length, 3);
    expect(result[0].label, 'Total Mahasiswa');
  });

  test('StatsNotifier bisa di-refresh', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(statsProvider.future);

    // Panggil refresh
    await container.read(statsProvider.notifier).refresh();

    // Pastikan state akhir bukan loading
    expect(container.read(statsProvider), isNot(isA<AsyncLoading>()));
  });
}