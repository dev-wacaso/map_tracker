import 'package:h3_flutter/h3_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/map_bounds.dart';

final _h3 = const H3Factory().load();

/// Returns H3 cell IDs (lowercase hex strings) covering [bounds] at [resolution].
List<String> cellsForViewport(MapBounds bounds, int resolution) {
  final cells = _h3.polygonToCells(
    perimeter: [
      GeoCoord(lat: bounds.north, lon: bounds.west),
      GeoCoord(lat: bounds.north, lon: bounds.east),
      GeoCoord(lat: bounds.south, lon: bounds.east),
      GeoCoord(lat: bounds.south, lon: bounds.west),
    ],
    resolution: resolution,
  );
  return cells.map(h3IndexToString).toList();
}

/// Converts an H3Index (BigInt) to the standard lowercase hex string.
String h3IndexToString(H3Index index) => index.toRadixString(16);

/// Converts a hex string cell ID back to H3Index for API calls.
H3Index h3IndexFromString(String cellId) => BigInt.parse(cellId, radix: 16);

/// Returns the center [LatLng] of an H3 cell (by string ID).
LatLng cellCenter(String cellId) {
  final geo = _h3.cellToGeo(h3IndexFromString(cellId));
  return LatLng(geo.lat, geo.lon);
}
