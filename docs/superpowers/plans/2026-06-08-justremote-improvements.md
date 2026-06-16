# JustRemote Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix code quality issues in the remote control architecture (Phase 1), add keyboard/touchpad/manual-IP features (Phase 2), and add media controls, tablet layout, and Android background service (Phase 3).

**Architecture:** A `RemoteConnectionNotifier` (Riverpod `Notifier`) becomes the single source of truth for connection state, replacing local widget fields. All three phases are sequential — complete Phase 1 before starting Phase 2, Phase 2 before Phase 3.

**Tech Stack:** Flutter, Dart 3 (sealed classes, pattern matching), Riverpod 3, go_router, Kotlin, Android NSD, protobuf-lite, Android foreground service.

**Spec:** [docs/superpowers/specs/2026-06-08-justremote-improvements-design.md](../specs/2026-06-08-justremote-improvements-design.md)

---

## File Map

### Phase 1 — Foundation

| Action | File |
|--------|------|
| Create | `lib/features/remote/domain/remote_connection_state.dart` |
| Create | `lib/features/remote/data/remote_connection_notifier.dart` |
| Modify | `lib/features/remote/data/remote_control_channel.dart` |
| Modify | `lib/features/remote/presentation/remote_screen.dart` |
| Modify | `lib/features/saved_tvs/presentation/saved_tvs_screen.dart` |
| Create | `test/remote_connection_state_test.dart` |
| Create | `test/remote_connection_notifier_test.dart` |
| Modify | `test/remote_control_channel_test.dart` |

### Phase 2 — Core Features

| Action | File |
|--------|------|
| Modify | `android/app/src/main/proto/remotemessage.proto` |
| Modify | `android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapper.kt` |
| Modify | `android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteProtocolClient.kt` |
| Modify | `android/app/src/main/kotlin/com/justremote/justremote/remote/TvCommandManager.kt` |
| Modify | `android/app/src/main/kotlin/com/justremote/justremote/remote/TvRemotePlugin.kt` |
| Modify | `android/app/src/test/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapperTest.kt` |
| Create | `lib/features/remote/presentation/widgets/keyboard_sheet.dart` |
| Create | `lib/features/remote/presentation/widgets/touchpad_sheet.dart` |
| Create | `lib/features/tv_discovery/presentation/widgets/enter_ip_sheet.dart` |
| Modify | `lib/features/tv_discovery/presentation/scan_tv_screen.dart` |

### Phase 3 — Advanced Features

| Action | File |
|--------|------|
| Modify | `android/app/src/main/proto/remotemessage.proto` |
| Modify | `android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapper.kt` |
| Modify | `android/app/src/test/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapperTest.kt` |
| Modify | `lib/features/remote/domain/remote_command.dart` |
| Create | `lib/features/remote/presentation/widgets/media_controls.dart` |
| Modify | `lib/features/remote/presentation/remote_screen.dart` |
| Create | `android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionService.kt` |
| Create | `android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionServiceBinder.kt` |
| Modify | `android/app/src/main/kotlin/com/justremote/justremote/remote/TvRemotePlugin.kt` |
| Modify | `android/app/src/main/AndroidManifest.xml` |

---

## Phase 1: Foundation

### Task 1: RemoteConnectionState sealed class

**Files:**
- Create: `lib/features/remote/domain/remote_connection_state.dart`
- Create: `test/remote_connection_state_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/remote_connection_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/domain/remote_connection_state.dart';
import 'package:justremote/features/tv_discovery/domain/tv_device.dart';

void main() {
  const device = TvDevice(
    id: 'tv_1',
    name: 'My TV',
    host: '192.168.1.100',
    port: 6466,
    type: '_androidtvremote2._tcp',
  );

  test('RemoteDisconnected is a RemoteConnectionState', () {
    expect(const RemoteDisconnected(), isA<RemoteConnectionState>());
  });

  test('RemoteConnecting is a RemoteConnectionState', () {
    expect(const RemoteConnecting(), isA<RemoteConnectionState>());
  });

  test('RemoteConnected holds its device', () {
    const state = RemoteConnected(device);
    expect(state.device, device);
  });

  test('RemoteFailed holds message and optional device', () {
    const state = RemoteFailed('Timed out', device: device);
    expect(state.message, 'Timed out');
    expect(state.device, device);
  });

  test('RemoteFailed device is optional', () {
    const state = RemoteFailed('No device');
    expect(state.device, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/remote_connection_state_test.dart
```

Expected: compile error — `RemoteConnectionState` not found.

- [ ] **Step 3: Create the sealed class**

```dart
// lib/features/remote/domain/remote_connection_state.dart
import '../../tv_discovery/domain/tv_device.dart';

sealed class RemoteConnectionState {
  const RemoteConnectionState();
}

class RemoteDisconnected extends RemoteConnectionState {
  const RemoteDisconnected();
}

class RemoteConnecting extends RemoteConnectionState {
  const RemoteConnecting();
}

class RemoteConnected extends RemoteConnectionState {
  const RemoteConnected(this.device);
  final TvDevice device;
}

class RemoteFailed extends RemoteConnectionState {
  const RemoteFailed(this.message, {this.device});
  final String message;
  final TvDevice? device;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/remote_connection_state_test.dart
```

Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/remote/domain/remote_connection_state.dart test/remote_connection_state_test.dart
git commit -m "feat: add RemoteConnectionState sealed class"
```

---

### Task 2: RemoteControlChannel — provider and sendTextInput

**Files:**
- Modify: `lib/features/remote/data/remote_control_channel.dart`
- Modify: `test/remote_control_channel_test.dart`

- [ ] **Step 1: Add the sendTextInput test**

Append to the existing `test/remote_control_channel_test.dart`, inside `main()` after the existing test:

```dart
  test(
    'sendTextInput delegates the text to the native channel',
    () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (
            MethodCall call,
          ) async {
            capturedCall = call;
            return <String, Object?>{'success': true};
          });

      final channel = RemoteControlChannel();
      final success = await channel.sendTextInput('hello');

      expect(success, isTrue);
      expect(capturedCall?.method, 'sendTextInput');
      expect(capturedCall?.arguments, <String, Object?>{'text': 'hello'});
    },
  );
```

- [ ] **Step 2: Run test to verify the new test fails**

```bash
flutter test test/remote_control_channel_test.dart
```

Expected: compile error — `sendTextInput` not found.

- [ ] **Step 3: Add sendTextInput and the provider to RemoteControlChannel**

Add `sendTextInput` to the class and the provider at the bottom of `lib/features/remote/data/remote_control_channel.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../tv_discovery/domain/tv_device.dart';
import '../domain/remote_command.dart';

class RemoteControlChannel {
  RemoteControlChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppConstants.methodChannelName);

  final MethodChannel _channel;

  Future<bool> connectToTv(TvDevice device) async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>('connectToTv', {
        'deviceId': device.id,
        'host': device.host,
        'port': device.port,
        'name': device.name,
      });
      return response?['success'] == true;
    } on PlatformException catch (error) {
      throw AppException('Unable to connect to TV.', cause: error);
    }
  }

  Future<bool> disconnectTv() async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>('disconnectTv');
      return response?['success'] == true;
    } on PlatformException catch (error) {
      throw AppException('Unable to disconnect TV.', cause: error);
    }
  }

  Future<bool> sendCommand(RemoteCommand command) async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'sendCommand',
        {'command': command.wireName},
      );
      return response?['success'] == true;
    } on PlatformException catch (error) {
      throw AppException('Unable to send command.', cause: error);
    }
  }

  Future<bool> sendTextInput(String text) async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'sendTextInput',
        {'text': text},
      );
      return response?['success'] == true;
    } on PlatformException catch (error) {
      throw AppException('Unable to send text.', cause: error);
    }
  }

  Future<Map<String, Object?>> getConnectionStatus() async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getConnectionStatus',
      );
      return Map<String, Object?>.from(response ?? const {});
    } on PlatformException catch (error) {
      throw AppException('Unable to read connection status.', cause: error);
    }
  }
}

