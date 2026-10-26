#!/usr/bin/env bash

# Author: LaMont Session
# Date Created: 2025-10-28
# Last Modified: 2026-10-25
#
# Retrieve geographical, threat intelligence, and network information
# for an IPv4 or IPv6 address.
#
# Dependencies: bash, curl, python3
# Optional: jq
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
  \${XDG_CONFIG_HOME:-\$HOME/.config}/iplookup/config

Exit codes:
  0  All attempted lookups succeeded or returned no record
  1  One or more attempted lookups failed
  2  Invalid input, configuration, or missing dependency

A missing threat-intelligence record does not establish that an IP is safe.
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

(( $# <= 1 )) || die "Expected exactly one IP address."

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

# Validate the input, reject scoped IPv6 addresses, and normalize it.
# Hostnames, URLs, CIDR ranges, and IPv4 addresses with leading zeros
# are intentionally not accepted at this time, but may be added in future releases.
if ! parsed_ip=$(
    python3 - "$ip_address" <<'PY'
import ipaddress
import sys

value = sys.argv[1]

try:
    if "%" in value:
        raise ValueError("Scoped IPv6 addresses are not supported")
    address = ipaddress.ip_address(value)
except ValueError:
    sys.exit(1)

print(address.version)
print(address.compressed)
PY
); then
    die "Invalid IP address: $ip_address"
fi

IP_VERSION=${parsed_ip%%$'\n'*}
ip_address=${parsed_ip#*$'\n'}

# Avoid automatically sourcing executable configuration from $PWD.
CONFIG_FILE=""
if (( CONFIG_EXPLICIT == 1 )); then
    CONFIG_FILE=$CONFIG_FILE_OVERRIDE
elif [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
    CONFIG_FILE="${XDG_CONFIG_HOME}/iplookup/config"
elif [[ -n "${HOME:-}" ]]; then
    CONFIG_FILE="${HOME}/.config/iplookup/config"
fi

if [[ -n "$CONFIG_FILE" ]]; then
    if [[ -e "$CONFIG_FILE" ]]; then
        [[ -f "$CONFIG_FILE" && -r "$CONFIG_FILE" ]] ||
            die "Configuration is not a readable regular file: $CONFIG_FILE"
        debug "Loading trusted configuration: $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    elif (( CONFIG_EXPLICIT == 1 )); then
        die "Configuration file not found: $CONFIG_FILE"
    fi
fi

IPINFO_TOKEN=$(trim_whitespace "${IPINFO_TOKEN:-}")
IPQS_KEY=$(trim_whitespace "${IPQS_KEY:-${IPQS_API_KEY:-}}")
GREYNOISE_KEY=$(trim_whitespace \
    "${GREYNOISE_KEY:-${GREYNOISE_API_KEY:-}}")
OSM_KEY=$(trim_whitespace "${OSM_KEY:-${OSM_API_KEY:-}}")
PULSEDIVE_KEY=$(trim_whitespace \
    "${PULSEDIVE_KEY:-${PULSEDIVE_API_KEY:-}}")

prompt_for_token() {
    local variable=$1
    local label=$2
    local answer=""
    local value=""

    [[ -z "${!variable}" ]] || return 0
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

prompt_for_token IPINFO_TOKEN "IPinfo"
prompt_for_token IPQS_KEY "IPQualityScore"
prompt_for_token OSM_KEY "OpenSourceMalware"

if [[ "$IP_VERSION" == 4 ]]; then
    prompt_for_token GREYNOISE_KEY "GreyNoise"
fi

# Prevent malformed headers caused by embedded CR/LF in credentials.
for token_name in \
    IPINFO_TOKEN IPQS_KEY GREYNOISE_KEY OSM_KEY PULSEDIVE_KEY
do
    token_value=${!token_name}
    if [[ "$token_value" == *$'\r'* || "$token_value" == *$'\n'* ]]; then
        die "$token_name contains an embedded newline."
    fi
done
unset token_name token_value

format_response() {
    local body=$1

    if (( HAS_JQ == 1 )); then
        if printf '%s\n' "$body" | jq . 2>/dev/null; then
            return 0
        fi
    fi

    printf '%s\n' "$body"
}

# Shared HTTP response state; request functions run in the current shell.
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

    # Disable ~/.curlrc, keep diagnostics on stderr, and do not follow
    # redirects automatically. Never print URLs containing API keys.
    response=$(
        curl --disable \
            --silent --show-error \
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

    if [[ ! "$HTTP_STATUS" =~ ^[0-9]{3}$ ]]; then
        printf 'Error: %s returned an invalid HTTP status.\n' \
            "$provider" >&2
        return 1
    fi

    debug "$provider: HTTP $HTTP_STATUS"
    return 0
}

# Return 0 for success, 1 for error, and 2 for an allowed no-record 404.
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

# Ordinary providers: no-record responses do not count as failures.
run_lookup() {
    local result=0

    lookup "$@" || result=$?

    if (( result == 1 )); then
        FAILURES=$((FAILURES + 1))
    fi

    return 0
}

# Shodan InternetDB: keep this integration IPv4-only.
if [[ "$IP_VERSION" == 4 ]]; then
    heading "Shodan InternetDB Results"
    run_lookup \
        "Shodan InternetDB" \
        "https://internetdb.shodan.io/$ip_address" \
        yes
else
    info "Skipping Shodan InternetDB: this integration is IPv4-only."
fi

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

if [[ -n "$IPQS_KEY" ]]; then
    heading "IPQualityScore Results"

    # The key is a URL path component; encode reserved characters.
    encoded_ipqs_key=$(
        python3 - "$IPQS_KEY" <<'PY'
import sys
from urllib.parse import quote
print(quote(sys.argv[1], safe=""))
PY
    )

    run_lookup \
        "IPQualityScore" \
        "https://www.ipqualityscore.com/api/json/ip/$encoded_ipqs_key/$ip_address" \
        no
    unset encoded_ipqs_key
else
    info "IPQualityScore API key not provided; skipping lookup."
fi

if [[ "$IP_VERSION" == 4 ]]; then
    heading "GreyNoise Results"

    greynoise_result=0

    if [[ -n "$GREYNOISE_KEY" ]]; then
        lookup \
            "GreyNoise IP Lookup" \
            "https://api.greynoise.io/v3/ip/$ip_address" \
            yes \
            --header "key: $GREYNOISE_KEY" ||
            greynoise_result=$?

        if (( greynoise_result != 0 )); then
            if (( greynoise_result == 1 )); then
                FAILURES=$((FAILURES + 1))
            fi

            info "Trying GreyNoise Community with the configured key..."
            run_lookup \
                "GreyNoise Community" \
                "https://api.greynoise.io/v3/community/$ip_address" \
                yes \
                --header "key: $GREYNOISE_KEY"
        fi
    else
        info "No GreyNoise key provided; trying Community without authentication."
        run_lookup \
            "GreyNoise Community" \
            "https://api.greynoise.io/v3/community/$ip_address" \
            yes
    fi
else
    info "Skipping GreyNoise: this integration requires IPv4."
fi

if [[ -n "$OSM_KEY" ]]; then
    heading "OSM IP Reputation Results"
    run_lookup \
        "OpenSourceMalware" \
        "https://api.opensourcemalware.com/functions/v1/check-malicious" \
        no \
        --header "Authorization: Bearer $OSM_KEY" \
        --get \
        --data-urlencode "report_type=ip" \
        --data-urlencode "resource_identifier=$ip_address"
else
    info "OSM API key not provided; skipping lookup."
fi

heading "Pulsedive Indicator Results"
pulsedive_options=(
    --get
    --data-urlencode "indicator=$ip_address"
    --data-urlencode "pretty=1"
)

if [[ -n "$PULSEDIVE_KEY" ]]; then
    pulsedive_options+=(--data-urlencode "key=$PULSEDIVE_KEY")
else
    info "No Pulsedive key provided; attempting a rate-limited unauthenticated lookup."
fi

run_lookup \
    "Pulsedive" \
    "https://pulsedive.com/api/indicator.php" \
    yes \
    "${pulsedive_options[@]}"

if (( FAILURES > 0 )); then
    info "IPLookup complete with $FAILURES failed lookup attempt(s)."
    exit 1
fi

info "IPLookup complete."
exit 0