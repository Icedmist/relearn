import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/services/app_prefs.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.next});

  /// Where to go after the guide. Defaults to the login screen.
  final String? next;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _GuidePage(
      icon: Icons.eco_outlined,
      accent: AppColors.leaf,
      eyebrow: 'Welcome',
      title: 'Recycle to Learn.',
      body:
          'ReLearn turns everyday recyclables into points, and points into '
          'the pencils, books and bags pupils need for class.',
      points: [
        'One printed card for every pupil',
        'No smartphone needed for pupils',
        'Works on low-cost Android phones',
      ],
    ),
    _GuidePage(
      icon: Icons.qr_code_scanner,
      accent: AppColors.sky,
      eyebrow: 'Collect',
      title: 'Scan. Weigh. Credit points.',
      body:
          'At the collection desk, open the scanner, read the pupil card, '
          'then record the materials they brought.',
      points: [
        'Scan the QR card or enter the public ID',
        'Weigh paper or count bottles and cans',
        'Points are credited to the card instantly',
      ],
    ),
    _GuidePage(
      icon: Icons.storefront_outlined,
      accent: Color(0xFF9A3E8F),
      eyebrow: 'Redeem',
      title: 'Spend points in the item shop.',
      body:
          'The shop shows real stock and real prices. Choose an item, check '
          'the balance, then confirm the redemption.',
      points: [
        'Browse by category or search for an item',
        'Stock and points are checked before saving',
        'Every collection and redemption is recorded',
      ],
    ),
    _GuidePage(
      icon: Icons.admin_panel_settings_outlined,
      accent: AppColors.forest,
      eyebrow: 'For staff',
      title: 'Admin and collector tools.',
      body:
          'Admins manage schools, beneficiaries, stock and staff accounts. '
          'Collectors work on the ground with the same sign-in.',
      points: [
        'Role-based access enforced by the database',
        'Account centre with password and fingerprint unlock',
        'The session locks after 15 minutes of inactivity',
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _next {
    final next = widget.next;
    if (next == null || !next.startsWith('/') || next == '/onboarding') {
      return '/login';
    }
    return next;
  }

  Future<void> _finish() async {
    await AppPrefs.setOnboardingSeen(true);
    if (mounted) context.go(_next);
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                children: [
                  const BrandLogo(height: 30),
                  const Spacer(),
                  TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => _PageBody(page: _pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _page ? AppColors.leaf : AppColors.line,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_page > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _goTo(_page - 1),
                            child: const Text('Back'),
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: last ? _finish : () => _goTo(_page + 1),
                          child: Text(last ? 'Get started' : 'Next'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'v${AppConfig.version} · ${AppConfig.tagline}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePage {
  const _GuidePage({
    required this.icon,
    required this.accent,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.points,
  });

  final IconData icon;
  final Color accent;
  final String eyebrow;
  final String title;
  final String body;
  final List<String> points;
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page});

  final _GuidePage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: page.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(page.icon, size: 44, color: page.accent),
              ),
              const SizedBox(height: 28),
              Text(
                page.eyebrow.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: page.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(page.title, style: theme.textTheme.headlineLarge),
              const SizedBox(height: 14),
              Text(
                page.body,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      for (var i = 0; i < page.points.length; i++) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: page.accent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 15,
                                color: page.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  page.points[i],
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (i < page.points.length - 1)
                          const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