final remoteControlChannelProvider = Provider<RemoteControlChannel>(
  (_) => RemoteControlChannel(),
);
```

- [ ] **Step 4: Run tests to verify all pass**

```bash
flutter test test/remote_control_channel_test.dart
```

Expected: Both tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/remote/data/remote_control_channel.dart test/remote_control_channel_test.dart
git commit -m "feat: add sendTextInput and provider to RemoteControlChannel"
```

---

### Task 3: RemoteConnectionNotifier

**Files:**
- Create: `lib/features/remote/data/remote_connection_notifier.dart`
- Create: `test/remote_connection_notifier_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/remote_connection_notifier_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/core/errors/app_exception.dart';
import 'package:justremote/features/remote/data/remote_connection_notifier.dart';
import 'package:justremote/features/remote/data/remote_control_channel.dart';
import 'package:justremote/features/remote/domain/remote_command.dart';
import 'package:justremote/features/remote/domain/remote_connection_state.dart';
import 'package:justremote/features/tv_discovery/domain/tv_device.dart';

const _device = TvDevice(
  id: 'tv_1',
  name: 'My TV',
  host: '192.168.1.100',
  port: 6466,
  type: '_androidtvremote2._tcp',
);

class _FakeChannel implements RemoteControlChannel {
  bool connectResult = true;
  bool throwOnConnect = false;
  Map<String, Object?> statusResult = {'connected': false, 'deviceName': null};

  @override
  Future<bool> connectToTv(TvDevice device) async {
    if (throwOnConnect) throw AppException('connect error');
    return connectResult;
  }

  @override
  Future<bool> disconnectTv() async => true;

  @override
  Future<bool> sendCommand(RemoteCommand command) async => true;

  @override
  Future<bool> sendTextInput(String text) async => true;

  @override
  Future<Map<String, Object?>> getConnectionStatus() async => statusResult;
}

ProviderContainer _makeContainer(_FakeChannel fake) {
  return ProviderContainer(
    overrides: [remoteControlChannelProvider.overrideWithValue(fake)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initial state is RemoteDisconnected', () {
    final container = _makeContainer(_FakeChannel());
    addTearDown(container.dispose);
    expect(container.read(remoteConnectionProvider), isA<RemoteDisconnected>());
  });

  test('connect transitions to RemoteConnected on success', () async {
    final container = _makeContainer(_FakeChannel());
    addTearDown(container.dispose);

    await container.read(remoteConnectionProvider.notifier).connect(_device);

    expect(container.read(remoteConnectionProvider), isA<RemoteConnected>());
    final connected = container.read(remoteConnectionProvider) as RemoteConnected;
    expect(connected.device, _device);
  });

  test('connect transitions to RemoteFailed when channel returns false', () async {
    final fake = _FakeChannel()..connectResult = false;
    final container = _makeContainer(fake);
    addTearDown(container.dispose);

    await container.read(remoteConnectionProvider.notifier).connect(_device);

    expect(container.read(remoteConnectionProvider), isA<RemoteFailed>());
    final failed = container.read(remoteConnectionProvider) as RemoteFailed;
    expect(failed.device, _device);
  });

  test('connect transitions to RemoteFailed on AppException', () async {
    final fake = _FakeChannel()..throwOnConnect = true;
    final container = _makeContainer(fake);
    addTearDown(container.dispose);

    await container.read(remoteConnectionProvider.notifier).connect(_device);

    expect(container.read(remoteConnectionProvider), isA<RemoteFailed>());
  });

  test('connect with null device stays disconnected when no existing connection',
      () async {
    final fake = _FakeChannel()
      ..statusResult = {'connected': false, 'deviceName': null};
    final container = _makeContainer(fake);
    addTearDown(container.dispose);

    await container.read(remoteConnectionProvider.notifier).connect(null);

    expect(container.read(remoteConnectionProvider), isA<RemoteDisconnected>());
  });

  test('retry re-connects using the last failed device', () async {
    final fake = _FakeChannel()..connectResult = false;
    final container = _makeContainer(fake);
    addTearDown(container.dispose);

    await container.read(remoteConnectionProvider.notifier).connect(_device);
    expect(container.read(remoteConnectionProvider), isA<RemoteFailed>());

    fake.connectResult = true;
    await container.read(remoteConnectionProvider.notifier).retry();

    expect(container.read(remoteConnectionProvider), isA<RemoteConnected>());
  });

  test('disconnect transitions to RemoteDisconnected', () async {
    final container = _makeContainer(_FakeChannel());
    addTearDown(container.dispose);

    await container.read(remoteConnectionProvider.notifier).connect(_device);
    await container.read(remoteConnectionProvider.notifier).disconnect();

    expect(container.read(remoteConnectionProvider), isA<RemoteDisconnected>());
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/remote_connection_notifier_test.dart
```

Expected: compile error — `RemoteConnectionNotifier` and `remoteConnectionProvider` not found.

- [ ] **Step 3: Create the notifier**

```dart
// lib/features/remote/data/remote_connection_notifier.dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../tv_discovery/domain/tv_device.dart';
import '../domain/remote_command.dart';
import '../domain/remote_connection_state.dart';
import 'remote_control_channel.dart';

class RemoteConnectionNotifier extends Notifier<RemoteConnectionState> {
  @override
  RemoteConnectionState build() => const RemoteDisconnected();

  RemoteControlChannel get _channel => ref.read(remoteControlChannelProvider);

  Future<void> connect(TvDevice? device) async {
    if (device == null) {
      if (state is RemoteConnected) return;
      try {
        final status = await _channel.getConnectionStatus();
        if (status['connected'] == true) {
          final name = status['deviceName'] as String? ?? 'Android TV';
          state = RemoteConnected(
            TvDevice(id: 'existing', name: name, host: '', port: 0, type: ''),
          );
        }
      } catch (_) {}
      return;
    }

    state = const RemoteConnecting();
    try {
      final connected = await _channel.connectToTv(device);
      state = connected
          ? RemoteConnected(device)
          : RemoteFailed('Could not connect to ${device.name}', device: device);
    } on AppException catch (e) {
      state = RemoteFailed(e.message, device: device);
    } catch (_) {
      state = RemoteFailed('Connection failed', device: device);
    }
  }

  Future<void> sendCommand(RemoteCommand command) async {
    await HapticFeedback.lightImpact();
    try {
      await _channel.sendCommand(command);
    } on AppException {
      // transient failure — do not change connection state
    }
  }

  Future<void> sendTextInput(String text) async {
    await HapticFeedback.lightImpact();
    try {
      await _channel.sendTextInput(text);
    } on AppException {
      // text input failure is not fatal
    }
  }

  Future<void> retry() async {
    final current = state;
    if (current is RemoteFailed) {
      await connect(current.device);
    }
  }

  Future<void> disconnect() async {
    await _channel.disconnectTv();
    state = const RemoteDisconnected();
  }
}

final remoteConnectionProvider =
    NotifierProvider<RemoteConnectionNotifier, RemoteConnectionState>(
  RemoteConnectionNotifier.new,
);
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/remote_connection_notifier_test.dart
```

Expected: All 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/remote/data/remote_connection_notifier.dart test/remote_connection_notifier_test.dart
git commit -m "feat: add RemoteConnectionNotifier with Riverpod state management"
```

---

### Task 4: Refactor RemoteScreen

**Files:**
- Modify: `lib/features/remote/presentation/remote_screen.dart`

Replace the entire file content:

- [ ] **Step 1: Rewrite RemoteScreen**

```dart
// lib/features/remote/presentation/remote_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../tv_discovery/domain/tv_device.dart';
import '../data/remote_connection_notifier.dart';
import '../domain/remote_command.dart';
import '../domain/remote_connection_state.dart';
import 'widgets/dpad_widget.dart';
import 'widgets/remote_button_widget.dart';
import 'widgets/top_controls.dart';
import 'widgets/volume_controls.dart';

