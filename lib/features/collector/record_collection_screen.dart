import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class RecordCollectionScreen extends ConsumerStatefulWidget {
  const RecordCollectionScreen({super.key, required this.beneficiaryId});

  final String beneficiaryId;

  @override
  ConsumerState<RecordCollectionScreen> createState() =>
      _RecordCollectionScreenState();
}

class _RecordCollectionScreenState
    extends ConsumerState<RecordCollectionScreen> {
  final List<({MaterialItem material, double quantity})> _lines = [];

  @override
  void initState() {
    super.initState();
    final materials = ref
        .read(appStoreProvider)
        .materials
        .where((m) => m.allowed && m.active)
        .toList();
    if (materials.isNotEmpty) {
      _lines.add((material: materials.first, quantity: 2));
    }
  }

  int get _total => _lines.fold(
    0,
    (sum, line) => sum + (line.quantity * line.material.pointsPerUnit).round(),
  );

  double _step(MaterialItem material) =>
      material.unit == MaterialUnit.kg ? 0.5 : 1;

  void _changeQty(int index, double delta) {
    final line = _lines[index];
    final next = line.quantity + delta;
    if (next <= 0) return;
    setState(() => _lines[index] = (material: line.material, quantity: next));
  }

  void _addMaterial() {
    final state = ref.read(appStoreProvider);
    final available = state.materials
        .where((m) => m.allowed && m.active)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'Add material',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final material in available)
              ListTile(
                leading: const Icon(Icons.recycling, color: AppColors.leaf),
                title: Text(material.name),
                subtitle: Text(
                  '${material.pointsPerUnit.toStringAsFixed(0)} pts / ${material.unit.label}',
                ),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final existing = _lines.indexWhere(
                    (l) => l.material.id == material.id,
                  );
                  setState(() {
                    if (existing >= 0) {
                      final line = _lines[existing];
                      _lines[existing] = (
                        material: line.material,
                        quantity: line.quantity + _step(material),
                      );
                    } else {
                      _lines.add((
                        material: material,
                        quantity: _step(material),
                      ));
                    }
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one material line.')),
      );
      return;
    }
    final points = await ref
        .read(appStoreProvider.notifier)
        .recordCollection(beneficiaryId: widget.beneficiaryId, lines: _lines);
    if (!mounted) return;
    if (points == null) {
      final error =
          ref.read(appStoreProvider).error ??
          'Could not record the collection. Try again.';
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
    context.pushReplacement(
      '/collector/success?action=collect&points=$points&balance=$balance&beneficiary=${widget.beneficiaryId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStoreProvider);
    final beneficiary = state.beneficiaryById(widget.beneficiaryId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record collection'),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (beneficiary != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          InitialsAvatar(
                            initials: beneficiary.initials(),
                            size: 38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  beneficiary.name,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  beneficiary.publicId,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          BalancePill(points: beneficiary.balance),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Materials received',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addMaterial,
                        icon: const Icon(Icons.add, size: 17),
                        label: const Text('Add material'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_lines.isEmpty)
                    const Card(
                      child: EmptyState(
                        icon: Icons.recycling_outlined,
                        title: 'No material lines',
                        message:
                            'Add paper, bottles, cans or wrappers to start.',
                      ),
                    )
                  else
                    for (var i = 0; i < _lines.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LineCard(
                          material: _lines[i].material,
                          quantity: _lines[i].quantity,
                          points:
                              (_lines[i].quantity *
                                      _lines[i].material.pointsPerUnit)
                                  .round(),
                          step: _step(_lines[i].material),
                          onMinus: () =>
                              _changeQty(i, -_step(_lines[i].material)),
                          onPlus: () =>
                              _changeQty(i, _step(_lines[i].material)),
                          onRemove: () => setState(() => _lines.removeAt(i)),
                        ),
                      ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.leaf.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.leaf.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.eco_outlined, color: AppColors.leaf),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Points preview',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                'Server recalculates with the current rate on confirm.',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.muted,
                                      fontSize: 10.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${formatPoints(_total)} pts',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sync, size: 17, color: AppColors.leaf),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'The collection is saved immediately and points are '
                            'credited to the card in the same transaction.',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.muted, height: 1.4),
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
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  child: Text(
                    'Confirm collection · +${formatPoints(_total)} pts',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.material,
    required this.quantity,
    required this.points,
    required this.step,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  final MaterialItem material;
  final double quantity;
  final int points;
  final double step;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final qtyText = material.unit == MaterialUnit.kg
        ? '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)} kg'
        : '${quantity.toInt()} pcs';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.leaf.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.recycling,
                    size: 18,
                    color: AppColors.leaf,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.name,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${material.pointsPerUnit.toStringAsFixed(0)} pts / ${material.unit.label}',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'Remove line',
                  icon: const Icon(Icons.close, size: 17),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _QtyButton(icon: Icons.remove, onTap: onMinus),
                Container(
                  width: 92,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    qtyText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                _QtyButton(icon: Icons.add, onTap: onPlus),
                const Spacer(),
                Text(
                  '+${formatPoints(points)} pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                    fontSize: 14,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
