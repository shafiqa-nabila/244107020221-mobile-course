import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _initFcm();
  }

  Future<void> _initFcm() async {
    await initFcmToken(onToken: (token) async {
      // Simulasi kirim token ke backend (di produksi: dio.post('/devices'))
      debugPrint('FCM Token diperbarui: $token');
      if (mounted) setState(() => _fcmToken = token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final display = _fcmToken == null
        ? 'Memuat token...'
        : '${_fcmToken!.substring(0, 12)}...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Selamat datang!'),
            const SizedBox(height: 8),
            Text('FCM Token: $display'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.announcementById('1')),
              child: const Text('Lihat Pengumuman'),
            ),
          ],
        ),
      ),
    );
  }
}