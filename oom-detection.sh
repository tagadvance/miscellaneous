#!/usr/bin/env -S java --source 17

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Consumer;
import java.util.function.Supplier;

/**
 * Sent alert via ntfy when failed ssh authentication failure is detected.
 */
final class IntrusionDetection {

	private static final String DEFAULT_JOURNAL_DIRECTORY = "/var/log/journal";
	private static final String DEFAULT_HASH_DIRECTORY = ".ntfy";

	private static final String TOPIC = "homelab";
	private static final String SEARCH_STRING = "Killed process";

	private static final String HOST = "https://%s".formatted(System.getenv("NTFY_HOST"));
	private static final String BEARER_TOKEN = System.getenv("NTFY_BEARER_TOKEN");

	static void main(final String[] args) throws IOException {
		final var journalKey = "--journal=";
		final var journalDirectory = new AtomicReference<>(DEFAULT_JOURNAL_DIRECTORY);
		final var deduplicationKey = "--hash=";
		final var deduplicationDirectory = new AtomicReference<>(DEFAULT_HASH_DIRECTORY);
		for (String arg : args) {
			if (arg.startsWith(journalKey)) {
				final var value = arg.substring(journalKey.length());
				journalDirectory.set(value);
			} else if (arg.startsWith(deduplicationKey)) {
				final var value = arg.substring(deduplicationKey.length());
				deduplicationDirectory.set(value);
			}
		}

		final Supplier<String> supplier = () -> {
			final var journal = journalDirectory.get();
			if (journal == null || !Files.isDirectory(Path.of(journal))) {
				System.err.println("Please specify a valid --journal argument.");
				System.exit(1);
			}

			return journal;
		};

		journalctl(supplier.get(), line -> {
			try {
				final var path = Path.of(deduplicationDirectory.get());
				Files.createDirectories(path);

				process(path, line);
			} catch (final Exception e) {
				System.err.println(e.getMessage());
			}
		});
	}

	private static void journalctl(final String journalDirectory,
		final Consumer<String> lineConsumer) throws IOException {
		final var command = new String[]{"/usr/bin/journalctl", "--directory", journalDirectory,
			"--dmesg"};
		final var process = Runtime.getRuntime().exec(command);
		try (final var in = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
			in.lines().filter(line -> line.contains(SEARCH_STRING)).forEach(lineConsumer);
		}
	}

	private static void process(final Path deduplicationDirectory, final String line)
		throws NoSuchAlgorithmException, IOException {
		final var digest = MessageDigest.getInstance("SHA-256");
		final var bytes = line.getBytes(StandardCharsets.UTF_8);
		final var encodedHash = digest.digest(bytes);
		final var hexFormat = HexFormat.of().withUpperCase();
		final var hex = hexFormat.formatHex(encodedHash);

		final var hexFile = deduplicationDirectory.resolve(hex);
		if (!Files.exists(hexFile)) {
			ntfy(TOPIC, line);
			Files.createFile(hexFile);
		}
	}

	private static void ntfy(final String topic, final String message) throws IOException {
		final var host = "%s/%s".formatted(HOST, topic);
		final var url = URI.create(host).toURL();

		final var connection = (HttpURLConnection) url.openConnection();
		connection.setDoOutput(true);
		connection.setRequestMethod("POST");
		connection.setRequestProperty("Authorization", "Bearer %s".formatted(BEARER_TOKEN));
		connection.setRequestProperty("Priority", "low");
		connection.setRequestProperty("Title", "Warning");
		connection.setRequestProperty("Tags", "Warning");
		connection.connect();
		try {
			try (final var writer = new OutputStreamWriter(connection.getOutputStream())) {
				writer.write(message);
			}

			final int responseCode = connection.getResponseCode();
			if (responseCode == HttpURLConnection.HTTP_OK) {
				try (final var reader = new BufferedReader(
					new InputStreamReader(connection.getInputStream()))) {
					reader.lines().forEach(System.out::println);
				}
			}
		} finally {
			connection.disconnect();
		}
	}

}
