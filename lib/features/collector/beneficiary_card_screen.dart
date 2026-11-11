import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/demo_data.dart';
import '../../data/models.dart';

class BeneficiaryCardScreen extends ConsumerWidget {
  const BeneficiaryCardScreen({super.key, required this.beneficiaryId});

  final String beneficiaryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(demoStoreProvider);
    final beneficiary = state.beneficiaryById(beneficiaryId);
    if (beneficiary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Beneficiary')),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Beneficiary not found',
          message: 'The card may belong to another programme or the record was removed.',
        ),
      );
    }
    final school = state.schoolById(beneficiary.schoolId);
    final lastLedger = state.ledgerFor(beneficiary.id).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiary card'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (beneficiary.cardBlocked)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.block, color: AppColors.danger),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This card is blocked. Ask an admin to unblock it before recording or redeeming.',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              InitialsAvatar(
                                initials: beneficiary.initials(),
                                size: 54,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      beneficiary.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${beneficiary.publicId} · ${beneficiary.type.label}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              if (beneficiary.active)
                                const StatusPill(
                                  label: 'ACTIVE',
                                  color: AppColors.leaf,
                                )
                              else
                                const StatusPill(
                                  label: 'INACTIVE',
                                  color: AppColors.muted,
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'CURRENT BALANCE',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.muted,
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatPoints(beneficiary.balance)} pts',
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Text(
                                  school?.name ?? '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _Meta(
                                  label: 'Class',
                                  value: beneficiary.className,
                                ),
                              ),
                              Expanded(
                                child: _Meta(
                                  label: 'School',
                                  value: school?.name ?? '—',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: beneficiary.cardBlocked
                          ? null
                          : () => context.push(
                              '/collector/beneficiary/${beneficiary.id}/collect',
                            ),
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text('Record collection'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: beneficiary.cardBlocked
                          ? null
                          : () => context.push(
                              '/collector/beneficiary/${beneficiary.id}/redeem',
                            ),
                      icon: const Icon(Icons.card_giftcard, size: 20),
                      label: const Text('Redeem reward'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent history',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/collector/history'),
                        child: const Text('Full history'),
                      ),
                    ],
                  ),
                  Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < lastLedger.length; i++) ...[
                          _HistoryTile(entry: lastLedger[i]),
                          if (i < lastLedger.length - 1)
                            const Divider(height: 1),
                        ],
                        if (lastLedger.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No transactions yet.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Points are calculated on the server. This device only shows a preview before confirming.',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.muted),
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

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            letterSpacing: 0.7,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final positive = entry.points > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            entry.type == LedgerType.earn
                ? Icons.eco_outlined
                : Icons.redeem_outlined,
            size: 18,
            color: positive ? AppColors.leaf : AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.note ?? entry.type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  formatDateShort(entry.at),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : ''}${formatPoints(entry.points)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: positive ? AppColors.leaf : AppColors.danger,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
