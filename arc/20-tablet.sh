#!/bin/bash
#
# Tablets, windows, keyboards and pointers.
#
# The build is already a desktop-Android build (is_desktop_android = true in
# args.gn), which is what gives it a tab strip, real windows and the extension
# system. What is left is the handful of large-screen behaviours Chromium 152
# has finished but not yet switched on.
#
# Not patched here, because Chromium 152 already ships them on by default and
# a patch would be dead weight to carry across version bumps:
#
#   kUniversalKeyboardHandling      keyboard shortcuts and focus traversal
#   kKeyboardEscBackNavigation      Esc goes back
#   kEdgeToEdgeTablet               content under the system bars on tablets
#   kToolbarTabletResizeRefactor    toolbar reflow when a window is resized
#   kAndroidThemeModule             Material 3 surfaces
#
# Pointer input (hover, right-click menus, two-finger scroll, drag) is handled
# in the input stack rather than behind a flag, so trackpad support is a
# question of which UI opts into it. The sidebar's expand-on-hover in
# 10-sidebar.sh is the piece that was behind a flag.

arc_section "Tablet, window and pointer behaviour"

FEATURES=chrome/browser/flags/android/chrome_feature_list.cc

# Keep the toolbar pinned on large tablets instead of letting it scroll away.
# On a laptop-shaped device a toolbar that hides on scroll and needs a fling to
# come back is the wrong interaction; the sidebar and toolbar should stay put.
arc_enable "$FEATURES" kLockTopControlsOnLargeTabletsV2

# Move and merge tab groups across windows. Tab groups are the closest thing
# Chromium has to Arc's Spaces, and on a tablet running two windows side by
# side this is what lets a Space move between them.
arc_enable "$FEATURES" kCrossWindowTabGroupOperations

# Anchor bottom sheets to the window they were opened from rather than the
# display, so they behave when several windows are on screen at once.
arc_enable "$FEATURES" kBottomSheetOnDesktopWindowing
