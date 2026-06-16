# JustRemote Improvements — Design Spec

**Date:** 2026-06-08
**Scope:** Code quality (Phase 1), core features (Phase 2), advanced features (Phase 3)

---

## Overview

Three phases of work, executed sequentially so each phase builds on a clean foundation.

- **Phase 1 — Foundation:** Move connection state into Riverpod, remove debug artifacts, add retry UI, fix direct channel instantiation in two screens.
- **Phase 2 — Core Features:** Keyboard/text input, touchpad mode, manual IP entry.
- **Phase 3 — Advanced Features:** Background Android service for persistent connections, media transport controls, tablet two-column layout.

---

## Phase 1: Architecture & Code Quality

### 1.1 RemoteConnectionState (new sealed class)

File: `lib/features/remote/domain/remote_connection_state.dart`

```
sealed class RemoteConnectionState
  RemoteDisconnected
  RemoteConnecting
  RemoteConnected(TvDevice device)
  RemoteFailed(String message, TvDevice? device)  // device kept for retry
```

`RemoteConnected` and `RemoteFailed` carry their payload as constructor fields. `RemoteFailed` keeps the last attempted device so retry can re-use it without the caller tracking it.

### 1.2 RemoteConnectionNotifier (new Riverpod notifier)

File: `lib/features/remote/data/remote_connection_notifier.dart`

A `Notifier<RemoteConnectionState>` (not `AsyncNotifier` — state transitions are explicit, not future-based). Lives at app scope with no `.autoDispose` so the connection survives navigation.

`build()` returns `const RemoteDisconnected()` as the initial state. `ref.read(remoteControlChannelProvider)` is called inside each method that needs the channel (not in `build()`).

Public API:
- `connect(TvDevice? device)` — async; transitions `disconnected → connecting → connected | failed`. If `device` is null and the channel reports an existing connection, transitions to `connected` with the retrieved device name. If `device` is null and there is no existing connection, transitions to `disconnected`.
- `sendCommand(RemoteCommand command)` — calls `RemoteControlChannel.sendCommand`; triggers `HapticFeedback.lightImpact()` before the call regardless of outcome. No state change on success; transitions to `failed` on `AppException`.
- `sendTextInput(String text)` — calls `RemoteControlChannel.sendTextInput`; triggers haptic feedback.
- `retry()` — re-calls `connect()` with the device from `RemoteFailed.device`.
- `disconnect()` — calls `RemoteControlChannel.disconnectTv`, transitions to `disconnected`.

Provider declaration:
```dart
final remoteConnectionProvider =
    NotifierProvider<RemoteConnectionNotifier, RemoteConnectionState>(
  RemoteConnectionNotifier.new,
);
```

### 1.3 RemoteControlChannel — expose as provider

File: `lib/features/remote/data/remote_control_channel.dart`

Add at the bottom:
```dart
final remoteControlChannelProvider = Provider<RemoteControlChannel>(
  (_) => RemoteControlChannel(),
);
```

`RemoteConnectionNotifier`'s methods call `ref.read(remoteControlChannelProvider)` to obtain the channel. All existing channel method signatures are unchanged.

Add one new method to `RemoteControlChannel`:
```dart
Future<bool> sendTextInput(String text)
```
Calls method channel `sendTextInput` with `{'text': text}`.

### 1.4 RemoteScreen refactor

`RemoteScreen` becomes a `ConsumerStatefulWidget`. Its `initState` calls:
```dart
Future.microtask(() =>
  ref.read(remoteConnectionProvider.notifier).connect(widget.device));
```

All local fields (`_connected`, `_deviceName`, `_lastMessage`) are removed. The build method reads `ref.watch(remoteConnectionProvider)` and pattern-matches on the state to render the connection header.

- `RemoteConnected(device)` → green dot, device name, "Connected"
- `RemoteConnecting` → spinner in the header
- `RemoteDisconnected` → grey dot, "No TV connected"
- `RemoteFailed(msg, _)` → red dot, error message, retry button

`_send(RemoteCommand)` replaced by `ref.read(remoteConnectionProvider.notifier).sendCommand(command)`.

