import 'package:flutter/material.dart';

import 'remote_command.dart';

class RemoteButton {
  const RemoteButton({
    required this.label,
    required this.icon,
    required this.command,
  });

  final String label;
  final IconData icon;
  final RemoteCommand command;
}
