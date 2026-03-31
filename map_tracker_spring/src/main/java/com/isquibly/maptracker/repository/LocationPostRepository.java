package com.isquibly.maptracker.repository;

import com.isquibly.maptracker.entity.LocationPost;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public interface LocationPostRepository extends JpaRepository<LocationPost, UUID> {

    List<LocationPost> findByTimestampAfter(OffsetDateTime cutoff);

    List<LocationPost> findTop1ByUserIdOrderByTimestampDesc(String userId);
}
