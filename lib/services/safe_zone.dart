import 'dart:math' as math;

/// Domyślny promień bezpiecznej strefy wokół miejsca, na przykład domu.
const defaultSafeZoneRadius = 100;

const minSafeZoneRadius = 50;
const maxSafeZoneRadius = 500;

/// Dodatkowe metry poza promieniem, zanim uznamy, że pacjent wyszedł.
/// Ogranicza fałszywe alerty przy drganiu GPS na granicy strefy.
const safeZoneExitBufferMeters = 20.0;

/// Środek mapy, zanim użytkownik wskaże własne miejsce (Warszawa).
const defaultMapLatitude = 52.2297;
const defaultMapLongitude = 21.0122;

enum ZonePresence { unknown, inside, outside }

class GeoFix {
  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.at,
  });

  final double latitude;
  final double longitude;
  final DateTime at;

  Map<String, Object> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'at': at.toIso8601String(),
  };

  static GeoFix? fromJson(Map<String, dynamic> json) {
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final at = json['at'];
    if (latitude is! num || longitude is! num || at is! String) return null;
    return GeoFix(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      at: DateTime.parse(at),
    );
  }
}

class SafeZone {
  const SafeZone({
    required this.patientId,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String patientId;
  final String label;
  final double latitude;
  final double longitude;
  final int radiusMeters;

  Map<String, Object> toJson() => {
    'patientId': patientId,
    'label': label,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
  };

  static SafeZone? fromJson(Map<String, dynamic> json) {
    final patientId = json['patientId'];
    final label = json['label'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final radius = json['radiusMeters'];
    if (patientId is! String ||
        label is! String ||
        latitude is! num ||
        longitude is! num ||
        radius is! num) {
      return null;
    }
    if (patientId.isEmpty || label.trim().isEmpty) return null;
    return SafeZone(
      patientId: patientId,
      label: label.trim(),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      radiusMeters: radius.round().clamp(minSafeZoneRadius, maxSafeZoneRadius),
    );
  }
}

class SafeZoneAlert {
  SafeZoneAlert({
    required this.patientId,
    required this.patientName,
    required this.placeLabel,
    required this.radiusMeters,
    required this.distanceMeters,
    required this.at,
    required this.latitude,
    required this.longitude,
    required this.caregiverNames,
    this.seen = false,
  });

  final String patientId;
  final String patientName;
  final String placeLabel;
  final int radiusMeters;
  final int distanceMeters;
  final DateTime at;
  final double latitude;
  final double longitude;
  final List<String> caregiverNames;
  bool seen;

  String get title => 'Poza bezpieczną strefą';

  String get message => zoneAlertMessage(
    patientName: patientName,
    placeLabel: placeLabel,
    radiusMeters: radiusMeters,
    distanceMeters: distanceMeters,
    caregiverNames: caregiverNames,
  );

  Map<String, Object> toJson() => {
    'patientId': patientId,
    'patientName': patientName,
    'placeLabel': placeLabel,
    'radiusMeters': radiusMeters,
    'distanceMeters': distanceMeters,
    'at': at.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'caregiverNames': caregiverNames,
    'seen': seen,
  };

  static SafeZoneAlert? fromJson(Map<String, dynamic> json) {
    final patientId = json['patientId'];
    final patientName = json['patientName'];
    final placeLabel = json['placeLabel'];
    final radius = json['radiusMeters'];
    final distance = json['distanceMeters'];
    final at = json['at'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final names = json['caregiverNames'];
    if (patientId is! String ||
        patientName is! String ||
        placeLabel is! String ||
        radius is! num ||
        distance is! num ||
        at is! String ||
        latitude is! num ||
        longitude is! num ||
        names is! List) {
      return null;
    }
    return SafeZoneAlert(
      patientId: patientId,
      patientName: patientName,
      placeLabel: placeLabel,
      radiusMeters: radius.round(),
      distanceMeters: distance.round(),
      at: DateTime.parse(at),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      caregiverNames: [
        for (final name in names)
          if (name is String) name,
      ],
      seen: json['seen'] == true,
    );
  }
}

class ZoneSession {
  const ZoneSession({
    required this.patientId,
    required this.patientName,
    required this.caregiverNames,
    required this.canEdit,
    required this.signedIn,
  });

  final String patientId;
  final String patientName;
  final List<String> caregiverNames;
  final bool canEdit;
  final bool signedIn;

  static const guest = ZoneSession(
    patientId: 'local',
    patientName: 'Pacjent',
    caregiverNames: [],
    canEdit: true,
    signedIn: false,
  );
}

String zoneAlertMessage({
  required String patientName,
  required String placeLabel,
  required int radiusMeters,
  required int distanceMeters,
  required List<String> caregiverNames,
}) {
  final recipients = caregiverNames.isEmpty
      ? 'opiekuna'
      : caregiverNames.join(', ');
  return '$patientName jest poza bezpieczną strefą '
      '($placeLabel, promień $radiusMeters m, około $distanceMeters m od środka). '
      'Powiadomienie dla: $recipients.';
}

String formatZoneTime(DateTime at) {
  const months = [
    'sty',
    'lut',
    'mar',
    'kwi',
    'maj',
    'cze',
    'lip',
    'sie',
    'wrz',
    'paź',
    'lis',
    'gru',
  ];
  final local = at.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]}, $hour:$minute';
}

double distanceMeters(
  double latitudeA,
  double longitudeA,
  double latitudeB,
  double longitudeB,
) {
  const earthRadius = 6371000.0;
  final phi1 = _radians(latitudeA);
  final phi2 = _radians(latitudeB);
  final dPhi = _radians(latitudeB - latitudeA);
  final dLambda = _radians(longitudeB - longitudeA);
  final a =
      math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) *
          math.cos(phi2) *
          math.sin(dLambda / 2) *
          math.sin(dLambda / 2);
  return 2 * earthRadius * math.asin(math.min(1, math.sqrt(a)));
}

ZonePresence evaluatePresence({
  required ZonePresence previous,
  required double distanceMeters,
  required double radiusMeters,
  double exitBufferMeters = safeZoneExitBufferMeters,
}) {
  if (distanceMeters <= radiusMeters) return ZonePresence.inside;
  if (distanceMeters > radiusMeters + exitBufferMeters) {
    return ZonePresence.outside;
  }
  if (previous == ZonePresence.outside) return ZonePresence.outside;
  return ZonePresence.inside;
}

bool shouldNotifyCaregiver(ZonePresence previous, ZonePresence next) {
  return next == ZonePresence.outside && previous != ZonePresence.outside;
}

double _radians(double degrees) => degrees * math.pi / 180;
