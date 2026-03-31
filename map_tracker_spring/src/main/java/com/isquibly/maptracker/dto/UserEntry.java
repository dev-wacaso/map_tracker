package com.isquibly.maptracker.dto;

import java.time.OffsetDateTime;

public record UserEntry(
        String userId,
        String role,
        double lat,
        double lng,
        Double bearing,
        OffsetDateTime lastSeen
) {}
