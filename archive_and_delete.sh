#!/bin/bash

# Author: LaMont Session
# Date Created: 2025-11-28
# Last Modified: 2025-11-28

# Description: This script enumerates files in its directory (excluding itself), counts them, archives them into a tar file with a timestamped name, and then deletes the original files after confirming the archive was created successfully.
# Script: archive_and_delete.sh
# Usage: ./archive_and_delete.sh [--compress] [--output /path/to/destination]

# Fail on error, undefined var, and fail pipeline on first failing command
set -euo pipefail
# Safer IFS for word splitting
IFS=$'\n\t'

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Parse command line arguments
USE_COMPRESSION=false
OUTPUT_DIR="$SCRIPT_DIR"

while [[ $# -gt 0 ]]; do
    case "${1}" in
        --compress)
            USE_COMPRESSION=true
            shift
            ;;
        --output)
            if [[ -z "${2:-}" ]]; then
                printf "Error: --output requires a path argument\n" >&2
                exit 1
            fi
            OUTPUT_DIR="${2}"
            shift 2
            ;;
        *)
            printf "Error: Unknown option: %s\n" "${1}" >&2
            printf "Usage: %s [--compress] [--output /path/to/destination]\n" "$(basename "$0")" >&2
            exit 1
            ;;
    esac
done

# Validate and create output directory if needed
if [[ ! -d "$OUTPUT_DIR" ]]; then
    printf "Output directory does not exist: %s\n" "$OUTPUT_DIR"
    while true; do
        read -p "Create directory? (yes/no): " CREATE_DIR
        CREATE_DIR_LC=$(echo "$CREATE_DIR" | tr '[:upper:]' '[:lower:]')
        if [[ "$CREATE_DIR_LC" == "yes" ]]; then
            if mkdir -p "$OUTPUT_DIR" 2>/dev/null; then
                printf "Created directory: %s\n" "$OUTPUT_DIR"
            else
                printf "Error: Failed to create directory: %s\n" "$OUTPUT_DIR" >&2
                exit 1
            fi
            break
        elif [[ "$CREATE_DIR_LC" == "no" ]]; then
            printf "Operation cancelled.\n"
            exit 0
        else
            printf "Please answer 'yes' or 'no'.\n"
        fi
    done
fi

# Set archive name and location
if [[ "$USE_COMPRESSION" == true ]]; then
    ARCHIVE_NAME="$OUTPUT_DIR/archive_$(date +%Y%m%d_%H%M%S).tar.gz"
    TAR_FLAGS="-czf"
else
    ARCHIVE_NAME="$OUTPUT_DIR/archive_$(date +%Y%m%d_%H%M%S).tar"
    TAR_FLAGS="-cf"
fi

TEMP_FILELIST=$(mktemp)

# Trap to clean up temp file on exit
trap "rm -f '$TEMP_FILELIST'" EXIT

echo "=========================================="
echo "Archive and Delete Script"
echo "=========================================="
echo "Working directory: $SCRIPT_DIR"
echo "Archive destination: $OUTPUT_DIR"
echo ""

# Step 1: Enumerate files (excluding the script itself and directories)
echo "[1] Enumerating files in directory..."
find "$SCRIPT_DIR" -maxdepth 1 -type f ! -name "$(basename "$0")" > "$TEMP_FILELIST"

# Step 2: Count files to be processed
FILE_COUNT=$(wc -l < "$TEMP_FILELIST")

echo "[2] File count to be archived and deleted: $FILE_COUNT"
echo ""

# Check if there are files to process
if [[ "$FILE_COUNT" -eq 0 ]]; then
    echo "No files to process. Exiting."
    exit 0
fi

# Step 3: Display files that will be processed
echo "[3] Files to be archived:"
sed 's/^/    - /' "$TEMP_FILELIST"
echo ""

# Step 4: Prompt for confirmation
read -p "Proceed with archiving and deletion? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Step 5: Archive files using the filelist
echo "[4] Creating archive: $ARCHIVE_NAME"
if tar $TAR_FLAGS "$ARCHIVE_NAME" -T "$TEMP_FILELIST" 2>&1; then
    echo "    Archive created successfully."
else
    printf "    ERROR: Failed to create archive.\n"
    exit 1
fi

# Step 6 & 7: Verify archive contents and integrity in one pass
if [[ "$USE_COMPRESSION" == true ]]; then
    ARCHIVE_LIST_OUTPUT=$(tar -tzf "$ARCHIVE_NAME" 2>/dev/null)
    TAR_STATUS=$?
else
    ARCHIVE_LIST_OUTPUT=$(tar -tf "$ARCHIVE_NAME" 2>/dev/null)
    TAR_STATUS=$?
fi
ARCHIVE_FILE_COUNT=$(echo "$ARCHIVE_LIST_OUTPUT" | wc -l)
echo "[5] Files in archive: $ARCHIVE_FILE_COUNT"

# Check that archive file count matches original file count
if [[ "$ARCHIVE_FILE_COUNT" -ne "$FILE_COUNT" ]]; then
    printf "    ERROR: Archive file count (%s) does not match original file count (%s). Aborting deletion.\n" "$ARCHIVE_FILE_COUNT" "$FILE_COUNT"
    exit 1
fi

# Step 7.5: Verify archive integrity (using previous tar exit status)
echo "[6] Verifying archive integrity..."
if [[ "$TAR_STATUS" -ne 0 ]]; then
    printf "    ERROR: Archive integrity check failed. Aborting deletion.\n"
    exit 1
fi
echo "    Archive integrity verified."

# Step 8: Delete original files
echo "[7] Deleting original files..."
DELETE_FAILED=0
while IFS= read -r FILE; do
    if ERROR_MSG=$(rm "$FILE" 2>&1); then
        echo "    Deleted: $(basename "$FILE")"
    else
        printf "    ERROR deleting: %s: %s\n" "$FILE" "$ERROR_MSG"
        DELETE_FAILED=1
    fi
done < "$TEMP_FILELIST"

echo ""
if [[ "$DELETE_FAILED" -eq 0 ]]; then
    echo "=========================================="
    echo "Operation completed successfully!"
    echo "Archive: $ARCHIVE_NAME"
    echo "Original files deleted: $FILE_COUNT"
    echo "=========================================="
    exit 0
else
    echo "=========================================="
    echo "Operation completed with ERRORS during deletion!"
    echo "Some files may not have been deleted. Please check the log above."
    echo "Archive: $ARCHIVE_NAME"
    echo "=========================================="
    exit 1
fi

