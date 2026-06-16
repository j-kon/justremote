import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
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
                  color: AppTheme.surfaceRaised.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.glassButtonBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.05),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    const BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                child: _DpadArrow(
                  icon: Icons.keyboard_arrow_up_rounded,
                  size: buttonSize,
                  onCommand: () => onCommand(RemoteCommand.up),
                ),
              ),
              Positioned(
                bottom: 0,
                child: _DpadArrow(
                  icon: Icons.keyboard_arrow_down_rounded,
                  size: buttonSize,
                  onCommand: () => onCommand(RemoteCommand.down),
                ),
              ),
              Positioned(
                left: 0,
                child: _DpadArrow(
                  icon: Icons.keyboard_arrow_left_rounded,
                  size: buttonSize,
                  onCommand: () => onCommand(RemoteCommand.left),
                ),
              ),
              Positioned(
                right: 0,
                child: _DpadArrow(
                  icon: Icons.keyboard_arrow_right_rounded,
                  size: buttonSize,
                  onCommand: () => onCommand(RemoteCommand.right),
                ),
              ),
              SizedBox.square(
                dimension: buttonSize,
                child: _OkButton(onCommand: () => onCommand(RemoteCommand.select)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DpadArrow extends StatefulWidget {
  const _DpadArrow({
    required this.icon,
    required this.size,
    required this.onCommand,
  });

  final IconData icon;
  final double size;
  final VoidCallback onCommand;

  @override
  State<_DpadArrow> createState() => _DpadArrowState();
}

class _DpadArrowState extends State<_DpadArrow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        widget.onCommand();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed ? AppTheme.accent.withValues(alpha: 0.1) : Colors.transparent,
          border: _pressed
              ? Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.6),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            if (_pressed)
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.15),
                blurRadius: 10,
              ),
          ],
        ),
        child: Icon(
          widget.icon,
          size: widget.size * 0.45,
          color: _pressed ? AppTheme.accent : AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _OkButton extends StatefulWidget {
  const _OkButton({required this.onCommand});

  final VoidCallback onCommand;

  @override
  State<_OkButton> createState() => _OkButtonState();
}

class _OkButtonState extends State<_OkButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        widget.onCommand();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.accentLight, AppTheme.accentDark],
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.25),
                    spreadRadius: 5,
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    spreadRadius: 10,
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.5),
                    blurRadius: 14,
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.5),
                    blurRadius: 14,
                  ),
                ],
        ),
        child: const Center(
          child: Text(
            'OK',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
