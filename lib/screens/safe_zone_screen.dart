import 'package:flutter/material.dart';
import 'package:m_opiekun/services/safe_zone.dart';
import 'package:m_opiekun/services/safe_zone_store.dart';
import 'package:m_opiekun/widgets/care_components.dart';
import 'package:m_opiekun/widgets/osm_safe_zone_map.dart';
import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/section_card.dart';

/// Bezpieczna strefa: miejsce na mapie OpenStreetMap, promień i alert.
void openSafeZone(
  BuildContext context, {
  String? patientId,
  String? patientName,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: careAppBar(context, 'Strefa'),
        body: SafeZoneScreen(patientId: patientId, patientName: patientName),
      ),
    ),
  );
}

void showZoneNotifications(BuildContext context) {
  final store = SafeZoneStore.instance;
  final alerts = List<SafeZoneAlert>.of(store.alerts);
  store.markAllSeen();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      if (alerts.isEmpty) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Text('Brak nowych powiadomień.'),
          ),
        );
      }
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            for (final alert in alerts)
              ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(alert.title),
                subtitle: Text('${alert.message}\n${formatZoneTime(alert.at)}'),
                isThreeLine: true,
              ),
          ],
        ),
      );
    },
  );
}

class SafeZoneScreen extends StatefulWidget {
  const SafeZoneScreen({super.key, this.patientId, this.patientName});

  final String? patientId;
  final String? patientName;

  @override
  State<SafeZoneScreen> createState() => _SafeZoneScreenState();
}

