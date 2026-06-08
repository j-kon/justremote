import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/saved_tvs/data/saved_tvs_repository.dart';
import '../../../shared/widgets/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [_Page1(), _Page2(), _Page3()];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(AppConstants.hasCompletedOnboardingKey, true);
    if (mounted) context.go('/scan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => _page = value),
                  children: _pages,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _page ? 20 : 7,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: index == _page ? AppTheme.accent : Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _page == _pages.length - 1 ? 'Get Started' : 'Next',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  if (_page == _pages.length - 1) {
                    _complete();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page scenes ───────────────────────────────────────────────────

class _Page1 extends StatelessWidget {
  const _Page1();

  @override
  Widget build(BuildContext context) {
    return const _ScenePage(
      title: 'Your phone.\nYour remote.',
      message: 'Works with any Android TV or Google TV on your Wi-Fi.',
      scene: _PhoneTvScene(),
    );
  }
}

class _Page2 extends StatelessWidget {
  const _Page2();

  @override
  Widget build(BuildContext context) {
    return const _ScenePage(
      title: 'Same Wi-Fi.\nZero setup.',
      message: 'JustRemote discovers nearby TVs automatically.',
      scene: _WifiScene(),
    );
  }
}

class _Page3 extends StatelessWidget {
  const _Page3();

  @override
  Widget build(BuildContext context) {
    return const _ScenePage(
      title: 'Pair once.\nAlways ready.',
      message: 'Save your TV and reconnect in seconds.',
      scene: _LockScene(),
    );
  }
}

class _ScenePage extends StatelessWidget {
  const _ScenePage({
    required this.title,
    required this.message,
    required this.scene,
  });

  final String title;
  final String message;
  final Widget scene;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        scene,
        const SizedBox(height: 36),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Scene widgets (Flutter primitives — no image assets) ──────────

class _PhoneTvScene extends StatelessWidget {
  const _PhoneTvScene();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Phone (left) with accent glow border
          Positioned(
            left: 10,
            child: Container(
              width: 48,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.sports_esports_rounded,
                  color: AppTheme.accent,
                  size: 22,
                ),
              ),
            ),
          ),
          // Connection line with gradient
          Positioned(
            left: 62,
            right: 62,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accent, Color(0x336C63FF)],
                ),
              ),
            ),
          ),
          // Traveling dot
          Positioned(
            left: 100,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent,
                boxShadow: [
                  BoxShadow(color: AppTheme.accent, blurRadius: 4),
                ],
              ),
            ),
          ),
          // TV (right)
          Positioned(
            right: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRaised,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.glassButtonBorder),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.movie_rounded,
                      color: AppTheme.textDim,
                      size: 20,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRaised,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WifiScene extends StatelessWidget {
  const _WifiScene();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 120,
      child: CustomPaint(
        painter: _WifiPainter(),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Icon(Icons.wifi_rounded, color: AppTheme.accent, size: 48),
          ),
        ),
      ),
    );
  }
}

class _WifiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.width / 2, size.height * 0.55);
    for (final r in [30.0, 55.0, 80.0]) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_WifiPainter _) => false;
}

class _LockScene extends StatelessWidget {
  const _LockScene();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accentBorder),
          ),
          child: const Center(
            child: Icon(
              Icons.lock_open_rounded,
              color: AppTheme.accent,
              size: 46,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}
