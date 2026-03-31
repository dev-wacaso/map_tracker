# Map Tracker — Architecture Design Doc

## Overview

A location tracking app where **transmitters** periodically post their position and **viewers** periodically pull a snapshot of nearby users. No real-time streaming. No WebSocket. A pull-based, pre-computed grid model optimized for low server load and minimal data transfer.

---

## Core Concept: Pre-Computed Grid Buckets

The world is divided into a **fixed, predefined H3 hexagonal grid** at two resolutions. The server maintains a bucket per grid cell, updated as transmitters post. Viewers request specific cells by ID — the server does pure key lookups, no spatial queries at request time.

All spatial computation (viewport → cell IDs) happens **client-side** using `dart_h3`. The server is geography-agnostic — it only knows cell IDs.

---

## Server Config Endpoint

Client fetches on startup (and periodically refreshes). All behavior-driving values live here so thresholds and resolutions are tunable server-side without a client update.

```
GET /config
```

```json
{
  "transmitter_interval_seconds": 300,
  "zoom_threshold_heatmap": 7,
  "zoom_threshold_detail": 11,
  "h3_resolution_heatmap": 5,
  "h3_resolution_detail": 8,
  "viewer_refresh_interval_default_seconds": 300
}
```

> **Note:** `zoom_threshold_heatmap` and `zoom_threshold_detail` are TBD and will require tuning. Additional app-wide config values can be added to this endpoint as the app grows.

---

## Three-Zone Zoom Model

Client checks current map zoom level before making any data requests:

```
Zoom < zoom_threshold_heatmap   →  empty map, no requests
Zoom threshold_heatmap–detail   →  heatmap mode  (coarse H3 grid)
Zoom > zoom_threshold_detail    →  detail mode   (fine H3 grid)
```

This prevents sending large payloads to zoomed-out users and avoids unnecessary server load.

### Zone Transition Hysteresis

To prevent rapid request thrashing when a user hovers at a threshold boundary, apply a small hysteresis buffer on the client:

- Switch **into** detail mode when zoom exceeds `zoom_threshold_detail`
- Switch **back** to heatmap only when zoom drops below `zoom_threshold_detail - 0.5`

Same principle applies at the heatmap/empty boundary.

---

## H3 Grid: Two Resolutions

H3 cells have a natural parent/child hierarchy — every fine cell has a deterministic parent at the coarse resolution. This is exploited so the two grids are structurally related.

| Mode | H3 Resolution | Approx Cell Size | Data Returned |
|---|---|---|---|
| Heatmap | 5 (from config) | ~250 km² | Count + role breakdown |
| Detail | 8 (from config) | ~0.7 km² | Full user list per cell |

Resolutions come from server config — client never hardcodes them.

---

## Bucket Structures

### Detail Bucket (per fine cell)

```json
{
  "cell": "8928308280fffff",
  "updated_at": "2026-03-25T14:05:00Z",
  "window_minutes": 5,
  "users": [
    {
      "user_id": "u_abc",
      "role": "plumber",
      "lat": 40.712,
      "lng": -74.006,
      "bearing": 247,
      "last_seen": "2026-03-25T13:58:22Z"
    }
  ]
}
```

### Heatmap Bucket (per coarse cell)

```json
{
  "cell": "8528308280fffff",
  "updated_at": "2026-03-25T14:05:00Z",
  "count": 47,
  "breakdown": {
    "plumber": 20,
    "mechanic": 15,
    "teacher": 12
  }
}
```

---

## API Endpoints

### 1. Config
```
GET /config
```
Returns server config (see above).

---

### 2. Cell Timestamps (lightweight staleness check)
```
POST /cells/timestamps
{ "cells": ["h3abc", "h3def", "h3ghi"] }
```
```json
{
  "h3abc": "2026-03-25T14:05:00Z",
  "h3def": "2026-03-25T13:58:00Z",
  "h3ghi": "2026-03-25T14:02:00Z"
}
```
Client compares these against its local cache timestamps and determines which cells need a full fetch. Tiny payload — one timestamp per cell.

---

