import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:h3_flutter/h3_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/heatmap_bucket.dart';
import '../utils/h3_viewport.dart';

final _h3 = const H3Factory().load();

/// Renders H3 heatmap cells as filled hexagonal polygons.
/// Color intensity scales with [HeatmapBucket.count].
class HexHeatmapLayer extends StatelessWidget {
  final List<HeatmapBucket> buckets;

  const HexHeatmapLayer({super.key, required this.buckets});

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) return const SizedBox.shrink();

    final maxCount = buckets.map((b) => b.count).reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return const SizedBox.shrink();

    final polygons = buckets.map((bucket) {
      final boundary = _h3.cellToBoundary(h3IndexFromString(bucket.cell));
      final points = boundary.map((c) => LatLng(c.lat, c.lon)).toList();
      final intensity = bucket.count / maxCount;
      return Polygon(
        points: points,
        color: _heatColor(intensity).withValues(alpha: 0.55),
        borderColor: _heatColor(intensity).withValues(alpha: 0.8),
        borderStrokeWidth: 1.0,
      );
    }).toList();

    return PolygonLayer(polygons: polygons);
  }

  /// Maps intensity (0.0–1.0) to a yellow→orange→red gradient.
  Color _heatColor(double t) {
    if (t < 0.5) {
      return Color.lerp(Colors.yellow, Colors.orange, t * 2)!;
    } else {
      return Color.lerp(Colors.orange, Colors.red, (t - 0.5) * 2)!;
    }
  }
}
