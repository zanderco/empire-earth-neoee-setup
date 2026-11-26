#!/bin/bash
# Empire Earth (NeoEE): set how far the camera can zoom out. Mac and Linux.
#
# The game shows the same left-to-right slice of the map on every screen, so on
# a big or very wide monitor everything looks zoomed in. The limit on zooming
# out is a number inside "Empire Earth.exe". This script changes that number
# (and the draw distance and sound distance that go with it) to one of five
# fixed levels, so that two computers on the same level have identical files.
# The numbers are the ones the community tool EmpireEarthZoomChanger edits
# (https://github.com/j-frei/EmpireEarthZoomChanger).
#
#   bash set_zoom.sh status       show the current level
#   bash set_zoom.sh auto         pick the level for the saved match resolution
#   bash set_zoom.sh auto 3440    pick the level for a match 3440 pixels wide
#   bash set_zoom.sh 35           use level 35 from now on (stock 25 30 35 40)
#   bash set_zoom.sh stock        put the original values back, from now on
#
# Options: --app "/path/Empire Earth NeoEE.app"   Mac app to change
#          --exe "/path/Empire Earth.exe"         game file to change
#          --no-save   do not remember the choice (the launchers use this)
#
# A level chosen here by hand is remembered in family-settings.txt next to the
# game folder, and the launcher keeps using it. "auto" hands the choice back to
# the launcher. Quit the game before changing the level.
#
# Level   zoom-out limit   draw distance   meant for a match about this wide
# stock        20.5             35         up to 1950 pixels (laptops)
# 25           25               43         2050 to 2350
# 30           30               51         2400 to 2750 (2560x1440)
# 35           35               60         2800 to 3200
# 40           40               68         3250 and wider (3440x1440)
#
# Safe by construction: it only ever writes 20 known bytes, it refuses any file
# that is not the tested NeoEE 2.0.0.5 game file apart from those bytes, and it
# checks the result against a known fingerprint before replacing the file.
# Written for the bash 3.2 that ships with macOS.
set -u

SIZE=11978080
CAM_AT=4374272   # 0x42bf00: zoom-out limit, draw distance (two 4-byte numbers)
SND_AT=4403964   # 0x4332fc: sound fade start, fade end, fade slope (three)
LEVELS="stock 25 30 35 40"

# For one level: the bytes to write and the SHA-256 of the resulting file.
level_data() {
  case "$1" in
    stock) cam=0000a4c100000c42; snd=0000d84100000c420000003e
           sum=e352d7ae5ebc91f8d2f9c4363e41e990d7be8b063b1ee9e686a0d2a5f9bea2b5
           about="zoom-out limit 20.5, draw distance 35, the original file";;
    25)    cam=0000c8c100002c42; snd=8baf044200002c42415fd03d
           sum=62fc282b7417dab89e32373e7b99bf61b218a4669964c5e5d0f8818946801412
           about="zoom-out limit 25, draw distance 43";;
    30)    cam=0000f0c100004c42; snd=165f1d4200004c42b0afaf3d
           sum=69514c243baa16637c1db9f219b30ca7ad30af8bf3bcecfc96646aeb3fc61085
           about="zoom-out limit 30, draw distance 51";;
    35)    cam=00000cc200007042; snd=92243942000070425555953d
           sum=9083ee56dd8b55a2d1bfb9d24cc459ea1583432ad407b25a786cba9bfc204ce2
           about="zoom-out limit 35, draw distance 60";;
    40)    cam=000020c200008842; snd=1dd4514200008842c4c3833d
           sum=d4ca2f1df6fe66bba1ef20c07f2817af1af39895c8a13f673c596f18b773b27b
           about="zoom-out limit 40, draw distance 68";;
    *) return 1;;
  esac
}

# The level that keeps things about the size they are on a 1920-wide screen.
level_for_width() {
  if   [ "$1" -lt 1957 ]; then echo stock
  elif [ "$1" -lt 2365 ]; then echo 25
  elif [ "$1" -lt 2795 ]; then echo 30
  elif [ "$1" -lt 3225 ]; then echo 35
  else echo 40
  fi
}

stop() { printf 'set_zoom: %s\n' "$*" >&2; exit 1; }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# write_hex FILE OFFSET HEX: overwrite bytes in place.
write_hex() {
  local escaped
  escaped="$(printf '%s' "$3" | sed 's/../\\x&/g')"
  # The format string is built from the fixed table above, never from input.
  # shellcheck disable=SC2059
  printf "$escaped" | dd of="$1" bs=1 seek="$2" conv=notrunc 2>/dev/null
}

app=""; exe=""; save=1; action=""; width=""
while [ $# -gt 0 ]; do
  case "$1" in
    --app) app="${2:-}"; shift 2;;
    --exe) exe="${2:-}"; shift 2;;
    --no-save) save=0; shift;;
    -h|--help) sed -n '2,36p' "$0"; exit 0;;
    -*) stop "unknown option: $1";;
    *) if [ -z "$action" ]; then action="$1"; elif [ -z "$width" ]; then width="$1"; else stop "too many arguments."; fi; shift;;
  esac
