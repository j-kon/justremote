import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../tv_discovery/domain/tv_device.dart';
import '../data/remote_control_channel.dart';
import '../domain/remote_command.dart';
import 'widgets/apps_tab.dart';
import 'widgets/dpad_widget.dart';
import 'widgets/gesture_trackpad.dart';
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
  bool _connecting = false;
  bool _busy = false;
  String? _deviceName;
  int _tabIndex = 0;
  bool _showDpad = true;

  @override
  void initState() {
    super.initState();
    _channel.setConnectionClosedHandler(() {
      if (mounted) {
        setState(() {
          _connected = false;
        });
      }
    });
    _connect();
  }

  Future<bool> _connect() async {
    if (_connecting) return false;
    setState(() {
      _connecting = true;
    });
    try {
      var device = widget.device;
      if (device == null) {
        final status = await _channel.getConnectionStatus();
        if (status['connected'] == true) {
          if (!mounted) return false;
          setState(() {
            _connected = true;
            _deviceName = status['deviceName'] as String?;
            _connecting = false;
          });
          return true;
        }
        final lastTvMap = await _channel.getLastConnectedTv();
        if (lastTvMap != null) {
          device = TvDevice.fromMap(lastTvMap);
        }
      }

      if (device == null) {
        if (!mounted) return false;
        setState(() {
          _connected = false;
          _connecting = false;
        });
        return false;
      }

      final connected = await _channel.connectToTv(device);
      if (!mounted) return false;
      setState(() {
        _connected = connected;
        _deviceName = device!.name;
        _connecting = false;
      });
      return connected;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _connected = false;
        _connecting = false;
      });
      return false;
    }
  }

  Future<void> _send(RemoteCommand command) async {
    if (_connecting || _busy) return;
    setState(() => _busy = true);
    try {
      if (!_connected && !await _connect()) {
        setState(() => _busy = false);
        return;
      }
      final sent = await _channel.sendCommand(command);
      if (!sent) {
        if (await _connect()) {
          await _channel.sendCommand(command);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection lost. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sendText(String text) async {
    if (_connecting || _busy) return;
    setState(() => _busy = true);
    try {
      if (!_connected && !await _connect()) {
        setState(() => _busy = false);
        return;
      }
      final sent = await _channel.sendText(text);
      if (!sent) throw Exception('Failed to send text');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection lost. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _launchApp(String appLink) async {
    if (_connecting || _busy) return;
    setState(() => _busy = true);
    try {
      if (!_connected && !await _connect()) {
        setState(() => _busy = false);
        return;
      }
      final launched = await _channel.launchApp(appLink);
      if (!launched) throw Exception('Failed to launch app');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection lost. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = switch (_tabIndex) {
      0 => AppTheme.accent.withValues(alpha: 0.15),
      1 => Colors.blue.withValues(alpha: 0.12),
      2 => Colors.teal.withValues(alpha: 0.12),
      3 => Colors.amber.withValues(alpha: 0.12),
      _ => AppTheme.accent.withValues(alpha: 0.15),
    };

    return AppScaffold(
      title: '',
      actions: [
        if (_tabIndex == 0)
          IconButton(
            tooltip: _showDpad ? 'Switch to Trackpad' : 'Switch to D-pad',
            icon: Icon(_showDpad ? Icons.touch_app_rounded : Icons.sports_esports_rounded),
            onPressed: () => setState(() => _showDpad = !_showDpad),
          ),
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
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            top: _tabIndex == 3 ? 150 : -150,
            left: -150,
            right: -150,
            height: 500,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [glowColor, Colors.transparent],
                  stops: const [0.0, 0.8],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: InkWell(
                  onTap: _connecting || _connected ? null : _connect,
                  borderRadius: BorderRadius.circular(10),
                  child: StatusBar(
                    connected: _connected,
                    connecting: _connecting,
                    deviceName:
                        _deviceName ?? widget.device?.name ?? 'No TV connected',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: AbsorbPointer(
                  absorbing: _connecting || _busy,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TopControls(onCommand: _send),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: IndexedStack(
                          index: _tabIndex,
                          children: [
                            // Remote tab — D-pad or Gesture Touchpad
                            _showDpad
                                ? LayoutBuilder(
                                    builder: (context, constraints) {
                                      final size = constraints.maxHeight.clamp(200.0, 300.0);
                                      return Center(
                                        child: SizedBox.square(
                                          dimension: size,
                                          child: DpadWidget(onCommand: _send),
                                        ),
                                      );
                                    },
                                  )
                                : Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                                    child: GestureTrackpad(onCommand: _send),
                                  ),
                            // Media tab
                            MediaTab(onCommand: _send),
                            // Input tab
                            InputTab(onCommand: _send, onSendText: _sendText),
                            // Apps tab
                            AppsTab(onLaunchApp: _launchApp),
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
                ),
              ),
            ],
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
          _Tab(
            icon: Icons.sports_esports_rounded,
            label: 'Remote',
            selected: selectedIndex == 0,
            onTap: () => onTab(0),
          ),
          _Tab(
            icon: Icons.music_note_rounded,
            label: 'Media',
            selected: selectedIndex == 1,
            onTap: () => onTab(1),
          ),
          _Tab(
            icon: Icons.keyboard_rounded,
            label: 'Input',
            selected: selectedIndex == 2,
            onTap: () => onTab(2),
          ),
          _Tab(
            icon: Icons.apps_rounded,
            label: 'Apps',
            selected: selectedIndex == 3,
            onTap: () => onTab(3),
          ),
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
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
