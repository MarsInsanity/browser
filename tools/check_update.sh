#!/bin/bash
#
# Is there a newer Chromium to move to, and would the Arc layer survive it?
#
#     tools/check_update.sh
#
# Answers both questions without a checkout and without a build, so it is cheap
# enough to run on a schedule. CI runs it daily and opens an issue when the
# answer changes; see .github/workflows/update-check.yml.
#
# Where the version actually comes from: this repo pins Chromium through the
# Vanadium submodule, because the Vanadium patches are written against the
# Chromium that Vanadium itself targets. So the question "is there a new
# Chromium" is really "has GrapheneOS tagged a new Vanadium", and the Chromium
# version is whatever that tag's args.gn names.
#
# Exit codes, so a caller can branch on the outcome:
#   0  up to date
#   10 a newer Chromium is available and every patch still applies to it
#   11 a newer Chromium is available but some patch needs re-anchoring
#   1  could not work it out (network, a moved file, a bad tag)

set -u

cd "$(dirname "$0")/.."
source common.sh

VANADIUM_REPO=${VANADIUM_REPO:-https://github.com/GrapheneOS/Vanadium.git}
VANADIUM_RAW=${VANADIUM_RAW:-https://raw.githubusercontent.com/GrapheneOS/Vanadium}

current=$(chromium_version)
if [ -z "$current" ]; then
    echo "Could not determine the Chromium version this repo targets." >&2
    echo "Check out the vanadium submodule, or set CHROMIUM_VERSION." >&2
    exit 1
fi

# Newest Vanadium tag, read straight off the remote so no clone is needed.
latest_tag=$(git ls-remote --tags --refs "$VANADIUM_REPO" 2>/dev/null \
    | sed 's|.*refs/tags/||' | sort -V | tail -n1)
if [ -z "$latest_tag" ]; then
    echo "Could not reach $VANADIUM_REPO to list tags." >&2
    exit 1
fi

# That tag's args.gn names the Chromium it targets.
latest=$(curl -sfL --retry 3 --retry-delay 2 "$VANADIUM_RAW/$latest_tag/args.gn" \
    | grep -m1 -oE '[0-9]+(\.[0-9]+){3}')
if [ -z "$latest" ]; then
    echo "Could not read a Chromium version out of Vanadium tag $latest_tag." >&2
    exit 1
fi

echo "Targeting Chromium : $current"
echo "Newest Vanadium    : $latest_tag (Chromium $latest)"
echo

if [ "$current" = "$latest" ]; then
    echo "Up to date."
    exit 0
fi

if version_lt "$latest" "$current"; then
    echo "This repo is ahead of the newest Vanadium tag. Nothing to do."
    exit 0
fi

echo "A newer Chromium is available: $current -> $latest"
echo "Checking whether the Arc layer still applies to it."
echo

if bash tools/verify_patches.sh "$latest"; then
    echo
    echo "Every patch still applies to Chromium $latest. The bump is:"
    echo "  cd vanadium && git fetch --tags && git checkout $latest_tag && cd .."
    exit 10
fi

echo
echo "Some patch no longer applies to Chromium $latest."
echo "Re-anchor the patches named above before bumping. See docs/UPDATING.md."
exit 11
