import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/item_art.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  String _category = 'All';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStoreProvider);
    final query = _search.text.trim().toLowerCase();
    final visible = state.rewards.where((reward) {
      final categoryOk = _category == 'All' || reward.category == _category;
      final searchOk =
          query.isEmpty ||
          reward.name.toLowerCase().contains(query) ||
          (reward.description ?? '').toLowerCase().contains(query);
      return categoryOk && searchOk;
    }).toList();
    final categories = [
      'All',
      ...{for (final reward in state.rewards) reward.category},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Catalogue',
          title: 'Item shop',
          subtitle: 'Marketplace preview. Add photos, categories and descriptions; collectors see the same cards.',
          actions: [
            FilledButton.icon(
              onPressed: () => _showEditor(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add item'),
            ),
          ],
        ),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search items',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in categories) ...[
                ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1080
                ? 4
                : constraints.maxWidth >= 760
                ? 3
                : constraints.maxWidth >= 480
                ? 2
                : 1;
            const gap = 16.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            if (visible.isEmpty) {
              return const EmptyState(
                icon: Icons.storefront_outlined,
                title: 'No items match',
                message: 'Try another category or search term.',
              );
            }
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final reward in visible)
                  SizedBox(
                    width: width,
                    height: 392,
                    child: _RewardCard(
                      reward: reward,
                      redemptions: state.redemptions
                          .where((r) => r.rewardName == reward.name)
                          .length,
                      onRestock: () => _showRestock(reward),
                      onEdit: () => _showEditor(reward),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Recent redemptions',
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: state.redemptions.isEmpty
              ? const EmptyState(
                  icon: Icons.redeem_outlined,
                  title: 'No redemptions yet',
                  message: 'Rewards given by collectors will appear here.',
                )
              : Column(
                  children: [
                    for (final r in state.redemptions.take(8))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard,
                              size: 18,
                              color: AppColors.sun,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${state.beneficiaryById(r.beneficiaryId)?.name ?? 'Unknown'} · '
                                '${r.rewardName} × ${r.qty}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              '−${formatPoints(r.points)} pts',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: AppColors.danger,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              formatDateShort(r.at),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  void _showRestock(Reward reward) {
    final qty = TextEditingController(text: '50');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Restock ${reward.name}'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: qty,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantity to add',
              helperText: 'Current stock: ${reward.stock}',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(qty.text);
              if (value == null || value <= 0) return;
              ref.read(appStoreProvider.notifier).restock(reward.id, value);
              Navigator.pop(dialogContext);
            },
            child: const Text('Add stock'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditor([Reward? reward]) async {
    final draft = await showDialog<_RewardDraft>(
      context: context,
      builder: (_) => _RewardDialog(reward: reward),
    );
    if (draft == null) return;
    final store = ref.read(appStoreProvider.notifier);
    if (reward == null) {
      store.addReward(
        name: draft.name,
        pointsCost: draft.pointsCost,
        stock: draft.stock,
        category: draft.category,
        description: draft.description,
        imageUrl: draft.imageUrl,
      );
    } else {
      store.updateReward(
        reward.id,
        name: draft.name,
        pointsCost: draft.pointsCost,
        stock: draft.stock,
        active: draft.active,
        category: draft.category,
        description: draft.description,
        imageUrl: draft.imageUrl,
      );
    }
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.redemptions,
    required this.onRestock,
    required this.onEdit,
  });

  final Reward reward;
  final int redemptions;
  final VoidCallback onRestock;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final low = reward.stock <= 10;
    final out = reward.stock == 0;
    final color = out
        ? AppColors.danger
        : low
        ? const Color(0xFFB45309)
        : AppColors.leaf;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemArt(
              category: reward.category,
              imageUrl: reward.imageUrl,
              height: 112,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  reward.category.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: itemColor(reward.category),
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                StatusPill(
                  label: out
                      ? 'OUT OF STOCK'
                      : low
                      ? 'LOW STOCK'
                      : 'IN STOCK',
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              reward.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                reward.description ?? 'No description yet.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted, height: 1.35),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPoints(reward.pointsCost),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'pts',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ),
                const Spacer(),
                Text(
                  '${reward.stock} left',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: out ? AppColors.danger : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$redemptions given',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRestock,
                    icon: const Icon(Icons.add_box_outlined, size: 17),
                    label: const Text('Restock'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit item',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardDraft {
  const _RewardDraft({
    required this.name,
    required this.pointsCost,
    required this.stock,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.active,
  });

  final String name;
  final int pointsCost;
  final int stock;
  final String category;
  final String? description;
  final String? imageUrl;
  final bool active;
}

class _RewardDialog extends StatefulWidget {
  const _RewardDialog({this.reward});

  final Reward? reward;

  @override
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _points;
  late final TextEditingController _stock;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late String _category;
  late bool _active;

  bool get _editing => widget.reward != null;

  @override
  void initState() {
    super.initState();
    final reward = widget.reward;
    _name = TextEditingController(text: reward?.name ?? '');
    _points = TextEditingController(
      text: (reward?.pointsCost ?? 50).toString(),
    );
    _stock = TextEditingController(text: (reward?.stock ?? 100).toString());
    _description = TextEditingController(text: reward?.description ?? '');
    _imageUrl = TextEditingController(text: reward?.imageUrl ?? '');
    _category = reward?.category ?? 'Stationery';
    _active = reward?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _points.dispose();
    _stock.dispose();
    _description.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final description = _description.text.trim();
    final imageUrl = _imageUrl.text.trim();
    Navigator.pop(
      context,
      _RewardDraft(
        name: _name.text.trim(),
        pointsCost: int.parse(_points.text.trim()),
        stock: int.parse(_stock.text.trim()),
        category: _category,
        description: description.isEmpty ? null : description,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        active: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_editing ? 'Edit item' : 'Add item'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    hintText: 'e.g. Geometry set',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Enter an item name.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final category in itemCategories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'Other'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Short line shown in the shop',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _points,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Points'),
                        validator: (value) {
                          final points = int.tryParse((value ?? '').trim());
                          return points == null || points <= 0
                              ? 'Use a positive number.'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        validator: (value) {
                          final stock = int.tryParse((value ?? '').trim());
                          return stock == null || stock < 0
                              ? 'Use 0 or more.'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://…/item-images/photo.jpg',
                    helperText: 'Upload photos to the item-images bucket, then paste the public URL.',
                    helperMaxLines: 2,
                  ),
                ),
                if (_editing) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Visible in the shop',
                      style: theme.textTheme.bodyMedium,
                    ),
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_editing ? 'Save changes' : 'Add item'),
        ),
      ],
    );
  }
}
