I want to set up the game Empire Earth (NeoEE community edition) on this Linux machine so I can join LAN matches with family members who are on Macs on the same Wi-Fi. I own Empire Earth Gold Edition on GOG.

This exact setup works on two Apple-silicon Macs under Wine 11.0. It has NEVER been tried on Linux. Treat the steps below as a tested Mac recipe translated to Linux, not as a known-good Linux recipe. Run one step at a time, show me what happened, and tell me where it diverges instead of pushing through. You may install the packages named in step 1 and create the Wine prefix in step 2. Ask me before anything else that needs sudo, and do not change firewall settings yourself.

Update, Nov 25, 2026: this has now been done once, on an Omarchy laptop with Wine 11.20. It worked. Read "What happened on the first Linux machine" at the end before you start; the steps below are unchanged.

## 0. Check the machine
- `uname -m` must print `x86_64`. If it does not, stop and tell me.
- Tell me the distro (it should be Omarchy, which is Arch-based), the desktop session (`echo $XDG_SESSION_TYPE`), and the monitor resolution and scaling.

## 1. Packages
Find out which packages provide `wine`, `winetricks` and `cabextract` on this machine and install them. Report `wine --version`. Only Wine 11.0 has been tested with this game; if this is a different version, continue but tell me.

## 2. A dedicated Wine prefix
Use a prefix only for this game, for example `~/.local/share/empire-earth-neoee/prefix`, and export `WINEPREFIX` to it for every command below. Do not use `~/.wine`. Run `wineboot -u` once.

