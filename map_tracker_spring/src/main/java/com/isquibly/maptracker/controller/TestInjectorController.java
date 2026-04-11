package com.isquibly.maptracker.controller;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.isquibly.maptracker.dto.LocationRequest;
import com.isquibly.maptracker.region.Region;
import com.isquibly.maptracker.region.Regions;
import com.isquibly.maptracker.service.LocationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.stream.Collectors;

/**
 * Test-only controller for injecting fake location data without a real transmitter.
 *
 * POST /test/inject  — inject a single position for a user at the current timestamp.
 * POST /test/route   — inject a sequence of waypoints with artificial timestamps spaced
 *                      by intervalSeconds.  Bearing is computed correctly because each
 *                      waypoint reads the previous Redis-stored position.
 */
@RestController
@RequestMapping("/test")
@RequiredArgsConstructor
@Slf4j
public class TestInjectorController {

    private final LocationService locationService;

    // -------------------------------------------------------------------------
    // POST /test/inject
    // -------------------------------------------------------------------------

    @PostMapping("/inject")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void inject(@Valid @RequestBody InjectRequest request) {
        log.info("Test inject: user={} role={} lat={} lng={}",
                request.userId(), request.role(), request.lat(), request.lng());
        locationService.handleLocationPost(new LocationRequest(
                request.userId(),
                request.role(),
                request.lat(),
                request.lng(),
                OffsetDateTime.now(ZoneOffset.UTC)
        ));
    }

    // -------------------------------------------------------------------------
    // POST /test/route
    // -------------------------------------------------------------------------

    @PostMapping("/route")
    public Map<String, Object> injectRoute(@Valid @RequestBody RouteRequest request) {
        int count = request.waypoints().size();
        int intervalSecs = request.intervalSeconds() > 0 ? request.intervalSeconds() : 300;

        // Timestamp the last waypoint as "now"; earlier waypoints go back in time.
        // This keeps the most recent position live in Redis (within TTL window).
        OffsetDateTime base = OffsetDateTime.now(ZoneOffset.UTC)
                .minusSeconds((long) (count - 1) * intervalSecs);

        log.info("Test route: user={} role={} waypoints={} intervalSeconds={}",
                request.userId(), request.role(), count, intervalSecs);

        for (int i = 0; i < count; i++) {
            Waypoint wp = request.waypoints().get(i);
            locationService.handleLocationPost(new LocationRequest(
                    request.userId(),
                    request.role(),
                    wp.lat(),
                    wp.lng(),
                    base.plusSeconds((long) i * intervalSecs)
            ));
        }

        return Map.of("injected", count, "user_id", request.userId());
    }

    // -------------------------------------------------------------------------
    // POST /test/inject-regions
    // -------------------------------------------------------------------------

    private static final String[] ROLES = {"plumber", "mechanic", "teacher", "driver", "cruiser", "sport", "other"};
    private static final Random RNG = new Random();

    /**
     * Injects {@code count} fake users distributed round-robin across the given region IDs.
     * Each user gets a random position within the region's bounding box and a random role.
     * User IDs are stable per run: {@code inject_{regionId}_{index}}.
     */
    @PostMapping("/inject-regions")
    public Map<String, Object> injectRegions(@Valid @RequestBody InjectRegionsRequest request) {
        Map<String, Region> regionMap = Regions.ALL.stream()
                .filter(r -> request.regions().contains(r.id()))
                .collect(Collectors.toMap(Region::id, r -> r));

        List<String> unknown = request.regions().stream()
                .filter(id -> !regionMap.containsKey(id))
                .toList();
        if (!unknown.isEmpty()) {
            throw new IllegalArgumentException("Unknown region IDs: " + unknown);
        }

        Map<String, Integer> distribution = new LinkedHashMap<>();
        request.regions().forEach(id -> distribution.put(id, 0));

        for (int i = 0; i < request.count(); i++) {
            String regionId = request.regions().get(i % request.regions().size());
            Region region   = regionMap.get(regionId);

            double lat  = region.south() + RNG.nextDouble() * (region.north() - region.south());
            double lng  = region.west()  + RNG.nextDouble() * (region.east()  - region.west());
            String role = ROLES[RNG.nextInt(ROLES.length)];

            locationService.handleLocationPost(new LocationRequest(
                    "inject_" + regionId + "_" + i, role, lat, lng,
                    OffsetDateTime.now(ZoneOffset.UTC)
            ));
            distribution.merge(regionId, 1, Integer::sum);
        }

        log.info("Test inject-regions: total={} distribution={}", request.count(), distribution);
        return Map.of("injected", request.count(), "distribution", distribution);
    }

    // -------------------------------------------------------------------------
    // Inner request records
    // -------------------------------------------------------------------------

    record InjectRequest(
            @NotBlank @JsonProperty("user_id") String userId,
            @NotBlank @JsonProperty("role") String role,
            @NotNull @DecimalMin("-90.0")  @DecimalMax("90.0")   @JsonProperty("lat") Double lat,
            @NotNull @DecimalMin("-180.0") @DecimalMax("180.0")  @JsonProperty("lng") Double lng
    ) {}

    record Waypoint(
            @NotNull @DecimalMin("-90.0")  @DecimalMax("90.0")   @JsonProperty("lat") Double lat,
            @NotNull @DecimalMin("-180.0") @DecimalMax("180.0")  @JsonProperty("lng") Double lng
    ) {}

    record RouteRequest(
            @NotBlank @JsonProperty("user_id") String userId,
            @NotBlank @JsonProperty("role") String role,
            @NotEmpty @JsonProperty("waypoints") List<Waypoint> waypoints,
            @JsonProperty("interval_seconds") int intervalSeconds   // artificial seconds between waypoints; defaults to 300 if 0
    ) {}

    record InjectRegionsRequest(
            @Min(1) @Max(1000) @JsonProperty("count") int count,
            @NotEmpty                @JsonProperty("regions") List<String> regions
    ) {}
}
