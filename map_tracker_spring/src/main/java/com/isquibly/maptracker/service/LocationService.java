package com.isquibly.maptracker.service;

import com.isquibly.maptracker.config.AppProperties;
import com.isquibly.maptracker.dto.LocationRequest;
import com.isquibly.maptracker.dto.UserEntry;
import com.isquibly.maptracker.redis.RedisLocationStore;
import com.isquibly.maptracker.region.Region;
import com.isquibly.maptracker.region.RegionLookup;
import com.isquibly.maptracker.region.RegionRedisStore;
import com.isquibly.maptracker.util.BearingCalculator;
import com.uber.h3core.H3Core;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.List;

@Slf4j
@Service
public class LocationService {

    private final AppProperties config;
    private final RedisLocationStore redisStore;
    private final RegionRedisStore regionRedisStore;
    private final H3Core h3;

    public LocationService(AppProperties config, RedisLocationStore redisStore,
                           RegionRedisStore regionRedisStore) throws IOException {
        this.config           = config;
        this.redisStore       = redisStore;
        this.regionRedisStore = regionRedisStore;
        this.h3               = H3Core.newInstance();
    }

    public void handleLocationPost(LocationRequest req) {
        String h3DetailCell  = h3.latLngToCellAddress(req.lat(), req.lng(), config.h3ResolutionDetail());
        String h3HeatmapCell = h3.cellToParentAddress(h3DetailCell, config.h3ResolutionHeatmap());

        // Compute bearing from user's live region bucket entry in Redis — null if new or pruned
        List<Region> matchedRegions = RegionLookup.findRegions(req.lat(), req.lng());
        Double bearing = matchedRegions.stream()
                .flatMap(r -> regionRedisStore.getExistingPosition(r.id(), req.userId()).stream())
                .findFirst()
                .map(prev -> BearingCalculator.calculate(prev[0], prev[1], req.lat(), req.lng()))
                .orElse(null);

        UserEntry entry = new UserEntry(
                req.userId(), req.role(),
                req.lat(), req.lng(),
                bearing, req.timestamp()
        );

        // H3 write path
        redisStore.upsertUser(h3DetailCell, h3HeatmapCell, entry, req.timestamp());

        // Region write path — write to every matching region (border riders may match >1)
        matchedRegions.forEach(region -> regionRedisStore.upsertRider(region.id(), entry, req.timestamp()));
    }
}
