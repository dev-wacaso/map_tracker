package com.isquibly.maptracker.region;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
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

    static final Duration RIDER_TTL = Duration.ofSeconds(600);

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;

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
        double minScore = Instant.now().getEpochSecond() - RIDER_TTL.toSeconds();

        Set<String> activeIds = redis.opsForZSet()
                .rangeByScore("region:scores:" + regionId, minScore, Double.MAX_VALUE);
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
