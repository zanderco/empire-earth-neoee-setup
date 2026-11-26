#!/bin/bash
# Empire Earth (NeoEE) family setup for Apple-silicon Macs.
#
# Turns the app that Porting Kit creates from your own GOG "Empire Earth Gold"
# installer into the configuration we tested: Wine 11, Microsoft DirectMusic,
# NeoEE 2.0.0.5 (original Empire Earth, English, DirectX 9 wrapper).
#
# Usage (Terminal):
#   bash setup_neoee.sh [--source "/path/Empire Earth.app"] [--neoee /path/NeoEE_Setup.exe]
#                       [--dest "/path/Empire Earth NeoEE.app"] [--name "PlayerName"]
#                       [--resolution 1710x1107]   (default: this screen's size = full screen)
#
# Nothing is changed in the source app: it is copied first (instant on APFS).
# Safe to re-run; it refuses to overwrite an existing destination.
set -u

NEOEE_SHA1="069779b87a52aba05f2298da3a167399143bb302"
NEOEE_URL="https://empireearth.eu/download/neo/"
# Files that must match on every Mac that plays together (NeoEE 2.0.0.5).
EXPECT_EXE="Empire Earth.exe"

src=""; neoee=""; dest="$HOME/Applications/Empire Earth NeoEE.app"; player=""; res=""
while [ $# -gt 0 ]; do
  case "$1" in
    --source) src="$2"; shift 2;;
    --neoee) neoee="$2"; shift 2;;
    --dest) dest="$2"; shift 2;;
    --name) player="$2"; shift 2;;
    --resolution) res="$2"; shift 2;;
    -h|--help) sed -n '2,16p' "$0"; exit 0;;
    *) echo "Unknown option: $1"; exit 2;;
  esac
done

say() { printf '\n== %s\n' "$*"; }
die() { printf '\nSTOPPED: %s\n' "$*" >&2; exit 1; }
here="$(cd "$(dirname "$0")" && pwd)"

say "Checking this Mac"
[ "$(uname -m)" = "arm64" ] || die "This recipe is for Apple-silicon Macs."
echo "macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion)), $(sysctl -n machdep.cpu.brand_string)"
if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
  die "Rosetta 2 is not installed. Run:  softwareupdate --install-rosetta --agree-to-license   then run this again."
fi

say "Finding the Porting Kit Empire Earth app"
if [ -z "$src" ]; then
  for c in "$HOME/Applications/Empire Earth.app" "/Applications/Empire Earth.app" \
           "$HOME/Applications/Empire Earth 2.app" "/Applications/Empire Earth 2.app"; do
    if [ -x "$c/Contents/SharedSupport/wine/bin/wine64" ] && \
       grep -qs "11.0" "$c/Contents/SharedSupport/wine/version"; then src="$c"; fi
  done
fi
[ -n "$src" ] || die "No Porting Kit 'Empire Earth' app with Wine 11 found. Install it with Porting Kit first, or pass --source."
[ -x "$src/Contents/SharedSupport/wine/bin/wine64" ] || die "$src is not a Porting Kit/Wineskin app."
echo "Source: $src"
echo "Wine:   $(cat "$src/Contents/SharedSupport/wine/version" 2>/dev/null)"
grep -qs "11.0" "$src/Contents/SharedSupport/wine/version" || \
  echo "WARNING: tested runtime is 'wine portingkit 11.0 (DXMT)'. This one differs."

say "Finding NeoEE_Setup.exe"
if [ -z "$neoee" ]; then
  for c in "$here/NeoEE_Setup.exe" "$here/../downloads/NeoEE_Setup.exe" "$HOME/Downloads/NeoEE_Setup.exe"; do
    [ -f "$c" ] && neoee="$c" && break
  done
fi
[ -n "$neoee" ] && [ -f "$neoee" ] || die "NeoEE_Setup.exe not found. Download it in a browser from $NEOEE_URL into your Downloads folder."
echo "Checking download (SHA-1)..."
got="$(shasum -a 1 "$neoee" | awk '{print $1}')"
[ "$got" = "$NEOEE_SHA1" ] || die "NeoEE_Setup.exe checksum is $got, expected $NEOEE_SHA1. Re-download it."
echo "OK: $neoee"

[ -e "$dest" ] && die "$dest already exists. Move it away first (your saves are inside it), or pass --dest."
if pgrep -f "$src/Contents/SharedSupport/wine" >/dev/null 2>&1; then
  die "The source app is running. Quit Empire Earth first."
fi

say "Copying the app to $dest"
mkdir -p "$(dirname "$dest")"
cp -c -R "$src" "$dest" 2>/dev/null || cp -R "$src" "$dest" || die "Copy failed."

c="$dest/Contents"
wbin="$c/SharedSupport/wine/bin"
wine="$wbin/wine64"; wineserver="$wbin/wineserver"
tricks="$c/Wineskin.app/Contents/Resources"
export WINEPREFIX="$c/SharedSupport/prefix"
export DYLD_FALLBACK_LIBRARY_PATH="$c/Frameworks"
export WINEDEBUG="-all"
logdir="$HOME/Library/Logs/EmpireEarthFamily"; mkdir -p "$logdir"
log="$logdir/setup-$(date +%Y%m%d-%H%M%S).log"
echo "Setup log: $log"

