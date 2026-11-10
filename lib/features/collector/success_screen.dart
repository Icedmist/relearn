import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    super.key,
    required this.action,
    required this.points,
    required this.balance,
    required this.beneficiaryId,
  });

  final String action;
  final int points;
  final int balance;
  final String beneficiaryId;

  @override
  Widget build(BuildContext context) {
    final collecting = action == 'collect';
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.leaf.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 54,
                      color: AppColors.leaf,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    collecting ? 'Collection recorded' : 'Reward redeemed',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    collecting
                        ? 'Points are now in the beneficiary’s ledger.'
                        : 'Points and stock were updated in one transaction.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${collecting ? '+' : '−'}${formatPoints(points)} pts',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: collecting
                                ? AppColors.leaf
                                : AppColors.danger,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'New balance',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          '${formatPoints(balance)} pts',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.go('/collector/scan'),
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      label: const Text('Scan next card'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/collector/home'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 54),
                      ),
                      child: const Text('Back to home'),
                    ),
                  ),
                  if (beneficiaryId.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () =>
                          context.go('/collector/beneficiary/$beneficiaryId'),
                      child: const Text('View beneficiary'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'An idempotency key prevents this action from being applied twice if the network retries.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