## 3. Match what the working Mac prefix has
The Mac prefix was built by Porting Kit and then extended. It contains, and this one should too:
- `winetricks -q renderer=gl vcrun6 cnc_ddraw`
- `winetricks -q directmusic` (downloads Microsoft's DirectX redistributable)
- DLL overrides in `HKCU\Software\Wine\DllOverrides`: `*ddraw` = `native,builtin` and `*dsound` = `native,builtin`, plus the DirectMusic ones that the winetricks verb sets (`dmime`, `dmusic`, `dmsynth`, `dmloader`, `dmband`, `dmcompos`, `dmstyle`, `dmscript`, `dswave`, `streamci` as `native`). Check they are there afterwards.
- `HKCU\Software\Wine\AppDefaults\Empire Earth.exe`, value `Version` = `winxp`

One caveat: on the Macs, NeoEE was always installed into a prefix that already held Porting Kit's GOG install of the game. Installing NeoEE into a prefix without that has never been done. NeoEE is a complete separate copy of the game, so it should not matter, but if the game will not start, suspect this first and tell me.

## 4. Get the NeoEE installer
Download `NeoEE_Setup.exe` in a normal web browser from https://empireearth.eu/download/neo/ (direct command-line downloads have been refused with 403). It must be 645,063,720 bytes with SHA-1 `069779b87a52aba05f2298da3a167399143bb302` (`sha1sum`). Do not use it if either differs.

## 5. Install NeoEE silently
```
wine /path/to/NeoEE_Setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- '/DIR=C:\NeoEE' '/COMPONENTS=game,language\en,additional\directx_wrapper\dx9' /TASKS=neoee_cdkeys '/LOG=C:\neoee-install.log'
```
Then `wineserver -w`. It takes a few minutes. Afterwards `drive_c/NeoEE/Empire Earth/Empire Earth.exe` must exist, and `drive_c/NeoEE/Empire Earth/NeoEE.cfg` must have the line `ShowGui:` set to `false` (the installer does that when it detects Wine; if it says `true`, change it to `false`).

## 6. Game settings
In `HKCU\Software\Neo\Empire Earth` set: `Game Window Width` = 1280 and `Game Window Height` = 960 (REG_DWORD), `Game Bit Depth` = 32, `Texture Bit Depth` = 32, `Rasterizer Name` = `Direct3D` (REG_SZ), and `Player Name` = the name I give you. Start with 1280x960. The Macs run full screen by setting width and height to the screen size, but that result may not carry over to Linux; try it only after 1280x960 works.

## 7. Fingerprint
These five files in `drive_c/NeoEE/Empire Earth/` must have exactly these SHA-256 hashes, or multiplayer will go out of sync with the Macs:
```
e352d7ae5ebc91f8d2f9c4363e41e990d7be8b063b1ee9e686a0d2a5f9bea2b5  Empire Earth.exe
2b2d4214f2e48a767d06476342b767e158a06b81f9d00dd6fd1d95b972e2c75c  neoee.dll
84bc3c26bacd526150bdfca32fc30db6247207bbf69f8a7b90d6b55025bf5e01  DDraw.dll
0350ef776b68d3a6ac84d8addf05e710907bea911aa15b23b8dffdbf68e8b05b  Low-Level Engine.dll
114dc91cdedfd45055509e2de618410c5b4abc3a70ebf4d65a96d748c934ceb2  TCP Protocol.dll
```

## 8. Start the game
From inside `drive_c/NeoEE/Empire Earth/`, run `wine "Empire Earth.exe"`. Keep the terminal output. I should see the Empire Earth main menu with "NeoEE Edition" in the corner; menus are always 1024x768. If the window, the pointer or focus misbehaves, try a Wine virtual desktop instead: `wine explorer /desktop=EmpireEarth,1280x960 "Empire Earth.exe"`. On the Macs the game draws its own gold pointer that is faster than the system pointer, and it minimizes itself when it loses focus; similar behaviour here would not be surprising.

## 9. Network, before trying to join
- The game uses UDP 8585 (LAN room discovery broadcasts), UDP 33334 and 33336, and TCP 33335 and 33336.
- Check whether this machine filters inbound traffic (for example `ufw status`, nftables or firewalld) and tell me what you find. A firewall that drops inbound UDP 8585 would make the room list stay empty. Do not open ports yourself; tell me the exact commands and let me decide.
- In the game: Multiplayer, Other Multiplayer, Options tab. "Local Address" should be this machine's LAN address. If not, use Choose Network Adapter and pick the row with that address. VPNs off.

## 10. First test: join only
A Mac hosts (LAN tab, Host Game). On this machine, LAN tab: does the room appear within 30 seconds? If yes, Join Game. If not, try the Direct Connect tab with the Mac's Local Address. Do not host from this machine until it has joined a Mac's game successfully.

## Report back
Give me a short summary I can forward: distro, session type, Wine version; which step, if any, diverged and the exact error text; whether the fingerprint matched; what I saw when the game started; what the firewall check showed; the Local Address the game shows; and whether the room appeared in the LAN list, joined by Direct Connect, or neither.

## What happened on the first Linux machine (Nov 25, 2026)

Omarchy 4.5.0 (Arch), Hyprland on Wayland with XWayland, Wine 11.20 from the Arch repositories. One machine, one day; treat it as one data point.

- Steps 0 to 8 worked as written, and all five fingerprints matched. Installing NeoEE into a prefix without the GOG game was fine.
- The installer set the match resolution to 1920x1080 by itself, and its log has one failed web request (`files.empireearth.eu/localized`). Neither mattered.
- The Wine virtual desktop in step 8 never opened a window on Wine 11.20. The plain `wine "Empire Earth.exe"` start is the one that works.
- **Firewall.** `ufw` was on and dropped inbound traffic, so the Mac's room never appeared in the LAN list. The kernel log showed the blocked packets (`journalctl -k | grep 'UFW BLOCK'`, UDP port 8585 from the Mac). After the owner ran these three commands (with the home network's own range), joining a Mac's room and hosting a room a Mac joined both worked:
  ```
  sudo ufw allow proto udp from 192.168.1.0/24 to any port 8585 comment 'Empire Earth LAN discovery'
  sudo ufw allow proto udp from 192.168.1.0/24 to any port 33334,33336 comment 'Empire Earth'
  sudo ufw allow proto tcp from 192.168.1.0/24 to any port 33335,33336 comment 'Empire Earth'
  ```
  These are for the owner to decide and run, as step 9 says.
- **Full screen.** A match fills the screen when the match resolution equals the monitor's size in the pixels X11 programs see (on Hyprland, real pixels when `xwayland:force_zero_scaling` is on). Seen at 1920x1200 and 3440x1440. A smaller match sits in the top-left corner.
- The game froze once on entering Multiplayer right after the match size was first set to 3440x1440. Not explained and not seen again.

## 11. Launcher, screen fit and zoom

`start-empire-earth.sh` in this folder is the launcher written for that machine. At every start it sets the match resolution to the focused monitor's size, runs `set_zoom.sh` to set the zoom level for that width (see "Screen fit and zoom" in `READ-ME-FIRST.md`), and then starts the game from the prefix in step 2. Keep `set_zoom.sh` next to it.

It reads the monitor size with `hyprctl` and switches to desktop 5 with an Omarchy command before starting. On another desktop environment, adapt those two parts: set `EMPIRE_EARTH_RES=WIDTHxHEIGHT` if it cannot read the monitor size, and `EMPIRE_EARTH_DESKTOP=` (empty) to stay on the current desktop. The comments at the top of the file list the options.

`bash set_zoom.sh status` works on Linux as on the Macs and finds the game in `~/.local/share/empire-earth-neoee/prefix`; use `--exe` for another location.
