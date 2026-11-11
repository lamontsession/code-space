# IP Lookup Script

## Description

`iplookup.sh` retrieves geographical, network, and threat-intelligence information for a single IPv4 or IPv6 address using seven integrated services:

- SANS Internet Storm Center / DShield
- Shodan InternetDB
- IPinfo
- IPQualityScore (IPQS)
- GreyNoise
- OpenSourceMalware (OSM)
- Pulsedive

Providers are queried sequentially. Lookups depend on the address family and available API credentials.

A missing record, zero reports, or a successful API request does not establish that an IP address is safe.

## Features

- Validates and normalizes IPv4 and IPv6 addresses using Python's `ipaddress` module.
- Rejects hostnames, URLs, CIDR ranges, scoped IPv6 addresses, and IPv4 addresses with leading zeros.
- Normalizes carriage returns in validator output to prevent incorrect address-family comparisons.
- Protects the validated IP address and address-family variables from subsequent reassignment.
- Supports credentials through environment variables, trusted Bash configuration files, and optional interactive entry.
- Preserves backward-compatible credential aliases.
- Supports interactive, noninteractive, quiet, and verbose operation.
- Continues subsequent provider lookups after an individual request fails.
- Reports HTTP failures, transport failures, and empty successful-response bodies.
- Uses a 5-second connection timeout and 20-second overall timeout per request.
- Requires HTTPS, does not automatically follow redirects, and disables curl's default configuration file.
- Pretty-prints JSON with `jq` when available; otherwise prints raw response bodies.
- Returns exit codes suitable for automation.

The script does not implement automatic retries, exponential backoff, configurable retry limits, a custom User-Agent, or provider-specific interpretation of HTTP 2xx error objects.

## Prerequisites

Required:

- Bash
- `curl`
- `python3`

Optional:

- `jq` for JSON formatting

Run the script directly or with `bash`, not `sh`.

## Installation

```bash
git clone https://github.com/lamontsession/code-space.git
cd code-space/iplookup
chmod +x iplookup.sh
```

Check Bash syntax:

```bash
bash -n ./iplookup.sh
```

Syntax checks do not validate API availability, credentials, or runtime behavior.

## Provider Support

Providers run in this order:

| Order | Provider | Address-family behavior | Credential behavior |
|---|---|---|---|
| 1 | SANS ISC/DShield | IPv4 only in this integration | No key used |
| 2 | Shodan InternetDB | IPv4 only in this integration | No key used |
| 3 | IPinfo | IPv4 and IPv6 attempted | Bearer token if configured; otherwise unauthenticated |
| 4 | IPQualityScore | Either validated family attempted when configured | Key required to run |
| 5 | GreyNoise | IPv4 only in this integration | Authenticated IP lookup with a key; otherwise unauthenticated Community attempt |
| 6 | OpenSourceMalware | Either validated family attempted when configured | Key required to run |
| 7 | Pulsedive | IPv4 and IPv6 attempted | Configured key or unauthenticated attempt |

"Attempted" describes script behavior, not guaranteed provider or subscription support.

The script runs without API keys, but unauthenticated requests can fail because of authentication requirements, rate limits, or access restrictions.

## Configuration

### Default Location

The default configuration is:

```text
${PWD}/.iplookup.conf
```

This is the current working directory, not automatically the home directory or the script directory.

To use a home-directory configuration:

```bash
./iplookup.sh --config "$HOME/.iplookup.conf" --no-prompt 8.8.8.8
```

A missing default configuration is allowed. An explicitly requested file must exist and be a readable regular file.

### Environment Variables

```bash
export IPINFO_TOKEN="your_ipinfo_token"
export IPQS_API_KEY="your_ipqs_api_key"
export GREYNOISE_API_KEY="your_greynoise_api_key"
export OSM_API_KEY="your_osm_api_key"
export PULSEDIVE_API_KEY="your_pulsedive_api_key"
```

Configure only the credentials you intend to use.

### Configuration File

Create `.iplookup.conf` in your working directory:

```bash
IPINFO_TOKEN="your_ipinfo_token"
IPQS_API_KEY="your_ipqs_api_key"
GREYNOISE_API_KEY="your_greynoise_api_key"
OSM_API_KEY="your_osm_api_key"
PULSEDIVE_API_KEY="your_pulsedive_api_key"
```

