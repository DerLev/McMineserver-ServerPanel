#!/bin/bash
echo -e "Updating apt..."
apt update >/dev/null 2>&1
echo -e "Installing cURL..."
apt install -y curl >/dev/null 2>&1
echo -e "\nMounting to server directory"
mkdir -p /mnt/server >/dev/null 2>&1
cd /mnt/server >/dev/null 2>&1
echo -e "Pulling README.txt"
curl -o README.txt https://raw.githubusercontent.com/DerLev/McMineserver-ServerPanel/bd2587ccda4d6c20cde8eb1fec5eaa515b90e3a8/README.txt >/dev/null 2>&1
echo -e "Pulling .pteroignore"
curl -o .pteroignore https://raw.githubusercontent.com/DerLev/McMineserver-ServerPanel/bd2587ccda4d6c20cde8eb1fec5eaa515b90e3a8/.pteroignore >/dev/null 2>&1
echo -e "\n\n=== Install Complete ==="
