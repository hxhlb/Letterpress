#!/bin/sh

set -e

cd "$(dirname "$0")"/..

export PATH
PATH="$PATH:$(pwd)/devkit/"

rm -rf build || true
mkdir -p build/Payload
mkdir -p packages

THEOS="$HOME/theos"
if [ ! -d "$THEOS" ]; then
  THEOS="$GITHUB_WORKSPACE/theos"
fi

xcodebuild clean build archive \
    -scheme Letterpress-iOS \
    -project Letterpress.xcodeproj \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -archivePath Letterpress \
    CODE_SIGNING_ALLOWED=NO \
    THEOS="$THEOS" \
    | xcbeautify

cp Letterpress/Resources/App-iOS.entitlements Letterpress.xcarchive/Products
cd Letterpress.xcarchive/Products/Applications
codesign --remove-signature Letterpress.app
cd -
cd Letterpress.xcarchive/Products
mv Applications Payload
ldid -SApp-iOS.entitlements Payload/Letterpress.app
7z a -tzip -mm=LZMA Letterpress.tipa Payload
mv Payload Applications
cd -
mkdir -p packages

if [ -n "$DEBUG" ]; then
XCCONFIG_NAME=Letterpress/Version.Debug.xcconfig
if [ ! -f $XCCONFIG_NAME ]; then
  echo "Versioning configuration not found!"
  exit 1
fi
previous_version=$(cat $XCCONFIG_NAME | grep 'DEBUG_VERSION =' | awk -F "=" '/DEBUG_VERSION/ {print $2}' | tr -d ' ')
previous_build_number=$(cat $XCCONFIG_NAME | grep 'DEBUG_BUILD_NUMBER =' | awk -F "=" '/DEBUG_BUILD_NUMBER/ {print $2}' | tr -d ' ')
else
XCCONFIG_NAME=Letterpress/Version.xcconfig
if [ ! -f $XCCONFIG_NAME ]; then
  echo "Versioning configuration not found!"
  exit 1
fi
previous_version=$(cat $XCCONFIG_NAME | grep 'VERSION =' | awk -F "=" '/VERSION/ {print $2}' | tr -d ' ')
previous_build_number=$(cat $XCCONFIG_NAME | grep 'BUILD_NUMBER =' | awk -F "=" '/BUILD_NUMBER/ {print $2}' | tr -d ' ')
fi

mv Letterpress.xcarchive/Products/Letterpress.tipa "packages/Letterpress_$previous_version-$previous_build_number.tipa"
