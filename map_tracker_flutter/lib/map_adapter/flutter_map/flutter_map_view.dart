import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/debug_flags.dart';
import '../../data/regions.dart';
import '../../models/map_bounds.dart';
import '../../providers/map_state_provider.dart';
import '../../widgets/user_marker.dart';
import '../map_view.dart';

class FlutterMapView extends MapView {
  const FlutterMapView({
    super.key,
    required super.onViewportChanged,
    required super.mode,
    required super.users,
  });

  @override
  State<FlutterMapView> createState() => _FlutterMapViewState();
}

class _FlutterMapViewState extends State<FlutterMapView> {
  final MapController _mapController = MapController();

  // --- debug helpers ---------------------------------------------------------

  List<Polygon> _buildRegionPolygons() => kRegions.map((r) {
        return Polygon(
          points: [
            LatLng(r.north, r.west),
            LatLng(r.north, r.east),
            LatLng(r.south, r.east),
            LatLng(r.south, r.west),
          ],
          color: Colors.cyan.withValues(alpha: 0.08),
          borderColor: Colors.cyan.withValues(alpha: 0.6),
          borderStrokeWidth: 1.0,
        );
      }).toList();

  List<Marker> _buildRegionLabels() => kRegions.map((r) {
        final centerLat = (r.north + r.south) / 2;
        final centerLng = (r.west + r.east) / 2;
        return Marker(
          point: LatLng(centerLat, centerLng),
          width: 80,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '${r.id} ${r.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList();

  // ---------------------------------------------------------------------------

  void _reportViewport() {
    final camera = _mapController.camera;
    final fb = camera.visibleBounds;
    widget.onViewportChanged(
      camera.zoom,
      MapBounds(
        north: fb.north,
        south: fb.south,
        east: fb.east,
        west: fb.west,
      ),
    );
  }

  void _onMapReady() => _reportViewport();

  void _onMapEvent(MapEvent event) {
    if (event is! MapEventMove && event is! MapEventRotate) return;
    _reportViewport();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(39.7392, -104.9903), // Denver, CO
        initialZoom: 9.0,
        onMapReady: _onMapReady,
        onMapEvent: _onMapEvent,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.isquibly.map_tracker',
        ),
        if (widget.mode == ZoomMode.detail)
          MarkerLayer(
            markers: widget.users
                .map((user) => Marker(
                      point: LatLng(user.lat, user.lng),
                      width: 36,
                      height: 36,
                      child: UserMarker(user: user),
                    ))
                .toList(),
          ),
        if (kDebugShowRegionBoundaries) ...[
          PolygonLayer(polygons: _buildRegionPolygons()),
          MarkerLayer(markers: _buildRegionLabels()),
        ],
      ],
    );
  }
}