class RemoteScreen extends ConsumerStatefulWidget {
  const RemoteScreen({this.device, super.key});

  final TvDevice? device;

  @override
  ConsumerState<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends ConsumerState<RemoteScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(remoteConnectionProvider.notifier).connect(widget.device),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(remoteConnectionProvider);
    final onCommand = (RemoteCommand cmd) =>
        ref.read(remoteConnectionProvider.notifier).sendCommand(cmd);

    return AppScaffold(
      title: 'Remote',
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final dpadSize = constraints.maxWidth.clamp(260.0, 360.0);
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              _ConnectionHeader(
                connectionState: connectionState,
                onRetry: () =>
                    ref.read(remoteConnectionProvider.notifier).retry(),
              ),
              const SizedBox(height: 22),
              TopControls(onCommand: onCommand),
              const SizedBox(height: 28),
              Center(
                child: SizedBox.square(
                  dimension: dpadSize,
                  child: DpadWidget(onCommand: onCommand),
                ),
              ),
              const SizedBox(height: 28),
              VolumeControls(onCommand: onCommand),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RemoteButtonWidget(
                    label: 'Channel down',
                    icon: Icons.keyboard_arrow_down_rounded,
                    onPressed: () => onCommand(RemoteCommand.channelDown),
                  ),
                  RemoteButtonWidget(
                    label: 'Channel up',
                    icon: Icons.keyboard_arrow_up_rounded,
                    onPressed: () => onCommand(RemoteCommand.channelUp),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConnectionHeader extends StatelessWidget {
  const _ConnectionHeader({
    required this.connectionState,
    required this.onRetry,
  });

  final RemoteConnectionState connectionState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _StatusIndicator(connectionState: connectionState),
            const SizedBox(width: 12),
            Expanded(child: _StatusText(connectionState: connectionState)),
            _StatusAction(
              connectionState: connectionState,
              onRetry: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.connectionState});
  final RemoteConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    if (connectionState is RemoteConnecting) {
      return const SizedBox.square(
        dimension: 12,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: connectionState is RemoteConnected
            ? Theme.of(context).colorScheme.primary
            : Colors.white30,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.connectionState});
  final RemoteConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (connectionState) {
      RemoteConnected(:final device) => (device.name, null),
      RemoteConnecting() => ('Connecting...', null),
      RemoteDisconnected() => ('No TV connected', null),
      RemoteFailed(:final message, :final device) => (
          device?.name ?? 'Connection failed',
          message,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
      ],
    );
  }
}

class _StatusAction extends StatelessWidget {
  const _StatusAction({
    required this.connectionState,
    required this.onRetry,
  });

