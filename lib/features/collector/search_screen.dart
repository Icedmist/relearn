import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/demo_data.dart';

class CollectorSearchScreen extends ConsumerStatefulWidget {
  const CollectorSearchScreen({super.key});

  @override
  ConsumerState<CollectorSearchScreen> createState() =>
      _CollectorSearchScreenState();
}

class _CollectorSearchScreenState extends ConsumerState<CollectorSearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(demoStoreProvider);
    final results = _query.isEmpty
        ? state.beneficiaries
        : state.beneficiaries.where((b) {
            final q = _query.toLowerCase();
            final school =
                state.schoolById(b.schoolId)?.name.toLowerCase() ?? '';
            return b.name.toLowerCase().contains(q) ||
                b.publicId.toLowerCase().contains(q) ||
                school.contains(q);
          }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find a beneficiary',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Use this when a card is lost, damaged or unreadable.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          TextField(
            autofocus: true,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Name, ID or school',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => _query = ''),
                      icon: const Icon(Icons.close, size: 18),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                _query.isEmpty
                    ? 'Recent beneficiaries'
                    : '${results.length} result(s)',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: AppColors.muted),
              ),
              const Spacer(),
              const Text(
                'Tap to open',
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (results.isEmpty)
            const Card(
              child: EmptyState(
                icon: Icons.search_off,
                title: 'No match',
                message: 'Check the spelling, or search for the school name instead.',
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < results.length; i++) ...[
                    InkWell(
                      onTap: () => context.push(
                        '/collector/beneficiary/${results[i].id}',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            InitialsAvatar(
                              initials: results[i].initials(),
                              color: results[i].cardBlocked
                                  ? AppColors.muted
                                  : AppColors.leaf,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          results[i].name,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      if (results[i].cardBlocked) ...[
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.block,
                                          size: 13,
                                          color: AppColors.danger,
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${results[i].publicId} · ${state.schoolById(results[i].schoolId)?.name ?? ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            BalancePill(points: results[i].balance),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < results.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sky.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  size: 18,
                  color: AppColors.sky,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Manual search is always available. A blocked card still opens the profile, '
                    'but collections and redemptions are disabled.',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.ink, height: 1.4),
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
