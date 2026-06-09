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

  Future<bool> _connect() async {
    final device = widget.device;
    if (device == null) {
      final status = await _channel.getConnectionStatus();
      if (!mounted) return false;
      setState(() {
        _connected = status['connected'] == true;
        _deviceName = status['deviceName'] as String?;
      });
      return _connected;
    }
    final connected = await _channel.connectToTv(device);
    if (!mounted) return false;
    setState(() {
      _connected = connected;
      _deviceName = device.name;
    });
    return connected;
  }

  Future<void> _send(RemoteCommand command) async {
    try {
      if (!_connected && !await _connect()) return;
      final sent = await _channel.sendCommand(command);
      if (sent) return;
      if (await _connect()) {
        await _channel.sendCommand(command);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _connected = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection lost. Try again.')),
      );
    }
  }

  // Placeholder until the keyboard-input feature (other plan) is wired up.
  void _sendText(String text) {}

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
              deviceName:
                  _deviceName ?? widget.device?.name ?? 'No TV connected',
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
