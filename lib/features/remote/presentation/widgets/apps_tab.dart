import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

class TvAppItem {
  const TvAppItem({
    required this.name,
    required this.icon,
    required this.appLink,
    required this.color,
  });

  final String name;
  final IconData icon;
  final String appLink;
  final Color color;
}

class AppsTab extends StatelessWidget {
  const AppsTab({required this.onLaunchApp, super.key});

  final ValueChanged<String> onLaunchApp;

  static const List<TvAppItem> _apps = [
    TvAppItem(
      name: 'YouTube',
      icon: Icons.play_arrow_rounded,
      appLink: 'https://www.youtube.com',
      color: Color(0xFFFF0000),
    ),
    TvAppItem(
      name: 'Netflix',
      icon: Icons.movie_filter_rounded,
      appLink: 'https://www.netflix.com',
      color: Color(0xFFE50914),
    ),
    TvAppItem(
      name: 'Prime Video',
      icon: Icons.video_library_rounded,
      appLink: 'https://www.primevideo.com',
      color: Color(0xFF00A8E1),
    ),
    TvAppItem(
      name: 'Disney+',
      icon: Icons.star_rounded,
      appLink: 'https://www.disneyplus.com',
      color: Color(0xFF113CCF),
    ),
    TvAppItem(
      name: 'Plex',
      icon: Icons.dns_rounded,
      appLink: 'https://plex.tv',
      color: Color(0xFFE5A93B),
    ),
    TvAppItem(
      name: 'Spotify',
      icon: Icons.music_note_rounded,
      appLink: 'https://open.spotify.com',
      color: Color(0xFF1DB954),
    ),
    TvAppItem(
      name: 'Twitch',
      icon: Icons.live_tv_rounded,
      appLink: 'https://www.twitch.tv',
      color: Color(0xFF9146FF),
    ),
    TvAppItem(
      name: 'Hulu',
      icon: Icons.slideshow_rounded,
      appLink: 'https://www.hulu.com',
      color: Color(0xFF1CE783),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: _apps.length,
      itemBuilder: (context, index) {
        final app = _apps[index];
        return _AppCard(app: app, onTap: () => onLaunchApp(app.appLink));
      },
    );
  }
}

class _AppCard extends StatefulWidget {
  const _AppCard({required this.app, required this.onTap});

  final TvAppItem app;
  final VoidCallback onTap;

  @override
  State<_AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<_AppCard> {
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
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised.withValues(alpha: _pressed ? 0.3 : 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed
                ? widget.app.color.withValues(alpha: 0.6)
                : AppTheme.glassButtonBorder,
            width: _pressed ? 1.5 : 1.0,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: widget.app.color.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Ambient color glow corner
              Positioned(
                right: -10,
                bottom: -10,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: widget.app.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.app.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.app.icon,
                        color: widget.app.color,
                        size: 24,
                      ),
                    ),
                    Text(
                      widget.app.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
