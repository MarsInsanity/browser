#!/bin/bash
#
# "Set as pinned home" in the tab context menu.
#
# A pinned tab returns to where it was pinned when you close it (see
# arc/50-pinned-home.sh), but until now that place was fixed at the moment of
# pinning. Pin a tab on a site's front page, settle into some corner of it you
# actually use, and the tab keeps snapping back to the front page.
#
# This adds a menu item on a pinned tab that re-points it at whatever it is
# showing now. It appears only on a single pinned tab, since it means nothing
# for several at once or for an unpinned one.
#
# Three small pieces: an ID, the item and its handler, and making the
# PinnedTabClosureManager singleton reachable from the menu's package.
#
# The item's title is a literal rather than a string resource. The only place
# Chromium accepts new Android strings is android_chrome_strings.grd, a
# translated file, and adding to it would mean carrying a message through every
# Chromium bump for one line of a private fork. The cost is that this one item
# reads English regardless of locale.

arc_section "Pinned home from the context menu"

arc_apply_patch "set a pinned tab's home from the context menu" \
    "$ARC_ROOT/arc/patches/80-pinned-home-menu.patch"
