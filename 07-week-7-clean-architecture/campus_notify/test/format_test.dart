import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/format.dart';

void main() {
  test('formatDate menghasilkan format yang benar', () {
    final date = DateTime(2026, 9, 27);
    expect(formatDate(date), '27 Sep 2026');
  });

  test('formatRelativeTime menangani hari', () {
    final date = DateTime.now().subtract(const Duration(days: 2));
    expect(formatRelativeTime(date), '2 hari lalu');
  });

  test('routeFromMessage menangani route tanpa slash', () {
    expect(routeFromMessage({}), '/');
    expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
  });
}