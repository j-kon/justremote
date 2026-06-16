# Android TV / Google TV Discovery Implementation

Date: 2026-06-08

## Summary

JustRemote now uses real Android local network discovery for Android TV / Google TV devices instead of relying on mocked scan results.

The implementation keeps the Flutter UI unchanged and preserves the existing `MethodChannel` response shape:

```json
[
  {
    "id": "tv_living_room_tv_192_168_1_20_6466",
    "name": "Living Room TV",
    "host": "192.168.1.20",
    "port": 6466,
    "type": "android_tv"
  }
]
```

If discovery fails, Android NSD is unavailable, permissions are missing, or no Android TV service is found, the native implementation returns an empty list instead of crashing.

## Files Changed

### `android/app/src/main/kotlin/com/justremote/justremote/remote/TvDiscoveryManager.kt`

This file now performs real Android Network Service Discovery using `NsdManager`.

Main behavior:

- Starts DNS-SD/mDNS discovery for Android TV remote service types.
- Resolves matching services to IP address and port.
- Maps resolved services into `NativeTvDevice`.
- Uses the existing `NativeTvDevice.toMap()` output through the existing plugin flow.
- Adds detailed `Logcat` logs under the `TvDiscoveryManager` tag.
- Uses a Wi-Fi multicast lock during the scan to improve mDNS reliability.
- Catches discovery and resolve errors and returns `emptyList()` instead of throwing.

Service types scanned:

```text
_androidtvremote2._tcp.
_androidtvremote._tcp.
```

The main Android TV remote protocol port remains:

```text
6466
```

If the resolved NSD service does not provide a valid port, JustRemote falls back to port `6466`.

### `android/app/src/main/AndroidManifest.xml`

Additional Android permissions were added for Wi-Fi/local network discovery.

Added:

```xml
<uses-permission
    android:name="android.permission.NEARBY_WIFI_DEVICES"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission
    android:name="android.permission.ACCESS_FINE_LOCATION"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.ACCESS_LOCAL_NETWORK" />
```

