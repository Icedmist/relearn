import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class PrintCardsScreen extends ConsumerStatefulWidget {
  const PrintCardsScreen({super.key});

  @override
  ConsumerState<PrintCardsScreen> createState() => _PrintCardsScreenState();
}

class _PrintCardsScreenState extends ConsumerState<PrintCardsScreen> {
  String? _schoolId;
  String _className = 'all';
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStoreProvider);
    final schoolId =
        _schoolId ?? (state.schools.isNotEmpty ? state.schools.first.id : null);
    final school = schoolId == null ? null : state.schoolById(schoolId);
    final classes =
        state.beneficiaries
            .where((b) => b.schoolId == schoolId)
            .map((b) => b.className)
            .toSet()
            .toList()
          ..sort();
    final filtered = state.beneficiaries
        .where(
          (b) =>
              b.schoolId == schoolId &&
              (_className == 'all' || b.className == _className),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Identification',
          title: 'Print cards',
          subtitle: 'Eight cards per A4 page. QR encodes the public ID only.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => setState(() {
                if (_selected.length == filtered.length) {
                  _selected.clear();
                } else {
                  _selected
                    ..clear()
                    ..addAll(filtered.map((b) => b.id));
                }
              }),
              icon: Icon(
                _selected.length == filtered.length
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
                size: 18,
              ),
              label: Text(
                _selected.length == filtered.length
                    ? 'Clear selection'
                    : 'Select all',
              ),
            ),
            FilledButton.icon(
              onPressed: filtered.isEmpty
                  ? null
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'PDF export for ${_selected.isEmpty ? filtered.length : _selected.length} '
                          'card(s) is wired in Stage 1 (pdf + printing).',
                        ),
                      ),
                    ),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Export PDF'),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final filters = SectionCard(
              title: 'Filters',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: schoolId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'School'),
                    items: [
                      for (final s in state.schools)
                        DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ],
                    onChanged: (value) => setState(() {
                      _schoolId = value;
                      _className = 'all';
                      _selected.clear();
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _className,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All classes'),
                      ),
                      for (final c in classes)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (value) => setState(() {
                      _className = value ?? 'all';
                      _selected.clear();
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${filtered.length} card(s) · ${(filtered.length / 8).ceil()} A4 page(s)',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Selected: ${_selected.length}. Crop marks and 25 mm minimum QR are applied in the PDF.',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _checkLine('School name and class printed'),
                  _checkLine('Public ID in tabular text'),
                  _checkLine('QR quiet zone preserved'),
                  _checkLine('8 cards per A4 sheet'),
                ],
              ),
            );

            final preview = SectionCard(
              title: 'A4 preview',
              subtitle: school?.name ?? 'Select a school',
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBDF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.print_disabled_outlined,
                        title: 'No cards to preview',
                        message:
                            'Choose a school with registered beneficiaries.',
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final b in filtered.take(12))
                            SizedBox(
                              width: 236,
                              child: _CardPreview(
                                beneficiary: b,
                                schoolName: school?.name ?? '',
                                selected:
                                    _selected.isEmpty ||
                                    _selected.contains(b.id),
                                onTap: () => setState(() {
                                  if (_selected.isEmpty) {
                                    _selected.addAll(filtered.map((x) => x.id));
                                  }
                                  if (_selected.contains(b.id)) {
                                    _selected.remove(b.id);
                                  } else {
                                    _selected.add(b.id);
                                  }
                                }),
                              ),
                            ),
                        ],
                      ),
              ),
            );

            if (!wide) {
              return Column(
                children: [filters, const SizedBox(height: 16), preview],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 320, child: filters),
                const SizedBox(width: 16),
                Expanded(child: preview),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => context.go('/admin/beneficiaries'),
          icon: const Icon(Icons.arrow_back, size: 17),
          label: const Text('Back to beneficiaries'),
        ),
      ],
    );
  }

  Widget _checkLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 15, color: AppColors.leaf),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.beneficiary,
    required this.schoolName,
    required this.selected,
    required this.onTap,
  });

  final Beneficiary beneficiary;
  final String schoolName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.leaf : AppColors.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.leaf,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ReLearn',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'RECYCLE TO LEARN',
                      style: TextStyle(
                        fontSize: 5.5,
                        color: AppColors.muted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            beneficiary.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${beneficiary.type.label} · ${beneficiary.className}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 7.5,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            schoolName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 6.5,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            beneficiary.publicId,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    QrImageView(
                      data: beneficiary.publicId,
                      size: 52,
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
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'This card belongs to your school. Return it if found.',
                  style: TextStyle(fontSize: 5.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (!selected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 17,
              color: selected ? AppColors.leaf : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
