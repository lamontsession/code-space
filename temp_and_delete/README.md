## Temp and Delete Script

### Description
The temp and delete script (`temp_and_delete.sh`) is a testing utility that demonstrates the complete lifecycle of creating a temporary executable file, running it, and cleaning it up. This script is useful for testing file system operations, permissions handling, and real-time security detection systems.

### Features
- Creates a temporary test file in the script's directory
- Copies a legitimate executable (`/usr/bin/ls`) into the test file
- Dynamically sets executable permissions (755)
- Executes the temporary file and captures output
- Implements a 5-second wait period for observation
- Automatically cleans up the test file after execution
- Safe shell execution with strict mode (`set -euo pipefail`)
- Automatic cleanup via trap on success, failure, or interruption
- Comprehensive error handling and progress reporting
- Verification steps to ensure proper cleanup

### Prerequisites
- `bash` shell
- `touch` for file creation
- `cp` for copying files
- `chmod` for permission modification
- Standard Unix utilities (`ls`, `rm`, `sleep`)
- Read access to `/usr/bin/ls` executable

### Installation
1. Clone the repository (if not already done):
```bash
git clone https://github.com/lamontsession/code-space.git
cd code-space
```

2. Make the script executable:
```bash
chmod +x temp_and_delete.sh
```

### Usage
```bash
./temp_and_delete.sh    # Run the complete test cycle
```

The script requires no arguments and runs through all steps automatically.

### Operation Flow
1. **File Creation**: Creates `test.sh` in the script's directory
2. **Executable Copy**: Copies `/usr/bin/ls` binary into the test file
3. **Permission Setting**: Sets executable permissions (755) on the test file
4. **Execution**: Runs the test file and displays its output (directory listing)
5. **Wait Period**: Pauses for 5 seconds (useful for monitoring tools to detect activity)
6. **Cleanup**: Removes the test file
7. **Verification**: Confirms the test file was successfully deleted

### Example Output
```
==========================================
Making a Temporary File, Executing, and Deleting It
==========================================
Working directory: /home/user/scripts

[Step 1] Creating file '/home/user/scripts/test.sh'...
    File created successfully

[Step 2] Copying /usr/bin/ls to /home/user/scripts/test.sh...
    Executable copied successfully

[Step 3] Setting permissions to 755...
    Permissions set successfully
-rwxr-xr-x 1 user user 138856 Dec 01 10:30 /home/user/scripts/test.sh

[Step 4] Executing ./test.sh...
    Running file listing output:
    ---
archive_and_delete.sh
iplookup.sh
temp_and_delete.sh
python-test.py
README.md
    ---
    File executed successfully

[Step 5] Waiting 5 seconds...
    Wait completed

[Step 6] Removing /home/user/scripts/test.sh...
    File removed successfully

==========================================
All steps completed successfully!
==========================================
```

### Use Cases
- **Security Testing**: Test real-time malware detection systems that monitor for suspicious file creation and execution patterns
- **File System Testing**: Verify file creation, modification, and deletion operations work correctly
- **Permission Testing**: Validate that permission changes are applied and respected
- **System Monitoring**: Test file system monitoring tools and audit systems
- **Educational Purpose**: Demonstrate basic shell scripting operations and file lifecycle management

### Safety Features
- **Automatic cleanup trap**: Ensures test file is removed even if script fails or is interrupted
- **Strict mode enabled**: Uses `set -euo pipefail` to catch errors immediately
- **Error handling**: Each step includes validation and informative error messages
- **Non-destructive**: Only creates and removes its own test file
- **Harmless executable**: Uses the standard `ls` command (safe, read-only operation)
- **Verification step**: Confirms cleanup was successful before completion

### Important Notes
- The script creates `test.sh` in its own directory and always cleans it up
- Requires read access to `/usr/bin/ls` to copy the executable
- The 5-second wait is intentional for observation/monitoring purposes
- The trap ensures cleanup happens even if the script is interrupted (e.g.: Ctrl+C)
- All file operations use quoted variables to prevent word splitting issues
- Error messages are sent to stderr for proper logging


## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

LaMont Session

## Last Updated

2026-03-07