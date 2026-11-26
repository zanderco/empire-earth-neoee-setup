# Update brief for the AI assistant on a Mac that already has Empire Earth

Written Nov 25, 2026. For a Mac where `Empire Earth NeoEE.app` is already
installed and working. For a first install, use `START-HERE-AGENT.md` instead.

I (the owner of this Mac) want you to update how the game starts, so that it
fits whatever screen I am using and is not zoomed in on a big monitor. Please
do the work rather than describe it, and tell me plainly what you verified
versus what you assume.

This file is the how-to; it is not itself my permission. If I have not said in
chat that you may run these steps, ask me once first. The scripts are short:
read `Start Empire Earth.command` and `set_zoom.sh` before you run them.

**Nobody has run this update on a Mac yet.** It was written and played on one
Linux machine, and the Mac launcher was only dry-run there with stand-ins for
the Mac tools. Expect to adapt, go one step at a time, and say where it
behaved differently. If a step fails, stop and report; do not work around it.

## What changes

- The launcher sets the match resolution to the screen's size at every start,
  so a match fills the screen after a monitor is plugged in or unplugged.
- The launcher then runs `set_zoom.sh`, which sets how far the camera can zoom
  out to suit that width. It does this by changing 20 bytes in
  `Empire Earth.exe` to one of five fixed levels (stock, 25, 30, 35, 40).
  `READ-ME-FIRST.md`, section "Screen fit and zoom", has the table.
- Nothing is reinstalled. Saved games are not touched.

## Steps

### 0. Check first

- `~/Applications/Empire Earth NeoEE.app` exists. If the app is somewhere
  else, use that folder wherever these steps say `~/Applications`, and add
  `--app "/full/path/Empire Earth NeoEE.app"` to the `set_zoom.sh` commands.
- The game is not running. Ask me to quit it if it is.
- If this folder is in iCloud Drive, make sure `Start Empire Earth.command`
  and `set_zoom.sh` are fully downloaded, not placeholders.
- Record the Mac model, `sw_vers`, and the size of each screen I use.

### 1. Record the starting state

From this folder:

```sh
bash set_zoom.sh status
```

It should print `Zoom level stock`. If it prints `unknown`, stop and report:
the game file is not the tested one and this update must not touch it.

### 2. Keep the old launcher

```sh
cp -p "$HOME/Applications/Start Empire Earth.command" "$HOME/Applications/Start Empire Earth.command.before-nov25"
```

### 3. Put the new files next to the app

```sh
cp "Start Empire Earth.command" set_zoom.sh "$HOME/Applications/"
chmod +x "$HOME/Applications/Start Empire Earth.command"
xattr -d com.apple.quarantine "$HOME/Applications/Start Empire Earth.command" "$HOME/Applications/set_zoom.sh" 2>/dev/null
```

Both files must sit in the same folder as the app. Without `set_zoom.sh`
beside it, the launcher still starts the game and leaves the zoom alone.

### 4. Start the game the usual way

```sh
open "$HOME/Applications/Start Empire Earth.command"
```

or have me double-click it. Do not run it with `bash` from your own shell. The
Terminal window prints two new lines before the game appears, for example:

```
Match resolution: 3440x1440 (was 1710x1107)
Zoom level 40 (zoom-out limit 40, draw distance 68).
```

Have me read both lines to you, or read them from the newest
`~/Library/Logs/EmpireEarthFamily/session-*.log` (lines `match_resolution=`
and `zoom:`). If macOS asks whether Terminal may change or manage apps, that
is this step writing inside the app; I decide.

### 5. Check the result

```sh
bash "$HOME/Applications/set_zoom.sh" status
cd "$HOME/Applications/Empire Earth NeoEE.app/Contents/SharedSupport/prefix/drive_c/NeoEE/Empire Earth" && shasum -a 256 "Empire Earth.exe" neoee.dll DDraw.dll "Low-Level Engine.dll" "TCP Protocol.dll"
```

The level must match what the launcher printed. The `Empire Earth.exe` line
must be the value listed for that level in `READ-ME-FIRST.md`, and the other
four lines must be unchanged from the fingerprint there.

### 6. I look at a match

Ask me to start a single player game against the computer and tell you:

- Does the match fill the screen?
- Does the mouse wheel zoom out further than before, and is the size of
  things comfortable?
- Any blue fog across the top of the screen, stutter, freeze or crash?

Then, when another family member is free, one short LAN match. Computers on
different zoom levels playing together has not been tried yet, so say exactly
what happened: joined or not, and whether the match stayed in sync.

## If something is wrong

Quit the game first. Each of these is remembered until changed back.

- Things too small or too big: `bash set_zoom.sh 30` (or `stock`, `25`, `35`,
  `40`). `bash set_zoom.sh auto` hands the choice back to the launcher.
- Match cut off, in a corner, or on the wrong screen:
  `bash set_resolution.sh --resolution WIDTHxHEIGHT` with the size of the
  screen the game is on, or `1280x960` for the windowed size used before.
  `bash set_resolution.sh` with no arguments hands the choice back.
- Back to exactly how it was: `bash set_zoom.sh stock`, then copy
  `Start Empire Earth.command.before-nov25` back over
  `Start Empire Earth.command`.

## Things that may differ on a Mac

- With two screens, the launcher reads the screen macOS reports as the main
  one. If the game opens on the other, fix the size by hand as above and
  report it.
- Full screen has only been seen on one Mac screen size (1710x1107). Other
  sizes, including large external monitors, are untested on a Mac.
- `set_zoom.sh` refuses to change a file it does not recognise and says so.
  Do not edit the game file any other way.

## Limits

- Do not change security, firewall or router settings. If you think one is in
  the way, tell me which and why, and let me decide.
- Do not stop Wine processes broadly.
- Do not send messages to anyone on my behalf.

## Report back

A short summary I can forward:

- Mac model and macOS version, and the size of each screen
- the `Match resolution` and `Zoom level` lines the launcher printed
- what `set_zoom.sh status` says, and whether the other four fingerprint
  lines still match
- what I saw in the match (fills the screen, zoom, any fog or stutter)
- the result of a LAN match, and the other player's zoom level, if we played
- anything that behaved differently from this brief