  final RemoteConnectionState connectionState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (connectionState is RemoteFailed) {
      return TextButton(onPressed: onRetry, child: const Text('Retry'));
    }
    final connected = connectionState is RemoteConnected;
    return Text(
      connected ? 'Connected' : 'Disconnected',
      style: TextStyle(
        color: connected
            ? Theme.of(context).colorScheme.primary
            : Colors.white54,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
```

- [ ] **Step 2: Run all Flutter tests to check nothing is broken**

```bash
flutter test
```

Expected: All tests pass. Fix any import errors before continuing.

- [ ] **Step 3: Commit**

```bash
git add lib/features/remote/presentation/remote_screen.dart
git commit -m "refactor: migrate RemoteScreen to RemoteConnectionNotifier"
```

---

### Task 5: Fix SavedTvsScreen direct channel instantiation

**Files:**
- Modify: `lib/features/saved_tvs/presentation/saved_tvs_screen.dart`

- [ ] **Step 1: Replace direct channel call with notifier**

In `saved_tvs_screen.dart`, find the `TvDeviceCard` `onTap` callback (currently line 87–89):

```dart
// Before
onTap: () async {
  await RemoteControlChannel().connectToTv(device);
  if (context.mounted) context.go('/remote', extra: device);
},
```

Replace with:

```dart
// After
onTap: () async {
  await ref.read(remoteConnectionProvider.notifier).connect(device);
  if (context.mounted) context.go('/remote');
},
```

Note: `extra: device` is removed because the notifier already holds the connection. `RemoteScreen` called with no extra will call `connect(null)`, which detects the already-connected state and returns immediately.

Also add the two missing imports at the top of the file:

```dart
import '../../remote/data/remote_connection_notifier.dart';
```

Remove the now-unused import:

```dart
import '../../remote/data/remote_control_channel.dart';
```

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/saved_tvs/presentation/saved_tvs_screen.dart
git commit -m "fix: use RemoteConnectionNotifier in SavedTvsScreen"
```

---

## Phase 2: Core Features

### Task 6: Text keycodes in proto and RemoteCommandMapper

**Files:**
- Modify: `android/app/src/main/proto/remotemessage.proto`
- Modify: `android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapper.kt`
- Modify: `android/app/src/test/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapperTest.kt`

- [ ] **Step 1: Write the failing Kotlin test**

Add a new `@Test` to `RemoteCommandMapperTest`:

```kotlin
@Test
fun mapsLowercaseLettersToKeyCodes() {
    assertEquals(RemoteKeyCode.KEYCODE_A, RemoteCommandMapper.toTextKeyCode('a'))
    assertEquals(RemoteKeyCode.KEYCODE_Z, RemoteCommandMapper.toTextKeyCode('z'))
}

@Test
fun mapsUppercaseLettersToLowercaseKeyCode() {
    assertEquals(RemoteKeyCode.KEYCODE_A, RemoteCommandMapper.toTextKeyCode('A'))
}

@Test
fun mapsDigitsToKeyCodes() {
    assertEquals(RemoteKeyCode.KEYCODE_0, RemoteCommandMapper.toTextKeyCode('0'))
    assertEquals(RemoteKeyCode.KEYCODE_9, RemoteCommandMapper.toTextKeyCode('9'))
}

@Test
fun mapsCommonPunctuationToKeyCodes() {
    assertEquals(RemoteKeyCode.KEYCODE_SPACE, RemoteCommandMapper.toTextKeyCode(' '))
    assertEquals(RemoteKeyCode.KEYCODE_ENTER, RemoteCommandMapper.toTextKeyCode('\n'))
    assertEquals(RemoteKeyCode.KEYCODE_DEL, RemoteCommandMapper.toTextKeyCode('\b'))
    assertEquals(RemoteKeyCode.KEYCODE_PERIOD, RemoteCommandMapper.toTextKeyCode('.'))
    assertEquals(RemoteKeyCode.KEYCODE_AT, RemoteCommandMapper.toTextKeyCode('@'))
}

@Test
fun returnsNullForUnsupportedCharacter() {
    assertNull(RemoteCommandMapper.toTextKeyCode('€'))
}
```

- [ ] **Step 2: Run Kotlin tests to verify they fail**

```bash
cd android && ./gradlew :app:testDebugUnitTest --tests "com.justremote.justremote.remote.protocol.RemoteCommandMapperTest" 2>&1 | tail -20
```

Expected: compile error — `KEYCODE_A`, `toTextKeyCode` not found.

- [ ] **Step 3: Add text and shift keycodes to remotemessage.proto**

In `android/app/src/main/proto/remotemessage.proto`, extend the `RemoteKeyCode` enum (add after the existing entries, before the closing `}`):

```protobuf
  // Digits
  KEYCODE_0 = 7;
  KEYCODE_1 = 8;
  KEYCODE_2 = 9;
  KEYCODE_3 = 10;
  KEYCODE_4 = 11;
  KEYCODE_5 = 12;
  KEYCODE_6 = 13;
  KEYCODE_7 = 14;
  KEYCODE_8 = 15;
  KEYCODE_9 = 16;

  // Letters (standard Android KeyEvent values)
  KEYCODE_A = 29;
  KEYCODE_B = 30;
  KEYCODE_C = 31;
  KEYCODE_D = 32;
  KEYCODE_E = 33;
  KEYCODE_F = 34;
  KEYCODE_G = 35;
  KEYCODE_H = 36;
  KEYCODE_I = 37;
  KEYCODE_J = 38;
  KEYCODE_K = 39;
  KEYCODE_L = 40;
  KEYCODE_M = 41;
  KEYCODE_N = 42;
  KEYCODE_O = 43;
  KEYCODE_P = 44;
  KEYCODE_Q = 45;
  KEYCODE_R = 46;
  KEYCODE_S = 47;
  KEYCODE_T = 48;
  KEYCODE_U = 49;
  KEYCODE_V = 50;
  KEYCODE_W = 51;
  KEYCODE_X = 52;
  KEYCODE_Y = 53;
  KEYCODE_Z = 54;

  // Punctuation and control
  KEYCODE_COMMA       = 55;
  KEYCODE_PERIOD      = 56;
  KEYCODE_SHIFT_LEFT  = 59;
  KEYCODE_SPACE       = 62;
  KEYCODE_ENTER       = 66;
  KEYCODE_DEL         = 67;
  KEYCODE_MINUS       = 69;
  KEYCODE_EQUALS      = 70;
  KEYCODE_AT          = 77;
```

- [ ] **Step 4: Add toTextKeyCode to RemoteCommandMapper**

In `RemoteCommandMapper.kt`, add after the existing `keyCodes` map and `toKeyCode`/`toKeyInjectMessage` functions:

```kotlin
private val textKeyCodes = mapOf(
    '0' to RemoteKeyCode.KEYCODE_0, '1' to RemoteKeyCode.KEYCODE_1,
    '2' to RemoteKeyCode.KEYCODE_2, '3' to RemoteKeyCode.KEYCODE_3,
    '4' to RemoteKeyCode.KEYCODE_4, '5' to RemoteKeyCode.KEYCODE_5,
    '6' to RemoteKeyCode.KEYCODE_6, '7' to RemoteKeyCode.KEYCODE_7,
    '8' to RemoteKeyCode.KEYCODE_8, '9' to RemoteKeyCode.KEYCODE_9,
    'a' to RemoteKeyCode.KEYCODE_A, 'b' to RemoteKeyCode.KEYCODE_B,
    'c' to RemoteKeyCode.KEYCODE_C, 'd' to RemoteKeyCode.KEYCODE_D,
    'e' to RemoteKeyCode.KEYCODE_E, 'f' to RemoteKeyCode.KEYCODE_F,
    'g' to RemoteKeyCode.KEYCODE_G, 'h' to RemoteKeyCode.KEYCODE_H,
    'i' to RemoteKeyCode.KEYCODE_I, 'j' to RemoteKeyCode.KEYCODE_J,
    'k' to RemoteKeyCode.KEYCODE_K, 'l' to RemoteKeyCode.KEYCODE_L,
    'm' to RemoteKeyCode.KEYCODE_M, 'n' to RemoteKeyCode.KEYCODE_N,
    'o' to RemoteKeyCode.KEYCODE_O, 'p' to RemoteKeyCode.KEYCODE_P,
    'q' to RemoteKeyCode.KEYCODE_Q, 'r' to RemoteKeyCode.KEYCODE_R,
    's' to RemoteKeyCode.KEYCODE_S, 't' to RemoteKeyCode.KEYCODE_T,
    'u' to RemoteKeyCode.KEYCODE_U, 'v' to RemoteKeyCode.KEYCODE_V,
    'w' to RemoteKeyCode.KEYCODE_W, 'x' to RemoteKeyCode.KEYCODE_X,
    'y' to RemoteKeyCode.KEYCODE_Y, 'z' to RemoteKeyCode.KEYCODE_Z,
    ' ' to RemoteKeyCode.KEYCODE_SPACE,
    '\n' to RemoteKeyCode.KEYCODE_ENTER,
    '\b' to RemoteKeyCode.KEYCODE_DEL,
    '.' to RemoteKeyCode.KEYCODE_PERIOD,
    ',' to RemoteKeyCode.KEYCODE_COMMA,
    '-' to RemoteKeyCode.KEYCODE_MINUS,
    '=' to RemoteKeyCode.KEYCODE_EQUALS,
    '@' to RemoteKeyCode.KEYCODE_AT,
)

fun toTextKeyCode(char: Char): RemoteKeyCode? {
    return if (char.isUpperCase()) textKeyCodes[char.lowercaseChar()]
    else textKeyCodes[char]
}
```

- [ ] **Step 5: Run Kotlin tests to verify they pass**

```bash
cd android && ./gradlew :app:testDebugUnitTest --tests "com.justremote.justremote.remote.protocol.RemoteCommandMapperTest" 2>&1 | tail -20
```

Expected: All tests pass (including pre-existing ones).

- [ ] **Step 6: Commit**

```bash
git add android/app/src/main/proto/remotemessage.proto \
        android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapper.kt \
        android/app/src/test/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapperTest.kt
git commit -m "feat: add text character keycodes to proto and RemoteCommandMapper"
```

---

### Task 7: sendTextInput through the Kotlin stack

**Files:**
- Modify: `android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteProtocolClient.kt`
- Modify: `android/app/src/main/kotlin/com/justremote/justremote/remote/TvCommandManager.kt`
- Modify: `android/app/src/main/kotlin/com/justremote/justremote/remote/TvRemotePlugin.kt`

- [ ] **Step 1: Add writeKeyInject helper and sendTextInput to RemoteConnection**

In `RemoteProtocolClient.kt`, inside the `RemoteConnection` class, add after the existing `sendCommand` method:

```kotlin
@Synchronized
fun sendTextInput(text: String): Boolean {
    check(!isClosed) { "Connection is closed" }
    for (char in text) {
        val keyCode = RemoteCommandMapper.toTextKeyCode(char) ?: continue
        if (char.isUpperCase()) writeKeyInject(RemoteKeyCode.KEYCODE_SHIFT_LEFT, RemoteDirection.START_LONG)
        writeKeyInject(keyCode, RemoteDirection.SHORT)
        if (char.isUpperCase()) writeKeyInject(RemoteKeyCode.KEYCODE_SHIFT_LEFT, RemoteDirection.END_LONG)
    }
    return true
}

private fun writeKeyInject(keyCode: RemoteKeyCode, direction: RemoteDirection) {
    val message = RemoteMessage.newBuilder()
        .setRemoteKeyInject(
            RemoteKeyInject.newBuilder()
                .setKeyCode(keyCode)
                .setDirection(direction)
        )
        .build()
    ProtobufFramer.writeDelimited(socket.outputStream, message.toByteArray())
}
```

Also add the new import at the top of the file if not already present:

```kotlin
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteKeyCode
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteDirection
```

(These are likely already imported — check and skip duplicates.)

- [ ] **Step 2: Add sendTextInput to TvCommandManager**

In `TvCommandManager.kt`, add after the existing `sendCommand` method:

```kotlin
fun sendTextInput(text: String): Map<String, Any> {
    Log.d(TAG, "sendTextInput length=${text.length} device=${connectedDevice?.name}")
    val activeConnection = connection
    if (activeConnection == null || activeConnection.isClosed) {
        return mapOf("success" to false, "message" to "Not connected")
    }
    return try {
        val success = runWithTimeout(COMMAND_TIMEOUT_SECONDS, "Text input timed out") {
            activeConnection.sendTextInput(text)
        }
        if (success) mapOf("success" to true)
        else mapOf("success" to false, "message" to "Text input failed")
    } catch (error: Throwable) {
        Log.w(TAG, "sendTextInput failed", error)
        mapOf("success" to false, "message" to error.cleanMessage("Text input failed"))
    }
}
```

- [ ] **Step 3: Route sendTextInput in TvRemotePlugin**

In `TvRemotePlugin.kt`, add `"sendTextInput"` to the when-clause in `onMethodCall` that routes to `executor.execute`:

```kotlin
// Find the existing when block and add "sendTextInput" to the list:
"scanForTvs",
"pairTv",
"connectToTv",
"disconnectTv",
"sendCommand",
"sendTextInput",   // add this line
"getConnectionStatus" -> executor.execute {
    handleRemoteMethod(call, result)
}
```

Then add the case to `handleRemoteMethod`:

```kotlin
"sendTextInput" -> {
    val text = call.argument<String>("text").orEmpty()
    result.success(commandManager.sendTextInput(text))
}
```

And add the failure response in `failureResponse`:

```kotlin
"sendTextInput" -> mapOf("success" to false, "message" to message)
```

- [ ] **Step 4: Run Kotlin build to verify no compile errors**

```bash
cd android && ./gradlew :app:compileDebugKotlin 2>&1 | tail -30
```

Expected: BUILD SUCCESSFUL.

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteProtocolClient.kt \
        android/app/src/main/kotlin/com/justremote/justremote/remote/TvCommandManager.kt \
        android/app/src/main/kotlin/com/justremote/justremote/remote/TvRemotePlugin.kt
git commit -m "feat: implement sendTextInput through Kotlin protocol stack"
```

---

### Task 8: KeyboardSheet widget

**Files:**
- Create: `lib/features/remote/presentation/widgets/keyboard_sheet.dart`
- Modify: `lib/features/remote/presentation/remote_screen.dart`

- [ ] **Step 1: Create KeyboardSheet**

```dart
// lib/features/remote/presentation/widgets/keyboard_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote_connection_notifier.dart';

class KeyboardSheet extends ConsumerStatefulWidget {
  const KeyboardSheet({super.key});

  @override
  ConsumerState<KeyboardSheet> createState() => _KeyboardSheetState();
}

class _KeyboardSheetState extends ConsumerState<KeyboardSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.isEmpty) return;
    ref.read(remoteConnectionProvider.notifier).sendTextInput(text);
    _controller.clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Type on TV',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: 'Enter text...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded),
                onPressed: _send,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire the Keyboard button into RemoteScreen**

In `remote_screen.dart`, add the import:

```dart
import 'widgets/keyboard_sheet.dart';
```

Replace the two-button channel row with a four-button row that includes Keyboard and Touchpad (Touchpad will be a placeholder for now — it gets its real implementation in Task 9):

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    RemoteButtonWidget(
      label: 'Channel down',
      icon: Icons.keyboard_arrow_down_rounded,
      onPressed: () => onCommand(RemoteCommand.channelDown),
    ),
    RemoteButtonWidget(
      label: 'Keyboard',
      icon: Icons.keyboard_rounded,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const KeyboardSheet(),
      ),
    ),
    RemoteButtonWidget(
      label: 'Touchpad',
      icon: Icons.touch_app_rounded,
      onPressed: () {}, // wired in Task 9
    ),
    RemoteButtonWidget(
      label: 'Channel up',
      icon: Icons.keyboard_arrow_up_rounded,
      onPressed: () => onCommand(RemoteCommand.channelUp),
    ),
  ],
),
```

- [ ] **Step 3: Run all Flutter tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/remote/presentation/widgets/keyboard_sheet.dart \
        lib/features/remote/presentation/remote_screen.dart
git commit -m "feat: add keyboard text input bottom sheet"
```

