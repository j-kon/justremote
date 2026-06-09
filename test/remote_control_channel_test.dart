import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/data/remote_control_channel.dart';
import 'package:justremote/features/remote/domain/remote_command.dart';
import 'package:justremote/features/tv_discovery/domain/tv_device.dart';

void main() {
  const channelName = 'com.justremote.tv_remote';
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), null);
  });

  test(
    'sendCommand delegates the command name to the native channel',
    () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (
            MethodCall call,
          ) async {
            capturedCall = call;
            return <String, Object?>{'success': true};
          });

      final channel = RemoteControlChannel();
      final success = await channel.sendCommand(RemoteCommand.home);

      expect(success, isTrue);
      expect(capturedCall?.method, 'sendCommand');
      expect(capturedCall?.arguments, <String, Object?>{'command': 'home'});
    },
  );

  test('forgetTv delegates the device to the native channel', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), (
          MethodCall call,
        ) async {
          capturedCall = call;
          return <String, Object?>{'success': true, 'message': 'Forgot TV'};
        });

    final channel = RemoteControlChannel();
    final success = await channel.forgetTv(
      const TvDevice(
        id: 'tv_1',
        name: 'Living Room TV',
        host: '192.168.1.20',
        port: 6466,
        type: 'android_tv',
      ),
    );

    expect(success, isTrue);
    expect(capturedCall?.method, 'forgetTv');
    expect(capturedCall?.arguments, containsPair('deviceId', 'tv_1'));
  });

  test('getDiagnostics reads native diagnostics map', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), (
          MethodCall call,
        ) async {
          return <String, Object?>{
            'connected': true,
            'deviceName': 'Living Room TV',
            'lastError': null,
            'events': <String>['Connected'],
          };
        });

    final channel = RemoteControlChannel();
    final diagnostics = await channel.getDiagnostics();

    expect(diagnostics['connected'], isTrue);
    expect(diagnostics['events'], isA<List<Object?>>());
  });
}
