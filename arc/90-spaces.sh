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
# "All" — and choosing one collapses every other group so that a single Space
# is open at a time.
#
# It is done by collapsing rather than by handing the list a filtered set of
# tabs, which is what the first version of this patch did and got wrong. Two
# things downstream assume the list holds every tab in tab-model order:
# TabListMediator maps a tab-model index onto a list position to follow the
# selected tab, and StaticPinnedTabsMediator builds the pinned strip by walking
# that same list. Feeding it a subset moves the selection onto the wrong row
# and empties the pinned grid of anything outside the chosen Space. Collapsing
# is the mechanism upstream already uses to hide a group's tabs, and it leaves
# both of those intact.
#
# Three things follow, and are deliberate:
#
#   - Pinned tabs stay visible from every Space, which is what Arc does with
#     Favorites.
#   - Making a Space is making a tab group, and renaming or recolouring one is
#     done where Chromium already does it, in the tab context menu.
#   - Tabs in no group stay visible from every Space, because only a group can
#     be collapsed. Arc would hide them; matching that needs the rail to render
#     a genuine subset, which is a much larger change than this one.
#
# What this does *not* do is give each Space its own cookies, which is the
# other half of what Arc means by a Space and by far the larger job — Android's
# UI assumes a single profile in a great many places. See docs/ROADMAP.md.

arc_section "Spaces"

arc_apply_patch "rail shows one Space at a time, with a switcher" \
    "$ARC_ROOT/arc/patches/90-spaces.patch"
