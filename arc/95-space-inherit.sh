#!/bin/bash
#
# Links open into the Space you are in.
#
# Arc calls the general idea Air Traffic Control — links routed to the Space
# they belong to. Most of that is rules about external links and profiles; this
# is the half that matters every minute, and the half Chromium gets wrong for a
# sidebar: a tab opened from a tab that lives in a Space is left ungrouped, so
# following any link drops you out of the Space you were working in and the new
# tab lands somewhere the rail is not showing.
#
# ChromeTabCreator already carries the parent tab through every path that makes
# a tab, and hands it to TabBuilder, so the Space is right there — it is simply
# never read. Inherit it just before the tab is handed to the model, which is
# the one point every branch of createNewTab converges on.
#
# Pinned tabs are excluded on purpose: they sit outside every Space by design,
# so a tab opened from one should not be dragged into a Space it never had.

arc_section "Links open into the Space you are in"

arc_apply_patch "a tab opened from a Space joins that Space" \
    "$ARC_ROOT/arc/patches/95-space-inherit.patch"
