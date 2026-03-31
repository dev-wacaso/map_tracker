import 'detail_bucket.dart';
import 'heatmap_bucket.dart';

/// An entry in the local bucket cache.
/// Key format: "{h3_cell_id}::detail" or "{h3_cell_id}::heatmap"
class CacheEntry {
  final DateTime receivedAt;
  final DetailBucket? detail;
  final HeatmapBucket? heatmap;

  const CacheEntry.detail(this.receivedAt, DetailBucket bucket)
      : detail = bucket,
        heatmap = null;

  const CacheEntry.heatmap(this.receivedAt, HeatmapBucket bucket)
      : heatmap = bucket,
        detail = null;

  bool isStale(Duration maxAge) =>
      DateTime.now().difference(receivedAt) > maxAge;
}
