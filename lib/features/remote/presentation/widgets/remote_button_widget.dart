import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

class RemoteButtonWidget extends StatefulWidget {
  const RemoteButtonWidget({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.size = 56,
    this.isPower = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final bool isPower;

  @override
  State<RemoteButtonWidget> createState() => _RemoteButtonWidgetState();
}

class _RemoteButtonWidgetState extends State<RemoteButtonWidget> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.isPower) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 80), () => HapticFeedback.mediumImpact());
    } else {
      HapticFeedback.lightImpact();
    }
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    widget.onPressed();
    setState(() => _pressed = false);
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isPower ? AppTheme.powerRed : AppTheme.accent;

    return Tooltip(
      message: widget.label,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: _pressed
              ? const Duration(milliseconds: 80)
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.isPower
                ? AppTheme.powerRed.withValues(alpha: _pressed ? 0.3 : 0.15)
                : AppTheme.surfaceRaised.withValues(alpha: _pressed ? 0.35 : 0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressed
                  ? borderColor.withValues(alpha: 0.8)
                  : (widget.isPower
                      ? AppTheme.powerRed.withValues(alpha: 0.3)
                      : AppTheme.glassButtonBorder),
              width: _pressed ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (_pressed)
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.38,
            color: _pressed
                ? (widget.isPower ? AppTheme.powerRed : AppTheme.accent)
                : (widget.isPower ? AppTheme.powerRed : AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}
