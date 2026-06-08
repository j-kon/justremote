import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../tv_discovery/domain/tv_device.dart';
import '../data/remote_control_channel.dart';
import '../domain/remote_command.dart';
import 'widgets/dpad_widget.dart';
import 'widgets/remote_button_widget.dart';
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
  String? _lastMessage;

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
      final success = await _channel.sendCommand(command);
      if (!mounted) return;
      setState(() {
        _lastMessage = success ? '${command.wireName} sent' : 'Command failed';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lastMessage = 'Command failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                connected: _connected,
                deviceName:
                    _deviceName ?? widget.device?.name ?? 'No TV connected',
              ),
              const SizedBox(height: 22),
              TopControls(onCommand: _send),
              const SizedBox(height: 28),
              Center(
                child: SizedBox.square(
                  dimension: dpadSize,
                  child: DpadWidget(onCommand: _send),
                ),
              ),
              const SizedBox(height: 28),
              VolumeControls(onCommand: _send),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RemoteButtonWidget(
                    label: 'Channel down',
                    icon: Icons.keyboard_arrow_down_rounded,
                    onPressed: () => _send(RemoteCommand.channelDown),
                  ),
                  RemoteButtonWidget(
                    label: 'Keyboard',
                    icon: Icons.keyboard_rounded,
                    onPressed: () => setState(() {
                      _lastMessage = 'Keyboard placeholder';
                    }),
                  ),
                  RemoteButtonWidget(
                    label: 'Touchpad',
                    icon: Icons.touch_app_rounded,
                    onPressed: () => setState(() {
                      _lastMessage = 'Touchpad placeholder';
                    }),
                  ),
                  RemoteButtonWidget(
                    label: 'Channel up',
                    icon: Icons.keyboard_arrow_up_rounded,
                    onPressed: () => _send(RemoteCommand.channelUp),
                  ),
                ],
              ),
              if (_lastMessage != null) ...[
                const SizedBox(height: 20),
                Text(
                  _lastMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ConnectionHeader extends StatelessWidget {
  const _ConnectionHeader({required this.connected, required this.deviceName});

  final bool connected;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: connected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white30,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                deviceName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              connected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: connected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
