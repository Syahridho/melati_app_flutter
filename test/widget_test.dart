// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:melati_app/main.dart';

void main() {
  testWidgets('Melati app loads the main navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MelatiApp());

    expect(find.text('Lapor'), findsOneWidget);
    expect(find.text('Cek'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Beri Laporan'), findsOneWidget);
    expect(
      find.text('Maksimal 3 file • JPG, PNG, PDF • Maks. 2 MB per file'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cek'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Cek Laporan'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Riwayat Laporan'), findsOneWidget);
  });
}