The placeholder Keyboard and Touchpad `RemoteButtonWidget`s in the bottom row are **removed** now and replaced with real implementations in Phase 2.

`_lastMessage` debug text block removed entirely. Haptic feedback is emitted by the notifier.

### 1.5 SavedTvsScreen fix

File: `lib/features/saved_tvs/presentation/saved_tvs_screen.dart`

Line 88 currently calls `RemoteControlChannel().connectToTv(device)` directly. Replace with:
```dart
await ref.read(remoteConnectionProvider.notifier).connect(device);
```

`SavedTvsScreen` already extends `ConsumerWidget`, so `ref` is available.

### 1.6 Retry UI

When `remoteConnectionProvider` is in the `RemoteFailed` state, the `_ConnectionHeader` widget renders a "Retry" `TextButton` next to the status text. Tapping it calls `ref.read(remoteConnectionProvider.notifier).retry()`. No separate screen or dialog needed.

---

## Phase 2: Core Features

### 2.1 Keyboard / Text Input

**Protocol constraint:** `remotemessage.proto` defines only a small set of keycodes (navigation, volume, power). To send text, we need letter and digit keycodes added to the proto enum.

**Keycodes to add to proto:**

```protobuf
// Digits
KEYCODE_0 = 7;
KEYCODE_1 = 8;
// ... through 9 = 16

// Letters (standard Android values)
KEYCODE_A = 29;
KEYCODE_B = 30;
// ... through Z = 54

// Common
KEYCODE_SPACE    = 62;
KEYCODE_ENTER    = 66;
KEYCODE_DEL      = 67;  // backspace
KEYCODE_PERIOD   = 56;
KEYCODE_COMMA    = 55;
KEYCODE_MINUS    = 69;
KEYCODE_EQUALS   = 70;
KEYCODE_AT       = 77;
```

**Kotlin — `RemoteConnection`:**

Add `sendTextInput(text: String): Boolean`. Iterates each character, maps it to a `RemoteKeyCode` via `RemoteCommandMapper.toTextKeyCode(char)`, and sends a `SHORT` `RemoteKeyInject` per character. Returns `false` if any character is unmappable (skips it, continues). Uppercase letters are sent by injecting `KEYCODE_SHIFT_LEFT` in `START_LONG` before the letter and `END_LONG` after. Numbers and lowercase require no modifier.

Add `toTextKeyCode(char: Char): RemoteKeyCode?` to `RemoteCommandMapper`.

**Kotlin — `TvCommandManager`:**

Add `sendTextInput(text: String): Map<String, Any>` delegating to `connection.sendTextInput(text)`, wrapped in the same timeout/error pattern as `sendCommand`.

**Kotlin — `TvRemotePlugin`:**

Route `sendTextInput` method call: extract `text: String` from args, call `commandManager.sendTextInput(text)`, return result.

**Dart — `RemoteControlChannel`:**

`sendTextInput(String text)` — calls `'sendTextInput'` on the method channel with `{'text': text}`.

**Dart — `RemoteConnectionNotifier`:**

`sendTextInput(String text)` calls the channel, triggers haptic feedback.

**Dart — `KeyboardSheet`:**

File: `lib/features/remote/presentation/widgets/keyboard_sheet.dart`

A `StatefulWidget` shown via `showModalBottomSheet`. Contains:
- A `TextField` with `autofocus: true`, `textInputAction: TextInputAction.send`, `onSubmitted` calls notifier `sendTextInput` and pops.
- A "Send" `IconButton` in the `suffixIcon`.
- The bottom sheet is `isScrollControlled: true` so it resizes above the software keyboard.

Keyboard button in the remote screen (Phase 2 bottom row) shows this sheet.

### 2.2 Touchpad Mode

**Protocol constraint:** `remotemessage.proto` has no `RemoteMouseEvent`. Touchpad is implemented as gesture-to-D-pad translation — no proto changes required.

**Dart — `TouchpadSheet`:**

File: `lib/features/remote/presentation/widgets/touchpad_sheet.dart`

A `StatefulWidget` shown via `showModalBottomSheet` with a tall drag handle. The body is a `GestureDetector` covering the available space with a dark rounded surface.

