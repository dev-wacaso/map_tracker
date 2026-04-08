package com.isquibly.maptracker.region;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

/**
 * Periodically removes expired riders from every region bucket.
 *
 * Runs on a fixed delay (not rate) so back-pressure from a slow Redis doesn't
 * cause overlapping runs. Interval is controlled by app.config.pruner-interval-seconds.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RegionPrunerService {

    private final RegionRedisStore regionRedisStore;

    @Scheduled(fixedDelayString = "#{${app.config.pruner-interval-seconds} * 1000}")
    public void pruneAllRegions() {
        log.info("//-------------- Pruning regions -----------------//");
        int totalRemoved = 0;
        for (Region region : Regions.ALL) {
            int removed = regionRedisStore.pruneExpired(region.id());
            if (removed > 0) {
                log.debug("Pruner: removed {} expired rider(s) from region {} ({})", removed, region.id(), region.name());
                totalRemoved += removed;
            }
        }
        if (totalRemoved > 0) {
            log.info("//-------------- Pruned {} expired rider(s) total -----------------//", totalRemoved);
        } else {
            log.info("//-------------- Pruned 0 -----------------//");
        }
    }
}