---

### Task 9: TouchpadSheet widget

**Files:**
- Create: `lib/features/remote/presentation/widgets/touchpad_sheet.dart`
- Modify: `lib/features/remote/presentation/remote_screen.dart`

- [ ] **Step 1: Create TouchpadSheet**

```dart
// lib/features/remote/presentation/widgets/touchpad_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote_connection_notifier.dart';
import '../../domain/remote_command.dart';

class TouchpadSheet extends ConsumerStatefulWidget {
  const TouchpadSheet({super.key});

  @override
  ConsumerState<TouchpadSheet> createState() => _TouchpadSheetState();
}

class _TouchpadSheetState extends ConsumerState<TouchpadSheet> {
  // Accumulated gesture distance before firing a D-pad command
  static const double _threshold = 24.0;
  double _accX = 0;
  double _accY = 0;

  void _onCommand(RemoteCommand command) {
    ref.read(remoteConnectionProvider.notifier).sendCommand(command);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _accX += details.delta.dx;
    _accY += details.delta.dy;

    if (_accX.abs() >= _threshold || _accY.abs() >= _threshold) {
      if (_accX.abs() > _accY.abs()) {
        _onCommand(_accX > 0 ? RemoteCommand.right : RemoteCommand.left);
      } else {
        _onCommand(_accY > 0 ? RemoteCommand.down : RemoteCommand.up);
      }
      _accX = 0;
      _accY = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: (_) {
                _accX = 0;
                _accY = 0;
              },
              onTap: () => _onCommand(RemoteCommand.select),
              onLongPress: () => _onCommand(RemoteCommand.back),
              child: Container(
                margin: const EdgeInsets.all(20),
                height: 260,
                decoration: BoxDecoration(
                  color: const Color(0xFF121722),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Center(
                  child: Text(
                    'Swipe to navigate\nTap to select • Hold for back',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire Touchpad button in RemoteScreen**

In `remote_screen.dart`, add the import:

```dart
import 'widgets/touchpad_sheet.dart';
```

Replace the `onPressed: () {}` for the Touchpad button with:

```dart
onPressed: () => showModalBottomSheet<void>(
  context: context,
  builder: (_) => const TouchpadSheet(),
),
```

- [ ] **Step 3: Run all Flutter tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/remote/presentation/widgets/touchpad_sheet.dart \
        lib/features/remote/presentation/remote_screen.dart
git commit -m "feat: add gesture touchpad bottom sheet"
```

---

### Task 10: Manual IP entry

**Files:**
- Create: `lib/features/tv_discovery/presentation/widgets/enter_ip_sheet.dart`
- Modify: `lib/features/tv_discovery/presentation/scan_tv_screen.dart`

- [ ] **Step 1: Create EnterIpSheet**

```dart
// lib/features/tv_discovery/presentation/widgets/enter_ip_sheet.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/tv_device.dart';

class EnterIpSheet extends StatefulWidget {
  const EnterIpSheet({super.key});

  @override
  State<EnterIpSheet> createState() => _EnterIpSheetState();
}

class _EnterIpSheetState extends State<EnterIpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '6466');

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  String? _validateIp(String? value) {
    if (value == null || value.trim().isEmpty) return 'IP address is required';
    final parts = value.trim().split('.');
    if (parts.length != 4) return 'Enter a valid IPv4 address';
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return 'Enter a valid IPv4 address';
    }
    return null;
  }

  String? _validatePort(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = int.tryParse(value.trim());
    if (n == null || n < 1 || n > 65535) return 'Port must be 1–65535';
    return null;
  }

  void _connect() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ip = _ipController.text.trim();
    final portText = _portController.text.trim();
    final port = portText.isEmpty ? 6466 : int.parse(portText);

    final device = TvDevice(
      id: 'manual_${ip}_$port',
      name: ip,
      host: ip,
      port: port,
      type: '_androidtvremote2._tcp',
    );
    Navigator.of(context).pop();
    context.push('/pairing', extra: device);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connect by IP',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ipController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'TV IP address',
                hintText: '192.168.1.x',
              ),
              validator: _validateIp,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _portController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _connect(),
              decoration: const InputDecoration(
                labelText: 'Port (optional)',
                hintText: '6466',
              ),
              validator: _validatePort,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _connect,
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add "Enter IP manually" button to ScanTvScreen**

In `scan_tv_screen.dart`, add the import:

```dart
import 'widgets/enter_ip_sheet.dart';
```

Add a `_showEnterIp` helper method to `_ScanTvScreenState`:

```dart
void _showEnterIp() {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const EnterIpSheet(),
  );
}
```

In the `EmptyState` for 'No TVs found', update the `action` to wrap both buttons in a `Column`:

```dart
action: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    PrimaryButton(
      label: 'Rescan',
      icon: Icons.refresh_rounded,
      onPressed: _rescan,
    ),
    const SizedBox(height: 10),
    TextButton.icon(
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: const Text('Enter IP manually'),
      onPressed: _showEnterIp,
    ),
  ],
),
```

Also add the "Enter IP manually" button below the Rescan button in the scan-results list footer. In the `itemBuilder`, the item at `index == devices.length` currently shows the Rescan button. Replace it with:

```dart
if (index == devices.length)
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          label: 'Rescan',
          icon: Icons.refresh_rounded,
          onPressed: _rescan,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Enter IP manually'),
          onPressed: _showEnterIp,
        ),
      ],
    ),
  );
