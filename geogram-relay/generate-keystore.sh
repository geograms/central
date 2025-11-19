#!/bin/bash

# Generate a self-signed SSL certificate for development/testing
# For production, use a proper certificate from Let's Encrypt or a CA

KEYSTORE_FILE="keystore.jks"
KEYSTORE_PASSWORD="changeit"
VALIDITY_DAYS=365
ALIAS="geogram-relay"

echo "==========================================="
echo "Geogram Relay - SSL Keystore Generator"
echo "==========================================="
echo ""

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo "WARNING: $KEYSTORE_FILE already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    rm -f "$KEYSTORE_FILE"
fi

# Get hostname/IP for certificate
echo "Enter the hostname or IP address for the certificate"
echo "(This should match how clients will connect to the server)"
read -p "Hostname/IP [localhost]: " HOSTNAME
HOSTNAME=${HOSTNAME:-localhost}

echo ""
echo "Generating self-signed certificate..."
echo "  Hostname: $HOSTNAME"
echo "  Alias: $ALIAS"
echo "  Validity: $VALIDITY_DAYS days"
echo "  Keystore: $KEYSTORE_FILE"
echo ""

# Generate keystore with self-signed certificate
keytool -genkeypair \
    -alias "$ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity $VALIDITY_DAYS \
    -keystore "$KEYSTORE_FILE" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEYSTORE_PASSWORD" \
    -dname "CN=$HOSTNAME, OU=Geogram, O=Geogram, L=Unknown, ST=Unknown, C=XX" \
    -ext "SAN=dns:$HOSTNAME,dns:localhost,ip:127.0.0.1"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Keystore generated successfully: $KEYSTORE_FILE"
    echo ""
    echo "To enable SSL in the relay server:"
    echo "1. Edit config.json and set:"
    echo "   \"enableSsl\": true"
    echo "   \"keystorePath\": \"$KEYSTORE_FILE\""
    echo "   \"keystorePassword\": \"$KEYSTORE_PASSWORD\""
    echo ""
    echo "2. Restart the relay server"
    echo ""
    echo "NOTE: This is a self-signed certificate for development/testing only."
    echo "For production, use a certificate from Let's Encrypt or a trusted CA."
    echo ""
    echo "SECURITY WARNING: Change the default password in config.json!"
else
    echo "✗ Failed to generate keystore"
    exit 1
fi
