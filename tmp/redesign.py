from pathlib import Path
root=Path('lib')
def read(p): return (root/p).read_text(encoding='utf-8')
def write(p,s): (root/p).write_text(s,encoding='utf-8')
care="import 'package:m_opiekun/widgets/care_components.dart';\n"
proto="import 'package:m_opiekun/widgets/prototype_page.dart';\n"
for name in ['login','health','appointments','profile','connect_patient','change_password','safe_zone','wellness_guide','shared_patient']:
 p=f'screens/{name}_screen.dart'; s=read(p); s=care+s
 if name in ['connect_patient','wellness_guide','shared_patient']: s=proto+s
 s=s.replace("AppBar(title: const Text('Połącz z chorym'))", "careAppBar(context, 'Połącz z chorym')").replace("AppBar(title: const Text('Zmiana hasła'))", "careAppBar(context, 'Zmiana hasła')").replace("AppBar(title: const Text('Strefa'))", "careAppBar(context, 'Strefa')").replace('AppBar(title: Text(guide.title))','careAppBar(context, guide.title)').replace('AppBar(title: Text(name))','careAppBar(context, name)')
 s=s.replace("body: ListView(\n        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),", 'body: PrototypePage(').replace("body: ListView(\n        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),",'body: PrototypePage(').replace("body: ListView(\n            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),",'body: PrototypePage(')
 s=s.replace('EdgeInsets.only(bottom: isLast ? 0 : 12)', 'EdgeInsets.only(bottom: isLast ? 0 : 20)')
 if name=='login':
  s=s.replace('maxWidth: 400','maxWidth: 480')
  start=s.index("                  Text('mOpiekun'"); end=s.index('                  if (_error',start)
  s=s[:start]+'''                  const Align(alignment: Alignment.centerLeft, child: CareIcon(Icons.favorite_outline)),
                  const SizedBox(height: 24),
                  const CareHeading('Dobrze mieć wsparcie', eyebrow: 'mCare', subtitle: 'Twoje leki, zdrowie i bliscy w jednym miejscu.'),
                  const SizedBox(height: 32),
                  CareField(label: 'Login', child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                  )),
                  CareField(label: 'Hasło', child: TextField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                  )),
'''+s[end:]
  s=s.replace('''                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),''','''                    CareNotice(_error!, error: true),''')
  s=s.replace("                  const SizedBox(height: 12),\n                  OutlinedButton(", "                  const SizedBox(height: 28),\n                  const CareHeading('Wypróbuj aplikację', subtitle: 'Wybierz przykładowe konto.'),\n                  const SizedBox(height: 16),\n                  OutlinedButton(",1)
 if name=='health':
  start=s.index('      lead:'); end=s.index('        const SectionCard(',start)
  s=s[:start]+'''      children: [
        const CareHeading('Karta medyczna', subtitle: 'Najważniejsze informacje na wizytę i dla opiekuna.'),
        const CareNotice('Dane i zalecenia poniżej są przykładowe. Eksport PDF jest w przygotowaniu.'),
'''+s[end:]
 if name=='appointments':
  start=s.index('      lead:'); end=s.index("        const SizedBox(height: 8)",start)
  s=s[:start]+'''      children: [
        const CareHeading('Porady', subtitle: 'Wybierz krótkie ćwiczenie. Wróć do niego, kiedy potrzebujesz.'),
        for (final guide in wellnessGuides)
          CareLinkCard(title: guide.title, subtitle: guide.duration, icon: guide.icon,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WellnessGuideScreen(guide: guide)))),
'''+s[end:]
  a=s.index('class _GuideRow'); b=s.index('class _VisitCard'); s=s[:a]+s[b:]
  a=s.index('    return Card(',s.index('class _VisitCard')); s=s[:a]+'''    return Card(
      child: Padding(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('$day $month · $time', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(details, style: theme.textTheme.bodyLarge),
          const Divider(),
          Text(reminder, style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor)),
          if (muted) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Wizyta odbyta')),
        ]),
      ),
    );
  }
}
'''
  s=s.replace("        Text('Nadchodzące', style: Theme.of(context).textTheme.titleLarge),", "        const CareHeading('Nadchodzące', subtitle: 'Przykładowe terminy i przypomnienia.'),")
 if name=='profile':
  a=s.index('          lead:'); b=s.index('            _AccountCard',a)
  s=s[:a]+'''          children: [
            CareHeading('Twoje konto', subtitle: isPatient
              ? 'Ty wybierasz, komu i jakie dane udostępniasz.'
              : 'Twoje dane i podopieczni, którzy udzielili Ci dostępu.'),
'''+s[b:]
  a=s.index('    final theme = Theme.of(context);',s.index('class _ZoneEntry')); b=s.index('class _PendingRequestCard',a)
  s=s[:a]+'''    return CareLinkCard(
      key: const Key('openSafeZone'),
      title: 'Bezpieczna strefa', subtitle: 'Miejsce, promień i alert dla opiekuna',
      icon: Icons.location_on_outlined, onTap: () => openSafeZone(context),
    );
  }
}

'''+s[b:]
  s=s.replace('''              child: QrImageView(
                data: user.codePayload,
                size: 220,
                backgroundColor: Colors.white,
                semanticsLabel: 'Kod QR ${user.id}',
              ),''','''              child: LayoutBuilder(builder: (context, constraints) => QrImageView(
                data: user.codePayload,
                size: constraints.maxWidth.clamp(0, 220),
                backgroundColor: Colors.white,
                semanticsLabel: 'Kod QR ${user.id}',
              )),''')
  s=s.replace('            contentPadding: EdgeInsets.zero,','            contentPadding: const EdgeInsets.symmetric(vertical: 8),\n            controlAffinity: ListTileControlAffinity.leading,')
 if name=='change_password':
  import re
  s=re.sub(r"          const TextField\(\n            obscureText: true,\n            decoration: InputDecoration\(\n              labelText: '([^']+)',\n              border: OutlineInputBorder\(\),\n            \),\n          \),",lambda m: "          const CareField(label: '"+m[1]+"', child: TextField(obscureText: true)),",s)
 if name=='connect_patient':
  s=s.replace("          TextField(\n            key:","          CareField(label: 'Kod chorego', child: TextField(\n            key:")
  s=s.replace("            decoration: const InputDecoration(\n              labelText: 'Kod chorego',\n              border: OutlineInputBorder(),\n            ),\n",'')
  s=s.replace('            onSubmitted: (_) => _submit(),\n          ),','            onSubmitted: (_) => _submit(),\n          )),')
  s=s.replace('''            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),''','''            CareNotice(_error!, error: true),''')
 if name=='safe_zone':
  s=s.replace('      children: [\n        Card(',"      children: [\n        const CareHeading('Bezpieczna strefa'),\n        const CareNotice('Podgląd funkcji. Lokalizacja, mapa i wysyłanie alertów nie są jeszcze podłączone.'),\n        Card(",1)
  s=s.replace('          height: 180,','          constraints: const BoxConstraints(minHeight: 200),\n          padding: const EdgeInsets.all(24),')
  s=s.replace("Text('Miejsce na mapę', style:", "Text('Miejsce na mapę', textAlign: TextAlign.center, style:")
  s=s.replace("                'Okrąg strefy wokół domu',", "                'Okrąg strefy wokół domu',\n                textAlign: TextAlign.center,")
 if name=='wellness_guide':
  s=s.replace('          width: 32,\n          height: 32,','          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),\n          padding: const EdgeInsets.all(8),')
 if name=='shared_patient':
  s=s.replace('              else ...[','              else ...[\n                const CareNotice(\'Podgląd zawiera dane przykładowe w udostępnionym zakresie.\'),',1)
 write(p,s)

p='widgets/medication_form.dart'; s=read(p); s=care+s
s=s.replace('''  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(''','''  }) => CareField(
    label: label,
    child: TextFormField(
      key: ValueKey('medication-$label'),''')
s=s.replace('        labelText: label,\n','').replace('        border: const OutlineInputBorder(),','        hintMaxLines: 4,')
s=s.replace("              _field(\n                'Dawkowanie według zaleceń lekarza',", "              const CareHeading('Dawkowanie i zapas'),\n              const SizedBox(height: 20),\n              _field(\n                'Dawkowanie według zaleceń lekarza',")
write(p,s)
