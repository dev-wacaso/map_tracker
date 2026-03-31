package com.isquibly.maptracker.dto;

import java.time.OffsetDateTime;
import java.util.Map;

public record HeatmapBucket(
        String cell,
        OffsetDateTime updatedAt,
        int count,
        Map<String, Integer> breakdown
) {}
