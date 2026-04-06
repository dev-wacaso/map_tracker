import 'map_bounds.dart';

class Region {
  final String id;
  final String name;
  final double north;
  final double west;
  final double south;
  final double east;

  const Region({
    required this.id,
    required this.name,
    required this.north,
    required this.west,
    required this.south,
    required this.east,
  });

  /// Returns true if this region overlaps the given map viewport.
  bool intersects(MapBounds bounds) {
    return bounds.north >= south &&
        bounds.south <= north &&
        bounds.east >= west &&
        bounds.west <= east;
  }
}
