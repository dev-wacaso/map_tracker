package com.isquibly.maptracker.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import java.util.List;

public record BucketsRequest(
        @NotEmpty List<String> cells,
        @NotNull @Pattern(regexp = "detail|heatmap") String mode
) {}
