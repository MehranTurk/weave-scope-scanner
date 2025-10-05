#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════╗"
echo "║         WEAVE SCOPE SCANNER          ║"
echo "║           PORT DISCOVERY             ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

# IP validation function
validate_ip() {
    local ip=$1
    local stat=1
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Scan mode selection
echo -e "${YELLOW}[MODE] Select scan mode:${NC}"
echo -e "${CYAN}[1] Single IP target"
echo -e "[2] IP range scan${NC}"
echo -e "${YELLOW}[CHOICE] Enter 1 or 2:${NC}"
read -r MODE_CHOICE

if [[ $MODE_CHOICE == "1" ]]; then
    # Single IP mode
    echo -e "${YELLOW}[INPUT] Enter target IP:${NC}"
    read -r TARGET_IP
    TARGET_IP=$(echo "$TARGET_IP" | tr -d ' ')
    
    while ! validate_ip "$TARGET_IP"; do
        echo -e "${RED}[!] Invalid IP address! Try again.${NC}"
        echo -e "${YELLOW}[INPUT] Enter target IP:${NC}"
        read -r TARGET_IP
        TARGET_IP=$(echo "$TARGET_IP" | tr -d ' ')
    done
    
    SCAN_MODE="single"
    echo -e "${CYAN}[*] Target: $TARGET_IP${NC}"
    
else
    # Range IP mode
    echo -e "${YELLOW}[INPUT] Enter target IP range (e.g., 192.168.1.0):${NC}"
    read -r BASE_IP
    BASE_IP=$(echo "$BASE_IP" | tr -d ' ')

    while ! validate_ip "$BASE_IP"; do
        echo -e "${RED}[!] Invalid IP address format! Try again.${NC}"
        echo -e "${YELLOW}[INPUT] Enter target IP range:${NC}"
        read -r BASE_IP
        BASE_IP=$(echo "$BASE_IP" | tr -d ' ')
    done

    echo -e "${YELLOW}[SUBNET] Select subnet mask:${NC}"
    echo -e "${CYAN}[1] /24 (256 hosts)     - Fast scan"
    echo -e "[2] /16 (65K hosts)     - Medium scan"  
    echo -e "[3] /8  (16M hosts)     - Hard scan${NC}"
    echo -e "${YELLOW}[CHOICE] Enter 1, 2 or 3:${NC}"
    read -r SUBNET_CHOICE

    case $SUBNET_CHOICE in
        1)
            SUBNET="$BASE_IP/24"
            TOTAL_IPS=256
            ;;
        2)
            SUBNET="$BASE_IP/16"
            TOTAL_IPS=65536
            ;;
        3)
            SUBNET="$BASE_IP/8"
            TOTAL_IPS=16777216
            ;;
        *)
            echo -e "${RED}[!] Invalid choice! Using /24 by default.${NC}"
            SUBNET="$BASE_IP/24"
            TOTAL_IPS=256
            ;;
    esac
    
    SCAN_MODE="range"
    echo -e "${CYAN}[*] Target Range: $SUBNET${NC}"
    echo -e "${CYAN}[*] Total IPs: $TOTAL_IPS${NC}"
fi

echo -e "${YELLOW}[*] Starting comprehensive port scan...${NC}"

# Weave Scope common ports
COMMON_PORTS="4040,80,443,8080,8081,3000,5000,8000,8001,8443,9443"

