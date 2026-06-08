import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/pairing/presentation/pairing_screen.dart';
import 'package:justremote/features/tv_discovery/domain/tv_device.dart';

void main() {
  final device = TvDevice(
    id: 'test-id',
    name: 'Test TV',
    host: '192.168.1.1',
    port: 6466,
    type: 'androidtv',
  );

  testWidgets('PairingScreen shows 6 code boxes', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: PairingScreen(device: device)),
    ));
    await tester.pump();
    expect(find.byType(CodeBox), findsNWidgets(6));
  });

  testWidgets('PairingScreen typing fills code boxes', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: PairingScreen(device: device)),
    ));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'AB3');
    await tester.pump();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
