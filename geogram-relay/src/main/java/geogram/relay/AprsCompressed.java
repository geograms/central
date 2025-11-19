/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

/**
 * APRS Compressed Position Encoding (Base91)
 *
 * Encodes/decodes GPS coordinates using APRS compressed format
 * Provides ~0.3m precision for latitude and ~0.6m for longitude
 *
 * @author brito
 */
public class AprsCompressed {

    private static final int BASE = 91;
    private static final int OFFSET = 33; // ASCII '!'
    private static final int CODE_LEN = 4;

    // Scaling constants for APRS compression
    private static final double LAT_SCALE = 380_926.0;
    private static final double LON_SCALE = 190_463.0;
    private static final long MAX_VAL = 68719476735L; // 91^4 - 1

    /**
     * Encode latitude in APRS compressed format (4 Base91 characters)
     */
    public static String encodeLat(double latDeg) {
        latDeg = clampLat(latDeg);
        long y = (long) Math.floor(LAT_SCALE * (90.0 - latDeg));
        if (y < 0) y = 0;
        if (y > MAX_VAL) y = MAX_VAL;
        return toBase91(y, CODE_LEN);
    }

    /**
     * Encode longitude in APRS compressed format (4 Base91 characters)
     */
    public static String encodeLon(double lonDeg) {
        lonDeg = wrapLon(lonDeg);
        long x = (long) Math.floor(LON_SCALE * (180.0 + lonDeg));
        if (x < 0) x = 0;
        if (x > MAX_VAL) x = MAX_VAL;
        return toBase91(x, CODE_LEN);
    }

    /**
     * Encode coordinate pair with dash separator (8 chars + dash = 9 chars total)
     * Format: LLLL-LLLL
     */
    public static String encodePairWithDash(double latDeg, double lonDeg) {
        return encodeLat(latDeg) + "-" + encodeLon(lonDeg);
    }

    /**
     * Encode coordinate pair in compact format (8 chars, no separator)
     */
    public static String encodePairCompact(double latDeg, double lonDeg) {
        return encodeLat(latDeg) + encodeLon(lonDeg);
    }

    /**
     * Decode latitude from APRS compressed format
     */
    public static double decodeLat(String encoded) {
        if (encoded == null || encoded.length() != CODE_LEN) {
            throw new IllegalArgumentException("Latitude code must be exactly 4 characters");
        }
        long y = fromBase91(encoded);
        return 90.0 - (y / LAT_SCALE);
    }

    /**
     * Decode longitude from APRS compressed format
     */
    public static double decodeLon(String encoded) {
        if (encoded == null || encoded.length() != CODE_LEN) {
            throw new IllegalArgumentException("Longitude code must be exactly 4 characters");
        }
        long x = fromBase91(encoded);
        return (x / LON_SCALE) - 180.0;
    }

    /**
     * Decode coordinate pair with dash separator
     */
    public static double[] decodePairWithDash(String encoded) {
        if (encoded == null || !encoded.contains("-")) {
            throw new IllegalArgumentException("Invalid dash-separated coordinate pair");
        }
        String[] parts = encoded.split("-", 2);
        if (parts.length != 2) {
            throw new IllegalArgumentException("Invalid coordinate format");
        }
        return new double[]{decodeLat(parts[0]), decodeLon(parts[1])};
    }

    /**
     * Convert long value to Base91 string of specified length
     */
    private static String toBase91(long val, int len) {
        char[] out = new char[len];
        for (int i = len - 1; i >= 0; i--) {
            int d = (int) (val % BASE);
            out[i] = (char) (d + OFFSET);
            val /= BASE;
        }
        return new String(out);
    }

    /**
     * Convert Base91 string to long value
     */
    private static long fromBase91(String s) {
        long result = 0;
        for (int i = 0; i < s.length(); i++) {
            int digit = s.charAt(i) - OFFSET;
            if (digit < 0 || digit >= BASE) {
                throw new IllegalArgumentException("Invalid Base91 character: " + s.charAt(i));
            }
            result = result * BASE + digit;
        }
        return result;
    }

    /**
     * Clamp latitude to valid range [-90, 90]
     */
    private static double clampLat(double lat) {
        if (lat < -90.0) return -90.0;
        if (lat > 90.0) return 90.0;
        return lat;
    }

    /**
     * Wrap longitude to valid range [-180, 180)
     */
    private static double wrapLon(double lon) {
        while (lon < -180.0) lon += 360.0;
        while (lon >= 180.0) lon -= 360.0;
        return lon;
    }
}
