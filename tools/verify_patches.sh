#!/bin/bash
#
# Check the Arc patch layer against a Chromium version, without a checkout and
# without a build.
#
#     tools/verify_patches.sh                # the version this repo targets
#     tools/verify_patches.sh 153.0.8000.0   # a version you are moving to
#
# It asks arc.sh which files it touches, downloads just those files at that
# version, and asks arc.sh whether every anchor it needs is still there. A
# failure names the patch and the file, which is the whole cost of a Chromium
# bump reduced to a few seconds and a few hundred kilobytes.
#
# If chromium/src is already checked out it is used as-is and nothing is
# downloaded. Note that a checkout is patched in place by build.sh, so verify
# against a fresh one or let this script download.

set -u

cd "$(dirname "$0")/.."
source common.sh

VERSION=${1:-$(chromium_version)}
export VERSION

if [ -z "$VERSION" ]; then
    echo "could not work out which Chromium version to check" >&2
    echo "pass one: tools/verify_patches.sh 153.0.8000.0" >&2
    exit 1
fi

echo "Checking the Arc layer against Chromium $VERSION"

if [ -d chromium/src ]; then
    tree=$(realpath chromium/src)
    echo "Using the checkout at $tree"
    downloaded=0
else
    tree=$(mktemp -d)
    trap 'rm -rf "$tree"' EXIT
    downloaded=1
fi

files=$(ARC_MODE=list bash arc.sh | sort -u)
count=$(printf '%s\n' "$files" | wc -l)

if [ "$downloaded" = 1 ]; then
    echo "Downloading $count file(s) from the Chromium mirror"
    missing=0
    for file in $files; do
        mkdir -p "$tree/$(dirname "$file")"
        if ! curl -sfL --retry 3 --retry-delay 2 \
            "$CHROMIUM_MIRROR/$VERSION/$file" -o "$tree/$file"; then
            echo "  could not fetch $file" >&2
            missing=$((missing + 1))
        fi
    done
    if [ "$missing" != 0 ]; then
        echo "" >&2
        echo "$missing file(s) could not be fetched at $VERSION." >&2
        echo "Either the version does not exist or Chromium moved those files." >&2
        exit 1
    fi
fi

cd "$tree"
ARC_MODE=check source "$OLDPWD/arc.sh"
