/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Search engine for collections stored in the relay
 * Indexes and searches collection metadata and file trees
 *
 * @author brito
 */
public class CollectionSearcher {

    private static final Logger LOG = LoggerFactory.getLogger(CollectionSearcher.class);
    private final String deviceStoragePath;

    public CollectionSearcher(String deviceStoragePath) {
        this.deviceStoragePath = deviceStoragePath;
    }

    /**
     * Search across all collections
     *
     * @param query Search query string
     * @param limit Maximum number of results to return
     * @return List of search results sorted by relevance
     */
    public List<SearchResult> search(String query, int limit) {
        if (query == null || query.trim().isEmpty()) {
            return Collections.emptyList();
        }

        String normalizedQuery = query.toLowerCase().trim();
        List<SearchResult> results = new ArrayList<>();

        try {
            Path devicesDir = Paths.get(deviceStoragePath);
            if (!Files.exists(devicesDir)) {
                LOG.warn("Device storage path does not exist: {}", deviceStoragePath);
                return results;
            }

            // Iterate through all device directories
            try (Stream<Path> devicePaths = Files.list(devicesDir)) {
                devicePaths.filter(Files::isDirectory).forEach(devicePath -> {
                    String callsign = devicePath.getFileName().toString();
                    Path collectionsDir = devicePath.resolve("collections");

                    if (Files.exists(collectionsDir) && Files.isDirectory(collectionsDir)) {
                        searchDeviceCollections(callsign, collectionsDir, normalizedQuery, results);
                    }
                });
            }

        } catch (IOException e) {
            LOG.error("Error during search", e);
        }

        // Sort by relevance (descending) and limit results
        return results.stream()
                .sorted((a, b) -> Double.compare(b.relevance, a.relevance))
                .limit(limit)
                .collect(Collectors.toList());
    }

    /**
     * Search collections for a specific device
     */
    private void searchDeviceCollections(String callsign, Path collectionsDir,
                                        String query, List<SearchResult> results) {
        try (Stream<Path> collectionPaths = Files.list(collectionsDir)) {
            collectionPaths.filter(Files::isDirectory).forEach(collectionPath -> {
                String collectionName = collectionPath.getFileName().toString();
                searchCollection(callsign, collectionName, collectionPath, query, results);
            });
        } catch (IOException e) {
            LOG.error("Error searching collections for device {}", callsign, e);
        }
    }

    /**
     * Search within a single collection
     */
    private void searchCollection(String callsign, String collectionName,
                                 Path collectionPath, String query,
                                 List<SearchResult> results) {
        // Parse collection metadata
        Path collectionFile = collectionPath.resolve("collection.js");
        CollectionMetadata metadata = parseCollectionMetadata(collectionFile);

        if (metadata == null) {
            LOG.warn("Could not parse collection metadata: {}", collectionFile);
            return;
        }

        // Check if collection title or description matches
        boolean collectionMatches = false;
        double collectionRelevance = 0.0;

        if (metadata.title != null && metadata.title.toLowerCase().contains(query)) {
            collectionMatches = true;
            collectionRelevance = calculateRelevance(metadata.title.toLowerCase(), query);
        }

        if (metadata.description != null && metadata.description.toLowerCase().contains(query)) {
            collectionMatches = true;
            double descRelevance = calculateRelevance(metadata.description.toLowerCase(), query);
            collectionRelevance = Math.max(collectionRelevance, descRelevance * 0.8);
        }

        if (collectionMatches) {
            results.add(new SearchResult(
                callsign,
                collectionName,
                metadata.title,
                metadata.description,
                null,
                null,
                null,
                "collection",
                collectionRelevance
            ));
        }

        // Search file tree using tree.json
        Path treeJsonFile = collectionPath.resolve("extra").resolve("tree.json");

        if (Files.exists(treeJsonFile)) {
            searchTreeJson(callsign, collectionName, metadata, treeJsonFile, query, results);
        }
    }

    /**
     * Search within tree.json file (pure JSON format)
     */
    private void searchTreeJson(String callsign, String collectionName,
                               CollectionMetadata metadata, Path treeJsonFile,
                               String query, List<SearchResult> results) {
        try {
            String content = Files.readString(treeJsonFile);
            JsonArray treeData = JsonParser.parseString(content).getAsJsonArray();

            // Search through file entries
            for (int i = 0; i < treeData.size(); i++) {
                JsonObject fileEntry = treeData.get(i).getAsJsonObject();

                String path = fileEntry.has("path") ? fileEntry.get("path").getAsString() : null;
                String name = fileEntry.has("name") ? fileEntry.get("name").getAsString() : null;
                String type = fileEntry.has("type") ? fileEntry.get("type").getAsString() : null;

                if (path == null || name == null) {
                    continue;
                }

                // Check if path or name matches query
                String pathLower = path.toLowerCase();
                String nameLower = name.toLowerCase();

                if (pathLower.contains(query) || nameLower.contains(query)) {
                    double relevance = Math.max(
                        calculateRelevance(pathLower, query),
                        calculateRelevance(nameLower, query)
                    );

                    results.add(new SearchResult(
                        callsign,
                        collectionName,
                        metadata.title,
                        metadata.description,
                        path,
                        name,
                        type,
                        "file",
                        relevance
                    ));
                }
            }

        } catch (IOException e) {
            LOG.error("Error reading tree.json: {}", treeJsonFile, e);
        } catch (Exception e) {
            LOG.error("Error parsing tree.json: {}", treeJsonFile, e);
        }
    }

    /**
     * Parse collection.js file to extract metadata
     */
    private CollectionMetadata parseCollectionMetadata(Path collectionFile) {
        try {
            if (!Files.exists(collectionFile)) {
                return null;
            }

            String content = Files.readString(collectionFile);

            // Extract JSON from JavaScript file
            // Format: window.COLLECTION_DATA = {...}
            int startIdx = content.indexOf('{');
            int endIdx = content.lastIndexOf('}');

            if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
                return null;
            }

            String json = content.substring(startIdx, endIdx + 1);
            JsonObject data = JsonParser.parseString(json).getAsJsonObject();

            if (!data.has("collection")) {
                return null;
            }

            JsonObject collection = data.getAsJsonObject("collection");

            String id = collection.has("id") ? collection.get("id").getAsString() : null;
            String title = collection.has("title") ? collection.get("title").getAsString() : null;
            String description = collection.has("description") ? collection.get("description").getAsString() : null;
            String updated = collection.has("updated") ? collection.get("updated").getAsString() : null;

            return new CollectionMetadata(id, title, description, updated);

        } catch (IOException e) {
            LOG.error("Error reading collection.js: {}", collectionFile, e);
            return null;
        } catch (Exception e) {
            LOG.error("Error parsing collection.js: {}", collectionFile, e);
            return null;
        }
    }

    /**
     * Calculate relevance score based on query match
     * Returns a value between 0.0 and 1.0
     */
    private double calculateRelevance(String text, String query) {
        if (text.equals(query)) {
            return 1.0; // Exact match
        }

        if (text.startsWith(query)) {
            return 0.9; // Prefix match
        }

        if (text.contains(" " + query) || text.contains("/" + query) || text.contains("-" + query)) {
            return 0.8; // Word boundary match
        }

        // Calculate based on query coverage
        double coverage = (double) query.length() / text.length();
        return Math.min(0.7, coverage);
    }

    /**
     * Collection metadata holder
     */
    private static class CollectionMetadata {
        String id;
        String title;
        String description;
        String updated;

        CollectionMetadata(String id, String title, String description, String updated) {
            this.id = id;
            this.title = title;
            this.description = description;
            this.updated = updated;
        }
    }
}
