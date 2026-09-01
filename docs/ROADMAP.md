# Roadmap

Three Arc behaviours this browser does not yet have, what Chromium 152 already
provides for each, and what it would cost to finish them. The findings below
come from reading the Chromium 152.0.7977.64 tree; they are recorded here so
the next person does not have to rediscover them.

The governing constraint is that a Chromium bump must stay cheap. That ranks
the implementation strategies before it ranks the features:

1. **Flip a flag.** A one-line anchored edit. What `arc/*.sh` does today.
2. **Add a file.** New Java or C++ that Chromium never touches, plus a
   one-line anchored edit to register it in a `BUILD.gn` or `.gni`. A new file
   cannot conflict on a version bump — only its registration can, and that
   fails loudly.
3. **Edit upstream code in place.** The expensive kind. Every such edit is a
   thing to re-anchor on every bump, so each one has to earn its place.

Prefer 2 over 3 wherever a feature can be expressed as new code with a small
hook, and keep the hooks few and shallow.

## Spaces with isolated cookies

**Wanted:** named spaces (Personal, School) that do not share cookies, so a
different account can be signed in inside each.

**What exists.** Chromium's Java layer on Android exposes exactly one regular
profile, through `ProfileManager.getLastUsedRegularProfile()`. There is no
profile creation, switching or picker on Android — `chrome/browser/ui/android`
has no profile picker at all, and the multi-profile UI in
`chrome/browser/profiles/profile_manager.cc` sits behind `#if
!BUILDFLAG(IS_ANDROID)`.

Two things are nonetheless available:

- **Multiple off-the-record profiles.** `OtrProfileId.createUnique(prefix)`
  plus `Profile.getOrCreateOffTheRecordProfile(id)` create as many isolated
  contexts as you like, each with its own cookie jar. Incognito Custom Tabs
  already use this. They are in-memory, so logins do not survive a restart.
- **Persistent profiles, natively.** `ProfileManager::GetProfile(path)`,
  `CreateProfileAsync`, `GetProfileByPath`, `GetLoadedProfiles` and
  `GetProfileAttributesStorage()` are *not* Android-guarded. The machinery for
  several on-disk profiles is compiled into the Android build; what is missing
  is the Java and JNI plumbing above it, and a UI to drive it.

**Recommended shape.** Two stages, because the visible part of Spaces is much
cheaper than the isolation part and is worth having on its own.

1. ~~*Spaces as an organising concept*, backed by tab groups — naming, colour,
   switching, and the rail showing one space at a time.~~ **Done**, in
   `arc/90-spaces.sh`. It came out smaller than this estimate: the rail's
   contents are set from an explicit list of tabs at a single call site, so
   narrowing it to one group is a filter there rather than new plumbing.
2. *Isolation*, by giving each space its own persistent profile: a JNI bridge
   over the native APIs above, then teaching the tab model and tab persistence
   to carry a profile per space.

Stage 2 is the large one, and not because of the profile APIs. It is that the
Android UI resolves the profile through `getLastUsedRegularProfile()` in a great
many places — tab persistence, sync, bookmarks, history, settings — each of
which assumes there is only one. Widening that assumption is the actual work.

Do not use route (a), OTR-backed spaces, as a shortcut for stage 2: cookies
that vanish on restart do not meet the requirement, and the plumbing thrown
away afterwards is most of the same plumbing.

## Done since this was written

- **Pinned tabs return to where they were pinned** — `arc/50-pinned-home.sh`,
  with the URL written through to disk and a fallback to the first entry in the
  tab's own history, which is what covers a tab reopened under a new ID.
- **Setting a pinned tab's home from the context menu** —
  `arc/80-pinned-home-menu.sh`.
- **The pinned grid** — `arc/40-pinned.sh`, three columns, tiles filling their
  cells.
- **Spaces, the organising half** — `arc/90-spaces.sh`. The rail shows one tab
  group at a time with a switcher along the bottom. Cookie isolation is still
  the open half; see below.
- **Auto picture-in-picture** — `arc/70-media.sh`, which is Arc's Mini Player
  under another name.

The sections below are what remains.

## Pinned tabs that return to where they were pinned — done

**Wanted:** closing a pinned tab (Ctrl+W, or a home button) returns it to the
URL it held when it was pinned, rather than closing it.

**What exists.** `PinnedTabClosureManager.shouldCloseTab()` already intercepts
closing a pinned tab: the first attempt records the tab as pending, shows a
toast and returns false; a second attempt within four seconds closes it. So the
interception point is upstream and stable — what is missing is the pinned-at
URL and a navigation instead of a close.

**Recommended shape.** Store the URL at pin time (there is already a tab
metadata path in `TabPersistenceUtils` and `MultiTabMetadata`), then change the
intercepted branch to navigate to it. New file for the storage and the
navigation; one anchored edit inside `shouldCloseTab`. Column layout is already
done — see `arc/40-pinned.sh`.

Worth checking on device before writing anything: unpinning may already be
restricted to the context menu. Dragging across the pinned boundary is
explicitly rejected in `VerticalTabListItemTouchHelperCallback`, and pin/unpin
live at `R.id.pin_tab_menu_id` and `R.id.unpin_tab_menu_id` in the tab context
menu, so this part of the request may need no code at all.

## The address bar in the rail

**Wanted:** the address bar inside the sidebar rather than in a toolbar across
the top, and clicking it opening a centred command palette.

**What exists.** The rail is a `SideUiContainer`
(`VerticalTabsSideUiCoordinator`) whose root is a `FrameLayout` holding the tab
list, so there is a clean place to add a view. The omnibox lives in the top
toolbar and is already aware of the rail: `ToolbarControlContainer` observes
the rail's width and active state, and `AutocompleteMediator` consults
`VerticalTabUtils.isVerticalTabsEnabled()`.

**Recommended shape.** Do not try to move `LocationBarCoordinator` into the
rail; it is wired into `ToolbarManager` deeply enough that it would be an
in-place edit of the worst kind. Instead:

1. Add a field to the rail that looks like the address bar but is only a
   button, showing the current tab's URL. New file, added to the rail's root.
2. On click, open the omnibox in its focused state as a centred overlay, and
   suppress the toolbar's own location bar while the rail is active.

Step 2 reuses the existing suggestions UI rather than reimplementing it, which
is both less work and less to re-anchor later.
