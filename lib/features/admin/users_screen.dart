import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _demoUsers = <StaffUser>[
    const StaffUser(
      id: 'usr-1',
      name: 'Abdullahi Adamu',
      email: 'admin@relearn.app',
      role: 'admin',
      active: true,
    ),
    const StaffUser(
      id: 'usr-2',
      name: 'Ngozi Okonkwo',
      email: 'ngozi@relearn.app',
      role: 'admin',
      active: true,
    ),
    const StaffUser(
      id: 'usr-3',
      name: 'Musa Bello',
      email: 'musa@relearn.app',
      role: 'collector',
      active: true,
    ),
    const StaffUser(
      id: 'usr-4',
      name: 'Aisha Garba',
      email: 'aisha@relearn.app',
      role: 'collector',
      active: true,
    ),
    const StaffUser(
      id: 'usr-5',
      name: 'Peter Danjuma',
      email: 'peter@relearn.app',
      role: 'collector',
      active: false,
    ),
  ];
  final _demoActive = <String, bool>{};

  bool get _live => !AppConfig.demoMode;

  @override
  void initState() {
    super.initState();
    for (final user in _demoUsers) {
      _demoActive[user.id] = user.active;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStoreProvider);
    final users = _live ? state.users : _demoUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Access',
          title: 'Users',
          subtitle: 'Staff accounts live in Supabase Auth. Roles and access are stored in profiles and enforced by RLS.',
          actions: [
            FilledButton.icon(
              onPressed: _showInvite,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: Text(_live ? 'How to add a user' : 'Invite user'),
            ),
          ],
        ),
        Card(
          child: users.isEmpty
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: 'No staff accounts',
                  message: 'Create users in Supabase Auth and assign a role in profiles.',
                )
              : Column(
                  children: [
                    for (var i = 0; i < users.length; i++) ...[
                      _UserRow(
                        user: users[i],
                        active: _active(users[i]),
                        onToggle: () => _toggle(users[i]),
                        onReset: () => _reset(users[i]),
                      ),
                      if (i < users.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline, size: 18, color: AppColors.leaf),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Collectors can only scan, record and redeem. They cannot change rates, view admin reports or delete history. '
                    'Row Level Security enforces this on the server, not just in the UI.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _active(StaffUser user) =>
      _live ? user.active : (_demoActive[user.id] ?? user.active);

  void _toggle(StaffUser user) {
    final next = !_active(user);
    if (_live) {
      ref.read(appStoreProvider.notifier).setStaffActive(user.id, next);
    } else {
      setState(() => _demoActive[user.id] = next);
    }
  }

  Future<void> _reset(StaffUser user) async {
    if (!_live) {
      _notify('Password reset link sent to ${user.email} (simulated).');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(user.email);
      _notify('Password reset link sent to ${user.email}.');
    } on AuthException catch (error) {
      _notify(error.message);
    } catch (error) {
      _notify('Could not send the reset email: $error');
    }
  }

  void _showInvite() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_live ? 'Add a staff user' : 'Invite user'),
        content: SizedBox(
          width: 400,
          child: Text(
            _live
                ? 'Create the account in Supabase → Authentication → Users, then set the role in the profiles table:\n\n'
                      "update public.profiles set role = 'collector' where id = '<user-id>';\n\n"
                      'Accounts are never created by the client, so nobody can self-assign an admin role.'
                : 'Demo mode keeps accounts in memory. In live mode, accounts are created in Supabase Auth and roles are assigned in profiles.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.active,
    required this.onToggle,
    required this.onReset,
  });

  final StaffUser user;
  final bool active;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          InitialsAvatar(
            initials: _initials(user.name),
            color: user.isAdmin ? AppColors.forest : AppColors.leaf,
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: StatusPill(
              label: user.role.toUpperCase(),
              color: user.isAdmin ? AppColors.forest : AppColors.sky,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _lastActive(user),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
          StatusPill(
            label: active ? 'ACTIVE' : 'INACTIVE',
            color: active ? AppColors.leaf : AppColors.muted,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') onReset();
              if (value == 'toggle') onToggle();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Text('Send password reset'),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Text(active ? 'Deactivate user' : 'Reactivate user'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static String _lastActive(StaffUser user) {
    final at = user.lastActive;
    if (at == null) return 'Never';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 5) return 'Now';
    if (diff.inHours < 24) {
      final time =
          '${at.hour.toString().padLeft(2, '0')}:'
          '${at.minute.toString().padLeft(2, '0')}';
      return 'Today, $time';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
