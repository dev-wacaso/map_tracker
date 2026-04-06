package com.isquibly.maptracker.region;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

/** POST /regions/buckets — fetch full rider buckets for the given region IDs. */
public record RegionBucketsRequest(@NotEmpty List<String> regions) {}
