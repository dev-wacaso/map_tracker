package com.isquibly.maptracker.region;

import java.util.List;

/**
 * Master region list — must stay in sync with the Flutter client's regions.dart.
 * Bounding box format per entry: north, west, south, east.
 */
public final class Regions {

    private Regions() {}

    public static final List<Region> ALL = List.of(

        // United States
        new Region("01", "US I",     49.3007, -127.5357,  41.5043, -114.7917),
        new Region("02", "US II",    49.3007, -114.7916,  41.5043, -101.3831),
        new Region("03", "US III",   49.3007, -101.3832,  41.5043,  -79.5864),
        new Region("04", "US IV",    49.3007,  -79.5864,  41.5043,  -51.2856),
        new Region("05", "US V",     41.5042, -127.5357,  31.9303, -113.5611),
        new Region("06", "US VI",    41.5042, -113.5610,  31.9303, -101.9595),
        new Region("07", "US VII",   41.5042, -101.9594,  36.2235,  -88.9517),
        new Region("08", "US VIII",  41.5042,  -88.9516,  36.2235,  -80.4263),
        new Region("09", "US IX",    41.5042,  -80.4262,  36.2235,  -67.0669),
        new Region("10", "US X",     36.2234, -101.9594,  26.0929,  -93.2584),
        new Region("11", "US XI",    36.2234,  -93.2583,  26.0929,  -85.3482),
        new Region("12", "US XII",   36.2234,  -85.3482,  31.2567,  -74.7470),
        new Region("13", "US XIII",  31.2566,  -85.3482,  24.0231,  -74.7470),

        // Territories
        new Region("14", "Alaska",   72.3177, -169.1874,  54.7284, -140.5351),
        new Region("15", "Hawaii",   23.0764, -162.3248,  18.5595, -153.5796),

        // Canada
        new Region("16", "Canada I",    72.3177, -140.5350,  49.3008, -119.6171),
        new Region("17", "Canada II",   72.3177, -119.6170,  49.3008, -110.1732),
        new Region("18", "Canada III",  72.3177, -110.1731,  49.3008, -101.3833),
        new Region("19", "Canada IV",   72.3177, -101.3832,  49.3008,  -91.5395),
        new Region("20", "Canada V",    72.3177,  -91.5394,  49.3008,  -79.5864),
        new Region("21", "Canada VI",   72.3177,  -79.5864,  49.3008,  -51.2856),

        // Mexico
        new Region("22", "Mexico I",   31.9302, -118.1314,  26.0929, -101.9595),
        new Region("23", "Mexico II",  26.0928, -118.1314,  13.0438,  -91.8522),

        // Central America
        new Region("24", "C America I",   24.0230,  -91.8521,  13.0438,  -49.0494),
        new Region("25", "C America II",  13.0437,  -91.8521,   1.6440,  -72.1647),

        // South America
        new Region("26", "S America I",     -8.1803,  -57.2457, -18.9959,  -31.4059),
        new Region("27", "S America II",    13.0437,  -72.1646,   1.6440,  -49.0494),
        new Region("28", "S America III",    1.6439,  -83.9755,  -3.7944,  -69.7372),
        new Region("29", "S America IV",    -3.7945,  -83.9755, -18.9960,  -69.7372),
        new Region("30", "S America V",    -51.4652,  -78.3505, -55.7465,  -57.2458),
        new Region("31", "S America VI",    -8.1803,  -69.7371, -18.9960,  -57.2458),
        new Region("32", "S America VII",  -18.9960,  -78.3395, -51.4652,  -66.3864),
        new Region("33", "S America VIII",   1.6439,  -69.7371,  -8.1802,  -31.4059),
        new Region("34", "S America IX",   -18.9960,  -66.3863, -51.4651,  -57.2458),
        new Region("35", "S America X",    -18.9960,  -57.2457, -35.4171,  -31.4059),

        // Asia
        new Region("36", "Asia I",   54.4339,  86.8172,  29.6341, 147.5801),
        new Region("37", "Asia II",  29.6340,  86.8172, -10.1166, 163.9277),

        // Europe
        new Region("38", "Europe I",   59.5027, -12.3007,  37.1491,   5.6289),
        new Region("39", "Europe II",  59.5027,   5.6290,  37.1491,  45.8828),

        // Oceania
        new Region("40", "Australia",  -10.1167, 111.3613, -46.1773, 178.3340),

        // Northern Europe / Scandinavia
        new Region("41", "Norway/Sweden",  71.5052,  -0.3476,  59.5028,  42.1914),

        // Central/South Asia
        new Region("42", "Kazakhstan",  59.5027,  45.8829,  37.1491,  86.8171),
        new Region("43", "India",       37.1490,  45.8829,  11.0739,  86.8171),
        new Region("44", "India II",    11.0738,  51.3321,   5.0000,  86.8171),

        // Africa
        new Region("45", "Southern Africa",  11.0740,   8.3976, -35.5114,  51.3320),
        new Region("46", "NE Africa",        37.1490,   8.3976,  11.0741,  45.8828),
        new Region("47", "W Africa",         37.1490, -20.0790,   3.4077,   8.3975),

        // Russia
        new Region("48", "Russia I",    81.3254,  42.1915,  59.5028,  86.8171),
        new Region("49", "Russia III",  76.7865, 147.5802,  29.6341, 179.0000),
        new Region("50", "Russia II",   81.3254,  86.8172,  54.4340, 147.5801)
    );
}
