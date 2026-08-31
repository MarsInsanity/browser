#!/bin/bash
#
# The sidebar.
#
# Arc's defining trait is that tabs live in a vertical rail down the side of
# the window instead of a horizontal strip across the top, and that the rail
# expands when you point at it and collapses when you leave.
#
# Chromium 152 ships exactly this, as chrome://flags#android-vertical-tabs. It
# is complete but off by default and gated to tablets. This turns it on, turns
# on its two variations (expand-on-hover and drag-between-windows), and widens
# the gate to any window wide enough to hold the expanded rail.
#
# Upstream implementation:
#   chrome/browser/ui/vertical_tabs/android/.../VerticalTabUtils.java

arc_section "Sidebar (vertical tabs)"

FEATURES=chrome/browser/flags/android/chrome_feature_list.cc
FLAGS_JAVA=chrome/browser/flags/android/java/src/org/chromium/chrome/browser/flags/ChromeFeatureList.java
VT_UTILS=chrome/browser/ui/vertical_tabs/android/java/src/org/chromium/chrome/browser/ui/vertical_tabs/VerticalTabUtils.java

# The native feature. Everything else in this file is downstream of it.
arc_enable "$FEATURES" kAndroidVerticalTabs

# The Java side reads a cached copy of the flag so that it can lay out the
# first frame before native is up. Without this the sidebar would be missing
# on the very first launch after install and appear on the second.
arc_patch "sidebar cached flag defaults on" \
    "$FLAGS_JAVA" \
    '^ +ANDROID_VERTICAL_TABS,$' \
    '/^ *ANDROID_VERTICAL_TABS,$/{N;s|^\( *\)ANDROID_VERTICAL_TABS,\n *\/\* defaultValue= \*\/ false,|\1ANDROID_VERTICAL_TABS, /* defaultValue= */ true,|}' \
    'ANDROID_VERTICAL_TABS, /\* defaultValue= \*/ true,'

# isVerticalTabsEnabled() reads a user preference and falls back to this
# parameter when the user has not chosen. Defaulting it on makes the sidebar
# the out-of-the-box layout; the app menu still toggles it per user.
arc_patch "sidebar is the default layout" \
    "$FLAGS_JAVA" \
    'ANDROID_VERTICAL_TABS, "enable_by_default", /\* defaultValue= \*/ false\);' \
    's|ANDROID_VERTICAL_TABS, "enable_by_default", /\* defaultValue= \*/ false);|ANDROID_VERTICAL_TABS, "enable_by_default", /* defaultValue= */ true);|' \
    'ANDROID_VERTICAL_TABS, "enable_by_default", /\* defaultValue= \*/ true\);'

# The collapsed rail widens under the pointer and shrinks when it leaves. This
# is the half of the sidebar that only exists for a mouse or trackpad, and it
# is the single most Arc-like behaviour in the build.
arc_patch "rail expands on hover" \
    "$VT_UTILS" \
    'ChromeFeatureList\.ANDROID_VERTICAL_TABS, "expand_on_hover", false\);' \
    's|ChromeFeatureList.ANDROID_VERTICAL_TABS, "expand_on_hover", false);|ChromeFeatureList.ANDROID_VERTICAL_TABS, "expand_on_hover", true);|' \
    'ChromeFeatureList\.ANDROID_VERTICAL_TABS, "expand_on_hover", true\);'

# Drag a tab out of the rail and into another window, which on a tablet in
# split screen is how you pull a tab into the other pane.
arc_patch "tabs drag between windows" \
    "$VT_UTILS" \
    'ChromeFeatureList\.ANDROID_VERTICAL_TABS, EXTERNAL_DRAG_PARAM, false\);' \
    's|ChromeFeatureList.ANDROID_VERTICAL_TABS, EXTERNAL_DRAG_PARAM, false);|ChromeFeatureList.ANDROID_VERTICAL_TABS, EXTERNAL_DRAG_PARAM, true);|' \
    'ChromeFeatureList\.ANDROID_VERTICAL_TABS, EXTERNAL_DRAG_PARAM, true\);'

# Upstream gates the sidebar on the device reporting a tablet form factor. A
# phone in desktop mode, a foldable opened out, or a freeform window on a
# desktop-class display are all wide enough for the rail but fail that check.
# Gate on the width the rail actually needs instead, which is the constant
# upstream already uses to decide whether the rail may expand at all.
arc_patch "sidebar available in any window wide enough for it" \
    "$VT_UTILS" \
    '&& DeviceFormFactor\.isNonMultiDisplayContextOnTablet\(context\);' \
    's|&& DeviceFormFactor.isNonMultiDisplayContextOnTablet(context);|\&\& (DeviceFormFactor.isNonMultiDisplayContextOnTablet(context)\n                        \|\| context.getResources().getConfiguration().screenWidthDp\n                                >= MIN_EXPAND_WINDOW_WIDTH_DP);|' \
    '>= MIN_EXPAND_WINDOW_WIDTH_DP\);'
