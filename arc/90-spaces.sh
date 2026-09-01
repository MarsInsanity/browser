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
# This narrows the rail to one group at a time and puts a row of chips at the
# bottom to choose between them, plus "All" for the unfiltered view. It is a
# lens over tab groups, and owns no state beyond which one is being looked
# through, so nothing here can lose a tab.
#
# Three things follow from that, and are deliberate:
#
#   - Pinned tabs are not filtered. They come from a separate mediator and stay
#     visible from every Space, which is what Arc does with Favorites.
#   - Making a Space is making a tab group, and renaming or recolouring one is
#     done where Chromium already does it, in the tab context menu.
#   - Opening a new tab widens back to "All", because a new tab belongs to no
#     group and would otherwise open into a rail that is not showing it.
#
# What this does *not* do is give each Space its own cookies, which is the
# other half of what Arc means by a Space and by far the larger job — Android's
# UI assumes a single profile in a great many places. See docs/ROADMAP.md.

arc_section "Spaces"

arc_apply_patch "rail shows one Space at a time, with a switcher" \
    "$ARC_ROOT/arc/patches/90-spaces.patch"
