# Code Space

A collection of utility scripts and testing examples for various programming tasks.

## Contents

This repository contains the following key files:

- `iplookup.sh`: A Bash script for IP address lookup and analysis
- `python-test.py`: A Python test suite demonstrating data types and operations

## IP Lookup Script

### Description
The IP lookup script (`iplookup.sh`) retrieves geographical and network information for IP addresses using two services:
- IPinfo.io
- IPQualityScore

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
You can configure API tokens in two ways:

1. Environment variables:
```bash
export IPINFO_TOKEN="your_ipinfo_token"
export IPQS_API_KEY="your_ipqs_api_key"
```

2. Configuration file:
Create `~/.iplookup.conf` with:
```bash
IPINFO_TOKEN="your_ipinfo_token"
IPQS_API_KEY="your_ipqs_api_key"
```

### Usage
```bash
./iplookup.sh <IP_ADDRESS>    # Look up specific IP
./iplookup.sh                 # Interactive prompt
./iplookup.sh -h             # Show help message
```

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
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

LaMont Session

## Last Updated

2025-11-02