# Function to display results in box
display_results() {
    local found_services=("$@")
    
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════╗"
    echo "║           SCAN RESULTS               ║"
    echo "╠══════════════════════════════════════╣"
    
    if [ ${#found_services[@]} -eq 0 ]; then
        echo "║                                    ║"
        echo "║        No services found           ║"
        echo "║                                    ║"
    else
        for service in "${found_services[@]}"; do
            printf "║  %-34s  ║\n" "$service"
        done
    fi
    
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to display Weave Scope results in box
display_weave_results() {
    local weave_services=("$@")
    
    if [ ${#weave_services[@]} -gt 0 ]; then
        echo -e "${GREEN}"
        echo "╔══════════════════════════════════════╗"
        echo "║         WEAVE SCOPE FOUND           ║"
        echo "╠══════════════════════════════════════╣"
        for result in "${weave_services[@]}"; do
            printf "║  %-34s  ║\n" "$result"
        done
        echo "╚══════════════════════════════════════╝"
        echo -e "${NC}"
    fi
}

# Function to check service
check_service() {
    local ip=$1
    local port=$2
    
    echo -e "${BLUE}[→] Testing $ip:$port...${NC}"
    
    # Check if port is open with timeout
    timeout 2 bash -c "echo > /dev/tcp/$ip/$port" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Port $port is open on $ip${NC}"
        
        # Try HTTP
        http_response=$(curl -s --connect-timeout 3 "http://$ip:$port/" 2>/dev/null)
        if echo "$http_response" | grep -qi "weave-scope\|scope.*app\|container.*monitor\|graph.*table"; then
            echo -e "${GREEN}[🎯] WEAVE SCOPE FOUND: http://$ip:$port/${NC}"
            return 0
        fi
        
        # Try HTTPS
        https_response=$(curl -s -k --connect-timeout 3 "https://$ip:$port/" 2>/dev/null)
        if echo "$https_response" | grep -qi "weave-scope\|scope.*app\|container.*monitor\|graph.*table"; then
            echo -e "${GREEN}[🎯] WEAVE SCOPE FOUND: https://$ip:$port/${NC}"
            return 0
        fi
        
        # Check API endpoint
        api_response=$(curl -s --connect-timeout 3 "http://$ip:$port/api/topology" 2>/dev/null)
        if echo "$api_response" | grep -qi "nodes\|containers\|topology"; then
            echo -e "${GREEN}[🎯] WEAVE SCOPE API FOUND: http://$ip:$port/api/topology${NC}"
            return 0
        fi
        
        # Check for other services
        service_name="$ip:$port - Other Service"
        if echo "$http_response" | grep -qi "nginx"; then
            service_name="$ip:$port - Nginx"
        elif echo "$http_response" | grep -qi "apache"; then
            service_name="$ip:$port - Apache"
        elif echo "$http_response" | grep -qi "iis"; then
            service_name="$ip:$port - IIS"
        elif [ -n "$http_response" ]; then
            service_name="$ip:$port - Web Service"
        else
            service_name="$ip:$port - Unknown Service"
        fi
        
        echo -e "${YELLOW}[?] $service_name${NC}"
        RESULTS+=("$service_name")
        return 2
    else
        echo -e "${RED}[✗] Port $port closed on $ip${NC}"
        return 1
    fi
}

# Arrays to store results
declare -a RESULTS
declare -a WEAVE_SCOPE_FOUND
declare -a OPEN_PORTS

# Single IP scan
if [[ $SCAN_MODE == "single" ]]; then
    echo -e "${CYAN}[*] Scanning common ports on $TARGET_IP${NC}"
    for port in 4040 80 443 8080 8081 3000 5000 8000 8001 8443 9443; do
        check_service "$TARGET_IP" "$port"
        result_code=$?
        if [ $result_code -eq 0 ]; then
            WEAVE_SCOPE_FOUND+=("$TARGET_IP:$port - Weave Scope ✓")
        elif [ $result_code -eq 2 ]; then
            OPEN_PORTS+=("$TARGET_IP:$port")
        fi
    done

# Range IP scan - USING NMAP INSTEAD OF MASSCAN
else
    echo -e "${CYAN}[*] Starting nmap scan on range $SUBNET...${NC}"
    
    if ! command -v nmap &> /dev/null; then
        echo -e "${RED}[!] nmap not installed${NC}"
        echo -e "${YELLOW}[*] Install with: sudo apt install nmap${NC}"
        exit 1
    fi

    echo -e "${YELLOW}[*] Scanning $TOTAL_IPS hosts on common ports${NC}"
    
    # Run nmap scan
    echo -e "${CYAN}[*] Running nmap (this may take a while)...${NC}"
    
    # Use nmap to scan the range
    NMAP_OUTPUT="nmap_temp_$$.txt"
    
    # Scan common ports on the range
    nmap -p $COMMON_PORTS --open -oG "$NMAP_OUTPUT" "$SUBNET" 2>/dev/null

    # Parse nmap results
    echo -e "${CYAN}[*] Analyzing scan results...${NC}"
    
    if [[ -f "$NMAP_OUTPUT" ]]; then
        # Extract open ports from nmap output
        while IFS= read -r line; do
            if [[ $line =~ Host:\ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*Ports:\ (.*) ]]; then
                ip="${BASH_REMATCH[1]}"
                ports_line="${BASH_REMATCH[2]}"
                
                # Extract port numbers
                echo "$ports_line" | grep -oP '[0-9]+/open' | grep -oP '[0-9]+' | while read -r port; do
                    echo -e "${GREEN}[+] Open port: $ip:$port${NC}"
                    OPEN_PORTS+=("$ip:$port")
                    
                    # Check if this is Weave Scope
                    if check_service "$ip" "$port"; then
                        WEAVE_SCOPE_FOUND+=("$ip:$port - Weave Scope ✓")
                    fi
                done
            fi
        done < "$NMAP_OUTPUT"
        
        rm -f "$NMAP_OUTPUT"
    else
        echo -e "${RED}[!] Nmap output file not found!${NC}"
    fi
fi

# Display results
display_weave_results "${WEAVE_SCOPE_FOUND[@]}"
display_results "${RESULTS[@]}"

# Final summary
echo -e "${CYAN}"
echo "╔══════════════════════════════════════╗"
echo "║           SCAN COMPLETE              ║"
echo "╠══════════════════════════════════════╣"
if [[ $SCAN_MODE == "single" ]]; then
    printf "║  %-33s ║\n" "Mode: Single IP"
    printf "║  %-33s ║\n" "Target: $TARGET_IP"
else
    printf "║  %-33s ║\n" "Mode: Range Scan"
    printf "║  %-33s ║\n" "Target: $SUBNET"
    printf "║  %-33s ║\n" "IPs: $TOTAL_IPS hosts"
fi
printf "║  %-33s ║\n" "Weave Scope: ${#WEAVE_SCOPE_FOUND[@]} found"
printf "║  %-33s ║\n" "Other Services: ${#RESULTS[@]} found"
printf "║  %-33s ║\n" "Open Ports: ${#OPEN_PORTS[@]} found"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"
