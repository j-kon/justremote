import 'package:flutter/material.dart';

import '../../domain/remote_command.dart';
import 'remote_button_widget.dart';

class VolumeControls extends StatelessWidget {
  const VolumeControls({required this.onCommand, super.key});

  final ValueChanged<RemoteCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RemoteButtonWidget(
          label: 'Volume down',
          icon: Icons.volume_down_rounded,
          onPressed: () => onCommand(RemoteCommand.volumeDown),
        ),
        RemoteButtonWidget(
          label: 'Mute',
          icon: Icons.volume_off_rounded,
          onPressed: () => onCommand(RemoteCommand.mute),
        ),
        RemoteButtonWidget(
          label: 'Volume up',
          icon: Icons.volume_up_rounded,
          onPressed: () => onCommand(RemoteCommand.volumeUp),
        ),
      ],
    );
  }
}
