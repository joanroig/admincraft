#!/bin/bash

# ========================
# User Configuration
# ========================
# Replace with your domain name (e.g., *.example.com) or IP address (e.g., 192.168.1.1)
COMMON_NAME="*.example.com"  # Common Name for the certificate
DAYS=365                    # Certificate validity period in days

# ========================
# Script Variables
# ========================
CA_KEY=ca.key
CA_CERT=ca.crt
SERVER_KEY=server.key
SERVER_CSR=server.csr
SERVER_CERT=server.crt
SERVER_EXT=server.ext

# ========================
# Detect Input Type (IP or Domain)
# ========================
# Automatically determine if the input is an IP address or a domain name
if [[ "$COMMON_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  ALT_TYPE="IP"  # If it's an IP address, use IP.1
else
  ALT_TYPE="DNS"  # If it's a domain, use DNS.1
fi

# ========================
# Generate CA key and certificate
# ========================
openssl genrsa -out $CA_KEY 2048
openssl req -x509 -new -nodes -key $CA_KEY -sha256 -days $DAYS -out $CA_CERT -subj "/C=US/ST=State/L=City/O=MyCA/CN=MyCA"

# ========================
# Generate server key and CSR
# ========================
openssl genrsa -out $SERVER_KEY 2048
openssl req -new -key $SERVER_KEY -out $SERVER_CSR -subj "/C=US/ST=State/L=City/O=MyServer/CN=$COMMON_NAME"

# ========================
# Create a configuration file for subjectAltName
# ========================
cat > $SERVER_EXT <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
$ALT_TYPE.1 = $COMMON_NAME  # Use IP.1 or DNS.1 depending on the input type
EOF

# ========================
# Sign the server certificate
# ========================
openssl x509 -req -in $SERVER_CSR -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial \
-out $SERVER_CERT -days $DAYS -sha256 -extfile $SERVER_EXT

# ========================
# Output and Instructions
# ========================
echo "Generated CA and server certificates successfully!"
echo "Files created:"
echo "  - CA Key:        $CA_KEY"
echo "  - CA Certificate: $CA_CERT"
echo "  - Server Key:     $SERVER_KEY"
echo "  - Server CSR:     $SERVER_CSR"
echo "  - Server Certificate: $SERVER_CERT"
echo
echo "To trust the CA certificate on your PC:"
echo "  1. On Windows: Double-click '$CA_CERT' and install it in 'Trusted Root Certification Authorities'."
echo "  2. On macOS: Open '$CA_CERT' in Keychain Access and add it to the 'System' keychain as trusted."
echo "  3. On Linux: Copy '$CA_CERT' to '/usr/local/share/ca-certificates/' and run 'sudo update-ca-certificates'."