Gesture handling:
- `onPanUpdate`: accumulates `delta.dx` and `delta.dy`. When accumulated distance exceeds a threshold (24 logical pixels), fires the appropriate D-pad command (`left`/`right`/`up`/`down`) and resets the accumulator. This gives smooth repeated D-pad events as the user drags.
- `onTap`: fires `RemoteCommand.select`.
- `onLongPress`: fires `RemoteCommand.back`.

A small legend at the bottom of the sheet: "Swipe to navigate • Tap to select • Hold for back".

Touchpad button in the remote screen (Phase 2 bottom row) shows this sheet.

### 2.3 Manual IP Entry

**Motivation:** mDNS/NSD discovery fails on many home networks (AP isolation, mixed-band routers). Users need a fallback.

**Dart — `EnterIpSheet`:**

File: `lib/features/tv_discovery/presentation/widgets/enter_ip_sheet.dart`

A `StatefulWidget` shown via `showModalBottomSheet`. Contains:
- `TextField` for IP address (keyboard type `TextInputType.number` with decimal), required.
- `TextField` for port, optional, defaults to `6466` (the `AndroidTvPorts.DEFAULT_REMOTE_PORT`).
- A "Connect" button.

Validation: IP must match `r'^(\d{1,3}\.){3}\d{1,3}$'` and each octet must be 0–255. Port must be 1–65535.

On confirm: creates:
```dart
TvDevice(
  id: 'manual_${ip}_$port',
  name: ip,
  host: ip,
  port: port,
  type: 'manual',
)
```
Pops the sheet and calls `context.push('/pairing', extra: device)`.

**`ScanTvScreen` change:**

In the empty-state widget (`No TVs found`), add a secondary `TextButton` below the Rescan button: "Enter IP manually". Also add it as a secondary action in the scan-results list footer (below the Rescan button) so it is reachable even when some TVs were found but not the target one.

---

## Phase 3: Advanced Features

### 3.1 Background Connection Service

**Motivation:** The `TvCommandManager` and its `RemoteConnection` currently live inside `TvRemotePlugin`, which is tied to the Flutter engine lifecycle. When the screen goes to background on some devices, the engine may pause and the TLS socket drops. An Android foreground service holds the connection independently.

**Architecture:**

New file: `android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionService.kt`

An `android.app.Service` that:
- Holds a `TvCommandManager` instance.
- Exposes a `Binder` with methods: `connectToTv`, `disconnectTv`, `sendCommand`, `sendTextInput`, `getConnectionStatus`.
- When connected, calls `startForeground(NOTIFICATION_ID, notification)` showing "JustRemote — Connected to [TV name]" with a disconnect action.
- When disconnected, calls `stopForeground(true)`.

New file: `android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionServiceBinder.kt`

`Binder` subclass that delegates to the service's `TvCommandManager`.

**`TvRemotePlugin` change:**

On plugin registration, binds to `RemoteConnectionService` using `context.bindService`. Once bound, all `connectToTv`, `disconnectTv`, `sendCommand`, `sendTextInput`, `getConnectionStatus` calls route through the binder instead of a locally-owned `TvCommandManager`. Before the binder is available (race on startup), calls fall back to a local `TvCommandManager` (same behaviour as today).

**`AndroidManifest.xml` additions:**
- `<service android:name=".remote.RemoteConnectionService" android:foregroundServiceType="connectedDevice" />`
- `<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />`
- `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />` (API 34+)

**Dart side:** No changes. The method channel interface is unchanged.

### 3.2 Media Transport Controls

**Motivation:** Play/pause, rewind, fast-forward are the most-used buttons after navigation. They require only adding keycodes to the proto — no structural changes.

**Keycodes to add to proto:**
```protobuf
KEYCODE_MEDIA_PLAY_PAUSE    = 85;
KEYCODE_MEDIA_STOP          = 86;
KEYCODE_MEDIA_NEXT          = 87;
KEYCODE_MEDIA_PREVIOUS      = 88;
KEYCODE_MEDIA_REWIND        = 89;
KEYCODE_MEDIA_FAST_FORWARD  = 90;
```

