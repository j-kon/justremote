import 'package:flutter/material.dart';

class RemoteButtonWidget extends StatelessWidget {
  const RemoteButtonWidget({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.size = 68,
    this.backgroundColor,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: backgroundColor ?? const Color(0xFF1B2230),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onPressed,
            child: Icon(icon, size: size * 0.34),
          ),
        ),
      ),
    );
  }
}
