import '../models/region.dart';
import '../models/map_bounds.dart';

// Bounding box format: north, west, south, east
const List<Region> kRegions = [

  // United States
  Region(id: '01', name: 'US I',     north:  49.3007, west: -127.5357, south:  41.5043, east: -114.7917),
  Region(id: '02', name: 'US II',    north:  49.3007, west: -114.7916, south:  41.5043, east: -101.3831),
  Region(id: '03', name: 'US III',   north:  49.3007, west: -101.3832, south:  41.5043, east:  -79.5864),
  Region(id: '04', name: 'US IV',    north:  49.3007, west:  -79.5864, south:  41.5043, east:  -51.2856),
  Region(id: '05', name: 'US V',     north:  41.5042, west: -127.5357, south:  31.9303, east: -113.5611),
  Region(id: '06', name: 'US VI',    north:  41.5042, west: -113.5610, south:  31.9303, east: -101.9595),
  Region(id: '07', name: 'US VII',   north:  41.5042, west: -101.9594, south:  36.2235, east:  -88.9517),
  Region(id: '08', name: 'US VIII',  north:  41.5042, west:  -88.9516, south:  36.2235, east:  -80.4263),
  Region(id: '09', name: 'US IX',    north:  41.5042, west:  -80.4262, south:  36.2235, east:  -67.0669),
  Region(id: '10', name: 'US X',     north:  36.2234, west: -101.9594, south:  26.0929, east:  -93.2584),
  Region(id: '11', name: 'US XI',    north:  36.2234, west:  -93.2583, south:  26.0929, east:  -85.3482),
  Region(id: '12', name: 'US XII',   north:  36.2234, west:  -85.3482, south:  31.2567, east:  -74.7470),
  Region(id: '13', name: 'US XIII',  north:  31.2566, west:  -85.3482, south:  24.0231, east:  -74.7470),

  // Territories
  Region(id: '14', name: 'Alaska',   north:  72.3177, west: -169.1874, south:  54.7284, east: -140.5351),
  Region(id: '15', name: 'Hawaii',   north:  23.0764, west: -162.3248, south:  18.5595, east: -153.5796),

  // Canada
  Region(id: '16', name: 'Canada I',   north:  72.3177, west: -140.5350, south:  49.3008, east: -119.6171),
  Region(id: '17', name: 'Canada II',  north:  72.3177, west: -119.6170, south:  49.3008, east: -110.1732),
  Region(id: '18', name: 'Canada III', north:  72.3177, west: -110.1731, south:  49.3008, east: -101.3833),
  Region(id: '19', name: 'Canada IV',  north:  72.3177, west: -101.3832, south:  49.3008, east:  -91.5395),
  Region(id: '20', name: 'Canada V',   north:  72.3177, west:  -91.5394, south:  49.3008, east:  -79.5864),
  Region(id: '21', name: 'Canada VI',  north:  72.3177, west:  -79.5864, south:  49.3008, east:  -51.2856),

  // Mexico
  Region(id: '22', name: 'Mexico I',  north:  31.9302, west: -118.1314, south:  26.0929, east: -101.9595),
  Region(id: '23', name: 'Mexico II', north:  26.0928, west: -118.1314, south:  13.0438, east:  -91.8522),

  // Central America
  Region(id: '24', name: 'C America I',  north:  24.0230, west: -91.8521, south:  13.0438, east: -49.0494),
  Region(id: '25', name: 'C America II', north:  13.0437, west: -91.8521, south:   1.6440, east: -72.1647),

  // South America
  Region(id: '26', name: 'S America I',    north:  -8.1803, west: -57.2457, south: -18.9959, east: -31.4059),
  Region(id: '27', name: 'S America II',   north:  13.0437, west: -72.1646, south:   1.6440, east: -49.0494),
  Region(id: '28', name: 'S America III',  north:   1.6439, west: -83.9755, south:  -3.7944, east: -69.7372),
  Region(id: '29', name: 'S America IV',   north:  -3.7945, west: -83.9755, south: -18.9960, east: -69.7372),
  Region(id: '30', name: 'S America V',    north: -51.4652, west: -78.3505, south: -55.7465, east: -57.2458),
  Region(id: '31', name: 'S America VI',   north:  -8.1803, west: -69.7371, south: -18.9960, east: -57.2458),
  Region(id: '32', name: 'S America VII',  north: -18.9960, west: -78.3395, south: -51.4652, east: -66.3864),
  Region(id: '33', name: 'S America VIII', north:   1.6439, west: -69.7371, south:  -8.1802, east: -31.4059),
  Region(id: '34', name: 'S America IX',   north: -18.9960, west: -66.3863, south: -51.4651, east: -57.2458),
  Region(id: '35', name: 'S America X',    north: -18.9960, west: -57.2457, south: -35.4171, east: -31.4059),

  // Asia
  Region(id: '36', name: 'Asia I',  north:  54.4339, west:  86.8172, south:  29.6341, east: 147.5801),
  Region(id: '37', name: 'Asia II', north:  29.6340, west:  86.8172, south: -10.1166, east: 163.9277),

  // Europe
  Region(id: '38', name: 'Europe I',  north:  59.5027, west: -12.3007, south:  37.1491, east:   5.6289),
  Region(id: '39', name: 'Europe II', north:  59.5027, west:   5.6290, south:  37.1491, east:  45.8828),

  // Oceania
  Region(id: '40', name: 'Australia', north: -10.1167, west: 111.3613, south: -46.1773, east: 178.3340),

  // Northern Europe / Scandinavia
  Region(id: '41', name: 'Norway/Sweden', north:  71.5052, west:  -0.3476, south:  59.5028, east:  42.1914),

  // Central/South Asia
  Region(id: '42', name: 'Kazakhstan', north:  59.5027, west:  45.8829, south:  37.1491, east:  86.8171),
  Region(id: '43', name: 'India',      north:  37.1490, west:  45.8829, south:  11.0739, east:  86.8171),
  Region(id: '44', name: 'India II',   north:  11.0738, west:  51.3321, south:   5.0000, east:  86.8171),

  // Africa
  Region(id: '45', name: 'Southern Africa', north:  11.0740, west:   8.3976, south: -35.5114, east:  51.3320),
  Region(id: '46', name: 'NE Africa',       north:  37.1490, west:   8.3976, south:  11.0741, east:  45.8828),
  Region(id: '47', name: 'W Africa',        north:  37.1490, west: -20.0790, south:   3.4077, east:   8.3975),

  // Russia
  Region(id: '48', name: 'Russia I',   north:  81.3254, west:  42.1915, south:  59.5028, east:  86.8171),
  Region(id: '49', name: 'Russia III', north:  76.7865, west: 147.5802, south:  29.6341, east: 179.0000),
  Region(id: '50', name: 'Russia II',  north:  81.3254, west:  86.8172, south:  54.4340, east: 147.5801),
];

/// Returns all regions that intersect the given viewport.
List<Region> regionsForViewport(MapBounds bounds) =>
    kRegions.where((r) => r.intersects(bounds)).toList();
