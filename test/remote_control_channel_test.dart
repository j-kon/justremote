import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/data/remote_control_channel.dart';
import 'package:justremote/features/remote/domain/remote_command.dart';

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
}
