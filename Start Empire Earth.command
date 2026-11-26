#!/bin/bash
# Empire Earth (NeoEE) family launcher.
#
# Double-click to start. Runs the game exactly the way it was tested: Wine
# started directly from Terminal, inside a 1280x960 Wine virtual desktop.
# Starting from Terminal matters on macOS 15+: Apple exempts command-line tools
# run from Terminal (and their child processes) from Local Network privacy
# (TN3179), so LAN discovery does not depend on the unsigned Wineskin wrapper
# getting a Local Network prompt.
#
# Keep this file next to "Empire Earth NeoEE.app", or set EE_APP to the app path.
# Logs: ~/Library/Logs/EmpireEarthFamily/  (session monitor + optional trace)
#
# Before each start it also fits the game to this Mac's screen (added Nov 25,
# 2026; not yet run on a Mac when written, see READ-ME-FIRST.md):
#   - the match resolution is set to the screen's size, so a match fills the
#     screen even after you plug in or unplug a monitor;
#   - the zoom level is set to suit that width by set_zoom.sh, which must sit
#     next to this file. Without it the zoom level is simply left alone.
# A choice that should stick is remembered in family-settings.txt inside the
# app: "bash set_resolution.sh --resolution 1280x960" and "bash set_zoom.sh 30"
# write it, and this launcher then stops choosing for you.
#
# Options (environment variables):
#   EE_APP=/path/to/App.app   wrapper to use
#   EE_DESKTOP=1280x960       virtual desktop size
#   EE_TRACE=1                record Wine network trace (large; for diagnosis)
#   EE_RES=2560x1440          match resolution for this start (or: keep)
#   EE_ZOOM=30                zoom level for this start: stock 25 30 35 40 (or: keep)
set -u

here="$(cd "$(dirname "$0")" && pwd)"
app="${EE_APP:-}"
if [ -z "$app" ]; then
  for candidate in "$here/Empire Earth NeoEE.app" "$HOME/Applications/Empire Earth NeoEE.app" "/Applications/Empire Earth NeoEE.app"; do
    [ -d "$candidate" ] && app="$candidate" && break
  done
fi
if [ -z "$app" ] || [ ! -d "$app/Contents/SharedSupport/prefix" ]; then
  echo "Could not find 'Empire Earth NeoEE.app'. Put this file next to it or set EE_APP."
  read -r -p "Press Return to close." _; exit 1
fi

c="$app/Contents"
wine="$c/SharedSupport/wine/bin/wine64"
wineserver="$c/SharedSupport/wine/bin/wineserver"
export WINEPREFIX="$c/SharedSupport/prefix"
export DYLD_FALLBACK_LIBRARY_PATH="$c/Frameworks"
game_dir="$WINEPREFIX/drive_c/NeoEE/Empire Earth"
exe="$game_dir/Empire Earth.exe"
[ -f "$exe" ] || { echo "NeoEE is not installed in $app"; read -r -p "Press Return to close." _; exit 1; }

# "wineserver -k0" only asks whether this app's Wine is already running (signal 0).
if "$wineserver" -k0 >/dev/null 2>&1; then
  echo "Empire Earth already appears to be running. Close it first."
  read -r -p "Press Return to close." _; exit 1
fi

logs="$HOME/Library/Logs/EmpireEarthFamily"; mkdir -p "$logs"
stamp="$(date +%Y%m%d-%H%M%S)"
session="$logs/session-$stamp.log"
if [ "${EE_TRACE:-0}" = 1 ]; then
  export WINEDEBUG="+timestamp,+winsock"
  winelog="$logs/wine-$stamp.log"
else
  export WINEDEBUG="-all"
  winelog="$logs/wine-$stamp.log"
fi

{
  echo "start $(date -u +%FT%TZ) app=$app"
  sw_vers | tr '\n' ' '; echo
  echo "hostname=$(hostname) default_if=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
  ifconfig | awk '/^[a-z]/{i=$1} /inet /{print "  " i, $2}'
} > "$session"

