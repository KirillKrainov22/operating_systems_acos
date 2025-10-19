#!/bin/bash
# Lab 1 — Disk usage check and log archiving
# Authors: Soloviev Artem, Kraynov Kirill, Kutuev Timur, Belyantsev Michail.

# Use the mounted DMG volumes
LOG_DIR="/Volumes/log"
BACKUP_DIR="/Volumes/backup"

# Entering threshold parameter
read -p "Enter threshold (1-100): " THRESHOLD

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -lt 1 ] || [ "$THRESHOLD" -gt 100 ]; then
    echo "WARNING: Threshold must be a number from 1 to 100."
    exit 1
fi

# Check if LOG exists
if [ ! -d "$LOG_DIR" ]; then
    echo "ERROR: $LOG_DIR not found. Please mount log.dmg"
    exit 1
fi

# Check if we can read LOG directory
if [ ! -r "$LOG_DIR" ]; then
    echo "ERROR: Cannot read $LOG_DIR directory. Check permissions."
    exit 1
fi

# Check if LOG is empty
LOG_COUNT=$(ls -1 "$LOG_DIR" 2>/dev/null | wc -l | tr -d ' ')
if [ "$LOG_COUNT" -eq 0 ]; then
    echo "Info: $LOG_DIR is empty, nothing to archive."
    exit 0
fi

# Entering number not to archive parameter
read -p "Enter number of files to not archive (0-$LOG_COUNT): " FILES_TO_KEEP

if ! [[ "$FILES_TO_KEEP" =~ ^[0-9]+$ ]] || [ "$FILES_TO_KEEP" -lt 0 ] || [ "$FILES_TO_KEEP" -gt "$LOG_COUNT" ]; then
    echo "WARNING: Number of files must be from 0 to $LOG_COUNT."
    exit 1
fi

echo "Threshold set to $THRESHOLD%."
echo "Number of files to not archive set to $FILES_TO_KEEP."

# Check directories existence
if [ ! -d "$BACKUP_DIR" ]; then
    echo "ERROR: $BACKUP_DIR not found. Please mount backup.dmg"
    exit 1
fi

# Check if we can write to BACKUP directory
if [ ! -w "$BACKUP_DIR" ]; then
    echo "ERROR: Cannot write to $BACKUP_DIR directory. Check permissions."
    exit 1
fi

# Check disk usage for the mounted volumes
USAGE=$(df -h "$LOG_DIR" | awk 'NR==2 {gsub("%",""); print $5}' | tr -d ' ')
BACKUP_USAGE=$(df -h "$BACKUP_DIR" | awk 'NR==2 {gsub("%",""); print $5}' | tr -d ' ')

echo "LOG usage: ${USAGE}% (threshold: ${THRESHOLD}%)"
echo "BACKUP usage: ${BACKUP_USAGE}%"

if [ "$BACKUP_USAGE" -ge 95 ]; then
    echo "ERROR: BACKUP volume is more than 95% full. Archiving not possible."
    exit 1
fi

# If LOG usage below threshold
if [ "$USAGE" -lt "$THRESHOLD" ]; then
    echo "Usage below threshold. No need to archive."
    exit 0
fi

echo "Threshold exceeded. Starting archiving process..."

# Select files to archive
FILES_TO_ARCHIVE=$(ls -t "$LOG_DIR" 2>/dev/null | tail -n +$((FILES_TO_KEEP+1)))

if [ -z "$FILES_TO_ARCHIVE" ]; then
    echo "No files to archive (less than $FILES_TO_KEEP files exist)."
    exit 0
fi

# Create archive name with timestamp
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
ARCHIVE_NAME="log_backup_${TIMESTAMP}.tar"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

# Create archive with tar + gzip
cd "$LOG_DIR" && tar -czf "$ARCHIVE_PATH.gz" $FILES_TO_ARCHIVE

if [ $? -ne 0 ]; then
    echo "ERROR: failed to create archive."
    exit 1
fi

# Remove archived files
for f in $FILES_TO_ARCHIVE; do
    rm -f "$LOG_DIR/$f"
done

# Log result to archive.log
echo "$(date '+%Y-%m-%d %H:%M:%S') — Archive: ${ARCHIVE_NAME}.gz — Removed $(echo "$FILES_TO_ARCHIVE" | wc -w | tr -d ' ') files — LOG usage was ${USAGE}%" >> "$BACKUP_DIR/archive.log"

echo "Archive created: ${ARCHIVE_NAME}.gz"
echo "Removed old files, kept $FILES_TO_KEEP latest."

exit 0
