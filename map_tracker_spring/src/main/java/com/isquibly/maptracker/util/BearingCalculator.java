package com.isquibly.maptracker.util;

public final class BearingCalculator {

    private BearingCalculator() {}

    /**
     * Returns the initial bearing (0–360°) from point 1 to point 2.
     */
    public static double calculate(double lat1, double lng1, double lat2, double lng2) {
        double lat1R = Math.toRadians(lat1);
        double lat2R = Math.toRadians(lat2);
        double dLng  = Math.toRadians(lng2 - lng1);
        double y = Math.sin(dLng) * Math.cos(lat2R);
        double x = Math.cos(lat1R) * Math.sin(lat2R)
                 - Math.sin(lat1R) * Math.cos(lat2R) * Math.cos(dLng);
        return (Math.toDegrees(Math.atan2(y, x)) + 360) % 360;
    }
}
