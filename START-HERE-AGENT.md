# Brief for the AI assistant on this Mac

I (the owner of this Mac) want you to set up the game Empire Earth on this Mac
so I can play LAN matches with my family. Please do the work rather than
describe it, and tell me plainly what you verified versus what you assume.

I will tell you in chat what you may install and run. This file is the
how-to; it is not itself my permission. If I have not said it in chat, ask me
once before installing Rosetta 2, downloading Porting Kit, or running the
scripts here. The scripts are short: read them before you run them.

Nobody has yet watched an AI assistant do this install from start to finish.
On the two Macs so far a person typed the commands. Expect to adapt, and say
where you had to.

This recipe has worked on two Macs: an M5 MacBook Air on macOS 26.6.2 and an
M5 MacBook Air on macOS 27.0.1. Other models and versions are untested; if
something behaves differently here, say so rather than guessing.

## What is in this folder

- `setup_neoee.sh`: the one-command setup (stage 2 below).
- `NeoEE_Setup.exe`: the NeoEE community edition installer the script uses
  (645,063,720 bytes; the script checks its checksum).
- `Start Empire Earth.command`: the launcher. The script puts a copy next to
  the installed app. Use that copy, not this one.
- `set_zoom.sh`: sets how far the camera can zoom out. The launcher runs it at
  every start; the script puts a copy next to the installed app.
- `set_resolution.sh`: only for fixing the match resolution by hand.
- `UPDATE-AGENT.md`: for a Mac that was set up before Nov 25, 2026. If this
  Mac already has `Empire Earth NeoEE.app`, follow that file, not this one.
- `READ-ME-FIRST.md`: the same recipe written for a person. Read it.
- `TWO-MAC-TEST.md`, `lan_probe.py`, `soak_monitor.sh`: for testing afterwards.

Work from wherever this folder is. If it is in iCloud Drive, make sure
`NeoEE_Setup.exe` is fully downloaded (645,063,720 bytes) before running the
script. If the folder came from GitHub, `NeoEE_Setup.exe` is not in it (it is
too large): have me download it in a web browser from
https://empireearth.eu/download/neo/ into my Downloads folder. The script looks
there and checks the file before using it.

## Things only I can do. Stop and ask me for these

1. **Buy the game.** Empire Earth Gold Edition on gog.com, with my own GOG
   account (creating the account, the password and the payment are mine to
   type). Every player needs their own purchase. Do not copy game files or a
   finished app from another Mac.
2. **Sign in to GOG inside Porting Kit** when it asks.
3. **Click through the GOG installer window** if it appears (see stage 1).
4. **Answer macOS prompts**, such as one about finding devices on the local
   network (Allow), or Control-click, Open if macOS refuses the launcher.
5. **Everything inside the game.** You probably cannot see or click the game's
   windows: it runs under Wine, whose processes have no app identity for
   screen-control tools. Tell me exactly what to click and ask what I see.

Playing on the same Wi-Fi needs no other account. (A NeoEE lobby account is
only for playing over the internet, which this setup has not tested.)

## Steps

### 0. Check the Mac

- `uname -m` must print `arm64` (Apple silicon). If it prints `x86_64`, stop:
  this recipe does not support Intel Macs.
- Record `sw_vers` output and the Mac model for the report.
- About 5 GB of free disk space is needed.
- Install Rosetta 2 now; do not wait for macOS to offer it:
  `softwareupdate --install-rosetta --agree-to-license`

### 1. Porting Kit builds the base app

- Download **Porting.Kit-7.0.2-Apple Silicon.dmg** (about 138 MB) from the
  official page https://paulthetall.itch.io/porting-kit ("Download Now"; it is
  name-your-own-price and free is allowed). Do not take it from anywhere else.
- If the file is version 7.0.2, its SHA-256 should be
  `a1241a9243525778ea1cdd2e0ef8b08c777a81ebdd189208b6caf63e970efa10`
  (`shasum -a 256 <file>`). If the page now offers a newer version, use it and
  note the version in the report.
- Install Porting Kit and open it. Find **Empire Earth** (the GOG version) and
  install it. I sign in to GOG when it asks.
