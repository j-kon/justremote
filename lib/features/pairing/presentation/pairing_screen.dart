import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../saved_tvs/data/saved_tvs_repository.dart';
import '../../tv_discovery/domain/tv_device.dart';
import '../data/pairing_channel.dart';
import '../domain/pairing_status.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({required this.device, super.key});

  final TvDevice device;

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  final _pairingChannel = PairingChannel();
  PairingStatus _status = PairingStatus.idle;
  String? _message;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
    Future<void>.microtask(_startPairing);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _startPairing() async {
    setState(() {
      _status = PairingStatus.pairing;
      _message = 'Starting pairing on ${widget.device.name}...';
    });
    try {
      final message = await _pairingChannel.startPairing(widget.device);
      if (!mounted) return;
      setState(() {
        _status = PairingStatus.idle;
        _message = message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = PairingStatus.failed;
        _message = 'Could not start pairing. Check that the TV is on.';
      });
    }
  }

  Future<void> _pair() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _status = PairingStatus.failed;
        _message = 'Enter the pairing code shown on your TV.';
      });
      return;
    }
    setState(() {
      _status = PairingStatus.pairing;
      _message = null;
    });
    try {
      final message = await _pairingChannel.pairTv(
        device: widget.device,
        pairingCode: code,
      );
      await ref.read(savedTvsRepositoryProvider).saveTv(widget.device);
      ref.invalidate(savedTvsProvider);
      setState(() {
        _status = PairingStatus.success;
        _message = message;
      });
      if (mounted) context.go('/remote', extra: widget.device);
    } catch (_) {
      setState(() {
        _status = PairingStatus.failed;
        _message = 'Could not pair with ${widget.device.name}.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPairing = _status == PairingStatus.pairing;
    final code = _codeController.text;
    final isCodeComplete = code.length == 6;

    return AppScaffold(
      title: 'Pair TV',
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          // TV status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.tv_rounded, size: 32, color: AppTheme.accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.device.host,
                        style: const TextStyle(
                          color: AppTheme.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'A code appeared on your TV.\nEnter it below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // 6 segmented boxes driven by hidden TextField
          GestureDetector(
            onTap: () => _codeFocus.requestFocus(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final char = i < code.length ? code[i] : null;
                final isActive = i == code.length && code.length < 6;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CodeBox(char: char, isActive: isActive),
                );
              }),
            ),
          ),
          // Hidden text field that drives the boxes
          SizedBox(
            height: 0,
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _codeController,
                focusNode: _codeFocus,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                onSubmitted: (_) => _pair(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _message == null
                ? const SizedBox.shrink()
                : Text(
                    _message!,
                    key: ValueKey(_message),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _status == PairingStatus.failed
                          ? Theme.of(context).colorScheme.error
                          : AppTheme.accent,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Confirm',
            icon: Icons.link_rounded,
            isLoading: isPairing,
            onPressed: (isPairing || !isCodeComplete) ? null : _pair,
          ),
        ],
      ),
    );
  }
}

class CodeBox extends StatelessWidget {
  const CodeBox({required this.char, required this.isActive, super.key});

  final String? char;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 42,
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? AppTheme.accent : AppTheme.glassButtonBorder,
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Center(
        child: isActive
            ? const _BlinkingCursor()
            : (char != null
                ? Text(
                    char!.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Opacity(
        opacity: _ctrl.value > 0.5 ? 1.0 : 0.0,
        child: Container(
          width: 2,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
