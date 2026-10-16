#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Build AeroSpace.app + aerospace CLI from this branch and install them.

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

if ! test -d "$DEVELOPER_DIR"; then
    echo "Xcode is not installed. Get it from developer.apple.com/xcode" >&2
    exit 1
fi

APP_SRC="xcode/.xcode-build/Build/Products/Release/AeroSpace.app"
CLI_SRC=".build/release/aerospace"

# refuse a dirty tree, generate.sh writes to tracked files
if test -n "$(git status --porcelain)"; then
    echo "Uncommitted changes. Commit or stash first." >&2
    git status --short >&2
    exit 1
fi

# revert generate.sh's writes even if the build fails
trap 'git checkout . >/dev/null 2>&1 || true' EXIT

VERSION="$(git describe --tags --abbrev=0 | sed 's/^v//')-mybuild"
echo "==> $VERSION ($(git rev-parse --short HEAD))"

echo "==> generate"
./generate.sh --build-version "$VERSION" --generate-git-hash >/dev/null

echo "==> cli"
swift build -c release --product aerospace
codesign -s - --force "$CLI_SRC"

echo "==> app"
( cd xcode && xcodebuild -scheme AeroSpace -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath .xcode-build \
    CODE_SIGN_IDENTITY="-" clean build ) >/dev/null
codesign -v "$APP_SRC"

echo "==> install"
osascript -e 'quit app "AeroSpace"' >/dev/null 2>&1 || true
sleep 2
rm -rf /Applications/AeroSpace.app
cp -r "$APP_SRC" /Applications/
sudo cp "$CLI_SRC" /usr/local/bin/aerospace

echo
echo "Installed $VERSION"
echo "Re-grant Accessibility: the ad-hoc signature changes every build."
