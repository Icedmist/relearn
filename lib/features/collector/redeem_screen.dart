import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/item_art.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class RedeemScreen extends ConsumerStatefulWidget {
  const RedeemScreen({super.key, required this.beneficiaryId});

  final String beneficiaryId;

  @override
  ConsumerState<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends ConsumerState<RedeemScreen> {
  String? _rewardId;
  int _qty = 1;
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStoreProvider);
    final beneficiary = state.beneficiaryById(widget.beneficiaryId);
    final rewards = state.rewards.where((r) => r.active).toList();
    final selected = _rewardId == null ? null : state.rewardById(_rewardId!);
    final cost = selected == null ? 0 : selected.pointsCost * _qty;
    final balance = beneficiary?.balance ?? 0;
    final canAfford =
        selected != null && balance >= cost && selected.stock >= _qty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem reward'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (beneficiary != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.forest, AppColors.leaf],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          InitialsAvatar(
                            initials: beneficiary.initials(),
                            size: 42,
                            color: AppColors.sun,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  beneficiary.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${beneficiary.publicId} · ${beneficiary.className}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${formatPoints(balance)} pts',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              Text(
                                'available',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text(
                        'Item shop',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${rewards.length} items',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse by category and pick a reward for this card.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final category in [
                          'All',
                          ...{for (final reward in rewards) reward.category},
                        ]) ...[
                          ChoiceChip(
                            label: Text(category),
                            selected: _category == category,
                            onSelected: (_) =>
                                setState(() => _category = category),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 620
                          ? 3
                          : constraints.maxWidth >= 400
                          ? 2
                          : 1;
                      const gap = 10.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      final visible = rewards
                          .where(
                            (r) =>
                                _category == 'All' || r.category == _category,
                          )
                          .toList();
                      if (visible.isEmpty) {
                        return const EmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'No items in this category',
                          message: 'Pick another category to continue.',
                        );
                      }
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final reward in visible)
                            SizedBox(
                              width: width,
                              height: 208,
                              child: _ShopCard(
                                reward: reward,
                                selected: _rewardId == reward.id,
                                affordable: balance >= reward.pointsCost,
                                onTap: reward.stock == 0
                                    ? null
                                    : () => setState(() {
                                        _rewardId = reward.id;
                                        _qty = 1;
                                      }),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  if (selected != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: itemColor(selected.category)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    itemIcon(selected.category),
                                    size: 20,
                                    color: itemColor(selected.category),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selected.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        '${selected.category} · ${formatPoints(selected.pointsCost)} pts each',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Text(
                                  'Quantity',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: _qty <= 1
                                      ? null
                                      : () => setState(() => _qty--),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '$_qty',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _qty >= selected.stock
                                      ? null
                                      : () => setState(() => _qty++),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                            const Divider(),
                            _summaryRow('Cost', '${formatPoints(cost)} pts'),
                            _summaryRow(
                              'Balance after',
                              '${formatPoints(balance - cost)} pts',
                            ),
                            _summaryRow(
                              'Stock after',
                              '${selected.stock - _qty}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (selected != null && !canAfford)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 17,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selected.stock < _qty
                                  ? 'Not enough stock for this quantity.'
                                  : 'Not enough points. Record a collection first.',
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 12.5,
                              ),
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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selected == null || !canAfford ? null : _confirm,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  child: Text(
                    selected == null
                        ? 'Select a reward'
                        : 'Redeem · ${formatPoints(cost)} pts',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.muted),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    final error = await ref
        .read(appStoreProvider.notifier)
        .redeem(
          beneficiaryId: widget.beneficiaryId,
          rewardId: _rewardId!,
          qty: _qty,
        );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final balance =
        ref
            .read(appStoreProvider)
            .beneficiaryById(widget.beneficiaryId)
            ?.balance ??
        0;
    final reward = ref.read(appStoreProvider).rewardById(_rewardId!);
    final cost = (reward?.pointsCost ?? 0) * _qty;
    context.pushReplacement(
      '/collector/success?action=redeem&points=$cost&balance=$balance&beneficiary=${widget.beneficiaryId}',
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.reward,
    required this.selected,
    required this.affordable,
    required this.onTap,
  });

  final Reward reward;
  final bool selected;
  final bool affordable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final out = reward.stock == 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.leaf.withValues(alpha: 0.06)
              : AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.leaf : AppColors.line,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Opacity(
                  opacity: out ? 0.45 : 1,
                  child: ItemArt(
                    category: reward.category,
                    imageUrl: reward.imageUrl,
                    height: 84,
                    radius: 10,
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.leaf,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              reward.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              reward.category,
              style: theme.textTheme.labelSmall?.copyWith(
                color: itemColor(reward.category),
                fontSize: 10,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '${formatPoints(reward.pointsCost)} pts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: affordable ? AppColors.forest : AppColors.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Text(
                  out ? 'Out' : '${reward.stock} left',
                  style: TextStyle(
                    fontSize: 10,
                    color: out ? AppColors.danger : AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
