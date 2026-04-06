package com.isquibly.maptracker.region;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

/** POST /regions/timestamps — lightweight staleness check by region ID. */
public record RegionTimestampsRequest(@NotEmpty List<String> regions) {}
