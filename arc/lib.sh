#!/bin/bash
#
# Helpers for the Arc patch layer.
#
# The upstream patch script edits Chromium with bare `sed -i` calls. When
# Chromium moves the code a bare sed silently matches nothing, the build still
# succeeds, and the feature is quietly missing from the APK. Every patch here
# instead declares the upstream text it depends on (the anchor) and the text it
# expects to leave behind (the result), so a Chromium bump that breaks a patch
# stops the build with the name of the patch that broke.
#
# The same declarations let tools/verify_patches.sh check the whole layer
# against any Chromium tag over the network, without a checkout or a build.
#
# Larger changes, which do not read well as a sed expression, are unified diffs
# in arc/patches/ applied through arc_apply_patch. `git apply` refuses a patch
# whose context has drifted, which gives those the same property.
#
# Modes, via $ARC_MODE:
#   apply  (default) verify the anchor, edit the file, verify the result
#   check            verify the anchor only, against a pristine tree
#   list             print the files the layer touches, one per line

ARC_MODE=${ARC_MODE:-apply}
ARC_FAILURES=0
ARC_APPLIED=0

arc_log() { printf '[arc] %s\n' "$*" >&2; }

arc_section() {
    [ "$ARC_MODE" = list ] && return 0
    arc_log ""
    arc_log "== $* =="
}

# arc_patch <description> <file> <anchor> <sed-expression> <result>
#
# <anchor> and <result> are extended regexes. <anchor> must match before the
# edit; <result> must match after it.
arc_patch() {
    local desc=$1 file=$2 anchor=$3 expr=$4 result=$5

    if [ "$ARC_MODE" = list ]; then
        printf '%s\n' "$file"
        return 0
    fi

    if [ ! -f "$file" ]; then
        arc_log "FAIL $desc"
        arc_log "     missing file: $file"
        ARC_FAILURES=$((ARC_FAILURES + 1))
        return 1
    fi

    if ! grep -qE -- "$anchor" "$file"; then
        arc_log "FAIL $desc"
        arc_log "     anchor not found in $file"
        arc_log "     anchor: $anchor"
        ARC_FAILURES=$((ARC_FAILURES + 1))
        return 1
    fi

    if [ "$ARC_MODE" = check ]; then
        arc_log "ok   $desc"
        return 0
    fi

    sed -i "$expr" "$file"

    if ! grep -qE -- "$result" "$file"; then
        arc_log "FAIL $desc"
        arc_log "     anchor matched but the edit did not take in $file"
        arc_log "     expected: $result"
        ARC_FAILURES=$((ARC_FAILURES + 1))
        return 1
    fi

    ARC_APPLIED=$((ARC_APPLIED + 1))
    arc_log "ok   $desc"
}

# arc_apply_patch <description> <patch-file>
#
# For changes that are too large to read as a sed expression. The patch is a
# unified diff against pristine Chromium, applied with `git apply`, which
# refuses a patch whose context has drifted rather than applying half of it.
# That gives the same fail-loudly property as arc_patch's anchor, so a Chromium
# bump that moves the surrounding code stops the build.
#
# Prefer adding a file over editing one: a file Chromium does not have cannot
# conflict on a bump, so only its one-line registration in a BUILD.gn or .gni
# can break, and that is an arc_patch with an anchor. See docs/ROADMAP.md.
arc_apply_patch() {
    local desc=$1 patch=$2

    if [ "$ARC_MODE" = list ]; then
        # The files this patch needs, so verify_patches.sh knows to fetch them.
        sed -n 's|^+++ b/||p' "$patch"
        return 0
    fi

    if [ ! -f "$patch" ]; then
        arc_log "FAIL $desc"
        arc_log "     missing patch: $patch"
        ARC_FAILURES=$((ARC_FAILURES + 1))
        return 1
    fi

    if ! git apply --check -p1 "$patch" 2>/dev/null; then
        arc_log "FAIL $desc"
        arc_log "     patch no longer applies: $patch"
        arc_log "     Chromium most likely moved the code around it"
        ARC_FAILURES=$((ARC_FAILURES + 1))
        return 1
    fi

    if [ "$ARC_MODE" = check ]; then
        arc_log "ok   $desc"
        return 0
    fi

    if ! git apply -p1 "$patch"; then
        arc_log "FAIL $desc"
        arc_log "     patch checked out clean but did not apply: $patch"
        ARC_FAILURES=$((ARC_FAILURES + 1))
        return 1
    fi

    ARC_APPLIED=$((ARC_APPLIED + 1))
    arc_log "ok   $desc"
}

# arc_feature <file> <symbol> <from> <to>
#
# Flips the compiled-in default of a BASE_FEATURE. The feature stays
# overridable at runtime from chrome://flags and the command line; this only
# changes which way it defaults when nothing overrides it.
arc_feature() {
    local file=$1 symbol=$2 from=$3 to=$4
    arc_patch "$symbol default $from -> $to" "$file" \
        "^BASE_FEATURE\($symbol, base::FEATURE_${from}_BY_DEFAULT\);" \
        "s|^BASE_FEATURE($symbol, base::FEATURE_${from}_BY_DEFAULT);|BASE_FEATURE($symbol, base::FEATURE_${to}_BY_DEFAULT);|" \
        "^BASE_FEATURE\($symbol, base::FEATURE_${to}_BY_DEFAULT\);"
}

# arc_enable <file> <symbol>
arc_enable() { arc_feature "$1" "$2" DISABLED ENABLED; }

# arc_disable <file> <symbol>
arc_disable() { arc_feature "$1" "$2" ENABLED DISABLED; }

arc_report() {
    [ "$ARC_MODE" = list ] && return 0
    arc_log ""
    if [ "$ARC_FAILURES" -ne 0 ]; then
        arc_log "$ARC_FAILURES patch(es) failed against Chromium ${VERSION:-unknown}."
        arc_log "Chromium most likely moved the code these patches anchor to."
        arc_log "See docs/UPDATING.md for how to re-anchor them."
        return 1
    fi
    if [ "$ARC_MODE" = check ]; then
        arc_log "all anchors present for Chromium ${VERSION:-unknown}"
    else
        arc_log "$ARC_APPLIED patch(es) applied for Chromium ${VERSION:-unknown}"
    fi
    return 0
}