### 3. Bucket Fetch
```
POST /buckets
{
  "cells": ["h3abc", "h3def"],
  "mode": "detail" | "heatmap"
}
```
Returns the current bucket for each requested cell. Server does pure key lookups — no spatial queries.

---

### 4. Transmitter Post
```
POST /location
{
  "user_id": "u_abc",
  "role": "plumber",
  "lat": 40.712,
  "lng": -74.006,
  "timestamp": "2026-03-25T14:05:00Z"
}
```
Server computes bearing from user's previous position and writes to storage. Client does not need to track or compute bearing.

---

## Transmitter Flow

1. Every `transmitter_interval_seconds`, POST current position to `/location`
2. Server:
   - Computes H3 fine cell from `(lat, lng)`
   - Computes bearing from previous stored position (null on first post)
   - Upserts user entry into that cell's detail bucket (Redis hash, per-member TTL ~10 min)
   - Updates heatmap count in parent coarse cell
3. Done — no fanout, no per-viewer work

---

## Viewer Flow

1. On startup: fetch `/config`, store locally
2. On each refresh cycle (timer = `viewer_refresh_interval_default_seconds`, user-adjustable):
   a. Check current zoom level against thresholds → determine mode (empty / heatmap / detail)
   b. If empty zone → do nothing
   c. Compute visible cell IDs from viewport bbox using `dart_h3` at appropriate resolution
   d. **Optional optimization:** POST `/cells/timestamps` for visible cells → compare to local cache → identify stale/missing cells
   e. POST `/buckets` for stale/missing cells only
   f. Merge response into local cache
   g. Re-render map layer
3. On viewport pan/zoom:
   - Recompute visible cells
   - Check local cache — request only cells not already cached (or stale by client's own reckoning)
   - **Client owns all staleness decisions** — server has no knowledge of client state

---

## Client Cache Structure

```
cache: {
  "h3abc::detail":  { received_at: DateTime, bucket: { users: [...] } },
  "h3abc::heatmap": { received_at: DateTime, bucket: { count: 47, breakdown: {...} } },
  ...
}
```

On zoom transition (heatmap → detail): client checks for `cell::detail` entries for newly visible fine cells. Requests any that are missing or older than `viewer_refresh_interval_default_seconds`.

Cache entries for cells no longer in the viewport are evicted locally.

---

## Storage Layer

### Redis (hot cache, primary read path)
- One hash per detail cell: `cell:detail:{h3_id}` → fields are `user_id`, values are JSON payloads
- Per-member TTL on hash entries (Redis 7.4+): auto-evicts stale users after ~10 min
- Heatmap counts derived from detail buckets on read (cached short-term, ~30-60s TTL)
- All viewer requests served from Redis — no DB hits on reads

### PostGIS (persistent store)
- All transmitter posts persisted for history, audit, and future features (replay, analytics)
- Used to rebuild Redis cache on server restart
- Enables future complex spatial queries if needed

---

## Flutter Client Stack

| Concern | Package |
|---|---|
| Map rendering | `flutter_map` |
| Heatmap layer | `flutter_map_heatmap` |
| H3 cell computation | `dart_h3` |
| HTTP | `dio` or `http` |
| Local cache | in-memory map + optional `hive` for persistence across sessions |

User type symbology (plumber / mechanic / teacher / etc.) is handled via custom `Marker` widgets — different icons per role with a small directional arrow overlay using the `bearing` value.

---

## Key Design Decisions (Summary)

| Decision | Choice | Rationale |
|---|---|---|
| Update model | Pull-based polling | 5-min transmit interval makes real-time unnecessary |
| Grid type | H3 hexagonal | Uniform cell geometry, natural parent/child hierarchy, built for this use case |
| Staleness ownership | Client | Server is stateless w.r.t. viewers; simpler, no per-client tracking |
| Zoom gating | Three zones (empty / heatmap / detail) | Prevents large data transfers to zoomed-out users |
| Thresholds/resolutions | Server config | Tunable without client update |
| Bearing computation | Server-side at write time | Client doesn't need to track user history |
| Real-time / WebSocket | None | Not required; pull model is sufficient |
| Server read path | Redis key lookup | No spatial queries at read time; pure key/value |
| Persistent store | PostGIS | History, rebuild, future spatial queries |
