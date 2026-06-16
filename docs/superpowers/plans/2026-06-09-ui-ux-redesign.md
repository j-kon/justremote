# JustRemote UI/UX Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved Premium Glass visual style, Fixed + Tabs remote layout, Ring Pulse button feedback, and improved onboarding/discovery flow across the app.

**Architecture:** Each task is isolated to specific files. Theme tokens go first; widgets that consume them come after. The remote screen rebuild is the largest task and depends on Tasks 1–4. Scanning, pairing, and onboarding tasks are independent of each other and the remote rebuild.

**Tech Stack:** Flutter / Dart 3, `flutter/services.dart` (HapticFeedback), Flutter animation primitives (AnimatedContainer, AnimationController)

**Spec:** `docs/superpowers/specs/2026-06-09-ui-ux-design.md`

---

## File Map

| File | Action |
|------|--------|
| `lib/core/theme/app_theme.dart` | Modify — replace teal accent with purple, add glass token constants |
| `lib/features/remote/presentation/widgets/remote_button_widget.dart` | Modify — convert to StatefulWidget with AnimatedContainer ring pulse |
| `lib/features/remote/presentation/widgets/dpad_widget.dart` | Modify — gradient OK button with ring pulse, glass background |
| `lib/features/remote/presentation/widgets/top_controls.dart` | Modify — pass `isPower: true` instead of `backgroundColor` |
| `lib/features/remote/presentation/widgets/status_bar.dart` | Create — slim connected/disconnected status indicator |
| `lib/features/remote/presentation/widgets/media_tab.dart` | Create — 2×3 media transport grid |
| `lib/features/remote/presentation/widgets/input_tab.dart` | Create — touchpad surface + text input row |
| `lib/features/remote/presentation/remote_screen.dart` | Modify — Fixed + Tabs layout, IndexedStack, no scroll |
| `lib/features/remote/domain/remote_command.dart` | Modify — add 6 media commands |
| `android/app/src/main/proto/remotemessage.proto` | Modify — add media keycodes |
| `android/app/src/main/kotlin/.../protocol/RemoteCommandMapper.kt` | Modify — map 6 media wire names to keycodes |
| `lib/features/tv_discovery/presentation/scan_tv_screen.dart` | Modify — radar animation, slide-in TV cards, manual IP entry |
| `lib/features/pairing/presentation/pairing_screen.dart` | Modify — 6 segmented code boxes |
| `lib/features/onboarding/presentation/onboarding_screen.dart` | Modify — illustrated scenes replace plain icon circles |
| `test/features/remote/presentation/widgets/remote_button_widget_test.dart` | Create |
| `test/features/remote/presentation/widgets/status_bar_test.dart` | Create |
| `test/features/pairing/presentation/pairing_screen_test.dart` | Create |

---

## Task 1: Premium Glass Theme Tokens

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/theme/app_theme_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/theme/app_theme_test.dart
```

Expected: FAIL — `accent` is `0xFF55D6BE`, not `0xFF6C63FF`

- [ ] **Step 3: Update `app_theme.dart`**

Replace the entire file content:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Base surfaces
  static const Color background    = Color(0xFF080C14);
  static const Color surface       = Color(0xFF0D1117);
  static const Color surfaceRaised = Color(0xFF1A1F2E);

  // Accent — Premium Glass purple
  static const Color accent         = Color(0xFF6C63FF);
  static const Color accentLight    = Color(0xFF7C74FF);
  static const Color accentDark     = Color(0xFF5A52D5);
  static const Color accentGlow     = Color(0x4D6C63FF); // 30% opacity
  static const Color accentBorder   = Color(0x666C63FF); // 40% opacity

  // Power button red
  static const Color powerRed       = Color(0xFFE05252);

  // Glass button borders
  static const Color glassButtonBorder       = Color(0x1AFFFFFF); // white 10%
  static const Color glassButtonBorderActive = Color(0xB36C63FF); // purple 70%

  // Text
  static const Color textPrimary = Color(0xFFCCCCCC);
  static const Color textMuted   = Color(0xFF888888);
  static const Color textDim     = Color(0xFF555555);

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary:    accent,
      onPrimary:  Colors.white,
      secondary:  accentLight,
      onSecondary: Colors.white,
      error:      powerRed,
      onError:    Colors.white,
      surface:    surface,
      onSurface:  textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: glassButtonBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: glassButtonBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        hintStyle: const TextStyle(color: textDim),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/core/theme/app_theme_test.dart
```

Expected: PASS (4 tests)

- [ ] **Step 5: Verify app compiles**

```bash
flutter analyze lib/core/theme/app_theme.dart
```

Expected: No issues (or only style suggestions)

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme/app_theme.dart test/core/theme/app_theme_test.dart
git commit -m "feat: update theme to Premium Glass — purple accent #6C63FF"
```

---

## Task 2: GlassButton — Ring Pulse Feedback

**Files:**
- Modify: `lib/features/remote/presentation/widgets/remote_button_widget.dart`
- Modify: `lib/features/remote/presentation/widgets/top_controls.dart`
- Create: `test/features/remote/presentation/widgets/remote_button_widget_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/remote/presentation/widgets/remote_button_widget_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/remote/presentation/widgets/remote_button_widget_test.dart
```

Expected: FAIL — `isPower` parameter does not exist

- [ ] **Step 3: Replace `remote_button_widget.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

