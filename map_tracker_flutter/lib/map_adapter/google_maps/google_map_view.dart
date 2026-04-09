import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../config/debug_flags.dart';
import '../../data/regions.dart';
import '../../models/map_bounds.dart';
import '../../providers/map_state_provider.dart';
import '../map_view.dart';

class GoogleMapView extends MapView {
  const GoogleMapView({
    super.key,
    required super.onViewportChanged,
    required super.mode,
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

  static const _clusterManagerId = gmaps.ClusterManagerId('riders');

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

  Set<gmaps.Marker> _buildMarkers() {
    return widget.users.map((user) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(user.userId),
        position: gmaps.LatLng(user.lat, user.lng),
        clusterManagerId: _clusterManagerId,
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          _hueForRole(user.role),
        ),
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
          fillColor: Colors.deepPurple.withValues(alpha: 0.08),
          strokeColor: Colors.deepPurple.withValues(alpha: 0.6),
          strokeWidth: 1,
        );
      }).toSet();

  // ---------------------------------------------------------------------------

  double _hueForRole(String role) => switch (role) {
        'plumber'  => gmaps.BitmapDescriptor.hueBlue,
        'mechanic' => gmaps.BitmapDescriptor.hueOrange,
        'teacher'  => gmaps.BitmapDescriptor.hueGreen,
        'driver'   => gmaps.BitmapDescriptor.hueViolet,
        _          => gmaps.BitmapDescriptor.hueRed,
      };

  @override
  Widget build(BuildContext context) {
    final showMarkers = widget.mode != ZoomMode.empty;

    return gmaps.GoogleMap(
      initialCameraPosition: _initialPosition,
      onMapCreated: (controller) {
        setState(() => _controller = controller);
        _reportViewport(_initialPosition.zoom);
      },
      onCameraMove: _onCameraMove,
      clusterManagers: {
        gmaps.ClusterManager(
          clusterManagerId: _clusterManagerId,
          onClusterTap: (_) {},
        ),
      },
      markers: showMarkers ? _buildMarkers() : {},
      polygons: {
        if (kDebugShowRegionBoundaries) ..._buildRegionDebugPolygons(),
      },
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}
