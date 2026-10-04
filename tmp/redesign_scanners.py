from pathlib import Path
for name in ['medication','user_code']:
 p=Path(f'lib/screens/{name}_scanner_screen.dart'); s=p.read_text(encoding='utf-8')
 s="import '../widgets/care_components.dart';\nimport '../widgets/scanner_layout.dart';\n"+s
 s=s.replace("appBar: AppBar(\n        title: const Text('Skanuj kod leku'),", "appBar: careAppBar(context, 'Skanuj kod leku',").replace("appBar: AppBar(\n        title: const Text('Skanuj kod chorego'),", "appBar: careAppBar(context, 'Skanuj kod chorego',")
 start=s.index('      body: Column(')
 camstart=s.index('                MobileScanner(',start)
 camend=s.index('                if (!_locked)',camstart)
 camera=s[camstart:camend].strip().removesuffix(',')
 # Camera errors can exceed the preview height with large system text.
 if name=='medication':
  camera=camera.replace('child: Column(\n                      mainAxisSize:', 'child: SingleChildScrollView(child: Column(\n                      mainAxisSize:')
  camera=camera.replace("                    ),\n                  ),\n                  overlayBuilder", "                    )),\n                  ),\n                  overlayBuilder")
 else:
  camera=camera.replace('child: Text(\n                      error.errorCode','child: SingleChildScrollView(child: Text(\n                      error.errorCode')
  camera=camera.replace("                    ),\n                  ),\n                  overlayBuilder", "                    )),\n                  ),\n                  overlayBuilder")
 if name=='medication':
  footer="""if (_loading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            const Semantics(liveRegion: true, child: Text('Wyszukiwanie leku w rejestrze…')),
          ],
          if (_error != null) ...[
            CareNotice(_error!, error: true),
            const SizedBox(height: 16),
            FilledButton(onPressed: _retry, child: const Text('Skanuj ponownie')),
          ],
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Wróć')),
"""
  instruction='Skieruj aparat na kod kreskowy lub DataMatrix na opakowaniu leku.'
 else:
  footer="OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Wpisz kod ręcznie')),"
  instruction='Skieruj aparat na kod QR z profilu chorego.'
 s=s[:start]+f"""      body: ScannerLayout(
        instruction: '{instruction}',
        preview: {camera},
        actions: [
          {footer}
        ],
      ),
    );
  }}
}}
"""
 p.write_text(s,encoding='utf-8')
