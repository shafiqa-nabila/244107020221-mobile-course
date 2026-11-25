import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_performance_optimization/features/optimized_notes_page.dart';

void main() {
  group('OptimizedNotesPage Widget & Performance Tests', () {
    testWidgets('Merender struktur halaman teroptimasi dengan RepaintBoundary',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OptimizedNotesPage(),
          ),
        ),
      );

      // Selesaikan inisialisasi microtask
      await tester.pumpAndSettle();

      // Verifikasi judul dan metrik header
      expect(find.text('Optimized Campus Notes'), findsOneWidget);
      expect(find.text('60 FPS'), findsOneWidget);
      expect(find.text('SWR 5m'), findsOneWidget);

      // Verifikasi ListView terpasang
      expect(find.byType(ListView), findsOneWidget);

      // Verifikasi keberadaan RepaintBoundary untuk mengisolasi repaint list item
      expect(find.byType(RepaintBoundary), findsWidgets);

      // Verifikasi badge counter terisolasi di AppBar
      expect(find.textContaining('Catatan'), findsWidgets);
    });

    testWidgets('Memastikan widget dapat di-unmount tanpa exception (Memory Safe)',
        (tester) async {
      // Menguji navigasi bolak-balik 5x (simulasi Langkah 5 Memory Profiling)
      for (var i = 0; i < 5; i++) {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: OptimizedNotesPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Unmount widget dengan me-render Container kosong
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('Page Lain'))),
        );
        await tester.pump();
      }

      // Jika controller tidak di-dispose dengan benar, Flutter akan melempar exception
      expect(find.text('Page Lain'), findsOneWidget);
    });
  });
}
