import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/regions.dart';
import '../models/app_config.dart';
import '../providers/api_service_provider.dart';
import '../providers/config_provider.dart';
import '../providers/fetching_provider.dart';
import '../providers/map_state_provider.dart';
import '../providers/region_bucket_cache_provider.dart';

/// Region-based viewer refresh cycle:
/// 1. Check zoom mode — bail if empty zone
/// 2. Compute visible regions from viewport (bounding-box intersection, client-side)
/// 3. Fetch any region whose cache entry is older than the refresh window (or missing)
/// 4. Merge into region cache and evict off-screen regions
///
/// No server timestamp pre-check — the cache age is the sole staleness signal.
/// This ensures pruned/emptied regions are always reflected on the next fetch.
class RegionViewerService {
  final Ref _ref;
  final AppConfig _config;

  RegionViewerService(this._ref, this._config);

  Future<void> refresh() async {
    final mapState = _ref.read(mapStateProvider);
    if (mapState.mode == ZoomMode.empty || mapState.bounds == null) return;

    final visibleRegions = regionsForViewport(mapState.bounds!);
    if (visibleRegions.isEmpty) return;

    final now = DateTime.now();
    final refreshWindow =
        Duration(seconds: _config.viewerRefreshIntervalDefaultSeconds);
    final currentCache = _ref.read(regionBucketCacheProvider);

    final staleIds = visibleRegions
        .map((r) => r.id)
        .where((id) {
          final entry = currentCache[id];
          if (entry == null) return true;
          return now.difference(entry.receivedAt) >= refreshWindow;
        })
        .toList();

    final cache = _ref.read(regionBucketCacheProvider.notifier);
    cache.evictRegionsNotIn(visibleRegions.map((r) => r.id).toSet());

    if (staleIds.isEmpty) return;

    _ref.read(fetchingProvider.notifier).state = true;
    try {
      final buckets =
          await _ref.read(apiServiceProvider).fetchRegionBuckets(staleIds);
      cache.mergeBuckets(buckets);
    } finally {
      _ref.read(fetchingProvider.notifier).state = false;
    }
  }
}

final regionViewerServiceProvider = Provider<RegionViewerService>((ref) {
  final config = ref.watch(configProvider).value;
  if (config == null) return RegionViewerService(ref, _defaultConfig);
  return RegionViewerService(ref, config);
});

const _defaultConfig = AppConfig(
  transmitterIntervalSeconds: 300,
  zoomThresholdHeatmap: 7.0,
  zoomThresholdDetail: 11.0,
  h3ResolutionHeatmap: 5,
  h3ResolutionDetail: 8,
  viewerRefreshIntervalDefaultSeconds: 300,
  markerToastDurationSeconds: 3,
);
