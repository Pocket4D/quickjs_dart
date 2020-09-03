import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickjs_dart/quickjs_dart.dart';

void main() {
  const MethodChannel channel = MethodChannel('quickjs_dart');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await QuickjsDart.platformVersion, '42');
  });
}
