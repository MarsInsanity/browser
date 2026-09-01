#!/bin/bash
#
# Spaces.
#
# Arc separates browsing into Spaces and shows one at a time, with a switcher
# along the bottom of the sidebar. Chromium has the container already — a tab
# group is a named, coloured, persistent set of tabs that syncs and can be
# moved between windows — but the rail shows every group at once, as sections
# of one long list. That is a list of groups, not a Space you are in.
#
# This puts a row of chips along the bottom of the rail — one per group, plus
# "All" — and choosing one leaves only that Space's tabs on screen.
#
# How the hiding is done matters, because the obvious way is wrong. Shortening
# the list breaks two things downstream: TabListMediator maps a tab-model index
# onto a list position to follow the selected tab, and StaticPinnedTabsMediator
# builds the pinned strip by walking that same list. A shortened list puts the
# selection on the wrong row and empties the pinned grid.
#
# So rows are kept and rendered as nothing instead. The adapter already does
# exactly this for pinned tabs — in the main list, UiType.PINNED_TAB is bound
# to a zero-size hidden layout, with a comment saying it exists to preserve the
# list's alignment with the tab model. Rows outside the open Space are given
# that same view type. The list stays whole and aligned; the screen shows one
# Space.
#
# Two things follow, and are deliberate:
#
#   - Pinned tabs are never hidden. They are Favorites: shown in their own
#     strip, reachable from every Space, which is what Arc does.
#   - Making a Space is making a tab group, and renaming or recolouring one
#     happens where Chromium already does it, in the tab context menu.
#
# What this does *not* do is give each Space its own cookies, which is the
# other half of what Arc means by a Space and by far the larger job — Android's
# UI assumes a single profile in a great many places. See docs/ROADMAP.md.

arc_section "Spaces"

arc_apply_patch "rail shows one Space at a time, with a switcher" \
    "$ARC_ROOT/arc/patches/90-spaces.patch"
