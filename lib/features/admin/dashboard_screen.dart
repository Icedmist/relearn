import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStoreProvider);
    final theme = Theme.of(context);
    final lowStock = state.rewards.where((r) => r.stock <= 10).toList();

    final activity =
        <
            ({
              DateTime at,
              String title,
              String subtitle,
              IconData icon,
              Color color,
            })
          >[
            for (final c in state.collections)
              (
                at: c.at,
                title:
                    state.beneficiaryById(c.beneficiaryId)?.name ?? 'Unknown',
                subtitle:
                    '${c.summary} · +${formatPoints(c.points)} pts · ${c.collectorName}',
                icon: Icons.recycling,
                color: AppColors.leaf,
              ),
            for (final r in state.redemptions)
              (
                at: r.at,
                title:
                    state.beneficiaryById(r.beneficiaryId)?.name ?? 'Unknown',
                subtitle:
                    '${r.rewardName} × ${r.qty} · −${formatPoints(r.points)} pts',
                icon: Icons.card_giftcard,
                color: AppColors.sun,
              ),
          ]
          ..sort((a, b) => b.at.compareTo(a.at));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Overview',
          title: 'Good morning, Abdullahi',
          subtitle:
              '${formatDateRange(DateTime.now())} · Gombe pilot programme',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/admin/reports'),
              icon: const Icon(Icons.insert_chart_outlined, size: 18),
              label: const Text('View reports'),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/admin/beneficiaries/new'),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Register beneficiary'),
            ),
          ],
        ),
        if (lowStock.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sun.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sun.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF7A4F00),
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Low stock: ${lowStock.map((r) => '${r.name} (${r.stock})').join(', ')}. Restock before the next visit.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7A4F00),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/admin/rewards'),
                  child: const Text('Restock'),
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 5
                : constraints.maxWidth >= 700
                ? 3
                : 2;
            const gap = 12.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            final cards = [
              KpiCard(
                label: 'Active beneficiaries',
                value: formatPoints(state.totalBeneficiaries),
                icon: Icons.people_alt_outlined,
                hint: '+12 this week',
              ),
              KpiCard(
                label: 'Collected this month',
                value: '${formatPoints(state.totalKg.round())} kg',
                icon: Icons.scale_outlined,
                hint: '+8.4%',
                accent: AppColors.sky,
              ),
              KpiCard(
                label: 'Points awarded',
                value: formatPoints(state.pointsAwarded),
                icon: Icons.eco_outlined,
                hint: 'all time',
                accent: AppColors.leaf,
              ),
              KpiCard(
                label: 'Points redeemed',
                value: formatPoints(state.pointsRedeemed),
                icon: Icons.redeem_outlined,
                hint: 'all time',
                accent: AppColors.sun,
              ),
              KpiCard(
                label: 'Rewards distributed',
                value: formatPoints(state.rewardsDistributed),
                icon: Icons.card_giftcard_outlined,
                hint: 'all time',
                accent: AppColors.forest,
              ),
            ];
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final card in cards) SizedBox(width: width, child: card),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final chart = _CollectionsChart(collections: state.collections);
            final materials = _TopMaterials(
              materials: state.materials,
              collections: state.collections,
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: chart),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: materials),
                ],
              );
            }
            return Column(
              children: [chart, const SizedBox(height: 16), materials],
            );
          },
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Recent activity',
          subtitle: 'Collections and redemptions across all schools',
          action: TextButton(
            onPressed: () => context.go('/admin/reports'),
            child: const Text('See all'),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            children: [
              for (final a in activity.take(6))
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    final match = state.beneficiaries.where(
                      (b) => b.name == a.title,
                    );
                    if (match.isNotEmpty) {
                      context.go('/admin/beneficiaries/${match.first.id}');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: a.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(a.icon, size: 18, color: a.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                a.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatDateShort(a.at),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollectionsChart extends StatelessWidget {
  const _CollectionsChart({required this.collections});

  final List<CollectionRecord> collections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i)),
    );
    final totals = [
      for (final day in days)
        collections
            .where(
              (c) =>
                  c.at.year == day.year &&
                  c.at.month == day.month &&
                  c.at.day == day.day &&
                  !c.voided,
            )
            .fold(0, (s, c) => s + c.points),
    ];
    final max = totals.fold(0, (m, v) => v > m ? v : m).clamp(1, 1 << 30);

    return SectionCard(
      title: 'Collections over time',
      subtitle: 'Points awarded per day · last 7 days',
      child: SizedBox(
        height: 200,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        totals[i] == 0 ? '' : formatPoints(totals[i]),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: (totals[i] / max).clamp(0.04, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: i == days.length - 1
                                  ? AppColors.leaf
                                  : const Color(0xFFBFE6CE),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ][days[i].weekday - 1],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopMaterials extends StatelessWidget {
  const _TopMaterials({required this.materials, required this.collections});

  final List<MaterialItem> materials;
  final List<CollectionRecord> collections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = <String, double>{
      for (final m in materials.where((m) => m.allowed))
        m.name: collections
            .where((c) => c.summary.startsWith(m.name) && !c.voided)
            .fold(0.0, (s, c) => s + c.kg + (c.points / 10)),
    };
    final max = totals.values.fold(1.0, (m, v) => v > m ? v : m);

    return SectionCard(
      title: 'Top materials',
      subtitle: 'By volume this month',
      child: Column(
        children: [
          for (final entry in totals.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        entry.value.toStringAsFixed(1),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (entry.value / max).clamp(0.02, 1.0),
                      minHeight: 7,
                      backgroundColor: AppColors.line,
                      color: AppColors.leaf,
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
