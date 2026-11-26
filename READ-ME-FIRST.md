# Family install recipe

Status (Nov 9, 2026): the setup script below rebuilt the working configuration
on the first Mac from a plain Porting Kit install, and the result matched the
tested game files byte for byte (441 files). A LAN room was hosted and a match
started and rendered on that Mac. That evening two Macs (macOS 26.6.2 and
27.0.1), both built with this recipe, joined and played a short match on the
same Wi-Fi. See `docs/lan-test.md` for what is still untested.

Each person uses their own GOG purchase. Do not copy someone else's installed
game.

Tested on: Apple M5 MacBook Air, macOS 26.6.2 (25G83). Write down your Mac
model and macOS version when you install.

## You need (about 5 GB free)

1. Your own GOG purchase of **Empire Earth Gold Edition**.
2. **Porting Kit 7.0.2** for Apple silicon: paulthetall.itch.io/porting-kit
3. **NeoEE_Setup.exe** (645,063,720 bytes), downloaded in a browser from
   https://empireearth.eu/download/neo/ into your Downloads folder.
4. Three files from this project: `setup_neoee.sh`,
   `Start Empire Earth.command` and `set_zoom.sh`. Keep them together in one
   folder.

## Steps (about 15 minutes plus downloads)

1. **Porting Kit: install "Empire Earth" (the GOG port).** This step can sit
   on "running setup_empire_earth_gold..." for 30 minutes or more and look
   stuck; on the second Mac it finished without help. Wait. Sign in to GOG when
   it asks, or give it your downloaded installer
   `setup_empire_earth_gold_2.0.0.2974_gog_v3_(78415).exe`. It builds an app
   called **Empire Earth** using Wine 11.0 (DXMT). If macOS offers to install
   Rosetta, accept. You do not need to start the game.
2. **Run the setup script.** Open Terminal, type `bash ` (with the space), drag
   `setup_neoee.sh` into the window, add your player name, and press Return:
   ```sh
   bash /path/to/setup_neoee.sh --name YourName
   ```
   It checks the NeoEE download, copies the Porting Kit app to
   `~/Applications/Empire Earth NeoEE.app`, installs Microsoft DirectMusic and
   NeoEE, applies the tested settings, and puts **Start Empire Earth.command**
   and `set_zoom.sh` next to the app. It takes about three minutes and ends
   with `DONE` and a five-line fingerprint.
3. **Compare the fingerprint** with the list at the bottom of this page. If any
   line differs, stop: mismatched game files cause out-of-sync games.
4. **Start the game** by double-clicking `Start Empire Earth.command` (first
   time: Control-click it, choose Open). A Terminal window opens and must stay
   open while you play; the game appears at the top-left of the screen.

If the script stops, it says why in plain words. The usual causes: Rosetta not
installed, NeoEE_Setup.exe not in Downloads, or Porting Kit's Empire Earth app
not found (pass `--source "/path/to/Empire Earth.app"`).

## Playing on the same Wi-Fi

- Everyone on the same Wi-Fi network, not a guest network. VPNs off.
- Everyone: Multiplayer, then Other Multiplayer, then the LAN tab.
- Host: Host Game, type a name, Create Game. Others should see it in the list
  and Join Game. If it is not listed, use the Direct Connect tab with the
  host's address.
- The host's address is on the lobby's **Options** tab under Advanced Network
  Options, "Local Address". It should look like the Mac's Wi-Fi address
  (192.168.x.x or 10.x.x.x). If it does not, click Choose Network Adapter and
  pick the row with the Wi-Fi address.
- If the game window ever drops into the Dock (it does this when it loses
  focus), click it at the right end of the Dock to bring it back.
- Untick "Use Custom Civs" for the first game unless you want the civilization
  builder.

## Screen fit and zoom (changed Nov 25, 2026)

The launcher now does two things by itself every time you start the game, so
it keeps working when you plug in or unplug a monitor:

1. **Fits the match to the screen.** Matches run full screen when the game's
   resolution equals the screen's own size, so the launcher sets it to that.
   The main menu and the multiplayer lobby are always a 1024x768 window in the
   top-left corner; only the match itself fills the screen.
2. **Sets the zoom level for that width.** The game shows the same
   left-to-right slice of the map on every screen, so on a big or very wide
   monitor everything looks zoomed in. `set_zoom.sh` raises the limit on how
   far the camera can pull back. In a match, scroll the mouse wheel to zoom.

| Match width (pixels) | Zoom level | Zoom-out limit | Draw distance |
|---|---|---|---|
| up to about 1950 (laptops) | stock | 20.5 | 35 |
| about 2050 to 2350 | 25 | 25 | 43 |
| about 2400 to 2750 (2560x1440) | 30 | 30 | 51 |
| about 2800 to 3200 | 35 | 35 | 60 |
| 3250 and wider (3440x1440) | 40 | 40 | 68 |

The launcher prints both choices when it starts, for example
`Match resolution: 3440x1440` and `Zoom level 40 (...)`.

