# GM Genie Forever port notes

Community port of Chocochaos's GM Genie 0.7.3, licensed under GPL v3. Original
copyright and LICENSE are retained. Port version: **0.7.3-forever.9**.

## Target

- WoW Forever client 1.60.1, build 70338, interface 16001.
- Tested server: `advocaite/TrinityCore` Forever revision
  `9ed0d9eb5d442714177bebb58e6b2312add6ab46`.
- English server command responses. Other locales need parser changes.

Forever combines Classic content with newer UI APIs. The
[Questie Forever port discussion](https://github.com/Questie/Questie/pull/7848)
also describes its Retail project ID and mixed API environment. This addon uses
explicit compatibility adapters instead of selecting a branch from project ID.

## Online players

Open **Online players**, `/gmplayers [search]`, or `/gmgenie players [search]`.
Each row shows a character, their zone and compact **TP**, **SUM** and **Actions**
controls. Typing filters loaded player/zone names; **Enter** or **Refresh** queries
the server. Refresh is manual because Forever requires a hardware action for Who searches.

- **TP** uses `.appear PlayerName` to move you to that player.
- **SUM** uses `.summon PlayerName` to bring that player to you.
- **Actions > Kick** asks for a reason, then confirms `.kick PlayerName Reason`.
- **Actions > Ban character** asks for a reason and a positive duration such as
  `30m`, `1h` or `7d`, then confirms `.ban character PlayerName Duration Reason`.
  This form bans the selected character; it does not ban their whole account.
- **Actions > Kill** requires that exact player to be your current target.
  Confirmation rechecks their name and target GUID before sending `.die`.
  Forever's kill command has no player-name argument; target changes cancel execution.

Kick, Ban and Kill require a confirmation click. The action forms block
stale/changed roster entries and reject repeated submits.
TP/SUM/Kick/Ban name the row's character and do not change your selected target.
Full Forever names (first name plus surname) remain visible in rows and forms;
GM commands use the unique first name stored in `characters.name`. For example,
Ben Hacks sends `.appear Ben`, `.kick Ben Reason` or `.ban character Ben 1h Reason`.
Your own row and foreign-realm action targets are disabled. Server permissions
and instance restrictions remain authoritative; actions report requests, not success.

The roster uses `C_FriendList.SendWho`, `WHO_LIST_UPDATE` and `GetWhoInfo` to read
native player/zone data. It never sends `.account onlinelist`: that command can
be unavailable to in-game GMs even when it works from the server console.
No account names or IP addresses are queried or retained, and roster data is not
saved to addon variables. Other addon features still require English server messages.

Who visibility follows your server's faction and GM visibility permissions.
Forever normally returns at most 50 results and may report that truncated count
as its total. The addon warns at 50 results (or when total exceeds shown); narrow
the player/zone search and press Enter. It cannot promise an uncapped realm roster.
Who shares the native client result buffer with `/who` and other addons.

Pending searches and snapshots older than 45 seconds disable actions. Incomplete
searches time out after 10 seconds; use **Refresh** to retry. Searches never run
from a timer. No server permission or configuration changes are required by this fix.

## Content catalog

Version 0.7.3-forever.7 adds an offline Forever-only catalog with 22,659 items and
15,205 NPCs/monsters, search/filters/favorites, guarded model previews, explicit
self item delivery, temporary spawns and confirmed persistent spawns.
See [catalog documentation](docs/CATALOG.md) for source coverage, reference-core
availability and regeneration.

## Changes

- Modern backdrops, checkbox templates, scrolling editors, tooltip padding and
  Settings canvas categories. Fixed frame levels so window labels stay visible.
- Player context menus use `Menu.ModifyMenu`; GM Genie keeps its own dropdowns.
- Commands use a self-whisper, which the core consumes as a command. This works
  for unguilded GMs, where the client rejects the original guild-chat transport.
- Explicit command names replace old abbreviations. Startup queries wait until
  the character enters the world.
- Tickets support Forever's **bug**, **complaint** and **suggestion** report
  command trees. The native menu selects the report type directly. Synchronization includes
  report type because each type has its own IDs.
- Updated report and player-info parsing. Reports lack online status and last
  modification time: all reports are shown, and Modified displays a dash.
- System messages are read through an event listener. Creature/gameobject chat
  links use Blizzard's addon hyperlink callback. Blizzard's chat dispatch and
  SetItemRef functions are preserved.
- False saved settings remain false, and default tables are copied independently.
- `/gmgenie debug` records up to 100 GM Genie Lua errors without suppressing the
  normal error display. Diagnostics reset on reload.

## Commands

| Command | Action |
| --- | --- |
| `/gmgenie` | Toggle the HUD |
| `/gmgenie catalog [search]` / `/gmcatalog [search]` | Open the Forever content catalog |
| `/gmgenie players [search]` / `/gmplayers [search]` | Online roster with zones and TP/SUM |
| `/gmgenie options` | Open Settings |
| `/gmgenie status` | Query badge, visibility and whisper status |
| `/gmgenie debug` | Show initialization and Lua error count |
| `/tickets` | Toggle reports |
| `/tickets bug` / `/tickets complaint` / `/tickets suggestion` | Select report type and toggle the window |
| `/builder` | Toggle the builder |
| `/spy CharacterName` | Read player information |

GM mode follows server notifications and self inspection; Forever has no
read-only `.gm` query. Flight starts as unknown until its first command response.
Guild report synchronization requires both GMs to be guilded and use this port.

## Move an existing NPC

Open `/builder`, target the NPC, stand at its new position and face the desired
direction, then click **Move NPC here**. The command `.npc move` copies your
current position and orientation, saves the spawn permanently and respawns it.
The button rejects missing targets, players and pets. The core checks that the
NPC is a persistent spawn on the same map and that you have command permission.

The **Move self** and **Move self back** controls move your character using the
Builder offsets. **Move NPC here** uses your live position rather than those
offsets or cached coordinates.

## Bundled starter macros

The addon includes **28 editable starters**, available from the player context
menu under **GM Genie** and from Spy's macro dropdown. Open `/gmgenie options`
to edit them in Whisper, Mail, Teleport or Discipline Macros.

| Category | Included examples |
| --- | --- |
| Whispers (7) | First reply, request details, permission before teleport, stuck character, resolution, chat warning, custom topic prompt |
| Mail (4) | Offline follow-up, bug details, conduct reminder, two-part welcome |
| Teleport (10) | Recall, GM Island, Stormwind, Ironforge, Darnassus, Orgrimmar, Thunder Bluff, Undercity, Booty Bay, Ratchet |
| Mutes (3) | Spam 5 minutes, disruptive chat 15 minutes, harassment 60 minutes |
| Character bans (2) | Disruption 1 hour, exploit abuse 1 day |
| Account bans (1) | Cheating 1 day |
| IP bans (1) | Spam source 1 hour |

`NAME` inserts the recipient's name in whisper/mail bodies. `SUBJECT` in a
whisper opens a text prompt; the custom-topic example demonstrates this.
Each newline sends a separate message. The welcome mail demonstrates separate
numbered mails in order. Keep each message short enough for the command limit.

Teleport macros move the selected player; recall returns them to the position
saved before their GM teleport/summon. Destination names were verified on the test server; check your own
`game_tele` table before use. Choose a faction-appropriate destination when helping a player.

Discipline examples perform the named action when selected. Mutes use minutes;
ban durations use `s`, `m`, `h` or `d`. Examples use finite durations and GM-only
announcements. Edit durations/reasons for your moderation policy. IP bans affect
the address and can affect other players sharing it.

Fresh installs receive the pack automatically. Existing installs merge missing
names once using `starterMacrosVersion = 1`. Custom macros and same-name edits
are preserved; deleting or renaming an example stays effective after reload.
The shipped definitions live in `StarterMacros.lua`; personal edits stay in WTF.

## Install and rollback

Use the installable ZIP from [Releases](https://github.com/brandonjank/gmgenie-forever/releases).
Follow the [installation instructions](README.md#install). To roll back, close
the client and restore your backed-up `GMGenie` addon directory and, if needed,
its saved variables. Personal macros/settings are stored in the client's WTF
folder, outside the addon directory.

## Validation and limits

`python tests/test_gmgenie.py` checks 225 Lua/XML script chunks in Lua 5.1,
manifest resources, cold-start report-type switching, synthetic report/player-info
responses, saved settings, command routing, and hyperlink rewriting. Install
the dependency with `python -m pip install -r tests/requirements.txt`.

The suite also checks the actual NPC-move button callback, rejecting invalid
targets and sending the exact command through self-whisper, plus all 28 starter entries, new/existing-install migration,
preservation of edits/deletions, independent nested settings, generated commands,
message lengths, the custom-topic prompt with literal percent text, and selecting
whisper/mail examples through the modern editor callbacks. All network sends are
mocked; these checks do not send mail, move players or impose discipline.

Live checks covered login, HUD queries, Settings pages, report-list loading,
all three report types before the first Spy request, modern player submenus,
self inspection, creature lookup links and spawn listing. The final fresh-reload
check reported `initialized=true, errors=0` after cycling all report types.
The live report list was empty; populated report parsing was checked with
synthetic examples from the running core's public response templates.

The dashboard and command library were previously checked in an
active Forever GM session: search, favorites, recent history, keyboard
selection, category menus, source details, Builder, report shortcuts and
100/110% scaling rendered and responded correctly. The live check found
and fixed blank-button font-region initialization; no further Lua error
dialog appeared during these interactions. Saved layouts and target
guards are additionally covered by the Lua UI regression suite.

Destructive GM actions (bans, deletion, report closure), cross-GM sync, WIM and
legacy custom anticheat integrations were not exercised. Spawn, mail and
teleport commands retain their original behavior with updated transport/names;
they still depend on server permissions. This is a community compatibility port,
not certification of every original addon feature or future Forever build.

Version 0.7.3-forever.9 replaces the roster's account-command dependency after
live use exposed its missing in-game RBAC permission. Lua 5.1 checks cover native
Who results, response caps, timeouts, paging, confirmations, reason/duration
validation, stale entries and exact target GUID checks. Kick, Ban, Kill and
teleport/summon commands were tested with mocked sends, not on real players.

## References

- [Forever roster command source](https://github.com/advocaite/TrinityCore/blob/9ed0d9eb5d442714177bebb58e6b2312add6ab46/src/server/scripts/Commands/cs_account.cpp)
- [Blizzard Classic beta FriendList API](https://github.com/Gethe/wow-ui-source/blob/classic_beta/Interface/AddOns/Blizzard_APIDocumentationGenerated/FriendListDocumentation.lua)
- [Forever Who handler](https://github.com/advocaite/TrinityCore/blob/9ed0d9eb5d442714177bebb58e6b2312add6ab46/src/server/game/Handlers/MiscHandler.cpp)
- [Original GM Genie](https://github.com/chocochaos/GMGenie)
- [Blizzard backdrop implementation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Backdrop.lua)
- [Blizzard modern menu guide](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua)
- [Addon hyperlink callback example](https://github.com/NumyAddon/AddonProfiler/blob/master/AddonProfiler.lua)


## Exhaustive command reference

Click **Commands** on the HUD, or use `/gmgenie commands`.
`/gmgenie commands npc move` opens with a search already applied. Search matches
command names, handler arguments and RBAC permission names; all words must match.
The catalog is available offline and lists all 619 handler registrations in
Forever commit `9ed0d9eb5d442714177bebb58e6b2312add6ab46`, including `legacy`,
`discord` and `armory` commands outside the usual Commands folder. Disabled/commented
commands and server-local additions are excluded. Group headings are represented
by their executable children, including bare commands with default handlers.

Details preserve C++ argument definitions and show a parameter outline. These
outlines describe order and optional parameters, not every handler validation.
Legacy free-form parsers explicitly direct you to **Server help** instead of
guessing syntax. The source link opens the exact registration revision when
copied into a browser. The reference itself executes no actions; its help button
requests only `.help <command>` from your current server. In-game-only commands
are invisible to console help even when they exist. RBAC grants and enabled
modules vary between servers; catalog inclusion is not a grant of permission.

The upstream fork point is TrinityCore **master** commit
[`85d3c25180a89f889294d54d855efccae0945f20`](https://github.com/TrinityCore/TrinityCore/commit/85d3c25180a89f889294d54d855efccae0945f20),
dated September 25, 2026. Forever's first descendant added Classic 1.60.1.70009
client support. Older TrinityCore 3.3.5 command guides are not authoritative for
this core. The general [TrinityCore command reference](https://trinitycore.info/how-to/gm-commands)
is useful background; the pinned handlers are the authority for this snapshot.

To regenerate after a core update, check out the desired clean
`advocaite/TrinityCore` Forever revision, then run:

```sh
python tools/generate_commands.py --source-root /path/to/TrinityCore
python tests/test_commands.py
```

Review the generated `CommandData.lua` and `docs/commands.json` diff before
shipping. The generator rejects unparsed entries, unknown permissions,
missing handlers, duplicate paths and unreachable tables. The regression suite
checks real Lua search, selection, pagination, source links, help-only sends and
all literal addon command prefixes against the catalog. Update the pinned count
assertions deliberately when a newer core adds or removes commands.


## Modern interface

The dashboard provides command search, GM controls, report-type menus, macro
editor shortcuts and a target card. The card updates on target changes; player
inspection is enabled only for players, and target commands are enabled for
players/NPCs. Selecting or changing targets sends no commands. Status values
remain unknown until received from the server; controls do not guess that a
command succeeded. Speed input accepts a finite multiplier from 0.1 to 50.

The command library has **All commands**, **Favorites** and **Recent** views.
Use the native category/context menus to narrow results, or type search words.
Press Up/Down in the search field to select results; use the mouse wheel over
the list to change pages. Click **+** beside a row or **Save favorite** to save
a command locally. Recent keeps up to 20 unique commands selected or queried
for help. Filtering and browsing do not pollute the recent list.

Command details show the parameter outline; **Source details** opens the exact
C++ arguments, permission name and pinned source link in a separate window.
**Server help** requests usage in chat. It does not execute the selected action.

Drag a window to reposition it. Its position is restored after reload. Open
**Settings** on the dashboard for interface scale (90%, 100%, 110%, 125%),
macro editors or resetting window positions. These preferences, favorites and
recent history are saved in GMGenie's existing SavedVariables and preserved
when upgrading the addon.

The UI uses BackdropTemplate and native MenuUtil descriptions, following the
[Blizzard menu implementation guide](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua).
Legacy tool layouts retain their existing workflows under the shared theme.
Run `python tests/test_ui.py` for dashboard/menu/target/layout checks.
