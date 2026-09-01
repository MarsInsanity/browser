#!/bin/bash
#
# Pinned tabs.
#
# Chromium 152 already implements pinned tabs in the vertical rail: they get
# their own RecyclerView above the tab list, laid out by a GridLayoutManager as
# icon-only squares, with pin/unpin in the tab context menu and a drag
# constraint that forbids dragging a tab across the pinned/unpinned boundary.
#
# What differs from Arc is the column count. Upstream derives it from the
# measured rail width and clamps it to at most four, so it drifts with the
# window and can collapse to a single column. Arc always lays pinned tabs out
# in a fixed grid, which is what makes them read as a launcher rather than as
# more tabs.
#
# Upstream implementation:
#   .../tab_management/vertical_tabs/VerticalTabListCoordinator.java
#   .../tab_management/StaticPinnedTabsMediator.java
#
# A pinned item is 42dp wide with a 4dp gap, so three columns need 134dp of a
# rail that is 240dp wide expanded. It fits with room to spare at every window
# size that is allowed to expand the rail at all.

arc_section "Pinned tabs"

VT_LIST=chrome/android/features/tab_ui/java/src/org/chromium/chrome/browser/tasks/tab_management/vertical_tabs/VerticalTabListCoordinator.java

# Three columns rather than up to four.
arc_patch "pinned tabs use a three-column grid" \
    "$VT_LIST" \
    '^ +static final int DEFAULT_GRID_SPAN_COUNT = 4;$' \
    's|static final int DEFAULT_GRID_SPAN_COUNT = 4;|static final int DEFAULT_GRID_SPAN_COUNT = 3;|' \
    '^ +static final int DEFAULT_GRID_SPAN_COUNT = 3;$'

# Hold that grid at exactly three columns while the rail is expanded, instead
# of letting the measured width decide. Upstream's calculation is what makes
# the grid reflow to one or two columns; the collapsed rail still drops to a
# single column through the separate COLLAPSED_GRID_SPAN_COUNT branch, which
# this leaves alone.
arc_patch "pinned grid does not reflow with rail width" \
    "$VT_LIST" \
    '^ +return Math\.min\(DEFAULT_GRID_SPAN_COUNT, calculatedSpans\);$' \
    's|return Math.min(DEFAULT_GRID_SPAN_COUNT, calculatedSpans);|return DEFAULT_GRID_SPAN_COUNT;|' \
    '^ +return DEFAULT_GRID_SPAN_COUNT;$'
