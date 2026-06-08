import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/pairing/presentation/pairing_screen.dart';
import 'features/remote/presentation/remote_screen.dart';
import 'features/saved_tvs/data/saved_tvs_repository.dart';
import 'features/saved_tvs/presentation/saved_tvs_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/tv_discovery/domain/tv_device.dart';
import 'features/tv_discovery/presentation/scan_tv_screen.dart';
import 'shared/widgets/loading_view.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) => const _StartupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/scan', builder: (context, state) => const ScanTvScreen()),
      GoRoute(
        path: '/saved',
        builder: (context, state) => const SavedTvsScreen(),
      ),
      GoRoute(
        path: '/pairing',
        builder: (context, state) {
          final device = state.extra as TvDevice;
          return PairingScreen(device: device);
        },
      ),
      GoRoute(
        path: '/remote',
        builder: (context, state) {
          final device = state.extra as TvDevice?;
          return RemoteScreen(device: device);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

class JustRemoteApp extends ConsumerWidget {
  const JustRemoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

class _StartupScreen extends ConsumerStatefulWidget {
  const _StartupScreen();

  @override
  ConsumerState<_StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<_StartupScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_routeFromSavedState);
  }

  Future<void> _routeFromSavedState() async {
    final preferences = ref.read(sharedPreferencesProvider);
    final firstRun =
        preferences.getBool(AppConstants.hasCompletedOnboardingKey) != true;
    if (!mounted) return;
    if (firstRun) {
      context.go('/onboarding');
      return;
    }

    final savedTvs = await ref.read(savedTvsRepositoryProvider).loadSavedTvs();
    if (!mounted) return;
    context.go(savedTvs.isEmpty ? '/scan' : '/saved');
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingView(message: 'Starting JustRemote...');
  }
}
