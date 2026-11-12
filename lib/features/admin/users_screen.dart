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
  bool _creating = false;

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
          subtitle: 'Create staff accounts and set their role. Access is enforced by Row Level Security, not just the UI.',
          actions: [
            FilledButton.icon(
              onPressed: _creating ? null : _createUser,
              icon: _creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1, size: 18),
              label: Text(_creating ? 'Creating…' : 'Add user'),
            ),
          ],
        ),
        Card(
          child: users.isEmpty
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: 'No staff accounts',
                  message: 'Add a user to create the first account.',
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
      _notify('Password reset is not available in demo mode.');
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

  Future<void> _createUser() async {
    final input = await showDialog<_NewStaff>(
      context: context,
      builder: (_) => const _CreateUserDialog(),
    );
    if (input == null || !mounted) return;

    if (!_live) {
      final user = StaffUser(
        id: 'usr-${_demoUsers.length + 1}',
        name: input.name,
        email: input.email,
        role: input.role,
        active: true,
      );
      setState(() {
        _demoUsers.insert(0, user);
        _demoActive[user.id] = true;
      });
      _notify('Account created for ${input.email}.');
      return;
    }

    setState(() => _creating = true);
    final error = await ref
        .read(appStoreProvider.notifier)
        .createStaffUser(
          name: input.name,
          email: input.email,
          password: input.password,
          role: input.role,
        );
    if (!mounted) return;
    setState(() => _creating = false);
    _notify(
      error ??
          'Account created for ${input.email}. '
              'Share the temporary password securely.',
    );
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NewStaff {
  const _NewStaff({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  final String name;
  final String email;
  final String password;
  final String role;
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'collector';
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _NewStaff(
        name: _name.text.trim(),
        email: _email.text.trim().toLowerCase(),
        password: _password.text,
        role: _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Create staff account'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The account can sign in immediately. Share the temporary '
                  'password securely and ask them to change it.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    hintText: 'e.g. Musa Bello',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Enter the staff member’s name.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'name@relearn.app',
                  ),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email);
                    return valid ? null : 'Enter a valid email address.';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Temporary password',
                    hintText: 'At least 8 characters',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => (value ?? '').length < 8
                      ? 'Use at least 8 characters.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                      value: 'collector',
                      child: Text('Collector — scan, record, redeem'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin — full access'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _role = value ?? 'collector'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create account')),
      ],
    );
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
