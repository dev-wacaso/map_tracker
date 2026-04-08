package com.isquibly.maptracker.redis;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.isquibly.maptracker.config.AppProperties;
import com.isquibly.maptracker.dto.HeatmapBucket;
import com.isquibly.maptracker.dto.UserEntry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.*;

/**
 * All Redis I/O for the location tracking system.
 *
 * Key schema:
 *   cell:scores:{h3_detail}   — ZSet, member=userId, score=last_seen epoch secs
 *   cell:data:{h3_detail}     — Hash, field=userId, value=JSON UserEntry
 *   heatmap:users:{h3_coarse} — ZSet, member="{userId}:{role}", score=last_seen epoch secs
 *   cell:updated:{h3_cell}    — String, ISO timestamp of last write to this cell
 *   cell:heatmap:{h3_coarse}  — String, JSON HeatmapBucket cache (short TTL)
 *   user:lastpos:{userId}     — String, JSON {lat, lng}
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RedisLocationStore {

    static final Duration HEATMAP_CACHE = Duration.ofSeconds(45);

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;
    private final AppProperties config;

    // -------------------------------------------------------------------------
    // Write path (called by LocationService)
    // -------------------------------------------------------------------------

    public void upsertUser(String h3DetailCell, String h3HeatmapCell,
                           UserEntry entry, OffsetDateTime lastSeen) {
        double score = lastSeen.toEpochSecond();
        String json  = toJson(entry);

        // detail tracking
        redis.opsForZSet().add("cell:scores:" + h3DetailCell, entry.userId(), score);
        redis.opsForHash().put("cell:data:" + h3DetailCell, entry.userId(), json);

        // heatmap tracking (member encodes role so we can aggregate without hash lookup)
        redis.opsForZSet().add("heatmap:users:" + h3HeatmapCell,
                entry.userId() + ":" + entry.role(), score);

        // staleness timestamps for /cells/timestamps
        String isoNow = lastSeen.toString();
        redis.opsForValue().set("cell:updated:" + h3DetailCell, isoNow);
        redis.opsForValue().set("cell:updated:" + h3HeatmapCell, isoNow);

        // invalidate cached heatmap bucket
        redis.delete("cell:heatmap:" + h3HeatmapCell);
    }

    public void saveLastPosition(String userId, double lat, double lng) {
        String json = toJson(Map.of("lat", lat, "lng", lng));
        redis.opsForValue().set("user:lastpos:" + userId, json);
    }

    public Optional<double[]> getLastPosition(String userId) {
        String raw = redis.opsForValue().get("user:lastpos:" + userId);
        if (raw == null) return Optional.empty();
        try {
            var map = objectMapper.readValue(raw, Map.class);
            double lat = ((Number) map.get("lat")).doubleValue();
            double lng = ((Number) map.get("lng")).doubleValue();
            return Optional.of(new double[]{lat, lng});
        } catch (Exception e) {
            log.warn("Failed to parse last position for {}: {}", userId, e.getMessage());
            return Optional.empty();
        }
    }

    // -------------------------------------------------------------------------
    // Read path (called by BucketService)
    // -------------------------------------------------------------------------

    public List<UserEntry> getActiveUsers(String h3DetailCell) {
        Set<String> activeUserIds = redis.opsForZSet()
                .range("cell:scores:" + h3DetailCell, 0, -1);
        if (activeUserIds == null || activeUserIds.isEmpty()) return List.of();

        List<Object> rawEntries = redis.opsForHash().multiGet(
                "cell:data:" + h3DetailCell, new ArrayList<>(activeUserIds));

        List<UserEntry> result = new ArrayList<>();
        for (Object raw : rawEntries) {
            if (raw != null) {
                try {
                    result.add(objectMapper.readValue((String) raw, UserEntry.class));
                } catch (Exception e) {
                    log.warn("Failed to deserialize UserEntry: {}", e.getMessage());
                }
            }
        }
        return result;
    }

    public Optional<HeatmapBucket> getCachedHeatmap(String h3HeatmapCell) {
        String raw = redis.opsForValue().get("cell:heatmap:" + h3HeatmapCell);
        if (raw == null) return Optional.empty();
        try {
            return Optional.of(objectMapper.readValue(raw, HeatmapBucket.class));
        } catch (Exception e) {
            log.warn("Failed to deserialize cached heatmap for {}: {}", h3HeatmapCell, e.getMessage());
            return Optional.empty();
        }
    }

    public HeatmapBucket computeAndCacheHeatmap(String h3HeatmapCell) {
        Set<String> activeMembers = redis.opsForZSet()
                .range("heatmap:users:" + h3HeatmapCell, 0, -1);

        Map<String, Integer> breakdown = new HashMap<>();
        if (activeMembers != null) {
            for (String member : activeMembers) {
                // member format: "{userId}:{role}"
                int colonIdx = member.lastIndexOf(':');
                if (colonIdx > 0) {
                    String role = member.substring(colonIdx + 1);
                    breakdown.merge(role, 1, Integer::sum);
                }
            }
        }

        int count = breakdown.values().stream().mapToInt(Integer::intValue).sum();
        String updatedAt = redis.opsForValue().get("cell:updated:" + h3HeatmapCell);
        OffsetDateTime ts = updatedAt != null
                ? OffsetDateTime.parse(updatedAt)
                : OffsetDateTime.now(ZoneOffset.UTC);

        HeatmapBucket bucket = new HeatmapBucket(h3HeatmapCell, ts, count, breakdown);
        redis.opsForValue().set("cell:heatmap:" + h3HeatmapCell, toJson(bucket), HEATMAP_CACHE);
        return bucket;
    }

    public Map<String, String> getCellTimestamps(List<String> cells) {
        Map<String, String> result = new HashMap<>();
        for (String cell : cells) {
            result.put(cell, redis.opsForValue().get("cell:updated:" + cell));
        }
        return result;
    }

    // -------------------------------------------------------------------------
    // Cache rebuild (called on startup)
    // -------------------------------------------------------------------------

    public void upsertUserForRebuild(String h3DetailCell, String h3HeatmapCell, UserEntry entry, OffsetDateTime lastSeen) {
        upsertUser(h3DetailCell, h3HeatmapCell, entry, lastSeen);
    }

    // -------------------------------------------------------------------------

    private String toJson(Object obj) {
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Serialization failed", e);
        }
    }
}
