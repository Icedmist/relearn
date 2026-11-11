import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class SchoolsScreen extends ConsumerStatefulWidget {
  const SchoolsScreen({super.key});

  @override
  ConsumerState<SchoolsScreen> createState() => _SchoolsScreenState();
}

class _SchoolsScreenState extends ConsumerState<SchoolsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStoreProvider);
    final schools = state.schools
        .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Programme',
          title: 'Schools',
          subtitle: 'Deactivate a school to hide it from new registrations. History is never deleted.',
          actions: [
            FilledButton.icon(
              onPressed: () => _showAddSchool(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add school'),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search schools',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (schools.isEmpty)
          const Card(
            child: EmptyState(
              icon: Icons.school_outlined,
              title: 'No schools found',
              message: 'Try a different search, or add the first school to the programme.',
            ),
          )
        else
          Column(
            children: [
              for (final school in schools)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SchoolCard(
                    school: school,
                    beneficiaryCount: state.beneficiaries
                        .where((b) => b.schoolId == school.id)
                        .length,
                    points: state.beneficiaries
                        .where((b) => b.schoolId == school.id)
                        .fold(0, (s, b) => s + b.balance),
                    onToggle: () {
                      ref
                          .read(appStoreProvider.notifier)
                          .toggleSchool(school.id);
                    },
                    onOpen: () => context.go('/admin/beneficiaries'),
                    onEdit: () => _showEditSchool(context, school),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  void _showAddSchool(BuildContext context) {
    final name = TextEditingController();
    final address = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add school'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'School name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address'),
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
                  .addSchool(
                    name: name.text.trim(),
                    address: address.text.trim(),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Add school'),
          ),
        ],
      ),
    );
  }

  void _showEditSchool(BuildContext context, School school) {
    final name = TextEditingController(text: school.name);
    final address = TextEditingController(text: school.address);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit school'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'School name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address'),
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
                  .renameSchool(
                    school.id,
                    name: name.text.trim(),
                    address: address.text.trim(),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({
    required this.school,
    required this.beneficiaryCount,
    required this.points,
    required this.onToggle,
    required this.onOpen,
    required this.onEdit,
  });

  final School school;
  final int beneficiaryCount;
  final int points;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                school.name,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(
              label: school.active ? 'ACTIVE' : 'INACTIVE',
              color: school.active ? AppColors.leaf : AppColors.muted,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          school.address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final icon = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: school.active
                ? AppColors.leaf.withValues(alpha: 0.1)
                : AppColors.line,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.school_outlined,
            color: school.active ? AppColors.leaf : AppColors.muted,
          ),
        );
        final menu = PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'toggle') onToggle();
            if (value == 'edit') onEdit();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit school')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(
                school.active ? 'Deactivate school' : 'Reactivate school',
              ),
            ),
          ],
        );

        if (compact) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(width: 14),
                      Expanded(child: details),
                      menu,
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MiniStat(label: 'People', value: '$beneficiaryCount'),
                      _MiniStat(label: 'Points', value: formatPoints(points)),
                      TextButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.chevron_right, size: 18),
                        label: const Text('View beneficiaries'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 14),
                Expanded(child: details),
                const SizedBox(width: 12),
                _MiniStat(label: 'People', value: '$beneficiaryCount'),
                const SizedBox(width: 20),
                _MiniStat(label: 'Points', value: formatPoints(points)),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'View beneficiaries',
                  onPressed: onOpen,
                  icon: const Icon(Icons.chevron_right),
                ),
                menu,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
    );
  }
}
