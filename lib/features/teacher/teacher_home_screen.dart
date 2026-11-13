import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

/// Read-only landing page for the teacher role.
///
/// Teachers belong to one school. They can review that school's activity and
/// generate a brief, but they cannot record collections or redeem items.
class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStoreProvider);
    final theme = Theme.of(context);
    final profile = state.profile;
    final schoolId = profile?.schoolId;
    final school = schoolId == null ? null : state.schoolById(schoolId);
    final beneficiaries = state.beneficiaries
        .where((b) => schoolId == null || b.schoolId == schoolId)
        .toList();
    final collections = state.collections.toList();
    final kg = collections
        .where((c) => !c.voided)
        .fold(0.0, (sum, c) => sum + c.kg);
    final points = collections
        .where((c) => !c.voided)
        .fold(0, (sum, c) => sum + c.points);

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(height: 30),
        actions: [
          IconButton(
            tooltip: 'Account',
            onPressed: () => context.push('/account'),
            icon: const Icon(Icons.account_circle_outlined, size: 20),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(appStoreProvider.notifier).reload(showLoading: false),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatDateRange(DateTime.now()),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.muted,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Good to see you, '
                                '${(profile?.name ?? 'teacher').split(RegExp(r'\s+')).first}',
                                style: theme.textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                        const StatusPill(
                          label: 'READ ONLY',
                          color: AppColors.sun,
                          icon: Icons.visibility_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      school?.name ?? 'No school linked yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (schoolId == null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Link your school',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'A teacher account needs a school before it can '
                                'show history or briefs.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton(
                                onPressed: () => context.go('/school-setup'),
                                child: const Text('Choose school'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 560;
                          final tiles = [
                            _Tile(
                              label: 'Beneficiaries',
                              value: '${beneficiaries.length}',
                              icon: Icons.people_outline,
                              color: AppColors.leaf,
                            ),
                            _Tile(
                              label: 'Collected',
                              value: '${kg.toStringAsFixed(1)} kg',
                              icon: Icons.scale_outlined,
                              color: AppColors.sky,
                            ),
                            _Tile(
                              label: 'Points earned',
                              value: formatPoints(points),
                              icon: Icons.eco_outlined,
                              color: AppColors.sun,
                            ),
                          ];
                          if (!wide) {
                            return Column(
                              children: [
                                for (var i = 0; i < tiles.length; i++) ...[
                                  tiles[i],
                                  if (i < tiles.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              for (var i = 0; i < tiles.length; i++) ...[
                                Expanded(child: tiles[i]),
                                if (i < tiles.length - 1)
                                  const SizedBox(width: 10),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => context.push('/briefs'),
                              icon: const Icon(
                                Icons.summarize_outlined,
                                size: 19,
                              ),
                              label: const Text('School brief & history'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            onPressed: () =>
                                ref.read(appStoreProvider.notifier).reload(),
                            tooltip: 'Refresh',
                            icon: const Icon(Icons.refresh, size: 20),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(52, 52),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Recent collections',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: collections.isEmpty
                            ? const EmptyState(
                                icon: Icons.recycling_outlined,
                                title: 'No collections yet',
                                message:
                                    'Records appear here as collectors scan '
                                    'cards at your school.',
                              )
                            : Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i <
                                        (collections.length > 6
                                            ? 6
                                            : collections.length);
                                    i++
                                  ) ...[
                                    _ActivityRow(
                                      title:
                                          state
                                              .beneficiaryById(
                                                collections[i].beneficiaryId,
                                              )
                                              ?.name ??
                                          'Unknown beneficiary',
                                      subtitle:
                                          '${collections[i].summary} · '
                                          '${collections[i].collectorName}',
                                      points: collections[i].points,
                                      at: collections[i].at,
                                      voided: collections[i].voided,
                                    ),
                                    if (i <
                                        (collections.length > 6
                                            ? 5
                                            : collections.length - 1))
                                      const Divider(height: 1),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.sky.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 17,
                              color: AppColors.sky,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Teacher accounts are read-only. Ask a '
                                'collector or admin to record collections, '
                                'redeem items or correct points.',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.ink,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => signOutAndGo(context, ref),
                        icon: const Icon(Icons.logout, size: 17),
                        label: const Text('Sign out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.at,
    required this.voided,
  });

  final String title;
  final String subtitle;
  final int points;
  final DateTime at;
  final bool voided;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.recycling, size: 18, color: AppColors.leaf),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (voided) ...[
                      const SizedBox(width: 6),
                      const StatusPill(
                        label: 'VOIDED',
                        color: AppColors.danger,
                      ),
                    ],
                  ],
                ),
                Text(
                  '$subtitle · ${formatDateShort(at)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${formatPoints(points)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.leaf,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
