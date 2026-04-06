package com.isquibly.maptracker.region;

import com.isquibly.maptracker.dto.UserEntry;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class RegionBucketService {

    private final RegionRedisStore regionRedisStore;

    public Map<String, String> getRegionTimestamps(List<String> regionIds) {
        return regionRedisStore.getRegionTimestamps(regionIds);
    }

    public Map<String, RegionBucket> getRegionBuckets(List<String> regionIds) {
        Map<String, RegionBucket> result = new LinkedHashMap<>();

        for (String id : regionIds) {
            Optional<Region> region = Regions.ALL.stream()
                    .filter(r -> r.id().equals(id))
                    .findFirst();

            String regionName = region.map(Region::name).orElse(id);
            List<UserEntry> riders = regionRedisStore.getActiveRiders(id);

            OffsetDateTime updatedAt = riders.isEmpty()
                    ? OffsetDateTime.now(ZoneOffset.UTC)
                    : riders.stream()
                            .map(UserEntry::lastSeen)
                            .max(OffsetDateTime::compareTo)
                            .orElse(OffsetDateTime.now(ZoneOffset.UTC));

            result.put(id, new RegionBucket(id, regionName, updatedAt, riders));
        }

        return result;
    }
}
