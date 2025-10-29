#!/bin/bash

# Author: LaMont Session
# Date Created: 2025-10-28
# Last Modified: 2025-10-29

# Description:
# This is an ip lookup script that retrieves geographical and network information for a given IP address.

# Usage:
# iplookup <IP_ADDRESS>


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

# Prompt for IPinfo API token
read -p "Do you have an IPinfo API token? Enter 'y' if you have one, otherwise enter 'n': " use_token

if [[ "$use_token" == "y" || "$use_token" == "Y" ]]; then
    read -p "Enter your IPinfo API token: " TOKEN
    IPINFO_URL="https://ipinfo.io/$ip_address?token=$TOKEN"
else
    IPINFO_URL="https://ipinfo.io/$ip_address"
fi

# Prompt for IPQualityScore API key
read -p "Do you have an IPQualityScore API key? Enter 'y' if you have one, otherwise enter 'n': " use_ipqs
if [[ "$use_ipqs" == "y" || "$use_ipqs" == "Y" ]]; then
    read -p "Enter your IPQualityScore API key: " IPQS_KEY
else
    IPQS_KEY=""
fi

# Output results (pretty-print with jq if installed)
echo -e "\n--- IPinfo Results ---"
if command -v jq >/dev/null 2>&1; then
    curl -s "$IPINFO_URL" | jq
else
    echo "Note: Install 'jq' for pretty-printed output. Raw JSON follows:"
    curl -s "$IPINFO_URL"
fi
# IPQualityScore lookup if API key provided
if [[ -n "$IPQS_KEY" ]]; then
    IPQS_URL="https://www.ipqualityscore.com/api/json/ip/$IPQS_KEY/$ip_address"
    echo -e "\n--- IPQS Results ---"
    if command -v jq >/dev/null 2>&1; then
        curl -s "$IPQS_URL" | jq
    else
        echo "Note: Install 'jq' for pretty-printed output. Raw JSON follows:"
        curl -s "$IPQS_URL"
    fi
else
    echo "IPQualityScore API key not provided. Skipping IPQS lookup."
fi
# Final message displayed to screen
echo -e "\nIPLookup complete."

