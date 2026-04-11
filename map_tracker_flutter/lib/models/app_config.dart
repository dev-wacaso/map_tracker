class AppConfig {
  final int transmitterIntervalSeconds;
  final double zoomThresholdHeatmap;
  final double zoomThresholdDetail;
  final int h3ResolutionHeatmap;
  final int h3ResolutionDetail;
  final int viewerRefreshIntervalDefaultSeconds;
  final int markerToastDurationSeconds;

  const AppConfig({
    required this.transmitterIntervalSeconds,
    required this.zoomThresholdHeatmap,
    required this.zoomThresholdDetail,
    required this.h3ResolutionHeatmap,
    required this.h3ResolutionDetail,
    required this.viewerRefreshIntervalDefaultSeconds,
    required this.markerToastDurationSeconds,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        transmitterIntervalSeconds: json['transmitter_interval_seconds'] as int,
        zoomThresholdHeatmap: (json['zoom_threshold_heatmap'] as num).toDouble(),
        zoomThresholdDetail: (json['zoom_threshold_detail'] as num).toDouble(),
        h3ResolutionHeatmap: json['h3_resolution_heatmap'] as int,
        h3ResolutionDetail: json['h3_resolution_detail'] as int,
        viewerRefreshIntervalDefaultSeconds:
            json['viewer_refresh_interval_default_seconds'] as int,
        markerToastDurationSeconds:
            json['marker_toast_duration_seconds'] as int,
      );
}