class RemoteButtonWidget extends StatefulWidget {
  const RemoteButtonWidget({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.size = 56,
    this.isPower = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final bool isPower;

  @override
  State<RemoteButtonWidget> createState() => _RemoteButtonWidgetState();
}

class _RemoteButtonWidgetState extends State<RemoteButtonWidget> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.isPower) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    widget.onPressed();
    setState(() => _pressed = false);
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isPower ? AppTheme.powerRed : AppTheme.accent;

    return Tooltip(
      message: widget.label,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: _pressed
              ? const Duration(milliseconds: 80)
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.isPower
                ? AppTheme.powerRed.withValues(alpha: 0.15)
                : AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed
                  ? borderColor.withValues(alpha: 0.7)
                  : (widget.isPower
                      ? AppTheme.powerRed.withValues(alpha: 0.25)
                      : AppTheme.glassButtonBorder),
              width: _pressed ? 1.5 : 1.0,
            ),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.15),
                      spreadRadius: 3,
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.38,
            color: widget.isPower ? AppTheme.powerRed : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Update `top_controls.dart` to use `isPower` instead of `backgroundColor`**

```dart
import 'package:flutter/material.dart';

import '../../domain/remote_command.dart';
import 'remote_button_widget.dart';

class TopControls extends StatelessWidget {
  const TopControls({required this.onCommand, super.key});

  final ValueChanged<RemoteCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RemoteButtonWidget(
          label: 'Power',
          icon: Icons.power_settings_new_rounded,
          isPower: true,
          onPressed: () => onCommand(RemoteCommand.power),
        ),
        RemoteButtonWidget(
          label: 'Back',
          icon: Icons.arrow_back_rounded,
          onPressed: () => onCommand(RemoteCommand.back),
        ),
        RemoteButtonWidget(
          label: 'Home',
          icon: Icons.home_rounded,
          onPressed: () => onCommand(RemoteCommand.home),
        ),
        RemoteButtonWidget(
          label: 'Menu',
          icon: Icons.menu_rounded,
          onPressed: () => onCommand(RemoteCommand.menu),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/features/remote/presentation/widgets/remote_button_widget_test.dart
```

Expected: PASS (3 tests)

- [ ] **Step 6: Commit**

```bash
git add lib/features/remote/presentation/widgets/remote_button_widget.dart \
        lib/features/remote/presentation/widgets/top_controls.dart \
        test/features/remote/presentation/widgets/remote_button_widget_test.dart
git commit -m "feat: Ring Pulse button feedback with haptic — replace InkWell with AnimatedContainer"
```

---

## Task 3: D-pad Premium Glass Styling

**Files:**
- Modify: `lib/features/remote/presentation/widgets/dpad_widget.dart`

- [ ] **Step 1: Write smoke test**

Create `test/features/remote/presentation/widgets/dpad_widget_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it currently passes (baseline)**

```bash
flutter test test/features/remote/presentation/widgets/dpad_widget_test.dart
```

Expected: PASS — confirms existing behavior before refactoring

- [ ] **Step 3: Replace `dpad_widget.dart` with glass-styled version**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/remote_command.dart';

class DpadWidget extends StatelessWidget {
  const DpadWidget({required this.onCommand, super.key});

  final ValueChanged<RemoteCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonSize = constraints.maxWidth / 3;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.glassButtonBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                child: _DpadArrow(
                  icon: Icons.keyboard_arrow_up_rounded,
                  size: buttonSize,
                  onCommand: () => onCommand(RemoteCommand.up),
                ),
              ),
              Positioned(
                bottom: 0,
                child: _DpadArrow(
                  icon: Icons.keyboard_arrow_down_rounded,
                  size: buttonSize,
                  onCommand: () => onCommand(RemoteCommand.down),
                ),
              ),
              Positioned(
                left: 0,
                child: _DpadArrow(
                  icon: Icons.keyboard_arrow_left_rounded,
                  size: buttonSize,
                  onCommand: () => onCommand(RemoteCommand.left),
                ),
              ),
              Positioned(
                right: 0,
                child: _DpadArrow(
                  icon: Icons.keyboard_arrow_right_rounded,
                  size: buttonSize,
                  onCommand: () => onCommand(RemoteCommand.right),
                ),
              ),
              SizedBox.square(
                dimension: buttonSize,
                child: _OkButton(onCommand: () => onCommand(RemoteCommand.select)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DpadArrow extends StatefulWidget {
  const _DpadArrow({required this.icon, required this.size, required this.onCommand});

  final IconData icon;
  final double size;
  final VoidCallback onCommand;

  @override
  State<_DpadArrow> createState() => _DpadArrowState();
}

class _DpadArrowState extends State<_DpadArrow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        widget.onCommand();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: _pressed
              ? Border.all(color: AppTheme.accent.withValues(alpha: 0.5), width: 1.5)
              : null,
        ),
        child: Icon(
          widget.icon,
          size: widget.size * 0.45,
          color: _pressed ? AppTheme.accent : AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _OkButton extends StatefulWidget {
  const _OkButton({required this.onCommand});

  final VoidCallback onCommand;

  @override
  State<_OkButton> createState() => _OkButtonState();
}

class _OkButtonState extends State<_OkButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        widget.onCommand();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.accentLight, AppTheme.accentDark],
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(color: AppTheme.accent.withValues(alpha: 0.25), spreadRadius: 5, blurRadius: 0),
                  BoxShadow(color: AppTheme.accent.withValues(alpha: 0.1), spreadRadius: 10, blurRadius: 0),
                  BoxShadow(color: AppTheme.accent.withValues(alpha: 0.5), blurRadius: 14),
                ]
              : [
                  BoxShadow(color: AppTheme.accent.withValues(alpha: 0.5), blurRadius: 14),
                ],
        ),
        child: const Center(
          child: Text(
            'OK',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/remote/presentation/widgets/dpad_widget_test.dart
```

Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/remote/presentation/widgets/dpad_widget.dart \
        test/features/remote/presentation/widgets/dpad_widget_test.dart