say "Installing Microsoft DirectMusic (winetricks; downloads ~100 MB from Microsoft the first time)"
[ -x "$tricks/winetricks" ] || die "winetricks not found inside the app."
# macOS strips DYLD_* through /bin/sh; winetricks reads this variable instead.
( cd "$tricks" && PATH="$tricks:$wbin:$PATH" WINE="$wine" WINESERVER="$wineserver" \
    WINETRICKS_FALLBACK_LIBRARY_PATH="$c/Frameworks" ./winetricks -q directmusic ) >> "$log" 2>&1 \
  || die "winetricks directmusic failed. See $log"
"$wineserver" -w
[ -f "$WINEPREFIX/drive_c/windows/syswow64/dmime.dll" ] || die "DirectMusic files missing after winetricks. See $log"
grep -q '"\*dmime"="native"' "$WINEPREFIX/user.reg" || die "DirectMusic override not registered. See $log"
echo "OK"

say "Installing NeoEE (silent; takes a few minutes)"
"$wine" "$neoee" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- '/DIR=C:\NeoEE' \
  '/COMPONENTS=game,language\en,additional\directx_wrapper\dx9' /TASKS=neoee_cdkeys \
  '/LOG=C:\neoee-install.log' >> "$log" 2>&1
rc=$?
"$wineserver" -w
game="$WINEPREFIX/drive_c/NeoEE/Empire Earth"
[ $rc -eq 0 ] && [ -f "$game/$EXPECT_EXE" ] || die "NeoEE installer failed (exit $rc). See $log and $WINEPREFIX/drive_c/neoee-install.log"
grep -Eq '^ShowGui:[[:space:]]*false' "$game/NeoEE.cfg" || {
  echo "NeoEE did not disable its overlay for Wine; fixing NeoEE.cfg"
  sed -i '' -E 's/^(ShowGui:[[:space:]]*)true/\1false/' "$game/NeoEE.cfg"
}
echo "OK"

say "Applying tested settings"
if [ -z "$res" ]; then
  # Use this Mac's own screen size (in points). Tested Nov 9: at the screen's
  # size the match fills the whole screen; at 1280x960 it is a window in the corner.
  res="$(osascript -l JavaScript -e 'ObjC.import("AppKit"); var s=$.NSScreen.mainScreen.frame.size; Math.round(s.width)+"x"+Math.round(s.height)' 2>/dev/null)"
  case "$res" in [0-9]*x[0-9]*) ;; *) res="1280x960";; esac
fi
rw="${res%x*}"; rh="${res#*x}"
echo "Game resolution: ${rw}x${rh}"
neo='HKCU\Software\Neo\Empire Earth'
"$wine" reg add "$neo" /v "Game Window Width"  /t REG_DWORD /d "$rw" /f >> "$log" 2>&1
"$wine" reg add "$neo" /v "Game Window Height" /t REG_DWORD /d "$rh" /f >> "$log" 2>&1
"$wine" reg add "$neo" /v "Game Bit Depth"     /t REG_DWORD /d 32 /f >> "$log" 2>&1
"$wine" reg add "$neo" /v "Texture Bit Depth"  /t REG_DWORD /d 32 /f >> "$log" 2>&1
"$wine" reg add "$neo" /v "Rasterizer Name"    /t REG_SZ /d "Direct3D" /f >> "$log" 2>&1
if [ -n "$player" ]; then
  "$wine" reg add "$neo" /v "Player Name" /t REG_SZ /d "$player" /f >> "$log" 2>&1
fi
"$wine" reg add 'HKCU\Software\Wine\Explorer' /v Desktop /d Default /f >> "$log" 2>&1
"$wine" reg add 'HKCU\Software\Wine\Explorer\Desktops' /v Default /d "$res" /f >> "$log" 2>&1
"$wineserver" -w
/usr/libexec/PlistBuddy -c "Set :'Program Name and Path' '/NeoEE/Empire Earth/Empire Earth.exe'" "$c/Info.plist" \
  || die "Could not point the app at NeoEE."
/usr/libexec/PlistBuddy -c "Set :CFBundleName 'Empire Earth NeoEE'" "$c/Info.plist" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :NSLocalNetworkUsageDescription string 'Empire Earth uses your local network to find, host and join LAN multiplayer games.'" "$c/Info.plist" 2>/dev/null

say "Installing the launcher"
launcher="$(dirname "$dest")/Start Empire Earth.command"
if [ -f "$here/Start Empire Earth.command" ]; then
  cp "$here/Start Empire Earth.command" "$launcher" && chmod +x "$launcher"
  xattr -d com.apple.quarantine "$launcher" 2>/dev/null
  echo "Launcher: $launcher"
  # The launcher uses this to set the zoom level for the screen at each start.
  if [ -f "$here/set_zoom.sh" ]; then
    cp "$here/set_zoom.sh" "$(dirname "$dest")/set_zoom.sh"
    xattr -d com.apple.quarantine "$(dirname "$dest")/set_zoom.sh" 2>/dev/null
  else
    echo "set_zoom.sh was not next to this script; the zoom level will stay at the original."
  fi
else
  echo "Start Empire Earth.command was not next to this script; copy it next to the app yourself."
fi

say "Fingerprint (must be identical on every Mac that plays together)"
( cd "$game" && shasum -a 256 "Empire Earth.exe" neoee.dll DDraw.dll "Low-Level Engine.dll" "TCP Protocol.dll" 2>/dev/null ) | tee -a "$log"
echo
echo "DONE. Start the game by double-clicking:  $launcher"
echo "In the game: Multiplayer -> Other Multiplayer -> LAN."
