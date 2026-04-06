package com.isquibly.maptracker.region;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
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

    private final RegionBucketService regionBucketService;

    /**
     * Lightweight staleness check.
     * Client sends the region IDs it can see; server returns the last-updated
     * timestamp for each. Null means the region has no active riders.
     */
    @PostMapping("/timestamps")
    public Map<String, String> getRegionTimestamps(
            @Valid @RequestBody RegionTimestampsRequest request) {
        return regionBucketService.getRegionTimestamps(request.regions());
    }

    /**
     * Fetch full region buckets.
     * Client sends only the stale/missing region IDs; server returns each bucket
     * with its complete active rider list.
     */
    @PostMapping("/buckets")
    public Map<String, RegionBucket> getRegionBuckets(
            @Valid @RequestBody RegionBucketsRequest request) {
        return regionBucketService.getRegionBuckets(request.regions());
    }
}
