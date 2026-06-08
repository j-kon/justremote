import 'package:flutter/material.dart';

import '../../domain/remote_command.dart';

class DpadWidget extends StatelessWidget {
  const DpadWidget({required this.onCommand, super.key});

  final ValueChanged<RemoteCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonSize = constraints.maxWidth / 3;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF121722),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: Colors.white10),
                ),
              ),
              Positioned(
                top: 0,
                child: _DpadButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  size: buttonSize,
                  onTap: () => onCommand(RemoteCommand.up),
                ),
              ),
              Positioned(
                bottom: 0,
                child: _DpadButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  size: buttonSize,
                  onTap: () => onCommand(RemoteCommand.down),
                ),
              ),
              Positioned(
                left: 0,
                child: _DpadButton(
                  icon: Icons.keyboard_arrow_left_rounded,
                  size: buttonSize,
                  onTap: () => onCommand(RemoteCommand.left),
                ),
              ),
              Positioned(
                right: 0,
                child: _DpadButton(
                  icon: Icons.keyboard_arrow_right_rounded,
                  size: buttonSize,
                  onTap: () => onCommand(RemoteCommand.right),
                ),
              ),
              SizedBox.square(
                dimension: buttonSize,
                child: Material(
                  color: Theme.of(context).colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onCommand(RemoteCommand.select),
                    child: const Center(
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DpadButton extends StatelessWidget {
  const _DpadButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: IconButton(onPressed: onTap, icon: Icon(icon, size: 36)),
    );
  }
}
