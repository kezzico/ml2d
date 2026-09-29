#!/bin/bash
# build and run on ios
set -euo pipefail

if [ -f .env ]; then
  echo "Loading environment variables from .env"
  source .env
else
  echo "No .env file found."
  
#   68WTNC8XPF
fi

if [ -z "${APPLE_TEAM_ID:-}" ]; then
  read -r -p "Enter Apple Team ID: " APPLE_TEAM_ID
  export APPLE_TEAM_ID
  printf 'APPLE_TEAM_ID=%s\n' "$APPLE_TEAM_ID" >> .env
fi

if [ -z "${IOS_APP_ID:-}" ]; then
  read -r -p "Enter iOS bundle identifier: " IOS_APP_ID
  export IOS_APP_ID
  printf 'IOS_APP_ID=%s\n' "$IOS_APP_ID" >> .env
fi

if [ -z "${IOS_APP_NAME:-}" ]; then
  read -r -p "Enter App Display Name: " IOS_APP_NAME
  export IOS_APP_NAME
  printf 'IOS_APP_NAME=%s\n' "$IOS_APP_NAME" >> .env
fi

# Default version to 1.0.0
if [ -z "${IOS_VERSION:-}" ]; then
  IOS_VERSION="1.0.0"
  export IOS_VERSION
  printf 'IOS_VERSION=%s\n' "$IOS_VERSION" >> .env
fi

# Start build number at 1 and increment on every build
if [ -z "${IOS_BUILD_NUMBER:-}" ]; then
  IOS_BUILD_NUMBER=1
else
  IOS_BUILD_NUMBER=$((IOS_BUILD_NUMBER + 1))
fi

export IOS_BUILD_NUMBER

# Replace the existing value in .env
if grep -q '^IOS_BUILD_NUMBER=' .env; then
  sed -i '' "s/^IOS_BUILD_NUMBER=.*/IOS_BUILD_NUMBER=$IOS_BUILD_NUMBER/" .env
else
  printf 'IOS_BUILD_NUMBER=%s\n' "$IOS_BUILD_NUMBER" >> .env
fi


if [ ! -d "ios" ]; then
  echo "iOS directory not found. Cloning from main branch..."
  git clone --branch main --recurse-submodules https://github.com/love2d/love ios

  pushd ios
  echo "cloning apple dependencies"
  git clone https://github.com/love2d/love-apple-dependencies.git
  pushd platform/xcode
  
  echo "linking apple depedencies"
  pushd ios
  ln -s ../../../love-apple-dependencies/iOS/libraries
  popd
  ln -s ../../love-apple-dependencies/shared/
  ln -s ../../love-apple-dependencies/macOS/
  popd
  popd
fi

# bundle the game assets into dist/
./ml2d/scripts/bundle.sh
cp dist/app.love ios/platform/xcode/app.love

if ! grep -q 'app.love in Resources' ios/platform/xcode/love.xcodeproj/project.pbxproj; then
    echo "attaching bundle to xcode project"
    git -C ios apply ../ml2d/scripts/xcode-patch.diff
fi

# TODO: remove love file loading permissions from the plist

echo "building for iOS with latest Löve bundle..."

pushd ios/platform/xcode
# ios/platform/xcode/ios/love-ios.plist
PLIST="ios/love-ios.plist"

echo "Setting iOS bundle identifier: $IOS_APP_ID"

# plist buddy is replaced by variables injected into xcode build
# /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $IOS_APP_ID" "$PLIST"
# /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $IOS_APP_NAME" "$PLIST"
# /usr/libexec/PlistBuddy -c "Set :CFBundleName $IOS_APP_NAME" "$PLIST"
# /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $IOS_VERSION" "$PLIST"
# /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $IOS_BUILD_NUMBER" "$PLIST"

BUILD_DIR=build/Release-iphoneos

xcodebuild \
  -project love.xcodeproj \
  -scheme liblove-ios \
  -configuration Release \
  -sdk iphoneos \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  build

xcodebuild \
  -project love.xcodeproj \
  -scheme love-ios \
  -configuration Release \
  -sdk iphoneos \
  CONFIGURATION_BUILD_DIR=$BUILD_DIR \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$IOS_APP_ID" \
  MARKETING_VERSION="$IOS_VERSION" \
  CURRENT_PROJECT_VERSION="$IOS_BUILD_NUMBER" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  build

while true; do
    devices=$(xcrun devicectl list devices | tail -n +3)

    device_ids=()
    device_names=()

    while IFS= read -r line; do
        identifier=$(echo "$line" | grep -oE '[0-9A-F-]{36}')
        [ -z "$identifier" ] && continue

        state=$(echo "$line" | sed -E "s/.*$identifier[[:space:]]+([^[:space:]]+).*/\1/")
        [ "$state" = "unavailable" ] && continue

        name=$(echo "$line" | sed -E "s/[[:space:]]+$identifier.*//")

        device_ids+=("$identifier")
        device_names+=("$name")
    done <<< "$devices"

    if [ "${#device_ids[@]}" -eq 0 ]; then
        echo
        echo "No available iOS devices found."
        echo
        read -r -p "Connect/trust a device, then press Enter to check again (q to quit): " retry

        if [ "$retry" = "q" ]; then
            exit 0
        fi

        continue
    fi

    echo
    echo "Available iOS devices:"
    echo

    for i in "${!device_ids[@]}"; do
        printf "%d) %s\n" "$((i + 1))" "${device_names[$i]}"
    done

    echo
    read -r -p "Select device [1]: " selection
    selection=${selection:-1}

    if [[ "$selection" =~ ^[0-9]+$ ]] &&
       [ "$selection" -ge 1 ] &&
       [ "$selection" -le "${#device_ids[@]}" ]; then

        DEVICE_ID="${device_ids[$((selection - 1))]}"
        echo "Selected: ${device_names[$((selection - 1))]}"

        # if xcrun fails give option to try again
        if xcrun devicectl device install app \
            --device "$DEVICE_ID" \
            "$BUILD_DIR/love.app"; then

            # launch the app
            xcrun devicectl device process launch \
                --device "$DEVICE_ID" \
                "$IOS_APP_ID"            

            popd
            break
        else
            echo "Install failed for $IOS_APP_NAME."
            read -r -p "Try again? [Y/n]: " retry
            if [[ "$retry" =~ ^[Nn]$ ]]; then
                popd
                exit 1
            fi
        fi

    else
        echo "Invalid device selection."
    fi
done

# Check for keystore and create one if not found

