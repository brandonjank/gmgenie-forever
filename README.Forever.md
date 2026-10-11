# GM Genie Forever port notes

Community port of Chocochaos's GM Genie 0.7.3, licensed under GPL v3. Original
copyright and LICENSE are retained. Port version: **0.7.3-forever.4**.

## Target

- WoW Forever client 1.60.1, build 70338, interface 16001.
- Tested server: `advocaite/TrinityCore` Forever revision
  `f8712a6ad24ba8d921f9be8bf74502888d463723`.
- English server command responses. Other locales need parser changes.

Forever combines Classic content with newer UI APIs. The
[Questie Forever port discussion](https://github.com/Questie/Questie/pull/7848)
also describes its Retail project ID and mixed API environment. This addon uses
explicit compatibility adapters instead of selecting a branch from project ID.

## Changes

- Modern backdrops, checkbox templates, scrolling editors, tooltip padding and
  Settings canvas categories. Fixed frame levels so window labels stay visible.
- Player context menus use `Menu.ModifyMenu`; GM Genie keeps its own dropdowns.
- Commands use a self-whisper, which the core consumes as a command. This works
  for unguilded GMs, where the client rejects the original guild-chat transport.
- Explicit command names replace old abbreviations. Startup queries wait until
  the character enters the world.
- Tickets support Forever's **bug**, **complaint** and **suggestion** report
  command trees. The selector cycles between them. Synchronization includes
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

`python tests/test_gmgenie.py` checks 229 Lua/XML script chunks in Lua 5.1,
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

Destructive GM actions (bans, deletion, report closure), cross-GM sync, WIM and
legacy custom anticheat integrations were not exercised. Spawn, mail and
teleport commands retain their original behavior with updated transport/names;
they still depend on server permissions. This is a community compatibility port,
not certification of every original addon feature or future Forever build.

## References

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
