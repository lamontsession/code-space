#!/bin/bash
   
# Author: LaMont Session
# Date Created: 2025-10-28
# Last Modified: 2025-10-28

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
if ! [[ "$ip_address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ || "$ip_address" =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]]; then
    echo "Error: Invalid IP address format."
    exit 1
fi

# Ask if user wants to use an API token
read -p "Do you have an IPinfo API token? Enter 'y' if you have one, otherwise enter 'n': " use_token

if [[ "$use_token" == "y" || "$use_token" == "Y" ]]; then
    read -p "Enter your IPinfo API token: " TOKEN
    URL="https://ipinfo.io/$ip_address?token=$TOKEN"
else
    URL="https://ipinfo.io/$ip_address"
fi

# The output is in JSON format. You can use 'jq' to pretty-print and interpret the fields.
if command -v jq >/dev/null 2>&1; then
    curl -s "$URL" | jq
else
    echo "Note: Install 'jq' for pretty-printed output. Raw JSON follows:"
    curl -s "$URL"
fi

# Make the request and output the result to the screen
# (Handled above, no need to repeat the curl command)
