## Shodan IP Lookup — shodan_iplookup.py

### Description
A focused Python tool that queries the Shodan Host API for detailed information about a single IP address (IPv4 or IPv6). Designed for interactive and non-interactive use, it validates input, loads configuration safely, and pretty-prints JSON output using jq when available.

### Features
- IPv4 and IPv6 validation (rejects empty/whitespace CLI args and invalid input)
- Configurable Shodan API key via:
  - Config file (~/.shodan_iplookup.conf by default)
  - Environment variable SHODAN_IPLOOKUP_CONFIG to point to an alternate config file
- Config file format (INI-style):
  ```
  [shodan]
  api_key = YOUR_API_KEY
  ```
- Uses official shodan Python client (pip package `shodan`) for host lookups
- Pretty JSON output:
  - Uses `jq` if available on PATH
  - Falls back to Python's json.dumps(indent=2, sort_keys=True) if jq is absent or fails
- Clear error handling for config errors, invalid IPs, and Shodan API errors
- Exit codes and stderr messages for automated workflows and logging

### Prerequisites
- Python 3.x
- pip package: shodan (`pip install shodan`)
- `jq` optional, recommended for nicer terminal output
- Network access to Shodan API

### Installation
1. Install dependencies:
```bash
python3 -m pip install shodan
# optionally install jq via your package manager (apt, brew, choco, etc.)
```
2. Place `shodan_iplookup.py` under your scripts directory and make executable if desired:
```bash
chmod +x shodan_iplookup.py
```

### Configuration
- Default config path: `~/.shodan_iplookup.conf`
- To use a different config file path set:
```bash
export SHODAN_IPLOOKUP_CONFIG="/path/to/config.conf"
```
- Config file example:
```ini
[shodan]
api_key = YOUR_API_KEY
```

Notes:
- The tool avoids wrapping an existing Path object when the env var is not set — this prevents nested Path bugs.
- If the config file is missing or the api_key is not present, the script exits with a clear stderr message.

### Usage
- Single CLI argument (non-interactive):
```bash
./shodan_iplookup.py 1.2.3.4
./shodan_iplookup.py 2001:db8::1
```
- Interactive prompt (runs without CLI args):
```bash
./shodan_iplookup.py
# prompts: Enter an IP address to look up (or 'q' to quit):
```

Examples:
- Lookup IPv4:
```bash
python3 shodan_iplookup.py 8.8.8.8
```
- Lookup IPv6:
```bash
python3 shodan_iplookup.py 2001:4860:4860::8888
```

### Output
- Full Shodan host JSON payload printed to stdout, pretty-printed by jq if available.
- Key fields typically present:
  - ip_str, hostnames, os, org, isp, asn, ports, data (service banners), vulns/CVEs (if available), location data

### Error Handling & Exit Codes
- Missing/invalid config file → stderr message and exit code 1
- Missing api_key in config → stderr message and exit code 1
- Invalid/empty CLI IP argument → stderr message and exit code 1
- Invalid interactive input → stderr and exit
- Shodan API errors (rate limited, invalid key, etc.) are printed to stderr and exit with code 1

### Troubleshooting
- "Config file not found" → create `~/.shodan_iplookup.conf` with the [shodan] section
- "no 'api_key' found" → ensure `api_key = YOUR_API_KEY` under [shodan]
- "jq not installed" → optional: install jq for improved formatting; otherwise script falls back to Python formatting
- Shodan APIError messages are relayed directly to stderr—verify API key and account limits at https://account.shodan.io/

### Usability Insights
- Use the script in automation by invoking with a CLI argument; the script validates input early and fails fast with meaningful exit codes.
- Use SHODAN_IPLOOKUP_CONFIG to test with alternate credential files without changing the default config.
- Combining with jq filters is straightforward; if jq is installed, the script automatically pipes JSON into jq for clearer reading.
- The script was designed to be lightweight and explicit — it performs a single host lookup and returns the full Shodan host document so downstream tooling can consume or filter the JSON as needed.

### Security Best Practices
- Do not commit your API key to source control. Use the config file with restrictive permissions (chmod 600).
- The script prints Shodan error messages to stderr to aid debugging but avoids leaking local secrets.
- Network calls should be run in trusted environments; the full host payload may contain service banners and other sensitive metadata.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

LaMont Session

## Last Updated

2026-03-07