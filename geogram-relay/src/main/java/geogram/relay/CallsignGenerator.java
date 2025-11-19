/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import java.security.SecureRandom;

/**
 * Callsign generator for Geogram relay servers
 *
 * Generates unique callsigns with X3 prefix (indicating relay)
 * Format: X3XXXX (6 characters total)
 *
 * @author brito
 */
public class CallsignGenerator {

    private static final String PREFIX = "X3";
    private static final int SUFFIX_LENGTH = 4;
    private static final String ALPHANUMERIC = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    private static final SecureRandom RANDOM = new SecureRandom();

    /**
     * Generate a new random callsign for a relay
     * Format: X3XXXX where XXXX is 4 random alphanumeric characters
     *
     * Example: X3A7B2, X3QW5K, X34RT9
     *
     * @return A unique callsign with X3 prefix
     */
    public static String generateCallsign() {
        StringBuilder suffix = new StringBuilder(SUFFIX_LENGTH);

        for (int i = 0; i < SUFFIX_LENGTH; i++) {
            int index = RANDOM.nextInt(ALPHANUMERIC.length());
            suffix.append(ALPHANUMERIC.charAt(index));
        }

        return PREFIX + suffix.toString();
    }

    /**
     * Validate a callsign format
     *
     * @param callsign The callsign to validate
     * @return true if valid relay callsign format
     */
    public static boolean isValidRelayCallsign(String callsign) {
        if (callsign == null || callsign.length() != 6) {
            return false;
        }

        if (!callsign.startsWith(PREFIX)) {
            return false;
        }

        // Check that suffix contains only alphanumeric characters
        String suffix = callsign.substring(PREFIX.length());
        return suffix.matches("[A-Z0-9]{" + SUFFIX_LENGTH + "}");
    }
}
