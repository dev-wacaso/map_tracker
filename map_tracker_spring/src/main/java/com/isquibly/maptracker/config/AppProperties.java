package com.isquibly.maptracker.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.config")
public record AppProperties(
        int transmitterIntervalSeconds,
        double zoomThresholdHeatmap,
        double zoomThresholdDetail,
        int h3ResolutionHeatmap,
        int h3ResolutionDetail,
        int viewerRefreshIntervalDefaultSeconds
) {}
