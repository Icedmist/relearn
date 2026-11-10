import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/demo_data.dart';
import '../../data/models.dart';

enum _ReportTab { collections, redemptions, ledger }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _ReportTab _tab = _ReportTab.collections;
  String _schoolId = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(demoStoreProvider);
    final schoolBeneficiaries = state.beneficiaries
        .where((b) => _schoolId == 'all' || b.schoolId == _schoolId)
        .map((b) => b.id)
        .toSet();

    final collections = state.collections
        .where((c) => schoolBeneficiaries.contains(c.beneficiaryId))
        .toList();
    final redemptions = state.redemptions
        .where((r) => schoolBeneficiaries.contains(r.beneficiaryId))
        .toList();
    final ledger = state.ledger
        .where((l) => schoolBeneficiaries.contains(l.beneficiaryId))
        .toList();

    final rows = switch (_tab) {
      _ReportTab.collections => collections.length,
      _ReportTab.redemptions => redemptions.length,
      _ReportTab.ledger => ledger.length,
    };
    final points = switch (_tab) {
      _ReportTab.collections => collections.fold(0, (s, c) => s + c.points),
      _ReportTab.redemptions => redemptions.fold(0, (s, r) => s + r.points),
      _ReportTab.ledger => ledger.fold(0, (s, l) => s + l.points.abs()),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Reporting',
          title: 'Reports',
          subtitle:
              'Transaction-level truth. Exports respect the active filters.',
          actions: [
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'CSV export for ${_tab.name} is wired in Stage 1 (csv package).',
                  ),
                ),
              ),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Export CSV'),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<_ReportTab>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: _ReportTab.collections,
                            label: Text('Collections'),
                          ),
                          ButtonSegment(
                            value: _ReportTab.redemptions,
                            label: Text('Redemptions'),
                          ),
                          ButtonSegment(
                            value: _ReportTab.ledger,
                            label: Text('Points ledger'),
                          ),
                        ],
                        selected: {_tab},
                        onSelectionChanged: (value) =>
                            setState(() => _tab = value.first),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        initialValue: _schoolId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'School',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All schools'),
                          ),
                          for (final s in state.schools)
                            DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _schoolId = value ?? 'all'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _SummaryChip(label: 'Rows', value: '$rows'),
                    const SizedBox(width: 10),
                    _SummaryChip(label: 'Points', value: formatPoints(points)),
                    const SizedBox(width: 10),
                    _SummaryChip(
                      label: 'Date range',
                      value: 'All time',
                      icon: Icons.calendar_today_outlined,
                    ),
                    const Spacer(),
                    Text(
                      'Filters: ${_schoolId == 'all' ? 'all schools' : state.schoolById(_schoolId)?.name ?? ''}',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _ReportHeader(tab: _tab),
              const Divider(height: 1),
              if (_tab == _ReportTab.collections)
                ..._collectionRows(context, state, collections)
              else if (_tab == _ReportTab.redemptions)
                ..._redemptionRows(context, state, redemptions)
              else
                ..._ledgerRows(context, state, ledger),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _collectionRows(
    BuildContext context,
    DemoState state,
    List<CollectionRecord> list,
  ) {
    if (list.isEmpty) {
      return [
        const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No collections',
          message: 'Collections recorded by collectors will appear here.',
        ),
      ];
    }
    return [
      for (var i = 0; i < list.length; i++) ...[
        _ReportRow(
          title:
              state.beneficiaryById(list[i].beneficiaryId)?.name ?? 'Unknown',
          subtitle:
              '${state.beneficiaryById(list[i].beneficiaryId)?.publicId ?? ''} · ${list[i].summary}',
          trailing: '+${formatPoints(list[i].points)} pts',
          trailingColor: AppColors.leaf,
          meta: '${list[i].collectorName} · ${formatDateShort(list[i].at)}',
          voided: list[i].voided,
        ),
        if (i < list.length - 1) const Divider(height: 1),
      ],
    ];
  }

  List<Widget> _redemptionRows(
    BuildContext context,
    DemoState state,
    List<RedemptionRecord> list,
  ) {
    if (list.isEmpty) {
      return [
        const EmptyState(
          icon: Icons.redeem_outlined,
          title: 'No redemptions',
          message: 'Rewards given to beneficiaries will appear here.',
        ),
      ];
    }
    return [
      for (var i = 0; i < list.length; i++) ...[
        _ReportRow(
          title:
              state.beneficiaryById(list[i].beneficiaryId)?.name ?? 'Unknown',
          subtitle: '${list[i].rewardName} × ${list[i].qty}',
          trailing: '−${formatPoints(list[i].points)} pts',
          trailingColor: AppColors.danger,
          meta: '${list[i].collectorName} · ${formatDateShort(list[i].at)}',
          voided: list[i].voided,
        ),
        if (i < list.length - 1) const Divider(height: 1),
      ],
    ];
  }

  List<Widget> _ledgerRows(
    BuildContext context,
    DemoState state,
    List<LedgerEntry> list,
  ) {
    final sorted = [...list]..sort((a, b) => b.at.compareTo(a.at));
    if (sorted.isEmpty) {
      return [
        const EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'No ledger entries',
          message:
              'Every earn, redeem, adjust and void entry is recorded here.',
        ),
      ];
    }
    return [
      for (var i = 0; i < sorted.length; i++) ...[
        _ReportRow(
          title:
              state.beneficiaryById(sorted[i].beneficiaryId)?.name ?? 'Unknown',
          subtitle: sorted[i].note ?? sorted[i].type.label,
          trailing:
              '${sorted[i].points > 0 ? '+' : ''}${formatPoints(sorted[i].points)} pts',
          trailingColor: sorted[i].points > 0
              ? AppColors.leaf
              : AppColors.danger,
          meta: '${sorted[i].type.label} · ${formatDateShort(sorted[i].at)}',
        ),
        if (i < sorted.length - 1) const Divider(height: 1),
      ],
    ];
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.tab});

  final _ReportTab tab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          const Expanded(
            flex: 4,
            child: Text('BENEFICIARY / DETAIL', style: _labelStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(
              tab == _ReportTab.collections ? 'COLLECTION' : 'REFERENCE',
              style: _labelStyle,
            ),
          ),
          Expanded(flex: 2, child: Text('POINTS', style: _labelStyle)),
          Expanded(flex: 3, child: Text('WHEN', style: _labelStyle)),
        ],
      ),
    );
  }

  static const _labelStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.muted,
  );
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    required this.meta,
    this.voided = false,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;
  final String meta;
  final bool voided;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: voided ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: voided
                ? const StatusPill(label: 'VOIDED', color: AppColors.danger)
                : const StatusPill(label: 'POSTED', color: AppColors.leaf),
          ),
          Expanded(
            flex: 2,
            child: Text(
              trailing,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: trailingColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              meta,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.muted),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
