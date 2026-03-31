import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ZoomMode { empty, heatmap, detail }

class MapState {
  final double zoom;
  final LatLngBounds? bounds;
  final ZoomMode mode;

  const MapState({
    this.zoom = 5.0,
    this.bounds,
    this.mode = ZoomMode.empty,
  });

  MapState copyWith({double? zoom, LatLngBounds? bounds, ZoomMode? mode}) =>
      MapState(
        zoom: zoom ?? this.zoom,
        bounds: bounds ?? this.bounds,
        mode: mode ?? this.mode,
      );
}

class MapStateNotifier extends Notifier<MapState> {
  static const double _hysteresis = 0.5;

  @override
  MapState build() => const MapState();

  void update({
    required double zoom,
    required LatLngBounds bounds,
    required double thresholdHeatmap,
    required double thresholdDetail,
  }) {
    final newMode = _computeMode(zoom, state.mode, thresholdHeatmap, thresholdDetail);
    state = state.copyWith(zoom: zoom, bounds: bounds, mode: newMode);
  }

  ZoomMode _computeMode(
    double zoom,
    ZoomMode current,
    double thresholdHeatmap,
    double thresholdDetail,
  ) {
    if (zoom > thresholdDetail) return ZoomMode.detail;
    if (zoom < thresholdHeatmap) return ZoomMode.empty;

    // Apply hysteresis when transitioning back from detail to heatmap
    if (current == ZoomMode.detail && zoom > thresholdDetail - _hysteresis) {
      return ZoomMode.detail;
    }
    return ZoomMode.heatmap;
  }
}

final mapStateProvider =
    NotifierProvider<MapStateNotifier, MapState>(MapStateNotifier.new);
