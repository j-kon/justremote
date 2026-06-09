import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../remote/data/remote_control_channel.dart';
import '../../tv_discovery/presentation/widgets/tv_device_card.dart';
import '../data/saved_tvs_repository.dart';

class SavedTvsScreen extends ConsumerWidget {
  const SavedTvsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedTvs = ref.watch(savedTvsProvider);

    return AppScaffold(
      title: 'Saved TVs',
      actions: [
        IconButton(
          tooltip: 'Add TV',
          icon: const Icon(Icons.add_rounded),
          onPressed: () => context.go('/scan'),
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => context.push('/settings'),
        ),
      ],
      body: savedTvs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load TVs',
          message: 'Try reopening JustRemote.',
          action: PrimaryButton(
            label: 'Scan for TV',
            icon: Icons.search_rounded,
            onPressed: () => context.go('/scan'),
          ),
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return EmptyState(
              icon: Icons.tv_off_rounded,
              title: 'No saved TVs',
              message: 'Add your Android TV or Google TV to get started.',
              action: PrimaryButton(
                label: 'Scan for TV',
                icon: Icons.search_rounded,
                onPressed: () => context.go('/scan'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: devices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final device = devices[index];
              return Dismissible(
                key: ValueKey(device.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.delete_rounded),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  await RemoteControlChannel().forgetTv(device);
                  await ref
                      .read(savedTvsRepositoryProvider)
                      .removeTv(device.id);
                  ref.invalidate(savedTvsProvider);
                },
                child: TvDeviceCard(
                  device: device,
                  onTap: () async {
                    if (!device.paired) {
                      context.push('/pairing', extra: device);
                      return;
                    }
                    final connected = await RemoteControlChannel().connectToTv(
                      device,
                    );
                    if (!context.mounted) return;
                    if (connected) {
                      context.go('/remote', extra: device);
                    } else {
                      context.push('/pairing', extra: device);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
