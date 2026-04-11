import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../config/debug_flags.dart';
import '../../data/regions.dart';
import '../../models/map_bounds.dart';
import '../../providers/map_state_provider.dart';
import '../../services/marker_bitmap_cache.dart';
import '../map_view.dart';

class GoogleMapView extends MapView {
  const GoogleMapView({
    super.key,
    required super.onViewportChanged,
    super.onMarkerTap,
    required super.mode,
    required super.users,
  });

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  gmaps.GoogleMapController? _controller;

  // Markers are rebuilt asynchronously when users change.
  Set<gmaps.Marker> _markers = {};

  static const _initialPosition = gmaps.CameraPosition(
    target: gmaps.LatLng(36.7173, -107.7603), // Center of region 06
    zoom: 6.06,
  );

  static const _clusterManagerId = gmaps.ClusterManagerId('riders');

  @override
  void didUpdateWidget(GoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users || oldWidget.mode != widget.mode) {
      _rebuildMarkers();
    }
  }

  // onCameraMove fires synchronously; getVisibleRegion is async so we fire-and-forget.
  void _onCameraMove(gmaps.CameraPosition position) {
    _reportViewport(position.zoom);
  }

  Future<void> _reportViewport(double zoom) async {
    if (_controller == null) return;
    final region = await _controller!.getVisibleRegion();
    widget.onViewportChanged(
      zoom,
      MapBounds(
        north: region.northeast.latitude,
        south: region.southwest.latitude,
        east: region.northeast.longitude,
        west: region.southwest.longitude,
      ),
    );
  }

  Future<void> _rebuildMarkers() async {
    if (widget.mode == ZoomMode.empty) {
      if (mounted) setState(() => _markers = {});
      return;
    }

    final cache = MarkerBitmapCache.instance;
    final built = <gmaps.Marker>{};

    for (final user in widget.users) {
      final icon = await cache.descriptorFor(user.role);
      built.add(gmaps.Marker(
        markerId: gmaps.MarkerId(user.userId),
        position: gmaps.LatLng(user.lat, user.lng),
        clusterManagerId: _clusterManagerId,
        icon: icon,
        rotation: user.bearing ?? 0.0,
        flat: true,
        anchor: const Offset(0.5, 1.0), // pin tip touches map position
        consumeTapEvents: true,
        onTap: () => widget.onMarkerTap?.call(user),
      ));
    }

    if (mounted) setState(() => _markers = built);
  }

  // --- debug helpers ---------------------------------------------------------

  Set<gmaps.Polygon> _buildRegionDebugPolygons() => kRegions.map((r) {
        return gmaps.Polygon(
          polygonId: gmaps.PolygonId('debug_region_${r.id}'),
          points: [
            gmaps.LatLng(r.north, r.west),
            gmaps.LatLng(r.north, r.east),
            gmaps.LatLng(r.south, r.east),
            gmaps.LatLng(r.south, r.west),
          ],
          fillColor: Colors.deepPurple.withValues(alpha: 0.08),
          strokeColor: Colors.deepPurple.withValues(alpha: 0.6),
          strokeWidth: 1,
        );
      }).toSet();

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return gmaps.GoogleMap(
      initialCameraPosition: _initialPosition,
      onMapCreated: (controller) {
        setState(() => _controller = controller);
        _reportViewport(_initialPosition.zoom);
        _rebuildMarkers();
      },
      onCameraMove: _onCameraMove,
      clusterManagers: {
        gmaps.ClusterManager(
          clusterManagerId: _clusterManagerId,
          onClusterTap: (_) {},
        ),
      },
      markers: _markers,
      polygons: {
        if (kDebugShowRegionBoundaries) ..._buildRegionDebugPolygons(),
      },
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}
