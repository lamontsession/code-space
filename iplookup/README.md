# IP Lookup Script

## Description
The IP lookup script (`iplookup.sh`) retrieves geographical and network information for IP addresses using currently five services:
- **IPinfo.io** - Provides basic geographical and network information
- **IPQualityScore (IPQS)** - Provides additional IP intelligence and threat assessment (optional)
- **GreyNoise** - Provides Threat Actor intelligence, internet scanning heuristics, known malicious IP detection
- **OpenSourceMalware (OSM)** - Provides community threat reputation and malicious IP checks (optional)
- **Pulsedive** - Provides threat intelligence indicator lookup with optional unauthenticated access
- **Shodan InternetDB** - Provides service/port information and open port enumeration (public, no auth required)

### Features
- Automatic detection and usage of API tokens for supported services from environment variables, `~/.iplookup.conf` config file, or interactive input prompt
- Interactive prompt mode – run `iplookup.sh` without arguments to be prompted for an IP address
- Non-interactive mode with `--no-prompt` flag for CI/automation use (prevents hangs on missing tokens)
- Quiet mode (`-q|--quiet`) to suppress non-error output; useful for scripting and automation
- Verbose mode (`-v|--verbose`) for detailed debug output including failure diagnostics
- Custom config file support via `-c|--config FILE` to override default `~/.iplookup.conf`
- **Improved Error Handling**:
  - User-Agent header on all requests for better server telemetry
  - Automatic retry logic with exponential backoff (2^n seconds) for transient errors (429 Rate Limit, 5xx Server Errors)
  - Configurable max retry attempts (default: 3 attempts)
  - Clear distinction between client errors (400-499) and transient errors (429, 5xx)
  - 404 errors treated as expected fallbacks (suppressed in quiet mode, verbose warning available)
  - Empty response bodies displayed as "(no body)" instead of blank for clarity
  - Request URLs included in error messages for debugging
- API calls include a 10-second timeout and comprehensive HTTP error handling
- Displays actual API error responses (HTTP status codes and server messages) instead of generic curl exit codes
- Detection and reporting of rate limiting, empty responses, and failures for each service
- Pretty-prints JSON results using jq if installed; otherwise outputs raw JSON
- All API lookups configured independently and optional
- Secure handling of tokens (masked when entering interactively, never echoed in output)
- Requires only curl (mandatory) and jq (optional for pretty printing)


### Prerequisites
- `bash` shell
- `curl` for making HTTP requests
- `jq` (optional but recommended) for JSON formatting


### Installation
1. Clone the repository:
```bash
git clone https://github.com/lamontsession/code-space.git
cd code-space/iplookup
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
export GREYNOISE_KEY="your_greynoise_key"        # For GreyNoise service (optional)
export OSM_KEY="your_osm_api_key"                # For OpenSourceMalware service (optional)
export PULSEDIVE_KEY="your_pulsedive_api_key"    # For Pulsedive service (optional)
```

2. Configuration file:
Create `~/.iplookup.conf` with:
```bash
IPINFO_TOKEN="your_ipinfo_token"          # For IPinfo.io service
IPQS_KEY="your_ipqs_api_key"              # For IPQualityScore service (optional)
GREYNOISE_KEY="your_greynoise_key"        # For GreyNoise service (optional)
OSM_KEY="your_osm_api_key"                # For OpenSourceMalware service (optional)
PULSEDIVE_KEY="your_pulsedive_api_key"    # For Pulsedive service (optional)
```

3. Interactive input:
If no tokens are found in environment variables or the configuration file, the script will prompt you to enter them manually during execution (unless `--no-prompt` is used). You can:
- Choose to enter an IPinfo.io token (Bearer token authentication)
- Choose to enter an IPQualityScore API key
- Choose to enter an OpenSourceMalware (OSM) API key
- Choose to enter a GreyNoise API key
- Skip all to use the services without authentication

Note: The script works without API tokens but with rate limitations. Using API tokens provides higher rate limits and additional features. The script will use the first available token it finds in the order: environment variables → configuration file → manual input.

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


### Command-Line Options
- `-q, --quiet` — Suppress non-error output; useful for scripting and automation
- `-v, --verbose` — Print verbose debug information including failure reasons and retry attempts
- `-c, --config FILE` — Specify an alternate configuration file (overrides `~/.iplookup.conf`)
- `--no-prompt` — Non-interactive mode; do not prompt for missing API tokens (useful in CI/automation)
- `-h, --help` — Display help message and exit

### Output Format
The script queries multiple services in order and displays results for each. All results are formatted as JSON (pretty-printed if `jq` is installed):

1. **Shodan InternetDB** (public API, no authentication required):
   - Open ports enumeration
   - Services and banners
   - CVE information associated with services
   - **Note**: Returns 404 gracefully if IP has no Shodan data

2. **IPinfo.io** (always queried):
   - Geographical location (city, region, country)
   - Network information (ASN, organization)
   - Coordinates (latitude/longitude)
   - IPinfo Bearer token authentication (if provided)

3. **IPQualityScore (IPQS)** (if API key provided):
   - Fraud score and risk assessment
   - VPN/Proxy detection
   - Additional threat intelligence
   - Optional; skipped if no API key configured

4. **GreyNoise** (with API key or free community API):
   - Threat Actor intelligence
   - Known malicious IP detection
   - Internet scanning behavior analysis
   - Supports authenticated API (with key) and free community API (50 searches/week limit)
   - Falls back to community API if token-based query fails (HTTP 404)

5. **OpenSourceMalware (OSM)** (if API key provided):
   - Community threat reputation and malicious IP checks
   - Bearer token authentication
   - Optional; queried after GreyNoise

6. **Pulsedive** (always attempted, with or without key):
   - Indicator lookup for IP addresses
   - Optional authenticated lookup, with unauthenticated fallback
   - Provides additional threat intelligence and context

**Error Handling**: If any API query fails, the actual HTTP status code and server error message are displayed (e.g., "Error: HTTP 403 from https://api.example.com - Unauthorized") instead of generic curl exit codes, making diagnosis straightforward. Transient errors (429, 5xx) are automatically retried with exponential backoff.

All results are displayed as JSON. When `jq` is installed, results are pretty-printed for readability; otherwise, raw JSON is displayed.

### Error Handling & Resilience

**Automatic Retries:**
- Transient errors (HTTP 429 Rate Limit, 5xx Server Errors) trigger automatic retries
- Exponential backoff: 1 second, 2 seconds, 4 seconds (configurable max attempts)
- Silent retries in quiet mode; verbose logging in `-v` mode
- Client errors (4xx except 404) and permanent failures fail immediately

**Degradation:**
- 404 errors on authenticated GreyNoise endpoint → automatic fallback to community API
- Missing API keys → services skipped with informative messages
- Network timeouts → clear error messages with request URLs
- Empty responses → detected and reported separately from malformed JSON

**Security Improvements:**
- User-Agent header identifies requests (prevents blocking by WAF)
- No API tokens echoed to output or logs
- Tokens masked during interactive entry (using `read -rs`)
- Request URLs logged for debugging (aids in troubleshooting)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

LaMont Session

## Last Updated

2026-06-27