```

- [ ] **Step 3: Run all Flutter tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/tv_discovery/presentation/widgets/enter_ip_sheet.dart \
        lib/features/tv_discovery/presentation/scan_tv_screen.dart
git commit -m "feat: add manual IP entry for TVs not found by mDNS"
```

---

## Phase 3: Advanced Features

### Task 11: Media transport controls

**Files:**
- Modify: `android/app/src/main/proto/remotemessage.proto`
- Modify: `android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapper.kt`
- Modify: `android/app/src/test/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapperTest.kt`
- Modify: `lib/features/remote/domain/remote_command.dart`
- Create: `lib/features/remote/presentation/widgets/media_controls.dart`

- [ ] **Step 1: Write the failing Kotlin test for media commands**

In `RemoteCommandMapperTest.kt`, add:

```kotlin
@Test
fun mapsMediaCommandsToKeyCodes() {
    val expected = mapOf(
        "playpause" to RemoteKeyCode.KEYCODE_MEDIA_PLAY_PAUSE,
        "mediaStop" to RemoteKeyCode.KEYCODE_MEDIA_STOP,
        "mediaNext" to RemoteKeyCode.KEYCODE_MEDIA_NEXT,
        "mediaPrevious" to RemoteKeyCode.KEYCODE_MEDIA_PREVIOUS,
        "rewind" to RemoteKeyCode.KEYCODE_MEDIA_REWIND,
        "fastForward" to RemoteKeyCode.KEYCODE_MEDIA_FAST_FORWARD,
    )
    expected.forEach { (command, keyCode) ->
        assertEquals(keyCode, RemoteCommandMapper.toKeyCode(command))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd android && ./gradlew :app:testDebugUnitTest --tests "com.justremote.justremote.remote.protocol.RemoteCommandMapperTest" 2>&1 | tail -20
```

Expected: compile error — `KEYCODE_MEDIA_PLAY_PAUSE` not found.

- [ ] **Step 3: Add media keycodes to remotemessage.proto**

In `android/app/src/main/proto/remotemessage.proto`, add inside `RemoteKeyCode` after the text keycodes added in Task 6:

```protobuf
  // Media transport
  KEYCODE_MEDIA_PLAY_PAUSE   = 85;
  KEYCODE_MEDIA_STOP         = 86;
  KEYCODE_MEDIA_NEXT         = 87;
  KEYCODE_MEDIA_PREVIOUS     = 88;
  KEYCODE_MEDIA_REWIND       = 89;
  KEYCODE_MEDIA_FAST_FORWARD = 90;
```

- [ ] **Step 4: Add media commands to RemoteCommandMapper**

In `RemoteCommandMapper.kt`, add the following entries to the existing `keyCodes` map:

```kotlin
"playpause"     to RemoteKeyCode.KEYCODE_MEDIA_PLAY_PAUSE,
"mediaStop"     to RemoteKeyCode.KEYCODE_MEDIA_STOP,
"mediaNext"     to RemoteKeyCode.KEYCODE_MEDIA_NEXT,
"mediaPrevious" to RemoteKeyCode.KEYCODE_MEDIA_PREVIOUS,
"rewind"        to RemoteKeyCode.KEYCODE_MEDIA_REWIND,
"fastForward"   to RemoteKeyCode.KEYCODE_MEDIA_FAST_FORWARD,
```

- [ ] **Step 5: Run Kotlin tests to verify they pass**

```bash
cd android && ./gradlew :app:testDebugUnitTest --tests "com.justremote.justremote.remote.protocol.RemoteCommandMapperTest" 2>&1 | tail -20
```

Expected: All tests pass.

- [ ] **Step 6: Add media commands to RemoteCommand enum**

In `lib/features/remote/domain/remote_command.dart`, add before the closing `;`:

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
  playpause('playpause'),
  mediaStop('mediaStop'),
  mediaNext('mediaNext'),
  mediaPrevious('mediaPrevious'),
  rewind('rewind'),
  fastForward('fastForward');

  const RemoteCommand(this.wireName);

  final String wireName;
}
```

- [ ] **Step 7: Create MediaControls widget**

```dart
// lib/features/remote/presentation/widgets/media_controls.dart
import 'package:flutter/material.dart';

import '../../domain/remote_command.dart';
import 'remote_button_widget.dart';

class MediaControls extends StatelessWidget {
  const MediaControls({required this.onCommand, super.key});

  final ValueChanged<RemoteCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RemoteButtonWidget(
          label: 'Previous',
          icon: Icons.skip_previous_rounded,
          onPressed: () => onCommand(RemoteCommand.mediaPrevious),
        ),
        RemoteButtonWidget(
          label: 'Rewind',
          icon: Icons.fast_rewind_rounded,
          onPressed: () => onCommand(RemoteCommand.rewind),
        ),
        RemoteButtonWidget(
          label: 'Play/Pause',
          icon: Icons.play_arrow_rounded,
          onPressed: () => onCommand(RemoteCommand.playpause),
        ),
        RemoteButtonWidget(
          label: 'Forward',
          icon: Icons.fast_forward_rounded,
          onPressed: () => onCommand(RemoteCommand.fastForward),
        ),
        RemoteButtonWidget(
          label: 'Next',
          icon: Icons.skip_next_rounded,
          onPressed: () => onCommand(RemoteCommand.mediaNext),
        ),
      ],
    );
  }
}
```

- [ ] **Step 8: Run all Flutter tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 9: Commit**

```bash
git add android/app/src/main/proto/remotemessage.proto \
        android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapper.kt \
        android/app/src/test/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapperTest.kt \
        lib/features/remote/domain/remote_command.dart \
        lib/features/remote/presentation/widgets/media_controls.dart
