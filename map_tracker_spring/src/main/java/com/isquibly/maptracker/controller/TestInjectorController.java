package com.isquibly.maptracker.controller;

import com.isquibly.maptracker.dto.LocationRequest;
import com.isquibly.maptracker.service.LocationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;

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
    // Inner request records
    // -------------------------------------------------------------------------

    record InjectRequest(
            @NotBlank String userId,
            @NotBlank String role,
            @NotNull @DecimalMin("-90.0")  @DecimalMax("90.0")   Double lat,
            @NotNull @DecimalMin("-180.0") @DecimalMax("180.0")  Double lng
    ) {}

    record Waypoint(
            @NotNull @DecimalMin("-90.0")  @DecimalMax("90.0")   Double lat,
            @NotNull @DecimalMin("-180.0") @DecimalMax("180.0")  Double lng
    ) {}

    record RouteRequest(
            @NotBlank String userId,
            @NotBlank String role,
            @NotEmpty List<Waypoint> waypoints,
            int intervalSeconds   // artificial seconds between waypoints; defaults to 300 if 0
    ) {}
}
