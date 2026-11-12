import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class BeneficiaryProfileScreen extends ConsumerWidget {
  const BeneficiaryProfileScreen({super.key, required this.beneficiaryId});

  final String beneficiaryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStoreProvider);
    final beneficiary = state.beneficiaryById(beneficiaryId);
    final school = beneficiary == null
        ? null
        : state.schoolById(beneficiary.schoolId);

    if (beneficiary == null) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'Beneficiary not found',
        message: 'This record may have been removed or deactivated.',
      );
    }

    final ledger = state.ledgerFor(beneficiaryId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/admin/beneficiaries'),
          icon: const Icon(Icons.arrow_back, size: 17),
          label: const Text('Back to beneficiaries'),
        ),
        const SizedBox(height: 8),
        PageHeader(
          eyebrow: beneficiary.publicId,
          title: beneficiary.name,
          subtitle:
              '${beneficiary.type.label} · ${beneficiary.className} · ${school?.name ?? 'Unknown school'}',
          actions: [
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Card PDF export is not available in this build.',
                  ),
                ),
              ),
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Print card'),
            ),
            FilledButton.icon(
              onPressed: () => _showAdjustDialog(context, ref, beneficiary),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Adjust points'),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final left = Column(
              children: [
                _IdCard(
                  beneficiary: beneficiary,
                  schoolName: school?.name ?? '',
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Details',
                  child: Column(
                    children: [
                      InfoRow(label: 'Full name', value: beneficiary.name),
                      InfoRow(label: 'Public ID', value: beneficiary.publicId),
                      InfoRow(label: 'School', value: school?.name ?? '—'),
                      InfoRow(label: 'Class', value: beneficiary.className),
                      InfoRow(
                        label: 'Guardian phone',
                        value: beneficiary.guardianPhone ?? 'Not provided',
                      ),
                      InfoRow(
                        label: 'Status',
                        value: beneficiary.active ? 'Active' : 'Inactive',
                      ),
                    ],
                  ),
                ),
              ],
            );
            final right = Column(
              children: [
                _BalanceCard(beneficiary: beneficiary),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Points history',
                  subtitle: 'Append-only ledger · corrections are new entries',
                  action: beneficiary.cardBlocked
                      ? null
                      : TextButton.icon(
                          onPressed: () =>
                              _confirmBlock(context, ref, beneficiary),
                          icon: const Icon(Icons.block, size: 16),
                          label: const Text('Block card'),
                        ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    children: [
                      if (beneficiary.cardBlocked)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.block,
                                color: AppColors.danger,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'This card is blocked. Scans are rejected until it is unblocked.',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(appStoreProvider.notifier)
                                      .setCardBlocked(beneficiary.id, false);
                                },
                                child: const Text('Unblock'),
                              ),
                            ],
                          ),
                        ),
                      for (final entry in ledger) _LedgerRow(entry: entry),
                      if (ledger.isEmpty)
                        const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No history yet',
                          message:
                              'Record a collection to credit the first points.',
                        ),
                    ],
                  ),
                ),
              ],
            );
            if (!wide) {
              return Column(
                children: [left, const SizedBox(height: 16), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: right),
              ],
            );
          },
        ),
      ],
    );
  }

  void _confirmBlock(
    BuildContext context,
    WidgetRef ref,
    Beneficiary beneficiary,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block this card?'),
        content: Text(
          'Scans of ${beneficiary.publicId} will be rejected immediately. '
          'The beneficiary stays active and the ID can be reprinted later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref
                  .read(appStoreProvider.notifier)
                  .setCardBlocked(beneficiary.id, true);
              Navigator.pop(dialogContext);
            },
            child: const Text('Block card'),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(
    BuildContext context,
    WidgetRef ref,
    Beneficiary beneficiary,
  ) {
    final points = TextEditingController();
    final reason = TextEditingController();
    String? error;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Adjust points'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: points,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Points (+ or −)',
                    hintText: 'e.g. 50 or -20',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reason,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason (required)',
                    hintText: 'Why is this adjustment needed?',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12.5,
                    ),
                  ),
                ],
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
                final value = int.tryParse(points.text.trim());
                if (value == null || value == 0) {
                  setState(() => error = 'Enter a non-zero number of points.');
                  return;
                }
                if (reason.text.trim().length < 5) {
                  setState(
                    () => error =
                        'A reason of at least 5 characters is required.',
                  );
                  return;
                }
                ref
                    .read(appStoreProvider.notifier)
                    .adjustPoints(beneficiary.id, value, reason.text.trim());
                Navigator.pop(dialogContext);
              },
              child: const Text('Post adjustment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdCard extends StatelessWidget {
  const _IdCard({required this.beneficiary, required this.schoolName});

  final Beneficiary beneficiary;
  final String schoolName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: QrImageView(
                data: beneficiary.publicId,
                size: 180,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.forest,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.forest,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              beneficiary.publicId,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 16,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              schoolName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            const StatusPill(
              label: 'QR ENCODES ID ONLY',
              color: AppColors.sky,
              icon: Icons.lock_outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.beneficiary});

  final Beneficiary beneficiary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT BALANCE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatPoints(beneficiary.balance)} pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '≈ ${beneficiary.balance ~/ 80} exercise book(s)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.savings_outlined, color: Colors.white24, size: 64),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final positive = entry.points > 0;
    final color = positive ? AppColors.leaf : AppColors.danger;
    final icon = switch (entry.type) {
      LedgerType.earn => Icons.eco_outlined,
      LedgerType.redeem => Icons.redeem_outlined,
      LedgerType.adjust => Icons.tune,
      LedgerType.reversal => Icons.undo,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.note ?? entry.type.label,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${entry.type.label} · ${formatDateShort(entry.at)}',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : ''}${formatPoints(entry.points)} pts',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