# ---- Fit the screen: match resolution, then zoom level ----------------------
settings="$WINEPREFIX/drive_c/NeoEE/family-settings.txt"
# A remembered choice from family-settings.txt, or nothing.
setting() {
  [ -f "$settings" ] && sed -n "s/^$1=//p" "$settings" | tail -n 1
}
# The match resolution saved in the game's settings, as WIDTHxHEIGHT, or nothing.
saved_res() {
  [ -f "$WINEPREFIX/user.reg" ] || return 0
  tr -d '\r' < "$WINEPREFIX/user.reg" | awk '
    /^\[/ { inside = (index($0, "[Software\\\\Neo\\\\Empire Earth]") == 1) }
    inside && /^"Game Window Width"=dword:/  { sub(/.*dword:/, ""); w = $0 }
    inside && /^"Game Window Height"=dword:/ { sub(/.*dword:/, ""); h = $0 }
    END { if (w != "" && h != "") print w, h }' | {
      read -r w h || exit 0
      case "$w$h" in *[!0-9a-fA-F]*) exit 0;; esac
      echo "$((16#$w))x$((16#$h))"
    }
}

have_res="$(saved_res)"
want_res="${EE_RES:-$(setting resolution)}"
case "$want_res" in
  ""|auto)
    # This screen's size in points, the same reading the setup script uses.
    want_res="$(osascript -l JavaScript -e 'ObjC.import("AppKit"); var s=$.NSScreen.mainScreen.frame.size; Math.round(s.width)+"x"+Math.round(s.height)' 2>/dev/null)";;
esac
match_res="$have_res"
case "$want_res" in
  keep)
    echo "Match resolution: left at ${have_res:-the saved size}.";;
  [1-9]*x[1-9]*)
    if [ "$want_res" = "$have_res" ]; then
      echo "Match resolution: $want_res"
    else
      key='HKCU\Software\Neo\Empire Earth'
      if "$wine" reg add "$key" /v "Game Window Width"  /t REG_DWORD /d "${want_res%x*}" /f >/dev/null 2>&1 &&
         "$wine" reg add "$key" /v "Game Window Height" /t REG_DWORD /d "${want_res#*x}" /f >/dev/null 2>&1; then
        match_res="$want_res"
        echo "Match resolution: $want_res (was ${have_res:-unknown})"
      else
        echo "Match resolution: could not set $want_res; left at ${have_res:-the saved size}."
      fi
      # Let that short-lived Wine finish and save before the game starts.
      "$wineserver" -w 2>/dev/null
    fi;;
  *)
    echo "Match resolution: could not read the screen size; left at ${have_res:-the saved size}.";;
esac
echo "match_resolution=${match_res:-unknown}" >> "$session"

want_zoom="${EE_ZOOM:-$(setting zoom)}"
[ -n "$want_zoom" ] || want_zoom=auto
if [ "$want_zoom" = keep ]; then
  zoom_note="Zoom level: left as it is."
elif [ -f "$here/set_zoom.sh" ]; then
  match_width="${match_res%x*}"
  if [ "$want_zoom" = auto ]; then
    zoom_note="$(bash "$here/set_zoom.sh" --no-save --app "$app" auto ${match_width:+"$match_width"} 2>&1)"
  else
    zoom_note="$(bash "$here/set_zoom.sh" --no-save --app "$app" "$want_zoom" 2>&1)"
  fi
else
  zoom_note="Zoom level: set_zoom.sh is not next to this launcher; not changed."
fi
echo "$zoom_note"
echo "zoom: $zoom_note" >> "$session"

cd "$game_dir"
"$wine" explorer.exe "/desktop=EmpireEarth,${EE_DESKTOP:-1280x960}" "$exe" > "$winelog" 2>&1 &
launcher=$!

# Session monitor: once a minute, record the game process CPU/memory and whether
# the Mac itself is responsive. After a "freeze", this log distinguishes: game
# pegged or idle, Wine gone, or the whole Mac stalled (gaps in timestamps).
echo "Empire Earth is starting. Leave this window open while playing."
echo "Session log: $session"
sleep 20
# In desktop mode the first wine process may exit early; follow the game itself.
while kill -0 "$launcher" 2>/dev/null || "$wineserver" -k0 >/dev/null 2>&1; do
  line="$(ps -axo pid=,pcpu=,rss=,etime=,state=,command= | awk '$6 ~ /^\// && /NeoEE\/Empire Earth\/Empire Earth.exe/ {print "game pid=" $1 " cpu=" $2 " rss_kb=" $3 " up=" $4 " state=" $5; exit}')"
  echo "$(date -u +%FT%TZ) ${line:-game-not-running} load=$(sysctl -n vm.loadavg)" >> "$session"
  sleep 60
done
"$wineserver" -w 2>/dev/null
echo "end $(date -u +%FT%TZ)" >> "$session"
echo "Empire Earth has closed. You can close this window."
