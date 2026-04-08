package com.isquibly.maptracker.region;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Region-based bucket API — new design running alongside the H3 implementation.
 *
 * POST /regions/timestamps  — lightweight staleness check; returns last-updated ISO timestamp per region.
 * POST /regions/buckets     — returns full rider list for each requested region.
 */
@RestController
@RequestMapping("/regions")
@RequiredArgsConstructor
public class RegionController {

    private static final Logger log = LoggerFactory.getLogger(RegionController.class);
    private final RegionBucketService regionBucketService;

    /**
     * Lightweight staleness check.
     * Client sends the region IDs it can see; server returns the last-updated
     * timestamp for each. Null means the region has no active riders.
     */
    @PostMapping("/timestamps")
    public Map<String, String> getRegionTimestamps(
            @Valid @RequestBody RegionTimestampsRequest request) {
        log.debug("getRegionTimestamps requested regions: {}", request.regions());
        Map<String, String> result = regionBucketService.getRegionTimestamps(request.regions());
        log.debug("getRegionTimestamps result: {} regions with data out of {} requested", result.values().stream().filter(v -> v != null).count(), request.regions().size());
        return result;
    }

    /**
     * Fetch full region buckets.
     * Client sends only the stale/missing region IDs; server returns each bucket
     * with its complete active rider list.
     */
    @PostMapping("/buckets")
    public Map<String, RegionBucket> getRegionBuckets(
            @Valid @RequestBody RegionBucketsRequest request) {
        Map<String, RegionBucket> result = regionBucketService.getRegionBuckets(request.regions());
        result.forEach((regionId, bucket) ->
                log.debug("getRegionBuckets region={} count={}", regionId, bucket.riders().size()));
        return result;
    }
}
