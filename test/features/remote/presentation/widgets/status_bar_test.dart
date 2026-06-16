import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/presentation/widgets/status_bar.dart';

void main() {
  testWidgets('shows Connected label when connected', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: StatusBar(connected: true, deviceName: 'My TV'),
      ),
    ));
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('My TV'), findsOneWidget);
  });

  testWidgets('shows Disconnected label when not connected', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: StatusBar(connected: false, deviceName: 'My TV'),
      ),
    ));
    expect(find.text('Disconnected'), findsOneWidget);
  });
}
