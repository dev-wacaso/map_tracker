package com.isquibly.maptracker.region;

/**
 * A named geographic bounding box.
 * Bounding box format: north, west, south, east (all decimal degrees).
 */
public record Region(
        String id,
        String name,
        double north,
        double west,
        double south,
        double east
) {}
