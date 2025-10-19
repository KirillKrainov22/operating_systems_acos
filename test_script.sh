#!/bin/bash
# Test script for main_script.sh
# Authors: Soloviev Artem, Kraynov Kirill, Kutuev Timur, Belyantsev Michail.

MAIN_SCRIPT="./main_script.sh"
LOG_DIR="/Volumes/log"
BACKUP_DIR="/Volumes/backup"

echo "=== TEST START ==="

# Test of availability of main script
if [ ! -f "$MAIN_SCRIPT" ]; then
    echo "ERROR: main_script.sh not found in current directory."
    exit 1
fi

# Check if volumes are mounted
if [ ! -d "$LOG_DIR" ]; then
    echo "ERROR: $LOG_DIR not found. Please mount log.dmg"
    exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    echo "ERROR: $BACKUP_DIR not found. Please mount backup.dmg"
    exit 1
fi

# Preparing
echo "Preparing environment..."

# Cleaning archive logs
if [ -f "$BACKUP_DIR/archive.log" ]; then
    echo "Old archive log found. Keeping previous results."
else
    echo "Creating new archive log file..."
    touch "$BACKUP_DIR/archive.log"
    chmod 644 "$BACKUP_DIR/archive.log"
fi

# Creating test files
echo "Creating 6 test files in $LOG_DIR..."
for i in {1..6}; do
    echo "File content number $i" > "$LOG_DIR/file_$i.log"
    chmod 644 "$LOG_DIR/file_$i.log"
    sleep 1
done
echo "Test files created:"
ls -la "$LOG_DIR"

# Test 1: Threshold not exceeded
# Assume not archiving files
echo ""
echo "=== Test 1: Threshold not exceeded ==="
echo -e "90\n2" | bash "$MAIN_SCRIPT"

FILES_LEFT=$(ls -1 "$LOG_DIR" 2>/dev/null | wc -l | tr -d ' ')
ARCHIVES_BEFORE=$(ls -1 "$BACKUP_DIR"/*.gz 2>/dev/null | wc -l | tr -d ' ')
echo "Files left in LOG: $FILES_LEFT"
echo "Archives in BACKUP: $ARCHIVES_BEFORE"

# Test 2: Threshold exceeded
# Assume archiving files
echo ""
echo "=== Test 2: Threshold exceeded ==="
echo -e "1\n2" | bash "$MAIN_SCRIPT"

ARCHIVES_AFTER=$(ls -1 "$BACKUP_DIR"/*.gz 2>/dev/null | wc -l | tr -d ' ')
if [ "$ARCHIVES_AFTER" -gt "$ARCHIVES_BEFORE" ]; then
    echo "Archive successfully created."
else
    echo "WARNING: No new archive detected."
fi

echo "Files remaining in LOG:"
ls -la "$LOG_DIR" 2>/dev/null || echo "LOG directory is empty or inaccessible"

# Test 3: Uncorrect threshold input
# input "abc" instead correct numbers
echo ""
echo "=== Test 3: Invalid threshold input ==="
echo -e "abc\n2" | bash "$MAIN_SCRIPT"

# Test 4: Uncorrect number of files
# too large number of files to not archive, more than exists in LOG
echo ""
echo "=== Test 4: Invalid file count ==="
FILE_COUNT=$(ls -1 "$LOG_DIR" 2>/dev/null | wc -l | tr -d ' ')
INVALID_COUNT=$((FILE_COUNT + 10))
echo -e "50\n$INVALID_COUNT" | bash "$MAIN_SCRIPT"

# Final result
echo ""
echo "=== Final result ==="
echo "Files in LOG:"
ls -la "$LOG_DIR" 2>/dev/null || echo "LOG directory is empty or inaccessible"

echo ""
echo "Archives in BACKUP:"
ls -la "$BACKUP_DIR" 2>/dev/null || echo "BACKUP directory is empty or inaccessible"

echo ""
echo "Archive log content:"
cat "$BACKUP_DIR/archive.log" 2>/dev/null || echo "(no archive log found)"