Existing relevant permissions kept:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
```

### `android/app/src/test/kotlin/com/justremote/justremote/remote/TvDiscoveryManagerTest.kt`

Unit tests were added for the pure mapping logic.

Covered behavior:

- Builds an Android TV device from `_androidtvremote2._tcp.`.
- Uses default port `6466` when NSD reports port `0`.
- Ignores non-Android-TV services like `_googlecast._tcp.`.
- Ignores services that resolve without a host.

## Discovery Method Used

The implementation uses Android Network Service Discovery:

```kotlin
NsdManager.discoverServices(
    serviceType,
    NsdManager.PROTOCOL_DNS_SD,
    discoveryListener
)
```

Discovery flow:

1. Flutter calls the existing `scanForTvs` method over `MethodChannel`.
2. `TvRemotePlugin` delegates the call to `TvDiscoveryManager.scanForTvs()`.
3. `TvDiscoveryManager` starts NSD browsing for Android TV remote services.
4. When NSD finds a service, the implementation checks that the service type matches Android TV remote services.
5. The service is resolved with `NsdManager.resolveService(...)`.
6. The resolved host and port are mapped into `NativeTvDevice`.
7. The existing `NativeTvDevice.toMap()` shape is returned to Flutter.

The Flutter UI and Dart channel code were not changed.

## Why Android NSD

Android TV / Google TV devices commonly advertise local services over mDNS/DNS-SD. Android's `NsdManager` is the platform API for discovering these services on the local network.

This avoids hardcoded mock data and avoids scanning IP ranges manually. It is also safer for app stability because Android owns the discovery lifecycle and reports failures through callbacks.

## Permissions Added

### `NEARBY_WIFI_DEVICES`

Used on Android 13 and newer for nearby Wi-Fi device access. It is declared with:

```xml
android:usesPermissionFlags="neverForLocation"
```

That flag tells Android the app is not using this permission to infer physical location.

### `ACCESS_FINE_LOCATION`

Kept only for Android 12L/API 32 and below:

```xml
android:maxSdkVersion="32"
```

Older Android Wi-Fi discovery workflows can still require location-era compatibility permissions.

### `ACCESS_LOCAL_NETWORK`

Added for newer Android local network permission behavior. Current Android guidance notes that local network protections are evolving, and newer target SDKs may need this permission for broad local network access.

### `CHANGE_WIFI_MULTICAST_STATE`

Already present and used for the multicast lock. The discovery manager now acquires a short-lived multicast lock during scanning:

```kotlin
wifiManager.createMulticastLock("JustRemoteTvDiscovery")
```

This helps the app receive multicast DNS traffic during the NSD browse window.

## Failure Behavior

The implementation is intentionally defensive.

It returns an empty list when:

- `NsdManager` is unavailable.
- Discovery start fails.
- Discovery stop fails.
- Service resolution fails.
- A resolved service has no usable host.
- A found service is not an Android TV remote service.
- Any unexpected exception is thrown during scanning.

This keeps the MethodChannel stable and prevents Flutter from crashing due to network discovery problems.

## Logcat Debugging

Filter Android Studio Logcat by:

```text
TvDiscoveryManager
```

Important logs:

```text
scanForTvs requested
NSD available=true
Wi-Fi multicast lock available=true
ACCESS_WIFI_STATE granted=true
CHANGE_WIFI_MULTICAST_STATE granted=true
NEARBY_WIFI_DEVICES granted=true
ACCESS_LOCAL_NETWORK granted=true
Starting Android TV NSD browse for _androidtvremote2._tcp.
NSD discovery started for _androidtvremote2._tcp.
NSD service found name=... type=... port=...
Resolving NSD service name=... type=...
NSD resolved ... at 192.168.x.x:6466
Android TV discovered ... at 192.168.x.x:6466
scanForTvs finished with 1 device(s)
```

Failure logs to look for:

```text
NSD manager is unavailable; returning no devices
NSD discovery failed to start
NSD resolve failed
Resolved service is not usable
scanForTvs failed; returning no devices
Unable to acquire Wi-Fi multicast lock
```

If Android reports a permission-related NSD error, check:

- Whether Nearby devices is allowed in app permissions.
- Whether the phone and TV are on the same Wi-Fi.
- Whether the Wi-Fi network blocks client-to-client or multicast traffic.

## How To Test With Real Android TV / Google TV

1. Connect the Android phone running JustRemote and the Android TV / Google TV to the same Wi-Fi network.
2. Make sure the TV is awake and connected to the network.
3. Run the app:

```bash
flutter run
```

4. Open the TV scan screen in JustRemote.
5. Grant any Android permission prompts related to nearby devices/local network access.
6. Watch Android Studio Logcat with the `TvDiscoveryManager` filter.
7. A discovered device should appear in the existing scan UI.

If no device appears:

- Confirm both devices are on the same subnet.
- Disable guest Wi-Fi or AP/client isolation if enabled.
- Restart Wi-Fi on the phone and TV.
- Confirm Android TV remote control/network remote features are enabled on the TV.
- Check Logcat for NSD start/resolve failures.

## What Was Not Implemented

Pairing was intentionally not added or changed in this task.

The work only covers discovery. Existing pairing and command code paths remain separate.

The Flutter UI design was not changed.

## Verification Performed

The following checks were run after implementation.

Android unit tests:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:testDebugUnitTest
```

Result:

```text
BUILD SUCCESSFUL
```

Flutter tests:

```bash
flutter test
```

Result:

```text
All tests passed!
```

Flutter analyzer:

```bash
flutter analyze
```

Result:

```text
No issues found!
```

Debug APK build:

```bash
flutter build apk --debug
```

Result:

```text
Built build/app/outputs/flutter-apk/app-debug.apk
```

This verifies the project still builds in the same path that `flutter run` uses for the debug Android app.

## Notes From Android Documentation

Official Android documentation referenced during implementation:

- Android Network Service Discovery guide: https://developer.android.com/develop/connectivity/wifi/use-nsd
- Nearby Wi-Fi devices permission: https://developer.android.com/develop/connectivity/wifi/wifi-permissions
- Local network permission: https://developer.android.com/privacy-and-security/local-network-permission
- `NsdManager` API reference: https://developer.android.com/reference/android/net/nsd/NsdManager

Key takeaways:

- `NsdManager.discoverServices(...)` is the Android platform API for DNS-SD service discovery.
- `resolveService(...)` provides the connection information needed after a service is found.
- Android 13 and newer use `NEARBY_WIFI_DEVICES` for nearby Wi-Fi device workflows.
- Older Android compatibility can still require `ACCESS_FINE_LOCATION`, so it is declared only through API 32.
- Android local network permission behavior is evolving, so `ACCESS_LOCAL_NETWORK` was added for future local-network access requirements.

