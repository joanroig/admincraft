#!/bin/bash

# Define variables
DAYS=365
CA_KEY=ca.key
CA_CERT=ca.crt
SERVER_KEY=server.key
SERVER_CSR=server.csr
SERVER_CERT=server.crt
SERVER_EXT=server.ext
COMMON_NAME="YOUR_IP_HERE"

# Step 1: Generate CA key and certificate
echo "Generating CA key and certificate..."
openssl genrsa -out $CA_KEY 2048
openssl req -x509 -new -nodes -key $CA_KEY -sha256 -days $DAYS -out $CA_CERT -subj "/C=US/ST=State/L=City/O=MyCA/CN=MyCA"

# Step 2: Generate server key and CSR (Certificate Signing Request)
echo "Generating server key and CSR..."
openssl genrsa -out $SERVER_KEY 2048
openssl req -new -key $SERVER_KEY -out $SERVER_CSR -subj "/C=US/ST=State/L=City/O=MyServer/CN=$COMMON_NAME"

# Step 3: Create a config file for the subjectAltName
cat > $SERVER_EXT <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1 = $COMMON_NAME
EOF

# Step 4: Sign the server certificate with the CA certificate
echo "Signing the server certificate with the CA certificate..."
openssl x509 -req -in $SERVER_CSR -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial \
-out $SERVER_CERT -days $DAYS -sha256 -extfile $SERVER_EXT

# Step 5: Provide instructions for importing the CA certificate on the PC
echo "Generated CA and server certificates."
echo "Use '$SERVER_CERT' when connecting with Admincraft."
echo "To trust the CA certificate on your PC, follow the instructions below:"
echo "1. On Windows, double-click on '$CA_CERT' and install it in the 'Trusted Root Certification Authorities' store."
echo "2. On macOS, open '$CA_CERT' and add it to the Keychain Access under 'System' keychain as a trusted certificate."
echo "3. On Linux, copy '$CA_CERT' to '/usr/local/share/ca-certificates/' and run 'sudo update-ca-certificates'."