class _SafeZoneScreenState extends State<SafeZoneScreen> {
  final SafeZoneStore _store = SafeZoneStore.instance;
  final TextEditingController _label = TextEditingController(text: 'Dom');
  double? _latitude;
  double? _longitude;
  double _radius = defaultSafeZoneRadius.toDouble();
  bool _dirty = false;
  bool _draftReady = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStore);
    _store.load().then((_) {
      if (!mounted || _dirty) return;
      _applySavedZone();
      _draftReady = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    _label.dispose();
    super.dispose();
  }

  ZoneSession get _view {
    final session = _store.session;
    final id = widget.patientId ?? session.patientId;
    final same =
        widget.patientId == null || widget.patientId == session.patientId;
    return ZoneSession(
      patientId: id,
      patientName:
          widget.patientName ?? (same ? session.patientName : 'Pacjent'),
      caregiverNames: session.caregiverNames,
      canEdit: session.canEdit && same,
      signedIn: session.signedIn,
    );
  }

  void _onStore() {
    if (!mounted) return;
    if (!_draftReady && !_dirty) {
      _applySavedZone();
      _draftReady = true;
    }
    setState(() {});
  }

  void _applySavedZone() {
    final zone = _store.zoneFor(_view.patientId);
    if (zone == null) return;
    _label.text = zone.label;
    _latitude = zone.latitude;
    _longitude = zone.longitude;
    _radius = zone.radiusMeters.toDouble();
  }

  Future<void> _useMyLocation() async {
    setState(() => _busy = true);
    final result = await _store.readCurrentFix();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.fix == null) {
        _message = result.error;
        return;
      }
      _latitude = result.fix!.latitude;
      _longitude = result.fix!.longitude;
      _dirty = true;
      _message =
          'Środek strefy ustawiony na bieżącą lokalizację. Zapisz, aby został zapamiętany.';
    });
  }

  Future<void> _save() async {
    final view = _view;
    final label = _label.text.trim();
    if (label.isEmpty) {
      setState(() => _message = 'Podaj nazwę miejsca, na przykład Dom.');
      return;
    }
    if (_latitude == null || _longitude == null) {
      setState(
        () =>
            _message = 'Wskaż miejsce na mapie albo użyj bieżącej lokalizacji.',
      );
      return;
    }
    setState(() => _busy = true);
    final error = await _store.saveZone(
      SafeZone(
        patientId: view.patientId,
        label: label,
        latitude: _latitude!,
        longitude: _longitude!,
        radiusMeters: _radius.round(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _dirty = error != null;
      _message =
          error ??
          'Strefa zapisana. Włącz pilnowanie, aby opiekun dostał alert po wyjściu.';
    });
  }

  Future<void> _toggleMonitoring(bool enabled) async {
    final view = _view;
    setState(() => _busy = true);
    if (enabled) {
      final error = await _store.startMonitoring(
        patientId: view.patientId,
        patientName: view.patientName,
        caregiverNames: view.caregiverNames,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = error ?? 'Pilnowanie włączone.';
      });
      return;
    }
    await _store.stopMonitoring(view.patientId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = 'Pilnowanie wyłączone.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final view = _view;
    final zone = view.patientId.isEmpty ? null : _store.zoneFor(view.patientId);
    final presence = view.patientId.isEmpty
        ? ZonePresence.unknown
        : _store.presenceFor(view.patientId);
    final fix = view.patientId.isEmpty ? null : _store.fixFor(view.patientId);
    final mapLatitude = _latitude ?? zone?.latitude ?? defaultMapLatitude;
    final mapLongitude = _longitude ?? zone?.longitude ?? defaultMapLongitude;
    final showCircle = _latitude != null || zone != null;

    return PrototypePage(
      lead:
          'Status pobytu w bezpiecznej strefie i ostrzeżenie dla opiekuna, '
          'gdy osoba ją opuści.',
      children: [
        const CareHeading('Bezpieczna strefa'),
        if (!view.canEdit && view.patientId.isEmpty)
          const CareNotice(
            'Strefę wyznacza pacjent. Gdy udostępni zakres Strefa, '
            'zobaczysz tu mapę, promień i alert o wyjściu.',
          )
        else ...[
          _StatusCard(
            presence: presence,
            zone: zone,
            patientName: view.patientName,
          ),
          if (_store.locationMessage != null)
            CareNotice(_store.locationMessage!, error: true),
          if (_message != null) CareNotice(_message!),
          Text(
            view.canEdit
                ? 'Dotknij mapę, aby ustawić środek strefy, na przykład dom.'
                : 'Mapa pokazuje zapisane miejsce i promień.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          OsmSafeZoneMap(
            latitude: mapLatitude,
            longitude: mapLongitude,
            radiusMeters: _radius,
            showZone: showCircle,
            patientLatitude: fix?.latitude,
            patientLongitude: fix?.longitude,
            onTap: view.canEdit
                ? (point) {
                    setState(() {
                      _latitude = point.latitude;
                      _longitude = point.longitude;
                      _dirty = true;
                      _message = null;
                    });
                  }
                : null,
          ),
          Text(
            'Mapa © OpenStreetMap contributors',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (view.canEdit) ...[
            CareField(
              label: 'Nazwa miejsca',
              child: TextField(
                controller: _label,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Na przykład Dom',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _dirty = true,
              ),
            ),
            Text(
              'Promień ${_radius.round()} m',
              style: theme.textTheme.titleSmall,
            ),
            Semantics(
              label: 'Promień strefy',
              value: '${_radius.round()} metrów',
              child: Slider(
                min: minSafeZoneRadius.toDouble(),
                max: maxSafeZoneRadius.toDouble(),
                divisions: (maxSafeZoneRadius - minSafeZoneRadius) ~/ 25,
                value: _radius,
                label: '${_radius.round()} m',
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _radius = value;
                        _dirty = true;
                      }),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : _useMyLocation,
                child: const Text(
                  'Użyj mojej lokalizacji',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Zapisz strefę', textAlign: TextAlign.center),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pilnuj strefy'),
              subtitle: const Text(
                'Alert po wyjściu poza promień. Na Androidzie sprawdzanie '
                'trwa też po przełączeniu na inną aplikację.',
              ),
              value: _store.isMonitoring(view.patientId),
              onChanged: zone == null || _busy ? null : _toggleMonitoring,
            ),
          ],
          SectionCard(
            title: 'Ustawienia strefy',
            icon: Icons.home_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ZoneFact(
                  label: 'Miejsce',
                  value: zone == null
                      ? 'Jeszcze nieustawione'
                      : '${zone.label} · ${_formatCoordinate(zone.latitude)}, ${_formatCoordinate(zone.longitude)}',
                ),
                _ZoneFact(
                  label: 'Promień',
                  value: zone == null ? '100 m' : '${zone.radiusMeters} m',
                ),
                _ZoneFact(
                  label: 'Kto dostaje alert',
                  value: view.caregiverNames.isEmpty
                      ? 'Udostępnij opiekunowi zakres Strefa w profilu'
                      : view.caregiverNames.join(', '),
                  isLast: true,
                ),
              ],
            ),
          ),
          if (presence == ZonePresence.outside)
            _AlertPreview(patientName: view.patientName, zone: zone),
        ],
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.presence,
    required this.zone,
    required this.patientName,
  });

  final ZonePresence presence;
  final SafeZone? zone;
  final String patientName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outside = presence == ZonePresence.outside;
    final inside = presence == ZonePresence.inside;
    final background = outside
        ? theme.colorScheme.errorContainer
        : inside
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = outside
        ? theme.colorScheme.onErrorContainer
        : inside
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final saved = zone;
    final title = switch (presence) {
      ZonePresence.inside => 'W bezpiecznej strefie',
      ZonePresence.outside => 'Poza bezpieczną strefą',
      ZonePresence.unknown =>
        saved == null ? 'Wyznacz miejsce na mapie' : 'Czekam na lokalizację',
    };
    final place = saved == null
        ? 'Domyślny promień to 100 metrów wokół domu.'
        : '${saved.label}, promień ${saved.radiusMeters} m';
    final detail = switch (presence) {
      ZonePresence.inside => saved == null ? patientName : place,
      ZonePresence.outside => 'Poza zapisanym obszarem.',
      ZonePresence.unknown => place,
    };

    return Semantics(
      liveRegion: outside,
      child: Card(
        color: background,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                outside
                    ? Icons.warning_amber_rounded
                    : inside
                    ? Icons.check_circle
                    : Icons.location_on_outlined,
                size: 36,
                color: foreground,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                    Text(
                      detail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertPreview extends StatelessWidget {
  const _AlertPreview({required this.patientName, required this.zone});

  final String patientName;
  final SafeZone? zone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = zone?.label ?? 'strefa';
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Opiekun został powiadomiony',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$patientName jest poza bezpieczną strefą ($place).',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneFact extends StatelessWidget {
  const _ZoneFact({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

String _formatCoordinate(double value) => value.toStringAsFixed(5);
