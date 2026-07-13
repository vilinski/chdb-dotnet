#!/bin/bash

determine_platform() {
    case "$(uname -s)" in
        Linux)
            if [[ $(uname -m) == "aarch64" ]]; then
                echo "linux-aarch64"
            else
                echo "linux-x86_64"
            fi
            ;;
        Darwin)
            if [[ $(uname -m) == "arm64" ]]; then
                echo "macos-arm64"
            else
                echo "macos-x86_64"
            fi
            ;;
        *)
            echo "Unsupported platform"
            exit 1
            ;;
    esac
}

# Newer chdb releases may ship only python wheels, so pick the latest release
# which contains the libchdb tarball for the requested platform.
determine_latest_release() {
    local tags tag url
    tags=$(curl --silent "https://api.github.com/repos/chdb-io/chdb/releases?per_page=30" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    for tag in $tags; do
        url="https://github.com/chdb-io/chdb/releases/download/$tag/$PLATFORM-libchdb.tar.gz"
        if [ "$(curl --silent --head --location --output /dev/null --write-out '%{http_code}' "$url")" = "200" ]; then
            echo "$tag"
            return
        fi
    done
}

PLATFORM=${2:-$(determine_platform)}
RELEASE=${1:-$(determine_latest_release)}

if [ -z "$RELEASE" ]; then
    echo "No release with $PLATFORM-libchdb.tar.gz found"
    exit 1
fi

# Notify if selected release is not the latest
if [ -z "$1" ]; then
    echo "Using latest version $RELEASE"
else
    LATEST_RELEASE=$(determine_latest_release)
    if [ "$RELEASE" != "$LATEST_RELEASE" ]; then
        echo "Using version $RELEASE, while the latest version is $LATEST_RELEASE"
    fi
fi

# Download the file, untar and cleanup
DOWNLOAD_URL="https://github.com/chdb-io/chdb/releases/download/$RELEASE/$PLATFORM-libchdb.tar.gz"
echo "Downloading $PLATFORM-libchdb.tar.gz from $DOWNLOAD_URL"
curl -L -o libchdb.tar.gz "$DOWNLOAD_URL"
tar -xzf libchdb.tar.gz
chmod +x libchdb.so
# refresh mtime, otherwise CopyToOutputDirectory=PreserveNewest may keep a stale copy
touch libchdb.so
rm -f libchdb.tar.gz