git commit -m "feat: D-pad Premium Glass — gradient OK button, ring pulse on arrows"
```

---

## Task 4: Status Bar Widget

**Files:**
- Create: `lib/features/remote/presentation/widgets/status_bar.dart`
- Create: `test/features/remote/presentation/widgets/status_bar_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/features/remote/presentation/widgets/status_bar_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/remote/presentation/widgets/status_bar_test.dart
```

Expected: FAIL — `StatusBar` does not exist

- [ ] **Step 3: Create `status_bar.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({required this.connected, required this.deviceName, super.key});

  final bool connected;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: connected
            ? AppTheme.accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: connected
              ? AppTheme.accent.withValues(alpha: 0.2)
              : AppTheme.glassButtonBorder,
        ),
        boxShadow: connected
            ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.2), blurRadius: 8)]
            : null,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: connected ? AppTheme.accent : Colors.white30,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              deviceName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            connected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: connected ? AppTheme.accent : Colors.white30,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/remote/presentation/widgets/status_bar_test.dart
```

Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/remote/presentation/widgets/status_bar.dart \
        test/features/remote/presentation/widgets/status_bar_test.dart
git commit -m "feat: StatusBar widget — animated connected/disconnected glass indicator"
```

---

## Task 5: Media Commands — Domain + Android

**Files:**
- Modify: `lib/features/remote/domain/remote_command.dart`
- Modify: `android/app/src/main/proto/remotemessage.proto`
- Modify: `android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapper.kt`

- [ ] **Step 1: Write failing test**

Add to `test/features/remote/domain/remote_command_test.dart` (create if absent):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/domain/remote_command.dart';

