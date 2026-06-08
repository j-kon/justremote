import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/remote_command.dart';

class InputTab extends StatefulWidget {
  const InputTab({
    required this.onCommand,
    required this.onSendText,
    super.key,
  });

  final ValueChanged<RemoteCommand> onCommand;
  final ValueChanged<String> onSendText;

  @override
  State<InputTab> createState() => _InputTabState();
}

class _InputTabState extends State<InputTab> {
  final _textController = TextEditingController();
  Offset? _panStart;
  static const _threshold = 24.0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) => _panStart = d.localPosition;

  void _onPanUpdate(DragUpdateDetails d) {
    final start = _panStart;
    if (start == null) return;
    final delta = d.localPosition - start;
    if (delta.distance < _threshold) return;
    _panStart = d.localPosition;

    final RemoteCommand cmd;
    if (delta.dx.abs() > delta.dy.abs()) {
      cmd = delta.dx > 0 ? RemoteCommand.right : RemoteCommand.left;
    } else {
      cmd = delta.dy > 0 ? RemoteCommand.down : RemoteCommand.up;
    }
    HapticFeedback.lightImpact();
    widget.onCommand(cmd);
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onCommand(RemoteCommand.select);
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    widget.onCommand(RemoteCommand.back);
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              key: const Key('touchpad'),
              onTap: _onTap,
              onLongPress: _onLongPress,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.glassButtonBorder),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 32,
                        color: AppTheme.textDim,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Swipe to navigate · Tap to select · Hold for back',
                        style: TextStyle(color: AppTheme.textDim, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendText(),
                  decoration: const InputDecoration(
                    hintText: 'Type to send text to TV',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SendButton(onTap: _sendText),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        widget.onTap();
        setState(() => _pressed = false);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.accentLight, AppTheme.accentDark],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
