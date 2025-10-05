# Weave Scope Scanner

## Overview
Weave Scope Scanner is a professional network reconnaissance tool designed to discover Weave Scope instances and other web services across network ranges. It provides comprehensive port scanning capabilities with intelligent service detection and colorful, structured output.

## Features
- **Dual Scan Modes**: Single IP targeting and IP range scanning
- **Intelligent Service Detection**: Automatic identification of Weave Scope dashboards
- **Comprehensive Port Scanning**: Checks common Weave Scope and web service ports
- **Network Range Support**: /24, /16, and /8 subnet scanning capabilities
- **Real-time Results**: Color-coded output with live progress indication
- **Efficient Scanning**: Utilizes nmap for fast and reliable network discovery
- **Detailed Reporting**: Structured results display with summary statistics

## Usage
1. Download the script to your local machine
2. Make it executable: `chmod +x weave_scope_scanner.sh`
3. Run the script: `./weave_scope_scanner.sh`
4. Follow the interactive prompts to select scan mode and targets
5. View real-time results and final summary report

## Scan Modes

### Single IP Scan
- Targets a specific IP address
- Scans common Weave Scope and web service ports
- Ideal for focused reconnaissance

### IP Range Scan
- Supports three subnet sizes:
  - **/24** (256 hosts) - Fast scan
  - **/16** (65,536 hosts) - Medium scan
  - **/8** (16,777,216 hosts) - Comprehensive scan
- Efficiently scans large network ranges

## Ports Scanned
The tool checks these common service ports:
- **Weave Scope**: 4040
- **Web Services**: 80, 443, 8080, 8081, 3000, 5000, 8000, 8001, 8443, 9443

## Requirements
- **Operating System**: Linux
- **Dependencies**:
  - `nmap` - Network scanning tool
  - `curl` - HTTP client for service detection
  - `bash` - Shell environment

### Installation on Ubuntu/Debian:
```bash
sudo apt update
sudo apt install nmap curl

## License
This project is licensed under the MIT License.

## Author
MehranTurk (M.T)

## *Donate*

USDT: TSVd8USqUv1B1dz6Hw3bUCQhLkSz1cLE1v

TRX: TSVd8USqUv1B1dz6Hw3bUCQhLkSz1cLE1v

BTC: 32Sxd8UJav7pERtL9QbAStWuFJ4aMHaZ9g

ETH: 0xb2ba6B8CbB433Cb7120127474aEF3B1281C796a6
