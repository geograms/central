/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import java.util.Objects;

/**
 * Search result containing information about a matched item
 *
 * @author brito
 */
public class SearchResult {
    public String callsign;
    public String collectionName;
    public String collectionTitle;
    public String collectionDescription;
    public String filePath;
    public String fileName;
    public String fileType;
    public String matchType; // "collection", "file", "path"
    public double relevance; // 0.0 to 1.0

    public SearchResult(String callsign, String collectionName, String collectionTitle,
                       String collectionDescription, String filePath, String fileName,
                       String fileType, String matchType, double relevance) {
        this.callsign = callsign;
        this.collectionName = collectionName;
        this.collectionTitle = collectionTitle;
        this.collectionDescription = collectionDescription;
        this.filePath = filePath;
        this.fileName = fileName;
        this.fileType = fileType;
        this.matchType = matchType;
        this.relevance = relevance;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        SearchResult that = (SearchResult) o;
        return Objects.equals(callsign, that.callsign) &&
               Objects.equals(collectionName, that.collectionName) &&
               Objects.equals(filePath, that.filePath);
    }

    @Override
    public int hashCode() {
        return Objects.hash(callsign, collectionName, filePath);
    }
}
