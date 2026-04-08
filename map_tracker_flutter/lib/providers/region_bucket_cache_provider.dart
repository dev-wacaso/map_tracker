import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/region_bucket.dart';
import '../models/region_cache_entry.dart';

class RegionBucketCacheNotifier extends Notifier<Map<String, RegionCacheEntry>> {
  @override
  Map<String, RegionCacheEntry> build() => {};

  void mergeBuckets(Map<String, RegionBucket> buckets) {
    final now = DateTime.now();
    state = {
      ...state,
      for (final e in buckets.entries)
        e.key: RegionCacheEntry(now, e.value),
    };
  }

  void evictRegionsNotIn(Set<String> visibleIds) {
    final evicted = state.keys.where((k) => !visibleIds.contains(k)).toList();
    if (evicted.isEmpty) return;
    state = Map.fromEntries(
      state.entries.where((e) => visibleIds.contains(e.key)),
    );
  }
}

final regionBucketCacheProvider =
    NotifierProvider<RegionBucketCacheNotifier, Map<String, RegionCacheEntry>>(
        RegionBucketCacheNotifier.new);
