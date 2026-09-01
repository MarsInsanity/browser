#!/bin/bash
#
# The rail's proportions.
#
# Two things Chromium's rail does differently from Arc's sidebar, both of them
# a single number.
#
# Chromium's tab rows are thin — 6dp of padding above and below a 16dp favicon,
# so a row is about 28dp tall. That density suits a strip of tabs across the
# top of a window, where vertical space is what you are short of. In a sidebar
# it reads as cramped, and Arc's rows are noticeably chunkier.
#
# Chromium also packs the whole rail to the top: the tab list is only as tall
# as its contents, and the new tab button sits directly under the last tab,
# wherever that happens to be. So the controls wander up and down as tabs open
# and close. Arc keeps them still, at the bottom of the sidebar. Letting the
# list fill the space between the pinned grid and the controls does that, and
# also gives the list a stable area to scroll within.

arc_section "Rail proportions"

DIMENS=chrome/android/features/tab_ui/java/res/values/dimens.xml
LAYOUT=chrome/android/features/tab_ui/java/res/layout/vertical_tab_layout.xml

# Thicker rows.
arc_patch "tab rows are thicker" \
    "$DIMENS" \
    '<dimen name="vertical_tab_item_padding_vertical">6dp</dimen>' \
    's|<dimen name="vertical_tab_item_padding_vertical">6dp</dimen>|<dimen name="vertical_tab_item_padding_vertical">10dp</dimen>|' \
    '<dimen name="vertical_tab_item_padding_vertical">10dp</dimen>'

# The tab list takes the space between the pinned grid and the controls rather
# than only as much as its contents need, which leaves the new tab button and
# the Spaces row sitting at the bottom of the rail instead of following the
# last tab up and down the screen.
arc_patch "new tab button and Spaces sit at the bottom" \
    "$LAYOUT" \
    'android:id="@\+id/tab_list_recycler_view"' \
    '\|android:id="@+id/tab_list_recycler_view"|,+2 s|android:layout_height="wrap_content"|android:layout_height="0dp"|' \
    'android:layout_height="0dp"'
