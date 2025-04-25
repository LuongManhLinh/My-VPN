#!/bin/bash

set -e

echo "[+] Updating system..."
sudo apt update && sudo apt upgrade -y

echo "[+] Installing Docker and Docker Compose..."
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker

echo "[+] Creating WireGuard directory..."
mkdir -p ~/wireguard
cd ~/wireguard

echo "[+] Creating docker-compose.yml..."

cat > docker-compose.yml <<EOF
version: "3.8"

services:
  wireguard:
    image: linuxserver/wireguard
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ho_Chi_Minh
      - SERVERURL=$(curl -s ifconfig.me)
      - SERVERPORT=443
      - PEERS=client1
      - PEERDNS=auto
      - INTERNAL_SUBNET=10.13.13.0
    volumes:
      - ./config:/config
      - /lib/modules:/lib/modules
    ports:
      - "443:51820/udp"
    restart: unless-stopped
EOF

echo "[+] Starting WireGuard container..."
sudo docker-compose up -d

echo "[✅] WireGuard VPN is set up!"
echo "[👉] Config file: ~/wireguard/config/peer_client1/peer_client1.conf (may take a few seconds to generate)"
