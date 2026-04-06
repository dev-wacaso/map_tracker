package com.isquibly.maptracker.controller;

import com.isquibly.maptracker.config.AppProperties;
import com.isquibly.maptracker.service.DynamicConfigService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
@Slf4j
public class AdminController {
    
    private final DynamicConfigService dynamicConfigService;
    
    @GetMapping("/config")
    public ResponseEntity<AppProperties> getCurrentConfig() {
        return ResponseEntity.ok(dynamicConfigService.getCurrentConfig());
    }
    
    @PutMapping("/config")
    public ResponseEntity<AppProperties> updateFullConfig(@RequestBody AppProperties newConfig) {
        log.info("Updating full configuration: {}", newConfig);
        AppProperties updatedConfig = dynamicConfigService.updateConfig(newConfig);
        return ResponseEntity.ok(updatedConfig);
    }
    
    @PatchMapping("/config")
    public ResponseEntity<AppProperties> updatePartialConfig(
            @RequestParam(required = false) Integer transmitterIntervalSeconds,
            @RequestParam(required = false) Double zoomThresholdHeatmap,
            @RequestParam(required = false) Double zoomThresholdDetail,
            @RequestParam(required = false) Integer h3ResolutionHeatmap,
            @RequestParam(required = false) Integer h3ResolutionDetail,
            @RequestParam(required = false) Integer viewerRefreshIntervalDefaultSeconds) {
        
        log.info("Updating partial configuration - transmitterInterval: {}, zoomThresholdHeatmap: {}", 
                transmitterIntervalSeconds, zoomThresholdHeatmap);
        
        AppProperties updatedConfig = dynamicConfigService.updatePartialConfig(
                transmitterIntervalSeconds, zoomThresholdHeatmap, zoomThresholdDetail,
                h3ResolutionHeatmap, h3ResolutionDetail, viewerRefreshIntervalDefaultSeconds);
        
        return ResponseEntity.ok(updatedConfig);
    }
    
    @PostMapping("/config/reset")
    public ResponseEntity<String> resetConfig(@RequestBody AppProperties defaultConfig) {
        log.info("Resetting configuration to defaults: {}", defaultConfig);
        dynamicConfigService.updateConfig(defaultConfig);
        return ResponseEntity.ok("Configuration reset to defaults");
    }
}
