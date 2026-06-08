import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('accent is purple #6C63FF', () {
      expect(AppTheme.accent, const Color(0xFF6C63FF));
    });

    test('accentGlow is accent at 30% opacity', () {
      expect(AppTheme.accentGlow, const Color(0x4D6C63FF));
    });

    test('background is near-black #080c14', () {
      expect(AppTheme.background, const Color(0xFF080C14));
    });

    test('glassButtonBorder is white at 10% opacity', () {
      expect(AppTheme.glassButtonBorder, const Color(0x1AFFFFFF));
    });
  });
}
