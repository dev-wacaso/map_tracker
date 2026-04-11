import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Lazily loads and caches [BitmapDescriptor]s for each role.
///
/// Uses the `mrk_*_24.png` pin assets (tip points DOWN).
/// Apply [Marker.rotation] to point the pin toward a bearing.
/// Set [Marker.anchor] to (0.5, 1.0) so the tip touches the map position.
class MarkerBitmapCache {
  MarkerBitmapCache._();
  static final instance = MarkerBitmapCache._();

  final Map<String, BitmapDescriptor> _cache = {};

  static String _assetFor(String role) => switch (role) {
        'plumber'  => 'assets/markers/mrk_blue_24.png',
        'mechanic' => 'assets/markers/mrk_orange_24.png',
        'teacher'  => 'assets/markers/mrk_green_24.png',
        'driver'   => 'assets/markers/mrk_purple_24.png',
        _          => 'assets/markers/mrk_red_24.png',
      };

  Future<BitmapDescriptor> descriptorFor(String role) async {
    if (_cache.containsKey(role)) return _cache[role]!;

    final path = _assetFor(role);
    final bytes = await rootBundle.load(path);
    final descriptor = BitmapDescriptor.bytes(bytes.buffer.asUint8List());
    _cache[role] = descriptor;
    return descriptor;
  }
}