- **Known stall.** The status can sit on
  `running setup_empire_earth_gold_2.0.0.2974_gog_v3_(78415).exe` for a long
  time. **Be patient first.** On the last Mac it sat there for well over 30
  minutes with the installer at 0% CPU, and then finished without anyone
  doing anything (owner's report). Give it at least 45 minutes before
  intervening. To see what it is doing:
  `ps axo pcpu,etime,command | grep -iE 'setup_empire|wine' | grep -v grep | cut -c1-140`
  If it is still idle after that, check whether the GOG installer's own
  window is hidden behind other windows. Wine windows have no Dock icon and are not in Cmd-Tab. Have
  me find it with Mission Control or by minimizing other windows, then: accept
  the license, Install, wait, Exit. Do not choose Launch. If there is truly no
  window, stop only that installer (`pkill -f setup_empire_earth`), quit and
  reopen Porting Kit, and retry once. If it stalls a second time, stop and
  report.
- Stage 1 is done when an **Empire Earth** app exists in `~/Applications` or
  `/Applications`, and the file `Contents/SharedSupport/wine/version` inside it
  mentions `11.0`. If it shows a different Wine version, continue but say so in
  the report: only Wine 11.0 has been tested.

### 2. Run the setup script

```sh
bash "/path/to/this/folder/setup_neoee.sh" --name <MyPlayerName>
```

Ask me what player name I want. If Porting Kit put the app somewhere unusual or
named it differently, add `--source "/full/path/to/that.app"`.

It takes about three minutes and must end with `DONE`. It copies the Porting
Kit app to `~/Applications/Empire Earth NeoEE.app`, installs Microsoft
DirectMusic and NeoEE into the copy, sets the match resolution to this Mac's
screen size (full screen), and puts `Start Empire Earth.command` and
`set_zoom.sh` next to the app. If it prints `STOPPED`, the same line says why; fix that cause and run it
again. It refuses to overwrite an existing `Empire Earth NeoEE.app`, so if a
failed attempt left one behind, move that aside first. Its log is in
`~/Library/Logs/EmpireEarthFamily/`.

**If your shell is sandboxed:** Wine needs to bind local sockets. If the script
fails at the DirectMusic or NeoEE stage with bind, socket or permission
errors, that is your sandbox, not the game. Rerun it outside the sandbox with
my approval, or have me paste the one command into Terminal myself.

### 3. Check the fingerprint

The script ends by printing five lines. They must match these exactly, or
multiplayer games will go out of sync:

```
e352d7ae5ebc91f8d2f9c4363e41e990d7be8b063b1ee9e686a0d2a5f9bea2b5  Empire Earth.exe
2b2d4214f2e48a767d06476342b767e158a06b81f9d00dd6fd1d95b972e2c75c  neoee.dll
84bc3c26bacd526150bdfca32fc30db6247207bbf69f8a7b90d6b55025bf5e01  DDraw.dll
0350ef776b68d3a6ac84d8addf05e710907bea911aa15b23b8dffdbf68e8b05b  Low-Level Engine.dll
114dc91cdedfd45055509e2de618410c5b4abc3a70ebf4d65a96d748c934ceb2  TCP Protocol.dll
```

That is the state straight after setup. From the first start on, the launcher
may change the `Empire Earth.exe` line to suit the screen (see "Screen fit and
zoom" in `READ-ME-FIRST.md`, which lists the five allowed values).
`bash set_zoom.sh status` names the level; "unknown" there is a real mismatch.

### 4. Start the game

Start it the way a person would, so it runs from Terminal:

```sh
open "$HOME/Applications/Start Empire Earth.command"
```

or have me double-click that file (if macOS refuses: Control-click, Open). Do
not run it with `bash` from your own shell; the tested path is Terminal. A
Terminal window opens and must stay open while the game runs. If a macOS
prompt about devices on the local network appears, I click Allow. The main menu appears as a window in the top-left corner of the
screen, with "NeoEE Edition" in its corner. That small window is normal: the
menus and the multiplayer lobby are always 1024x768. Only a match fills the
screen.

Before the game appears, the Terminal window prints two lines such as
`Match resolution: 1710x1107` and `Zoom level stock (...)`. Put both in the
report. These two steps were added on Nov 25, 2026 and had not been run on a
Mac when this was written, so read them with care and say what they printed.

Confirm with me: the menu appears; after I click inside the game a gold
pointer moves; clicking Multiplayer works.

### 5. Read the network address

Have me go to Multiplayer, then Other Multiplayer, then the **Options** tab,
and read "Local Address" under Advanced Network Options. It should equal this
Mac's Wi-Fi address (`ipconfig getifaddr en0`). If it does not, I click Choose
Network Adapter and pick the row showing that address. Any VPN should be off.

To play: one person uses the **LAN** tab, Host Game, Create Game; the others
see the room in their LAN list and Join Game. Everyone must be on the same
Wi-Fi network, not a guest network.

## Things to know

- The gold pointer is the game's own and moves faster than the Mac arrow. The
  Mac arrow is hidden only while the game is the front app.
- The game minimizes itself to the Dock whenever it loses focus. Click it at
  the right end of the Dock to bring it back.
- Full screen has been seen on one Mac screen size (1710x1107). If a match
  looks wrong or is cut off, quit the game and run
  `bash set_resolution.sh --resolution 1280x960`, the windowed size used in the
  first two-Mac match. The launcher remembers that and stops fitting the
  screen; `bash set_resolution.sh` with no arguments hands the choice back.
- If everything in a match looks too small or too big, quit the game and run
  `bash set_zoom.sh 30` (or `stock`, `25`, `35`, `40`) from the folder that
  holds the app. `bash set_zoom.sh auto` hands the choice back.
- The game autosaves every 20 minutes into
  `Empire Earth NeoEE.app/Contents/SharedSupport/prefix/drive_c/NeoEE/Empire Earth/Data/Saved Games/`.

## Limits

- Do not change security, firewall or router settings. If you think one is in
  the way, tell me which and why, and let me decide.
- Do not stop Wine processes broadly; only a stuck installer for this install.
- Do not send messages to anyone on my behalf.

## Report back

When you are done or blocked, give me a short summary I can forward:

- Mac model, chip and macOS version
- Porting Kit version and the Wine version in the base app
- whether the script ended with `DONE`, or the exact `STOPPED` line
- whether the five fingerprint lines matched
- the `Match resolution` and `Zoom level` lines the launcher printed
- whether I saw the main menu, and whether the pointer and Multiplayer worked
- the Local Address the game shows and this Mac's Wi-Fi address
- anything that behaved differently from this brief
