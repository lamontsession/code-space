## Archive and Delete Script

### Description
The archive and delete script (`archive_and_delete.sh`) safely archives files in its directory into a timestamped tar archive, verifies the archive integrity, and then deletes the original files. This script is designed with multiple safety checks to prevent data loss.

### Features
- Enumerates all files in the script's directory (excluding the script itself and subdirectories)
- Creates timestamped archives for easy identification
- Optional gzip compression for space savings
- Custom output directory support for storing archives elsewhere
- Interactive confirmation before destructive operations
- Archive verification (file count and integrity checks) before deletion
- Detailed step-by-step progress reporting
- Robust error handling with informative messages
- Safe shell execution with strict mode (`set -euo pipefail`)
- Automatic cleanup of temporary files

### Prerequisites
- `bash` shell
- `tar` for creating archives
- `find` for file enumeration
- Standard Unix utilities (`wc`, `sed`, `rm`, `mkdir`)

### Installation
1. Clone the repository (if not already done):
```bash
git clone https://github.com/lamontsession/code-space.git
cd code-space
```

2. Make the script executable:
```bash
chmod +x archive_and_delete.sh
```

### Usage
```bash
./archive_and_delete.sh                                    # Archive to current directory
./archive_and_delete.sh --compress                         # Create compressed .tar.gz archive
./archive_and_delete.sh --output /path/to/backup          # Archive to specific directory
./archive_and_delete.sh --compress --output ~/backups     # Compressed archive to custom location
```

### Options
- `--compress`: Creates a compressed `.tar.gz` archive instead of an uncompressed `.tar` file
- `--output <path>`: Specifies the destination directory for the archive. If the directory doesn't exist, the script will prompt to create it

### Operation Flow
1. **Enumeration**: Lists all files in the script's directory (excludes itself and subdirectories)
2. **Count**: Displays the total number of files to be processed
3. **Preview**: Shows the list of files that will be archived and deleted
4. **Confirmation**: Prompts user to confirm before proceeding
5. **Archive Creation**: Creates a timestamped tar archive with optional compression
6. **Verification**: Verifies the archive contains the correct number of files and passes integrity checks
7. **Deletion**: Deletes original files only after successful verification
8. **Summary**: Reports success or any errors encountered

### Safety Features
- **User confirmation required**: The script prompts for explicit "yes" confirmation before any destructive operations
- **Archive verification**: Checks both file count and archive integrity before deletion
- **No deletion on failure**: If archive creation or verification fails, original files are preserved
- **Timestamped archives**: Uses `YYYYMMDD_HHMMSS` format to prevent overwrites
- **Error reporting**: Detailed error messages for each failed operation
- **Atomic operations**: Uses `set -euo pipefail` to fail fast on errors

### Example Output
```
==========================================
Archive and Delete Script
==========================================
Working directory: /home/user/data
Archive destination: /home/user/backups

[1] Enumerating files in directory...
[2] File count to be archived and deleted: 5

[3] Files to be archived:
    - document1.txt
    - document2.pdf
    - image.jpg
    - data.csv
    - notes.md

Proceed with archiving and deletion? (yes/no): yes
[4] Creating archive: /home/user/backups/archive_20251128_143022.tar.gz
    Archive created successfully.
[5] Files in archive: 5
[6] Verifying archive integrity...
    Archive integrity verified.
[7] Deleting original files...
    Deleted: document1.txt
    Deleted: document2.pdf
    Deleted: image.jpg
    Deleted: data.csv
    Deleted: notes.md

==========================================
Operation completed successfully!
Archive: /home/user/backups/archive_20251128_143022.tar.gz
Original files deleted: 5
==========================================
```

### Important Notes
- The script only processes files in its immediate directory (depth 1), not subdirectories
- The script always excludes itself from the archive
- Archive verification includes both file count matching and tar integrity checks
- If any deletion fails, the script reports errors but the archive remains intact
- The script requires write permissions in the output directory
- Always review the list of files to be archived and deleted before confirming
- Consider running the script in a test environment first to understand its behavior before using it on important

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

LaMont Session

## Last Updated

2026-03-07