Protect the file:

```bash
chmod 600 .iplookup.conf
```

Add it to `.gitignore`:

```gitignore
.iplookup.conf
```

Configuration files are executable Bash code. Only load trusted files. Do not assign `IP_VERSION` or `ip_address`; these are read-only before configuration loads.

### Backward-Compatible Aliases

| Canonical variable | Alias |
|---|---|
| `IPINFO_TOKEN` | None |
| `IPQS_API_KEY` | `IPQS_KEY` |
| `GREYNOISE_API_KEY` | `GREYNOISE_KEY` |
| `OSM_API_KEY` | `OSM_KEY` |
| `PULSEDIVE_API_KEY` | `PULSEDIVE_KEY` |

The first nonempty canonical value takes precedence over its alias after surrounding whitespace is trimmed.

### Credential Resolution

1. Environment variables are inherited.
2. The configuration file is sourced, and assignments can overwrite environment values.
3. Canonical names and aliases are resolved.
4. Missing credentials can be entered interactively where supported.

Configuration does not automatically have lower priority than the environment. To preserve an environment value:

```bash
IPINFO_TOKEN="${IPINFO_TOKEN:-your_default_token}"
```

### Interactive Entry

When standard input is a terminal and prompting is enabled, missing credentials can be entered for:

- IPinfo
- IPQualityScore
- OpenSourceMalware
- GreyNoise, for IPv4 targets only

Prompts can be declined, and credential entry is hidden. Pulsedive keys must come from configuration or environment variables; no Pulsedive credential prompt is provided.

Credentials are checked for embedded carriage returns and newlines before and after prompting.

## Usage

Place options before the target address. Only one target is accepted.

### IPv4 Lookup

```bash
./iplookup.sh 8.8.8.8
```

### IPv6 Lookup

```bash
./iplookup.sh --no-prompt 2001:4860:4860::8888
```

SANS, Shodan InternetDB, and GreyNoise are skipped for IPv6 by this integration.

### Interactive Mode

```bash
./iplookup.sh
```

Prompts for an IP address and offers supported missing-credential prompts.

### Noninteractive Mode

```bash
./iplookup.sh --no-prompt 8.8.8.8
```

Disables address and credential prompts. A target is required. Prompting is also disabled when standard input is not a terminal.

### Quiet Mode

```bash
./iplookup.sh --quiet 8.8.8.8
```

Suppresses headings, informational messages, debug output, and prompts. Successful bodies remain on standard output; errors remain on standard error.

### Verbose Mode

```bash
./iplookup.sh --verbose --no-prompt 8.8.8.8
```

Reports the validated family and target using shell-escaped formatting, configuration-loading information, and completed-request HTTP statuses. Quiet mode takes precedence.

### Alternate Configuration

```bash
./iplookup.sh --config "$HOME/.iplookup.conf" --no-prompt 8.8.8.8
./iplookup.sh --config="$HOME/.iplookup.conf" --no-prompt 8.8.8.8
```

### Help

```bash
./iplookup.sh --help
```

## Command-Line Options

| Option | Behavior |
|---|---|
| `-q`, `--quiet` | Suppresses headings, informational messages, diagnostics, and prompts |
| `-v`, `--verbose` | Additional diagnostics to standard error unless quiet |
| `-c FILE`, `--config FILE` | Loads a trusted alternate configuration |
| `--config=FILE` | Alternate configuration syntax |
| `--no-prompt` | Disables all interactive prompts |
| `-h`, `--help` | Displays help and exits successfully |
| `--` | Ends option parsing |

## Output

Successful bodies go to standard output. Headings, informational messages, diagnostics, and errors go to standard error.

With `jq`, each body is formatted as JSON when possible. If formatting fails or `jq` is absent, the raw body is printed. Responses are not guaranteed to be JSON.

Results are consecutive response bodies, not one combined JSON document. Standard output has no structured provider labels.

Separate results and diagnostics:

```bash
./iplookup.sh --no-prompt 8.8.8.8 > results.txt 2> diagnostics.log
```

Capture combined human-readable output:

```bash
./iplookup.sh --no-prompt 8.8.8.8 > lookup-report.txt 2>&1
```

