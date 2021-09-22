import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soter_flutter_blue/soter_flutter_blue.dart';

void main() {
  const MethodChannel channel = MethodChannel('soter_flutter_blue');

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
    expect(await SoterFlutterBlue.platformVersion, '42');
  });
}
