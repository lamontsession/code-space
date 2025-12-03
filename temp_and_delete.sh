#!/bin/bash

# Author: LaMont Session
# Date Created: 2025-11-30
# Last Modified: 2025-12-01

# Description: The script creates a file, copies the ls executable into it, changes the file's permissions, executes it, waits 5 seconds, and then deletes the file.

# Usage: ./temp_and_delete.sh


# Fail on error, undefined var, and fail pipeline on first failing command
set -euo pipefail


# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Define test file path
TEST_FILE="$SCRIPT_DIR/test.sh"

# Trap to clean up test file on exit (success or failure)
trap 'rm -f "$TEST_FILE" 2>/dev/null || true' EXIT

echo "=========================================="
echo "Making a Temporary File, Executing, and Deleting It"
echo "=========================================="
echo "Working directory: $SCRIPT_DIR"
echo ""

# Step 1: Create the file in the script directory
echo "[Step 1] Creating file '$TEST_FILE'..."
touch "$TEST_FILE"
if [[ -f "$TEST_FILE" ]]; then
    echo "    File created successfully"
else
    printf "    ERROR: Failed to create file\n" >&2
    exit 1
fi
echo ""

# Step 2: Copy ls executable from /usr/bin/ to the created file
echo "[Step 2] Copying /usr/bin/ls to $TEST_FILE..."
if cp /usr/bin/ls "$TEST_FILE" 2>/dev/null; then
    echo "    Executable copied successfully"
else
    printf "    ERROR: Failed to copy executable\n" >&2
    exit 1
fi
echo ""

# Step 3: Change file permissions to 755 using chmod
echo "[Step 3] Setting permissions to 755..."
if chmod 755 "$TEST_FILE" 2>/dev/null; then
    echo "    Permissions set successfully"
    ls -l "$TEST_FILE"
else
    printf "    ERROR: Failed to set permissions\n" >&2
    exit 1
fi
echo ""

# Step 4: Execute the created file using ./
echo "[Step 4] Executing ./$TEST_FILE..."
echo "    Running file listing output:"
echo "    ---"

if "$TEST_FILE"; then
    echo "    ---"
    echo "    File executed successfully"
else
    printf "\n    ---\n    ERROR: Failed to execute file\n" >&2
    exit 1
fi
echo ""

# Step 5: Wait 5 seconds
echo "[Step 5] Waiting 5 seconds..."
sleep 5
echo "    Wait completed"
echo ""

# Step 6: Remove the created file
echo "[Step 6] Removing $TEST_FILE..."
if rm "$TEST_FILE" 2>/dev/null; then
    echo "    File removed successfully"
else
    printf "    ERROR: Failed to remove file\n" >&2
    exit 1
fi
echo ""

# Verify file was deleted
if [[ ! -f "$TEST_FILE" ]]; then
    echo "=========================================="
    echo "All steps completed successfully!"
    echo "=========================================="
else
    echo "=========================================="
    printf "WARNING: File still exists after removal\n" >&2
    echo "=========================================="
    exit 1
fi