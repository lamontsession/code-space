#!/bin/bash

# Author: LaMont Session
# Date Created: 2025-10-28
# Last Modified: 2025-01-28

# Description:
# This is an ip lookup script that retrieves geographical and network information for a given IP address.

# Usage:
# iplookup <IP_ADDRESS>
# iplookup -h|--help     Show this help message

# Fail on error, undefined var, and fail pipeline on first failing command
set -u  # Treat unset variables as an error
set -o pipefail  # Return the exit status of the first failed command in a pipeline

# Function to show help message
show_help() {
    echo "Usage: $(basename "$0") <IP_ADDRESS>"
    echo "Retrieve geographical and network information for a given IP address."
    echo ""
    echo "Options:"
    echo "  -q, --quiet       Suppress non-error output"
    echo "  -v, --verbose     Verbose output (debug)"
    echo "  -c, --config FILE Specify alternate config file"
    echo "      --no-prompt   Do not prompt for missing API tokens"
    echo "  -h, --help    Show this help message"
    exit 0
}

# Helper function to trim leading and trailing whitespace
trim_whitespace() {
    local str="$1"
    # Remove leading whitespace
    str="${str#${str%%[![:space:]]*}}"
    # Remove trailing whitespace
    str="${str%${str##*[![:space:]]}}"
    printf "%s\n" "$str"
}

## CLI flags
QUIET=0
VERBOSE=0
NO_PROMPT=0
CONFIG_FILE_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -q|--quiet)
            QUIET=1; shift ;;
        -v|--verbose)
            VERBOSE=1; shift ;;
        -c|--config)
            if [[ $# -lt 2 ]]; then
                printf "Error: -c|--config requires an argument\n" >&2; exit 1
            fi
            CONFIG_FILE_OVERRIDE="$2"; shift 2 ;;
        --config=*)
            CONFIG_FILE_OVERRIDE="${1#*=}"; shift ;;
        --no-prompt)
            NO_PROMPT=1; shift ;;
        --)
            shift; break ;;
        -*)
            printf "Unknown option: %s\n" "$1" >&2; exit 1 ;;
        *)
            break ;;
    esac
done

