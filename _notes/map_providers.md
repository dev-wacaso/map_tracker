# Map Provider Comparison

Relevant to the dual-map feature (Google Maps default + flutter_map alternative).
Last reviewed: March 2026.

---

## Overview

| Provider | Flutter Plugin | Billing Model | Free Tier | Commercial Free Use |
|---|---|---|---|---|
| Google Maps | `google_maps_flutter` (official) | Per-SKU events or subscription | Maps SDK mobile: **unlimited** | Yes |
| Mapbox | `mapbox_maps_flutter` (official) | Per MAU (mobile) | 25,000 MAU/month | Yes |
| Stadia Maps | `flutter_map` (OSS) | Per credit/request | 200K credits/month | **No** |
| MapTiler | `flutter_map` (OSS) | Per session + request | 5K sessions / 100K req/month | **No** |
| Thunderforest | `flutter_map` (OSS) | Per tile request | 150K tiles/month | Unclear — testing/experimentation only |

---

## Google Maps Platform

**Plugin:** [`google_maps_flutter`](https://pub.dev/packages/google_maps_flutter) — officially maintained by Google
**Pricing:** https://mapsplatform.google.com/pricing/
**Platforms:** Android, iOS, Web (partial — no desktop)

### Pricing (post-March 2025 restructure)

Google eliminated the $200/month rolling credit in March 2025 and replaced it with per-SKU free thresholds.

**Pay-as-you-go free thresholds (per SKU per month):**

| SKU Tier | Free Events/month |
|---|---|
| Essentials (Dynamic Maps, Geocoding, etc.) | 10,000 |
| Pro (Street View, Advanced Routing) | 5,000 |
| Enterprise (3D Tiles, Fleet Routing) | 1,000 |

**Key exception for this project:**
The **Maps SDK for Android and Maps SDK for iOS** (what `google_maps_flutter` uses) are billed as **unlimited with no per-load charge**. A tracker app that only renders a map with custom markers pays nothing for the map itself on mobile. You only pay if you also use Places, Geocoding, Routes, or Street View APIs.

**Subscription tiers (alternative to pay-as-you-go):**

| Tier | Monthly Cost | Included |
|---|---|---|
| Starter | $100/month | 50,000 calls (Dynamic Maps + Geocoding) |
| Essentials | $275/month | 100,000 calls (all core APIs) |
| Pro | $1,200/month | 250,000 calls (all APIs inc. Street View, Route Optimization) |
| Enterprise | Custom | Custom |

**Web:** Uses Maps JavaScript API, billed as Dynamic Maps at $7.00/1,000 requests after 10K free/month.

### Integration

Straightforward. API key from Google Cloud Console. Official codelabs and extensive documentation. Billing account required even for free usage.

### Map Data & Updates

Proprietary Google dataset — not OpenStreetMap. Updated continuously by Google. Includes Google-exclusive data (business hours, indoor maps, traffic, etc.).

### Add-ons / Ecosystem

- Routes API (Directions, Distance Matrix, Roads)
- Places API (Autocomplete, Place Details, Nearby Search)
- Address Validation API
- Air Quality, Solar, Pollen APIs (Pro+)
- Navigation SDK for Flutter: [`google_navigation_flutter`](https://pub.dev/packages/google_navigation_flutter) (beta, separate billing)
- Aerial View, Photorealistic 3D Tiles (Enterprise)

### Limitations

- Web support in `google_maps_flutter` is partial and lags behind the mobile SDK
- No desktop support
- Known performance issue: resizing the map widget causes whole-app lag (workaround via map padding API)
- Vendor lock-in — all map data, styling, and APIs are Google-controlled

---

## Mapbox

**Plugin:** [`mapbox_maps_flutter`](https://pub.dev/packages/mapbox_maps_flutter) — officially maintained by Mapbox (v11.x)
**Pricing:** https://www.mapbox.com/pricing
**Platforms:** Android, iOS only — **no web, no desktop**

### Pricing

Mobile apps are billed by **Monthly Active Users (MAUs)** — a MAU is counted the first time a unique user triggers map functionality within a 30-day window.

| MAU Range | Free / Paid |
|---|---|
| 0 – 25,000 | Free |
| 25,001 – 125,000 | ~$4.00 per 1,000 MAUs |
| 125,001 – 250,000 | Reduced rate (volume discount) |
| 250,000+ | Contact sales |

Additional APIs (Geocoding, Navigation, Routing) are billed separately on top of MAU charges.

### Integration

Moderate complexity. Requires a Mapbox access token (public token for read operations). The Flutter SDK is well-documented and actively maintained by Mapbox directly. Mapbox Studio is a powerful companion for visual style customization.

### Map Data & Updates

Proprietary dataset derived from OpenStreetMap plus Mapbox's own data. OSM edits typically appear within days to weeks. Not as fast as Thunderforest for OSM propagation, but faster than MapTiler's planet updates.

### Add-ons / Ecosystem

- **Offline maps** — best-in-class; StylePacks + TileRegions via `OfflineManager` (no extra charge per se, but downloads count against tile quotas)
- Navigation SDK (turn-by-turn, billed separately by MAU)
- Search SDK (autocomplete, reverse geocoding)
- Vision SDK (computer vision, AR overlays)
- Custom tilesets and data uploads via Mapbox Studio

### Limitations

- **No web or desktop Flutter support** — Android/iOS only
- MAU billing can be unpredictable if your app has viral growth
- Reinstalls count as new MAUs
- More expensive than Stadia/MapTiler at moderate scale

---

## Stadia Maps

**Plugin:** [`flutter_map`](https://pub.dev/packages/flutter_map) (open source) with Stadia tile URLs
**Pricing:** https://stadiamaps.com/pricing/
**Platforms:** All platforms that `flutter_map` supports (Android, iOS, Web, Desktop)
**Flutter docs:** https://docs.stadiamaps.com/native-multiplatform/flutter-map/

### Pricing

Stadia uses a **credit-based** model where different request types cost different amounts of credits.

| Tier | Monthly Cost | Credits/month | Commercial Use |
|---|---|---|---|
| Free | $0 | 200,000 | **No** |
| Starter | $20/month | 1,000,000 | Yes |
| Standard | $80/month | 7,500,000 | Yes |
| Professional | $250/month | 25,000,000 | Yes |
| Enterprise | Custom | Custom | Yes |

**Credit costs per request type:**

| Request | Credits |
|---|---|
| Map tile (vector or raster) | 1 |
| Satellite tile | 4 |
| Static map (cacheable) | 2,000 |
| Static map (non-cacheable) | 20 |
| Routing / geocoding | 5–40 (varies) |

**Developer-friendly overage policy:** Stadia does not silently bill overages. When you approach your limit they notify you; overage billing is opt-in.

**14-day free trial** of full feature set, no credit card required.

### Integration

Very easy with `flutter_map`. Insert the Stadia tile URL template with your API key into a standard `TileLayer`. No SDK, no complex initialization.

```dart
TileLayer(
  urlTemplate: 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png?api_key={apiKey}',
  additionalOptions: {'apiKey': 'YOUR_KEY'},
)
```

### Map Data & Updates

OpenStreetMap-based. Typical update cadence is weekly to bi-weekly. Not the fastest for OSM propagation.

### Add-ons

- Routing APIs (Starter+)
- Geocoding and search (Starter+)
- Satellite basemaps (Standard+)
- On-premises hosting (Enterprise)
- Available styles: Alidade Smooth, Alidade Smooth Dark, OSM Bright, Outdoors, Stamen Toner, Stamen Watercolor, and others

### Limitations

- Free tier is non-commercial
- Fixed styles — no custom style editor (unlike Mapbox Studio or MapTiler Cloud)
- Vector tile support requires additional setup with `flutter_map_vector_tile` or `maplibre_gl`

---

## MapTiler

**Plugin:** [`flutter_map`](https://pub.dev/packages/flutter_map) (open source) with MapTiler tile URLs
**Pricing:** https://www.maptiler.com/cloud/pricing/
**Platforms:** All platforms that `flutter_map` supports
**Docs:** https://docs.maptiler.com

### Pricing

MapTiler bills on both **sessions** (unique user-map interactions, time-windowed) and **requests** (individual tile/API calls).

| Tier | Monthly Cost | Sessions/month | Requests/month | Commercial Use |
|---|---|---|---|---|
| Free | $0 | 5,000 | 100,000 | **No** (branding required) |
| Flex | $25/month | 25,000 | 500,000 | Yes |
| Unlimited | $295/month | 300,000 | 5,000,000 | Yes |
| Custom | Prepaid | Soft limits | Custom | Yes |

**Overage rates (Flex/Unlimited):**
- Extra sessions: $2.00/1,000 (Flex), $1.50/1,000 (Unlimited)
- Extra requests: $0.10/1,000 (Flex), $0.08/1,000 (Unlimited)

### Integration

Easy with `flutter_map`. API key from MapTiler Cloud dashboard. Supports both raster and vector tiles. Custom styles created via MapTiler Cloud editor (similar to Mapbox Studio but simpler).

### Map Data & Updates

OpenStreetMap-based. **Weekly updates** for vector tiles; full Planet tileset updated approximately every 2–3 weeks (includes QA process). Among the more transparent providers regarding update cadence.

### Add-ons

- Custom map style editor (MapTiler Cloud)
- Geocoding API (included in paid plans)
- Weather map layers
- Satellite imagery (all tiers)
- Hillshading and terrain (Terrain-RGB tiles)
- Team collaboration (Unlimited+)
- **MapTiler Server** — self-hosted option (separate product, one-time license)
- 99.9% SLA on Unlimited+

### Limitations

- Free tier is non-commercial and requires MapTiler branding
- Session-based billing is harder to predict than pure tile-request billing
- 5,000 session free limit is very restrictive — effectively prototyping only

---

## Thunderforest

**Plugin:** [`flutter_map`](https://pub.dev/packages/flutter_map) (open source) with Thunderforest tile URLs
**Pricing:** https://www.thunderforest.com/pricing/
**Flutter tutorial:** https://www.thunderforest.com/tutorials/flutter/
**Platforms:** All platforms that `flutter_map` supports

### Pricing

| Tier | Monthly Cost | Tile Requests/month |
|---|---|---|
| Hobby Project | Free | 150,000 |
| Solo Developer | $125/month | 1,500,000 |
| Small Business | $255/month | 15,000,000 |
| Large Business | $525/month | 150,000,000 |
| Enterprise | Custom | Custom |

**No surge charges on any tier.** Thunderforest notifies you instead of silently billing overages.
**Bulk tile downloading** only permitted on Small Business ($255/month) and above.

### Integration

Very easy. Thunderforest provides a dedicated Flutter tutorial. Standard `flutter_map` `TileLayer` with API key in the URL template.

### Map Data & Updates

OpenStreetMap-based. **Among the fastest OSM propagation** of all providers — processes new OSM edits within a few hours. OpenCycleMap style specifically can update every few hours from OSM edits.

### Map Styles

Thunderforest's main differentiator is specialty styles:
- OpenCycleMap (cycling routes and elevation)
- Transport (transit-focused)
- Landscape
- Outdoors
- Pioneer (retro/classic cartographic)
- Mobile Atlas
- Neighbourhood
- Atlas

### Limitations

- **Raster tiles only** — no vector tile support
- **No routing or geocoding APIs** — tiles only
- Paid entry at $125/month is high relative to Stadia ($20) and MapTiler ($25)
- Free tier commercial use policy is ambiguous — intended for testing/experimentation
- Best suited for apps that specifically need one of their specialty styles

---

## Key Takeaways for Map Tracker

**Google Maps is uniquely cost-effective for a native mobile tracker app.** The Maps SDK for Android/iOS has no per-load charge. A service-worker tracker that only renders a map with custom markers and H3 overlays pays nothing on mobile. Costs only appear if you add Places, Geocoding, or Routing API calls.

**Mapbox is the best full-featured alternative** if offline maps or deep style customization are needed. The 25,000 MAU free tier is generous for early-stage apps. No web/desktop support is a real constraint.

**Stadia is the best flutter_map tile provider for production commercial use** at small-to-medium scale. $20/month entry, all platforms, opt-in overage policy, and a 14-day full trial. The lack of custom style editing is the main tradeoff.

**MapTiler is best for style-customization-first workflows** (they have the most accessible style editor outside of Mapbox). Session-based billing can be unpredictable at scale.

**Thunderforest is a niche choice** — use it only if you specifically need cycling, transit, or outdoor-specialty basemaps. Raster-only, no routing, expensive paid entry.

---

## Relevant Links

| Resource | URL |
|---|---|
| Google Maps Platform pricing | https://mapsplatform.google.com/pricing/ |
| Google March 2025 pricing change details | https://developers.google.com/maps/billing-and-pricing/march-2025 |
| Maps SDK Android billing docs | https://developers.google.com/maps/documentation/android-sdk/usage-and-billing |
| google_maps_flutter (pub.dev) | https://pub.dev/packages/google_maps_flutter |
| google_navigation_flutter (pub.dev) | https://pub.dev/packages/google_navigation_flutter |
| Mapbox pricing | https://www.mapbox.com/pricing |
| Mapbox pricing docs | https://docs.mapbox.com/accounts/guides/pricing/ |
| mapbox_maps_flutter (pub.dev) | https://pub.dev/packages/mapbox_maps_flutter |
| Stadia Maps pricing | https://stadiamaps.com/pricing/ |
| Stadia flutter_map quickstart | https://docs.stadiamaps.com/native-multiplatform/flutter-map/ |
| MapTiler pricing | https://www.maptiler.com/cloud/pricing/ |
| MapTiler docs | https://docs.maptiler.com |
| Thunderforest pricing | https://www.thunderforest.com/pricing/ |
| Thunderforest Flutter tutorial | https://www.thunderforest.com/tutorials/flutter/ |
| flutter_map (pub.dev) | https://pub.dev/packages/flutter_map |
