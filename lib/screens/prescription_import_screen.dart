import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/medication.dart';
import '../models/prescription.dart';
import '../services/prescription_pdf_service.dart';
import '../services/dose_schedule.dart';
import '../widgets/care_components.dart';
import '../widgets/medication_form.dart';
import '../widgets/prototype_page.dart';
import '../widgets/section_card.dart';

class PrescriptionImportScreen extends StatefulWidget {
  const PrescriptionImportScreen({super.key, this.readPrescription});
  final Future<PrescriptionImport?> Function(void Function(String))?
  readPrescription;
  @override
  State<PrescriptionImportScreen> createState() =>
      _PrescriptionImportScreenState();
}

class _PrescriptionImportScreenState extends State<PrescriptionImportScreen> {
  PrescriptionImport? _result;
  List<MedicationStock?> _reviewed = [];
  List<bool> _included = [];
  bool _busy = false;
  bool _committed = false;
  String _progress = 'Otwieranie PDF…';
  String? _error;

  Future<void> _read() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      void progress(String value) {
        if (mounted) setState(() => _progress = value);
      }

      final result =
          await (widget.readPrescription?.call(progress) ??
              PrescriptionPdfService().pickAndRead(onProgress: progress));
      if (!mounted || result == null) return;
      setState(() {
        _result = result;
        _reviewed = List.filled(result.items.length, null);
        _included = List.filled(result.items.length, false);
      });
    } on PrescriptionReadException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Nie udało się otworzyć pliku. Wybierz PDF ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(int index) async {
    final draft = _result!.items[index];
    final stock = await showMedicationForm(
      context,
      initialStock:
          _reviewed[index] ??
          MedicationStock(
            product: draft.product,
            instruction: draft.instruction,
          ),
      prescriptionSource: draft.sourceText,
      prescribedPackages: draft.prescribedPackages,
    );
    if (!mounted || stock == null) return;
    setState(() {
      _reviewed[index] = stock;
      _included[index] = true;
    });
  }

  void _openPdf() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: careAppBar(context, 'Oryginał recepty'),
        body: PdfViewer.data(
          _result!.pdfBytes,
          sourceName: 'prescription-preview-${identityHashCode(_result)}',
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ready = [
      for (var i = 0; i < _reviewed.length; i++)
        if (_included[i] && _reviewed[i] != null) _reviewed[i]!,
    ];
    return Scaffold(
      appBar: careAppBar(context, 'Wczytaj receptę'),
      body: PrototypePage(
        children: [
          const CareHeading(
            'Leki z pliku PDF',
            subtitle:
                'Wybierz receptę, sprawdź odczytane dane i ustaw godziny dawek.',
          ),
          const CareNotice(
            'Odczyt odbywa się na urządzeniu. Przepisane opakowania nie są automatycznie dodawane do posiadanego zapasu.',
          ),
          OutlinedButton.icon(
            key: const Key('selectPrescriptionPdf'),
            onPressed: _busy ? null : _read,
            icon: const Icon(Icons.upload_file),
            label: Text(_result == null ? 'Wybierz PDF' : 'Wybierz inny PDF'),
          ),
          if (_busy) ...[
            const LinearProgressIndicator(),
            Semantics(liveRegion: true, child: Text(_progress)),
          ],
          if (_error != null) CareNotice(_error!, error: true),
          if (_result != null) ...[
            OutlinedButton.icon(
              onPressed: _openPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Pokaż oryginał PDF'),
            ),
            if (_result!.usedOcr)
              const CareNotice(
                'PDF zawiera skan. Sprawdź dokładnie cyfry, ułamki, nazwę i dawkowanie po rozpoznaniu tekstu.',
              ),
            for (final warning in _result!.warnings) CareNotice(warning),
            if (_result!.items.isEmpty)
              const CareNotice(
                'Nie odczytano leków. Spróbuj pobrać oryginalny PDF z IKP albo dodaj lek ręcznie.',
              ),
            for (var i = 0; i < _result!.items.length; i++)
              SectionCard(
                title: 'Lek ${i + 1}',
                icon: Icons.medication_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      (_reviewed[i]?.product ?? _result!.items[i].product)
                          .displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dawkowanie: ${(_reviewed[i]?.instruction ?? _result!.items[i].instruction).isEmpty ? 'do uzupełnienia' : (_reviewed[i]?.instruction ?? _result!.items[i].instruction)}',
                    ),
                    if (_reviewed[i]?.doseMinutes.isNotEmpty ?? false)
                      Text(
                        'Godziny: ${_reviewed[i]!.doseMinutes.map(doseTimeLabel).join(', ')} • ${_reviewed[i]!.everyDays == 1 ? 'codziennie' : 'co ${_reviewed[i]!.everyDays} dni'}',
                      ),
                    for (final warning in _result!.items[i].warnings)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: CareNotice(warning),
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      key: ValueKey('review-prescription-$i'),
                      onPressed: _busy ? null : () => _review(i),
                      child: Text(
                        _reviewed[i] == null
                            ? 'Sprawdź i ustaw godziny'
                            : 'Popraw dane',
                      ),
                    ),
                    if (_reviewed[i] != null)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Dodaj ten lek'),
                        value: _included[i],
                        onChanged: (value) =>
                            setState(() => _included[i] = value ?? false),
                      ),
                  ],
                ),
              ),
            if (_result!.items.isNotEmpty)
              FilledButton(
                key: const Key('savePrescriptionImport'),
                onPressed: ready.isEmpty || _busy || _committed
                    ? null
                    : () {
                        if (_committed) return;
                        setState(() => _committed = true);
                        Navigator.of(context).pop(ready);
                      },
                child: Text('Dodaj sprawdzone leki (${ready.length})'),
              ),
          ],
        ],
      ),
    );
  }
}
