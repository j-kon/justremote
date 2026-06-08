import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/domain/remote_command.dart';
import 'package:justremote/features/remote/presentation/widgets/input_tab.dart';

void main() {
  testWidgets('InputTab renders touchpad and text field', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InputTab(onCommand: (_) {}, onSendText: (_) {}),
      ),
    ));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const Key('touchpad')), findsOneWidget);
  });

  testWidgets('InputTab fires select on touchpad tap', (tester) async {
    RemoteCommand? fired;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InputTab(
          onCommand: (cmd) => fired = cmd,
          onSendText: (_) {},
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('touchpad')));
    await tester.pump();
    expect(fired, RemoteCommand.select);
  });
}
