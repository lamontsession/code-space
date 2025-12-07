# Code Space

A collection of utility scripts and testing examples for various programming tasks.

## Contents

This repository contains the following key files:

- `iplookup.sh`: A Bash script for IP address lookup and analysis
- `archive_and_delete.sh`: A Bash script for archiving and deleting files with verification
- `temp_and_delete.sh`: A Bash script for testing file creation, execution, and cleanup
- `url-processor.ps1`: A PowerShell GUI application for processing and refanging obfuscated URLs
- `python-test.py`: A Python test suite demonstrating data types and operations

## IP Lookup Script

### Description
The IP lookup script (`iplookup.sh`) retrieves geographical and network information for IP addresses using two services:
- IPinfo.io - Provides basic geographical and network information
- IPQualityScore - Provides additional IP intelligence and threat assessment (optional)
- GreyNoise - Provides Threat Actor intelligence, internet scanning heuristics, known malicious IP detection.

### Features
- Supports both IPv4 and IPv6 addresses with strict input validation; errors if the format is incorrect.
- Automatic detection and usage of API tokens for all services from environment variables, ~/.iplookup.conf config file, or interactive input prompt.
- Interactive prompt mode – run iplookup.sh without arguments to be prompted for an IP address.
- API calls include a 10-second timeout and error handling for failed requests.
- Detection and reporting of rate limiting, empty responses, and failures for each service.
- Pretty-prints JSON results using jq if installed; otherwise outputs raw JSON.
- Optional GreyNoise and IPQualityScore lookups (configured independently).
- Secure handling of tokens (masked when entering interactively).
- Displays help message with -h or --help flags.
- Requires only curl (mandatory) and jq (optional for pretty printing).

### Prerequisites
- `bash` shell
- `curl` for making HTTP requests
- `jq` (optional but recommended) for JSON formatting

### Installation
1. Clone the repository:
```bash
git clone https://github.com/lamontsession/code-space.git
cd code-space
```

2. Make the script executable:
```bash
chmod +x iplookup.sh
```

### Configuration
You can configure API tokens in three ways:

1. Environment variables:
```bash
export IPINFO_TOKEN="your_ipinfo_token"  # For IPinfo.io service
export IPQS_API_KEY="your_ipqs_api_key"  # For IPQualityScore service (optional)
export GREYNOISE_API_KEY="your_greynoise_key" # GreyNoise (non-key requirement community edition available)
```

2. Configuration file:
Create `~/.iplookup.conf` with:
```bash
IPINFO_TOKEN="your_ipinfo_token"  # For IPinfo.io service
IPQS_API_KEY="your_ipqs_api_key"  # For IPQualityScore service (optional)
GREYNOISE_API_KEY="your_greynoise_key" # For GreyNoise service (non-key requirement community edition available)
```

3. Interactive input:
If no tokens are found in environment variables or the configuration file, the script will prompt you to enter them manually during execution. You can:
- Choose to enter an IPinfo.io token
- Choose to enter an IPQualityScore API key
- Choose to enter an GreyNoise API key
- Skip all to use the services without authentication

Note: The script works without API tokens but with rate limitations. Using API tokens provides higher rate limits and additional features. The script will use the first available token it finds in the order: environment variables → configuration file → manual input.

### Usage
```bash
./iplookup.sh <IP_ADDRESS>    # Look up specific IP address
./iplookup.sh                 # Interactive prompt for IP address
./iplookup.sh -h             # Show help message
./iplookup.sh --help        # Show help message
```

### Output Format
The script provides:
1. IPinfo.io results showing:
   - Geographical location (city, region, country)
   - Network information (ASN, organization)
   - Coordinates (latitude/longitude)

2. IPQualityScore results (if API key provided) showing:
   - Fraud score and risk assessment
   - VPN/Proxy detection
   - Additional threat intelligence

3. GreyNoise results showing (both via API key and free community API(50 searches per week limit)):
   - Geographical location (city, region, country)
   - Behavioral intelligence
   - Threat intelligence

Results are formatted as pretty-printed JSON when `jq` is installed, or raw JSON otherwise.

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

## URL Processor Script