To choose for yourself, quit the game and run one of these. The choice is
remembered and the launcher stops choosing for you:

```sh
bash set_zoom.sh 30                           # stock, 25, 30, 35 or 40
bash set_zoom.sh auto                         # back to automatic
bash set_resolution.sh --resolution 1280x960  # a fixed match size
bash set_resolution.sh                        # back to automatic
```

`bash set_zoom.sh stock` puts the original game file back, byte for byte.

The zoom level is stored inside `Empire Earth.exe`, so that one file is no
longer the same on every computer: see the fingerprint section below.

**What has and has not been tried (Nov 25, 2026):**

- Level 40 at 3440x1440 was played against the computer on one Linux machine
  and looked right. A limit of 30.5 was also tried there and was not far
  enough for that monitor.
- Levels 25, 30 and 35 have not been played. Their files were only checked
  against the fingerprints below.
- The new launcher steps have not been run on a Mac yet. They were only
  dry-run on Linux with stand-ins for the Mac tools.
- A multiplayer match between computers on different zoom levels has not been
  tried. The change only affects what your own camera shows, so it should not
  matter, but nobody has seen it work. If a match misbehaves, everyone runs
  `bash set_zoom.sh stock` and tries again before suspecting anything else.
- On the Linux machine the game froze once on entering Multiplayer right
  after the match size was first set to 3440x1440. It has not been explained
  or seen again.

## Known rough edges

- The game minimizes itself to the Dock whenever it loses focus (clicking
  another app, a notification stealing focus). Click it in the Dock to return.
  At a windowed resolution it also did this at every multiplayer match start;
  at full-screen resolution it did not (one test).
- The gold pointer is the game's own and is faster than the Mac arrow. Click
  inside the game first; the Mac arrow is hidden and kept inside the game while
  the game has focus.
- Saves and autosaves (every 20 minutes) are inside the app:
  `Empire Earth NeoEE.app/Contents/SharedSupport/prefix/drive_c/NeoEE/Empire Earth/Data/Saved Games/`.
  Deleting the app deletes them.
- The launcher writes one line a minute to
  `~/Library/Logs/EmpireEarthFamily/session-*.log`. If a game freezes, keep
  that file: it shows whether the game or the whole Mac stalled.

## Open questions this recipe does not settle yet

- Whether two Macs see and join each other (the historical failure).
- Whether the Dock-minimize at match start also happens with hand clicks.
- Long-session stability with several human players.
- Full-screen resolution has been seen on one Mac (1710x1107) against the
  computer; not yet in a two-Mac match or on other Mac screen sizes.
- Whether the new screen fit and zoom steps work on a Mac, and whether
  computers on different zoom levels can play together (see "Screen fit and
  zoom").

## Fingerprint of the tested build (NeoEE 2.0.0.5, game 2.00.3750)

```
e352d7ae5ebc91f8d2f9c4363e41e990d7be8b063b1ee9e686a0d2a5f9bea2b5  Empire Earth.exe
2b2d4214f2e48a767d06476342b767e158a06b81f9d00dd6fd1d95b972e2c75c  neoee.dll
84bc3c26bacd526150bdfca32fc30db6247207bbf69f8a7b90d6b55025bf5e01  DDraw.dll
0350ef776b68d3a6ac84d8addf05e710907bea911aa15b23b8dffdbf68e8b05b  Low-Level Engine.dll
114dc91cdedfd45055509e2de618410c5b4abc3a70ebf4d65a96d748c934ceb2  TCP Protocol.dll
```

The setup script prints exactly these five lines. After the first start, the
`Empire Earth.exe` line depends on the zoom level and must be one of the five
below; `bash set_zoom.sh status` says which. The other four files never change.

```
stock  e352d7ae5ebc91f8d2f9c4363e41e990d7be8b063b1ee9e686a0d2a5f9bea2b5
25     62fc282b7417dab89e32373e7b99bf61b218a4669964c5e5d0f8818946801412
30     69514c243baa16637c1db9f219b30ca7ad30af8bf3bcecfc96646aeb3fc61085
35     9083ee56dd8b55a2d1bfb9d24cc459ea1583432ad407b25a786cba9bfc204ce2
40     d4ca2f1df6fe66bba1ef20c07f2817af1af39895c8a13f673c596f18b773b27b
```

## What the script does (for the curious)

Copies the Porting Kit wrapper (APFS clone); runs the wrapper's own
`winetricks -q directmusic`; runs `NeoEE_Setup.exe /VERYSILENT` with
components `game,language\en,additional\directx_wrapper\dx9` into `C:\NeoEE`;
checks `NeoEE.cfg` has `ShowGui: false`; sets resolution, 32-bit colour and the
"Direct3D" rasterizer under `HKCU\Software\Neo\Empire Earth`; sets the Wine
virtual desktop; points the wrapper at the NeoEE executable. Porting Kit's
terms make its wrappers personal-use, which is why each person builds their
own instead of receiving a copy.
