import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/async_provider.dart';

class AsyncPage extends ConsumerWidget {
  const AsyncPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(dataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Uji Ketiga State')),
      body: Center(
        child: asyncValue.when(
          // STATE 1: LOADING
          loading: () => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data...'),
            ],
          ),

          // STATE 2: ERROR
          error: (error, stackTrace) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text('Terjadi kesalahan: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(dataProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),

          // STATE 3: SUCCESS
          data: (data) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              Text(data),
            ],
          ),
        ),
      ),
    );
  }
}