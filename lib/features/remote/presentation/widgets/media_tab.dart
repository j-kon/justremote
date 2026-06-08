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