### Description
The URL processor script (`url-processor.ps1`) is a Windows PowerShell GUI program designed to process and "refang" obfuscated URLs commonly found in security reports, threat intelligence feeds, and email security investigations. It converts defanged/obfuscated URLs back to their original, clickable format.

### Features
- **Modern GUI Interface**: User-friendly Windows Forms interface with input and output panels
- **Multiple Input Formats**: Supports various input formats:
  - Newline-separated URLs (one per line)
  - Space-separated URLs
  - Brace-wrapped format: `{None | url} {None | url}`
- **Comprehensive Refanging**: Automatically converts multiple obfuscation patterns:
  - `[%%]` → `.` 
  - `[.]` → `.`
  - `[dot]` and `[DOT]` → `.`
  - `hxxp://` and `hxxps://` → `http://` and `https://`
  - `hxxp` → `http`
  - `[:]` → `:`
  - `[@]` and `[at]` → `@` (for email addresses)
- **Export Functionality**: Save processed URLs to timestamped text files
- **Clipboard Integration**: One-click copy of processed URLs to clipboard
- **Duplicate Removal**: Automatically removes duplicate URLs from output
- **URL Counter**: Real-time display of processed URL count
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Professional UI**: Clean layout with separate input/output sections and button panel

### Prerequisites
- Windows operating system
- PowerShell 5.1 or higher
- .NET Framework (typically pre-installed on Windows)

### Installation
1. Clone the repository (if not already done):
```powershell
git clone https://github.com/lamontsession/code-space.git
cd code-space
```

2. The script is ready to use - no additional installation required

### Usage
Run the script from PowerShell:
```powershell
.\url-processor.ps1
```

Or right-click the file and select "Run with PowerShell"

### How to Use
1. **Launch the application** by running the PowerShell script
2. **Paste URLs** into the top input box in any of these formats:
   - One URL per line
   - Space-separated URLs
   - Brace-wrapped format from security tools
3. **Click "Process URLs"**
4. **Review results** in the bottom output box
5. **Copy to clipboard** or **Export to file** as needed

### Example Input/Output

**Input (Obfuscated):**
```
{None | https://malicious[.]example[.]com/payload}
hxxps://phishing[dot]site[.]org
suspicious[@]domain[.]net
```

**Output (Refanged):**
```
https://malicious.example.com/payload
https://phishing.site.org
suspicious@domain.net
```

### Button Functions
- **Process URLs**: Converts obfuscated URLs to standard format
- **Clear All**: Clears both input and output fields
- **Copy Output**: Copies processed URLs to clipboard for easy pasting
- **Export to File**: Saves processed URLs to a timestamped text file

### Use Cases
- **Security Analysis**: Convert obfuscated URLs from security reports for investigation
- **Threat Intelligence**: Process URLs from threat feeds and indicators of compromise (IoCs)
- **Email Security**: Refang URLs from quarantined email reports
- **Incident Response**: Quickly process multiple suspicious URLs for analysis
- **Malware Analysis**: Convert defanged URLs from malware samples or sandboxes
- **Security Operations**: Streamline URL processing in SOC workflows

### Technical Details
- Built using Windows Forms (.NET Framework)
- Uses regex-based pattern matching for URL refanging
- UTF-8 encoding for file exports
- Modal dialog interface for clean user experience
- Handles multiple URL obfuscation standards

### Important Notes
- Refanged URLs become clickable and may lead to malicious sites - use caution
- Always process suspicious URLs in a safe environment (isolated VM, sandbox, etc.)
- The script does not validate if URLs are malicious - it only reformats them
- Exported files are timestamped (e.g., `processed_urls_20251205_143022.txt`)
- The application removes duplicate URLs automatically from the output

## Python Test Suite

### Description
The Python test suite (`python-test.py`) demonstrates various Python data types, operations, and testing practices using the unittest framework.

### Prerequisites
- Python 3.x

### Running Tests
```bash
python3 python-test.py
```

The test suite covers:
- Boolean operations
- Numeric types (int, float)
- String operations
- Type conversions
- Arithmetic operations

## Contributing

1. Fork the repository
2. Create your additions branch (`git checkout -b additions/programV2`)
3. Commit your changes (`git commit -m 'Added some new features'`)
4. Push to the branch (`git push origin additions/programV2`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

LaMont Session

## Last Updated

2025-12-05