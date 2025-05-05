#!/bin/bash
# WireGuard VPN Server Setup Script
# This script will install and configure a WireGuard VPN server on Ubuntu/Debian
set -e

# Step 1: Update system and install WireGuard
echo "Updating system and installing WireGuard..."
apt update && apt upgrade -y
apt install -y wireguard wireguard-tools qrencode

# Step 2: Enable IP forwarding
echo "Enabling IP forwarding..."
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Step 3: Generate server keys
echo "Generating server keys..."
mkdir -p /etc/wireguard
cd /etc/wireguard
umask 077
wg genkey | tee server_private.key | wg pubkey > server_public.key

# Step 4: Create server configuration
echo "Creating server configuration..."
SERVER_PRIVATE_KEY=$(cat server_private.key)
SERVER_IP="10.0.0.1/24" # VPN internal subnet
LISTEN_PORT=51820  # Standard WireGuard port
EXTERNAL_INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')

cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = ${SERVER_PRIVATE_KEY}
Address = ${SERVER_IP}
ListenPort = ${LISTEN_PORT}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${EXTERNAL_INTERFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${EXTERNAL_INTERFACE} -j MASQUERADE
SaveConfig = true

# Peers will be added automatically when you add clients
EOF

# Step 5: Enable and start WireGuard service
echo "Enabling and starting WireGuard service..."
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Step 6: Generate client keys and configuration
echo "Generating client keys and configuration..."
CLIENT_NAME="client1"
mkdir -p /etc/wireguard/clients
cd /etc/wireguard/clients
wg genkey | tee ${CLIENT_NAME}_private.key | wg pubkey > ${CLIENT_NAME}_public.key

CLIENT_PRIVATE_KEY=$(cat ${CLIENT_NAME}_private.key)
CLIENT_IP="10.0.0.2/32"  # First client IP
SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
SERVER_PUBLIC_IP=$(curl -s ifconfig.me)
echo "Server public IP: ${SERVER_PUBLIC_IP}"
SERVER_ENDPOINT="${SERVER_PUBLIC_IP}:${LISTEN_PORT}" 

cat > ${CLIENT_NAME}.conf << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_IP}
DNS = 1.1.1.1, 8.8.8.8  # Using Cloudflare and Google DNS

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${SERVER_ENDPOINT}
AllowedIPs = 0.0.0.0/0  # Route all traffic through VPN
PersistentKeepalive = 25  # Important for NAT traversal
EOF

# Add client to server configuration
wg set wg0 peer $(cat ${CLIENT_NAME}_public.key) allowed-ips ${CLIENT_IP}
wg-quick save wg0

echo "WireGuard server setup complete!"
echo "Client configuration saved at /etc/wireguard/clients/${CLIENT_NAME}.conf"
echo "You can generate a QR code for mobile clients with:"
echo "qrencode -t ansiutf8 < /etc/wireguard/clients/${CLIENT_NAME}.conf"