# Remaining positional argument is the IP address
if [[ $# -ge 1 ]]; then
    ip_address="$1"
else
    if [[ $NO_PROMPT -eq 1 ]]; then
        printf "Error: IP address required in non-interactive mode\n" >&2
        exit 2
    fi
    read -p "Enter an IP address to look up: " ip_address
fi

# Load configuration: allow override from CLI, default to ${HOME}/.iplookup.conf
if [[ -n "${CONFIG_FILE_OVERRIDE:-}" ]]; then
    CONFIG_FILE="$CONFIG_FILE_OVERRIDE"
else
    CONFIG_FILE="${HOME}/.iplookup.conf"
fi
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

# Ensure required tools are available
if ! command -v curl >/dev/null 2>&1; then
    printf "Error: 'curl' is required but not installed.\n"
    exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
    if [[ ${QUIET:-0} -eq 0 ]]; then
        printf "Note: 'jq' not found — output will be raw JSON.\n"
    fi
fi

# IP address should already be set from earlier check

# Validate IP address format (IPv4 and IPv6)
if ! [[ "$ip_address" =~ ^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$ || "$ip_address" =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]]; then
    echo "Error: Invalid IP address format."
    exit 1
fi

# Function to prompt for tokens if needed
prompt_for_tokens() {
    # If non-interactive mode requested, skip prompting
    if [[ "${NO_PROMPT:-0}" -eq 1 ]]; then
        if [[ ${VERBOSE:-0} -eq 1 && ${QUIET:-0} -eq 0 ]]; then
            printf "Skipping interactive token prompts (--no-prompt set)\n"
        fi
        return
    fi
    # Check for IPinfo token
    if [[ -z "${IPINFO_TOKEN:-}" ]]; then
        read -p "Would you like to enter an IPinfo.io token? (y/n): " use_ipinfo
        if [[ "$use_ipinfo" == "y" || "$use_ipinfo" == "Y" ]]; then
            # hide token input
            read -rs -p "Enter your IPinfo.io token: " IPINFO_TOKEN
            IPINFO_TOKEN=$(trim_whitespace "$IPINFO_TOKEN")
            echo
        fi
    fi

    # Check for IPQS key
    if [[ -z "${IPQS_KEY:-}" ]]; then
        read -p "Would you like to enter an IPQualityScore API key? (y/n): " use_ipqs
        if [[ "$use_ipqs" == "y" || "$use_ipqs" == "Y" ]]; then
            read -rs -p "Enter your IPQualityScore API key: " IPQS_KEY
            IPQS_KEY=$(trim_whitespace "$IPQS_KEY")
            echo
        fi
    fi

    # Check for VirusTotal API key
    if [[ -z "${VIRUSTOTAL_KEY:-}" ]]; then
        read -p "Would you like to enter a VirusTotal API key? (y/n): " use_vt
        if [[ "$use_vt" == "y" || "$use_vt" == "Y" ]]; then
            read -rs -p "Enter your VirusTotal API key: " VIRUSTOTAL_KEY
            VIRUSTOTAL_KEY=$(trim_whitespace "$VIRUSTOTAL_KEY")
            echo
        fi
    fi

    # Check for MaxMind license key
    if [[ -z "${MAXMIND_KEY:-}" ]]; then
        read -p "Would you like to enter a MaxMind license key? (y/n): " use_mm
        if [[ "$use_mm" == "y" || "$use_mm" == "Y" ]]; then
            read -rs -p "Enter your MaxMind license key: " MAXMIND_KEY
            MAXMIND_KEY=$(trim_whitespace "$MAXMIND_KEY")
            echo
        fi
    fi

    # Check for MaxMind account ID
    if [[ -z "${MAXMIND_ACCOUNT_ID:-}" ]] && [[ -n "${MAXMIND_KEY:-}" ]]; then
        read -p "Enter your MaxMind account ID: " MAXMIND_ACCOUNT_ID
        MAXMIND_ACCOUNT_ID=$(trim_whitespace "$MAXMIND_ACCOUNT_ID")
    fi

    # Check for GreyNoise key
    if [[ -z "${GREYNOISE_KEY:-}" ]]; then
        read -p "Would you like to enter a GreyNoise API key? (y/n): " use_gn
        if [[ "$use_gn" == "y" || "$use_gn" == "Y" ]]; then
            read -rs -p "Enter your GreyNoise API key: " GREYNOISE_KEY
            GREYNOISE_KEY=$(trim_whitespace "$GREYNOISE_KEY")
            echo
        fi
    fi
}

# Use API tokens from config file or environment variables
IPINFO_TOKEN=${IPINFO_TOKEN:-${TOKEN:-}}
IPQS_KEY=${IPQS_KEY:-${IPQS_API_KEY:-}}
MAXMIND_KEY=${MAXMIND_KEY:-${MAXMIND_LICENSE_KEY:-}}
MAXMIND_ACCOUNT_ID=${MAXMIND_ACCOUNT_ID:-${MAXMIND_ID:-}}
GREYNOISE_KEY=${GREYNOISE_KEY:-${GREYNOISE_API_KEY:-}}
VIRUSTOTAL_KEY=${VIRUSTOTAL_KEY:-${VIRUSTOTAL_API_KEY:-}}

# Prompt for tokens if not found in environment or config
prompt_for_tokens

# Set up IPinfo URL (token will be passed via header when available)
if [[ -n "$IPINFO_TOKEN" ]]; then
    IPINFO_URL="https://api.ipinfo.io/lite/$ip_address"
else
    IPINFO_URL="https://ipinfo.io/$ip_address"
fi

# Function to validate and format JSON response
format_json_response() {
    local response=$1

    # Check if response looks like JSON (starts with { or [)
    if [[ "$response" =~ ^[[:space:]]*[\{\[]+ ]]; then
        if command -v jq >/dev/null 2>&1; then
            printf "%s\n" "$response" | jq . 2>/dev/null || printf "%s\n" "$response"
        else
            printf "%s\n" "$response"
        fi
    else
        printf "%s\n" "$response"
    fi
}

# Function to call MaxMind API with account ID and license key
call_api_maxmind() {
    local url=$1
    local account_id=$2
    local license_key=$3
    local response
    local http_code
    local exit_code

    # Capture response and HTTP status code separately
    response=$(curl -sS --max-time 10 --request GET --url "$url" \
            --user "$account_id:$license_key" \
            --header "accept: application/json" \
            -w "\n%{http_code}" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}

    if [[ $exit_code -ne 0 ]]; then
        printf "Error: curl failed (exit code: %s)\n" "$exit_code" >&2
        printf "%s\n" "$response"
        return 1
    fi

    # Extract HTTP code (last line) and body (everything else)
    http_code=$(printf "%s" "$response" | tail -n1)
    response=$(printf "%s" "$response" | sed '$d')

    # Check HTTP status
    if [[ $http_code -ge 400 ]]; then
        printf "Error: HTTP %s - %s\n" "$http_code" "$response" >&2
        return 1
    fi

    if [[ -z "${response:-}" ]]; then
        printf "Warning: Empty response received from %s\n" "$url"
        return 1
    fi

    format_json_response "$response"
}

# Function to call API with header authentication
call_api_with_header_auth() {
    local url=$1
    local header_name=$2
    local header_value=$3
    local response
    local http_code
    local exit_code

    # Capture response and HTTP status code separately
    response=$(curl -sS --max-time 10 --request GET --url "$url" \
            --header "accept: application/json" \
            --header "$header_name: $header_value" \
            -w "\n%{http_code}" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}

    if [[ $exit_code -ne 0 ]]; then
        printf "Error: curl failed (exit code: %s)\n" "$exit_code" >&2
        printf "%s\n" "$response"
        return 1
    fi

    # Extract HTTP code (last line) and body (everything else)
    http_code=$(printf "%s" "$response" | tail -n1)
    response=$(printf "%s" "$response" | sed '$d')

    # Check HTTP status
    if [[ $http_code -ge 400 ]]; then
        printf "Error: HTTP %s - %s\n" "$http_code" "$response" >&2
        return 1
    fi

    if [[ -z "${response:-}" ]]; then
        printf "Warning: Empty response received from %s\n" "$url"
        return 1
    fi

    format_json_response "$response"
}

# Function to call API with no authentication
call_api_public() {
    local url=$1
    local response
    local http_code
    local exit_code

    # Capture response and HTTP status code separately
    response=$(curl -sS --max-time 10 "$url" -w "\n%{http_code}" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}

    if [[ $exit_code -ne 0 ]]; then
        printf "Error: curl failed (exit code: %s)\n" "$exit_code" >&2
        printf "%s\n" "$response"
        return 1
    fi

    # Extract HTTP code (last line) and body (everything else)
    http_code=$(printf "%s" "$response" | tail -n1)
    response=$(printf "%s" "$response" | sed '$d')

    # Check HTTP status
    if [[ $http_code -ge 400 ]]; then
        printf "Error: HTTP %s - %s\n" "$http_code" "$response" >&2
        return 1
    fi

    if [[ -z "${response:-}" ]]; then
        printf "Warning: Empty response received from %s\n" "$url"
        return 1
    fi

    format_json_response "$response"
}

# Output results
printf "\n--- IPinfo Results ---\n"
if [[ -n "$IPINFO_TOKEN" ]]; then
    # prefer header-based auth for tokens
    call_api_with_header_auth "$IPINFO_URL" "Authorization" "Bearer $IPINFO_TOKEN" || true
else
    call_api_public "$IPINFO_URL" || true
fi

# IPQualityScore lookup if API key provided
if [[ -n "$IPQS_KEY" ]]; then
    IPQS_URL="https://www.ipqualityscore.com/api/json/ip/$IPQS_KEY/$ip_address"
    printf "\n--- IPQS Results ---\n"
    if ! call_api_public "$IPQS_URL"; then
        if [[ ${VERBOSE:-0} -eq 1 && ${QUIET:-0} -eq 0 ]]; then
            printf "(verbose) Failed to retrieve IPQS data\n" >&2
        fi
    fi
else
    if [[ ${QUIET:-0} -eq 0 ]]; then
        echo "IPQualityScore API key not provided. Skipping IPQS lookup."
    fi
fi

# MaxMind GeoIP2 lookup if license key and account ID provided
if [[ -n "$MAXMIND_KEY" ]] && [[ -n "$MAXMIND_ACCOUNT_ID" ]]; then
    MAXMIND_URL="https://geoip.maxmind.com/geoip/v2.1/city/$ip_address"
    printf "\n--- MaxMind GeoIP2 Results ---\n"
    if ! call_api_maxmind "$MAXMIND_URL" "$MAXMIND_ACCOUNT_ID" "$MAXMIND_KEY"; then
        if [[ ${VERBOSE:-0} -eq 1 && ${QUIET:-0} -eq 0 ]]; then
            printf "(verbose) Failed to retrieve MaxMind data\n" >&2
        fi
    fi
else
    if [[ -n "$MAXMIND_KEY" ]] && [[ -z "$MAXMIND_ACCOUNT_ID" ]]; then
        if [[ ${QUIET:-0} -eq 0 ]]; then
            echo "MaxMind account ID not provided. Skipping MaxMind lookup."
        fi
    elif [[ -z "$MAXMIND_KEY" ]]; then
        if [[ ${QUIET:-0} -eq 0 ]]; then
            echo "MaxMind license key not provided. Skipping MaxMind lookup."
        fi
    fi
fi

# GreyNoise lookup
if [[ -n "$GREYNOISE_KEY" ]]; then
    GREYNOISE_URL="https://api.greynoise.io/v3/ip/$ip_address"
    printf "\n--- GreyNoise Results ---\n"
    if ! call_api_with_header_auth "$GREYNOISE_URL" "key" "$GREYNOISE_KEY"; then
        if [[ ${VERBOSE:-0} -eq 1 && ${QUIET:-0} -eq 0 ]]; then
            printf "(verbose) Failed to retrieve GreyNoise data with token, falling back to community results...\n" >&2
        else
            printf "Failed to retrieve GreyNoise data with token, falling back to community results...\n"
        fi
        # Community fallback on token failure
        if ! call_api_public "https://api.greynoise.io/v3/community/$ip_address"; then
            if [[ ${VERBOSE:-0} -eq 1 && ${QUIET:-0} -eq 0 ]]; then
                printf "(verbose) Failed to retrieve GreyNoise community data\n" >&2
            fi
        fi
    fi
else
    printf "\n--- GreyNoise Community Results ---\n"
    if ! call_api_public "https://api.greynoise.io/v3/community/$ip_address"; then
        if [[ ${VERBOSE:-0} -eq 1 && ${QUIET:-0} -eq 0 ]]; then
            printf "(verbose) Failed to retrieve GreyNoise community data\n" >&2
        fi
    fi
fi

# VirusTotal lookup
if [[ -n "$VIRUSTOTAL_KEY" ]]; then
    VIRUSTOTAL_URL="https://www.virustotal.com/api/v3/ip_addresses/$ip_address"
    printf "\n--- VirusTotal Results ---\n"
    # VirusTotal requires the API key in header 'x-apikey'
    if ! call_api_with_header_auth "$VIRUSTOTAL_URL" "x-apikey" "$VIRUSTOTAL_KEY"; then
        if [[ ${VERBOSE:-0} -eq 1 && ${QUIET:-0} -eq 0 ]]; then
            printf "(verbose) Failed to retrieve VirusTotal data\n" >&2
        fi
    fi
else
    if [[ ${QUIET:-0} -eq 0 ]]; then
        echo "VirusTotal API key not provided. Skipping VirusTotal lookup."
    fi
fi


# Final message displayed to screen
printf "\nIPLookup complete.\n\n"