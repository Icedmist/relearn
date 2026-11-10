import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/demo_data.dart';
import '../../data/models.dart';

class RegisterBeneficiaryScreen extends ConsumerStatefulWidget {
  const RegisterBeneficiaryScreen({super.key});

  @override
  ConsumerState<RegisterBeneficiaryScreen> createState() =>
      _RegisterBeneficiaryScreenState();
}

class _RegisterBeneficiaryScreenState
    extends ConsumerState<RegisterBeneficiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _className = TextEditingController();
  final _guardian = TextEditingController();
  BeneficiaryType _type = BeneficiaryType.pupil;
  String? _schoolId;
  bool _importMode = false;

  @override
  void dispose() {
    _name.dispose();
    _className.dispose();
    _guardian.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final created = ref
        .read(demoStoreProvider.notifier)
        .addBeneficiary(
          name: _name.text.trim(),
          type: _type,
          schoolId: _schoolId!,
          className: _className.text.trim(),
          guardianPhone: _guardian.text.trim().isEmpty
              ? null
              : _guardian.text.trim(),
        );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Beneficiary registered'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: created.publicId,
                      size: 170,
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
                    const SizedBox(height: 10),
                    Text(
                      created.publicId,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${created.name} · ${created.type.label} · ${created.className}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Register another'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/admin/beneficiaries/${created.id}');
            },
            child: const Text('View profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(demoStoreProvider);
    final activeSchools = state.schools.where((s) => s.active).toList();

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
          eyebrow: 'Registration',
          title: 'Register beneficiary',
          subtitle: 'One person at a time, or import a whole class from CSV.',
          actions: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Single entry'),
                  icon: Icon(Icons.person_outline),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('CSV import'),
                  icon: Icon(Icons.upload_file_outlined),
                ),
              ],
              selected: {_importMode},
              onSelectionChanged: (value) =>
                  setState(() => _importMode = value.first),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final form = _importMode
                ? _CsvPanel(onBack: () => setState(() => _importMode = false))
                : _buildForm(activeSchools);
            if (!wide) return form;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: form),
                const SizedBox(width: 16),
                const Expanded(flex: 2, child: _RegistrationGuide()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildForm(List<School> schools) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Person details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'The ID and QR are generated on the server after saving.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Enter the full name'
                    : null,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<BeneficiaryType>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: BeneficiaryType.pupil,
                      label: Text('Pupil'),
                      icon: Icon(Icons.child_care),
                    ),
                    ButtonSegment(
                      value: BeneficiaryType.teacher,
                      label: Text('Teacher'),
                      icon: Icon(Icons.co_present_outlined),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (value) =>
                      setState(() => _type = value.first),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _schoolId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'School',
                  prefixIcon: Icon(Icons.school_outlined, size: 20),
                ),
                items: [
                  for (final school in schools)
                    DropdownMenuItem(
                      value: school.id,
                      child: Text(school.name),
                    ),
                ],
                onChanged: (value) => setState(() => _schoolId = value),
                validator: (value) => value == null ? 'Choose a school' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _className,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  hintText: 'e.g. Primary 5',
                  prefixIcon: Icon(Icons.class_outlined, size: 20),
                ),
                validator: (value) =>
                    _type == BeneficiaryType.pupil &&
                        (value == null || value.trim().isEmpty)
                    ? 'Class is required for pupils'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _guardian,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Guardian phone (optional)',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/admin/beneficiaries'),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.qr_code_2, size: 19),
                      label: const Text('Save and generate card'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CsvPanel extends StatelessWidget {
  const _CsvPanel({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.leaf.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.leaf.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.upload_file_outlined,
                    size: 40,
                    color: AppColors.leaf,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Drop a CSV here',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Columns: name, type, school, class, guardian_phone',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'File picking and validation land in Stage 1 (P1).',
                        ),
                      ),
                    ),
                    child: const Text('Choose file'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Template download is wired in Stage 1.'),
                      ),
                    ),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download template'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Import requires the Stage 1 repository.',
                        ),
                      ),
                    ),
                    child: const Text('Preview import'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Valid rows import; invalid rows are reported with row numbers. '
              'Imports are idempotent per file hash to prevent double uploads.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationGuide extends StatelessWidget {
  const _RegistrationGuide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SectionCard(
          title: 'What gets created',
          child: Column(
            children: [
              _GuideStep(
                number: '1',
                title: 'Public ID',
                body: 'Readable format like RL-0042-7K3Q, no 0/O or 1/I.',
              ),
              _GuideStep(
                number: '2',
                title: 'QR code',
                body: 'Encodes the public ID only — no personal data.',
              ),
              _GuideStep(
                number: '3',
                title: 'Card PDF',
                body: 'Eight cards per A4 page, ready for a local printer.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: AppColors.sun.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data protection', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  'Collect the minimum. Guardian phone is optional and only visible to authorised staff. '
                  'Never put a phone number or school on the QR.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.leaf.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.forest,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
