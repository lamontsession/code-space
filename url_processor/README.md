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

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

LaMont Session

## Last Updated

2026-03-07
