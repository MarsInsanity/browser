#!/bin/bash
#
# Appearance and tab organisation.
#
# The rest of what makes Arc feel like Arc, to the extent Chromium can express
# it: quieter surfaces, tabs that animate rather than snap, and tabs that
# suggest their own grouping.
#
# Arc's auto-archive and Spaces do not need patching. Tab declutter shipped in
# Chromium 152 and is on by default (only its dedupe kill switch is still a
# flag), and tab groups shipped earlier still. Both are live in this build
# already; see docs/ARC.md for where they surface.

arc_section "Appearance and tab organisation"

FEATURES=chrome/browser/flags/android/chrome_feature_list.cc

# Material 3 surface colours across the browser UI and the tab switcher. Flat,
# tonal surfaces rather than elevated cards, which is the register Arc works in.
arc_enable "$FEATURES" kAndroidSurfaceColorUpdate
arc_enable "$FEATURES" kGridTabSwitcherSurfaceColorUpdate

# Animate tabs in and out of the list instead of cutting. With the sidebar
# open this is the difference between tabs sliding into place and the rail
# jumping every time a tab opens or closes.
arc_enable "$FEATURES" kShowTabListAnimations

# Offer to group related tabs. Arc organises tabs into Spaces by hand; this is
# Chromium proposing the grouping for you, which is the nearest automatic
# equivalent it has.
arc_enable "$FEATURES" kTabSwitcherGroupSuggestionsAndroid
