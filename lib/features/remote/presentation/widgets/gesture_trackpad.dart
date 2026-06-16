import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/remote_command.dart';

class GestureTrackpad extends StatefulWidget {
  const GestureTrackpad({required this.onCommand, super.key});

  final ValueChanged<RemoteCommand> onCommand;

  @override
  State<GestureTrackpad> createState() => _GestureTrackpadState();
}

class _GestureTrackpadState extends State<GestureTrackpad> with SingleTickerProviderStateMixin {
  Offset? _panStart;
  Offset? _currentPosition;
  Offset? _tapPosition;
  double _rippleRadius = 0.0;
  double _rippleOpacity = 0.0;
  
  late final AnimationController _rippleController;
  static const double _swipeThreshold = 30.0;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        setState(() {
          _rippleRadius = _rippleController.value * 80.0;
          _rippleOpacity = 1.0 - _rippleController.value;
        });
      });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _panStart = details.localPosition;
      _currentPosition = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final start = _panStart;
    if (start == null) return;
    
    setState(() {
      _currentPosition = details.localPosition;
    });

    final delta = details.localPosition - start;
    if (delta.distance < _swipeThreshold) return;

    // Reset starting point to detect sequential swipes
    _panStart = details.localPosition;

    final RemoteCommand command;
    if (delta.dx.abs() > delta.dy.abs()) {
      command = delta.dx > 0 ? RemoteCommand.right : RemoteCommand.left;
    } else {
      command = delta.dy > 0 ? RemoteCommand.down : RemoteCommand.up;
    }

    HapticFeedback.lightImpact();
    widget.onCommand(command);
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _panStart = null;
      _currentPosition = null;
    });
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    _rippleController.forward(from: 0.0);
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onCommand(RemoteCommand.select);
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    widget.onCommand(RemoteCommand.back);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTap: _onTap,
      onLongPress: _onLongPress,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.glassButtonBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 15,
                spreadRadius: -5,
              )
            ],
          ),
          child: CustomPaint(
            painter: _TrackpadPainter(
              currentPosition: _currentPosition,
              tapPosition: _tapPosition,
              rippleRadius: _rippleRadius,
              rippleOpacity: _rippleOpacity,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_rounded,
                        size: 40,
                        color: AppTheme.accent.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'SWIPE',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to OK • Long Press for Back',
                        style: TextStyle(
                          color: AppTheme.textDim.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackpadPainter extends CustomPainter {
  _TrackpadPainter({
    required this.currentPosition,
    required this.tapPosition,
    required this.rippleRadius,
    required this.rippleOpacity,
  });

  final Offset? currentPosition;
  final Offset? tapPosition;
  final double rippleRadius;
  final double rippleOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.glassButtonBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw a subtle decorative tech grid in background
    const gridSpacing = 40.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw active finger position glow
    final pos = currentPosition;
    if (pos != null) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.25),
            AppTheme.accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: 45))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 45, glowPaint);

      final corePaint = Paint()
        ..color = AppTheme.accent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 4, corePaint);
    }

    // Draw tap ripple effect
    final tapPos = tapPosition;
    if (tapPos != null && rippleOpacity > 0.0) {
      final ripplePaint = Paint()
        ..color = AppTheme.accent.withValues(alpha: rippleOpacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(tapPos, rippleRadius, ripplePaint);

      final rippleFill = Paint()
        ..color = AppTheme.accent.withValues(alpha: rippleOpacity * 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tapPos, rippleRadius, rippleFill);
    }
  }

  @override
  bool shouldRepaint(covariant _TrackpadPainter oldDelegate) {
    return oldDelegate.currentPosition != currentPosition ||
        oldDelegate.tapPosition != tapPosition ||
        oldDelegate.rippleRadius != rippleRadius ||
        oldDelegate.rippleOpacity != rippleOpacity;
  }
}
