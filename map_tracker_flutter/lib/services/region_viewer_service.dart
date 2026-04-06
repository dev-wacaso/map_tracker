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
/// 3. POST /regions/timestamps — identify stale/missing regions
/// 4. POST /regions/buckets   — fetch only stale/missing regions
/// 5. Merge into region cache and evict off-screen regions
class RegionViewerService {
  final Ref _ref;
  final AppConfig _config;

  RegionViewerService(this._ref, this._config);

  Future<void> refresh() async {
    final mapState = _ref.read(mapStateProvider);
    if (mapState.mode == ZoomMode.empty || mapState.bounds == null) return;

    final visibleRegions = regionsForViewport(mapState.bounds!);
    if (visibleRegions.isEmpty) return;

    final regionIds = visibleRegions.map((r) => r.id).toList();
    final cache = _ref.read(regionBucketCacheProvider.notifier);

    _ref.read(fetchingProvider.notifier).state = true;
    try {
      final serverTimestamps =
          await _ref.read(apiServiceProvider).fetchRegionTimestamps(regionIds);

      final staleIds = regionIds.where((id) {
        final serverTs = serverTimestamps[id];
        if (serverTs == null) return false; // no riders in this region
        final entry = _ref.read(regionBucketCacheProvider)[id];
        if (entry == null) return true; // not cached yet
        final serverTime = DateTime.parse(serverTs);
        return serverTime.isAfter(entry.receivedAt); // server has newer data
      }).toList();

      if (staleIds.isNotEmpty) {
        final buckets =
            await _ref.read(apiServiceProvider).fetchRegionBuckets(staleIds);
        cache.mergeBuckets(buckets);
      }

      cache.evictRegionsNotIn(regionIds.toSet());
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
);
