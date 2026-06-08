import 'package:flutter/material.dart';

import '../../domain/remote_command.dart';
import 'remote_button_widget.dart';

class TopControls extends StatelessWidget {
  const TopControls({required this.onCommand, super.key});

  final ValueChanged<RemoteCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RemoteButtonWidget(
          label: 'Power',
          icon: Icons.power_settings_new_rounded,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.error.withValues(alpha: 0.22),
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
