import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:m_opiekun/theme/app_theme.dart';

/// Mapa OpenStreetMap z okręgiem bezpiecznej strefy.
///
/// W testach widżetów kafelki sieciowe są pomijane, żeby `pumpAndSettle`
/// nie czekał na animację ładowania mapy.
class OsmSafeZoneMap extends StatefulWidget {
  const OsmSafeZoneMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.patientLatitude,
    this.patientLongitude,
    this.showZone = true,
    this.onTap,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;
  final double? patientLatitude;
  final double? patientLongitude;
  final bool showZone;
  final ValueChanged<LatLng>? onTap;

  @override
  State<OsmSafeZoneMap> createState() => _OsmSafeZoneMapState();
}

class _OsmSafeZoneMapState extends State<OsmSafeZoneMap> {
  final MapController _controller = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(OsmSafeZoneMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _move(LatLng(widget.latitude, widget.longitude));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(LatLng target) {
    if (!_ready) return;
    _controller.move(target, _zoomFor(widget.radiusMeters));
  }

  @override
  Widget build(BuildContext context) {
    if (_isWidgetTest) {
      return _MapPlaceholder(radiusMeters: widget.radiusMeters);
    }

    final center = LatLng(widget.latitude, widget.longitude);
    return SizedBox(
      height: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: _zoomFor(widget.radiusMeters),
            minZoom: 3,
            maxZoom: 19,
            onMapReady: () => _ready = true,
            onTap: widget.onTap == null
                ? null
                : (_, point) => widget.onTap!(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.m_opiekun',
              maxNativeZoom: 19,
            ),
            if (widget.showZone)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: widget.radiusMeters,
                    useRadiusInMeter: true,
                    color: CareColors.primary.withValues(alpha: 0.22),
                    borderColor: CareColors.primary,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (widget.showZone)
                  Marker(
                    point: center,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.home_rounded,
                      size: 36,
                      color: CareColors.primary,
                    ),
                  ),
                if (widget.patientLatitude != null &&
                    widget.patientLongitude != null)
                  Marker(
                    point: LatLng(
                      widget.patientLatitude!,
                      widget.patientLongitude!,
                    ),
                    width: 22,
                    height: 22,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: CareColors.ink,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.radiusMeters});

  final double radiusMeters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, color: theme.colorScheme.primary, size: 40),
          const SizedBox(height: 8),
          Text(
            'OpenStreetMap',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          Text(
            'Okrąg ${radiusMeters.round()} m wokół miejsca',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

bool get _isWidgetTest {
  return WidgetsBinding.instance.runtimeType.toString().contains(
    'TestWidgetsFlutterBinding',
  );
}

double _zoomFor(double radiusMeters) {
  if (radiusMeters <= 120) return 16;
  if (radiusMeters <= 250) return 15.2;
  if (radiusMeters <= 400) return 14.6;
  return 14;
}
