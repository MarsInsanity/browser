#!/bin/bash
#
# The Arc layer.
#
# Sourced by build.sh from the Chromium checkout after patch.sh, so every path
# below is relative to chromium/src.
#
# Run it by hand against a checkout:
#     cd chromium/src && ARC_MODE=apply source ../../arc.sh
#
# Check it against a Chromium version without a checkout:
#     tools/verify_patches.sh
#
# A patch that no longer matches Chromium stops the build. That is deliberate:
# a silently skipped patch ships an APK with the feature missing and nothing to
# say so. See docs/UPDATING.md.

ARC_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

source "$ARC_ROOT/arc/lib.sh"

if [ "$ARC_MODE" = apply ] && [ -z "${PATCHED:-}" ]; then
    arc_log "refusing to run: patch.sh has not run yet"
    arc_log "arc.sh builds on the Vanadium and Titanium patches and must follow them"
    exit 1
fi

for part in "$ARC_ROOT"/arc/[0-9]*.sh; do
    source "$part"
done

arc_report || exit 1

export ARC_PATCHED=1
