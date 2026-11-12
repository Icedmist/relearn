import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../config/app_config.dart';
import '../services/app_prefs.dart';
import 'biometrics.dart';

class SessionLockState {
  const SessionLockState({
    this.locked = false,
    this.biometricsAvailable = false,
    this.biometricsEnabled = false,
    this.busy = false,
    this.error,
  });

  final bool locked;
  final bool biometricsAvailable;
  final bool biometricsEnabled;
  final bool busy;
  final String? error;

  SessionLockState copyWith({
    bool? locked,
    bool? biometricsAvailable,
    bool? biometricsEnabled,
    bool? busy,
    String? error,
    bool clearError = false,
  }) => SessionLockState(
    locked: locked ?? this.locked,
    biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
    biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Owns the inactivity timer and the lock state for the whole app.
///
/// Demo mode and signed-out sessions never lock. In live mode the app locks
/// after [AppConfig.sessionIdleTimeout] of inactivity and can be unlocked with
/// an enrolled fingerprint/face or the account password.
class SessionLockController extends Notifier<SessionLockState> {
  Timer? _timer;
  DateTime _lastActivity = DateTime.now();
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  DateTime? _lastPersisted;
  bool _disposed = false;

  @override
  SessionLockState build() {
    _lastActivity = AppPrefs.lastActiveAt ?? DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => checkNow());
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
    });
    Future<void>(() => _loadAvailability());
    return SessionLockState(biometricsEnabled: AppPrefs.biometricsEnabled);
  }

  bool get _signedIn {
    if (AppConfig.demoMode) return false;
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadAvailability() async {
    final available = await Biometrics.isAvailable();
    if (_disposed) return;
    if (!available && AppPrefs.biometricsEnabled) {
      await AppPrefs.setBiometricsEnabled(false);
    }
    if (_disposed) return;
    state = state.copyWith(
      biometricsAvailable: available,
      biometricsEnabled: available && AppPrefs.biometricsEnabled,
    );
  }

  /// Called whenever the signed-in user touches the screen.
  void recordActivity() {
    final now = DateTime.now();
    _lastActivity = now;
    if (_lastPersisted == null ||
        now.difference(_lastPersisted!) > const Duration(minutes: 1)) {
      _lastPersisted = now;
      AppPrefs.setLastActiveAt(now);
    }
  }

  void onLifecycle(AppLifecycleState value) {
    _lifecycle = value;
    if (value == AppLifecycleState.resumed) {
      final idle = DateTime.now().difference(_lastActivity);
      if (_signedIn && idle >= AppConfig.sessionIdleTimeout) {
        lockNow();
      } else {
        recordActivity();
      }
    } else {
      recordActivity();
      AppPrefs.setLastActiveAt(_lastActivity);
    }
  }

  void checkNow() {
    if (!_signedIn || state.locked) return;
    if (_lifecycle != AppLifecycleState.resumed) return;
    final idle = DateTime.now().difference(_lastActivity);
    if (idle >= AppConfig.sessionIdleTimeout) lockNow();
  }

  void lockNow() {
    if (!_signedIn || state.locked) return;
    state = state.copyWith(locked: true, clearError: true);
    if (state.biometricsEnabled && state.biometricsAvailable) {
      Future<void>.delayed(
        const Duration(milliseconds: 450),
        () => unlockWithBiometrics(),
      );
    }
  }

  Future<bool> unlockWithBiometrics() async {
    if (!state.biometricsAvailable || !state.biometricsEnabled) return false;
    state = state.copyWith(busy: true, clearError: true);
    final ok = await Biometrics.authenticate(reason: 'Unlock ReLearn');
    if (_disposed) return false;
    if (ok) {
      recordActivity();
      state = state.copyWith(locked: false, busy: false, clearError: true);
      return true;
    }
    state = state.copyWith(
      busy: false,
      error: 'Fingerprint not recognised. Try again or use your password.',
    );
    return false;
  }

  /// Returns null on success or a human-readable error.
  Future<String?> unlockWithPassword(String password) async {
    final auth = Supabase.instance.client.auth;
    final email = auth.currentUser?.email;
    if (email == null) return 'No signed-in account found.';
    state = state.copyWith(busy: true, clearError: true);
    try {
      await auth.signInWithPassword(email: email, password: password);
      if (_disposed) return null;
      recordActivity();
      state = state.copyWith(locked: false, busy: false, clearError: true);
      return null;
    } on AuthException catch (error) {
      if (_disposed) return error.message;
      state = state.copyWith(busy: false, error: error.message);
      return error.message;
    } catch (error) {
      final message = 'Could not unlock: $error';
      if (_disposed) return message;
      state = state.copyWith(busy: false, error: message);
      return message;
    }
  }

  /// Returns null on success or a human-readable error.
  Future<String?> setBiometricsEnabled(bool enabled) async {
    if (!enabled) {
      await AppPrefs.setBiometricsEnabled(false);
      state = state.copyWith(biometricsEnabled: false, clearError: true);
      return null;
    }
    if (!state.biometricsAvailable) {
      return 'Fingerprint or face unlock is not set up on this device.';
    }
    final ok = await Biometrics.authenticate(
      reason: 'Enable fingerprint unlock for ReLearn',
    );
    if (!ok) return 'Fingerprint was not confirmed.';
    await AppPrefs.setBiometricsEnabled(true);
    state = state.copyWith(biometricsEnabled: true, clearError: true);
    return null;
  }

  Future<void> reset() async {
    _lastActivity = DateTime.now();
    await AppPrefs.setLastActiveAt(_lastActivity);
    state = state.copyWith(locked: false, busy: false, clearError: true);
  }
}

