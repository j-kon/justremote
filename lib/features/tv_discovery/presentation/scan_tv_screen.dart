import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../domain/tv_device.dart';
import '../domain/tv_discovery_repository.dart';
import 'widgets/tv_device_card.dart';

class ScanTvScreen extends ConsumerStatefulWidget {
  const ScanTvScreen({super.key});

  @override
  ConsumerState<ScanTvScreen> createState() => _ScanTvScreenState();
}

class _ScanTvScreenState extends ConsumerState<ScanTvScreen> {
  late Future<List<TvDevice>> _scanFuture;

  @override
  void initState() {
    super.initState();
    _scanFuture = _scan();
  }

  Future<List<TvDevice>> _scan() =>
      ref.read(tvDiscoveryRepositoryProvider).scanForTvs();

  void _rescan() => setState(() {
        _scanFuture = _scan();
      });

  void _enterManualIp() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceRaised,
        title: const Text('Enter TV IP address'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '192.168.1.x'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                Navigator.of(ctx).pop();
                final device = TvDevice(
                  id: ip,
                  name: ip,
                  host: ip,
                  port: 6466,
                  type: 'manual',
                );
                context.push('/pairing', extra: device);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Find TV',
      actions: [
        IconButton(
          tooltip: 'Saved TVs',
          icon: const Icon(Icons.devices_rounded),
          onPressed: () => context.go('/saved'),
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => context.push('/settings'),
        ),
      ],
      body: FutureBuilder<List<TvDevice>>(
        future: _scanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _ScanningView();
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Scan failed',
              message: 'Check Wi-Fi and try scanning again.',
              action: PrimaryButton(
                label: 'Rescan',
                icon: Icons.refresh_rounded,
                onPressed: _rescan,
              ),
            );
          }
          final devices = snapshot.data ?? const [];
          if (devices.isEmpty) {
            return _EmptyResult(onRescan: _rescan, onManualIp: _enterManualIp);
          }
          return _ResultList(
            devices: devices,
            onRescan: _rescan,
            onManualIp: _enterManualIp,
          );
        },
      ),
    );
  }
}

// ── Scanning state ────────────────────────────────────────────────

class _ScanningView extends StatelessWidget {
  const _ScanningView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RadarWidget(size: 160),
          const SizedBox(height: 20),
          Text(
            'SCANNING',
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class RadarWidget extends StatefulWidget {
  const RadarWidget({this.size = 160, super.key});

  final double size;

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse1;
  late Animation<double> _pulse2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulse1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 1.0)),
    );
    _pulse2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0)),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _RadarPainter(_pulse1.value, _pulse2.value),
          child: Center(
            child: Container(
              width: widget.size * 0.22,
              height: widget.size * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.15),
                border: Border.all(color: AppTheme.accentBorder),
              ),
              child: const Center(
                child: Icon(
                  Icons.cell_tower_rounded,
                  color: AppTheme.accent,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter(this.pulse1, this.pulse2);

  final double pulse1;
  final double pulse2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.width / 2;

    final staticPaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final frac in [0.4, 0.7, 1.0]) {
      canvas.drawCircle(center, maxR * frac, staticPaint);
    }

    _drawPulse(canvas, center, maxR, pulse1);
    if (pulse2 > 0) _drawPulse(canvas, center, maxR, pulse2);
  }

  void _drawPulse(Canvas canvas, Offset center, double maxR, double t) {
    final r = maxR * 0.2 + maxR * 0.8 * t;
    final opacity = (1.0 - t).clamp(0.0, 0.6);
    final paint = Paint()
      ..color = AppTheme.accent.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.pulse1 != pulse1 || old.pulse2 != pulse2;
}

// ── Result states ─────────────────────────────────────────────────

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.onRescan, required this.onManualIp});

  final VoidCallback onRescan;
  final VoidCallback onManualIp;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No TVs found',
      message: 'Make sure your Android TV is on the same Wi-Fi network.',
      action: Column(
        children: [
          PrimaryButton(
            label: 'Rescan',
            icon: Icons.refresh_rounded,
            onPressed: onRescan,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onManualIp,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Enter IP manually'),
          ),
        ],
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.devices,
    required this.onRescan,
    required this.onManualIp,
  });

  final List<TvDevice> devices;
  final VoidCallback onRescan;
  final VoidCallback onManualIp;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: devices.length + 2,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index < devices.length) {
          return _SlideInCard(
            delay: Duration(milliseconds: index * 80),
            child: TvDeviceCard(
              device: devices[index],
              onTap: () => context.push('/pairing', extra: devices[index]),
            ),
          );
        }
        if (index == devices.length) {
          return PrimaryButton(
            label: 'Rescan',
            icon: Icons.refresh_rounded,
            onPressed: onRescan,
          );
        }
        return TextButton.icon(
          onPressed: onManualIp,
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: const Text('Enter IP manually'),
        );
      },
    );
  }
}

class _SlideInCard extends StatefulWidget {
  const _SlideInCard({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_SlideInCard> createState() => _SlideInCardState();
}

class _SlideInCardState extends State<_SlideInCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
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
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slide.value),
        child: Opacity(opacity: _fade.value, child: child),
      ),
      child: widget.child,
    );
  }
}
