# Updating Chromium

The browser is not a fork of Chromium. It is a set of patches applied to a
pristine Chromium checkout at build time, so moving to a new Chromium release
means pointing the build at a new version and fixing whatever the patches no
longer match. Nothing is vendored and there is no long-lived merge to resolve.

## How the version is chosen

`chromium_version()` in `common.sh` resolves it, in this order:

| Source | When to use it |
| --- | --- |
| `$CHROMIUM_VERSION` | Trying a version out for one build |
| `chromium.version` | Pinning the repo to a version, overriding Vanadium |
| `vanadium/args.gn` | The default: whatever the Vanadium submodule is on |

`chromium.version` is not checked in. Create it only when you deliberately want
to hold a version, and remember that the Vanadium patches are written against
the Chromium that Vanadium itself targets — pin too far away from it and those
patches, not ours, are what will fail to apply.

## The patch stack

Applied in this order, each on top of the last:

1. **Vanadium** — `vanadium/patches/*.patch`, applied with `git am`. The
   security and privacy base. A conflict here fails loudly by itself.
2. **`patch.sh`** — Titanium's layer: extensions, Manifest V2, off-store
   installs, desktop behaviours, upstream bug workarounds.
3. **`arc.sh`** — the Arc layer: the sidebar, large-screen and pointer
   behaviour, appearance. See [ARC.md](ARC.md).

## Bumping

The scheduled build in `.github/workflows/build.yml` moves the Vanadium
submodule to its newest tag every 16 days, commits it, and builds. Most of the
time you do not do anything.

To do it by hand:

```shell
cd vanadium && git fetch --tags && git checkout "$(git tag | sort -V | tail -n1)" && cd ..
tools/verify_patches.sh
```

`verify_patches.sh` asks `arc.sh` which files it touches, downloads only those
files at the target version, and reports whether every patch still has
something to attach to. It needs no checkout, no `gclient sync`, and no build,
so a bump is a few seconds of work when nothing broke.

```
[arc] ok   rail expands on hover
[arc] FAIL sidebar is the default layout
[arc]      anchor not found in .../ChromeFeatureList.java
```

If it passes, commit the submodule bump. If it fails, re-anchor the patches it
named before you start a build.

You can also check a version before moving to it:

```shell
tools/verify_patches.sh 153.0.8000.0
```

## Re-anchoring a patch

Every patch in `arc/` declares three things: the upstream text it needs
(**anchor**), the edit (**sed expression**), and the text it expects to leave
behind (**result**). A patch fails when the anchor is gone, which is exactly
the case a bare `sed -i` gets wrong — it matches nothing, changes nothing,
returns success, and ships an APK quietly missing the feature.

To fix one:

1. Read the failure. It names the patch and the file.
2. Look at the file at the new version. `verify_patches.sh` leaves nothing
   behind, so fetch it directly:

   ```shell
   curl -s "https://raw.githubusercontent.com/chromium/chromium/153.0.8000.0/<path>" | less
   ```
3. Find where the code went. Usually it moved a few lines, was reformatted, or
   the flag was renamed. Occasionally the feature shipped and the flag is gone
   entirely — then delete the patch, and note it in `arc/` as one of the
   behaviours upstream now does by itself.
4. Update the anchor, the sed expression and the result together.
5. Re-run `tools/verify_patches.sh`.

Both halves matter: the anchor catches Chromium moving, and the result catches
an edit that matched but did not do what it meant to.

## When a feature ships upstream

Chromium enables these behind flags first and turns them on when they are
ready. When a flag we flip becomes the default, its `BASE_FEATURE` line stops
saying `DISABLED_BY_DEFAULT`, the patch fails, and the fix is to delete it —
the behaviour stays, and the layer gets smaller. `arc/20-tablet.sh` lists the
ones that have already made that trip.

## Notes

- `arc.sh` is not idempotent by design. It verifies an anchor before editing,
  so running it twice over one checkout fails the second time: the anchors are
  gone because the first run consumed them. `build.sh` runs it once against a
  fresh checkout.
- `arc.sh` refuses to run before `patch.sh`, since it builds on that layer.
- If `chromium/src` exists, `verify_patches.sh` checks against it instead of
  downloading. A checkout that has already been built is patched in place, so
  verify against a fresh one.
