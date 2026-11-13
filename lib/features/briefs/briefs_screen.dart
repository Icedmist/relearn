import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

enum _Scope { all, school }

enum _Period { week, month, all }

extension on _Period {
  String get label => switch (this) {
    _Period.week => 'This week',
    _Period.month => 'This month',
    _Period.all => 'All time',
  };
}

/// Generates a plain-text school or programme brief plus the matching history.
///
/// The data is already scoped by RLS: a school-linked account only receives its
/// own school's beneficiaries, collections and ledger rows. Admins receive the
/// whole programme and can switch between all schools and one school.
class BriefsView extends ConsumerStatefulWidget {
  const BriefsView({super.key});

  @override
  ConsumerState<BriefsView> createState() => _BriefsViewState();
}

class _BriefsViewState extends ConsumerState<BriefsView> {
  _Scope _scope = _Scope.all;
  _Period _period = _Period.month;
  String? _schoolId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStoreProvider);
    final theme = Theme.of(context);
    final profile = state.profile;
    final isAdmin = profile?.isAdmin ?? state.isLive == false;
    final ownSchoolId = profile?.schoolId;

    if (!isAdmin && ownSchoolId == null) {
      return const EmptyState(
        icon: Icons.school_outlined,
        title: 'No school linked',
        message:
            'Your account is not linked to a school yet, so there is no '
            'history to brief. Ask an admin to assign your school.',
      );
    }

    final schoolId = isAdmin
        ? (_scope == _Scope.all
              ? null
              : _schoolId ??
                    (state.schools.isEmpty ? null : state.schools.first.id))
        : ownSchoolId;
    final school = schoolId == null ? null : state.schoolById(schoolId);
    final scopeLabel =
        school?.name ?? (isAdmin ? 'All schools' : 'Your school');

    final beneficiaryIds = state.beneficiaries
        .where((b) => schoolId == null || b.schoolId == schoolId)
        .map((b) => b.id)
        .toSet();

    final since = switch (_period) {
      _Period.week => DateTime.now().subtract(const Duration(days: 7)),
      _Period.month => DateTime(DateTime.now().year, DateTime.now().month),
      _Period.all => null,
    };
    bool inPeriod(DateTime at) => since == null || !at.isBefore(since);

    final collections =
        state.collections
            .where((c) => beneficiaryIds.contains(c.beneficiaryId))
            .where((c) => inPeriod(c.at))
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));
    final redemptions =
        state.redemptions
            .where((r) => beneficiaryIds.contains(r.beneficiaryId))
            .where((r) => inPeriod(r.at))
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));
    final beneficiaries = state.beneficiaries
        .where((b) => beneficiaryIds.contains(b.id) && b.active)
        .toList();

    final validCollections = collections.where((c) => !c.voided).toList();
    final validRedemptions = redemptions.where((r) => !r.voided).toList();
    final kg = validCollections.fold(0.0, (s, c) => s + c.kg);
    final pointsEarned = validCollections.fold(0, (s, c) => s + c.points);
    final pointsRedeemed = validRedemptions.fold(0, (s, r) => s + r.points);
    final itemsGiven = validRedemptions.fold(0, (s, r) => s + r.qty);

    final materials = <String, double>{};
    for (final c in validCollections) {
      final name = c.summary.split(' · ').first.trim();
      materials.update(name, (v) => v + c.kg, ifAbsent: () => c.kg);
    }
    final topMaterials = materials.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final collectors = <String, double>{};
    for (final c in validCollections) {
      collectors.update(c.collectorName, (v) => v + c.kg, ifAbsent: () => c.kg);
    }
    final topCollectors = collectors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final perSchool = <String, double>{};
    for (final c in validCollections) {
      final name =
          state
              .schoolById(
                state.beneficiaryById(c.beneficiaryId)?.schoolId ?? '',
              )
              ?.name ??
          'Unknown school';
      perSchool.update(name, (v) => v + c.kg, ifAbsent: () => c.kg);
    }

    final brief = _buildBrief(
      scopeLabel: scopeLabel,
      global: schoolId == null,
      period: _period,
      beneficiaries: beneficiaries.length,
      collectionCount: validCollections.length,
      kg: kg,
      pointsEarned: pointsEarned,
      pointsRedeemed: pointsRedeemed,
      itemsGiven: itemsGiven,
      topMaterials: topMaterials,
      topCollectors: topCollectors,
      perSchool: perSchool,
      collections: validCollections,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            eyebrow: 'Reporting',
            title: 'Briefs & history',
            subtitle:
                'Copy a ready-to-send update, or review every transaction in '
                'the selected scope.',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scope', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  if (isAdmin)
                    SegmentedButton<_Scope>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: _Scope.all,
                          label: Text('All schools'),
                          icon: Icon(Icons.public_outlined),
                        ),
                        ButtonSegment(
                          value: _Scope.school,
                          label: Text('One school'),
                          icon: Icon(Icons.school_outlined),
                        ),
                      ],
                      selected: {_scope},
                      onSelectionChanged: (value) =>
                          setState(() => _scope = value.first),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.leaf.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 18,
                            color: AppColors.leaf,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              scopeLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isAdmin &&
                      _scope == _Scope.school &&
                      state.schools.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _schoolId ?? state.schools.first.id,
                      decoration: const InputDecoration(labelText: 'School'),
                      items: [
                        for (final item in state.schools)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _schoolId = value),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text('Period', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<_Period>(
                    showSelectedIcon: false,
                    segments: [
                      for (final p in _Period.values)
                        ButtonSegment(value: p, label: Text(p.label)),
                    ],
                    selected: {_period},
                    onSelectionChanged: (value) =>
                        setState(() => _period = value.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Brief',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _copy(brief),
                        icon: const Icon(Icons.copy_all_outlined, size: 17),
                        label: const Text('Copy brief'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: SelectableText(
                      brief,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.6,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('History', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${collections.length + redemptions.length} transactions · '
            '$scopeLabel · ${_period.label.toLowerCase()}',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Card(
            child: collections.isEmpty && redemptions.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nothing in this period',
                    message:
                        'Collections and redemptions appear here as soon as '
                        'they are recorded.',
                  )
                : Column(
                    children: _historyRows(state, collections, redemptions),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _historyRows(
    AppState state,
    List<CollectionRecord> collections,
    List<RedemptionRecord> redemptions,
  ) {
    final rows =
        <
            ({
              DateTime at,
              bool collection,
              String name,
              String detail,
              int points,
              bool voided,
            })
          >[
            for (final c in collections)
              (
                at: c.at,
                collection: true,
                name: state.beneficiaryById(c.beneficiaryId)?.name ?? 'Unknown',
                detail: '${c.summary} · ${c.collectorName}',
                points: c.points,
                voided: c.voided,
              ),
            for (final r in redemptions)
              (
                at: r.at,
                collection: false,
                name: state.beneficiaryById(r.beneficiaryId)?.name ?? 'Unknown',
                detail: '${r.rewardName} × ${r.qty} · ${r.collectorName}',
                points: -r.points,
                voided: r.voided,
              ),
          ]
          ..sort((a, b) => b.at.compareTo(a.at));

    final limited = rows.length > 60 ? rows.sublist(0, 60) : rows;
    return [
      for (var i = 0; i < limited.length; i++) ...[
        _HistoryRow(row: limited[i]),
        if (i < limited.length - 1) const Divider(height: 1),
      ],
      if (rows.length > limited.length)
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Showing the latest ${limited.length} of ${rows.length}. '
            'Narrow the scope or period to see older rows.',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.muted),
          ),
        ),
    ];
  }

  String _buildBrief({
    required String scopeLabel,
    required bool global,
    required _Period period,
    required int beneficiaries,
    required int collectionCount,
    required double kg,
    required int pointsEarned,
    required int pointsRedeemed,
    required int itemsGiven,
    required List<MapEntry<String, double>> topMaterials,
    required List<MapEntry<String, double>> topCollectors,
    required Map<String, double> perSchool,
    required List<CollectionRecord> collections,
  }) {
    final now = DateTime.now();
    final buffer = StringBuffer()
      ..writeln('ReLearn brief — $scopeLabel')
      ..writeln(
        '${DateFormat('d MMM yyyy, HH:mm').format(now)} · ${period.label}',
      )
      ..writeln()
      ..writeln('HEADLINE')
      ..writeln('• $beneficiaries active beneficiary records')
      ..writeln(
        '• ${kg.toStringAsFixed(1)} kg collected in $collectionCount '
        'collections',
      )
      ..writeln('• ${formatPoints(pointsEarned)} points earned')
      ..writeln(
        '• ${formatPoints(pointsRedeemed)} points redeemed for $itemsGiven '
        'items',
      );

    if (topMaterials.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('TOP MATERIALS');
      for (final entry in topMaterials.take(5)) {
        buffer.writeln('• ${entry.key} — ${entry.value.toStringAsFixed(1)} kg');
      }
    }

    if (topCollectors.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('COLLECTORS');
      for (final entry in topCollectors.take(5)) {
        buffer.writeln('• ${entry.key} — ${entry.value.toStringAsFixed(1)} kg');
      }
    }

    if (global && perSchool.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('SCHOOLS');
      final sorted = perSchool.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sorted) {
        buffer.writeln('• ${entry.key} — ${entry.value.toStringAsFixed(1)} kg');
      }
    }

    if (collections.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('LATEST COLLECTIONS');
      for (final c in collections.take(5)) {
        buffer.writeln(
          '• ${DateFormat('d MMM').format(c.at)} · ${c.summary} · '
          '${formatPoints(c.points)} pts',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('Generated by ReLearn. Figures exclude voided rows.');
    return buffer.toString();
  }

  Future<void> _copy(String brief) async {
    await Clipboard.setData(ClipboardData(text: brief));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Brief copied to clipboard.')));
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.row});

  final ({
    DateTime at,
    bool collection,
    String name,
    String detail,
    int points,
    bool voided,
  })
  row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(
            row.collection ? Icons.recycling : Icons.card_giftcard,
            size: 18,
            color: row.collection ? AppColors.leaf : const Color(0xFF7A4F00),
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
                        row.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (row.voided) ...[
                      const SizedBox(width: 6),
                      const StatusPill(
                        label: 'VOIDED',
                        color: AppColors.danger,
                      ),
                    ],
                  ],
                ),
                Text(
                  '${row.detail} · ${formatDateShort(row.at)}',
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
            '${row.points > 0 ? '+' : ''}${formatPoints(row.points)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: row.points > 0 ? AppColors.leaf : AppColors.danger,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone route used by collectors and teachers.
class BriefsScreen extends StatelessWidget {
  const BriefsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Briefs & history')),
      body: const SafeArea(child: BriefsView()),
    );
  }
}
