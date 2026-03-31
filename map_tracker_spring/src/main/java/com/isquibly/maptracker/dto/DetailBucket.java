package com.isquibly.maptracker.dto;

import java.time.OffsetDateTime;
import java.util.List;

public record DetailBucket(
        String cell,
        OffsetDateTime updatedAt,
        int windowMinutes,
        List<UserEntry> users
) {}
