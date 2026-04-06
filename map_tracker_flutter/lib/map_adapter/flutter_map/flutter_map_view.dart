import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/map_bounds.dart';
import '../../providers/map_state_provider.dart';
import '../../widgets/heatmap_layer.dart';
import '../../widgets/user_marker.dart';
import '../map_view.dart';

class FlutterMapView extends MapView {
  const FlutterMapView({
    super.key,
    required super.onViewportChanged,
    required super.mode,
    required super.heatmapBuckets,
    required super.users,
  });

  @override
  State<FlutterMapView> createState() => _FlutterMapViewState();
}

class _FlutterMapViewState extends State<FlutterMapView> {
  final MapController _mapController = MapController();

  void _onMapEvent(MapEvent event) {
    if (event is! MapEventMove && event is! MapEventRotate) return;
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

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(51.5, -0.09),
        initialZoom: 5.0,
        onMapEvent: _onMapEvent,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.isquibly.map_tracker',
        ),
        if (widget.mode == ZoomMode.heatmap)
          HexHeatmapLayer(buckets: widget.heatmapBuckets),
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
      ],
    );
  }
}
