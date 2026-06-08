import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  Future<List<TvDevice>> _scan() {
    return ref.read(tvDiscoveryRepositoryProvider).scanForTvs();
  }

  void _rescan() {
    setState(() {
      _scanFuture = _scan();
    });
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
            return const Center(child: CircularProgressIndicator());
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
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No TVs found',
              message:
                  'Make sure your Android TV is on the same Wi-Fi network.',
              action: PrimaryButton(
                label: 'Rescan',
                icon: Icons.refresh_rounded,
                onPressed: _rescan,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: devices.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == devices.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: PrimaryButton(
                    label: 'Rescan',
                    icon: Icons.refresh_rounded,
                    onPressed: _rescan,
                  ),
                );
              }
              final device = devices[index];
              return TvDeviceCard(
                device: device,
                onTap: () => context.push('/pairing', extra: device),
              );
            },
          );
        },
      ),
    );
  }
}
