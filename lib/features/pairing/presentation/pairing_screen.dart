import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _pairingChannel = PairingChannel();
  PairingStatus _status = PairingStatus.idle;
  String? _message;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_startPairing);
  }

  @override
  void dispose() {
    _codeController.dispose();
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
    } catch (error) {
      setState(() {
        _status = PairingStatus.failed;
        _message = 'Could not pair with ${widget.device.name}.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPairing = _status == PairingStatus.pairing;

    return AppScaffold(
      title: 'Pair TV',
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.tv_rounded,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.device.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.device.host,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Pairing code',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              hintText: 'Enter code shown on TV',
            ),
            onSubmitted: (_) => _pair(),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _message == null
                ? const SizedBox.shrink()
                : Text(
                    _message!,
                    key: ValueKey(_message),
                    style: TextStyle(
                      color: _status == PairingStatus.failed
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Pair TV',
            icon: Icons.link_rounded,
            isLoading: isPairing,
            onPressed: isPairing ? null : _pair,
          ),
        ],
      ),
    );
  }
}