git commit -m "feat: add media transport controls"
```

---

### Task 12: Wire MediaControls and tablet layout into RemoteScreen

**Files:**
- Modify: `lib/features/remote/presentation/remote_screen.dart`

- [ ] **Step 1: Wire MediaControls into RemoteScreen**

Add the import to `remote_screen.dart`:

```dart
import 'widgets/media_controls.dart';
```

In the `ListView` children, add `MediaControls` between `VolumeControls` and the channel/keyboard row:

```dart
VolumeControls(onCommand: onCommand),
const SizedBox(height: 18),
MediaControls(onCommand: onCommand),
const SizedBox(height: 18),
Row( /* channel down / keyboard / touchpad / channel up */ ),
```

- [ ] **Step 2: Add tablet two-column layout**

Replace the entire `body:` of `AppScaffold` in `RemoteScreen.build` with:

```dart
body: LayoutBuilder(
  builder: (context, constraints) {
    final onCommand = (RemoteCommand cmd) =>
        ref.read(remoteConnectionProvider.notifier).sendCommand(cmd);
    if (constraints.maxWidth >= 600) {
      return _TabletLayout(
        connectionState: connectionState,
        onCommand: onCommand,
        onRetry: () => ref.read(remoteConnectionProvider.notifier).retry(),
      );
    }
    return _PhoneLayout(
      connectionState: connectionState,
      onCommand: onCommand,
      onRetry: () => ref.read(remoteConnectionProvider.notifier).retry(),
    );
  },
),
```

Add the two private layout widgets at the bottom of `remote_screen.dart` (outside of the `_RemoteScreenState` class):

```dart
class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({
    required this.connectionState,
    required this.onCommand,
    required this.onRetry,
  });

  final RemoteConnectionState connectionState;
  final ValueChanged<RemoteCommand> onCommand;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpadSize = constraints.maxWidth.clamp(260.0, 360.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: _remoteControls(
            context: context,
            connectionState: connectionState,
            onCommand: onCommand,
            onRetry: onRetry,
            dpadSize: dpadSize,
          ),
        );
      },
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({
    required this.connectionState,
    required this.onCommand,
    required this.onRetry,
  });

  final RemoteConnectionState connectionState;
  final ValueChanged<RemoteCommand> onCommand;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dpadSize = constraints.maxWidth.clamp(260.0, 360.0);
              return ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 12, 28),
                children: [
                  _ConnectionHeader(
                    connectionState: connectionState,
                    onRetry: onRetry,
                  ),
                  const SizedBox(height: 22),
                  TopControls(onCommand: onCommand),
                  const SizedBox(height: 28),
                  Center(
                    child: SizedBox.square(
                      dimension: dpadSize,
                      child: DpadWidget(onCommand: onCommand),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 22, 28),
            children: [
              VolumeControls(onCommand: onCommand),
              const SizedBox(height: 18),
              MediaControls(onCommand: onCommand),
              const SizedBox(height: 18),
              _ChannelAndInputRow(onCommand: onCommand),
            ],
          ),
        ),
      ],
    );
  }
}
```

Extract the repeated row widget:

```dart
class _ChannelAndInputRow extends StatelessWidget {
  const _ChannelAndInputRow({required this.onCommand});
  final ValueChanged<RemoteCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RemoteButtonWidget(
          label: 'Channel down',
          icon: Icons.keyboard_arrow_down_rounded,
          onPressed: () => onCommand(RemoteCommand.channelDown),
        ),
        RemoteButtonWidget(
          label: 'Keyboard',
          icon: Icons.keyboard_rounded,
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const KeyboardSheet(),
          ),
        ),
        RemoteButtonWidget(
          label: 'Touchpad',
          icon: Icons.touch_app_rounded,
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (_) => const TouchpadSheet(),
          ),
        ),
        RemoteButtonWidget(
          label: 'Channel up',
          icon: Icons.keyboard_arrow_up_rounded,
          onPressed: () => onCommand(RemoteCommand.channelUp),
        ),
      ],
    );
  }
}
```

Update `_PhoneLayout._remoteControls` to use `_ChannelAndInputRow` and `MediaControls` consistently with `_TabletLayout`. The `_remoteControls` helper function returns the list of widgets used in both layouts (connection header, top controls, dpad, volume, media, channel row). Replace the entire existing `ListView` children in `_PhoneLayout` with:

```dart
ListView(
  padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
  children: [
    _ConnectionHeader(connectionState: connectionState, onRetry: onRetry),
    const SizedBox(height: 22),
    TopControls(onCommand: onCommand),
    const SizedBox(height: 28),
    Center(
      child: SizedBox.square(
        dimension: dpadSize,
        child: DpadWidget(onCommand: onCommand),
      ),
    ),
    const SizedBox(height: 28),
    VolumeControls(onCommand: onCommand),
    const SizedBox(height: 18),
    MediaControls(onCommand: onCommand),
    const SizedBox(height: 18),
    _ChannelAndInputRow(onCommand: onCommand),
  ],
),
```

Also remove the duplicated inline `Row` for keyboard/touchpad/channel buttons that existed in `_RemoteScreenState.build` — it's now fully handled by `_PhoneLayout` and `_TabletLayout` through `_ChannelAndInputRow`.

Clean up `_RemoteScreenState.build` to just:

```dart
@override
Widget build(BuildContext context) {
  final connectionState = ref.watch(remoteConnectionProvider);

  return AppScaffold(
    title: 'Remote',
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
    body: LayoutBuilder(
      builder: (context, constraints) {
        final onCommand = (RemoteCommand cmd) =>
            ref.read(remoteConnectionProvider.notifier).sendCommand(cmd);
        final onRetry =
            () => ref.read(remoteConnectionProvider.notifier).retry();
        if (constraints.maxWidth >= 600) {
          return _TabletLayout(
            connectionState: connectionState,
            onCommand: onCommand,
            onRetry: onRetry,
          );
        }
        return _PhoneLayout(
          connectionState: connectionState,
          onCommand: onCommand,
          onRetry: onRetry,
        );
      },
    ),
  );
}
```

- [ ] **Step 3: Run all Flutter tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/remote/presentation/remote_screen.dart
git commit -m "feat: add media controls and tablet two-column layout to remote screen"
```

---

### Task 13: RemoteConnectionService and binder

**Files:**
- Create: `android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionServiceBinder.kt`
- Create: `android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionService.kt`

- [ ] **Step 1: Create RemoteConnectionServiceBinder**

```kotlin
// android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionServiceBinder.kt
package com.justremote.justremote.remote

import android.os.Binder
import com.justremote.justremote.remote.models.NativeTvDevice

class RemoteConnectionServiceBinder(
    private val service: RemoteConnectionService
) : Binder() {

    fun connectToTv(device: NativeTvDevice): Map<String, Any> =
        service.commandManager.connectToTv(device)

    fun disconnectTv(): Map<String, Any> =
        service.commandManager.disconnectTv()

    fun sendCommand(command: String): Map<String, Any> =
        service.commandManager.sendCommand(command)

    fun sendTextInput(text: String): Map<String, Any> =
        service.commandManager.sendTextInput(text)

    fun getConnectionStatus(): Map<String, Any?> =
        service.commandManager.getConnectionStatus()
}
```

- [ ] **Step 2: Create RemoteConnectionService**

```kotlin
// android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionService.kt
package com.justremote.justremote.remote

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.justremote.justremote.remote.protocol.PairingProtocolClient
import com.justremote.justremote.remote.protocol.RemoteProtocolClient
import com.justremote.justremote.remote.security.PairingCredentialStore
import com.justremote.justremote.remote.security.TlsSocketFactory

class RemoteConnectionService : Service() {
    internal lateinit var commandManager: TvCommandManager
        private set

    private val binder by lazy { RemoteConnectionServiceBinder(this) }

    override fun onCreate() {
        super.onCreate()
        val credentialStore = PairingCredentialStore(applicationContext)
        val tlsSocketFactory = TlsSocketFactory(credentialStore)
        commandManager = TvCommandManager(
            RemoteProtocolClient(credentialStore, tlsSocketFactory)
        )
        ensureNotificationChannel()
        Log.d(TAG, "RemoteConnectionService created")
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int =
        START_NOT_STICKY

    fun showConnectedNotification(deviceName: String) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("JustRemote")
            .setContentText("Connected to $deviceName")
            .setOngoing(true)
            .build()
        startForeground(NOTIFICATION_ID, notification)
    }

    fun hideNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    override fun onDestroy() {
        commandManager.dispose()
        super.onDestroy()
        Log.d(TAG, "RemoteConnectionService destroyed")
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "TV Connection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows while connected to an Android TV"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private companion object {
        const val TAG = "RemoteConnectionService"
        const val CHANNEL_ID = "justremote_connection"
        const val NOTIFICATION_ID = 1001
    }
}
```

