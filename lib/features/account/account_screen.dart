import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/session.dart';
import '../../core/auth/session_lock.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  String _name(WidgetRef ref) {
    final state = ref.watch(appStoreProvider);
    if (state.profile?.name.trim().isNotEmpty == true) {
      return state.profile!.name;
    }
    if (AppConfig.demoMode) return 'Demo staff';
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata?['name'];
    if (meta is String && meta.trim().isNotEmpty) return meta;
    return user?.email?.split('@').first ?? 'Staff';
  }

  String _email(WidgetRef ref) {
    final state = ref.watch(appStoreProvider);
    if (state.profile?.email.trim().isNotEmpty == true) {
      return state.profile!.email;
    }
    if (AppConfig.demoMode) return 'demo@relearn.app';
    return Supabase.instance.client.auth.currentUser?.email ?? '';
  }

  String _role(WidgetRef ref) {
    final state = ref.watch(appStoreProvider);
    if (state.profile != null) return state.profile!.roleLabel;
    return AppConfig.demoMode ? 'Demo account' : 'Staff';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(sessionLockProvider);
    final theme = Theme.of(context);
    final name = _name(ref);
    final email = _email(ref);
    final role = _role(ref);
    final profile = ref.watch(appStoreProvider).profile;
    final admin = profile?.isAdmin ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(homeForRole(profile?.role ?? 'collector'));
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        InitialsAvatar(initials: _initials(name), size: 58),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: theme.textTheme.titleLarge),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              StatusPill(
                                label: role.toUpperCase(),
                                icon: admin
                                    ? Icons.admin_panel_settings_outlined
                                    : profile?.isTeacher == true
                                    ? Icons.school_outlined
                                    : Icons.qr_code_scanner,
                              ),
                              if (profile?.schoolName != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  profile!.schoolName!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit name',
                          onPressed: () => _editName(context, ref, name),
                          icon: const Icon(Icons.edit_outlined, size: 19),
                        ),
                      ],
                    ),
                  ),
                ),
                if (AppConfig.demoMode) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sun.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.sun.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.science_outlined,
                          size: 18,
                          color: Color(0xFF7A4F00),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Demo mode uses sample records. Changes are not saved '
                            'and security settings are disabled.',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF7A4F00),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Security',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.password_outlined,
                          color: AppColors.leaf,
                        ),
                        title: const Text('Change password'),
                        subtitle: const Text(
                          'Use at least 6 characters. You stay signed in.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _changePassword(context, ref),
                      ),
                      const Divider(height: 1),
                      if (!kIsWeb)
                        SwitchListTile(
                          secondary: Icon(
                            Icons.fingerprint,
                            color: lock.biometricsEnabled
                                ? AppColors.leaf
                                : AppColors.muted,
                          ),
                          title: const Text('Fingerprint unlock'),
                          subtitle: Text(
                            lock.biometricsAvailable
                                ? 'Unlock ReLearn with your fingerprint or face.'
                                : 'No fingerprint or face is set up on this device.',
                          ),
                          value: lock.biometricsEnabled,
                          onChanged: lock.biometricsAvailable || lock.busy
                              ? (value) =>
                                    _toggleBiometrics(context, ref, value)
                              : null,
                        )
                      else
                        const ListTile(
                          leading: Icon(
                            Icons.lock_clock_outlined,
                            color: AppColors.muted,
                          ),
                          title: Text('Password unlock'),
                          subtitle: Text(
                            'The web app uses your password to unlock an expired session.',
                          ),
                        ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.timer_outlined,
                          color: AppColors.leaf,
                        ),
                        title: const Text('Session lock'),
                        subtitle: Text(
                          'Locks after '
                          '${AppConfig.sessionIdleTimeout.inMinutes} minutes of '
                          'inactivity. Unlock with '
                          '${lock.biometricsEnabled ? 'fingerprint or password' : 'your password'}.',
                        ),
                        trailing: AppConfig.demoMode
                            ? null
                            : OutlinedButton(
                                onPressed: () => ref
                                    .read(sessionLockProvider.notifier)
                                    .lockNow(),
                                child: const Text('Lock now'),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'App',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.summarize_outlined,
                          color: AppColors.leaf,
                        ),
                        title: const Text('Briefs & history'),
                        subtitle: Text(
                          admin
                              ? 'Copy a programme or school brief and review '
                                    'every transaction.'
                              : 'Copy a school brief and review your school’s '
                                    'transactions.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/briefs'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.menu_book_outlined,
                          color: AppColors.leaf,
                        ),
                        title: const Text('How to use ReLearn'),
                        subtitle: const Text(
                          'Replay the collection and redemption guide.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/onboarding?next=/account'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.info_outline,
                          color: AppColors.muted,
                        ),
                        title: const Text('Version'),
                        subtitle: Text(
                          'v${AppConfig.version} · ${AppConfig.tagline}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _signOut(context, ref),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    if (AppConfig.demoMode) {
      _notify(
        context,
        'Name changes are available when Supabase is connected.',
      );
      return;
    }
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit your name'),
        content: SizedBox(
          width: 380,
          child: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == current) return;
    final error = await ref
        .read(appStoreProvider.notifier)
        .updateProfileName(name);
    if (!context.mounted) return;
    _notify(context, error ?? 'Name updated.');
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    if (AppConfig.demoMode) {
      _notify(
        context,
        'Password changes are available when Supabase is connected.',
      );
      return;
    }
    final newPassword = await showDialog<String>(
      context: context,
      builder: (_) => const _PasswordDialog(),
    );
    if (newPassword == null) return;
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (!context.mounted) return;
      _notify(context, 'Password updated.');
    } on AuthException catch (error) {
      if (!context.mounted) return;
      _notify(context, error.message);
    } catch (error) {
      if (!context.mounted) return;
      _notify(context, 'Could not update password: $error');
    }
  }

  Future<void> _toggleBiometrics(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final error = await ref
        .read(sessionLockProvider.notifier)
        .setBiometricsEnabled(value);
    if (!context.mounted) return;
    _notify(
      context,
      error ??
          (value
              ? 'Fingerprint unlock enabled.'
              : 'Fingerprint unlock disabled.'),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need your email and password to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await signOutAndGo(context, ref);
    }
  }

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                  ),
                ),
                validator: (value) => (value ?? '').length < 6
                    ? 'Use at least 6 characters.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (value) =>
                    value != _password.text ? 'Passwords do not match.' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(context, _password.text);
          },
          child: const Text('Update password'),
        ),
      ],
    );
  }
}
