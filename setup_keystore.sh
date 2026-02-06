#!/bin/bash

echo "🔐 Setting up Production Keystore for DormEase"
echo ""
echo "This will create a keystore file for signing your app."
echo ""

# Check if keystore already exists
if [ -f ~/upload-keystore.jks ]; then
    echo "⚠️  Keystore already exists at ~/upload-keystore.jks"
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Get keystore details
read -p "Enter store password (default: dormease2024): " STORE_PASS
STORE_PASS=${STORE_PASS:-dormease2024}

read -p "Enter key password (default: dormease2024): " KEY_PASS
KEY_PASS=${KEY_PASS:-dormease2024}

read -p "Enter your name: " NAME
NAME=${NAME:-DormEase}

read -p "Enter organization (default: DormEase): " ORG
ORG=${ORG:-DormEase}

# Generate keystore
echo ""
echo "🔨 Generating keystore..."

keytool -genkey -v \
    -keystore ~/upload-keystore.jks \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias upload \
    -storepass "$STORE_PASS" \
    -keypass "$KEY_PASS" \
    -dname "CN=$NAME, OU=Development, O=$ORG, L=Unknown, ST=Unknown, C=US"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore created successfully at ~/upload-keystore.jks"
    echo ""
    echo "📝 Updating key.properties..."
    
    # Update key.properties
    cat > android/key.properties << EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=upload
storeFile=$HOME/upload-keystore.jks
EOF
    
    echo "✅ key.properties updated!"
    echo ""
    echo "⚠️  IMPORTANT: Keep these credentials safe!"
    echo "   Store Password: $STORE_PASS"
    echo "   Key Password: $KEY_PASS"
    echo "   Keystore Location: ~/upload-keystore.jks"
else
    echo ""
    echo "❌ Failed to create keystore. Make sure Java is installed."
    echo "   Install Java: brew install openjdk"
    exit 1
fi
