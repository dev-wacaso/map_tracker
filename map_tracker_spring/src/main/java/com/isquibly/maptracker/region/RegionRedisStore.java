package com.isquibly.maptracker.region;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.isquibly.maptracker.config.AppProperties;
import com.isquibly.maptracker.dto.UserEntry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.*;

/**
 * Redis I/O for the region-based location store.
 *
 * Key schema:
 *   region:scores:{regionId}  — ZSet,   member=userId,  score=lastSeen epoch secs
 *   region:data:{regionId}    — Hash,   field=userId,   value=JSON UserEntry
 *   region:updated:{regionId} — String, ISO timestamp of last write to this region
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RegionRedisStore {

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;
    private final AppProperties config;

    // -------------------------------------------------------------------------
    // Write path
    // -------------------------------------------------------------------------

    public void upsertRider(String regionId, UserEntry entry, OffsetDateTime lastSeen) {
        double score  = lastSeen.toEpochSecond();
        String json   = toJson(entry);
        String isoNow = lastSeen.toString();

        redis.opsForZSet().add("region:scores:" + regionId, entry.userId(), score);
        redis.opsForHash().put("region:data:"   + regionId, entry.userId(), json);
        redis.opsForValue().set("region:updated:" + regionId, isoNow);
    }

    // -------------------------------------------------------------------------
    // Read path
    // -------------------------------------------------------------------------

    public List<UserEntry> getActiveRiders(String regionId) {
        Set<String> activeIds = redis.opsForZSet()
                .range("region:scores:" + regionId, 0, -1);
        if (activeIds == null || activeIds.isEmpty()) return List.of();

        List<Object> rawEntries = redis.opsForHash()
                .multiGet("region:data:" + regionId, new ArrayList<>(activeIds));

        List<UserEntry> result = new ArrayList<>();
        for (Object raw : rawEntries) {
            if (raw != null) {
                try {
                    result.add(objectMapper.readValue((String) raw, UserEntry.class));
                } catch (Exception e) {
                    log.warn("Failed to deserialize rider entry for region {}: {}", regionId, e.getMessage());
                }
            }
        }
        return result;
    }

    /**
     * Removes riders whose last-seen score is older than the configured TTL.
     * Called by the pruner on a scheduled interval — not during reads.
     * Returns the number of riders removed.
     */
    public Optional<double[]> getExistingPosition(String regionId, String userId) {
        Object raw = redis.opsForHash().get("region:data:" + regionId, userId);
        if (raw == null) return Optional.empty();
        try {
            UserEntry entry = objectMapper.readValue((String) raw, UserEntry.class);
            return Optional.of(new double[]{entry.lat(), entry.lng()});
        } catch (Exception e) {
            log.warn("Failed to parse existing entry for user {} in region {}: {}", userId, regionId, e.getMessage());
            return Optional.empty();
        }
    }

    public int pruneExpired(String regionId) {
        double maxExpiredScore = Instant.now().getEpochSecond() - config.riderTtlSeconds();
        String scoresKey = "region:scores:" + regionId;
        String dataKey   = "region:data:"   + regionId;

        Set<String> expired = redis.opsForZSet().rangeByScore(scoresKey, Double.NEGATIVE_INFINITY, maxExpiredScore);
        if (expired == null || expired.isEmpty()) return 0;

        redis.opsForZSet().removeRangeByScore(scoresKey, Double.NEGATIVE_INFINITY, maxExpiredScore);
        redis.opsForHash().delete(dataKey, expired.toArray());
        return expired.size();
    }

    public Map<String, String> getRegionTimestamps(List<String> regionIds) {
        Map<String, String> result = new HashMap<>();
        for (String id : regionIds) {
            result.put(id, redis.opsForValue().get("region:updated:" + id));
        }
        return result;
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
