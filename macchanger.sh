#!/bin/bash

# Script to change MAC address and restart network services
# This script will stop Tor and NetworkManager, change MAC address,
# then restart everything

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Check if wireless interface is provided as argument
INTERFACE=${1:-wlan0}

echo -e "${YELLOW}[+] Starting MAC address change process for $INTERFACE...${NC}"

# Stop Tor service
echo -e "${YELLOW}[1/7] Stopping Tor service...${NC}"
sudo systemctl stop tor
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓] Tor stopped successfully${NC}"
else
    echo -e "${RED}[✗] Failed to stop Tor${NC}"
fi

# Stop NetworkManager
echo -e "${YELLOW}[2/7] Stopping NetworkManager...${NC}"
sudo systemctl stop NetworkManager
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓] NetworkManager stopped successfully${NC}"
else
    echo -e "${RED}[✗] Failed to stop NetworkManager${NC}"
fi

# Bring interface down
echo -e "${YELLOW}[3/7] Bringing $INTERFACE down...${NC}"
sudo ip link set $INTERFACE down
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓] $INTERFACE is down${NC}"
else
    echo -e "${RED}[✗] Failed to bring $INTERFACE down${NC}"
    exit 1
fi

# Change MAC address
echo -e "${YELLOW}[4/7] Changing MAC address for $INTERFACE...${NC}"
sudo macchanger -r $INTERFACE
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓] MAC address changed successfully${NC}"
else
    echo -e "${RED}[✗] Failed to change MAC address${NC}"
    exit 1
fi

# Bring interface up
echo -e "${YELLOW}[5/7] Bringing $INTERFACE up...${NC}"
sudo ip link set $INTERFACE up
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓] $INTERFACE is up${NC}"
else
    echo -e "${RED}[✗] Failed to bring $INTERFACE up${NC}"
    exit 1
fi

# Start Tor service
echo -e "${YELLOW}[6/7] Starting Tor service...${NC}"
sudo systemctl start tor
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓] Tor started successfully${NC}"
else
    echo -e "${RED}[✗] Failed to start Tor${NC}"
fi

# Start NetworkManager
echo -e "${YELLOW}[7/7] Starting NetworkManager...${NC}"
sudo systemctl start NetworkManager
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓] NetworkManager started successfully${NC}"
else
    echo -e "${RED}[✗] Failed to start NetworkManager${NC}"
fi

echo -e "${GREEN}[+] MAC address change process completed!${NC}"

# Display current MAC address
echo -e "${YELLOW}[+] Current MAC address for $INTERFACE:${NC}"
ip link show $INTERFACE | grep -oE '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}'

# Check Tor status
echo -e "${YELLOW}[+] Tor service status:${NC}"
systemctl status tor --no-pager | grep "Active:"

echo -e "${GREEN}[+] Done!${NC}"
