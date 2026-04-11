package com.isquibly.maptracker.service;

import com.isquibly.maptracker.config.AppProperties;
import org.springframework.stereotype.Service;

@Service
public class DynamicConfigService {
    
    private AppProperties currentConfig;
    
    public DynamicConfigService(AppProperties initialConfig) {
        this.currentConfig = initialConfig;
    }
    
    public AppProperties getCurrentConfig() {
        return currentConfig;
    }
    
    public AppProperties updateConfig(AppProperties newConfig) {
        this.currentConfig = newConfig;
        return currentConfig;
    }
    
    public AppProperties updatePartialConfig(
            Integer transmitterIntervalSeconds,
            Double zoomThresholdHeatmap,
            Double zoomThresholdDetail,
            Integer h3ResolutionHeatmap,
            Integer h3ResolutionDetail,
            Integer viewerRefreshIntervalDefaultSeconds) {

        AppProperties updatedConfig = new AppProperties(
            transmitterIntervalSeconds != null ? transmitterIntervalSeconds : currentConfig.transmitterIntervalSeconds(),
            zoomThresholdHeatmap != null ? zoomThresholdHeatmap : currentConfig.zoomThresholdHeatmap(),
            zoomThresholdDetail != null ? zoomThresholdDetail : currentConfig.zoomThresholdDetail(),
            h3ResolutionHeatmap != null ? h3ResolutionHeatmap : currentConfig.h3ResolutionHeatmap(),
            h3ResolutionDetail != null ? h3ResolutionDetail : currentConfig.h3ResolutionDetail(),
            viewerRefreshIntervalDefaultSeconds != null ? viewerRefreshIntervalDefaultSeconds : currentConfig.viewerRefreshIntervalDefaultSeconds(),
            currentConfig.riderTtlSeconds(),
            currentConfig.prunerIntervalSeconds(),
            currentConfig.markerToastDurationSeconds()
        );
        
        this.currentConfig = updatedConfig;
        return currentConfig;
    }
}
