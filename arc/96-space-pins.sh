#!/bin/bash
#
# Pinned tabs belong to a Space.
#
# Arc keeps two tiers: Favorites, which follow you everywhere, and a Space's
# own pinned tabs, which appear only in it. Chromium has one tier — every
# pinned tab is global — so School's pins sit in Personal and the grid fills
# with things that belong somewhere else.
#
# The awkward part is that Chromium *ungroups* a tab when it pins it, so a
# pinned tab has no Space left to read. The Space therefore has to be taken in
# pinTab, before the ungroup, and kept alongside the pinned URLs that
# arc/50-pinned-home.sh already stores. A Token survives that round trip as its
# two halves; it has no serialiser of its own but does expose them.
#
# That storage gives both of Arc's tiers from one rule, with nothing extra for
# anyone to configure:
#
#   - Pinned while a Space was open -> belongs to that Space.
#   - Pinned from "All" -> no Space recorded -> a Favorite, shown everywhere.
#
# The pinned strip is built by its own mediator walking its own list, so it
# does not follow the view types that hide rows elsewhere in the rail and has
# to be filtered and refreshed on its own terms.

arc_section "Pinned tabs belong to a Space"

arc_apply_patch "a pinned tab shows in the Space it was pinned in" \
    "$ARC_ROOT/arc/patches/96-space-pins.patch"
