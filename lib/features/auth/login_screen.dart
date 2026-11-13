import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/session_lock.dart';
import '../../core/config/app_config.dart';
import '../../core/services/app_prefs.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(
    text: AppConfig.demoMode ? 'admin@relearn.app' : '',
  );
  final _password = TextEditingController(
    text: AppConfig.demoMode ? 'relearn123' : '',
  );
  bool _obscure = true;
  bool _loading = false;
  bool _isAdmin = true;

  bool get _live => !AppConfig.demoMode;

  @override
  void initState() {
    super.initState();
    if (_live) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) return;
    try {
      final role = await _currentRole();
      await ref.read(appStoreProvider.notifier).reload();
      if (!mounted) return;
      final store = ref.read(appStoreProvider);
      if (role == null || store.profile == null || store.error != null) {
        await _expireSession(
          store.error ?? 'Your profile could not be loaded. Sign in again.',
        );
        return;
      }
      ref.read(sessionLockProvider.notifier).recordActivity();
      await _goAfterAuth(role);
    } catch (error) {
      if (!mounted) return;
      await _expireSession('Your session expired. Sign in again.');
    }
  }

  /// Clears a stale or incomplete session instead of opening a broken screen.
  Future<void> _expireSession(String message) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // The local session is invalid either way.
    }
    ref.invalidate(appStoreProvider);
    if (!mounted) return;
    _notify(message);
  }

  Future<void> _goAfterAuth(String role) async {
    final home = role == 'admin' ? '/admin/dashboard' : '/collector/home';
    if (!AppPrefs.onboardingSeen) {
      context.go('/onboarding?next=${Uri.encodeQueryComponent(home)}');
      return;
    }
    context.go(home);
  }

  Future<void> _openGuide() async {
    // The guide is public. It always returns to login; the signed-in role is
    // resolved after authentication, never from a toggle on this screen.
    context.push('/onboarding');
  }

  Future<String?> _currentRole() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client
        .from('profiles')
        .select('role, active')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null || row['active'] == false) return null;
    return row['role'] as String?;
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    if (!_live) {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      await _goAfterAuth(_isAdmin ? 'admin' : 'collector');
      return;
    }

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      final role = await _currentRole();
      if (role == null) {
        await _expireSession(
          'This account has no active staff profile. Contact an admin.',
        );
        return;
      }
      await ref.read(appStoreProvider.notifier).reload();
      if (!mounted) return;
      final store = ref.read(appStoreProvider);
      if (store.error != null || store.profile == null) {
        await _expireSession(
          store.error ?? 'Your profile could not be loaded. Try again.',
        );
        return;
      }
      ref.read(sessionLockProvider.notifier).recordActivity();
      await _goAfterAuth(role);
    } on AuthException catch (error) {
      _notify(error.message);
    } catch (error) {
      _notify('Could not sign in: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_live) {
      _notify('Password reset is available when Supabase is connected.');
      return;
    }
    if (_email.text.trim().isEmpty) {
      _notify('Enter your email first.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _email.text.trim(),
      );
      _notify('Password reset link sent to ${_email.text.trim()}.');
    } on AuthException catch (error) {
      _notify(error.message);
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = _LoginForm(
            formKey: _formKey,
            email: _email,
            password: _password,
            obscure: _obscure,
            loading: _loading,
            isAdmin: _isAdmin,
            live: _live,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
            onRoleChanged: (admin) => setState(() => _isAdmin = admin),
            onSubmit: _signIn,
            onForgotPassword: _resetPassword,
            onOpenGuide: _openGuide,
          );
          if (!wide) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandLogo(height: 40),
                    const SizedBox(height: 32),
                    form,
                  ],
                ),
              ),
            );
          }
          return Row(
            children: [
              const Expanded(child: _BrandPanel()),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 56,
                      vertical: 40,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: form,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.forest, AppColors.leaf],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sun.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandLogo(height: 52, onDark: true),
                const Spacer(),
                Text(
                  'Waste in.\nSchool supplies out.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 46,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    'ReLearn turns everyday recyclables into points, and points into '
                    'pencils and exercise books. One printed card. No app for pupils. '
                    'Works on the cheapest Android phone.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _FeatureChip(icon: Icons.qr_code_2, label: 'Scan a card'),
                    _FeatureChip(
                      icon: Icons.eco_outlined,
                      label: 'Credit points',
                    ),
                    _FeatureChip(
                      icon: Icons.menu_book_outlined,
                      label: 'Redeem books',
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Pilot build · ${AppConfig.version}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
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

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.sun),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.email,
    required this.password,
    required this.obscure,
    required this.loading,
    required this.isAdmin,
    required this.live,
    required this.onToggleObscure,
    required this.onRoleChanged,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onOpenGuide,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final bool loading;
  final bool isAdmin;
  final bool live;
  final VoidCallback onToggleObscure;
  final ValueChanged<bool> onRoleChanged;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'v${AppConfig.version}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Welcome back', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(
            live
                ? 'Sign in with your programme account.'
                : 'Sign in to the programme dashboard or the collector app.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          if (!live) ...[
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Admin'),
                  icon: Icon(Icons.dashboard_outlined),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Collector'),
                  icon: Icon(Icons.qr_code_scanner),
                ),
              ],
              selected: {isAdmin},
              onSelectionChanged: (value) => onRoleChanged(value.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.comfortable,
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.leaf.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: AppColors.leaf,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your admin or collector role is assigned by the programme admin.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your email';
              }
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: password,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
            ),
            validator: (value) => value == null || value.length < 6
                ? 'Password must be at least 6 characters'
                : null,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading ? null : onSubmit,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      live
                          ? 'Sign in'
                          : isAdmin
                          ? 'Sign in as admin'
                          : 'Sign in as collector',
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: onOpenGuide,
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('How ReLearn works'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'By signing in you agree to the pilot data protection policy. '
            'Only authorised programme staff can access beneficiary records.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
