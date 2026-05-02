import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:presensi_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('presensi/device');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'readValue') return null;
          if (call.method == 'deviceInfo') {
            return {
              'device_id': 'test-device',
              'device_name': 'Flutter Test',
              'platform': 'android',
            };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('normalizes mobile API base URL', () {
    expect(
      normalisasiBaseApiMobile('https://presensi.example.test'),
      'https://presensi.example.test/api/mobile',
    );
    expect(
      normalisasiBaseApiMobile('https://presensi.example.test/api'),
      'https://presensi.example.test/api/mobile',
    );
    expect(
      normalisasiBaseApiMobile('https://presensi.example.test/api/mobile'),
      'https://presensi.example.test/api/mobile',
    );
    expect(
      normalisasiBaseApiMobile(
        'https://presensi.example.test/api/mobile/autentikasi/masuk',
      ),
      'https://presensi.example.test/api/mobile',
    );
  });

  testWidgets('renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PresensiApp());
    await tester.pumpAndSettle();

    expect(find.text('Presensi Guru'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
  });

  testWidgets('login screen is usable on xxs phones', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PresensiApp());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('responsive pair stacks on narrow phone screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const firstKey = Key('first-responsive-item');
    const secondKey = Key('second-responsive-item');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsivePair(
            first: SizedBox(key: firstKey, height: 48),
            second: SizedBox(key: secondKey, height: 48),
          ),
        ),
      ),
    );

    final firstTop = tester.getTopLeft(find.byKey(firstKey));
    final secondTop = tester.getTopLeft(find.byKey(secondKey));
    final firstSize = tester.getSize(find.byKey(firstKey));

    expect(secondTop.dy, greaterThan(firstTop.dy));
    expect(firstSize.width, 390);
  });
}
