import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../map_adapter/flutter_map/flutter_map_view.dart';
import '../map_adapter/google_maps/google_map_view.dart';
import '../map_adapter/map_provider_type.dart';
import '../map_adapter/map_view.dart';
import '../models/map_bounds.dart';
import '../providers/config_provider.dart';
import '../providers/fetching_provider.dart';
import '../providers/map_provider_selector.dart';
import '../providers/map_state_provider.dart';
import '../providers/region_bucket_cache_provider.dart';
import '../services/region_viewer_service.dart';
import '../widgets/fetch_indicator.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  Timer? _refreshTimer;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    ref.read(configProvider.future).then((config) {
      _refreshTimer = Timer.periodic(
        Duration(seconds: config.viewerRefreshIntervalDefaultSeconds),
        (_) => _triggerRefresh(),
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onViewportChanged(double zoom, MapBounds bounds) {
    final config = ref.read(configProvider).value;
    if (config == null) return;

    ref.read(mapStateProvider.notifier).update(
          zoom: zoom,
          bounds: bounds,
          thresholdHeatmap: config.zoomThresholdHeatmap,
          thresholdDetail: config.zoomThresholdDetail,
        );

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _triggerRefresh);
  }

  void _triggerRefresh() {
    ref.read(regionViewerServiceProvider).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(configProvider);
    final mapState = ref.watch(mapStateProvider);
    final cache = ref.watch(bucketCacheProvider);
    final providerType = ref.watch(mapProviderTypeProvider);

    final isFetching = ref.watch(fetchingProvider);
    final regionCache = ref.watch(regionBucketCacheProvider);

    // All riders from every cached region bucket — map views decide how to render
    // based on zoom mode (heatmap layer vs individual markers).
    final users = regionCache.values
        .expand((entry) => entry.bucket.riders)
        .toList();

    // No H3 heatmap buckets in region mode — point heatmap is computed client-side
    // from the users list in FlutterMapView.
    const heatmapBuckets = <dynamic>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Tracker'),
        actions: [
          _MapToggle(
            current: providerType,
            onChanged: (type) =>
                ref.read(mapProviderTypeProvider.notifier).setProvider(type),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load config: $e')),
        data: (_) => Stack(
          children: [
            _buildMapView(providerType, mapState, heatmapBuckets, users),
            Positioned(
              top: 12,
              right: 12,
              child: FetchIndicator(isFetching: isFetching),
            ),
          ],
        ),
      ),
    );
  }

  MapView _buildMapView(MapProviderType type, MapState mapState,
      heatmapBuckets, users) {
    return switch (type) {
      MapProviderType.googleMaps => GoogleMapView(
          onViewportChanged: _onViewportChanged,
          mode: mapState.mode,
          heatmapBuckets: heatmapBuckets,
          users: users,
        ),
      MapProviderType.flutterMap => FlutterMapView(
          onViewportChanged: _onViewportChanged,
          mode: mapState.mode,
          heatmapBuckets: heatmapBuckets,
          users: users,
        ),
    };
  }
}

class _MapToggle extends StatelessWidget {
  final MapProviderType current;
  final void Function(MapProviderType) onChanged;

  const _MapToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MapProviderType>(
      segments: const [
        ButtonSegment(
          value: MapProviderType.googleMaps,
          label: Text('Google'),
          icon: Icon(Icons.map),
        ),
        ButtonSegment(
          value: MapProviderType.flutterMap,
          label: Text('OSM'),
          icon: Icon(Icons.public),
        ),
      ],
      selected: {current},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