- [ ] **Step 3: Build to verify no compile errors**

```bash
cd android && ./gradlew :app:compileDebugKotlin 2>&1 | tail -20
```

Expected: BUILD SUCCESSFUL.

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionService.kt \
        android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionServiceBinder.kt
git commit -m "feat: add RemoteConnectionService Android foreground service"
```

---

### Task 14: Wire service into TvRemotePlugin and update AndroidManifest

**Files:**
- Modify: `android/app/src/main/kotlin/com/justremote/justremote/remote/TvRemotePlugin.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Update TvRemotePlugin to bind the service**

Replace the entire `TvRemotePlugin.kt` with:

```kotlin
package com.justremote.justremote.remote

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.util.Log
import com.justremote.justremote.remote.models.NativeTvDevice
import com.justremote.justremote.remote.protocol.PairingProtocolClient
import com.justremote.justremote.remote.protocol.RemoteProtocolClient
import com.justremote.justremote.remote.security.PairingCredentialStore
import com.justremote.justremote.remote.security.TlsSocketFactory
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class TvRemotePlugin(context: Context) : MethodChannel.MethodCallHandler {
    private val appContext = context.applicationContext
    private val credentialStore = PairingCredentialStore(appContext)
    private val tlsSocketFactory = TlsSocketFactory(credentialStore)
    private val discoveryManager = TvDiscoveryManager(appContext)
    private val pairingManager = TvPairingManager(
        PairingProtocolClient(credentialStore, tlsSocketFactory)
    )
    // Fallback manager used before service is bound
    private val localCommandManager = TvCommandManager(
        RemoteProtocolClient(credentialStore, tlsSocketFactory)
    )
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private var channel: MethodChannel? = null
    private var serviceBinder: RemoteConnectionServiceBinder? = null

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, binder: IBinder) {
            serviceBinder = binder as RemoteConnectionServiceBinder
            Log.d(TAG, "RemoteConnectionService bound")
        }
        override fun onServiceDisconnected(name: ComponentName) {
            serviceBinder = null
            Log.w(TAG, "RemoteConnectionService disconnected")
        }
    }

    fun register(binaryMessenger: BinaryMessenger) {
        val intent = Intent(appContext, RemoteConnectionService::class.java)
        appContext.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)

        channel = MethodChannel(binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "MethodChannel call received: ${call.method}")
        when (call.method) {
            "scanForTvs",
            "pairTv",
            "connectToTv",
            "disconnectTv",
            "sendCommand",
            "sendTextInput",
            "getConnectionStatus" -> executor.execute {
                handleRemoteMethod(call, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleRemoteMethod(call: MethodCall, result: MethodChannel.Result) {
        val binder = serviceBinder
        try {
            when (call.method) {
                "scanForTvs" -> {
                    result.success(discoveryManager.scanForTvs().map { it.toMap() })
                }
                "pairTv" -> {
                    val args = call.argumentsMap()
                    val device = NativeTvDevice.fromArguments(args)
                    val pairingCode = args["pairingCode"] as? String ?: ""
                    result.success(pairingManager.pairTv(device, pairingCode).toMap())
                }
                "connectToTv" -> {
                    val device = NativeTvDevice.fromArguments(call.argumentsMap())
                    val response = if (binder != null) binder.connectToTv(device)
                                   else localCommandManager.connectToTv(device)
                    result.success(response)
                }
                "disconnectTv" -> {
                    val response = if (binder != null) binder.disconnectTv()
                                   else localCommandManager.disconnectTv()
                    result.success(response)
                }
                "sendCommand" -> {
                    val command = call.argument<String>("command").orEmpty()
                    val response = if (binder != null) binder.sendCommand(command)
                                   else localCommandManager.sendCommand(command)
                    result.success(response)
                }
                "sendTextInput" -> {
                    val text = call.argument<String>("text").orEmpty()
                    val response = if (binder != null) binder.sendTextInput(text)
                                   else localCommandManager.sendTextInput(text)
                    result.success(response)
                }
                "getConnectionStatus" -> {
                    val response = if (binder != null) binder.getConnectionStatus()
                                   else localCommandManager.getConnectionStatus()
                    result.success(response)
                }
            }
        } catch (error: Throwable) {
            Log.w(TAG, "MethodChannel call failed: ${call.method}", error)
            result.success(call.failureResponse(error.cleanMessage("Operation failed")))
        }
    }

    fun dispose() {
        discoveryManager.dispose()
        pairingManager.dispose()
        if (serviceBinder == null) localCommandManager.dispose()
        executor.shutdownNow()
        channel?.setMethodCallHandler(null)
        channel = null
        try {
            appContext.unbindService(serviceConnection)
        } catch (_: IllegalArgumentException) {
            // service was never bound
        }
    }

    private fun MethodCall.argumentsMap(): Map<*, *> =
        arguments as? Map<*, *> ?: emptyMap<Any, Any>()

    private fun MethodCall.failureResponse(message: String): Any = when (method) {
        "scanForTvs" -> emptyList<Map<String, Any>>()
        "pairTv", "connectToTv", "disconnectTv" -> mapOf("success" to false, "message" to message)
        "sendCommand", "sendTextInput" -> mapOf("success" to false, "message" to message)
        "getConnectionStatus" -> mapOf("connected" to false, "deviceName" to null)
        else -> mapOf("success" to false, "message" to message)
    }

    private fun Throwable.cleanMessage(fallback: String): String =
        message?.takeIf { it.isNotBlank() } ?: fallback

    private companion object {
        const val TAG = "TvRemotePlugin"
        const val CHANNEL_NAME = "com.justremote.tv_remote"
    }
}
```

- [ ] **Step 2: Update AndroidManifest.xml**

In `android/app/src/main/AndroidManifest.xml`, add the permissions inside `<manifest>` before `<application>`:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />
```

And inside `<application>`, add the service declaration before the closing `</application>`:

```xml
<service
    android:name=".remote.RemoteConnectionService"
    android:foregroundServiceType="connectedDevice"
    android:exported="false" />
```

- [ ] **Step 3: Build to verify no compile errors**

```bash
cd android && ./gradlew :app:compileDebugKotlin 2>&1 | tail -20
```

Expected: BUILD SUCCESSFUL.

- [ ] **Step 4: Run all Kotlin tests to confirm nothing regressed**

```bash
cd android && ./gradlew :app:testDebugUnitTest 2>&1 | tail -20
```

Expected: All tests pass.

- [ ] **Step 5: Run all Flutter tests**

```bash
cd .. && flutter test
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add android/app/src/main/kotlin/com/justremote/justremote/remote/TvRemotePlugin.kt \
        android/app/src/main/AndroidManifest.xml
git commit -m "feat: bind RemoteConnectionService in TvRemotePlugin for background connection persistence"
```

---

## Self-Review Checklist

After writing this plan, verified against the spec:

- [x] **RemoteConnectionState sealed class** — Task 1
- [x] **RemoteControlChannel provider + sendTextInput** — Task 2
- [x] **RemoteConnectionNotifier** — Task 3
- [x] **RemoteScreen refactor (haptics, retry, remove placeholders)** — Task 4
- [x] **SavedTvsScreen fix** — Task 5
- [x] **Text keycodes in proto + toTextKeyCode** — Task 6
- [x] **sendTextInput through Kotlin stack** — Task 7
- [x] **KeyboardSheet** — Task 8
- [x] **TouchpadSheet** — Task 9
- [x] **Manual IP entry** — Task 10
- [x] **Media transport controls (proto + mapper + RemoteCommand + widget)** — Task 11
- [x] **MediaControls wired + tablet layout** — Task 12
- [x] **RemoteConnectionService + binder** — Task 13
- [x] **TvRemotePlugin service binding + AndroidManifest** — Task 14
