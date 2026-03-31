package com.isquibly.maptracker.service;

import com.isquibly.maptracker.dto.UserEntry;
import com.isquibly.maptracker.entity.LocationPost;
import com.isquibly.maptracker.redis.RedisLocationStore;
import com.isquibly.maptracker.repository.LocationPostRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class CacheRebuildService {

    private final LocationPostRepository repository;
    private final RedisLocationStore redisStore;

    @EventListener(ApplicationReadyEvent.class)
    public void rebuildCacheOnStartup() {
        OffsetDateTime cutoff = OffsetDateTime.now(ZoneOffset.UTC).minusSeconds(600);
        List<LocationPost> recent = repository.findByTimestampAfter(cutoff);

        if (recent.isEmpty()) {
            log.info("Cache rebuild: no recent posts found, Redis already empty.");
            return;
        }

        log.info("Cache rebuild: replaying {} recent location posts into Redis.", recent.size());
        for (LocationPost post : recent) {
            UserEntry entry = new UserEntry(
                    post.getUserId(), post.getRole(),
                    post.getLocation().getY(), post.getLocation().getX(),
                    post.getBearing(), post.getTimestamp()
            );
            redisStore.upsertUserForRebuild(post.getH3DetailCell(), post.getH3HeatmapCell(),
                    entry, post.getTimestamp());
        }
        log.info("Cache rebuild complete.");
    }
}
