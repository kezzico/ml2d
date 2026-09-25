#!/bin/bash
# build and release to Google Play
set -euo pipefail

# Prefer JAVA_HOME if already set
if [ -n "${JAVA_HOME:-}" ]; then
    export PATH="$JAVA_HOME/bin:$PATH"
fi

echo "Using Java:"
which java
java -version

if [ -f .env ]; then
    echo "Loading environment variables from .env"
    source .env
else
    echo "No .env file found."
    read -p "Enter Android Key Alias (default: key0): " ANDROID_KEY_ALIAS
    ANDROID_KEY_ALIAS=${ANDROID_KEY_ALIAS:-key0}

    read -sp "Enter Keystore Password: " ANDROID_KEYSTORE_PASSWORD
    echo
    
    read -sp "Enter Key Password: " ANDROID_KEY_PASSWORD
    echo
    
    read -p "Enter Android App ID (default: org.love2d.game): " ANDROID_APP_ID
    ANDROID_APP_ID=${ANDROID_APP_ID:-org.love2d.game}

    cat >> .env << EOF
ANDROID_KEY_ALIAS=$ANDROID_KEY_ALIAS
ANDROID_KEYSTORE_PASSWORD=$ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_PASSWORD=$ANDROID_KEY_PASSWORD
ANDROID_APP_ID=$ANDROID_APP_ID
EOF
fi

if [ ! -d "android" ]; then
    echo "Android directory not found. Cloning..."
    git clone --branch main --recurse-submodules https://github.com/love2d/love-android android
    git submodule sync --recursive
    git submodule update --init --force --recursive
fi

# Increment version code and prompt for version name
echo "Updating version in gradle.properties..."
CURRENT_VERSION_CODE=$(sed -n 's/^app\.version_code=\([0-9]*\).*/\1/p' android/gradle.properties)
NEW_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))
sed -i '' "s/^app.version_code=.*/app.version_code=$NEW_VERSION_CODE/" android/gradle.properties

read -p "Enter Android App Version Name (leave blank to keep current): " ANDROID_VERSION_NAME
if [ -n "$ANDROID_VERSION_NAME" ]; then
    sed -i '' "s/^app.version_name=.*/app.version_name=$ANDROID_VERSION_NAME/" android/gradle.properties
fi

# Create dist directory
rm -rf dist
mkdir -p dist

echo "Bundling love game source code and assets..."
find . -name "*.lua" -type f -not -path "./android/*" | while read lua_file; do
    mkdir -p "dist/$(dirname "$lua_file")"
    cp "$lua_file" "dist/$lua_file"
done

if [ -d "assets" ]; then
    cp -r assets dist/
fi

rm -rf android/app/src/embed/assets/*
cp -r dist/ android/app/src/embed/assets/

echo "Building AAB for Google Play..."
pushd android

if [ ! -f "release.keystore" ]; then
    echo "Creating keystore..."
    keytool -genkey -v -keystore release.keystore -keyalg RSA -keysize 2048 -validity 10000 \
        -alias "$ANDROID_KEY_ALIAS" -storepass "$ANDROID_KEYSTORE_PASSWORD" -keypass "$ANDROID_KEY_PASSWORD" \
        -dname "CN=Rat Game, O=Game, C=US"
fi

if [ ! -z "${ANDROID_APP_ID:-}" ]; then
    echo "Using ANDROID_APP_ID: $ANDROID_APP_ID"
    sed -i '' "s/^app.application_id=.*/app.application_id=$ANDROID_APP_ID/" gradle.properties
fi

./gradlew bundleEmbedNoRecordRelease \
    -Pandroid.injected.signing.store.file="$(pwd)/release.keystore" \
    -Pandroid.injected.signing.store.password="$ANDROID_KEYSTORE_PASSWORD" \
    -Pandroid.injected.signing.key.alias="$ANDROID_KEY_ALIAS" \
    -Pandroid.injected.signing.key.password="$ANDROID_KEY_PASSWORD" \
    --rerun-tasks

echo "AAB created at: app/build/outputs/bundle/embedNoRecordRelease/app-embedNoRecord-release.aab"
echo "Upload this file to Google Play Console"

open "app/build/outputs/bundle/embedNoRecordRelease/"

popd
