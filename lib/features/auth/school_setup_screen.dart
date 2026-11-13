import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';

/// First-run step for every non-admin account: link the staff member to the
/// school they work at. RLS gives a school-less account no history, so this
/// screen is the gate between signing in and using the app.
class SchoolSetupScreen extends ConsumerStatefulWidget {
  const SchoolSetupScreen({super.key});

  @override
  ConsumerState<SchoolSetupScreen> createState() => _SchoolSetupScreenState();
}

class _SchoolSetupScreenState extends ConsumerState<SchoolSetupScreen> {
  String? _schoolId;
  bool _saving = false;

  Future<void> _join() async {
    final schoolId = _schoolId;
    if (schoolId == null) return;
    setState(() => _saving = true);
    final error = await ref
        .read(appStoreProvider.notifier)
        .setMySchool(schoolId);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final role = ref.read(appStoreProvider).profile?.role ?? 'collector';
    context.go(homeForRole(role));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStoreProvider);
    final theme = Theme.of(context);
    final schools = state.schools.where((s) => s.active).toList();
    final profile = state.profile;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(height: 40),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.leaf.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            color: AppColors.leaf,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Choose your school',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${profile?.name ?? 'Your account'} · '
                          '${profile?.roleLabel ?? 'Staff'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Every teacher and collector belongs to one school. '
                          'History, briefs and beneficiary records are limited '
                          'to that school. Ask an admin to move you later.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (schools.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'No active schools are available yet. Ask an '
                              'admin to add your school first.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.danger,
                                height: 1.5,
                              ),
                            ),
                          )
                        else ...[
                          DropdownButtonFormField<String>(
                            initialValue: _schoolId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'School',
                            ),
                            items: [
                              for (final school in schools)
                                DropdownMenuItem(
                                  value: school.id,
                                  child: Text(
                                    school.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _saving
                                ? null
                                : (value) => setState(() => _schoolId = value),
                          ),
                          const SizedBox(height: 12),
                          for (final school in schools)
                            if (_schoolId == school.id)
                              Text(
                                school.address,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _schoolId == null || _saving
                                  ? null
                                  : _join,
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Join this school'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _saving
                                ? null
                                : () => signOutAndGo(context, ref),
                            child: const Text('Sign out'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
