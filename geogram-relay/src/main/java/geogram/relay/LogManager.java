/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.nio.file.*;
import java.time.LocalDate;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.concurrent.*;
import java.util.stream.Stream;

/**
 * Manages log files with automatic rotation, size management, and cleanup.
 *
 * Features:
 * - Weekly log files: log-YY-WW.txt (e.g., log-25-01.txt for week 1 of 2025)
 * - Maximum file size: 100 MB
 * - Auto-pruning: when file exceeds 100 MB, keeps newest 50%, deletes oldest 50%
 * - Daily cleanup: removes log files older than 1 year
 * - Separate background threads for pruning and cleanup
 *
 * @author brito
 */
public class LogManager {

    private static final Logger LOG = LoggerFactory.getLogger(LogManager.class);

    // Configuration
    private static final String LOG_DIR = "logs";
    private static final long MAX_LOG_SIZE_BYTES = 100 * 1024 * 1024; // 100 MB
    private static final long RETENTION_DAYS = 365; // 1 year
    private static final long CLEANUP_INTERVAL_HOURS = 24; // Run cleanup daily
    private static final long PRUNE_CHECK_INTERVAL_MINUTES = 60; // Check size every hour

    // Thread management
    private final ScheduledExecutorService cleanupScheduler;
    private final ScheduledExecutorService pruneScheduler;
    private volatile boolean running = false;

    // File management
    private File logDirectory;
    private PrintWriter currentLogWriter;
    private String currentLogFileName;

