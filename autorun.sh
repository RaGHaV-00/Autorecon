#!/bin/bash

# Check if arp-scan, nmap, and searchsploit are installed
if ! command -v arp-scan &> /dev/null || ! command -v nmap &> /dev/null || ! command -v searchsploit &> /dev/null; then
    echo "Please install arp-scan, nmap, and searchsploit to use this script."
    exit 1
fi

# Define the network interface to use (replace 'eth0' with your interface)
interface="eth0"

# Function to search for vulnerabilities using searchsploit
search_for_vulnerabilities() {
    local ip="$1"
    echo "Searching for vulnerabilities on $ip..."
    
    # Extract service names using nmap grepable output
    services=$(sudo nmap -sV --script=banner --script-args="http.useragent='Mozilla/5.0 Gecko/20100101 Firefox/91.0'" "$ip" -oG - | awk '/open/ {print $3}')
    
    # Loop through each service and search for exploits
    for service in $services; do
        echo "Searching for exploits for $service on $ip..."
        searchsploit "$service"
    done
}

# Run arp-scan with the specified interface and store results in an array
discovered_ips=()
while IFS= read -r line; do
    # Extract IP addresses only (ignore MAC addresses)
    if [[ $line =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
        discovered_ips+=("${BASH_REMATCH[1]}")
    fi
done < <(sudo arp-scan --interface="$interface" --localnet)

# Check if any IP addresses were found
if [ ${#discovered_ips[@]} -eq 0 ]; then
    echo "No IP addresses found."
else
    echo "Discovered IP addresses:"
    for ip in "${discovered_ips[@]}"; do
        echo "$ip"
        # Run nmap -p- on the discovered IP addresses
        echo "Running nmap on $ip..."
        sudo nmap "$ip"
        
        # Search for vulnerabilities using searchsploit
        search_for_vulnerabilities "$ip"
    done
fi

