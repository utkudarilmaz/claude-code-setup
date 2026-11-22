#!/bin/bash
# Notification hook: plays a sound when Claude Code sends a notification.
# Fallback chain covers macOS (afplay), PulseAudio (paplay), and ALSA (aplay).

afplay /System/Library/Sounds/Glass.aiff 2>/dev/null ||
  paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null ||
  aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null ||
  true
