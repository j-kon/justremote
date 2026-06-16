import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/presentation/remote_screen.dart';

void main() {
  testWidgets('RemoteScreen renders without error', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RemoteScreen(device: null)),
      ),
    );
    await tester.pump();
    expect(find.byType(RemoteScreen), findsOneWidget);
  });

  testWidgets('RemoteScreen has three bottom tabs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RemoteScreen(device: null)),
      ),
    );
    await tester.pump();
    expect(find.text('Remote'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Input'), findsOneWidget);
  });
}
