#!/bin/bash
#
# Identity.
#
# The build installs as its own app rather than as an update to Titanium, so
# both can be installed at once and Titanium can stay the default browser.
#
# Two halves, and both are needed:
#
#   - The package ID, in args.gn. Android keys an installed app on it, so a
#     different ID is a different app. This is the half that decides whether
#     the two coexist.
#   - The name shown to the user, here. Without it both apps read "Titanium"
#     in the launcher and the app switcher, which is useless when the point is
#     to run them side by side.
#
# The resource directory this patches, res_titanium_base, is itself named by
# patch.sh — build.sh rewrites Vanadium's patches from "Vanadium" to
# "Titanium" before applying them, which is where every internal use of the
# name comes from. Only the strings a user actually sees are changed here; the
# internal naming is left alone, since renaming it would mean rebuilding from
# scratch to no visible effect.
#
# Change the package ID before a release, never after: Android treats a new ID
# as a different app, so an installed copy will not update across the change.

arc_section "Identity"

arc_apply_patch "app name shown to the user" \
    "$ARC_ROOT/arc/patches/60-identity.patch"
