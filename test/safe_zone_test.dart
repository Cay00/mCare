import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:m_opiekun/services/safe_zone.dart';
import 'package:m_opiekun/services/safe_zone_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('odległość jednego stopnia szerokości to około 111 km', () {
    expect(distanceMeters(52, 21, 53, 21), closeTo(111195, 50));
  });

  test('wyjście poza promień z buforem GPS wysyła alert tylko raz', () {
    expect(
      evaluatePresence(
        previous: ZonePresence.inside,
        distanceMeters: 110,
        radiusMeters: 100,
      ),
      ZonePresence.inside,
    );
    expect(
      shouldNotifyCaregiver(
        ZonePresence.inside,
        evaluatePresence(
          previous: ZonePresence.inside,
          distanceMeters: 130,
          radiusMeters: 100,
        ),
      ),
      isTrue,
    );
    expect(
      shouldNotifyCaregiver(ZonePresence.outside, ZonePresence.outside),
      isFalse,
    );
    expect(
      evaluatePresence(
        previous: ZonePresence.outside,
        distanceMeters: 90,
        radiusMeters: 100,
      ),
      ZonePresence.inside,
    );
    expect(
      evaluatePresence(
        previous: ZonePresence.unknown,
        distanceMeters: 130,
        radiusMeters: 100,
      ),
      ZonePresence.outside,
    );
  });

  test(
    'opiekun dostaje powiadomienie po wyjściu i po ponownym wyjściu',
    () async {
      final feed = _FakeLocationFeed();
      final store = SafeZoneStore(location: feed);
      addTearDown(feed.close);
      addTearDown(() => store.stopMonitoring('JKB-1042'));

      final saved = await store.saveZone(
        const SafeZone(
          patientId: 'JKB-1042',
          label: 'Dom',
          latitude: 52,
          longitude: 21,
          radiusMeters: 100,
        ),
      );
      expect(saved, isNull);

      final error = await store.startMonitoring(
        patientId: 'JKB-1042',
        patientName: 'Jakub B',
        caregiverNames: const ['Anna Kowalska'],
      );
      expect(error, isNull);
      expect(store.presenceFor('JKB-1042'), ZonePresence.inside);
      expect(store.alerts, isEmpty);

      feed.add(_moveNorth(52, 21, 40));
      await _flush();
      expect(store.alerts, isEmpty);

      feed.add(_moveNorth(52, 21, 160));
      await _flush();
      expect(store.alerts, hasLength(1));
      expect(store.presenceFor('JKB-1042'), ZonePresence.outside);
      expect(store.alerts.single.message, contains('Jakub B'));
      expect(store.alerts.single.message, contains('Dom'));
      expect(store.alerts.single.message, contains('Anna Kowalska'));
      expect(store.unreadCount, 1);

      feed.add(_moveNorth(52, 21, 180));
      await _flush();
      expect(store.alerts, hasLength(1));

      feed.add(_moveNorth(52, 21, 20));
      await _flush();
      expect(store.presenceFor('JKB-1042'), ZonePresence.inside);

      feed.add(_moveNorth(52, 21, 170));
      await _flush();
      expect(store.alerts, hasLength(2));

      await store.markAllSeen();
      final restored = SafeZoneStore(location: _FakeLocationFeed());
      await restored.load();
      expect(restored.zoneFor('JKB-1042')?.radiusMeters, 100);
      expect(restored.alerts, hasLength(2));
      expect(restored.alerts.every((alert) => alert.seen), isTrue);
      expect(restored.isMonitoring('JKB-1042'), isTrue);
      expect(restored.presenceFor('JKB-1042'), ZonePresence.outside);
    },
  );

  test('bez zgody na lokalizację pilnowanie się nie włącza', () async {
    final feed = _FakeLocationFeed()..access = LocationAccess.denied;
    final store = SafeZoneStore(location: feed);
    await store.saveZone(
      const SafeZone(
        patientId: 'JKB-1042',
        label: 'Dom',
        latitude: 52,
        longitude: 21,
        radiusMeters: 100,
      ),
    );
    final error = await store.startMonitoring(
      patientId: 'JKB-1042',
      patientName: 'Jakub B',
      caregiverNames: const ['Anna Kowalska'],
    );
    expect(error, isNotNull);
    expect(store.isMonitoring('JKB-1042'), isFalse);
    expect(store.alerts, isEmpty);
  });
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

GeoFix _moveNorth(double latitude, double longitude, double meters) {
  return GeoFix(
    latitude: latitude + meters / 111320,
    longitude: longitude,
    at: DateTime.utc(2026, 10, 4, 8),
  );
}

class _FakeLocationFeed implements LocationFeed {
  LocationAccess access = LocationAccess.granted;
  final StreamController<GeoFix> _positions = StreamController<GeoFix>();

  void add(GeoFix fix) => _positions.add(fix);

  Future<void> close() => _positions.close();

  @override
  Future<LocationAccess> ensureAccess() async => access;

  @override
  Future<GeoFix> current() async => _moveNorth(52, 21, 0);

  @override
  Stream<GeoFix> watch() => _positions.stream;
}
