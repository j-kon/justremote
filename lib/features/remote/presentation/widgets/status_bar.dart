import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({required this.connected, required this.deviceName, super.key});

  final bool connected;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: connected
            ? AppTheme.accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: connected
              ? AppTheme.accent.withValues(alpha: 0.2)
              : AppTheme.glassButtonBorder,
        ),
        boxShadow: connected
            ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.2), blurRadius: 8)]
            : null,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: connected ? AppTheme.accent : Colors.white30,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              deviceName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            connected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: connected ? AppTheme.accent : Colors.white30,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
