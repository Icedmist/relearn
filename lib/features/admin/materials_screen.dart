import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStoreProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Configuration',
          title: 'Materials & points',
          subtitle: 'Rates apply to new collections only. Past lines keep their rate snapshot.',
          actions: [
            FilledButton.icon(
              onPressed: () => _showAdd(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add material'),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 18,
                color: AppColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Iron, metal scrap and anything that could encourage theft of school property must stay disallowed. '
                  'The server rejects these materials even if the UI is bypassed.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('MATERIAL', style: _labelStyle),
                    ),
                    Expanded(child: Text('UNIT', style: _labelStyle)),
                    Expanded(child: Text('POINTS / UNIT', style: _labelStyle)),
                    Expanded(child: Text('ALLOWED', style: _labelStyle)),
                    Expanded(child: Text('ACTIVE', style: _labelStyle)),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (var i = 0; i < state.materials.length; i++) ...[
                _MaterialRow(
                  material: state.materials[i],
                  onEdit: () => _showEdit(context, ref, state.materials[i]),
                  onAllowed: (value) => ref
                      .read(appStoreProvider.notifier)
                      .updateMaterial(state.materials[i].id, allowed: value),
                  onActive: (value) => ref
                      .read(appStoreProvider.notifier)
                      .updateMaterial(state.materials[i].id, active: value),
                ),
                if (i < state.materials.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Suggested pilot rates: paper 10 pts/kg · PET 2 pts/piece · cans 3 pts/piece · '
          'sachet wrappers 8 pts/kg. Exercise book 80 pts · pencil 20 pts.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  static const _labelStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: AppColors.muted,
    letterSpacing: 0.8,
  );

  void _showAdd(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final rate = TextEditingController(text: '5');
    MaterialUnit unit = MaterialUnit.kg;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Add material'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Material name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MaterialUnit>(
                  initialValue: unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: const [
                    DropdownMenuItem(
                      value: MaterialUnit.kg,
                      child: Text('Kilogram (kg)'),
                    ),
                    DropdownMenuItem(
                      value: MaterialUnit.piece,
                      child: Text('Piece'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => unit = value ?? MaterialUnit.kg),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Points per unit',
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
                if (name.text.trim().isEmpty) return;
                ref
                    .read(appStoreProvider.notifier)
                    .addMaterial(
                      name: name.text.trim(),
                      unit: unit,
                      pointsPerUnit: double.tryParse(rate.text) ?? 0,
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('Add material'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext context, WidgetRef ref, MaterialItem material) {
    final rate = TextEditingController(
      text: material.pointsPerUnit.toStringAsFixed(0),
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${material.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rate,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Points per ${material.unit.label}',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Changing the rate affects new collections only.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted),
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
              ref
                  .read(appStoreProvider.notifier)
                  .updateMaterial(
                    material.id,
                    pointsPerUnit:
                        double.tryParse(rate.text) ?? material.pointsPerUnit,
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Save rate'),
          ),
        ],
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.material,
    required this.onEdit,
    required this.onAllowed,
    required this.onActive,
  });

  final MaterialItem material;
  final VoidCallback onEdit;
  final ValueChanged<bool> onAllowed;
  final ValueChanged<bool> onActive;

  @override
  Widget build(BuildContext context) {
    final excluded = !material.allowed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  excluded ? Icons.block : Icons.recycling,
                  size: 18,
                  color: excluded ? AppColors.danger : AppColors.leaf,
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    material.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: excluded ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              material.unit.label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              material.allowed
                  ? '${material.pointsPerUnit.toStringAsFixed(0)} pts'
                  : 'Excluded',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: material.allowed ? AppColors.forest : AppColors.danger,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Switch.adaptive(
                value: material.allowed,
                onChanged: (v) => onAllowed(v),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Switch.adaptive(
                value: material.active,
                onChanged: (v) => onActive(v),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: excluded ? null : onEdit,
              tooltip: 'Edit rate',
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
