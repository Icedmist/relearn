import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/demo_data.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(demoStoreProvider);
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
                  Text(
                    'Choose a reward',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  for (final reward in rewards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RewardOption(
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
                  const SizedBox(height: 14),
                  if (selected != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
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

  void _confirm() {
    final error = ref
        .read(demoStoreProvider.notifier)
        .redeem(
          beneficiaryId: widget.beneficiaryId,
          rewardId: _rewardId!,
          qty: _qty,
        );
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final balance =
        ref
            .read(demoStoreProvider)
            .beneficiaryById(widget.beneficiaryId)
            ?.balance ??
        0;
    final reward = ref.read(demoStoreProvider).rewardById(_rewardId!);
    final cost = (reward?.pointsCost ?? 0) * _qty;
    context.pushReplacement(
      '/collector/success?action=redeem&points=$cost&balance=$balance&beneficiary=${widget.beneficiaryId}',
    );
  }
}

class _RewardOption extends StatelessWidget {
  const _RewardOption({
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
    final out = reward.stock == 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.sun.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: Color(0xFF7A4F00),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.name,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${reward.stock} in stock',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: out ? AppColors.danger : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatPoints(reward.pointsCost)} pts',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: affordable ? AppColors.forest : AppColors.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (out)
                  const Text(
                    'Out of stock',
                    style: TextStyle(fontSize: 10, color: AppColors.danger),
                  )
                else if (!affordable)
                  const Text(
                    'Can’t afford',
                    style: TextStyle(fontSize: 10, color: AppColors.muted),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 19,
              color: selected ? AppColors.leaf : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
