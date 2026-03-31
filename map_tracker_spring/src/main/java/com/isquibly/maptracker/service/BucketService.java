package com.isquibly.maptracker.service;

import com.isquibly.maptracker.dto.DetailBucket;
import com.isquibly.maptracker.dto.HeatmapBucket;
import com.isquibly.maptracker.dto.UserEntry;
import com.isquibly.maptracker.redis.RedisLocationStore;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class BucketService {

    private static final int WINDOW_MINUTES = 10;

    private final RedisLocationStore redisStore;

    public Map<String, DetailBucket> getDetailBuckets(List<String> cells) {
        Map<String, DetailBucket> result = new LinkedHashMap<>();
        for (String cell : cells) {
            List<UserEntry> users = redisStore.getActiveUsers(cell);
            OffsetDateTime updatedAt = users.isEmpty()
                    ? OffsetDateTime.now(ZoneOffset.UTC)
                    : users.stream()
                            .map(UserEntry::lastSeen)
                            .max(OffsetDateTime::compareTo)
                            .orElse(OffsetDateTime.now(ZoneOffset.UTC));
            result.put(cell, new DetailBucket(cell, updatedAt, WINDOW_MINUTES, users));
        }
        return result;
    }

    public Map<String, HeatmapBucket> getHeatmapBuckets(List<String> cells) {
        Map<String, HeatmapBucket> result = new LinkedHashMap<>();
        for (String cell : cells) {
            HeatmapBucket bucket = redisStore.getCachedHeatmap(cell)
                    .orElseGet(() -> redisStore.computeAndCacheHeatmap(cell));
            result.put(cell, bucket);
        }
        return result;
    }

    public Map<String, String> getCellTimestamps(List<String> cells) {
        return redisStore.getCellTimestamps(cells);
    }
}
