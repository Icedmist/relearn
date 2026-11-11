import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

class CollectorShell extends StatelessWidget {
  const CollectorShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  int get _index {
    if (location.startsWith('/collector/search')) return 1;
    if (location.startsWith('/collector/history')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 480;
    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(height: 30),
        actions: [
          if (narrow)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.science_outlined,
                size: 20,
                color: AppColors.sky,
              ),
            )
          else
            StatusPill(
              label: 'DEMO · v${AppConfig.version}',
              color: AppColors.sky,
              icon: Icons.science_outlined,
            ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Admin dashboard',
            onPressed: () => context.go('/admin/dashboard'),
            icon: const Icon(Icons.dashboard_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.logout, size: 19),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          context.go(switch (index) {
            1 => '/collector/search',
            2 => '/collector/history',
            _ => '/collector/home',
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
