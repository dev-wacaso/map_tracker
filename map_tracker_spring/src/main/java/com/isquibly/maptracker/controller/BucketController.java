package com.isquibly.maptracker.controller;

import com.isquibly.maptracker.dto.BucketsRequest;
import com.isquibly.maptracker.dto.CellTimestampsRequest;
import com.isquibly.maptracker.service.BucketService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequiredArgsConstructor
public class BucketController {

    private final BucketService bucketService;

    @PostMapping("/cells/timestamps")
    public Map<String, String> getCellTimestamps(@Valid @RequestBody CellTimestampsRequest request) {
        return bucketService.getCellTimestamps(request.cells());
    }

    @PostMapping("/buckets")
    public Map<String, ?> getBuckets(@Valid @RequestBody BucketsRequest request) {
        return switch (request.mode()) {
            case "detail"  -> bucketService.getDetailBuckets(request.cells());
            case "heatmap" -> bucketService.getHeatmapBuckets(request.cells());
            default -> throw new IllegalArgumentException("Unknown mode: " + request.mode());
        };
    }
}
