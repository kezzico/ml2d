#!/bin/bash
# build and run on android
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

  read -sp "Enter Keystore Password(default: android): " ANDROID_KEYSTORE_PASSWORD
  echo
  ANDROID_KEYSTORE_PASSWORD=${ANDROID_KEYSTORE_PASSWORD:-android}

  read -sp "Enter Key Password(default: same as keystore password): " ANDROID_KEY_PASSWORD
  echo
  ANDROID_KEY_PASSWORD=${ANDROID_KEY_PASSWORD:-android}

  read -p "Enter Android App ID (default: org.love2d.game): " ANDROID_APP_ID
  ANDROID_APP_ID=${ANDROID_APP_ID:-org.love2d.game}

  cat >> .env << EOF
ANDROID_KEY_ALIAS=$ANDROID_KEY_ALIAS
ANDROID_KEYSTORE_PASSWORD=$ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_PASSWORD=$ANDROID_KEY_PASSWORD
ANDROID_APP_ID=$ANDROID_APP_ID
EOF
# ^^^ make sure this EOF stays at the start of the line
fi

if [ ! -d "android" ]; then
  echo "Android directory not found. Cloning from main branch..."
  git clone --branch main --recurse-submodules https://github.com/love2d/love-android android
  # git clone https://github.com/love2d/love-android android
  # pushd android
  # git fetch --tags
  # git checkout 12.x
  git submodule sync --recursive
  git submodule update --init --force --recursive  
  # popd
fi

# Create dist directory
rm -rf dist
mkdir -p dist

echo "bundle love game source code and assets..."
# Compile all Lua files with LuaJIT
find . -name "*.lua" -type f -not -path "./android/*" | while read lua_file; do
  mkdir -p "dist/$(dirname "$lua_file")"
    #   if [ "$lua_file" != "conf.lua" ]; then  # Skip conf.lua as it's a special case
    #     echo "Compiling $lua_file..."
    #     luajit -b "$lua_file" "dist/${lua_file%.lua}.lua"
    # else
    #     cp "$lua_file" "dist/$lua_file"  # Copy conf.lua as-is
    # fi

  cp "$lua_file" "dist/$lua_file"
done
if [ -d "assets" ]; then
  cp -r assets "dist/assets"
fi

# Copy assets directory
cp -r assets dist/
rm -rf android/app/src/embed/assets/*
cp -r dist/ android/app/src/embed/assets/

echo "building for Android with latest Löve bundle..."
# Check for keystore and create one if not found
pushd android
if [ ! -f "release.keystore" ]; then
  echo "Creating keystore..."
  echo "Keystore not found. Setting up Android signing credentials..."

  keytool -genkey -v -keystore release.keystore -keyalg RSA -keysize 2048 -validity 10000 \
    -alias "$ANDROID_KEY_ALIAS" -storepass "$ANDROID_KEYSTORE_PASSWORD" -keypass "$ANDROID_KEY_PASSWORD" \
    -dname "CN=Rat Game, O=Game, C=US"
fi

if [ ! -z "${ANDROID_APP_ID:-}" ]; then
  echo "Using ANDROID_APP_ID from .env: $ANDROID_APP_ID"
  sed -i '' "s/^app.application_id=.*/app.application_id=$ANDROID_APP_ID/" gradle.properties
fi

./gradlew assembleEmbedNoRecordRelease \
  -Pandroid.injected.signing.store.file="$(pwd)/release.keystore" \
  -Pandroid.injected.signing.store.password="$ANDROID_KEYSTORE_PASSWORD" \
  -Pandroid.injected.signing.key.alias="$ANDROID_KEY_ALIAS" \
  -Pandroid.injected.signing.key.password="$ANDROID_KEY_PASSWORD" \
  --rerun-tasks

echo "Using APK at app/build/outputs/apk/embedNoRecord/release/app-embed-noRecord-release.apk"

# Install APK with retry loop
while true; do
  DEVICE=$(adb devices | grep -v attached | head -1 | awk '{print $1}')
  echo "installing to $DEVICE"
  if adb -s $DEVICE install -r app/build/outputs/apk/embedNoRecord/release/app-embed-noRecord-release.apk; then
    echo "Installation successful. Starting app and showing logs..."
    adb -s "$DEVICE" shell am start -n "$ANDROID_APP_ID/org.love2d.android.GameActivity"
    # adb -s "$DEVICE" logcat | grep "$ANDROID_APP_ID"
    adb -s "$DEVICE" logcat -c
    adb -s "$DEVICE" logcat |
      grep -E "$ANDROID_APP_ID|Vulkan|SDL/APP"
    # adb -s "$DEVICE" logcat -c
    # adb -s "$DEVICE" logcat -v threadtime
    break
  else
    read -p "Installation failed. Try again? (y/n): " retry
    if [[ "$retry" != "y" ]]; then
      exit 1
    fi
  fi
done

popd
