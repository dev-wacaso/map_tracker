import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_config.dart';
import '../providers/api_service_provider.dart';
import '../providers/bucket_cache_provider.dart';
import '../providers/config_provider.dart';
import '../providers/map_state_provider.dart';
import '../utils/h3_viewport.dart';

/// Orchestrates the viewer refresh cycle:
/// 1. Check zoom mode
/// 2. Compute visible cells
/// 3. Identify stale cells (via /cells/timestamps or local cache age)
/// 4. Fetch missing/stale buckets
/// 5. Merge into cache and evict off-screen cells
class ViewerService {
  final Ref _ref;
  final AppConfig _config;

  ViewerService(this._ref, this._config);

  Future<void> refresh() async {
    final mapState = _ref.read(mapStateProvider);
    if (mapState.mode == ZoomMode.empty || mapState.bounds == null) return;

    final mode = mapState.mode == ZoomMode.detail ? 'detail' : 'heatmap';
    final resolution = mode == 'detail'
        ? _config.h3ResolutionDetail
        : _config.h3ResolutionHeatmap;

    final visibleCells = cellsForViewport(mapState.bounds!, resolution);
    if (visibleCells.isEmpty) return;

    final maxAge = Duration(seconds: _config.viewerRefreshIntervalDefaultSeconds);
    final cache = _ref.read(bucketCacheProvider.notifier);

    // Lightweight staleness check via server timestamps
    final serverTimestamps =
        await _ref.read(apiServiceProvider).fetchCellTimestamps(visibleCells);

    final staleCells = visibleCells.where((cell) {
      final serverTs = serverTimestamps[cell];
      if (serverTs == null) return false; // cell has no data on server
      final entry = _ref.read(bucketCacheProvider)['$cell::$mode'];
      if (entry == null) return true; // not cached
      final serverTime = DateTime.parse(serverTs);
      return serverTime.isAfter(entry.receivedAt); // server has newer data
    }).toList();

    if (staleCells.isNotEmpty) {
      final api = _ref.read(apiServiceProvider);
      if (mode == 'detail') {
        final buckets = await api.fetchDetailBuckets(staleCells);
        cache.mergeDetailBuckets(buckets);
      } else {
        final buckets = await api.fetchHeatmapBuckets(staleCells);
        cache.mergeHeatmapBuckets(buckets);
      }
    }

    cache.evictCellsNotIn(visibleCells.toSet());
  }
}

final viewerServiceProvider = Provider<ViewerService>((ref) {
  // Depends on config being loaded; callers should guard on configProvider state
  final config = ref.watch(configProvider).value;
  if (config == null) return ViewerService(ref, _defaultConfig);
  return ViewerService(ref, config);
});

// Used before config is loaded so the provider can be constructed safely
const _defaultConfig = AppConfig(
  transmitterIntervalSeconds: 300,
  zoomThresholdHeatmap: 7.0,
  zoomThresholdDetail: 11.0,
  h3ResolutionHeatmap: 5,
  h3ResolutionDetail: 8,
  viewerRefreshIntervalDefaultSeconds: 300,
);
