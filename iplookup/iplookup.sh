#!/usr/bin/env bash

# Author: LaMont Session
# Date Created: 2025-10-28
# Last Modified: 2026-11-11
#
# Description:
# Retrieve geographical, threat intelligence, and network information
# for an IPv4 or IPv6 address.
#
# Dependencies: bash, curl, python3
# Optional: jq
#
# Default configuration:
#   ${PWD}/.iplookup.conf
#
# Config files are sourced as Bash code. Only use trusted files.

set -euo pipefail

QUIET=0
VERBOSE=0
NO_PROMPT=0
CONFIG_FILE_OVERRIDE=""
CONFIG_EXPLICIT=0
FAILURES=0

show_help() {
    cat <<EOF
Usage: ${0##*/} [OPTIONS] [IP_ADDRESS]

Retrieve geographical, threat intelligence, and network information.

Options:
  -q, --quiet        Suppress headings, prompts, and informational messages
  -v, --verbose      Print additional diagnostics to stderr
  -c, --config FILE  Source a trusted alternate Bash configuration file
      --no-prompt    Never prompt for an IP address or API tokens
  -h, --help         Show this help message

Default configuration:
  .iplookup.conf in the current working directory

Supported configuration variables:
  IPINFO_TOKEN
  IPQS_API_KEY
  GREYNOISE_API_KEY
  OSM_API_KEY
  PULSEDIVE_API_KEY

Backward-compatible aliases:
  IPQS_KEY
  GREYNOISE_KEY
  OSM_KEY
  PULSEDIVE_KEY

When both names are configured, the first nonempty canonical variable wins.

Lookup providers:
  SANS ISC/DShield (IPv4 in this integration; no API key required)
  Shodan InternetDB, IPinfo, IPQualityScore, GreyNoise,
  OpenSourceMalware, and Pulsedive

Exit codes:
  0  All attempted lookups succeeded or returned no record
  1  One or more attempted lookups failed
  2  Invalid input, configuration, or missing dependency

A successful HTTP response is not necessarily a successful API result.
Provider-specific error objects inside HTTP 2xx responses are displayed
but are not currently interpreted as lookup failures.

A missing threat-intelligence record does not establish that an IP is safe.
Configuration files are executed as Bash code; only use trusted files.
Do not assign IP_VERSION or ip_address in configuration files.
EOF
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 2
}

info() {
    if (( QUIET == 0 )); then
        printf '%s\n' "$*" >&2
    fi
    return 0
}

debug() {
    if (( VERBOSE == 1 && QUIET == 0 )); then
        printf '(verbose) %s\n' "$*" >&2
    fi
    return 0
}

heading() {
    if (( QUIET == 0 )); then
        printf '\n--- %s ---\n' "$*" >&2
    fi
    return 0
}

trim_whitespace() {
    local value=${1-}

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    printf '%s' "$value"
}

# Parse command-line options.
while (( $# > 0 )); do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -q|--quiet)
            QUIET=1
            NO_PROMPT=1
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -c|--config)
            (( $# >= 2 )) || die "$1 requires a filename."
            [[ -n "$2" ]] || die "Configuration filename cannot be empty."

            CONFIG_FILE_OVERRIDE=$2
            CONFIG_EXPLICIT=1
            shift 2
            ;;
        --config=*)
            CONFIG_FILE_OVERRIDE=${1#*=}

            [[ -n "$CONFIG_FILE_OVERRIDE" ]] ||
                die "Configuration filename cannot be empty."

            CONFIG_EXPLICIT=1
            shift
            ;;
        --no-prompt)
            NO_PROMPT=1
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            die "Unknown option: $1"
            ;;
        *)
            break
            ;;
    esac
done

(( $# <= 1 )) || die "Expected at most one IP address."

# Obtain the target IP.
if (( $# == 1 )); then
    ip_address=$1
else
    if (( NO_PROMPT == 1 )) || [[ ! -t 0 ]]; then
        die "IP address required in non-interactive mode."
    fi

    if ! read -r -p 'Enter an IP address to look up: ' ip_address; then
        die "Unable to read an IP address."
    fi
fi

ip_address=$(trim_whitespace "$ip_address")
[[ -n "$ip_address" ]] || die "IP address cannot be empty."

# Ensure required dependencies are available.
for dependency in curl python3; do
    command -v "$dependency" >/dev/null 2>&1 ||
        die "'$dependency' is required but not installed."
done

HAS_JQ=0

if command -v jq >/dev/null 2>&1; then
    HAS_JQ=1
else
    info "Note: jq not found; responses will be printed without formatting."
fi

# Validate and normalize IPv4/IPv6 input.
# Return one tab-delimited record to avoid newline-splitting ambiguity.
# Hostnames, URLs, CIDR ranges, scoped IPv6 addresses, and IPv4
# addresses with leading zeros are deliberately not accepted.
if ! parsed_ip=$(
    python3 - "$ip_address" <<'PY'
import ipaddress
import sys

value = sys.argv[1]

try:
    if "%" in value:
        raise ValueError("Scoped IPv6 addresses are not supported")
    address = ipaddress.ip_address(value)
except ValueError as exc:
    print(f"IP validation failed: {exc}", file=sys.stderr)
    sys.exit(1)

sys.stdout.write(f"{address.version}\t{address.compressed}\n")
PY
); then
    die "Invalid IP address: $ip_address"
fi

# Command substitution removes trailing LF characters but can leave CR.
parsed_ip=${parsed_ip//$'\r'/}

case "$parsed_ip" in
    4$'\t'*|6$'\t'*)
        IP_VERSION=${parsed_ip%%$'\t'*}
        ip_address=${parsed_ip#*$'\t'}
        ;;
    *)
        printf 'Error: unexpected IP validator output: %q\n' \
            "$parsed_ip" >&2
        exit 2
        ;;
esac

[[ -n "$ip_address" ]] ||
    die "IP validation returned an empty address."

# Reject unexpected extra fields or embedded newlines.
if [[ "$ip_address" == *$'\t'* || "$ip_address" == *$'\n'* ]]; then
    die "IP validation returned malformed output."
fi

# Prevent configuration files or later functions from changing the
# validated address family or lookup target.
readonly IP_VERSION ip_address

if (( VERBOSE == 1 && QUIET == 0 )); then
    printf '(verbose) Validated target: IP_VERSION=%q ip_address=%q\n' \
        "$IP_VERSION" "$ip_address" >&2
fi

unset parsed_ip

# Load .iplookup.conf from the current working directory unless
# an alternate configuration file was explicitly requested.
if (( CONFIG_EXPLICIT == 1 )); then
    CONFIG_FILE=$CONFIG_FILE_OVERRIDE

    # Resolve relative paths explicitly instead of searching PATH.
    case "$CONFIG_FILE" in
        /*) ;;
        *) CONFIG_FILE="${PWD}/$CONFIG_FILE" ;;
    esac
else
    CONFIG_FILE="${PWD}/.iplookup.conf"
fi

if [[ -e "$CONFIG_FILE" ]]; then
    [[ -f "$CONFIG_FILE" && -r "$CONFIG_FILE" ]] ||
        die "Configuration is not a readable regular file: $CONFIG_FILE"

    debug "Loading trusted configuration: $CONFIG_FILE"

    # Configuration is executable Bash code.
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
elif (( CONFIG_EXPLICIT == 1 )); then
    die "Configuration file not found: $CONFIG_FILE"
else
    debug "No configuration found at $CONFIG_FILE; using environment variables or prompts."
fi

# Resolve credentials from configuration or environment variables.
# Missing optional credentials are not errors.
resolve_api_key() {
    local var
    local result=""

    for var in "$@"; do
        result=$(trim_whitespace "${!var:-}")

        if [[ -n "$result" ]]; then
            printf '%s' "$result"
            return 0
        fi
    done

    return 0
}

# Use canonical names throughout provider lookup blocks.
# Preserve compatibility with older configuration aliases.
IPINFO_TOKEN=$(resolve_api_key IPINFO_TOKEN)
IPQS_API_KEY=$(resolve_api_key IPQS_API_KEY IPQS_KEY)
GREYNOISE_API_KEY=$(resolve_api_key GREYNOISE_API_KEY GREYNOISE_KEY)
OSM_API_KEY=$(resolve_api_key OSM_API_KEY OSM_KEY)
PULSEDIVE_API_KEY=$(resolve_api_key PULSEDIVE_API_KEY PULSEDIVE_KEY)

prompt_for_token() {
    local variable=$1
    local label=$2
    local answer=""
    local value=""

    [[ "$variable" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] ||
        die "Invalid variable name: $variable"

    [[ -z "${!variable:-}" ]] || return 0
    (( NO_PROMPT == 0 )) || return 0
    [[ -t 0 ]] || return 0

    if ! read -r -p "Enter a ${label} token/key? [y/N]: " answer; then
        printf '\n' >&2
        return 0
    fi

    case "$answer" in
        y|Y|yes|YES)
            if ! read -r -s -p "${label} token/key: " value; then
                printf '\n' >&2
                return 0
            fi

            printf '\n' >&2
            value=$(trim_whitespace "$value")
            printf -v "$variable" '%s' "$value"
            ;;
    esac

    return 0
}

validate_api_credentials() {
    local token_name
    local token_value

    for token_name in \
        IPINFO_TOKEN \
        IPQS_API_KEY \
        GREYNOISE_API_KEY \
        OSM_API_KEY \
        PULSEDIVE_API_KEY
    do
        token_value=${!token_name:-}

        if [[ "$token_value" == *$'\r'* ||
              "$token_value" == *$'\n'* ]]; then
            die "$token_name contains an embedded newline."
        fi
    done

    return 0
}

validate_api_credentials

prompt_for_token IPINFO_TOKEN "IPinfo"
prompt_for_token IPQS_API_KEY "IPQualityScore"
prompt_for_token OSM_API_KEY "OpenSourceMalware"

if [[ "$IP_VERSION" == 4 ]]; then
    prompt_for_token GREYNOISE_API_KEY "GreyNoise"
fi

# Pulsedive is attempted without a key when one is not configured.
# Validate credentials again after interactive input.
validate_api_credentials

format_response() {
    local body=$1

    if (( HAS_JQ == 1 )); then
        if printf '%s\n' "$body" | jq . 2>/dev/null; then
            return 0
        fi
    fi

    printf '%s\n' "$body"
}

# Shared HTTP response state.
# Call request functions directly, not through command substitution.
HTTP_STATUS=""
HTTP_BODY=""

http_get() {
    local provider=$1
    local url=$2
    shift 2

    local response=""
    local curl_status=0

    HTTP_STATUS=""
    HTTP_BODY=""

    # --disable must be the first curl option to disable ~/.curlrc.
    # Keep diagnostics on stderr and do not automatically follow redirects.
    # Do not log URLs because some contain API credentials.
    response=$(
        curl --disable \
            --silent \
            --show-error \
            --globoff \
            --connect-timeout 5 \
            --max-time 20 \
            --proto '=https' \
            --header 'Accept: application/json' \
            --write-out $'\n%{http_code}' \
            "$@" \
            --url "$url"
    ) || curl_status=$?

    if (( curl_status != 0 )); then
        printf 'Error: %s transport failure (curl exit %s).\n' \
            "$provider" "$curl_status" >&2
        return 1
    fi

    if [[ "$response" != *$'\n'* ]]; then
        printf 'Error: %s returned no HTTP status trailer.\n' \
            "$provider" >&2
        return 1
    fi

    HTTP_STATUS=${response##*$'\n'}
    HTTP_BODY=${response%$'\n'*}

    # Normalize a possible CR on the status trailer only.
    HTTP_STATUS=${HTTP_STATUS%$'\r'}

    if [[ ! "$HTTP_STATUS" =~ ^[0-9]{3}$ ]]; then
        printf 'Error: %s returned an invalid HTTP status.\n' \
            "$provider" >&2
        return 1
    fi

    debug "$provider: HTTP $HTTP_STATUS"
    return 0
}

# Return:
#   0: Successful HTTP response with a nonempty body
#   1: Lookup error
#   2: Allowed no-record HTTP 404
#
# Provider-specific error objects inside HTTP 2xx responses are displayed
# but are not currently interpreted as failures.
lookup() {
    local provider=$1
    local url=$2
    local allow_no_record=$3
    shift 3

    if ! http_get "$provider" "$url" "$@"; then
        return 1
    fi

    case "$HTTP_STATUS" in
        2??)
            if [[ -z "$HTTP_BODY" ]]; then
                printf 'Error: %s returned an empty response.\n' \
                    "$provider" >&2
                return 1
            fi

            format_response "$HTTP_BODY"
            return 0
            ;;
        404)
            if [[ "$allow_no_record" == yes ]]; then
                info "$provider: no record found for $ip_address; this does not establish that the IP is safe."
                return 2
            fi
            ;;
    esac

    printf 'Error: %s returned HTTP %s.\n' \
        "$provider" "$HTTP_STATUS" >&2

    if [[ -n "$HTTP_BODY" ]]; then
        format_response "$HTTP_BODY" >&2
    fi

    return 1
}

# Track failed lookup attempts without stopping subsequent providers.
# Allowed no-record responses do not count as failures.
run_lookup() {
    local result=0

    lookup "$@" || result=$?

    if (( result == 1 )); then
        FAILURES=$((FAILURES + 1))
    fi

    return 0
}

# SANS Internet Storm Center / DShield IP summary.
# This integration is deliberately restricted to IPv4.
# No API key is required.
# Zero reports or a missing record is not a safety verdict.
# HTTP 404 is not treated as a confirmed no-record result here.
if [[ "$IP_VERSION" == 4 ]]; then
    heading "SANS Internet Storm Center / DShield Results"

    run_lookup \
        "SANS ISC/DShield" \
        "https://isc.sans.edu/api/ip/$ip_address?json" \
        no
else
    info "Skipping SANS ISC/DShield: target $ip_address is IPv$IP_VERSION; this integration is IPv4-only."
fi

# Shodan InternetDB lookup.
# This integration is restricted to IPv4.
if [[ "$IP_VERSION" == 4 ]]; then
    heading "Shodan InternetDB Results"

    run_lookup \
        "Shodan InternetDB" \
        "https://internetdb.shodan.io/$ip_address" \
        yes
else
    info "Skipping Shodan InternetDB: target $ip_address is IPv$IP_VERSION; this integration is IPv4-only."
fi

# IPinfo lookup.
heading "IPinfo Results"

if [[ -n "$IPINFO_TOKEN" ]]; then
    run_lookup \
        "IPinfo" \
        "https://ipinfo.io/$ip_address/json" \
        no \
        --header "Authorization: Bearer $IPINFO_TOKEN"
else
    run_lookup \
        "IPinfo" \
        "https://ipinfo.io/$ip_address/json" \
        no
fi

# IPQualityScore lookup.
if [[ -n "$IPQS_API_KEY" ]]; then
    heading "IPQualityScore Results"

    # Encode the key because it is included in a URL path.
    if ! encoded_ipqs_key=$(
        python3 - "$IPQS_API_KEY" <<'PY'
import sys
from urllib.parse import quote

print(quote(sys.argv[1], safe=""))
PY
    ); then
        die "Unable to encode the IPQualityScore API key."
    fi

    run_lookup \
        "IPQualityScore" \
        "https://www.ipqualityscore.com/api/json/ip/$encoded_ipqs_key/$ip_address" \
        no

    unset encoded_ipqs_key
else
    info "IPQualityScore API key not provided; skipping lookup."
fi

# GreyNoise lookup.
# This integration is restricted to IPv4.
if [[ "$IP_VERSION" == 4 ]]; then
    heading "GreyNoise Results"

    greynoise_result=0

    if [[ -n "$GREYNOISE_API_KEY" ]]; then
        lookup \
            "GreyNoise IP Lookup" \
            "https://api.greynoise.io/v3/ip/$ip_address" \
            yes \
            --header "key: $GREYNOISE_API_KEY" ||
            greynoise_result=$?

        if (( greynoise_result != 0 )); then
            # Preserve attempted-request failure accounting:
            # a successful fallback does not erase a prior failed attempt.
            if (( greynoise_result == 1 )); then
                FAILURES=$((FAILURES + 1))
            fi

            info "Trying GreyNoise Community with the configured key..."

            run_lookup \
                "GreyNoise Community" \
                "https://api.greynoise.io/v3/community/$ip_address" \
                yes \
                --header "key: $GREYNOISE_API_KEY"
        fi
    else
        info "No GreyNoise key provided; trying Community without authentication."

        run_lookup \
            "GreyNoise Community" \
            "https://api.greynoise.io/v3/community/$ip_address" \
            yes
    fi
else
    info "Skipping GreyNoise: target $ip_address is IPv$IP_VERSION; this integration is IPv4-only."
fi

# OpenSourceMalware IP reputation lookup.
if [[ -n "$OSM_API_KEY" ]]; then
    heading "OSM IP Reputation Results"

    run_lookup \
        "OpenSourceMalware" \
        "https://api.opensourcemalware.com/functions/v1/check-malicious" \
        no \
        --header "Authorization: Bearer $OSM_API_KEY" \
        --get \
        --data-urlencode "report_type=ip" \
        --data-urlencode "resource_identifier=$ip_address"
else
    info "OSM API key not provided; skipping lookup."
fi

# Pulsedive indicator lookup.
heading "Pulsedive Indicator Results"

pulsedive_options=(
    --get
    --data-urlencode "indicator=$ip_address"
    --data-urlencode "pretty=1"
)

if [[ -n "$PULSEDIVE_API_KEY" ]]; then
    pulsedive_options+=(
        --data-urlencode "key=$PULSEDIVE_API_KEY"
    )
else
    info "No Pulsedive key provided; attempting a rate-limited unauthenticated lookup."
fi

run_lookup \
    "Pulsedive" \
    "https://pulsedive.com/api/indicator.php" \
    yes \
    "${pulsedive_options[@]}"

# Final status.
if (( FAILURES > 0 )); then
    info "IPLookup complete with $FAILURES failed lookup attempt(s)."
    exit 1
fi

info "IPLookup complete."
exit 0