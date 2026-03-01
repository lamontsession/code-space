#!/usr/bin/env python3
# IP Lookup using Shodan's API with support for both IPv4 and IPv6 addresses.
# Author: LaMont Session
# Description: IP lookup tool that queries Shodan's API for detailed information about a given IP address. It supports both IPv4 and IPv6 addresses, validates user input, and provides pretty-printed JSON output using jq if available.
# Created Date: 2026-03-01
# Last Modified: 2026-03-01
import json
import os
import sys
import subprocess
from pathlib import Path
import ipaddress  # stdlib: IPv4/IPv6 validation

import shodan  # type: ignore # pip install shodan - Shodan's official Python library

CONFIG_PATH_DEFAULT = Path.home() / ".shodan_iplookup.conf"


def load_api_key(config_path: Path = CONFIG_PATH_DEFAULT) -> str:
    """
    Load the Shodan API key from a simple INI-style config file:

        [shodan]
        api_key = YOUR_API_KEY

    Raises SystemExit on error.
    """
    if not config_path.exists():
        print(f"Error: config file not found at {config_path}", file=sys.stderr)
        print("Create it with content like:", file=sys.stderr)
        print("[shodan]\napi_key = YOUR_API_KEY", file=sys.stderr)
        raise SystemExit(1)

    api_key = None
    section = None
    with config_path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or line.startswith(";"):
                continue
            if line.startswith("[") and line.endswith("]"):
                section = line[1:-1].strip().lower()
                continue
            if section == "shodan":
                if line.lower().startswith("api_key"):
                    parts = line.split("=", 1)
                    if len(parts) == 2:
                        api_key = parts[1].strip()
                        break

    if not api_key:
        print(f"Error: no 'api_key' found in [shodan] section of {config_path}", file=sys.stderr)
        raise SystemExit(1)

    return api_key


def check_jq_installed() -> bool:
    """
    Return True if jq is available on PATH, False otherwise.
    """
    try:
        subprocess.run(
            ["jq", "--version"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        return True
    except FileNotFoundError:
        return False


def pretty_print_with_jq(data: dict) -> None:
    """
    Pretty-print JSON using jq if installed, otherwise fall back
    to Python's json.dumps(indent=2).
    """
    if check_jq_installed():
        try:
            proc = subprocess.run(
                ["jq", "."],
                input=json.dumps(data).encode("utf-8"),
                stdout=sys.stdout,
                stderr=sys.stderr,
                check=False,
            )
            if proc.returncode != 0:
                print(
                    "\nWarning: jq returned a non-zero exit code, "
                    "falling back to Python JSON pretty print.\n",
                    file=sys.stderr,
                )
                print(json.dumps(data, indent=2, sort_keys=True))
        except Exception as e:
            print(
                f"Warning: failed to use jq ({e}), falling back to Python JSON pretty print.\n",
                file=sys.stderr,
            )
            print(json.dumps(data, indent=2, sort_keys=True))
    else:
        print("Note: 'jq' is not installed. Using Python's JSON pretty print.\n", file=sys.stderr)
        print(json.dumps(data, indent=2, sort_keys=True))


def prompt_for_ip() -> str:
    """
    Prompt the user for an IP address if not provided as a CLI argument.
    Validates that it is a syntactically correct IPv4 or IPv6 address.
    """
    try:
        ip = input("Enter an IP address to look up (or 'q' to quit): ").strip()
    except EOFError:
        raise SystemExit(0)

    if ip.lower() in ("q", "quit", "exit"):
        raise SystemExit(0)

    if not ip:
        print("Error: IP address cannot be empty.", file=sys.stderr)
        raise SystemExit(1)

    # Validate IPv4/IPv6 using standard library
    try:
        ipaddress.ip_address(ip)
    except ValueError:
        print(f"Error: '{ip}' is not a valid IPv4 or IPv6 address.", file=sys.stderr)
        raise SystemExit(1)

    return ip


def validate_ip_cli_arg(ip: str) -> str:
    """
    Validate IP address provided via CLI argument.
    Mirrors the checks in prompt_for_ip() and supports IPv4/IPv6.
    """
    ip = ip.strip()
    if not ip:
        print("Error: IP address argument cannot be empty or whitespace.", file=sys.stderr)
        raise SystemExit(1)

    try:
        ipaddress.ip_address(ip)
    except ValueError:
        print(f"Error: '{ip}' is not a valid IPv4 or IPv6 address.", file=sys.stderr)
        raise SystemExit(1)

    return ip


def lookup_ip(api: shodan.Shodan, ip: str) -> dict:
    """
    Perform the Shodan IP lookup using the official library.
    Supports both IPv4 and IPv6 addresses.
    """
    try:
        info = api.host(ip)
        return info
    except shodan.APIError as e:
        print(f"Shodan API error: {e}", file=sys.stderr)
        raise SystemExit(1)


def main() -> None:
    # Correct handling of SHODAN_IPLOOKUP_CONFIG vs default Path
    if "SHODAN_IPLOOKUP_CONFIG" in os.environ:
        config_path = Path(os.environ["SHODAN_IPLOOKUP_CONFIG"])
    else:
        config_path = CONFIG_PATH_DEFAULT

    api_key = load_api_key(config_path)
    api = shodan.Shodan(api_key)

    # IP from CLI (arg1) or interactive prompt, with validation
    if len(sys.argv) > 1:
        ip = validate_ip_cli_arg(sys.argv[1])
    else:
        ip = prompt_for_ip()

    print(f"\nLooking up IP in Shodan: {ip}\n")

    info = lookup_ip(api, ip)

    # Pretty-print the full JSON response using jq when available
    pretty_print_with_jq(info)


if __name__ == "__main__":
    main()
