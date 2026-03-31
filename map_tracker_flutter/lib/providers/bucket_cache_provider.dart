import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cache_entry.dart';
import '../models/detail_bucket.dart';
import '../models/heatmap_bucket.dart';

class BucketCacheNotifier extends Notifier<Map<String, CacheEntry>> {
  @override
  Map<String, CacheEntry> build() => {};

  void mergeDetailBuckets(Map<String, DetailBucket> buckets) {
    final now = DateTime.now();
    state = {
      ...state,
      for (final e in buckets.entries)
        '${e.key}::detail': CacheEntry.detail(now, e.value),
    };
  }

  void mergeHeatmapBuckets(Map<String, HeatmapBucket> buckets) {
    final now = DateTime.now();
    state = {
      ...state,
      for (final e in buckets.entries)
        '${e.key}::heatmap': CacheEntry.heatmap(now, e.value),
    };
  }

  void evictCellsNotIn(Set<String> visibleCellKeys) {
    state = Map.fromEntries(
      state.entries.where((e) {
        final cell = e.key.split('::').first;
        return visibleCellKeys.contains(cell);
      }),
    );
  }

  /// Returns cell IDs that are missing or older than [maxAge] for [mode].
  List<String> getStaleCells(
      List<String> visibleCells, String mode, Duration maxAge) {
    return visibleCells.where((cell) {
      final entry = state['$cell::$mode'];
      return entry == null || entry.isStale(maxAge);
    }).toList();
  }
}

final bucketCacheProvider =
    NotifierProvider<BucketCacheNotifier, Map<String, CacheEntry>>(
        BucketCacheNotifier.new);
