# Code Space

A collection of utility scripts and testing examples for various programming tasks.

## Contents

This repository contains the following key files:

- `iplookup.sh`: A Bash script for IP address lookup and analysis
- `archive_and_delete.sh`: A Bash script for archiving and deleting files with verification
- `temp_and_delete.sh`: A Bash script for testing file creation, execution, and cleanup
- `url-processor.ps1`: A PowerShell GUI application for processing and refanging obfuscated URLs
- `email_template.ps1`: A PowerShell GUI script for creating templated Outlook email drafts with predefined content
- `encrypted_attachment_email_template.ps1`: An enhanced PowerShell script for secure encrypted attachment notification emails
- `python-test.py`: A Python test suite demonstrating data types and operations

## IP Lookup Script

### Description
The IP lookup script (`iplookup.sh`) retrieves geographical and network information for IP addresses using five services:
- IPinfo.io - Provides basic geographical and network information
- IPQualityScore (IPQS) - Provides additional IP intelligence and threat assessment (optional)
- MaxMind GeoIP2 - Provides high-accuracy geolocation and network data (optional, requires account)
- GreyNoise - Provides Threat Actor intelligence, internet scanning heuristics, known malicious IP detection
- VirusTotal - Provides threat intelligence and malicious IP detection (optional)

### Features
- Supports both IPv4 and IPv6 addresses with strict input validation; errors if the format is incorrect.
- Automatic detection and usage of API tokens for all services from environment variables, ~/.iplookup.conf config file, or interactive input prompt.
- Interactive prompt mode – run iplookup.sh without arguments to be prompted for an IP address.
- Non-interactive mode with `--no-prompt` flag for CI/automation use (prevents hangs on missing tokens).
- Quiet mode (`-q|--quiet`) to suppress non-error output; useful for scripting and automation.
- Verbose mode (`-v|--verbose`) for detailed debug output including failure diagnostics.
- Custom config file support via `-c|--config FILE` to override default `~/.iplookup.conf`.
- API calls include a 10-second timeout and comprehensive HTTP error handling.
- Displays actual API error responses (HTTP status codes and server messages) instead of generic curl exit codes.
- Detection and reporting of rate limiting, empty responses, and failures for each service.
- Pretty-prints JSON results using jq if installed; otherwise outputs raw JSON.
- All API lookups configured independently and optional.
- Secure handling of tokens (masked when entering interactively).
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
export IPINFO_TOKEN="your_ipinfo_token"          # For IPinfo.io service
export IPQS_KEY="your_ipqs_api_key"              # For IPQualityScore service (optional)
export MAXMIND_ACCOUNT_ID="your_account_id"      # For MaxMind GeoIP2 (optional)
export MAXMIND_KEY="your_license_key"            # For MaxMind GeoIP2 (optional)
export GREYNOISE_KEY="your_greynoise_key"        # For GreyNoise service (optional)
export VIRUSTOTAL_KEY="your_virustotal_key"      # For VirusTotal service (optional)
```

2. Configuration file:
Create `~/.iplookup.conf` with:
```bash
IPINFO_TOKEN="your_ipinfo_token"          # For IPinfo.io service
IPQS_KEY="your_ipqs_api_key"              # For IPQualityScore service (optional)
MAXMIND_ACCOUNT_ID="your_account_id"      # For MaxMind GeoIP2 (optional)
MAXMIND_KEY="your_license_key"            # For MaxMind GeoIP2 (optional)
GREYNOISE_KEY="your_greynoise_key"        # For GreyNoise service (optional)
VIRUSTOTAL_KEY="your_virustotal_key"      # For VirusTotal service (optional)
```

3. Interactive input:
If no tokens are found in environment variables or the configuration file, the script will prompt you to enter them manually during execution (unless `--no-prompt` is used). You can:
- Choose to enter an IPinfo.io token (Bearer token authentication)
- Choose to enter an IPQualityScore API key
- Choose to enter a VirusTotal API key
- Choose to enter MaxMind license key and account ID
- Choose to enter a GreyNoise API key
- Skip all to use the services without authentication

Note: The script works without API tokens but with rate limitations. Using API tokens provides higher rate limits and additional features. The script will use the first available token it finds in the order: environment variables → configuration file → manual input. For MaxMind, both account ID and license key are required to make authenticated requests.

### Usage
```bash
./iplookup.sh <IP_ADDRESS>              # Look up specific IP address
./iplookup.sh                           # Interactive prompt for IP address
./iplookup.sh -q                        # Quiet mode (suppress non-error output)
./iplookup.sh -v                        # Verbose mode (detailed debug output)
./iplookup.sh -c ~/.custom.conf         # Use alternate config file
./iplookup.sh --config /path/to/conf    # Use alternate config file (long form)
./iplookup.sh --no-prompt               # Non-interactive mode (skip token prompts)
./iplookup.sh -h                        # Show help message
./iplookup.sh --help                    # Show help message
```

### Command-Line Options
- `-q, --quiet` — Suppress non-error output; useful for scripting and automation
- `-v, --verbose` — Print verbose debug information including failure reasons
- `-c, --config FILE` — Specify an alternate configuration file (overrides `~/.iplookup.conf`)
- `--no-prompt` — Non-interactive mode; do not prompt for missing API tokens (useful in CI/automation)
- `-h, --help` — Display help message and exit

### Output Format
The script queries multiple services in order and displays results for each. All results are formatted as JSON (pretty-printed if `jq` is installed):

1. **IPinfo.io** (always queried):
   - Geographical location (city, region, country)
   - Network information (ASN, organization)
   - Coordinates (latitude/longitude)
   - IPinfo Bearer token authentication (if provided)

2. **IPQualityScore (IPQS)** (if API key provided):
   - Fraud score and risk assessment
   - VPN/Proxy detection
   - Additional threat intelligence
   - Optional; skipped if no API key configured

3. **MaxMind GeoIP2** (if account ID and license key provided):
   - High-accuracy geolocation data
   - Network information (organization, ISP)
   - Security data (proxy detection, VPN, etc.)
   - HTTP Basic Auth with account ID and license key
   - Optional; requires both account ID and license key

4. **GreyNoise** (with API key or free community API):
   - Threat Actor intelligence
   - Known malicious IP detection
   - Internet scanning behavior analysis
   - Supports authenticated API (with key) and free community API (50 searches/week limit)
   - Falls back to community API if token-based query fails

5. **VirusTotal** (if API key provided):
   - Threat intelligence from multiple AV vendors
   - Known malicious activity detection
   - x-apikey header authentication
   - Optional; queried last after all other services

**Error Handling**: If any API query fails, the actual HTTP status code and server error message are displayed (e.g., "Error: HTTP 403 - Unauthorized") instead of generic curl exit codes, making diagnosis straightforward.

All results are displayed as JSON. When `jq` is installed, results are pretty-printed for readability; otherwise, raw JSON is displayed.

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

## Email Template Script

### email_template.ps1 - Generic Email Template

#### Description
The email template script (`email_template.ps1`) is a Windows PowerShell GUI application that creates Outlook email drafts with customizable prefilled content, subject lines, and recipient information. It provides a template-based approach for creating consistent, professional emails with predefined body text and signature integration.

#### Features
- **Modern GUI Interface**: User-friendly Windows Forms interface for entering email details
- **Customizable Subject Prefix**: Prefilled subject line with customizable prefix (e.g., "[Email Released]:")
- **Predefined Email Body**: Support for custom HTML email templates with automatic signature integration
- **Recipient Management**: Simple input field for specifying recipient email addresses (To field)
- **CC Support**: Script-level constant for automatic CC'ing to designated recipients
- **Signature Integration**: Automatically loads and preserves user's Outlook default signature
- **Input Validation**: Validates that required recipient information is provided before creating draft
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Outlook Integration**: Seamless integration with Microsoft Outlook COM interface
- **Professional UI**: Clean, intuitive interface with clear labels and organized layout

#### Prerequisites
- Windows operating system
- PowerShell 5.1 or higher
- Microsoft Outlook installed and configured
- .NET Framework (typically pre-installed on Windows)

#### Installation
1. Clone the repository (if not already done):
```powershell
git clone https://github.com/lamontsession/code-space.git
cd code-space
```

2. The script is ready to use - no additional installation required

#### Configuration
To customize the script for your organization, edit the script-level constants:

```powershell
# Script-level constants at the top of the file
$CC_EMAIL_ADDRESS = 'your-email@example.com'  # Change this to your CC email
```

You can also customize the subject prefix and email body template within the script.

#### Usage
Run the script from PowerShell:
```powershell
.\email_template.ps1
```

Or right-click the file and select "Run with PowerShell"

#### How to Use
1. **Launch the application** by running the PowerShell script
2. **Enter recipient addresses** in the first field (To field) - can include multiple addresses separated by semicolons
3. **Modify the subject** if needed (prefix is automatically added if not present)
4. **Click OK** to create the Outlook draft
5. **Review the draft** in Outlook, add attachments if needed, and send when ready
6. **Click Cancel** to close without creating an email

#### Example Workflow

**User Input:**
- Recipients: `user1@example.com; user2@example.com`
- Subject: `Monthly Report`

**Result:**
- Outlook draft created with:
  - To: `user1@example.com; user2@example.com`
  - CC: `your-email@example.com`
  - Subject: `[Automated Email]: Monthly Report`
  - Body: Prefilled template text + user's signature

#### Use Cases
- **Administrative Communications**: Create consistent internal communications with standardized formatting
- **Security Notifications**: Send templated security alerts or notifications with consistent messaging
- **Policy Communications**: Distribute organizational policies with predefined legal disclaimers
- **Bulk Notifications**: Quickly send notifications to multiple recipients with the same template
- **Standardized Workflows**: Ensure all outbound communications maintain consistent branding and format

#### Technical Details
- Built using Windows Forms (.NET Framework)
- Uses Outlook COM interface for seamless integration
- HTML-based email body support with signature preservation
- Input validation using PowerShell string operations
- Proper COM object cleanup and resource management
- Subject prefix logic prevents duplicate prefixes

#### Important Notes
- Microsoft Outlook must be installed and configured with an email account
- The script creates a draft - emails are not automatically sent
- Subject prefix is automatically added if not already present
- User's Outlook signature is automatically included (if configured in Outlook)
- CC field is controlled by the script constant - modify as needed
- The script displays the email draft for review before sending

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

2026-01-28