import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:some_package/some_package.dart';

void main() {
  const MethodChannel channel = MethodChannel('some_package');

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
    expect(await SomePackage.platformVersion, '42');
  });
}