void main() {
  group('RemoteCommand media commands', () {
    test('mediaPlayPause wire name is mediaPlayPause', () {
      expect(RemoteCommand.mediaPlayPause.wireName, 'mediaPlayPause');
    });
    test('mediaStop wire name is mediaStop', () {
      expect(RemoteCommand.mediaStop.wireName, 'mediaStop');
    });
    test('mediaNext wire name is mediaNext', () {
      expect(RemoteCommand.mediaNext.wireName, 'mediaNext');
    });
    test('mediaPrevious wire name is mediaPrevious', () {
      expect(RemoteCommand.mediaPrevious.wireName, 'mediaPrevious');
    });
    test('mediaRewind wire name is mediaRewind', () {
      expect(RemoteCommand.mediaRewind.wireName, 'mediaRewind');
    });
    test('mediaFastForward wire name is mediaFastForward', () {
      expect(RemoteCommand.mediaFastForward.wireName, 'mediaFastForward');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/remote/domain/remote_command_test.dart
```

Expected: FAIL — enum values do not exist

- [ ] **Step 3: Add media commands to `remote_command.dart`**

```dart
enum RemoteCommand {
  power('power'),
  home('home'),
  back('back'),
  menu('menu'),
  up('up'),
  down('down'),
  left('left'),
  right('right'),
  select('select'),
  volumeUp('volumeUp'),
  volumeDown('volumeDown'),
  mute('mute'),
  channelUp('channelUp'),
  channelDown('channelDown'),
  mediaPlayPause('mediaPlayPause'),
  mediaStop('mediaStop'),
  mediaNext('mediaNext'),
  mediaPrevious('mediaPrevious'),
  mediaRewind('mediaRewind'),
  mediaFastForward('mediaFastForward');

  const RemoteCommand(this.wireName);

  final String wireName;
}
```

- [ ] **Step 4: Add media keycodes to proto**

In `android/app/src/main/proto/remotemessage.proto`, add before the closing `}` of the `RemoteKeyCode` enum (after `KEYCODE_CHANNEL_DOWN = 167;`):

```protobuf
  KEYCODE_MEDIA_PLAY_PAUSE = 85;
  KEYCODE_MEDIA_STOP = 86;
  KEYCODE_MEDIA_NEXT = 87;
  KEYCODE_MEDIA_PREVIOUS = 88;
  KEYCODE_MEDIA_REWIND = 89;
  KEYCODE_MEDIA_FAST_FORWARD = 90;
```

- [ ] **Step 5: Add media mappings to `RemoteCommandMapper.kt`**

Add 6 entries to the `keyCodes` map (after `"channelDown" to RemoteKeyCode.KEYCODE_CHANNEL_DOWN`):

```kotlin
"mediaPlayPause"  to RemoteKeyCode.KEYCODE_MEDIA_PLAY_PAUSE,
"mediaStop"       to RemoteKeyCode.KEYCODE_MEDIA_STOP,
"mediaNext"       to RemoteKeyCode.KEYCODE_MEDIA_NEXT,
"mediaPrevious"   to RemoteKeyCode.KEYCODE_MEDIA_PREVIOUS,
"mediaRewind"     to RemoteKeyCode.KEYCODE_MEDIA_REWIND,
"mediaFastForward" to RemoteKeyCode.KEYCODE_MEDIA_FAST_FORWARD,
```

- [ ] **Step 6: Run Kotlin tests**

```bash
cd android && ./gradlew :app:testDebugUnitTest --tests "*.RemoteCommandMapperTest" && cd ..
```

Expected: PASS (existing tests pass; no new Kotlin tests needed since the mapper test already covers the pattern)

- [ ] **Step 7: Run Flutter tests**

```bash
flutter test test/features/remote/domain/remote_command_test.dart
```

Expected: PASS (6 tests)

- [ ] **Step 8: Commit**

```bash
git add lib/features/remote/domain/remote_command.dart \
        android/app/src/main/proto/remotemessage.proto \
        android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapper.kt \
        test/features/remote/domain/remote_command_test.dart
git commit -m "feat: add 6 media transport commands (play/pause, stop, next, prev, rewind, ffwd)"
```

---

## Task 6: Media Tab Widget

**Files:**
- Create: `lib/features/remote/presentation/widgets/media_tab.dart`

- [ ] **Step 1: Write smoke test**

Create `test/features/remote/presentation/widgets/media_tab_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/domain/remote_command.dart';
import 'package:justremote/features/remote/presentation/widgets/media_tab.dart';

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
```

Note: add `import 'package:justremote/features/remote/presentation/widgets/remote_button_widget.dart';` to the test file.

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/remote/presentation/widgets/media_tab_test.dart
```

Expected: FAIL — `MediaTab` does not exist

- [ ] **Step 3: Create `media_tab.dart`**

```dart
import 'package:flutter/material.dart';

import '../../domain/remote_command.dart';
import 'remote_button_widget.dart';

class MediaTab extends StatelessWidget {
  const MediaTab({required this.onCommand, super.key});

  final ValueChanged<RemoteCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          RemoteButtonWidget(
            label: 'Previous',
            icon: Icons.skip_previous_rounded,
            onPressed: () => onCommand(RemoteCommand.mediaPrevious),
          ),
          RemoteButtonWidget(
            label: 'Play / Pause',
            icon: Icons.play_arrow_rounded,
            onPressed: () => onCommand(RemoteCommand.mediaPlayPause),
          ),
          RemoteButtonWidget(
            label: 'Next',
            icon: Icons.skip_next_rounded,
            onPressed: () => onCommand(RemoteCommand.mediaNext),
          ),
          RemoteButtonWidget(
            label: 'Rewind',
            icon: Icons.fast_rewind_rounded,
            onPressed: () => onCommand(RemoteCommand.mediaRewind),
          ),
          RemoteButtonWidget(
            label: 'Stop',
            icon: Icons.stop_rounded,
            onPressed: () => onCommand(RemoteCommand.mediaStop),
          ),
          RemoteButtonWidget(
            label: 'Fast Forward',
            icon: Icons.fast_forward_rounded,
            onPressed: () => onCommand(RemoteCommand.mediaFastForward),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/remote/presentation/widgets/media_tab_test.dart
```

Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/remote/presentation/widgets/media_tab.dart \
        test/features/remote/presentation/widgets/media_tab_test.dart
git commit -m "feat: MediaTab widget — 2×3 media transport grid"
```

---

## Task 7: Input Tab Widget

**Files:**
- Create: `lib/features/remote/presentation/widgets/input_tab.dart`

The touchpad translates gestures to D-pad commands. A pan beyond a 24dp threshold fires the corresponding directional command. Tap fires select. Long-press fires back.

- [ ] **Step 1: Write smoke test**

Create `test/features/remote/presentation/widgets/input_tab_test.dart`:

```dart
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
    // Touchpad surface is a GestureDetector wrapping a Container
    expect(find.byType(GestureDetector), findsWidgets);
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
    // Tap the touchpad area (first GestureDetector)
    await tester.tap(find.byKey(const Key('touchpad')));
    await tester.pump();
    expect(fired, RemoteCommand.select);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/remote/presentation/widgets/input_tab_test.dart
```

Expected: FAIL — `InputTab` does not exist

- [ ] **Step 3: Create `input_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/remote_command.dart';

class InputTab extends StatefulWidget {
  const InputTab({
    required this.onCommand,
    required this.onSendText,
    super.key,
  });

  final ValueChanged<RemoteCommand> onCommand;
  final ValueChanged<String> onSendText;

  @override
  State<InputTab> createState() => _InputTabState();
}

class _InputTabState extends State<InputTab> {
  final _textController = TextEditingController();
  Offset? _panStart;
  static const _threshold = 24.0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) => _panStart = d.localPosition;

  void _onPanUpdate(DragUpdateDetails d) {
    final start = _panStart;
    if (start == null) return;
    final delta = d.localPosition - start;
    if (delta.distance < _threshold) return;
    _panStart = d.localPosition; // reset so repeated fires work naturally

    final RemoteCommand cmd;
    if (delta.dx.abs() > delta.dy.abs()) {
      cmd = delta.dx > 0 ? RemoteCommand.right : RemoteCommand.left;
    } else {
      cmd = delta.dy > 0 ? RemoteCommand.down : RemoteCommand.up;
    }
    HapticFeedback.lightImpact();
    widget.onCommand(cmd);
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onCommand(RemoteCommand.select);
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    widget.onCommand(RemoteCommand.back);
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              key: const Key('touchpad'),
              onTap: _onTap,
              onLongPress: _onLongPress,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.glassButtonBorder),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 32, color: AppTheme.textDim),
                      SizedBox(height: 8),
                      Text(
                        'Swipe to navigate · Tap to select · Hold for back',
                        style: TextStyle(color: AppTheme.textDim, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendText(),
                  decoration: const InputDecoration(
                    hintText: 'Type to send text to TV',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SendButton(onTap: _sendText),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        widget.onTap();
        setState(() => _pressed = false);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.accentLight, AppTheme.accentDark],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _pressed
              ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 8)]
              : null,
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/remote/presentation/widgets/input_tab_test.dart
```

Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/remote/presentation/widgets/input_tab.dart \
        test/features/remote/presentation/widgets/input_tab_test.dart
git commit -m "feat: InputTab — gesture touchpad + text send row"
```

---

## Task 8: Remote Screen — Fixed + Tabs Layout

**Files:**
- Modify: `lib/features/remote/presentation/remote_screen.dart`

- [ ] **Step 1: Write smoke test**

Create `test/features/remote/presentation/remote_screen_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify current state**

```bash
flutter test test/features/remote/presentation/remote_screen_test.dart
```

Expected: first test PASSES, second FAILS (tabs not present yet)

- [ ] **Step 3: Rebuild `remote_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../tv_discovery/domain/tv_device.dart';
import '../data/remote_control_channel.dart';
import '../domain/remote_command.dart';
import 'widgets/dpad_widget.dart';
import 'widgets/input_tab.dart';
import 'widgets/media_tab.dart';
import 'widgets/status_bar.dart';
import 'widgets/top_controls.dart';
import 'widgets/volume_controls.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({required this.device, super.key});

  final TvDevice? device;

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  final _channel = RemoteControlChannel();
  bool _connected = false;
  String? _deviceName;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final device = widget.device;
    if (device == null) {
      final status = await _channel.getConnectionStatus();
      if (!mounted) return;
      setState(() {
        _connected = status['connected'] == true;
        _deviceName = status['deviceName'] as String?;
      });
      return;
    }
    final connected = await _channel.connectToTv(device);
    if (!mounted) return;
    setState(() {
      _connected = connected;
      _deviceName = device.name;
    });
  }

  Future<void> _send(RemoteCommand command) async {
    try {
      await _channel.sendCommand(command);
    } catch (_) {
      // Command failure is non-fatal; TV may just ignore it.
    }
  }

  Future<void> _sendText(String text) async {
    for (final char in text.characters) {
      await _channel.sendCommand(RemoteCommand.values.firstWhere(
        (c) => c.wireName == 'char_$char',
        orElse: () => RemoteCommand.select,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '',
      actions: [
        IconButton(
          tooltip: 'Saved TVs',
          icon: const Icon(Icons.devices_rounded),
          onPressed: () => context.go('/saved'),
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => context.push('/settings'),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: StatusBar(
              connected: _connected,
              deviceName: _deviceName ?? widget.device?.name ?? 'No TV connected',
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TopControls(onCommand: _send),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                // Remote tab — D-pad dominant
                LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.maxHeight.clamp(200.0, 300.0);
                    return Center(
                      child: SizedBox.square(
                        dimension: size,
                        child: DpadWidget(onCommand: _send),
                      ),
                    );
                  },
                ),
                // Media tab
                MediaTab(onCommand: _send),
                // Input tab
                InputTab(onCommand: _send, onSendText: _sendText),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: VolumeControls(onCommand: _send),
          ),
          const SizedBox(height: 4),
          _BottomTabBar(
            selectedIndex: _tabIndex,
            onTab: (i) => setState(() => _tabIndex = i),
          ),
        ],
      ),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.selectedIndex, required this.onTab});

  final int selectedIndex;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFF141920),
        border: Border(top: BorderSide(color: AppTheme.glassButtonBorder)),
      ),
      child: Row(
        children: [
          _Tab(icon: Icons.sports_esports_rounded, label: 'Remote',
              selected: selectedIndex == 0, onTap: () => onTab(0)),
          _Tab(icon: Icons.music_note_rounded, label: 'Media',
              selected: selectedIndex == 1, onTap: () => onTab(1)),
          _Tab(icon: Icons.keyboard_rounded, label: 'Input',
              selected: selectedIndex == 2, onTap: () => onTab(2)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.accent : AppTheme.textDim;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
```

Note: `_sendText` above is a placeholder that won't work correctly — text input is wired up in the original 14-task plan (Task: keyboard input). For now `InputTab.onSendText` is connected and the text field renders correctly; the actual character-by-character send requires the `sendTextInput` channel method from the other plan.

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/remote/presentation/remote_screen_test.dart
```

Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/remote/presentation/remote_screen.dart \
        test/features/remote/presentation/remote_screen_test.dart
git commit -m "feat: remote screen Fixed+Tabs layout — D-pad/Media/Input tabs, no scroll"
```

---

## Task 9: Scan Screen — Radar Animation

**Files:**
- Modify: `lib/features/tv_discovery/presentation/scan_tv_screen.dart`

This task replaces the `CircularProgressIndicator` with an animated pulse radar and adds slide-in TV cards. The existing `FutureBuilder` structure is preserved.

- [ ] **Step 1: Write smoke test**

Create `test/features/tv_discovery/presentation/scan_tv_screen_test.dart`:

```dart
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
    // While scanning (future pending), RadarWidget should be visible
    expect(find.byType(RadarWidget), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/tv_discovery/presentation/scan_tv_screen_test.dart
```

Expected: FAIL — `RadarWidget` not found

- [ ] **Step 3: Add `RadarWidget` and update `scan_tv_screen.dart`**

Add `RadarWidget` as a private class and update the scan-in-progress state. The `FutureBuilder` structure stays; only the loading branch changes, plus a new `_TvSlideCard` replaces the plain `TvDeviceCard` for the list, and an "Enter IP manually" button is added.

Replace the full file:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../domain/tv_device.dart';
import '../domain/tv_discovery_repository.dart';
import 'widgets/tv_device_card.dart';

class ScanTvScreen extends ConsumerStatefulWidget {
  const ScanTvScreen({super.key});

  @override
  ConsumerState<ScanTvScreen> createState() => _ScanTvScreenState();
}

class _ScanTvScreenState extends ConsumerState<ScanTvScreen> {
  late Future<List<TvDevice>> _scanFuture;

  @override
  void initState() {
    super.initState();
    _scanFuture = _scan();
  }

  Future<List<TvDevice>> _scan() =>
      ref.read(tvDiscoveryRepositoryProvider).scanForTvs();

  void _rescan() => setState(() => _scanFuture = _scan());

  void _enterManualIp() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceRaised,
        title: const Text('Enter TV IP address'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '192.168.1.x'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                Navigator.of(ctx).pop();
                final device = TvDevice(name: ip, host: ip);
                context.push('/pairing', extra: device);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Find TV',
      actions: [
        IconButton(
          tooltip: 'Saved TVs',
          icon: const Icon(Icons.devices_rounded),
          onPressed: () => context.go('/saved'),
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => context.push('/settings'),
        ),
      ],
      body: FutureBuilder<List<TvDevice>>(
        future: _scanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _ScanningView();
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Scan failed',
              message: 'Check Wi-Fi and try scanning again.',
              action: PrimaryButton(
                label: 'Rescan',
                icon: Icons.refresh_rounded,
                onPressed: _rescan,
              ),
            );
          }
          final devices = snapshot.data ?? const [];
          if (devices.isEmpty) {
            return _EmptyResult(onRescan: _rescan, onManualIp: _enterManualIp);
          }
          return _ResultList(
            devices: devices,
            onRescan: _rescan,
            onManualIp: _enterManualIp,
          );
        },
      ),
    );
  }
}

// ── Scanning state ────────────────────────────────────────────────

class _ScanningView extends StatelessWidget {
  const _ScanningView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RadarWidget(size: 160),
          const SizedBox(height: 20),
          Text(
            'SCANNING',
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class RadarWidget extends StatefulWidget {
  const RadarWidget({this.size = 160, super.key});

  final double size;

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse1;
  late Animation<double> _pulse2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulse1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 1.0)),
    );
    _pulse2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0)),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _RadarPainter(_pulse1.value, _pulse2.value),
            child: Center(
              child: Container(
                width: widget.size * 0.22,
                height: widget.size * 0.22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  border: Border.all(color: AppTheme.accentBorder),
                ),
                child: const Center(
                  child: Icon(Icons.cell_tower_rounded, color: AppTheme.accent, size: 18),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter(this.pulse1, this.pulse2);

  final double pulse1;
  final double pulse2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.width / 2;

    // Static concentric rings
    final staticPaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final frac in [0.4, 0.7, 1.0]) {
      canvas.drawCircle(center, maxR * frac, staticPaint);
    }

    // Animated pulse rings
    _drawPulse(canvas, center, maxR, pulse1);
    if (pulse2 > 0) _drawPulse(canvas, center, maxR, pulse2);
  }

  void _drawPulse(Canvas canvas, Offset center, double maxR, double t) {
    final r = maxR * 0.2 + maxR * 0.8 * t;
    final opacity = (1.0 - t).clamp(0.0, 0.6);
    final paint = Paint()
      ..color = AppTheme.accent.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.pulse1 != pulse1 || old.pulse2 != pulse2;
}

// ── Result states ─────────────────────────────────────────────────

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.onRescan, required this.onManualIp});
  final VoidCallback onRescan;
  final VoidCallback onManualIp;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No TVs found',
      message: 'Make sure your Android TV is on the same Wi-Fi network.',
      action: Column(
        children: [
          PrimaryButton(
            label: 'Rescan',
            icon: Icons.refresh_rounded,
            onPressed: onRescan,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onManualIp,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Enter IP manually'),
          ),
        ],
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.devices,
    required this.onRescan,
    required this.onManualIp,
  });
  final List<TvDevice> devices;
  final VoidCallback onRescan;
  final VoidCallback onManualIp;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: devices.length + 2,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index < devices.length) {
          return _SlideInCard(
            delay: Duration(milliseconds: index * 80),
            child: TvDeviceCard(
              device: devices[index],
              onTap: () => context.push('/pairing', extra: devices[index]),
            ),
          );
        }
        if (index == devices.length) {
          return PrimaryButton(
            label: 'Rescan',
            icon: Icons.refresh_rounded,
            onPressed: onRescan,
          );
        }
        return TextButton.icon(
          onPressed: onManualIp,
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: const Text('Enter IP manually'),
        );
      },
    );
  }
}

class _SlideInCard extends StatefulWidget {
  const _SlideInCard({required this.child, required this.delay});
  final Widget child;
  final Duration delay;

  @override
  State<_SlideInCard> createState() => _SlideInCardState();
}

class _SlideInCardState extends State<_SlideInCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slide.value),
        child: Opacity(opacity: _fade.value, child: child),
      ),
      child: widget.child,
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/tv_discovery/presentation/scan_tv_screen_test.dart
```

Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add lib/features/tv_discovery/presentation/scan_tv_screen.dart \
        test/features/tv_discovery/presentation/scan_tv_screen_test.dart
git commit -m "feat: scan screen radar animation, slide-in TV cards, manual IP entry"
```

---

## Task 10: Pairing Screen — Segmented Code Boxes

**Files:**
- Modify: `lib/features/pairing/presentation/pairing_screen.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/pairing/presentation/pairing_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/pairing/presentation/pairing_screen.dart';
import 'package:justremote/features/tv_discovery/domain/tv_device.dart';

void main() {
  final device = TvDevice(name: 'Test TV', host: '192.168.1.1');

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
    // Enter 3 characters
    await tester.enterText(find.byType(TextField), 'AB3');
    await tester.pump();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/pairing/presentation/pairing_screen_test.dart
```

Expected: FAIL — `CodeBox` not found, no 6 boxes

- [ ] **Step 3: Replace `pairing_screen.dart`**

Keep all pairing logic (`_startPairing`, `_pair`, state machine) exactly as-is. Only the UI of the code input section changes.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../saved_tvs/data/saved_tvs_repository.dart';
import '../../tv_discovery/domain/tv_device.dart';
import '../data/pairing_channel.dart';
import '../domain/pairing_status.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({required this.device, super.key});

  final TvDevice device;

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  final _pairingChannel = PairingChannel();
  PairingStatus _status = PairingStatus.idle;
  String? _message;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
    Future<void>.microtask(_startPairing);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _startPairing() async {
    setState(() {
      _status = PairingStatus.pairing;
      _message = 'Starting pairing on ${widget.device.name}...';
    });
    try {
      final message = await _pairingChannel.startPairing(widget.device);
      if (!mounted) return;
      setState(() {
        _status = PairingStatus.idle;
        _message = message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = PairingStatus.failed;
        _message = 'Could not start pairing. Check that the TV is on.';
      });
    }
  }

  Future<void> _pair() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _status = PairingStatus.failed;
        _message = 'Enter the pairing code shown on your TV.';
      });
      return;
    }
    setState(() {
      _status = PairingStatus.pairing;
      _message = null;
    });
    try {
      final message = await _pairingChannel.pairTv(
        device: widget.device,
        pairingCode: code,
      );
      await ref.read(savedTvsRepositoryProvider).saveTv(widget.device);
      ref.invalidate(savedTvsProvider);
      setState(() {
        _status = PairingStatus.success;
        _message = message;
      });
      if (mounted) context.go('/remote', extra: widget.device);
    } catch (_) {
      setState(() {
        _status = PairingStatus.failed;
        _message = 'Could not pair with ${widget.device.name}.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPairing = _status == PairingStatus.pairing;
    final code = _codeController.text;
    final isCodeComplete = code.length == 6;

    return AppScaffold(
      title: 'Pair TV',
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          // TV status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.tv_rounded, size: 32, color: AppTheme.accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.device.host,
                        style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'A code appeared on your TV.\nEnter it below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          // 6 segmented boxes — driven by hidden TextField
          GestureDetector(
            onTap: () => _codeFocus.requestFocus(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final char = i < code.length ? code[i] : null;
                final isActive = i == code.length && code.length < 6;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CodeBox(char: char, isActive: isActive),
                );
              }),
            ),
          ),
          // Hidden text field
          SizedBox(
            height: 0,
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _codeController,
                focusNode: _codeFocus,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                onSubmitted: (_) => _pair(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _message == null
                ? const SizedBox.shrink()
                : Text(
                    _message!,
                    key: ValueKey(_message),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _status == PairingStatus.failed
                          ? Theme.of(context).colorScheme.error
                          : AppTheme.accent,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Confirm',
            icon: Icons.link_rounded,
            isLoading: isPairing,
            onPressed: (isPairing || !isCodeComplete) ? null : _pair,
          ),
        ],
      ),
    );
  }
}

class CodeBox extends StatelessWidget {
  const CodeBox({required this.char, required this.isActive, super.key});

  final String? char;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 42,
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? AppTheme.accent
              : (char != null ? AppTheme.glassButtonBorder : AppTheme.glassButtonBorder),
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 6)]
            : null,
      ),
      child: Center(
        child: isActive
            ? _BlinkingCursor()
            : (char != null
                ? Text(
                    char!.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _ctrl.value > 0.5 ? 1.0 : 0.0,
        child: Container(
          width: 2,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/pairing/presentation/pairing_screen_test.dart
```

Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/pairing/presentation/pairing_screen.dart \
        test/features/pairing/presentation/pairing_screen_test.dart
git commit -m "feat: pairing screen — 6 segmented code boxes with blinking cursor"
```

---

## Task 11: Onboarding — Illustrated Scenes

**Files:**
- Modify: `lib/features/onboarding/presentation/onboarding_screen.dart`

Replace the plain `_OnboardingPage` icon-in-circle widget with illustrated scene widgets. The `PageView`, page controller, dots, and navigation logic remain unchanged. Only `_pages` and the `_OnboardingPage` class change.

- [ ] **Step 1: Write smoke test**

Create `test/features/onboarding/presentation/onboarding_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders without error', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );
    await tester.pump();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Next button advances to page 2', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    // Page 2 scene title
    expect(find.text("Same Wi-Fi.\nZero setup."), findsOneWidget);
  });

  testWidgets('Last page shows Get Started', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );
    await tester.pump();
    // Advance to page 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify second test fails**

```bash
flutter test test/features/onboarding/presentation/onboarding_screen_test.dart
```

Expected: test 1 PASSES, tests 2 and 3 FAIL (different titles expected)

- [ ] **Step 3: Update `onboarding_screen.dart`**

Replace the `_pages` list and `_OnboardingPage` class. Keep everything else (controller, completion logic, dots, button) identical.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/saved_tvs/data/saved_tvs_repository.dart';
import '../../../shared/widgets/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _Page1(),
    _Page2(),
    _Page3(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(AppConstants.hasCompletedOnboardingKey, true);
    if (mounted) context.go('/scan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => _page = value),
                  children: _pages,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _page ? 20 : 7,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: index == _page
                          ? AppTheme.accent
                          : Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _page == _pages.length - 1 ? 'Get Started' : 'Next',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  if (_page == _pages.length - 1) {
                    _complete();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page scenes ───────────────────────────────────────────────────

class _Page1 extends StatelessWidget {
  const _Page1();

  @override
  Widget build(BuildContext context) {
    return _ScenePage(
      title: 'Your phone.\nYour remote.',
      message: 'Works with any Android TV or Google TV on your Wi-Fi.',
      scene: const _PhoneTvScene(),
    );
  }
}

class _Page2 extends StatelessWidget {
  const _Page2();

  @override
  Widget build(BuildContext context) {
    return _ScenePage(
      title: 'Same Wi-Fi.\nZero setup.',
      message: 'JustRemote discovers nearby TVs automatically.',
      scene: const _WifiScene(),
    );
  }
}

class _Page3 extends StatelessWidget {
  const _Page3();

  @override
  Widget build(BuildContext context) {
    return _ScenePage(
      title: 'Pair once.\nAlways ready.',
      message: 'Save your TV and reconnect in seconds.',
      scene: const _LockScene(),
    );
  }
}

class _ScenePage extends StatelessWidget {
  const _ScenePage({
    required this.title,
    required this.message,
    required this.scene,
  });

  final String title;
  final String message;
  final Widget scene;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        scene,
        const SizedBox(height: 36),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

// ── Scene widgets (Flutter primitives, no image assets) ───────────

class _PhoneTvScene extends StatelessWidget {
  const _PhoneTvScene();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Phone (left)
          Positioned(
            left: 10,
            child: Container(
              width: 48,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accent, width: 2),
                boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 12)],
              ),
              child: const Center(
                child: Icon(Icons.sports_esports_rounded, color: AppTheme.accent, size: 22),
              ),
            ),
          ),
          // Connection line
          Positioned(
            left: 62,
            right: 62,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accent, Color(0x336C63FF)],
                ),
              ),
            ),
          ),
          // Dot on line
          Positioned(
            left: 100,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent,
                boxShadow: [BoxShadow(color: AppTheme.accent, blurRadius: 4)],
              ),
            ),
          ),
          // TV (right)
          Positioned(
            right: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRaised,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.glassButtonBorder),
                  ),
                  child: const Center(
                    child: Icon(Icons.movie_rounded, color: AppTheme.textDim, size: 20),
                  ),
                ),
                Container(
                  width: 24,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRaised,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WifiScene extends StatelessWidget {
  const _WifiScene();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 120,
      child: CustomPaint(
        painter: _WifiPainter(),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Icon(Icons.wifi_rounded, color: AppTheme.accent, size: 48),
          ),
        ),
      ),
    );
  }
}

class _WifiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.width / 2, size.height * 0.55);
    for (final r in [30.0, 55.0, 80.0]) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_WifiPainter _) => false;
}

class _LockScene extends StatelessWidget {
  const _LockScene();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accentBorder),
          ),
          child: const Center(
            child: Icon(Icons.lock_open_rounded, color: AppTheme.accent, size: 46),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent,
              boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.5), blurRadius: 8)],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/features/onboarding/presentation/onboarding_screen_test.dart
```

Expected: PASS (3 tests)

- [ ] **Step 5: Run full test suite**

```bash
flutter test
```

Expected: All tests pass. If any fail, fix before committing.

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/presentation/onboarding_screen.dart \
        test/features/onboarding/presentation/onboarding_screen_test.dart
git commit -m "feat: onboarding illustrated scenes — phone+TV, WiFi, lock/check"
```

---

## Final Verification

After all 11 tasks:

```bash
flutter test
flutter analyze
flutter build apk --debug
```

All three should succeed with no errors.