final sessionLockProvider =
    NotifierProvider<SessionLockController, SessionLockState>(
      SessionLockController.new,
    );

/// Wraps the router and overlays the lock screen when the session expires.
class SessionLockGate extends ConsumerStatefulWidget {
  const SessionLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionLockGate> createState() => _SessionLockGateState();
}

class _SessionLockGateState extends ConsumerState<SessionLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(sessionLockProvider.notifier).onLifecycle(state);
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(sessionLockProvider);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) =>
          ref.read(sessionLockProvider.notifier).recordActivity(),
      child: Stack(
        children: [
          widget.child,
          if (lock.locked) const Positioned.fill(child: _LockOverlay()),
        ],
      ),
    );
  }
}

class _LockOverlay extends ConsumerStatefulWidget {
  const _LockOverlay();

  @override
  ConsumerState<_LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends ConsumerState<_LockOverlay> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_password.text.isEmpty) return;
    setState(() => _submitting = true);
    final error = await ref
        .read(sessionLockProvider.notifier)
        .unlockWithPassword(_password.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      _password.clear();
    }
  }

  Future<void> _signOut() async {
    await ref.read(sessionLockProvider.notifier).reset();
    if (!AppConfig.demoMode) {
      await Supabase.instance.client.auth.signOut();
    }
    ref.invalidate(appStoreProvider);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(sessionLockProvider);
    final theme = Theme.of(context);
    final canUseBiometrics = lock.biometricsAvailable && lock.biometricsEnabled;
    final minutes = AppConfig.sessionIdleTimeout.inMinutes;

    return Material(
      color: AppColors.cream,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BrandLogo(height: 34),
                      const SizedBox(height: 28),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.leaf.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: AppColors.leaf,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Session locked',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ReLearn locked after $minutes minutes of inactivity. '
                        'Unlock to keep using this account.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (canUseBiometrics) ...[
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: lock.busy
                              ? null
                              : () => ref
                                    .read(sessionLockProvider.notifier)
                                    .unlockWithBiometrics(),
                          icon: lock.busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.fingerprint, size: 22),
                          label: const Text('Unlock with fingerprint'),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'or use your password',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _unlock(),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: lock.busy || _submitting ? null : _unlock,
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Unlock'),
                      ),
                      if (lock.error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          lock.error!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _signOut,
                        child: const Text('Sign out instead'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
