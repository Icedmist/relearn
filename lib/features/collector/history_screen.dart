import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class CollectorHistoryScreen extends ConsumerWidget {
  const CollectorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStoreProvider);
    final activity =
        <
            ({
              DateTime at,
              bool collection,
              String title,
              String subtitle,
              int points,
              bool voided,
            })
          >[
            for (final c in state.collections)
              (
                at: c.at,
                collection: true,
                title:
                    state.beneficiaryById(c.beneficiaryId)?.name ?? 'Unknown',
                subtitle: c.summary,
                points: c.points,
                voided: c.voided,
              ),
            for (final r in state.redemptions)
              (
                at: r.at,
                collection: false,
                title:
                    state.beneficiaryById(r.beneficiaryId)?.name ?? 'Unknown',
                subtitle: '${r.rewardName} × ${r.qty}',
                points: -r.points,
                voided: r.voided,
              ),
          ]
          ..sort((a, b) => b.at.compareTo(a.at));

    final points = activity
        .where((a) => a.collection && !a.voided)
        .fold(0, (s, a) => s + a.points);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'History',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const StatusPill(
                label: 'ALL SYNCED',
                color: AppColors.leaf,
                icon: Icons.cloud_done_outlined,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'All transactions from this device',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  value: '${activity.where((a) => a.collection).length}',
                  label: 'Collections',
                  color: AppColors.leaf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  value: formatPoints(points),
                  label: 'Points earned',
                  color: AppColors.sun,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  value: '${activity.where((a) => !a.collection).length}',
                  label: 'Redeemed',
                  color: AppColors.sky,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < activity.length; i++) ...[
                  _TransactionRow(
                    title: activity[i].title,
                    subtitle: activity[i].subtitle,
                    points: activity[i].points,
                    at: activity[i].at,
                    collection: activity[i].collection,
                    voided: activity[i].voided,
                    onVoid: () => _requestVoid(context, activity[i].title),
                  ),
                  if (i < activity.length - 1) const Divider(height: 1),
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
                const Icon(Icons.info_outline, size: 17, color: AppColors.sky),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Corrections never delete a record. A void request is reviewed by an admin, '
                    'who posts a reversing entry. The original stays visible.',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.ink, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _requestVoid(BuildContext context, String name) {
    final reason = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request a void'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For the transaction for $name. An admin must approve it.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'What went wrong?',
                ),
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
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Void request sent for admin review (simulated).',
                  ),
                ),
              );
            },
            child: const Text('Send request'),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
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

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.at,
    required this.collection,
    required this.voided,
    required this.onVoid,
  });

  final String title;
  final String subtitle;
  final int points;
  final DateTime at;
  final bool collection;
  final bool voided;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (collection ? AppColors.leaf : AppColors.sun).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              collection ? Icons.recycling : Icons.card_giftcard,
              size: 18,
              color: collection ? AppColors.leaf : const Color(0xFF7A4F00),
            ),
          ),
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
            '${points > 0 ? '+' : ''}${formatPoints(points)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: points > 0 ? AppColors.leaf : AppColors.danger,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (_) => onVoid(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'void', child: Text('Request void')),
            ],
          ),
        ],
      ),
    );
  }
}
