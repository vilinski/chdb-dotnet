#!/bin/bash

# Get the newest release version
LATEST_RELEASE=$(curl --silent "https://api.github.com/repos/chdb-io/chdb/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LATEST_RELEASE" ]; then
    echo "Latest release not found"
    exit 1
fi
RELEASE=${1:-$LATEST_RELEASE}

# Download the correct version based on the platform
case "$(uname -s)" in
    Linux)
        if [[ $(uname -m) == "aarch64" ]]; then
            PLATFORM="linux-aarch64"
            RID="linux-arm64"
        else
            PLATFORM="linux-x86_64"
            RID="linux-x64"
        fi
        ;;
    Darwin)
        if [[ $(uname -m) == "arm64" ]]; then
            PLATFORM="macos-arm64"
            RID="osx-arm64"
        else
            PLATFORM="macos-x86_64"
            RID="osx-x64"
        fi
        ;;
    *)
        echo "Unsupported platform"
        exit 1
        ;;
esac
ARCH=${2:-$PLATFORM}

DOWNLOAD_URL="https://github.com/chdb-io/chdb/releases/download/$RELEASE/$ARCH-libchdb.tar.gz"

echo "Downloading $ARCH-libchdb.tar.gz from $DOWNLOAD_URL (latest is $LATEST_RELEASE)"

# Download the file
curl -L -o libchdb.tar.gz "$DOWNLOAD_URL"

# Untar the file
tar -xzf libchdb.tar.gz

# Set execute permission for libchdb.so
chmod +x libchdb.so

# Clean up
rm -f libchdb.tar.gz

# Move the libchdb.so to the correct runtime folder
mkdir -p "runtimes/$RID/native"
mv libchdb.so "runtimes/$RID/native/libchdb.so"