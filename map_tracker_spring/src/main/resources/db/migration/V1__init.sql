CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE location_posts (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       VARCHAR(255)             NOT NULL,
    role          VARCHAR(100)             NOT NULL,
    location      GEOMETRY(Point, 4326)    NOT NULL,
    bearing       DOUBLE PRECISION,
    timestamp     TIMESTAMPTZ              NOT NULL,
    h3_detail_cell   VARCHAR(20)           NOT NULL,
    h3_heatmap_cell  VARCHAR(20)           NOT NULL
);

CREATE INDEX idx_lp_timestamp     ON location_posts (timestamp);
CREATE INDEX idx_lp_h3_detail     ON location_posts (h3_detail_cell);
CREATE INDEX idx_lp_h3_heatmap    ON location_posts (h3_heatmap_cell);
CREATE INDEX idx_lp_user_id       ON location_posts (user_id);