## Provider-Specific Behavior

### SANS Internet Storm Center / DShield

Uses this IP-summary endpoint:

```text
https://isc.sans.edu/api/ip/<IP_ADDRESS>?json
```

IPv4 only, no key used, and HTTP 404 counts as failure rather than an allowed no-record result.

### Shodan InternetDB

IPv4 only, no key used. Displays the returned record without additional enrichment. HTTP 404 is an allowed no-record result.

### IPinfo

Always attempted for a validated target. Uses `Authorization: Bearer` when a token is configured; otherwise attempts the same endpoint without authentication.

### IPQualityScore

Runs only with a key. Python URL-encodes the key before it is placed in the request path.

### GreyNoise

For IPv4:

1. With a key, attempts the authenticated IP endpoint.
2. On failure or an allowed no-record result, attempts Community using the same key.
3. Without a key, attempts Community without authentication.

An authenticated failure remains counted even if Community succeeds.

### OpenSourceMalware

Runs only with a key. Uses Bearer authentication and sends `report_type=ip` with the target as the resource identifier.

### Pulsedive

Always attempted for a validated target, using a key when configured. Does not retry without a key after authenticated failure.

## Error Handling and Limitations

### HTTP Handling

| Response | Handling |
|---|---|
| HTTP 2xx, nonempty body | Prints body and counts request as successful |
| HTTP 2xx, empty body | Counts as failure |
| HTTP 404 from Shodan, GreyNoise, or Pulsedive | Allowed no-record result |
| HTTP 404 from other providers | Counts as failure |
| Other non-2xx statuses, including 429 and 5xx | Counts as failure and displays any body |

HTTP 2xx API-level error objects are not interpreted as failures.

### Transport Failures

Connection, TLS, DNS, and timeout failures are reported with provider name and curl exit code. Subsequent providers are still attempted.

### Timeouts and Retries

- Connection timeout: 5 seconds.
- Overall timeout: 20 seconds per request.
- No automatic retries or retry-delay settings.
- GreyNoise Community fallback is a separate lookup, not a general retry mechanism.

### Request Configuration

- HTTPS required.
- Redirects not automatically followed.
- curl default configuration disabled.
- No custom User-Agent.
- Request URLs not intentionally included in script diagnostics.

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | All attempted lookups succeeded or returned allowed no-record responses |
| `1` | One or more attempted lookups failed |
| `2` | Invalid input, missing dependency, or explicitly handled configuration error |

Skipped providers do not count as failures. Unhandled shell or configuration errors can terminate with a different status because configuration executes Bash code and strict mode is enabled.

```bash
./iplookup.sh --no-prompt 8.8.8.8
status=$?
printf 'Exit status: %s\n' "$status"
```

## Troubleshooting

### IPv4 Providers Unexpectedly Skipped

```bash
./iplookup.sh --verbose --no-prompt 8.8.8.8
```

Expected validation diagnostic:

```text
(verbose) Validated target: IP_VERSION=4 ip_address=8.8.8.8
```

The script normalizes carriage returns in validator output and protects the validated variables from reassignment.

### Read-Only Variable Error

Remove `IP_VERSION` and `ip_address` assignments from configuration. Keep configuration focused on supported credentials.

### Test Without Normal Configuration

```bash
empty_config=$(mktemp)
./iplookup.sh --verbose --no-prompt --config "$empty_config" 8.8.8.8
status=$?
rm -f -- "$empty_config"
printf 'Exit status: %s\n' "$status"
```

`/dev/null` is rejected because configuration must be a readable regular file.

### Failed Requests

Review standard error for provider name, HTTP status, response body, or curl exit code. Check credentials, subscription access, connectivity, and provider limits. Avoid sharing unsanitized responses or shell traces.

## Security Considerations

- Configuration files execute with the invoking user's privileges.
- Hidden credential entry does not prevent credentials from residing in process memory.
- Some credentials are passed in command arguments and may be visible to sufficiently privileged local observers.
- Response bodies are displayed without secret redaction.
- Avoid `bash -x` with credentials configured; tracing can expose secrets.
- Do not commit credential files.
- Providers receive the target IP. Consider investigation sensitivity and organizational policy before submitting indicators.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Author

LaMont Session

## Last Updated

2026-11-11
