import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:h3_flutter/h3_flutter.dart';
import '../../config/debug_flags.dart';
import '../../data/regions.dart';
import '../../models/map_bounds.dart';
import '../../providers/map_state_provider.dart';
import '../../utils/h3_viewport.dart';
import '../map_view.dart';

final _h3 = const H3Factory().load();

class GoogleMapView extends MapView {
  const GoogleMapView({
    super.key,
    required super.onViewportChanged,
    required super.mode,
    required super.heatmapBuckets,
    required super.users,
  });

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  gmaps.GoogleMapController? _controller;

  static const _initialPosition = gmaps.CameraPosition(
    target: gmaps.LatLng(39.7392, -104.9903), // Denver, CO
    zoom: 9.0,
  );

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

  Set<gmaps.Polygon> _buildHeatmapPolygons() {
    if (widget.heatmapBuckets.isEmpty) return {};
    final maxCount = widget.heatmapBuckets
        .map((b) => b.count)
        .reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return {};

    return widget.heatmapBuckets.map((bucket) {
      final boundary = _h3.cellToBoundary(h3IndexFromString(bucket.cell));
      final points = boundary
          .map((c) => gmaps.LatLng(c.lat, c.lon))
          .toList();
      final intensity = bucket.count / maxCount;
      final color = _heatColor(intensity);
      return gmaps.Polygon(
        polygonId: gmaps.PolygonId(bucket.cell),
        points: points,
        fillColor: color.withValues(alpha: 0.55),
        strokeColor: color.withValues(alpha: 0.8),
        strokeWidth: 1,
      );
    }).toSet();
  }

  Set<gmaps.Marker> _buildMarkers() {
    return widget.users.map((user) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(user.userId),
        position: gmaps.LatLng(user.lat, user.lng),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          _hueForRole(user.role),
        ),
        // bearing maps to marker rotation (degrees clockwise from north)
        rotation: user.bearing ?? 0.0,
        flat: true,
      );
    }).toSet();
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
          fillColor: Colors.cyan.withValues(alpha: 0.08),
          strokeColor: Colors.cyan.withValues(alpha: 0.6),
          strokeWidth: 1,
        );
      }).toSet();

  // ---------------------------------------------------------------------------

  Color _heatColor(double t) {
    if (t < 0.5) {
      return Color.lerp(Colors.yellow, Colors.orange, t * 2)!;
    } else {
      return Color.lerp(Colors.orange, Colors.red, (t - 0.5) * 2)!;
    }
  }

  double _hueForRole(String role) => switch (role) {
        'plumber'  => gmaps.BitmapDescriptor.hueBlue,
        'mechanic' => gmaps.BitmapDescriptor.hueOrange,
        'teacher'  => gmaps.BitmapDescriptor.hueGreen,
        'driver'   => gmaps.BitmapDescriptor.hueViolet,
        _          => gmaps.BitmapDescriptor.hueRed,
      };

  @override
  Widget build(BuildContext context) {
    return gmaps.GoogleMap(
      initialCameraPosition: _initialPosition,
      onMapCreated: (controller) => setState(() => _controller = controller),
      onCameraMove: _onCameraMove,
      polygons: {
        if (widget.mode == ZoomMode.heatmap) ..._buildHeatmapPolygons(),
        if (kDebugShowRegionBoundaries) ..._buildRegionDebugPolygons(),
      },
      markers: widget.mode == ZoomMode.detail ? _buildMarkers() : {},
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}
