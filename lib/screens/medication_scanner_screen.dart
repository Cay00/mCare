import '../widgets/care_components.dart';
import '../widgets/scanner_layout.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/medication.dart';
import '../services/gtin.dart';
import '../services/rpl_repository.dart';

/// UX adapted from Masasucha ScanLabelScreen: guide, torch, status, cancel,
/// and a single typed result returned to the previous form.
class MedicationScannerScreen extends StatefulWidget {
  const MedicationScannerScreen({super.key, this.repository});

  final RplRepository? repository;

  @override
  State<MedicationScannerScreen> createState() =>
      _MedicationScannerScreenState();
}

class _MedicationScannerScreenState extends State<MedicationScannerScreen> {
  final _controller = MobileScannerController(
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.itf14,
      BarcodeFormat.code128,
      BarcodeFormat.dataMatrix,
    ],
    detectionSpeed: DetectionSpeed.normal,
  );
  static final _repository = RplRepository();
  bool _locked = false;
  bool _loading = false;
  String? _error;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_locked || !mounted) return;
    String? code;
    var hasValue = false;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      hasValue = true;
      final normalized = gtinFromBarcode(raw);
      if (normalized != null) {
        code = normalized;
        break;
      }
    }
    if (!hasValue) return;
    setState(() {
      _locked = true;
      _loading = code != null;
      _error = code == null ? 'Nie rozpoznano poprawnego kodu EAN/GTIN.' : null;
    });
    try {
      await _controller.stop();
      if (code == null ||
          !mounted ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final product = await (widget.repository ?? _repository).findByBarcode(
        code,
      );
      // A popped route stays mounted during its exit animation. Do not pop
      // the previous screen if lookup finishes in that interval.
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      if (product == null) {
        setState(() => _error = 'Nie znaleziono leku dla zeskanowanego kodu.');
      } else {
        Navigator.of(context).pop<MedicationProduct>(product);
      }
    } on AmbiguousMedicationException {
      if (mounted) {
        setState(
          () => _error =
              'Kod wskazuje różne opakowania w rejestrze. '
              'Wpisz dane leku ręcznie.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Nie udało się odczytać danych leku. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _locked = false;
    });
    try {
      await _controller.start();
    } catch (_) {
      if (mounted) {
        setState(() {
          _locked = true;
          _error =
              'Nie udało się uruchomić aparatu. '
              'Sprawdź uprawnienie do aparatu w ustawieniach aplikacji.';
        });
      }
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
      appBar: careAppBar(
        context,
        'Skanuj kod leku',
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) => IconButton(
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
      body: ScannerLayout(
        instruction:
            'Skieruj aparat na kod kreskowy lub DataMatrix na opakowaniu leku.',
        preview: MobileScanner(
          controller: _controller,
          useAppLifecycleState: !_locked,
          tapToFocus: true,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? 'Brak uprawnień do aparatu. Włącz dostęp do aparatu '
                              'w ustawieniach aplikacji i spróbuj ponownie.'
                        : 'Nie udało się uruchomić aparatu.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _retry,
                    child: const Text('Spróbuj ponownie'),
                  ),
                ],
              ),
            ),
          ),
          overlayBuilder: (context, constraints) => IgnorePointer(
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.85,
                child: AspectRatio(
                  aspectRatio: 1.6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          if (_loading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text('Wyszukiwanie leku w rejestrze…'),
            ),
          ],
          if (_error != null) ...[
            CareNotice(_error!, error: true),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _retry,
              child: const Text('Skanuj ponownie'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Wróć'),
          ),
        ],
      ),
    );
  }
}
