package com.isquibly.maptracker.dto;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record CellTimestampsRequest(
        @NotEmpty List<String> cells
) {}
