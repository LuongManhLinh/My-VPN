#!/bin/bash

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --client-name) i="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$i" ]]; then
    echo "Usage: $0 --client-name <number>"
    exit 1
fi

CLIENT_NAME="client${i}"
CLIENT_IP="10.0.0.$((i + 1))/32" 

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

echo "Client ${CLIENT_NAME} added successfully."
