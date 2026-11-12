import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
          subtitle:
              'Marketplace preview. Add photos, categories and descriptions; '
              'collectors see the same cards.',
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
                    height: 404,
                    child: _RewardCard(
                      reward: reward,
                      redemptions: state.redemptions
                          .where((r) => r.rewardName == reward.name)
                          .length,
                      onRestock: () => _showRestock(reward),
                      onEdit: () => _showEditor(reward),
                      onToggleActive: () => _toggleActive(reward),
                      onDelete: () => _delete(reward),
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

  Future<void> _showRestock(Reward reward) async {
    final qty = TextEditingController(text: '50');
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Restock ${reward.name}'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: qty,
            autofocus: true,
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
              final parsed = int.tryParse(qty.text.trim());
              if (parsed == null || parsed <= 0) return;
              Navigator.pop(dialogContext, parsed);
            },
            child: const Text('Add stock'),
          ),
        ],
      ),
    );
    qty.dispose();
    if (value == null || !mounted) return;
    final error = await ref
        .read(appStoreProvider.notifier)
        .restock(reward.id, value);
    if (!mounted) return;
    _notify(error ?? 'Added $value to ${reward.name}.');
  }

  Future<void> _toggleActive(Reward reward) async {
    final error = await ref
        .read(appStoreProvider.notifier)
        .updateReward(reward.id, active: !reward.active);
    if (!mounted) return;
    _notify(
      error ??
          (reward.active
              ? '${reward.name} hidden from the shop.'
              : '${reward.name} is visible in the shop.'),
    );
  }

  Future<void> _delete(Reward reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${reward.name}?'),
        content: const Text(
          'This permanently removes the item. If it already has redemptions, '
          'deactivate it instead so history stays intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await ref
        .read(appStoreProvider.notifier)
        .deleteReward(reward.id);
    if (!mounted) return;
    _notify(error ?? '${reward.name} deleted.');
  }

  Future<void> _showEditor([Reward? reward]) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RewardDialog(
        reward: reward,
        onSave: (draft) async {
          final store = ref.read(appStoreProvider.notifier);
          var imageUrl = draft.imageUrl;
          var clearImage = false;
          if (draft.imageBytes != null) {
            final name = draft.imageName ?? 'item.jpg';
            final lower = name.toLowerCase();
            final contentType = lower.endsWith('.png')
                ? 'image/png'
                : lower.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
            final upload = await store.uploadItemImage(
              bytes: draft.imageBytes!,
              fileName: name,
              contentType: contentType,
            );
            if (upload.error != null) return upload.error;
            imageUrl = upload.url;
          } else if (imageUrl == null || imageUrl.isEmpty) {
            clearImage = true;
          }

          if (reward == null) {
            return store.addReward(
              name: draft.name,
              pointsCost: draft.pointsCost,
              stock: draft.stock,
              category: draft.category,
              description: draft.description,
              imageUrl: imageUrl,
            );
          }
          return store.updateReward(
            reward.id,
            name: draft.name,
            pointsCost: draft.pointsCost,
            stock: draft.stock,
            active: draft.active,
            category: draft.category,
            description: draft.description,
            imageUrl: imageUrl,
            clearImage: clearImage,
            clearDescription: draft.description == null,
          );
        },
      ),
    );
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.redemptions,
    required this.onRestock,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final Reward reward;
  final int redemptions;
  final VoidCallback onRestock;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final low = reward.stock <= 10;
    final out = reward.stock == 0;
    final color = !reward.active
        ? AppColors.muted
        : out
        ? AppColors.danger
        : low
        ? const Color(0xFFB45309)
        : AppColors.leaf;
    final status = !reward.active
        ? 'HIDDEN'
        : out
        ? 'OUT OF STOCK'
        : low
        ? 'LOW STOCK'
        : 'IN STOCK';

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
                StatusPill(label: status, color: color),
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
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit item',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                PopupMenuButton<_ItemAction>(
                  tooltip: 'More actions',
                  onSelected: (action) => switch (action) {
                    _ItemAction.toggle => onToggleActive(),
                    _ItemAction.delete => onDelete(),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _ItemAction.toggle,
                      child: Text(
                        reward.active
                            ? 'Deactivate (hide from shop)'
                            : 'Activate (show in shop)',
                      ),
                    ),
                    const PopupMenuItem(
                      value: _ItemAction.delete,
                      child: Text('Delete permanently'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _ItemAction { toggle, delete }

class _RewardDraft {
  const _RewardDraft({
    required this.name,
    required this.pointsCost,
    required this.stock,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.active,
    this.imageBytes,
    this.imageName,
  });

  final String name;
  final int pointsCost;
  final int stock;
  final String category;
  final String? description;
  final String? imageUrl;
  final bool active;
  final Uint8List? imageBytes;
  final String? imageName;
}

class _RewardDialog extends StatefulWidget {
  const _RewardDialog({this.reward, required this.onSave});

  final Reward? reward;
  final Future<String?> Function(_RewardDraft draft) onSave;

  @override
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _points;
  late final TextEditingController _stock;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late String _category;
  late bool _active;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _saving = false;
  String? _error;

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (!mounted) return;
        setState(() {
          _error = 'That photo is larger than 5 MB. Choose a smaller image.';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not open the photo picker: $error');
    }
  }

  void _removePhoto() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
      _imageUrl.clear();
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final description = _description.text.trim();
    final imageUrl = _imageUrl.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(
      _RewardDraft(
        name: _name.text.trim(),
        pointsCost: int.parse(_points.text.trim()),
        stock: int.parse(_stock.text.trim()),
        category: _category,
        description: description.isEmpty ? null : description,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        active: _active,
        imageBytes: _imageBytes,
        imageName: _imageName,
      ),
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = _imageBytes != null || _imageUrl.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(_editing ? 'Edit item' : 'Add item'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhotoPreview(
                  bytes: _imageBytes,
                  url: _imageBytes == null ? _imageUrl.text.trim() : null,
                  category: _category,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 17),
                      label: const Text('Gallery'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined, size: 17),
                      label: const Text('Camera'),
                    ),
                    if (hasPhoto)
                      TextButton.icon(
                        onPressed: _saving ? null : _removePhoto,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 17,
                          color: AppColors.danger,
                        ),
                        label: const Text(
                          'Remove photo',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  enabled: !_saving,
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
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _category = value ?? 'Other'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  enabled: !_saving,
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
                        enabled: !_saving,
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
                        enabled: !_saving,
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
                  enabled: !_saving,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://…/item-images/photo.jpg',
                    helperText:
                        'Upload a photo above, or paste a public image URL.',
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
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _active = value),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_editing ? 'Save changes' : 'Add item'),
        ),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.bytes,
    required this.url,
    required this.category,
  });

  final Uint8List? bytes;
  final String? url;
  final String category;

  @override
  Widget build(BuildContext context) {
    final tint = itemColor(category);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        width: double.infinity,
        color: tint.withValues(alpha: 0.1),
        child: bytes != null
            ? Image.memory(bytes!, fit: BoxFit.cover)
            : url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(tint),
              )
            : _placeholder(tint),
      ),
    );
  }

  Widget _placeholder(Color tint) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(itemIcon(category), size: 38, color: tint),
          const SizedBox(height: 6),
          Text('No photo yet', style: TextStyle(color: tint, fontSize: 12)),
        ],
      ),
    );
  }
}
