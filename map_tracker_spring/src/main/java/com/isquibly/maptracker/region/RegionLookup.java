package com.isquibly.maptracker.region;

import java.util.List;

/**
 * Resolves a lat/lng to all matching regions via bounding-box test.
 * A point near a border may match more than one region — all matches are returned.
 */
public final class RegionLookup {

    private RegionLookup() {}

    public static List<Region> findRegions(double lat, double lng) {
        return Regions.ALL.stream()
                .filter(r -> lat <= r.north() && lat >= r.south()
                          && lng >= r.west()  && lng <= r.east())
                .toList();
    }
}
