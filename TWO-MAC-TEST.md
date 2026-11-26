# Two-Mac test (about 20 minutes, both Macs on the same Wi-Fi)

Do this once before game night. Write down what happens at each step; the
exact step where it stops is what matters.

1. Both Macs: start the game with `Start Empire Earth.command`.
2. Both: Multiplayer, Other Multiplayer. On the **Options** tab, read
   "Local Address" under Advanced Network Options and write it down. It should
   be the Mac's Wi-Fi address. If not: Choose Network Adapter, pick the row
   with the Wi-Fi address.
3. Mac A: LAN tab, Host Game, name it `FamilyTest`, Create Game. Untick
   "Use Custom Civs".
4. Mac B: LAN tab. **Does FamilyTest appear within 30 seconds?** (Refresh List.)
5. Mac B: if it appears, Join Game. If not, Direct Connect tab, enter Mac A's
   Local Address. **Does Mac B appear in the room on Mac A?**
6. Mac A: Start Game. On both Macs the window may drop into the Dock; click
   it at the right end of the Dock. **Does the map appear on both?**
7. Play five minutes. Move units on both Macs. Chat (Enter).
8. Mac A: save the game from the in-game menu. Both quit to the lobby.
9. Swap roles and repeat 3 to 7 with Mac B hosting.

Report one of: room never listed / listed but join fails / direct connect
fails / joins but match does not load / match runs then drops or goes out of
sync / all good. Keep the files in `~/Library/Logs/EmpireEarthFamily/` from
both Macs.

If step 4 and 5 both fail, run the network check with the game closed:
Mac A `python3 lan_probe.py listen`, Mac B `python3 lan_probe.py send --to <A's address>`.
(Needs Python 3; macOS offers to install it the first time.)
