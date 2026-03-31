package com.isquibly.maptracker.service;

import com.isquibly.maptracker.config.AppProperties;
import com.isquibly.maptracker.dto.LocationRequest;
import com.isquibly.maptracker.dto.UserEntry;
import com.isquibly.maptracker.entity.LocationPost;
import com.isquibly.maptracker.redis.RedisLocationStore;
import com.isquibly.maptracker.repository.LocationPostRepository;
import com.isquibly.maptracker.util.BearingCalculator;
import com.uber.h3core.H3Core;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.time.OffsetDateTime;
import java.util.Optional;

@Slf4j
@Service
public class LocationService {

    private static final GeometryFactory GF = new GeometryFactory(new PrecisionModel(), 4326);

    private final AppProperties config;
    private final RedisLocationStore redisStore;
    private final LocationPostRepository repository;
    private final H3Core h3;

    public LocationService(AppProperties config, RedisLocationStore redisStore,
                           LocationPostRepository repository) throws IOException {
        this.config     = config;
        this.redisStore = redisStore;
        this.repository = repository;
        this.h3         = H3Core.newInstance();
    }

    public void handleLocationPost(LocationRequest req) {
        String h3DetailCell  = h3.latLngToCellAddress(req.lat(), req.lng(), config.h3ResolutionDetail());
        String h3HeatmapCell = h3.cellToParentAddress(h3DetailCell, config.h3ResolutionHeatmap());

        // Compute bearing from previous position (null on first post)
        Double bearing = redisStore.getLastPosition(req.userId())
                .map(prev -> BearingCalculator.calculate(prev[0], prev[1], req.lat(), req.lng()))
                .orElse(null);

        UserEntry entry = new UserEntry(
                req.userId(), req.role(),
                req.lat(), req.lng(),
                bearing, req.timestamp()
        );

        redisStore.upsertUser(h3DetailCell, h3HeatmapCell, entry, req.timestamp());
        redisStore.saveLastPosition(req.userId(), req.lat(), req.lng());

        var point = GF.createPoint(new Coordinate(req.lng(), req.lat()));
        repository.save(LocationPost.builder()
                .userId(req.userId())
                .role(req.role())
                .location(point)
                .bearing(bearing)
                .timestamp(req.timestamp())
                .h3DetailCell(h3DetailCell)
                .h3HeatmapCell(h3HeatmapCell)
                .build());
    }
}
