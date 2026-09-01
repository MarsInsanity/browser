#!/bin/bash
#
# A pinned tab returns to where it was pinned.
#
# In Arc, closing a pinned tab does not remove it: it goes back to the page it
# was pinned at. That is what makes a pinned tab behave like an app rather than
# like a tab that happens to be stuck to the top of the list.
#
# Chromium 152 already intercepts closing a pinned tab —
# PinnedTabClosureManager.shouldCloseTab() shows a toast on the first attempt
# and closes on a second within four seconds — so the interception point is
# upstream and stable. What it lacks is any memory of where the tab was pinned.
#
# This adds that memory and navigates instead of closing:
#
#   - TabCollectionTabModelImpl.updatePinnedState() is the single funnel both
#     pinning and unpinning pass through, so the URL is recorded and forgotten
#     there.
#   - shouldCloseTab() sends a pinned tab that has wandered back to its pinned
#     URL and reports the close as handled.
#
# Closing a pinned tab that is already at its pinned URL still falls through to
# upstream's two-step confirmation, which stays the way to close one outright.
#
# The map is in memory, so a pinned tab has no recorded home after a restart
# until it is pinned again; it falls back to upstream's behaviour until then.
# Persisting it means touching tab persistence, which is a bigger change than
# this one — see docs/ROADMAP.md.
#
# Too many lines to read as a sed expression, so it is a real patch. See
# arc/lib.sh for why that is still checkable.

arc_section "Pinned tabs return to where they were pinned"

arc_apply_patch "pinned tabs remember and return to their pinned URL" \
    "$ARC_ROOT/arc/patches/50-pinned-home.patch"
