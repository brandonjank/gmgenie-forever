# GM Genie Forever

GM tools for private servers using **WoW Forever** clients and a compatible
TrinityCore Forever server. A community port of
[Chocochaos's GM Genie 0.7.3](https://github.com/chocochaos/GMGenie), maintained by
[brandonjank](https://github.com/brandonjank).

**Current version: 0.7.3-forever.9.** Tested with WoW Forever **1.60.1, build
70338, interface 16001** and the `forever` branch of
[advocaite/TrinityCore](https://github.com/advocaite/TrinityCore/tree/forever).
English command responses are currently required for parsing.

## Install

1. Download **GMGenie-0.7.3-forever.9.zip** from the
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
- Creature/gameobject lookup links and the original spawning/builder tools.
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

The list is restricted to [Wowhead’s Forever database](https://www.wowhead.com/forever/database).
Equipment previews use your character; NPCs use creature displays. Drag to rotate
and scroll to zoom. Entries without a 3D appearance show an icon/tooltip.
**Add to my inventory** explicitly names your character, regardless of your target.
Temporary spawns are not saved; persistent spawns require an in-window confirmation.

Some official Forever entries are missing from the bundled reference core snapshot
and are labeled accordingly. Previews also depend on the assets in your client.
See [catalog data, availability and rebuild notes](docs/CATALOG.md).

## Move a selected NPC to your position

Open `/builder`, target the NPC, stand where it should be, face its desired
direction and click **Move NPC here**. This saves the selected NPC's new position
and orientation permanently and respawns it. It uses `.npc move`, so the target
must be a persistent creature spawn and your GM account needs permission.
Missing targets, players and pets are rejected before sending a command.

**Move self** and **Move self back** move your character using Builder offsets.
**Move NPC here** uses your character's current position and facing.

## Compatibility and validation

Forever combines Classic content with newer UI APIs. This port updates
backdrops, Settings pages, scrolling editors, player context menus and chat
links, rather than relying only on the TOC interface version. Commands use a
self-whisper consumed by the core, which also works for unguilded GMs.

The automated Lua 5.1 suite checks 224 Lua/XML chunks, manifest references,
command routing, synthetic report/player-info parsing, links, saved settings,
all 28 starter macros, migration and macro editors. Network sends are mocked.
Live checks covered login, HUD, Settings, report-type switching, player menus,
Spy, lookup links and starter editors; the final diagnostic reported
`initialized=true, errors=0` before the dashboard redesign. The redesigned
command library, search, favorites, recent history, native menus, Builder,
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
python tests/test_catalog.py
python tools/package.py
```

The package script creates an installable `dist/GMGenie-<version>.zip` with a
single `GMGenie/` directory. GitHub Actions runs the checks and builds the same
ZIP. See [CONTRIBUTING.md](CONTRIBUTING.md) for bug reports and contributions.

## Credits and license

Original GM Genie copyright **2011-2014 Chocochaos**. Forever modifications
copyright **2026 Brandon Jank**. Distributed under **GNU GPL version 3**;
the original license and copyright notices are retained. Chronos retains its
original source notices. See [LICENSE](LICENSE), [NOTICE](NOTICE), and the
[original README and changelog](docs/README.upstream.md).