    public LogManager() {
        this.cleanupScheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "LogCleanup");
            t.setDaemon(true);
            return t;
        });

        this.pruneScheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "LogPrune");
            t.setDaemon(true);
            return t;
        });
    }

    /**
     * Start the log manager
     */
    public void start() {
        if (running) {
            LOG.warn("LogManager already running");
            return;
        }

        try {
            // Create logs directory
            logDirectory = new File(LOG_DIR);
            if (!logDirectory.exists()) {
                if (!logDirectory.mkdirs()) {
                    throw new IOException("Failed to create logs directory: " + LOG_DIR);
                }
                LOG.info("Created logs directory: {}", logDirectory.getAbsolutePath());
            }

            // Open current log file
            openCurrentLogFile();

            // Schedule daily cleanup (remove files older than 1 year)
            cleanupScheduler.scheduleAtFixedRate(
                this::cleanupOldLogs,
                1, // Initial delay: 1 hour
                CLEANUP_INTERVAL_HOURS,
                TimeUnit.HOURS
            );

            // Schedule hourly size check and pruning
            pruneScheduler.scheduleAtFixedRate(
                this::checkAndPruneCurrentLog,
                PRUNE_CHECK_INTERVAL_MINUTES, // Initial delay
                PRUNE_CHECK_INTERVAL_MINUTES,
                TimeUnit.MINUTES
            );

            running = true;
            LOG.info("LogManager started - logs directory: {}", logDirectory.getAbsolutePath());
            LOG.info("Log retention: {} days, max size: {} MB", RETENTION_DAYS, MAX_LOG_SIZE_BYTES / 1024 / 1024);

        } catch (Exception e) {
            LOG.error("Failed to start LogManager", e);
            stop();
        }
    }

    /**
     * Stop the log manager
     */
    public void stop() {
        if (!running) {
            return;
        }

        running = false;

        // Shutdown schedulers
        cleanupScheduler.shutdown();
        pruneScheduler.shutdown();

        try {
            cleanupScheduler.awaitTermination(5, TimeUnit.SECONDS);
            pruneScheduler.awaitTermination(5, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            cleanupScheduler.shutdownNow();
            pruneScheduler.shutdownNow();
            Thread.currentThread().interrupt();
        }

        // Close current log file
        closeCurrentLogFile();

        LOG.info("LogManager stopped");
    }

    /**
     * Get the current log file name based on week of year
     * Format: log-YY-WW.txt (e.g., log-25-01.txt)
     */
    private String getCurrentLogFileName() {
        LocalDate now = LocalDate.now();
        int year = now.getYear() % 100; // Last 2 digits
        int weekOfYear = now.get(WeekFields.ISO.weekOfWeekBasedYear());
        return String.format("log-%02d-%02d.txt", year, weekOfYear);
    }

    /**
     * Open the current log file for writing
     */
    private void openCurrentLogFile() throws IOException {
        String newFileName = getCurrentLogFileName();

        // Check if we need to rotate to a new file
        if (currentLogWriter != null && newFileName.equals(currentLogFileName)) {
            return; // Already using correct file
        }

        // Close previous file if open
        closeCurrentLogFile();

        // Open new file
        File logFile = new File(logDirectory, newFileName);
        currentLogWriter = new PrintWriter(new FileWriter(logFile, true)); // Append mode
        currentLogFileName = newFileName;

        LOG.info("Opened log file: {}", logFile.getAbsolutePath());
    }

    /**
     * Close the current log file
     */
    private void closeCurrentLogFile() {
        if (currentLogWriter != null) {
            currentLogWriter.flush();
            currentLogWriter.close();
            currentLogWriter = null;
            currentLogFileName = null;
        }
    }

    /**
     * Write a log entry to the current log file
     */
    public synchronized void log(String message) {
        if (!running) {
            return;
        }

        try {
            // Check if we need to rotate to a new week's file
            String expectedFileName = getCurrentLogFileName();
            if (!expectedFileName.equals(currentLogFileName)) {
                openCurrentLogFile();
            }

            // Write log entry with timestamp
            if (currentLogWriter != null) {
                String timestamp = java.time.LocalDateTime.now().format(
                    java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS"));
                currentLogWriter.println("[" + timestamp + "] " + message);
                currentLogWriter.flush();
            }

        } catch (Exception e) {
            LOG.error("Failed to write log entry", e);
        }
    }

    /**
     * Check current log file size and prune if needed
     */
    private void checkAndPruneCurrentLog() {
        if (!running || currentLogFileName == null) {
            return;
        }

        try {
            File logFile = new File(logDirectory, currentLogFileName);
            if (!logFile.exists()) {
                return;
            }

            long fileSize = logFile.length();

            if (fileSize > MAX_LOG_SIZE_BYTES) {
                LOG.info("Log file {} exceeds max size ({} MB), pruning...",
                    currentLogFileName, fileSize / 1024 / 1024);
                pruneLogFile(logFile);
            }

        } catch (Exception e) {
            LOG.error("Error checking/pruning log file", e);
        }
    }

    /**
     * Prune a log file: keep newest 50%, remove oldest 50%
     */
    private synchronized void pruneLogFile(File logFile) throws IOException {
        // Close current writer
        closeCurrentLogFile();

        // Read all lines
        List<String> allLines = Files.readAllLines(logFile.toPath());
        int totalLines = allLines.size();
        int linesToKeep = totalLines / 2; // Keep newest 50%

        LOG.info("Pruning log file: {} lines -> {} lines", totalLines, linesToKeep);

        // Keep only the newest half
        List<String> linesToKeep_list = allLines.subList(totalLines - linesToKeep, totalLines);

        // Write back to file (overwrite)
        Files.write(logFile.toPath(), linesToKeep_list, StandardOpenOption.TRUNCATE_EXISTING);

        // Reopen file for appending
        openCurrentLogFile();

        LOG.info("Log file pruned: {} -> {} MB",
            logFile.length() / 1024 / 1024,
            Files.size(logFile.toPath()) / 1024 / 1024);
    }

    /**
     * Clean up log files older than retention period
     */
    private void cleanupOldLogs() {
        if (!running) {
            return;
        }

        try {
            LOG.info("Running daily log cleanup...");

            LocalDate cutoffDate = LocalDate.now().minusDays(RETENTION_DAYS);
            int deletedCount = 0;

            // List all log files
            File[] logFiles = logDirectory.listFiles((dir, name) ->
                name.startsWith("log-") && name.endsWith(".txt"));

            if (logFiles == null || logFiles.length == 0) {
                LOG.info("No log files found for cleanup");
                return;
            }

            for (File logFile : logFiles) {
                try {
                    // Check file modification time
                    long lastModified = logFile.lastModified();
                    LocalDate fileDate = LocalDate.ofEpochDay(lastModified / (1000 * 60 * 60 * 24));

                    if (fileDate.isBefore(cutoffDate)) {
                        // Delete old file
                        if (logFile.delete()) {
                            LOG.info("Deleted old log file: {} (last modified: {})",
                                logFile.getName(), fileDate);
                            deletedCount++;
                        } else {
                            LOG.warn("Failed to delete old log file: {}", logFile.getName());
                        }
                    }

                } catch (Exception e) {
                    LOG.error("Error processing log file: {}", logFile.getName(), e);
                }
            }

            if (deletedCount > 0) {
                LOG.info("Log cleanup completed: deleted {} old log files", deletedCount);
            } else {
                LOG.info("Log cleanup completed: no files to delete");
            }

        } catch (Exception e) {
            LOG.error("Error during log cleanup", e);
        }
    }

    /**
     * Get current log file path
     */
    public String getCurrentLogFilePath() {
        if (currentLogFileName == null) {
            return null;
        }
        return new File(logDirectory, currentLogFileName).getAbsolutePath();
    }
}
