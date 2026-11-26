#!/bin/bash
# Set the in-match resolution of an installed Empire Earth NeoEE app.
# With no arguments it uses this Mac's screen size, which makes matches fill the
# whole screen (menus and the lobby stay a 1024x768 window; that is how the game works).
#
#   bash set_resolution.sh                      # full screen on this Mac
#   bash set_resolution.sh --resolution 1280x960
#
# The launcher fits the screen by itself at every start. A size given here with
# --resolution is remembered (family-settings.txt inside the app) and the
# launcher then keeps it; running this with no arguments hands the choice back
# to the launcher.
#   bash set_resolution.sh --app "/path/Empire Earth NeoEE.app"
set -u
app="$HOME/Applications/Empire Earth NeoEE.app"; res=""; remember=auto
while [ $# -gt 0 ]; do
  case "$1" in
    --app) app="$2"; shift 2;;
    --resolution) res="$2"; remember="$2"; shift 2;;
    *) echo "Unknown option: $1"; exit 2;;
  esac
done
c="$app/Contents"; wine="$c/SharedSupport/wine/bin/wine64"; wineserver="$c/SharedSupport/wine/bin/wineserver"
[ -x "$wine" ] || { echo "STOPPED: $app not found. Pass --app."; exit 1; }
export WINEPREFIX="$c/SharedSupport/prefix" DYLD_FALLBACK_LIBRARY_PATH="$c/Frameworks" WINEDEBUG=-all
if "$wineserver" -k0 >/dev/null 2>&1; then echo "STOPPED: quit Empire Earth first."; exit 1; fi
if [ -z "$res" ]; then
  res="$(osascript -l JavaScript -e 'ObjC.import("AppKit"); var s=$.NSScreen.mainScreen.frame.size; Math.round(s.width)+"x"+Math.round(s.height)' 2>/dev/null)"
fi
case "$res" in [0-9]*x[0-9]*) ;; *) echo "STOPPED: could not read the screen size; pass --resolution WIDTHxHEIGHT."; exit 1;; esac
w="${res%x*}"; h="${res#*x}"
key='HKCU\Software\Neo\Empire Earth'
"$wine" reg add "$key" /v "Game Window Width"  /t REG_DWORD /d "$w" /f >/dev/null 2>&1 && \
"$wine" reg add "$key" /v "Game Window Height" /t REG_DWORD /d "$h" /f >/dev/null 2>&1 || { echo "STOPPED: could not write the setting."; exit 1; }
"$wineserver" -w 2>/dev/null
settings="$WINEPREFIX/drive_c/NeoEE/family-settings.txt"
{ [ -f "$settings" ] && grep -v '^resolution=' "$settings"; echo "resolution=$remember"; } > "$settings.new" 2>/dev/null &&
  mv -f "$settings.new" "$settings"
echo "Match resolution set to ${w}x${h}. Start the game as usual."
