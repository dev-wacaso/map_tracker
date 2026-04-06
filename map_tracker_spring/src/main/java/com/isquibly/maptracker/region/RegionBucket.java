package com.isquibly.maptracker.region;

import com.isquibly.maptracker.dto.UserEntry;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * Response bucket for a single named region.
 * Contains all active riders within the region's bounding box.
 */
public record RegionBucket(
        String regionId,
        String regionName,
        OffsetDateTime updatedAt,
        List<UserEntry> riders
) {}
