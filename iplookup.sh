#!/bin/bash

# Author: LaMont Session
# Date Created: 2025-10-28
# Last Modified: 2025-11-02

# Description:
# This is an ip lookup script that retrieves geographical and network information for a given IP address.

# Usage:
# iplookup <IP_ADDRESS>
# iplookup -h|--help     Show this help message

# Function to show help message
show_help() {
    echo "Usage: $(basename "$0") <IP_ADDRESS>"
    echo "Retrieve geographical and network information for a given IP address."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    exit 0
}

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
fi

# Load configuration if exists
CONFIG_FILE="$HOME/.iplookup.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Get IP address from argument or prompt user
if [[ -n "$1" ]]; then
    ip_address="$1"
else
    read -p "Enter an IP address to look up: " ip_address
fi

# Validate IP address format (IPv4 and IPv6)
if ! [[ "$ip_address" =~ ^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$ || "$ip_address" =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]]; then
    echo "Error: Invalid IP address format."
    exit 1
fi

# Function to prompt for tokens if needed
prompt_for_tokens() {
    # Check for IPinfo token
    if [[ -z "$IPINFO_TOKEN" ]]; then
        read -p "Would you like to enter an IPinfo.io token? (y/n): " use_ipinfo
        if [[ "$use_ipinfo" == "y" || "$use_ipinfo" == "Y" ]]; then
            read -p "Enter your IPinfo.io token: " IPINFO_TOKEN
        fi
    fi

    # Check for IPQS key
    if [[ -z "$IPQS_KEY" ]]; then
        read -p "Would you like to enter an IPQualityScore API key? (y/n): " use_ipqs
        if [[ "$use_ipqs" == "y" || "$use_ipqs" == "Y" ]]; then
            read -p "Enter your IPQualityScore API key: " IPQS_KEY
        fi
    fi
}

# Use API tokens from config file or environment variables
IPINFO_TOKEN=${IPINFO_TOKEN:-$TOKEN}
IPQS_KEY=${IPQS_KEY:-$IPQS_API_KEY}

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

    response=$(curl -s -m 10 "$url")  # 10 second timeout
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo "Error: Failed to fetch data (curl exit code: $exit_code)"
        return 1
    fi

    if [[ "$response" == *"rate limit"* ]] || [[ "$response" == *"quota exceeded"* ]]; then
        echo "Error: API rate limit exceeded"
        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        echo "$response" | jq
    else
        echo "Note: Install 'jq' for pretty-printed output. Raw JSON follows:"
        echo "$response"
    fi
}

# Output results
echo -e "\n--- IPinfo Results ---"
call_api "$IPINFO_URL" || exit 1
# IPQualityScore lookup if API key provided
if [[ -n "$IPQS_KEY" ]]; then
    IPQS_URL="https://www.ipqualityscore.com/api/json/ip/$IPQS_KEY/$ip_address"
    echo -e "\n--- IPQS Results ---"
    call_api "$IPQS_URL" || echo "Failed to retrieve IPQS data"
else
    echo "IPQualityScore API key not provided. Skipping IPQS lookup."
fi
# Final message displayed to screen
echo -e "\nIPLookup complete."

