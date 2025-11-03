# Code Space

A collection of utility scripts and testing examples for various programming tasks.

## Contents

This repository contains the following key files:

- `iplookup.sh`: A Bash script for IP address lookup and analysis
- `python-test.py`: A Python test suite demonstrating data types and operations

## IP Lookup Script

### Description
The IP lookup script (`iplookup.sh`) retrieves geographical and network information for IP addresses using two services:
- IPinfo.io - Provides basic geographical and network information
- IPQualityScore - Provides additional IP intelligence and threat assessment (optional)

### Features
- Supports both IPv4 and IPv6 addresses
- Automatic IP address format validation
- 10-second timeout for API calls
- Rate limit detection
- Error handling for API failures
- Pretty-printed JSON output with jq (if installed)
- Configuration via environment variables or config file
- Help message via -h or --help flags

### Prerequisites
- `bash` shell
- `curl` for making HTTP requests
- `jq` (optional but recommended) for JSON formatting

### Installation
1. Clone the repository:
```bash
git clone https://github.com/lamontsession/code-space.git
cd code-space
```

2. Make the script executable:
```bash
chmod +x iplookup.sh
```

### Configuration
You can configure API tokens in three ways:

1. Environment variables:
```bash
export IPINFO_TOKEN="your_ipinfo_token"  # For IPinfo.io service
export IPQS_API_KEY="your_ipqs_api_key"  # For IPQualityScore service (optional)
```

2. Configuration file:
Create `~/.iplookup.conf` with:
```bash
IPINFO_TOKEN="your_ipinfo_token"  # For IPinfo.io service
IPQS_API_KEY="your_ipqs_api_key"  # For IPQualityScore service (optional)
```

3. Interactive input:
If no tokens are found in environment variables or the configuration file, the script will prompt you to enter them manually during execution. You can:
- Choose to enter an IPinfo.io token
- Choose to enter an IPQualityScore API key
- Skip either or both to use the services without authentication

Note: The script works without API tokens but with rate limitations. Using API tokens provides higher rate limits and additional features. The script will use the first available token it finds in the order: environment variables → configuration file → manual input.

### Usage
```bash
./iplookup.sh <IP_ADDRESS>    # Look up specific IP address
./iplookup.sh                 # Interactive prompt for IP address
./iplookup.sh -h             # Show help message
./iplookup.sh --help        # Show help message
```

### Output Format
The script provides:
1. IPinfo.io results showing:
   - Geographical location (city, region, country)
   - Network information (ASN, organization)
   - Coordinates (latitude/longitude)

2. IPQualityScore results (if API key provided) showing:
   - Fraud score and risk assessment
   - VPN/Proxy detection
   - Additional threat intelligence

Results are formatted as pretty-printed JSON when `jq` is installed, or raw JSON otherwise.

## Python Test Suite

### Description
The Python test suite (`python-test.py`) demonstrates various Python data types, operations, and testing practices using the unittest framework.

### Prerequisites
- Python 3.x

### Running Tests
```bash
python3 python-test.py
```

The test suite covers:
- Boolean operations
- Numeric types (int, float)
- String operations
- Type conversions
- Arithmetic operations

## Contributing

1. Fork the repository
2. Create your additions branch (`git checkout -b additions/programV2`)
3. Commit your changes (`git commit -m 'Added some new features'`)
4. Push to the branch (`git push origin additions/programV2`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

LaMont Session

## Last Updated

2025-11-02