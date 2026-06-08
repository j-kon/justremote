import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/presentation/widgets/remote_button_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hapticLog = <String>[];

  setUp(() {
    hapticLog.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          hapticLog.add(call.arguments as String? ?? '');
        }
        return null;
      },
    );
  });

  testWidgets('calls onPressed callback on tap', (tester) async {
    var called = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RemoteButtonWidget(
          label: 'Test',
          icon: Icons.home,
          onPressed: () => called = true,
        ),
      ),
    ));
    await tester.tap(find.byType(RemoteButtonWidget));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('triggers lightImpact haptic on tap', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RemoteButtonWidget(
          label: 'Test',
          icon: Icons.home,
          onPressed: () {},
        ),
      ),
    ));
    await tester.tap(find.byType(RemoteButtonWidget));
    await tester.pump();
    expect(hapticLog, contains('HapticFeedbackType.lightImpact'));
  });

  testWidgets('isPower button triggers mediumImpact haptic', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RemoteButtonWidget(
          label: 'Power',
          icon: Icons.power_settings_new,
          isPower: true,
          onPressed: () {},
        ),
      ),
    ));
    await tester.tap(find.byType(RemoteButtonWidget));
    await tester.pump();
    expect(hapticLog, contains('HapticFeedbackType.mediumImpact'));
  });
}
