#!/usr/bin/env -S java --source 17

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.util.regex.Pattern;
import java.util.stream.IntStream;

/**
 * Format an IPv4 address to IPv6 Rapid Deployment (6RD) for Century Link.
 */
final class IPv6 {

        private static final String IP_URL = "http://checkip.amazonaws.com";
        private static final String FORMAT_6RD = "2602:%02x:%02x%02x:%02x::1/64";

        public static void main(String[] args) throws IOException {
                final var ipv4 = getIPv4();
                final var rd = format6rd(ipv4);

                System.out.println(rd);
        }

        private static String getIPv4() throws IOException {
                final var url = new URL(IP_URL);
                try (final var in = new BufferedReader(new InputStreamReader(url.openStream()))) {
                        return in.readLine().trim();
                }
        }

        private static String format6rd(final String ip) {
                final var regex = "^(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})$";
                final var pattern = Pattern.compile(regex);
                final var matcher = pattern.matcher(ip);
                if (matcher.matches()) {
                        final var octets = IntStream.range(1, matcher.groupCount() + 1)
                                .mapToObj(matcher::group)
                                .mapToInt(Integer::parseUnsignedInt)
                                .toArray();

                        return FORMAT_6RD.formatted(octets[0], octets[1], octets[2], octets[3]);
                }

                throw new IllegalArgumentException("Invalid IPv4 format: " + ip);
        }

}
