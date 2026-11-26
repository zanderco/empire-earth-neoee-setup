#!/bin/bash
# Start Empire Earth (NeoEE) on this Linux machine.
#
# Uses the game-only Wine prefix built on 2026-11-25. Before each start it does
# two things for the monitor the game will open on:
#   - sets the match resolution to the monitor's size, because a match only
#     fills the screen when the two are equal (menus and the lobby are always a
#     1024x768 box in the top-left corner);
#   - sets the zoom level to suit that width (see set_zoom.sh), because on a
#     wide monitor the game otherwise looks zoomed in.
#
# Usage: start-empire-earth.sh
#   EMPIRE_EARTH_RES=2560x1440 start-empire-earth.sh   use this size instead
#   EMPIRE_EARTH_RES=keep      start-empire-earth.sh   leave the saved size alone
#   EMPIRE_EARTH_ZOOM=30       start-empire-earth.sh   this zoom level (stock 25 30 35 40)
#   EMPIRE_EARTH_ZOOM=keep     start-empire-earth.sh   leave the zoom level alone
#   EMPIRE_EARTH_DESKTOP=3     start-empire-earth.sh   open on desktop 3, not 5
#
# A choice that should stick goes in family-settings.txt next to the game
# folder (prefix/drive_c/NeoEE/): lines "resolution=1920x1200" and "zoom=30".
# "bash set_zoom.sh 30" writes the zoom line for you.
set -u

base="${EMPIRE_EARTH_HOME:-$HOME/.local/share/empire-earth-neoee}"
export WINEPREFIX="$base/prefix"
game="$WINEPREFIX/drive_c/NeoEE/Empire Earth"
logdir="$base/logs"
here="$(dirname "$(readlink -f "$0")")"   # this file may be started through a link
settings="$WINEPREFIX/drive_c/NeoEE/family-settings.txt"

# A remembered choice from family-settings.txt, or nothing.
setting() {
  [ -f "$settings" ] && sed -n "s/^$1=//p" "$settings" | tail -n 1
}

# Tell the user why nothing happened, in the terminal and (when started from
# the app launcher, where there is no terminal) as a desktop notification.
fail() {
  printf 'Empire Earth: %s\n' "$*" >&2
  command -v notify-send >/dev/null 2>&1 && notify-send "Empire Earth" "$*"
  exit 1
}

command -v wine >/dev/null 2>&1 || fail "wine is not installed."
[ -f "$game/Empire Earth.exe" ] || fail "Game not found in $game"

# A second copy would fight the first one for the game's network ports.
if pgrep -x 'Empire Earth.ex' >/dev/null 2>&1; then
  fail "The game is already running."
fi

mkdir -p "$logdir"
log="$logdir/session-$(date +%Y%m%d-%H%M%S).log"
# Keep the ten newest session logs.
ls -1t "$logdir"/session-*.log 2>/dev/null | tail -n +10 | while IFS= read -r old; do
  rm -f -- "$old"
done

# Wine prints thousands of harmless "fixme" lines for this game; keep errors only.
export WINEDEBUG="${WINEDEBUG:-fixme-all}"

# Size, in the pixels the game sees, of the monitor that has focus (the game
# opens there). Prints WIDTHxHEIGHT, or nothing if it cannot tell.
monitor_size() {
  command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 || return 0
  local zero
  # With force_zero_scaling, X11 programs (Wine) see real pixels; without it
  # they see the scaled size.
  zero="$(hyprctl getoption xwayland:force_zero_scaling -j 2>/dev/null | jq -r '.bool // false' 2>/dev/null)"
  hyprctl monitors -j 2>/dev/null | jq -r --arg zero "$zero" '
    (map(select(.focused)) | first) // first
    | (if (.transform % 2) == 1 then {w: .height, h: .width} else {w: .width, h: .height} end) as $px
    | (if $zero == "true" then 1 else .scale end) as $div
    | "\(($px.w / $div) | floor)x\(($px.h / $div) | floor)"' 2>/dev/null
}

res="${EMPIRE_EARTH_RES:-$(setting resolution)}"
case "$res" in ""|auto) res="$(monitor_size)" ;; esac

case "$res" in
  keep|"")
    echo "Match resolution: left as saved." ;;
  [1-9]*x[1-9]*)
    neo='HKCU\Software\Neo\Empire Earth'
    if wine reg add "$neo" /v "Game Window Width"  /t REG_DWORD /d "${res%x*}" /f >>"$log" 2>&1 &&
       wine reg add "$neo" /v "Game Window Height" /t REG_DWORD /d "${res#*x}" /f >>"$log" 2>&1; then
      echo "Match resolution: $res"
    else
      echo "Match resolution: could not set $res; using the saved size. See $log"
    fi ;;
  *)
    echo "Match resolution: ignoring '$res' (expected WIDTHxHEIGHT); using the saved size." ;;
esac

# Zoom level: wide matches look zoomed in unless the zoom-out limit is raised.
zoom="${EMPIRE_EARTH_ZOOM:-$(setting zoom)}"
case "$zoom" in "") zoom=auto ;; esac
if [ "$zoom" = keep ]; then
  echo "Zoom level: left as it is."
elif [ -f "$here/set_zoom.sh" ]; then
  case "$res" in
    [1-9]*x[1-9]*) width="${res%x*}" ;;
    *) width="" ;;   # set_zoom.sh then reads the saved match width
  esac
  if [ "$zoom" = auto ]; then
    bash "$here/set_zoom.sh" --no-save --exe "$game/Empire Earth.exe" auto $width
  else
    bash "$here/set_zoom.sh" --no-save --exe "$game/Empire Earth.exe" "$zoom"
  fi || echo "Zoom level: not changed (see the line above); starting anyway."
else
  echo "Zoom level: set_zoom.sh is not next to this script; not changed."
fi

# Open the game on its own desktop so it does not cover other windows. This is
# the focused monitor's desktop 5, the one Super+5 goes to. Set
# EMPIRE_EARTH_DESKTOP to another number, or to nothing to stay where you are.
desktop="${EMPIRE_EARTH_DESKTOP-5}"
case "$desktop" in
  [1-9]|10)
    if command -v hyprctl >/dev/null 2>&1; then
      # Omarchy's own per-monitor desktop switch, the same call the key uses.
      hyprctl dispatch "o.workspaces.focus($desktop)" >/dev/null 2>&1 ||
        echo "Could not switch to desktop $desktop; starting on the current one."
    fi ;;
esac

cd "$game" || fail "Cannot enter $game"
echo "Starting Empire Earth. Log: $log"
exec wine "Empire Earth.exe" >>"$log" 2>&1
