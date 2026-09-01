# The Arc layer

What `arc.sh` changes, why, and which parts of Arc this cannot reproduce.

## The idea

Chromium 152 already contains most of the interaction model Arc made popular on
desktop — a vertical tab rail, tab groups, tabs that retire themselves — but
ships it switched off, half of it gated to tablets. The layer is small on
purpose: it turns those on and widens the gates, rather than rewriting Chromium's
UI. Every patch is a flag flip or a few lines, which is what keeps a Chromium
bump cheap.

Run `tools/verify_patches.sh` to see the current list against your Chromium.

## What Arc does, and what this does

| Arc | Here |
| --- | --- |
| Sidebar of tabs down the side | Chromium's vertical tabs, on by default, expanding under the pointer |
| Sidebar collapses out of the way | The rail's collapsed state, 76dp, remembered between launches |
| Spaces | Tab groups, including moving a group between windows |
| Tabs auto-archive | Tab declutter, which retires tabs left unused; shipped in 152 and already on |
| Command bar | The omnibox, which `patch.sh` already puts in its desktop form |
| Split view | Android's own split screen, with tabs draggable between the two windows |
| Boosts, per-site appearance | Not built in — but extensions are supported, and a userstyle extension covers it |
| Easels, Notes, shared Spaces | Not available. These are Arc's own services, not browser features |

Two things worth being plain about: this is not Arc, and it is not trying to
pass for Arc. It is Chromium arranged the way Arc arranges a browser. The name
and look of the app are unchanged from the upstream project — see
[Branding](#branding).

## The patches

### `arc/10-sidebar.sh` — the sidebar

Chromium's implementation lives in `VerticalTabUtils.java` and is complete;
it is `chrome://flags#android-vertical-tabs` upstream. Six patches:

- Enable `kAndroidVerticalTabs`, natively and in the Java cached flag. Both are
  needed: the Java side lays out the first frame before native is up, so
  without the cached flag the sidebar would be missing on the first launch
  after install and appear on the second.
- Default the layout to the sidebar (`enable_by_default`). Users can still
  switch back to a horizontal strip from the app menu; upstream's toggle is
  untouched.
- Turn on `expand_on_hover`. The rail widens under the pointer and shrinks when
  it leaves — the half of the sidebar that exists only for a mouse or trackpad.
- Turn on `external_drag`, so a tab can be dragged out of the rail into another
  window.
- Gate eligibility on width, not form factor. Upstream requires the device to
  report a tablet, so the sidebar follows the device. The patch gates on the
  window being at least `MIN_EXPAND_WINDOW_WIDTH_DP` (652dp) wide instead — the
  constant upstream already uses to decide whether the rail may expand — so it
  follows the window.

  This matters in both directions. A phone in desktop mode, an opened foldable
  and a freeform window on an external display are all wide enough for the rail
  but fail a form-factor check. And a tablet in a window *narrower* than the
  rail needs passes that check when it should not: vertical tabs being on
  suppresses the horizontal tab strip, but a rail with no room does not draw
  either, so the window keeps the strip's reserved height at the top of the
  window and fills it with nothing — a dead band above the toolbar. Width alone
  means a narrow window falls back to the horizontal strip, which fits there,
  and that band is occupied either way.

### `arc/20-tablet.sh` — large screens, windows and pointers

- `kLockTopControlsOnLargeTabletsV2` — keep the toolbar put on large tablets
  instead of hiding it on scroll. On a laptop-shaped device, needing a fling to
  get the toolbar back is the wrong interaction.
- `kCrossWindowTabGroupOperations` — move and merge tab groups across windows,
  which is what lets a Space move between two side-by-side windows.
- `kBottomSheetOnDesktopWindowing` — anchor bottom sheets to their own window.

Chromium 152 already ships these on, so there is nothing to patch and nothing
to carry forward: `kUniversalKeyboardHandling` (shortcuts and focus traversal),
`kKeyboardEscBackNavigation`, `kEdgeToEdgeTablet`,
`kToolbarTabletResizeRefactor` (toolbar reflow on window resize) and
`kAndroidThemeModule`.

### `arc/40-pinned.sh` — pinned tabs

Chromium 152 already implements pinned tabs in the rail: a separate
`RecyclerView` above the tab list, laid out by a `GridLayoutManager` as
icon-only 42dp squares, with pin and unpin in the tab context menu and a drag
constraint that forbids moving a tab across the pinned/unpinned boundary.

What differs from Arc is the column count. Upstream derives it from the
measured rail width and clamps it to at most four, so it reflows as the window
changes and can collapse to one column. Two patches hold it at three columns
whenever the rail is expanded; the collapsed rail still drops to a single
column through the separate `COLLAPSED_GRID_SPAN_COUNT` branch.

Not yet done: a pinned tab does not return to the URL it was pinned at. See
[ROADMAP.md](ROADMAP.md).

### `arc/30-appearance.sh` — appearance and tab organisation

- `kAndroidSurfaceColorUpdate`, `kGridTabSwitcherSurfaceColorUpdate` — flat,
  tonal Material 3 surfaces rather than elevated cards.
- `kShowTabListAnimations` — tabs animate in and out instead of the rail
  jumping every time one opens or closes.
- `kTabSwitcherGroupSuggestionsAndroid` — Chromium proposes groupings for
  related tabs, the nearest automatic equivalent to organising a Space by hand.

## Touch and pointer

The build targets both, and they need different things from the same UI.

Pointer input — hover, right-click, two-finger scroll, drag — is handled in
Chromium's input stack rather than behind flags, so trackpad support is a
question of which UI opts into it. The tab strip already routes trackpad
scrolling; the piece that was behind a flag is the sidebar's expand-on-hover,
which `10-sidebar.sh` turns on.

Touch is unaffected by all of this. The collapsed rail is 76dp and the expanded
rail 240dp, both comfortably above the 48dp minimum touch target, and the
sidebar is dragged and tapped the same way with a finger.

Keyboard handling, including shortcuts and focus traversal, is on by default in
152 and needs no patch.

## Extensions

Extension support is the upstream project's work, not this layer's, and is
untouched here. Manifest V2 and V3 both load, off-store installs are permitted
from the major add-on sites, and unpacked extensions load through the system
file picker. See the README for how to install them.

It is also the answer to several things Arc does natively: a userstyle
extension covers Boosts, and a vertical-tabs-adjacent extension is unnecessary
because the sidebar is native here.

## Branding

The app installs as `com.magiclabs.marsbrowser` and is called **Mars Browser**,
so it sits alongside Titanium rather than replacing it and Titanium can stay
the default browser. `arc/60-identity.sh` sets the visible name; `args.gn` sets
the package ID.

It is deliberately not named after Arc. This is Chromium arranged the way Arc
arranges a browser, not their product, and naming it theirs would misrepresent
whose it is.

The icon is still Titanium's, and the internal naming — resource directories,
identifiers — is still `titanium`, because `build.sh` rewrites Vanadium's
patches to that name before applying them. Renaming those would mean a build
from scratch for no visible change, so only the strings a user actually reads
are patched.

Change the package ID before a release, never after. Android keys an installed
app on it, so a new ID is a new app and existing installs will not update
across the change.
