import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/domain/remote_command.dart';
import 'package:justremote/features/remote/presentation/widgets/dpad_widget.dart';

void main() {
  testWidgets('DpadWidget fires select on OK tap', (tester) async {
    RemoteCommand? fired;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox.square(
          dimension: 260,
          child: DpadWidget(onCommand: (cmd) => fired = cmd),
        ),
      ),
    ));
    await tester.tap(find.text('OK'));
    await tester.pump();
    expect(fired, RemoteCommand.select);
  });

  testWidgets('DpadWidget fires up on up-arrow tap', (tester) async {
    RemoteCommand? fired;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox.square(
          dimension: 260,
          child: DpadWidget(onCommand: (cmd) => fired = cmd),
        ),
      ),
    ));
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await tester.pump();
    expect(fired, RemoteCommand.up);
  });
}
