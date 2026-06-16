import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../remote/data/remote_control_channel.dart';
import '../../saved_tvs/data/saved_tvs_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _remoteChannel = RemoteControlChannel();
  late Future<Map<String, Object?>> _diagnosticsFuture;

  @override
  void initState() {
    super.initState();
    _diagnosticsFuture = _remoteChannel.getDiagnostics();
  }

  void _refreshDiagnostics() {
    setState(() {
      _diagnosticsFuture = _remoteChannel.getDiagnostics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Version 1.0.0'),
                  const SizedBox(height: 16),
                  const Text('JustRemote is built to be clean and ad-free.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _DiagnosticsCard(
            diagnosticsFuture: _diagnosticsFuture,
            onRefresh: _refreshDiagnostics,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Clear saved TVs',
            icon: Icons.delete_outline_rounded,
            onPressed: () async {
              await _remoteChannel.resetPairingData();
              await ref.read(savedTvsRepositoryProvider).clearSavedTvs();
              ref.invalidate(savedTvsProvider);
              _refreshDiagnostics();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved TVs cleared')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({
    required this.diagnosticsFuture,
    required this.onRefresh,
  });

  final Future<Map<String, Object?>> diagnosticsFuture;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<Map<String, Object?>>(
          future: diagnosticsFuture,
          builder: (context, snapshot) {
            final diagnostics = snapshot.data ?? const <String, Object?>{};
            final connected = diagnostics['connected'] == true;
            final deviceName = diagnostics['deviceName'] as String?;
            final lastError = diagnostics['lastError'] as String?;
            final events =
                (diagnostics['events'] as List<dynamic>?)
                    ?.cast<Object?>()
                    .map((event) => event.toString())
                    .toList(growable: false) ??
                const <String>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Diagnostics',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: onRefresh,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(connected ? 'Connected' : 'Not connected'),
                if (deviceName != null) Text(deviceName),
                if (lastError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    lastError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (events.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (final event in events.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        event,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
