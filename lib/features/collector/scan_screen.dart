import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/demo_data.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _torch = false;
  bool _handling = false;

  void _found(String beneficiaryId) {
    if (_handling) return;
    setState(() => _handling = true);
    context.pushReplacement('/collector/beneficiary/$beneficiaryId');
  }

  void _simulateScan() {
    final state = ref.read(demoStoreProvider);
    if (state.beneficiaries.isEmpty) return;
    _found(state.beneficiaries.first.id);
  }

  void _manualEntry() {
    final controller = TextEditingController();
    final state = ref.read(demoStoreProvider);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter beneficiary ID'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Public ID',
              hintText: 'RL-0042-7K3Q',
              helperText: 'The last character is a check character.',
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
              final query = controller.text.trim().toUpperCase();
              final match = state.beneficiaries.where(
                (b) => b.publicId == query,
              );
              Navigator.pop(dialogContext);
              if (match.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No beneficiary found for that ID. Check the check character.',
                    ),
                  ),
                );
                return;
              }
              _found(match.first.id);
            },
            child: const Text('Find'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1F14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan QR card'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
        ),
        actions: [
          IconButton(
            tooltip: 'Flashlight',
            onPressed: () => setState(() => _torch = !_torch),
            icon: Icon(_torch ? Icons.flashlight_on : Icons.flashlight_off),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'Point the camera at the QR on the card',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The scan is debounced so one card cannot credit twice.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11.5,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.qr_code_2,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  const _Corner(top: true, left: true),
                  const _Corner(top: true, right: true),
                  const _Corner(bottom: true, left: true),
                  const _Corner(bottom: true, right: true),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_outlined,
                    size: 14,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Camera preview · simulated in Stage 0',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _simulateScan,
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      label: const Text('Simulate a successful scan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.sun,
                        foregroundColor: AppColors.ink,
                        minimumSize: const Size(0, 56),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _manualEntry,
                      icon: const Icon(Icons.keyboard_outlined, size: 19),
                      label: const Text('Enter ID manually'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Stage 2 replaces this with mobile_scanner and a real camera request. '
                    'Permission denied and camera errors are handled there.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({
    this.top = false,
    this.bottom = false,
    this.left = false,
    this.right = false,
  });

  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: bottom ? 0 : null,
      left: left ? 0 : null,
      right: right ? 0 : null,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: AppColors.sun, width: 4)
                : BorderSide.none,
            bottom: bottom
                ? const BorderSide(color: AppColors.sun, width: 4)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: AppColors.sun, width: 4)
                : BorderSide.none,
            right: right
                ? const BorderSide(color: AppColors.sun, width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(24) : Radius.zero,
            topRight: top && right ? const Radius.circular(24) : Radius.zero,
            bottomLeft: bottom && left
                ? const Radius.circular(24)
                : Radius.zero,
            bottomRight: bottom && right
                ? const Radius.circular(24)
                : Radius.zero,
          ),
        ),
      ),
    );
  }
}