**Dart — `RemoteCommand` enum additions:**
```dart
playpause('playpause'),
mediaStop('mediaStop'),
mediaNext('mediaNext'),
mediaPrevious('mediaPrevious'),
rewind('rewind'),
fastForward('fastForward'),
```

**Kotlin — `RemoteCommandMapper` additions:**

Map the new wire names to the new keycodes.

**Dart — `MediaControls` widget:**

File: `lib/features/remote/presentation/widgets/media_controls.dart`

A `StatelessWidget` rendered as a `Row` between `VolumeControls` and the keyboard/touchpad row in `RemoteScreen`. Contains: previous, rewind, play/pause, fast-forward, next. Uses `RemoteButtonWidget`.

### 3.3 Tablet Layout

**Breakpoint:** `constraints.maxWidth >= 600` (matches Material's medium-screen breakpoint).

**`RemoteScreen` layout change:**

Wrap the existing `ListView` builder in a `LayoutBuilder`. When width ≥ 600, render a `Row` with two columns instead of a single scroll list:

- **Left column (flex 1):** Connection header → `TopControls` → `DpadWidget` sized using the left column's available width, clamped to 260–360 (same logic as the existing single-column layout).
- **Right column (flex 1):** `VolumeControls` → `MediaControls` → channel controls row → keyboard/touchpad row.

When width < 600, existing single-column `ListView` is used unchanged.

The two-column layout does not scroll; both columns fit on screen for typical tablet sizes. For very small tablets (< 600dp), the existing layout applies.

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/features/remote/domain/remote_connection_state.dart` | Sealed state class |
| `lib/features/remote/data/remote_connection_notifier.dart` | Riverpod notifier |
| `lib/features/remote/presentation/widgets/keyboard_sheet.dart` | Text input bottom sheet |
| `lib/features/remote/presentation/widgets/touchpad_sheet.dart` | Gesture touchpad bottom sheet |
| `lib/features/remote/presentation/widgets/media_controls.dart` | Media transport controls row |
| `lib/features/tv_discovery/presentation/widgets/enter_ip_sheet.dart` | Manual IP entry bottom sheet |
| `android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionService.kt` | Android foreground service |
| `android/app/src/main/kotlin/com/justremote/justremote/remote/RemoteConnectionServiceBinder.kt` | Service binder |

## Files Modified

| File | Change |
|------|--------|
| `lib/features/remote/data/remote_control_channel.dart` | Add `remoteControlChannelProvider`, add `sendTextInput` |
| `lib/features/remote/presentation/remote_screen.dart` | Full refactor to use notifier; tablet layout |
| `lib/features/saved_tvs/presentation/saved_tvs_screen.dart` | Use notifier instead of direct channel |
| `lib/features/tv_discovery/presentation/scan_tv_screen.dart` | Add "Enter IP manually" button |
| `lib/features/remote/domain/remote_command.dart` | Add media transport commands |
| `android/app/src/main/proto/remotemessage.proto` | Add text and media keycodes |
| `android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteCommandMapper.kt` | Map new commands and text chars |
| `android/app/src/main/kotlin/com/justremote/justremote/remote/protocol/RemoteProtocolClient.kt` | Add `sendTextInput` to `RemoteConnection` |
| `android/app/src/main/kotlin/com/justremote/justremote/remote/TvCommandManager.kt` | Add `sendTextInput` |
| `android/app/src/main/kotlin/com/justremote/justremote/remote/TvRemotePlugin.kt` | Route `sendTextInput`; bind to service |
| `android/app/src/main/AndroidManifest.xml` | Foreground service declaration and permissions |

---

## Constraints and Non-Decisions

- **Text input** sends characters one-by-one as `RemoteKeyInject`. There is no `RemoteTextInput` message type in this proto. Special characters not in the keycode map are silently skipped.
- **Touchpad** uses gesture-to-D-pad translation. Real mouse cursor control (`RemoteMouseEvent`) is not in the proto and is not implemented here.
- **App launcher** is out of scope. There is no standard way to enumerate or launch TV apps via the Android TV Remote Protocol v2 without ADB (which requires developer mode). The `Home` button in `TopControls` already navigates to the TV launcher.
- **iOS** is not in scope for this spec. The Dart layer is fully reusable; only the Kotlin plugin would need a Swift equivalent.
