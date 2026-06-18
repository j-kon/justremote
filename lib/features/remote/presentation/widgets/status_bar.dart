import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({
    required this.connected,
    required this.deviceName,
    this.connecting = false,
    super.key,
  });

  final bool connected;
  final bool connecting;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final statusColor = connecting
        ? Colors.amberAccent
        : connected
            ? AppTheme.accent
            : Colors.white30;

    final statusText = connecting
        ? 'Connecting...'
        : connected
            ? 'Connected'
            : 'Disconnected';

    final bgColor = connecting
        ? Colors.amberAccent.withValues(alpha: 0.08)
        : connected
            ? AppTheme.accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04);

    final borderColor = connecting
        ? Colors.amberAccent.withValues(alpha: 0.2)
        : connected
            ? AppTheme.accent.withValues(alpha: 0.2)
            : AppTheme.glassButtonBorder;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: (connected && !connecting)
            ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.2), blurRadius: 8)]
            : connecting
                ? [BoxShadow(color: Colors.amberAccent.withValues(alpha: 0.2), blurRadius: 8)]
                : null,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: statusColor,
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
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
