import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

class _NavItem {
  const _NavItem(this.path, this.icon, this.selectedIcon, this.label);

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _items = [
  _NavItem(
    '/admin/dashboard',
    Icons.grid_view_outlined,
    Icons.grid_view_rounded,
    'Dashboard',
  ),
  _NavItem(
    '/admin/schools',
    Icons.school_outlined,
    Icons.school_rounded,
    'Schools',
  ),
  _NavItem(
    '/admin/beneficiaries',
    Icons.people_outline,
    Icons.people_rounded,
    'Beneficiaries',
  ),
  _NavItem(
    '/admin/print',
    Icons.print_outlined,
    Icons.print_rounded,
    'Print cards',
  ),
  _NavItem(
    '/admin/materials',
    Icons.recycling_outlined,
    Icons.recycling_rounded,
    'Materials & points',
  ),
  _NavItem(
    '/admin/rewards',
    Icons.card_giftcard_outlined,
    Icons.card_giftcard_rounded,
    'Rewards & stock',
  ),
  _NavItem(
    '/admin/reports',
    Icons.insert_chart_outlined,
    Icons.insert_chart_rounded,
    'Reports',
  ),
  _NavItem(
    '/admin/users',
    Icons.manage_accounts_outlined,
    Icons.manage_accounts_rounded,
    'Users',
  ),
];

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _index {
    final i = _items.indexWhere((item) => location.startsWith(item.path));
    return i < 0 ? 0 : i;
  }

  void _go(BuildContext context, int index) => context.go(_items[index].path);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 940;
        final content = SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 32 : 20,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: child,
            ),
          ),
        );

        if (wide) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    extended: constraints.maxWidth >= 1180,
                    minExtendedWidth: 236,
                    selectedIndex: _index,
                    onDestinationSelected: (i) => _go(context, i),
                    leading: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      child: constraints.maxWidth >= 1180
                          ? const BrandLogo(height: 34)
                          : const BrandLogo(height: 34, horizontal: false),
                    ),
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 18,
                            left: 8,
                            right: 8,
                          ),
                          child: _SidebarFooter(
                            extended: constraints.maxWidth >= 1180,
                          ),
                        ),
                      ),
                    ),
                    destinations: [
                      for (final item in _items)
                        NavigationRailDestination(
                          icon: Icon(item.icon, size: 21),
                          selectedIcon: Icon(item.selectedIcon, size: 21),
                          label: Text(item.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Column(
                      children: [
                        _AdminTopBar(compact: false),
                        Expanded(child: content),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const BrandLogo(height: 30),
            actions: [
              IconButton(
                tooltip: 'Account',
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.account_circle_outlined),
              ),
            ],
          ),
          drawer: Drawer(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: BrandLogo(height: 34),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          ListTile(
                            selected: i == _index,
                            selectedTileColor: const Color(0xFFD9F2E2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Icon(
                              i == _index
                                  ? _items[i].selectedIcon
                                  : _items[i].icon,
                            ),
                            title: Text(_items[i].label),
                            onTap: () {
                              Navigator.pop(context);
                              _go(context, i);
                            },
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign out'),
                    onTap: () => context.go('/login'),
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(child: content),
        );
      },
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          const StatusPill(
            label: 'DEMO DATA',
            color: AppColors.sky,
            icon: Icons.science_outlined,
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            Text(
              'Stage 0 scaffold · v${AppConfig.version}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
          ],
          const Spacer(),
          IconButton(
            tooltip: 'Switch to collector app',
            onPressed: () => context.go('/collector/home'),
            icon: const Icon(Icons.qr_code_scanner, size: 20),
          ),
          const SizedBox(width: 4),
          const InitialsAvatar(initials: 'AA', size: 34),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Abdullahi A.',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                'Programme admin',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.logout, size: 19),
          ),
        ],
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (extended)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.leaf.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Demo data only.\nConnect Supabase in Stage 1.',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppColors.forest, height: 1.4),
            ),
          ),
        const SizedBox(height: 8),
        IconButton(
          tooltip: 'Switch to collector app',
          onPressed: () => context.go('/collector/home'),
          icon: const Icon(Icons.qr_code_scanner, size: 20),
        ),
      ],
    );
  }
}
