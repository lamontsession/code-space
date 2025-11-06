#!/bin/bash

# Author: LaMont Session
# Date Created: 2025-10-28
# Last Modified: 2025-11-06

# Description:
# This is an ip lookup script that retrieves geographical and network information for a given IP address.

# Usage:
# iplookup <IP_ADDRESS>
# iplookup -h|--help     Show this help message

# Fail on error, undefined var, and fail pipeline on first failing command
set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error
set -o pipefail  # Return the exit status of the first failed command in a pipeline
# Safer IFS for word splitting
# Exclude spaces to prevent word splitting bugs when handling input with spaces.
# Note: Setting IFS to $'\n\t' is generally safe, but if user input (such as tokens) contains spaces,
# this may cause unexpected behavior when reading or processing those values.
IFS=$'\n\t'

# Function to show help message
show_help() {
    echo "Usage: $(basename "$0") <IP_ADDRESS>"
    echo "Retrieve geographical and network information for a given IP address."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    exit 0
}

# Check if any arguments were provided
if [[ $# -eq 0 ]]; then
    read -p "Enter an IP address to look up: " ip_address
else
    # Check for help flag
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        show_help
    fi
    ip_address="${1:-}"
fi

# Load configuration if exists
CONFIG_FILE="$HOME/.iplookup.conf"
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
    printf "Note: 'jq' not found — output will be raw JSON.\n"
fi

# IP address should already be set from earlier check

# Validate IP address format (IPv4 and IPv6)
if ! [[ "$ip_address" =~ ^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$ || "$ip_address" =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]]; then
    echo "Error: Invalid IP address format."
    exit 1
fi

# Function to prompt for tokens if needed
prompt_for_tokens() {
    # Check for IPinfo token
    if [[ -z "${IPINFO_TOKEN:-}" ]]; then
        read -p "Would you like to enter an IPinfo.io token? (y/n): " use_ipinfo
        if [[ "$use_ipinfo" == "y" || "$use_ipinfo" == "Y" ]]; then
            # hide token input
            read -s -p "Enter your IPinfo.io token: " IPINFO_TOKEN
            echo
        fi
    fi

    # Check for IPQS key
    if [[ -z "${IPQS_KEY:-}" ]]; then
        read -p "Would you like to enter an IPQualityScore API key? (y/n): " use_ipqs
        if [[ "$use_ipqs" == "y" || "$use_ipqs" == "Y" ]]; then
            read -s -p "Enter your IPQualityScore API key: " IPQS_KEY
            echo
        fi
    fi

    # Check for GreyNoise key
    if [[ -z "${GREYNOISE_KEY:-}" ]]; then
        read -p "Would you like to enter a GreyNoise API key? (y/n): " use_gn
        if [[ "$use_gn" == "y" || "$use_gn" == "Y" ]]; then
            read -s -p "Enter your GreyNoise API key: " GREYNOISE_KEY
            echo
        fi
    fi
}

# Use API tokens from config file or environment variables
IPINFO_TOKEN=${IPINFO_TOKEN:-${TOKEN:-}}
IPQS_KEY=${IPQS_KEY:-${IPQS_API_KEY:-}}
GREYNOISE_KEY=${GREYNOISE_KEY:-${GREYNOISE_API_KEY:-}}

# Prompt for tokens if not found in environment or config
prompt_for_tokens

# Set up URLs based on available tokens
if [[ -n "$IPINFO_TOKEN" ]]; then
    IPINFO_URL="https://ipinfo.io/$ip_address?token=$IPINFO_TOKEN"
else
    IPINFO_URL="https://ipinfo.io/$ip_address"
fi

# Function to handle API calls with timeout and error checking
call_api() {
    local url=$1
    local response
    local exit_code

    # --fail: return non-zero on HTTP errors; -sS: silent but show errors; --max-time for timeout
    response=$(curl --fail -sS --max-time 10 "$url" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}

    if [[ $exit_code -ne 0 ]]; then
        printf "Error: Failed to fetch data (curl exit code: %s)\n" "$exit_code"
        printf "%s\n" "$response"
        return 1
    fi

    if [[ -z "${response:-}" ]]; then
        printf "Warning: Empty response received from %s\n" "$url"
        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        printf "%s\n" "$response" | jq
    else
        printf "Note: Install 'jq' for pretty-printed output. Raw JSON follows:\n"
        printf "%s\n" "$response"
    fi
}

# Output results
printf "\n--- IPinfo Results ---\n"
call_api "$IPINFO_URL" || exit 1

# IPQualityScore lookup if API key provided
if [[ -n "$IPQS_KEY" ]]; then
    IPQS_URL="https://www.ipqualityscore.com/api/json/ip/$IPQS_KEY/$ip_address"
    printf "\n--- IPQS Results ---\n"
    call_api "$IPQS_URL" || printf "Failed to retrieve IPQS data\n"
else
    echo "IPQualityScore API key not provided. Skipping IPQS lookup."
fi

# GreyNoise lookup
if [[ -n "$GREYNOISE_KEY" ]]; then
    GREYNOISE_URL="https://api.greynoise.io/v3/ip/$ip_address"
    printf "\n--- GreyNoise Results ---\n"
    if ! curl --fail -sS --max-time 10 --request GET --url "$GREYNOISE_URL" \
         --header "accept: application/json" \
         --header "key: $GREYNOISE_KEY"; then
        printf "Failed to retrieve GreyNoise data\n"
    fi
else
    printf "\n--- GreyNoise Community Results ---\n"
    if ! curl --fail -sS --max-time 10 "https://api.greynoise.io/v3/community/$ip_address"; then
        printf "Failed to retrieve GreyNoise community data\n"
    fi
fi

# Final message displayed to screen
printf "\nIPLookup complete.\n"

