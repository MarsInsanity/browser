#!/bin/bash
#
# The Home button, on a pinned tab.
#
# A pinned tab returns to where it was pinned when you close it (see
# arc/50-pinned-home.sh), but that was reachable only from a keyboard —
# Ctrl+W — which is no use on a touchscreen. The toolbar's Home button is the
# obvious place for it: a pinned tab's home *is* the page it was pinned at, so
# on a pinned tab Home goes there, and on any other tab it still opens the
# homepage.
#
# Intercepted in ToolbarManager rather than in ToolbarTabControllerImpl, which
# is where the button's action actually lives. That is a dependency question,
# not a style one: the controller is in the toolbar module, which everything
# else depends on, so it cannot reach back into the tabmodel package where the
# pinned URLs are kept. ToolbarManager is in chrome/android/java, on the near
# side of that line, and is where the runnable is constructed.

arc_section "Home button on a pinned tab"

arc_apply_patch "Home sends a pinned tab back to where it was pinned" \
    "$ARC_ROOT/arc/patches/85-pinned-home-button.patch"
