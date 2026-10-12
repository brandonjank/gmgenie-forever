# GM Genie Forever

<img src="https://raw.githubusercontent.com/brandonjank/gmgenie-forever/TrinityCore/docs/branding/icon.png" width="96" height="96" alt="GMGenie Forever brass lamp and violet infinity smoke icon">

GM tools for private servers using **WoW Forever** clients and a compatible
TrinityCore Forever server. A community port of
[Chocochaos's GM Genie 0.7.3](https://github.com/chocochaos/GMGenie), maintained by
[brandonjank](https://github.com/brandonjank).

**Current version: 0.7.3-forever.13.** Tested with WoW Forever **1.60.1, build
70338, interface 16001** and the `forever` branch of
[advocaite/TrinityCore](https://github.com/advocaite/TrinityCore/tree/forever).
English command responses are currently required for parsing.

## Install

1. Download **GMGenie-Forever-1.60.1-13.zip** from the
   [latest release](https://github.com/brandonjank/gmgenie-forever/releases/latest).
2. Close the client. Back up your existing `Interface/AddOns/GMGenie` folder
   and your GM Genie saved variables in the client's `WTF` folder if upgrading.
3. Extract the ZIP into the **Forever client's** `Interface/AddOns` directory.
   The result must be `Interface/AddOns/GMGenie/GMGenie.toc`.
4. Enable **GM Genie Forever** in AddOns, log in with an authorized GM
   character, and run `/gmgenie options` to customize your macros.

The folder must be named **GMGenie** because the addon references its textures
and resources by that name. If using GitHub's **Code > Download ZIP**, rename
the extracted repository folder to `GMGenie` before installing it. Do not nest
it inside another `GMGenie` folder.

### WowUp updates

In the Forever client, use **Install from URL** with
`https://github.com/brandonjank/gmgenie-forever` (the repository URL).
WowUp tracks GitHub releases; it does not pull Git commits. A direct ZIP URL
cannot track future updates.

Releases use `GMGenie-Forever-<gameversion>-<build>.zip`, where game version is
derived from the TOC interface and build is the increasing addon release number
(for example, `1.60.1-12`). A separate `release.json` asset declares flavor
`forever`, the interface and the exact ZIP filename so WowUp can select the
package. Keep the GitHub provider and automatic
updates enabled. If the installed and latest release filenames match, the
addon is already current. No reinstall is needed for existing GitHub imports.

### Artwork in WowUp

The release branch contains `.previews/GMGenie-Forever.png` for WowUpHub
image previews. The addon includes `Textures/Forever.tga` and declares it in
the TOC as its icon.

The direct GitHub provider in WowUp currently uses the repository owner avatar
for its list thumbnail; `release.json` selects compatible ZIPs and does not
provide an icon override. WowUpHub documents using the repository social
preview for the default image. See [branding setup](docs/branding/README.md)
and [WowUpHub documentation](https://wowup.io/guide/wowup/hub).

## Included tools

- **Forever-only offline catalog: 22,659 items and 15,205 NPCs/monsters**, with
  search, type/quality/slot/rank filters, favorites, 3D previews and item/spawn
  actions. Open **Catalog** or `/gmcatalog`.
- **Online players with current zones**, name/zone search and compact **TP** / **SUM**
  buttons and an **Actions** menu for confirmed Kick/Ban/Kill. Native Who searches
  refresh with Enter or Refresh. Open **Online players** or `/gmplayers`;
  press Enter to search the server. Who visibility and result limits apply.
- Modern dashboard with command search, GM controls and a live target card.
- Native report/macro menus, remembered window positions and interface scaling.
- Bug, complaint and suggestion report lists using Forever's report commands.
- Spy/player information, player context menus and common GM actions.
- **Compact Builder remote** with safe gameobject selection, a directional pad,
  height/rotation steps, Move here, Face me, one-step undo and confirmed spawn/delete.
- Creature/gameobject lookup links and saved spawning presets.
- **619-command searchable reference**, with argument order, RBAC permissions,
  console availability, source links and a Server help button. Favorites, recent
  history and category/context filters help you find commands quickly.
- **28 editable starter macros**, installed automatically and preserved across
  reloads alongside your custom macros.

| Starter category | Examples |
| --- | --- |
| 7 whispers | First reply, details request, teleport consent, stuck character, resolution, conduct warning, custom-topic prompt |
| 4 mail templates | Offline follow-up, bug details, conduct reminder, two-part welcome |
| 10 teleports | Recall, GM Island, six faction capitals, Booty Bay, Ratchet |
| 7 discipline macros | Three temporary mutes, two character bans, one account ban, one IP ban |

Access macros through a player's **GM Genie** context menu or the Spy window.
Edit them under `/gmgenie options`. `NAME` inserts the recipient's name;
`SUBJECT` in a whisper opens a prompt. Each newline sends a separate message.
Existing installs merge missing starter names once. Same-name customizations
are preserved, and deleted examples stay deleted after reload.

Teleport macros move the **selected player**. Destination strings must exist
in your server's `game_tele` table; edit them to match your database. `RECALL`
uses the position saved before a GM teleport or summon.

Discipline macros execute their named action when selected. Their durations
and reasons are examples to adapt to your server's rules. Mutes use minutes;
bans use `s`, `m`, `h` or `d`. The included examples use finite durations and
GM-only announcements. An IP ban can affect players sharing an address.

## Commands

| Command | Action |
| --- | --- |
| `/gmgenie` | Toggle the HUD |
| `/gmgenie commands [search words]` | Browse the complete Forever command reference |
| `/gmgenie catalog [search]` / `/gmcatalog [search]` | Browse Forever items and creatures |
| `/gmgenie players [search]` / `/gmplayers [search]` | Online players, zones and quick TP/SUM |
| `/gmgenie options` | Open Settings |
| `/gmgenie status` | Query badge, visibility and whisper status |
| `/gmgenie debug` | Show initialization and captured addon error count |
| `/tickets` | Toggle the selected report list |
| `/tickets bug`, `/tickets complaint`, `/tickets suggestion` | Select report type and toggle its list |
| `/spy CharacterName` | Inspect a player |
| `/builder` | Toggle the builder |

## Item and creature catalog

The list is restricted to [Wowheadâ€™s Forever database](https://www.wowhead.com/forever/database).
Equipment previews use your character; NPCs use creature displays. Drag to rotate
and scroll to zoom. Entries without a 3D appearance show an icon/tooltip.
**Add to my inventory** explicitly names your character, regardless of your target.
Temporary spawns are not saved; persistent spawns require an in-window confirmation.

Some official Forever entries are missing from the bundled reference core snapshot
and are labeled accordingly. Previews also depend on the assets in your client.
See [catalog data, availability and rebuild notes](docs/CATALOG.md).

## Builder remote

Open `/builder` for the compact remote. In **Objects**, click **Nearest object**
to select without changing anything, enter an existing **spawn ID** and click
**Select ID**, or click a gameobject chat link and choose **Edit in Builder**.
The selection card shows the exact object name and spawn ID. Gameobjects usually
cannot be selected using the normal unit target; template entry IDs identify new
objects to spawn, while spawn IDs identify existing objects to edit.

- The directional pad moves the selected object relative to **your facing**.
  Choose 0.1, 0.5, 1, 5 or 10 yards per click; Up/Down changes height.
- Turn left/right uses 1, 5, 15, 45 or 90 degrees per click.
- **Move here** copies your position; **Face me** separately copies your facing.
- **Undo last edit** restores the position or yaw before the last acknowledged
  edit. It is one level, for the selected object, and does not undo spawn/delete.
- **Delete...** and **Spawn...** require confirmation. Spawning uses the template
  entry field and your current position. Existing object/NPC presets still work.

In **NPCs**, target a persistent NPC, stand where it belongs, face the desired
direction and click **Move here**. `.npc move` saves position and facing and
respawns the NPC. Missing targets, players and pets are rejected. This core has
no direct XYZ/yaw NPC editing command, so the directional controls stay disabled
in NPC mode. NPC deletion also rechecks that the target has not changed.

Edits save permanently through the server's GM commands and need the appropriate
RBAC permissions. Object movement waits for an acknowledgement, then reads live
coordinates with `.gps`; it never moves your character. Selection expires after
45 seconds and clears on world/location changes. Errors/timeouts require a fresh
read; commands never retry automatically. Avoid concurrent manual `.gps` commands
while a builder read is pending because server GPS replies lack request IDs.

Forever's `.gobject turn` resets pitch and roll, including when matching your
facing or undoing yaw. NPC spawning sends no success acknowledgement in this core;
the remote reports only that the command was sent and asks you to verify it.
Response parsing currently requires English server strings.

Builder commands and response formats were checked against the running Forever
revision `440d365e791baff1cdf555ed2179c71bd6ebd014`. Automated Lua 5.1 tests cover
the remote, transforms, acknowledgements, undo and guards using those formats.
This redesign has not yet been visually verified or used to edit a live spawn.

## Compatibility and validation

Forever combines Classic content with newer UI APIs. This port updates
backdrops, Settings pages, scrolling editors, player context menus and chat
links, rather than relying only on the TOC interface version. Commands use a
self-whisper consumed by the core, which also works for unguilded GMs.

The automated Lua 5.1 suite checks the Lua/XML chunks, manifest references,
command routing, synthetic report/player-info parsing, links, saved settings,
all 28 starter macros, migration and macro editors. Network sends are mocked.
Live checks covered login, HUD, Settings, report-type switching, player menus,
Spy, lookup links and starter editors; the final diagnostic reported
`initialized=true, errors=0` before the dashboard redesign. The redesigned
command library, search, favorites, recent history, native menus, the prior Builder,
report shortcuts and interface scaling were then checked in game with no
further Lua error dialog after fixing button font-region initialization.

Live report lists were empty; populated reports were checked with synthetic
responses. Bans, deletion, report closure, cross-GM synchronization, WIM and
custom anticheat integrations were not exercised. Commands require the
appropriate server permissions. Other Forever builds, core forks and response
locales may need changes. See [port notes](README.Forever.md) for details.

## Development

```sh
python -m pip install -r tests/requirements.txt
python tests/test_gmgenie.py
python tests/test_commands.py
python tests/test_ui.py
python tests/test_players.py
python tests/test_builder.py
python tests/test_catalog.py
python tools/package.py
python tests/test_package.py
```

The package script creates an installable `dist/GMGenie-Forever-<gameversion>-<build>.zip`
with a single `GMGenie/` directory plus `dist/release.json` for WowUp. Upload
both as assets of the tagged GitHub release. GitHub Actions runs the checks and builds the same
ZIP. See [CONTRIBUTING.md](CONTRIBUTING.md) for bug reports and contributions.

## Credits and license

Original GM Genie copyright **2011-2014 Chocochaos**. Forever modifications
copyright **2026 Brandon Jank**. Distributed under **GNU GPL version 3**;
the original license and copyright notices are retained. Chronos retains its
original source notices. See [LICENSE](LICENSE), [NOTICE](NOTICE), and the
[original README and changelog](docs/README.upstream.md).
