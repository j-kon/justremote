import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/tv_discovery/presentation/scan_tv_screen.dart';

void main() {
  testWidgets('ScanTvScreen shows radar while scanning', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ScanTvScreen()),
      ),
    );
    // Before the future resolves, RadarWidget should be visible
    expect(find.byType(RadarWidget), findsOneWidget);
  });
}
