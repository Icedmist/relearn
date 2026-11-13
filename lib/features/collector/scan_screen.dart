import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  /// Widget tests cannot start a real camera plugin. The production app never
  /// flips this flag; the manual-ID path remains available either way.
  @visibleForTesting
  static bool cameraDisabledForTests = false;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  MobileScannerController? _controller;
  bool _handling = false;
  bool _torchOn = false;
  String? _message;

  bool get _cameraSupported =>
      !kIsWeb &&
      !ScanScreen.cameraDisabledForTests &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_cameraSupported) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
        torchEnabled: false,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handling) return;
    String? raw;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        raw = value.trim();
        break;
      }
    }
    if (raw == null) return;
    _lookup(raw);
  }

  Future<void> _lookup(String raw) async {
    if (_handling) return;
    final query = raw.trim().toUpperCase();
    final state = ref.read(appStoreProvider);
    Beneficiary? match;
    for (final b in state.beneficiaries) {
      if (b.publicId.toUpperCase() == query || b.id == raw.trim()) {
        match = b;
        break;
      }
    }

    if (match == null) {
      if (_message == query) return; // Don't spam the same failed scan.
      setState(() {
        _message =
            'No card with ID “$query” in your school. Check the card or use '
            'manual entry.';
      });
      return;
    }

    setState(() {
      _handling = true;
      _message = null;
    });
    await _controller?.stop();
    if (!mounted) return;
    context.pushReplacement('/collector/beneficiary/${match.id}');
  }

  void _openSampleCard() {
    final beneficiaries = ref.read(appStoreProvider).beneficiaries;
    if (beneficiaries.isEmpty) {
      setState(() => _message = 'No beneficiaries are available in demo mode.');
      return;
    }
    context.pushReplacement('/collector/beneficiary/${beneficiaries.first.id}');
  }

  void _manualEntry() {
    final controller = TextEditingController();
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
            onSubmitted: (value) {
              Navigator.pop(dialogContext);
              _lookup(value);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text;
              Navigator.pop(dialogContext);
              _lookup(value);
            },
            child: const Text('Find'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.toggleTorch();
    if (!mounted) return;
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _switchCamera() async {
    await _controller?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1F14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan a card'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
        ),
        actions: [
          if (_cameraSupported) ...[
            IconButton(
              tooltip: _torchOn ? 'Turn torch off' : 'Turn torch on',
              onPressed: _toggleTorch,
              icon: Icon(_torchOn ? Icons.flashlight_on : Icons.flashlight_off),
            ),
            IconButton(
              tooltip: 'Switch camera',
              onPressed: _switchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
            ),
          ],
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                children: [
                  Text(
                    'Point the camera at the QR code on the pupil’s card',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cameraSupported
                        ? 'The card opens as soon as the QR is read.'
                        : 'Camera scanning needs the Android app. Use the '
                              'public ID printed under the QR code here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (_message != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 17,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _message!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_cameraSupported && _controller != null)
                              MobileScanner(
                                controller: _controller,
                                onDetect: _onDetect,
                                errorBuilder: (context, error) =>
                                    _CameraProblem(error: error),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.qr_code_2,
                                    size: 140,
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                              ),
                            IgnorePointer(
                              child: Stack(
                                children: [
                                  const Positioned(
                                    top: 0,
                                    left: 0,
                                    child: _Corner(top: true, left: true),
                                  ),
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: _Corner(top: true, right: true),
                                  ),
                                  const Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: _Corner(bottom: true, left: true),
                                  ),
                                  const Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: _Corner(bottom: true, right: true),
                                  ),
                                  if (_handling)
                                    const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  if (AppConfig.demoMode) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openSampleCard,
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        label: const Text('Open a sample card'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sun,
                          foregroundColor: AppColors.ink,
                          minimumSize: const Size(0, 56),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
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
                    'The public ID is printed on every card. The last character '
                    'is a check character.',
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

class _CameraProblem extends StatelessWidget {
  const _CameraProblem({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: const Color(0xFF0B1F14),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            denied
                ? Icons.no_photography_outlined
                : Icons.videocam_off_outlined,
            size: 42,
            color: Colors.white70,
          ),
          const SizedBox(height: 14),
          Text(
            denied ? 'Camera permission is off' : 'The camera could not start',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            denied
                ? 'Allow camera access for ReLearn in Android settings, then '
                      'reopen this screen. You can still enter the ID manually.'
                : 'Use manual entry, or reopen the screen. ${error.errorCode.name}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
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
    return SizedBox(
      width: 46,
      height: 46,
      child: Container(
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
