# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Map Tracker** is a dual-platform location tracking system for service workers (plumbers, mechanics, etc.). It uses a **pull-based, pre-computed H3 hexagonal grid model** — no WebSockets, no real-time streaming. Transmitters post positions every 5 minutes; viewers poll for snapshots.

Both projects are currently in early scaffolding state. The architecture is fully designed in `_notes/architecture.md` — read it before implementing anything.

---

## Environment

- User develops on **Windows**; Claude Code runs in **WSL**
- **Flutter commands must be run manually by the user in Windows** — do not run them from WSL. Present commands for the user to execute.
- Spring Boot / Gradle and Docker run in WSL
- Docker Engine runs in WSL to replicate the GCP environment for server-side components

## Commands

### Flutter Frontend — run manually in Windows (`map_tracker_flutter/`)
```bash
flutter pub get                            # Install dependencies
flutter run                                # Run app (select target interactively)
flutter test                               # Run all tests
flutter test test/widget_test.dart         # Run a single test file
flutter analyze                            # Static analysis / lint
dart format lib/                           # Format code
flutter build apk                          # Build Android (or: ios, web, windows, linux, macos)
flutter clean                              # Clean build artifacts
```

### Spring Boot Backend — run in WSL (`map_tracker_spring/`)
```bash
./gradlew build          # Build
./gradlew test           # Run tests (JUnit 5)
./gradlew bootRun        # Run with hot reload
./gradlew clean          # Clean build artifacts
docker-compose up        # Start services (PostgreSQL, Redis) via Docker in WSL
```

---

## Architecture

### System Design

Users are either **transmitters** (post GPS location every ~5 min via `POST /location`) or **viewers** (poll for map data via `POST /buckets`). The server never pushes data.

The world is divided into a fixed H3 hexagonal grid at two resolutions (both from `GET /config`, never hardcoded):
- **Heatmap resolution** (default H3 level 5, ~250 km²/cell): aggregate count + role breakdown
- **Detail resolution** (default H3 level 8, ~0.7 km²/cell): full user list with lat/lng/bearing/role

### Three-Zone Zoom Model (client-controlled)

```
Zoom < zoom_threshold_heatmap   →  no requests at all
zoom_threshold_heatmap to detail →  heatmap mode (coarse grid)
Zoom > zoom_threshold_detail    →  detail mode (fine grid)
```

Apply 0.5-level hysteresis on downward transitions to prevent request thrashing at boundaries.

### Viewer Data Flow

1. Fetch `/config` on startup (stores thresholds, resolutions, intervals)
2. On each refresh: determine zoom zone → compute visible H3 cell IDs client-side (`dart_h3`) → `POST /cells/timestamps` to identify stale cells → `POST /buckets` for stale cells only → merge into local cache → re-render
3. Client cache key format: `"{h3_id}::{mode}"` → `{ received_at, bucket }`
4. Server is stateless w.r.t. viewers — client owns all staleness decisions

### Transmitter Data Flow

`POST /location` → server computes H3 cell + bearing from previous position → upserts into Redis hash (`cell:detail:{h3_id}`, per-member TTL ~10 min) → updates heatmap count in parent coarse cell → persists to PostGIS

### Storage

- **Redis 7.4+**: Primary read path. One hash per detail cell; per-member TTLs auto-evict stale users. Heatmap counts derived on read with short TTL (~30–60s). All viewer requests served from Redis only.
- **PostGIS**: Write path for transmitters. Used for history, audit, and rebuilding Redis on restart.

### API Endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/config` | GET | Server-configurable thresholds, resolutions, intervals |
| `/location` | POST | Transmitter posts `{user_id, role, lat, lng, timestamp}` |
| `/cells/timestamps` | POST | Lightweight staleness check: `{cells:[...]}` → `{h3id: timestamp}` |
| `/buckets` | POST | Fetch bucket data: `{cells:[...], mode:"detail"\|"heatmap"}` |

### Flutter Client Stack (planned, add to `pubspec.yaml`)

| Concern | Package |
|---|---|
| State management | `riverpod` (use `flutter_riverpod`; **do not use** the code-generation annotations from `riverpod_annotation`/`riverpod_generator`) |
| Map rendering | `flutter_map` |
| Heatmap overlay | `flutter_map_heatmap` |
| H3 grid computation | `dart_h3` |
| HTTP | `dio` or `http` |
| Local cache persistence | `hive` (optional) |

Prefer well-established packages over hand-rolled solutions to minimize generated code. Role markers use custom `Marker` widgets with different icons per role and a directional arrow overlay derived from the `bearing` field.

### Backend Dependencies to Add (`build.gradle`)

Redis client (e.g., `spring-boot-starter-data-redis`) and PostGIS support (e.g., Hibernate Spatial or `postgis-jdbc`) are not yet added to `build.gradle`.
