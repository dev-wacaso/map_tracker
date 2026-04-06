/// Map-library-agnostic bounding box, used throughout business logic
/// so providers and services have no dependency on flutter_map or google_maps_flutter.
class MapBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  const MapBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}
