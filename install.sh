#!/bin/bash
echo -e "Updating apt..."
apt update >/dev/null 2>&1
echo -e "Installing cURL..."
apt install -y curl >/dev/null 2>&1
echo -e "\nMounting to server directory"
mkdir -p /mnt/server >/dev/null 2>&1
cd /mnt/server >/dev/null 2>&1
echo -e "Pulling README.txt"
curl -o README.txt https://raw.githubusercontent.com/DerLev/McMineserver-ServerPanel/81328e91020102dc864aa663a7b83186fe67fa19/README.txt >/dev/null 2>&1
echo -e "\n\n=== Install Complete ==="
