import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/demo_data.dart';
import '../../data/models.dart';

class BeneficiariesScreen extends ConsumerStatefulWidget {
  const BeneficiariesScreen({super.key});

  @override
  ConsumerState<BeneficiariesScreen> createState() =>
      _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends ConsumerState<BeneficiariesScreen> {
  String _query = '';
  String _schoolId = 'all';
  BeneficiaryType? _type;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(demoStoreProvider);
    final list = state.beneficiaries.where((b) {
      final matchesQuery =
          b.name.toLowerCase().contains(_query.toLowerCase()) ||
          b.publicId.toLowerCase().contains(_query.toLowerCase());
      final matchesSchool = _schoolId == 'all' || b.schoolId == _schoolId;
      final matchesType = _type == null || b.type == _type;
      return matchesQuery && matchesSchool && matchesType;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'People',
          title: 'Beneficiaries',
          subtitle:
              '${state.beneficiaries.length} registered · ${state.beneficiaries.where((b) => b.active).length} active',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/admin/print'),
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Print cards'),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/admin/beneficiaries/new'),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Register beneficiary'),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final search = TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search by name or ID',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                    );
                    final schoolFilter = DropdownButtonFormField<String>(
                      initialValue: _schoolId,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
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
                    );

                    if (constraints.maxWidth < 560) {
                      return Column(
                        children: [
                          search,
                          const SizedBox(height: 12),
                          schoolFilter,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: search),
                        const SizedBox(width: 12),
                        SizedBox(width: 230, child: schoolFilter),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('All types'),
                      selected: _type == null,
                      onSelected: (_) => setState(() => _type = null),
                    ),
                    FilterChip(
                      label: const Text('Pupils'),
                      selected: _type == BeneficiaryType.pupil,
                      onSelected: (_) =>
                          setState(() => _type = BeneficiaryType.pupil),
                    ),
                    FilterChip(
                      label: const Text('Teachers'),
                      selected: _type == BeneficiaryType.teacher,
                      onSelected: (_) =>
                          setState(() => _type = BeneficiaryType.teacher),
                    ),
                    Text(
                      '${list.length} result${list.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall
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
          child: list.isEmpty
              ? const EmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No beneficiaries match',
                  message: 'Clear the filters or register a new beneficiary.',
                )
              : Column(
                  children: [
                    for (var i = 0; i < list.length; i++) ...[
                      _BeneficiaryRow(
                        beneficiary: list[i],
                        schoolName:
                            state.schoolById(list[i].schoolId)?.name ??
                            'Unknown school',
                        onTap: () =>
                            context.go('/admin/beneficiaries/${list[i].id}'),
                      ),
                      if (i < list.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _BeneficiaryRow extends StatelessWidget {
  const _BeneficiaryRow({
    required this.beneficiary,
    required this.schoolName,
    required this.onTap,
  });

  final Beneficiary beneficiary;
  final String schoolName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            InitialsAvatar(initials: beneficiary.initials()),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          beneficiary.name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (beneficiary.cardBlocked) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.block,
                          size: 14,
                          color: AppColors.danger,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    beneficiary.publicId,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schoolName,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${beneficiary.type.label} · ${beneficiary.className}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            BalancePill(points: beneficiary.balance),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}