done
[ -n "$action" ] || { sed -n '2,36p' "$0"; exit 2; }

# Find the game file: --exe, then --app or EE_APP, then the usual places.
if [ -z "$exe" ]; then
  [ -n "$app" ] || app="${EE_APP:-}"
  if [ -z "$app" ]; then
    for candidate in "$HOME/Applications/Empire Earth NeoEE.app" "/Applications/Empire Earth NeoEE.app"; do
      [ -d "$candidate" ] && app="$candidate" && break
    done
  fi
  if [ -n "$app" ]; then
    exe="$app/Contents/SharedSupport/prefix/drive_c/NeoEE/Empire Earth/Empire Earth.exe"
  else
    exe="${EMPIRE_EARTH_HOME:-$HOME/.local/share/empire-earth-neoee}/prefix/drive_c/NeoEE/Empire Earth/Empire Earth.exe"
  fi
fi
[ -f "$exe" ] || stop "game file not found: $exe"
game_dir="$(dirname "$exe")"
neoee_dir="$(dirname "$game_dir")"            # .../drive_c/NeoEE
prefix="$(dirname "$(dirname "$neoee_dir")")" # the Wine prefix
settings="$neoee_dir/family-settings.txt"

game_running() {
  local wineserver="$prefix/../wine/bin/wineserver"
  if [ -x "$wineserver" ]; then
    # Mac app: signal 0 only asks whether this app's Wine is running.
    WINEPREFIX="$prefix" DYLD_FALLBACK_LIBRARY_PATH="$prefix/../../Frameworks" "$wineserver" -k0 >/dev/null 2>&1
  else
    pgrep -x 'Empire Earth.ex' >/dev/null 2>&1
  fi
}

# Match width saved in the game's settings, or nothing.
saved_width() {
  [ -f "$prefix/user.reg" ] || return 0
  local hex
  hex="$(tr -d '\r' < "$prefix/user.reg" | awk '
    /^\[/ { inside = (index($0, "[Software\\\\Neo\\\\Empire Earth]") == 1) }
    inside && /^"Game Window Width"=dword:/ { sub(/.*dword:/, ""); width = $0 }
    END { print width }')"
  case "$hex" in ""|*[!0-9a-fA-F]*) return 0;; esac
  echo $((16#$hex))
}

current_level() {
  local have name
  have="$(sha256_of "$exe")"
  for name in $LEVELS; do
    level_data "$name"
    [ "$have" = "$sum" ] && { echo "$name"; return 0; }
  done
  return 1
}

remember() {
  [ "$save" = 1 ] || return 0
  { [ -f "$settings" ] && grep -v '^zoom=' "$settings"; echo "zoom=$1"; } > "$settings.new" 2>/dev/null &&
    mv -f "$settings.new" "$settings"
}

case "$action" in
  status)
    if level="$(current_level)"; then
      level_data "$level"; echo "Zoom level $level ($about)."
    else
      echo "Zoom level unknown: this is not one of the five known game files."
    fi
    exit 0;;
  auto)
    [ -n "$width" ] || width="$(saved_width)"
    width="${width%%x*}"
    case "$width" in ""|*[!0-9]*) stop "could not tell the match width; use: set_zoom.sh auto WIDTH";; esac
    level="$(level_for_width "$width")"
    choice=auto;;
  *)
    level_data "$action" || stop "unknown level '$action'. Use one of: auto $LEVELS."
    level="$action"; choice="$action";;
esac

level_data "$level"
want_cam="$cam"; want_snd="$snd"; want_sum="$sum"; want_about="$about"

if [ "$(sha256_of "$exe")" = "$want_sum" ]; then
  remember "$choice"
  echo "Zoom level $level ($want_about). Already set."
  exit 0
fi

game_running && stop "the game is running. Quit it first."
[ "$(wc -c < "$exe" | tr -d ' ')" = "$SIZE" ] || stop "this is not the tested game file (wrong size). Nothing was changed."

# Work on a copy. First put the original bytes back: if the copy is then not
# exactly the original game file, something else differs and we leave it alone.
tmp="$exe.zoom-tmp"
cp -p "$exe" "$tmp" || stop "could not copy the game file."
level_data stock
write_hex "$tmp" "$CAM_AT" "$cam" && write_hex "$tmp" "$SND_AT" "$snd" || { rm -f "$tmp"; stop "could not write. Nothing was changed."; }
if [ "$(sha256_of "$tmp")" != "$sum" ]; then
  rm -f "$tmp"
  stop "this is not the tested NeoEE 2.0.0.5 game file. Nothing was changed."
fi
if [ "$level" != stock ]; then
  write_hex "$tmp" "$CAM_AT" "$want_cam" && write_hex "$tmp" "$SND_AT" "$want_snd" || { rm -f "$tmp"; stop "could not write. Nothing was changed."; }
fi
if [ "$(sha256_of "$tmp")" != "$want_sum" ]; then
  rm -f "$tmp"
  stop "the changed file did not match its known fingerprint. Nothing was changed."
fi
mv -f "$tmp" "$exe" || { rm -f "$tmp"; stop "could not replace the game file."; }
remember "$choice"
echo "Zoom level $level ($want_about)."
