#!/bin/bash
#
# Media.
#
# Arc's Mini Player is a video that pops out into a floating window and keeps
# playing when you go and do something else. Android has exactly this natively
# as picture-in-picture, and Chromium can enter it automatically rather than
# waiting to be asked — it is simply switched off.
#
# Unlike the rest of the layer these live in media/, not in Chromium's Android
# flag list, because they are engine-level rather than Android-UI-level.
#
# To turn it off again, chrome://flags has it; this only changes which way it
# defaults.

arc_section "Media"

MEDIA=media/base/media_switches.cc

# Video pops out and keeps playing when you leave the tab it is in, instead of
# stopping or needing to be put into picture-in-picture by hand.
arc_enable "$MEDIA" kAutoPictureInPictureAndroid
