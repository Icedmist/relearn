import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/demo_data.dart';
import '../../data/models.dart';

class CollectorHomeScreen extends ConsumerWidget {
  const CollectorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(demoStoreProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = state.collections
        .where(
          (c) =>
              c.at.year == now.year &&
              c.at.month == now.month &&
              c.at.day == now.day,
        )
        .toList();
    final todayPoints = today.fold(0, (s, c) => s + c.points);
    final todayKg = today.fold(0.0, (s, c) => s + c.kg);
    final recent = state.beneficiaries.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tuesday route · Gombe Model',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to collect',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const StatusPill(
                label: 'ONLINE',
                color: AppColors.leaf,
                icon: Icons.cloud_done_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: () => context.push('/collector/scan'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.forest, AppColors.leaf],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scan a QR card',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Point the camera at the pupil’s card',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/collector/search'),
                  icon: const Icon(Icons.search, size: 19),
                  label: const Text('Search by name or ID'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: () => context.go('/collector/history'),
                tooltip: 'History',
                icon: const Icon(Icons.receipt_long_outlined, size: 20),
                style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Today', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '${today.length}',
                  label: 'Collections',
                  icon: Icons.recycling,
                  color: AppColors.leaf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: '${todayKg.toStringAsFixed(1)} kg',
                  label: 'Collected',
                  icon: Icons.scale_outlined,
                  color: AppColors.sky,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: formatPoints(todayPoints),
                  label: 'Points',
                  icon: Icons.eco_outlined,
                  color: AppColors.sun,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Recent beneficiaries', style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/collector/search'),
                child: const Text('See all'),
              ),
            ],
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  InkWell(
                    onTap: () =>
                        context.push('/collector/beneficiary/${recent[i].id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          InitialsAvatar(
                            initials: recent[i].initials(),
                            size: 38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recent[i].name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${recent[i].publicId} · ${recent[i].className}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          BalancePill(points: recent[i].balance),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i < recent.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync, size: 18, color: AppColors.leaf),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All changes synced · 0 pending. Offline queue arrives in Stage 2.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
      ),
    );
  }
}
