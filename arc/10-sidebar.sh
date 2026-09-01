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

# Upstream gates the sidebar on the device reporting a tablet form factor.
# Gate it on the width the rail actually needs instead — the constant upstream
# already uses to decide whether the rail may expand at all.
#
# This runs both ways, and both matter. A phone in desktop mode, a foldable
# opened out and a freeform window on an external display are all wide enough
# for the rail but fail a form-factor check. More importantly, a tablet in a
# window *narrower* than the rail needs passes that check and should not:
# vertical tabs being on suppresses the horizontal tab strip, but a rail with
# no room does not draw either, so the window keeps the strip's reserved height
# at the top and fills it with nothing. Making eligibility a question of width
# alone means a narrow window falls back to the horizontal strip, which is what
# fits there, and the band at the top is occupied either way.
arc_patch "sidebar follows the window's width, not the device's form factor" \
    "$VT_UTILS" \
    '&& DeviceFormFactor\.isNonMultiDisplayContextOnTablet\(context\);' \
    's|&& DeviceFormFactor.isNonMultiDisplayContextOnTablet(context);|\&\& context.getResources().getConfiguration().screenWidthDp\n                        >= MIN_EXPAND_WINDOW_WIDTH_DP;|' \
    '>= MIN_EXPAND_WINDOW_WIDTH_DP;'
