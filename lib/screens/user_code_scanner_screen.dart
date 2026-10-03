import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Odczyt kodu QR chorego. Zwraca surową treść kodu.
class UserCodeScannerScreen extends StatefulWidget {
  const UserCodeScannerScreen({super.key});

  @override
  State<UserCodeScannerScreen> createState() => _UserCodeScannerScreenState();
}

class _UserCodeScannerScreenState extends State<UserCodeScannerScreen> {
  final _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );
  bool _locked = false;

  void _onDetect(BarcodeCapture capture) {
    if (_locked || !mounted) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;
      setState(() => _locked = true);
      Navigator.of(context).pop(raw);
      return;
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Latarka jest niedostępna.')),
        );
      }
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skanuj kod chorego'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) => IconButton(
              tooltip: state.torchState == TorchState.on
                  ? 'Wyłącz latarkę'
                  : 'Włącz latarkę',
              onPressed: _locked || state.torchState == TorchState.unavailable
                  ? null
                  : _toggleTorch,
              icon: Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  useAppLifecycleState: !_locked,
                  tapToFocus: true,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text(
                      error.errorCode == MobileScannerErrorCode.permissionDenied
                          ? 'Brak uprawnień do aparatu. Włącz aparat '
                                'w ustawieniach albo wpisz kod ręcznie.'
                          : 'Nie udało się uruchomić aparatu. '
                                'Wpisz kod chorego ręcznie.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  overlayBuilder: (context, constraints) => const IgnorePointer(
                    child: Center(
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.fromBorderSide(
                              BorderSide(color: Colors.white, width: 3),
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_locked)
                  const Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Skieruj aparat na kod QR z profilu chorego.',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Wpisz kod ręcznie'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
