package com.isquibly.maptracker.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.locationtech.jts.geom.Point;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "location_posts")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LocationPost {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String userId;

    @Column(nullable = false)
    private String role;

    @Column(nullable = false, columnDefinition = "GEOMETRY(Point, 4326)")
    private Point location;

    private Double bearing;

    @Column(nullable = false)
    private OffsetDateTime timestamp;

    @Column(nullable = false, length = 20)
    private String h3DetailCell;

    @Column(nullable = false, length = 20)
    private String h3HeatmapCell;
}
