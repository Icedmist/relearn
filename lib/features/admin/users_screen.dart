import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

class _User {
  _User(
    this.name,
    this.email,
    this.role, {
    this.active = true,
    this.lastActive = 'Today',
  });

  final String name;
  final String email;
  final String role;
  bool active;
  final String lastActive;
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _users = [
    _User('Abdullahi Adamu', 'admin@relearn.app', 'Admin', lastActive: 'Now'),
    _User(
      'Ngozi Okonkwo',
      'ngozi@relearn.app',
      'Admin',
      lastActive: '2 days ago',
    ),
    _User(
      'Musa Bello',
      'musa@relearn.app',
      'Collector',
      lastActive: 'Today, 09:14',
    ),
    _User(
      'Aisha Garba',
      'aisha@relearn.app',
      'Collector',
      lastActive: 'Yesterday',
    ),
    _User(
      'Peter Danjuma',
      'peter@relearn.app',
      'Collector',
      active: false,
      lastActive: '12 days ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Access',
          title: 'Users',
          subtitle: 'Create collectors, reset passwords and deactivate access. Role changes are admin-only.',
          actions: [
            FilledButton.icon(
              onPressed: _showInvite,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Invite user'),
            ),
          ],
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < _users.length; i++) ...[
                _UserRow(
                  user: _users[i],
                  onToggle: () =>
                      setState(() => _users[i].active = !_users[i].active),
                  onReset: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Password reset link sent to ${_users[i].email} (simulated).',
                      ),
                    ),
                  ),
                ),
                if (i < _users.length - 1) const Divider(height: 1),
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

  void _showInvite() {
    final name = TextEditingController();
    final email = TextEditingController();
    String role = 'Collector';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Invite user'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Collector',
                      child: Text('Collector'),
                    ),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  ],
                  onChanged: (value) =>
                      setState(() => role = value ?? 'Collector'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty || !email.text.contains('@')) {
                  return;
                }
                setState(() {
                  _users.add(
                    _User(
                      name.text.trim(),
                      email.text.trim(),
                      role,
                      lastActive: 'Invited',
                    ),
                  );
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Invite sent to ${email.text.trim()} (simulated).',
                    ),
                  ),
                );
              },
              child: const Text('Send invite'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.onToggle,
    required this.onReset,
  });

  final _User user;
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
            initials: user.name
                .split(' ')
                .map((p) => p[0])
                .take(2)
                .join()
                .toUpperCase(),
            color: user.role == 'Admin' ? AppColors.forest : AppColors.leaf,
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user.email,
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
              color: user.role == 'Admin' ? AppColors.forest : AppColors.sky,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.lastActive,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
          StatusPill(
            label: user.active ? 'ACTIVE' : 'INACTIVE',
            color: user.active ? AppColors.leaf : AppColors.muted,
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
                child: Text(
                  user.active ? 'Deactivate user' : 'Reactivate user',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
