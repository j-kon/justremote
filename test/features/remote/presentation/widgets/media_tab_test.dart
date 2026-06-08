import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/domain/remote_command.dart';
import 'package:justremote/features/remote/presentation/widgets/media_tab.dart';
import 'package:justremote/features/remote/presentation/widgets/remote_button_widget.dart';

void main() {
  testWidgets('MediaTab fires mediaPlayPause on play button tap', (tester) async {
    RemoteCommand? fired;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MediaTab(onCommand: (cmd) => fired = cmd)),
    ));
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(fired, RemoteCommand.mediaPlayPause);
  });

  testWidgets('MediaTab renders 6 media buttons', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MediaTab(onCommand: (_) {})),
    ));
    expect(find.byType(RemoteButtonWidget), findsNWidgets(6));
  });
}
