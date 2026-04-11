import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../map_adapter/flutter_map/flutter_map_view.dart';
import '../map_adapter/google_maps/google_map_view.dart';
import '../map_adapter/map_provider_type.dart';
import '../map_adapter/map_view.dart';
import '../models/app_config.dart';
import '../models/map_bounds.dart';
import '../config/debug_flags.dart';
import '../models/user_entry.dart';
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

  // Sensible defaults used until /config responds. Keep in sync with
  // _defaultConfig in region_viewer_service.dart.
  static const double _defaultThresholdHeatmap = 5.25;
  static const double _defaultThresholdDetail = 6;
  static const int _defaultRefreshSeconds = 300;
  static const int _defaultMarkerToastSeconds = 5;

  int _markerToastSeconds = _defaultMarkerToastSeconds;

  @override
  void initState() {
    super.initState();

    // Start the map and refresh cycle immediately with defaults so the map is
    // usable even when the backend is unreachable.
    _triggerRefresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: _defaultRefreshSeconds),
      (_) => _triggerRefresh(),
    );

    // If the backend responds, upgrade the timer to the server-configured interval.
    ref.read(configProvider.future).then((AppConfig config) {
      if (!mounted) return;
      _markerToastSeconds = config.markerToastDurationSeconds;
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(
        Duration(seconds: config.viewerRefreshIntervalDefaultSeconds),
        (_) => _triggerRefresh(),
      );
    }).catchError((_) {
      // Keep running with defaults — the error banner will inform the user.
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
    ref.read(mapStateProvider.notifier).update(
          zoom: zoom,
          bounds: bounds,
          thresholdHeatmap:
              config?.zoomThresholdHeatmap ?? _defaultThresholdHeatmap,
          thresholdDetail:
              config?.zoomThresholdDetail ?? _defaultThresholdDetail,
        );

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _triggerRefresh);
  }

  void _triggerRefresh() {
    ref.read(regionViewerServiceProvider).refresh();
  }

  void _onMarkerTap(UserEntry user) {
    final lastSeen = _formatLocalTime(user.lastSeen);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: Duration(seconds: _markerToastSeconds),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.userId,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text('Role: ${user.role}'),
              Text('Last update: $lastSeen'),
            ],
          ),
        ),
      );
  }

  String _formatLocalTime(DateTime dt) {
    final t = dt.toLocal();
    final period = t.hour < 12 ? 'AM' : 'PM';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(configProvider);
    final mapState = ref.watch(mapStateProvider);
    final providerType = ref.watch(mapProviderTypeProvider);
    final isFetching = ref.watch(fetchingProvider);
    final regionCache = ref.watch(regionBucketCacheProvider);

    final users = regionCache.values
        .expand((entry) => entry.bucket.riders)
        .toList();

    final backendError = configAsync.hasError;

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
      body: Stack(
        children: [
          _buildMapView(providerType, mapState, users),
          Positioned(
            top: 12,
            right: 12,
            child: FetchIndicator(isFetching: isFetching),
          ),
          if (backendError)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BackendErrorBanner(),
            ),
          if (kDebugShowZoomLevel)
            Positioned(
              bottom: backendError ? 36 : 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'zoom: ${mapState.zoom.toStringAsFixed(2)}  [${mapState.mode.name}]',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  MapView _buildMapView(
      MapProviderType type, MapState mapState, List<UserEntry> users) {
    return switch (type) {
      MapProviderType.googleMaps => GoogleMapView(
          onViewportChanged: _onViewportChanged,
          onMarkerTap: _onMarkerTap,
          mode: mapState.mode,
          users: users,
        ),
      MapProviderType.flutterMap => FlutterMapView(
          onViewportChanged: _onViewportChanged,
          onMarkerTap: _onMarkerTap,
          mode: mapState.mode,
          users: users,
        ),
    };
  }
}

class _BackendErrorBanner extends StatelessWidget {
  const _BackendErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade800,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          'Backend unavailable — running with defaults',
          style: TextStyle(color: Colors.white, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
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
