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
SERVER_IP="10.0.0.1/24" 
LISTEN_PORT=80
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
echo "Generating client keys and configurations..."
mkdir -p /etc/wireguard/clients
cd /etc/wireguard/clients

SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
SERVER_PUBLIC_IP=$(curl -s ifconfig.me)
echo "Server public IP: ${SERVER_PUBLIC_IP}"
SERVER_ENDPOINT="${SERVER_PUBLIC_IP}:${LISTEN_PORT}" 

# Generate configs for 3 clients
for i in 1 2 3; do
  CLIENT_NAME="client${i}"
  CLIENT_IP="10.0.0.$((i + 1))/32"  # client1: 10.0.0.2, client2: 10.0.0.3, etc.

  echo "Creating keys and config for ${CLIENT_NAME} with IP ${CLIENT_IP}..."

  wg genkey | tee ${CLIENT_NAME}_private.key | wg pubkey > ${CLIENT_NAME}_public.key

  CLIENT_PRIVATE_KEY=$(cat ${CLIENT_NAME}_private.key)
  CLIENT_PUBLIC_KEY=$(cat ${CLIENT_NAME}_public.key)

  cat > ${CLIENT_NAME}.conf << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_IP}
DNS = 1.1.1.1, 8.8.8.8, 9.9.9.9  # Using Cloudflare, Google, and Quad9 DNS

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${SERVER_ENDPOINT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

  # Add client to server config
  wg set wg0 peer ${CLIENT_PUBLIC_KEY} allowed-ips ${CLIENT_IP}
done

# Save updated server config
wg-quick save wg0

echo "Done generating clients. Config files are in /etc/wireguard/clients/"
echo "WireGuard server setup complete!"
echo "Client configuration saved at /etc/wireguard/clients/${CLIENT_NAME}.conf"
echo "You can generate a QR code for mobile clients with:"
echo "sudo cat /etc/wireguard/clients/client1.conf | qrencode -t ansiutf8
"
