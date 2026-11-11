import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStoreProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Catalogue',
          title: 'Rewards & stock',
          subtitle: 'Stock is decremented in the same transaction as points on redemption.',
          actions: [
            FilledButton.icon(
              onPressed: () => _showAdd(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add reward'),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 3
                : constraints.maxWidth >= 640
                ? 2
                : 1;
            const gap = 16.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final reward in state.rewards)
                  SizedBox(
                    width: width,
                    child: _RewardCard(
                      reward: reward,
                      redemptions: state.redemptions
                          .where((r) => r.rewardName == reward.name)
                          .length,
                      onRestock: () => _showRestock(context, ref, reward),
                      onEdit: () => _showEdit(context, ref, reward),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Recent redemptions',
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: state.redemptions.isEmpty
              ? const EmptyState(
                  icon: Icons.redeem_outlined,
                  title: 'No redemptions yet',
                  message: 'Rewards given by collectors will appear here.',
                )
              : Column(
                  children: [
                    for (final r in state.redemptions.take(8))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard,
                              size: 18,
                              color: AppColors.sun,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${state.beneficiaryById(r.beneficiaryId)?.name ?? 'Unknown'} · '
                                '${r.rewardName} × ${r.qty}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              '−${formatPoints(r.points)} pts',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: AppColors.danger,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              formatDateShort(r.at),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  void _showRestock(BuildContext context, WidgetRef ref, Reward reward) {
    final qty = TextEditingController(text: '50');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Restock ${reward.name}'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: qty,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantity to add',
              helperText: 'Current stock: ${reward.stock}',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(qty.text);
              if (value == null || value <= 0) return;
              ref.read(appStoreProvider.notifier).restock(reward.id, value);
              Navigator.pop(dialogContext);
            },
            child: const Text('Add stock'),
          ),
        ],
      ),
    );
  }

  void _showEdit(BuildContext context, WidgetRef ref, Reward reward) {
    final cost = TextEditingController(text: reward.pointsCost.toString());
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${reward.name}'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: cost,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Points cost'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(cost.text);
              if (value == null || value <= 0) return;
              ref
                  .read(appStoreProvider.notifier)
                  .updateReward(reward.id, pointsCost: value);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAdd(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final cost = TextEditingController(text: '50');
    final stock = TextEditingController(text: '100');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add reward'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Reward name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cost,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Points cost'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Opening stock'),
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
              if (name.text.trim().isEmpty) return;
              ref
                  .read(appStoreProvider.notifier)
                  .addReward(
                    name: name.text.trim(),
                    pointsCost: int.tryParse(cost.text) ?? 50,
                    stock: int.tryParse(stock.text) ?? 0,
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Add reward'),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.redemptions,
    required this.onRestock,
    required this.onEdit,
  });

  final Reward reward;
  final int redemptions;
  final VoidCallback onRestock;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final low = reward.stock <= 10;
    final out = reward.stock == 0;
    final color = out
        ? AppColors.danger
        : low
        ? const Color(0xFFB45309)
        : AppColors.leaf;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.sun.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: Color(0xFF7A4F00),
                  ),
                ),
                const Spacer(),
                StatusPill(
                  label: out
                      ? 'OUT OF STOCK'
                      : low
                      ? 'LOW STOCK'
                      : 'IN STOCK',
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(reward.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              '${formatPoints(reward.pointsCost)} pts per item',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${reward.stock}',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'in stock',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ),
                const Spacer(),
                Text(
                  '$redemptions given',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRestock,
                    icon: const Icon(Icons.add_box_outlined, size: 17),
                    label: const Text('Restock'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit points cost',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
