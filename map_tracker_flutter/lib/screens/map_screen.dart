import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/cache_entry.dart';
import '../providers/bucket_cache_provider.dart';
import '../providers/config_provider.dart';
import '../providers/map_state_provider.dart';
import '../services/viewer_service.dart';
import '../widgets/heatmap_layer.dart';
import '../widgets/user_marker.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
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

  void _onMapEvent(MapEvent event) {
    if (event is! MapEventMove && event is! MapEventRotate) return;
    final config = ref.read(configProvider).value;
    if (config == null) return;

    final camera = _mapController.camera;
    ref.read(mapStateProvider.notifier).update(
          zoom: camera.zoom,
          bounds: camera.visibleBounds,
          thresholdHeatmap: config.zoomThresholdHeatmap,
          thresholdDetail: config.zoomThresholdDetail,
        );

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _triggerRefresh);
  }

  void _triggerRefresh() {
    ref.read(viewerServiceProvider).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(configProvider);
    final mapState = ref.watch(mapStateProvider);
    final cache = ref.watch(bucketCacheProvider);

    return Scaffold(
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load config: $e')),
        data: (_) => FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(51.5, -0.09),
            initialZoom: 5.0,
            onMapEvent: _onMapEvent,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.isquibly.map_tracker',
            ),
            if (mapState.mode == ZoomMode.heatmap) _buildHeatmapLayer(cache),
            if (mapState.mode == ZoomMode.detail) _buildMarkerLayer(cache),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapLayer(Map<String, CacheEntry> cache) {
    final buckets = cache.entries
        .where((e) => e.key.endsWith('::heatmap') && e.value.heatmap != null)
        .map((e) => e.value.heatmap!)
        .toList();
    return HexHeatmapLayer(buckets: buckets);
  }

  Widget _buildMarkerLayer(Map<String, CacheEntry> cache) {
    final markers = cache.entries
        .where((e) => e.key.endsWith('::detail') && e.value.detail != null)
        .expand((e) => e.value.detail!.users)
        .map((user) => Marker(
              point: LatLng(user.lat, user.lng),
              width: 36,
              height: 36,
              child: UserMarker(user: user),
            ))
        .toList();
    return MarkerLayer(markers: markers);
  }
}
