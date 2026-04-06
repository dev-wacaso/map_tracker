# Dynamic Configuration API

## Endpoints

### Public Configuration
- `GET /config` - Get current configuration (unchanged)

### Admin Configuration Management
- `GET /admin/config` - Get current configuration
- `PUT /admin/config` - Update entire configuration
- `PATCH /admin/config` - Update specific configuration parameters
- `POST /admin/config/reset` - Reset to default configuration

## Usage Examples

### Get Current Config
```bash
curl http://localhost:8000/config
curl http://localhost:8000/admin/config
```

### Update Full Config
```bash
curl -X PUT http://localhost:8000/admin/config \
  -H "Content-Type: application/json" \
  -d '{
    "transmitterIntervalSeconds": 120,
    "zoomThresholdHeatmap": 8.0,
    "zoomThresholdDetail": 12.0,
    "h3ResolutionHeatmap": 6,
    "h3ResolutionDetail": 9,
    "viewerRefreshIntervalDefaultSeconds": 180
  }'
```

### Update Partial Config
```bash
curl -X PATCH http://localhost:8000/admin/config \
  -d "transmitterIntervalSeconds=120&zoomThresholdHeatmap=8.0"
```

### Reset Config
```bash
curl -X POST http://localhost:8000/admin/config/reset \
  -H "Content-Type: application/json" \
  -d '{
    "transmitterIntervalSeconds": 300,
    "zoomThresholdHeatmap": 7.0,
    "zoomThresholdDetail": 11.0,
    "h3ResolutionHeatmap": 5,
    "h3ResolutionDetail": 8,
    "viewerRefreshIntervalDefaultSeconds": 300
  }'
```

## Implementation Details

- Configuration is stored in memory using `DynamicConfigService`
- Changes are immediate and persist until application restart
- `@RefreshScope` enables future integration with Spring Cloud Config
- All admin endpoints are currently unrestricted (add security later)
