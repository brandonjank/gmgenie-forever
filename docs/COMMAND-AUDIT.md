# Forever command audit

The reference is pinned to `advocaite/TrinityCore` Forever commit
`9ed0d9eb5d442714177bebb58e6b2312add6ab46`. Its 46 command scripts define
702 table entries, resolving to **619 executable command paths**. Empty-name
default handlers are included; commented-out entries are excluded. The snapshot
includes the three Forever scripts under `Custom/Classic/world` and excludes
deployment-local patches. File hashes and registration line numbers are
recorded in [commands.json](commands.json).

The common ancestor with TrinityCore master is
[`85d3c25180a89f889294d54d855efccae0945f20`](https://github.com/TrinityCore/TrinityCore/commit/85d3c25180a89f889294d54d855efccae0945f20)
(2026-09-25). The first Forever descendant,
[`cd640c7067c7d79b62cf7f44886583d09e58d059`](https://github.com/advocaite/TrinityCore/commit/cd640c7067c7d79b62cf7f44886583d09e58d059),
adds Classic 1.60.1.70009 client support. This core does not derive its command
API from the TrinityCore 3.3.5 branch despite the addon's original client target.

## Addon commands

The regression check resolves all **57 distinct literal command prefixes** sent
by shipped addon modules against this catalog, after transport aliases and report
type expansion. Dynamic mail/teleport/discipline commands are exercised by the
existing Lua 5.1 starter-macro tests. This establishes command spelling and
generated argument order for those fixtures, not successful execution of all
actions against every database or RBAC configuration.

| Area | Source check / correction |
| --- | --- |
| NPC movement | `.npc move [spawnid]` uses the selected creature when the ID is omitted; copies the GM's location/facing, saves the spawn, and relocates it. Builder rejects player/pet/missing targets. |
| Builder GPS | Changed bare `.gps` to `.gps <GM name>` so a selected NPC cannot supply the starting coordinates for Move self. |
| Coordinate teleport | `.go xyz x y [z] [mapId] [orientation]`; Builder supplies all five in that order. |
| Mail | `.send mail player "subject" "body"`; existing tests check quoting, multipart ordering and chat lengths. |
| Teleports | `.tele name player destination`; `.recall player` is separate. Destination names depend on the server database. |
| Discipline | Mute time is minutes; bans use time strings. Character, player-account and IP bans use distinct command paths. |
| Reports | `ticket bug`, `ticket complaint` and `ticket suggestion` each expose assign/close/comment/delete/list/unassign/view. The addon expands its legacy ticket aliases to the selected report type. |
| Compatibility aliases | `pin`, `mod`, `gob`, `char`, `name`, `gmname`, `ban char`, `gobject del`, `ticket viewid` and `ticket del` are rewritten only for addon GM commands. |
| Custom anticheat | `.anticheat player` is absent from this core. The old integration now explains its unavailability instead of sending an unknown command. |

## Repeatable validation

Run `python tests/test_gmgenie.py` and `python tests/test_commands.py` with the
dependencies in `tests/requirements.txt`. The latter checks parser edge cases,
complete pinned catalog counts, disabled entries, prefixes, real Lua browser
search/pagination/selection, source links, and help-only network sends.

`python tools/command_help_plan.py --console` prints read-only help requests for
the **332 console-enabled** commands. Feed those through your existing authorized
console transport. Without `--console`, the plan includes dot-prefixed in-game
help requests for every command. Review output explicitly; delivery is not proof
of successful execution. The addon's Server help button can check one command
from an authorized in-game GM character.

The remaining **287 commands are in-game only**. Console help hides them and may
report their parent as nonexistent. This is expected and must not be interpreted
as absence from the core. Help checks validate visibility/documentation; mutating
actions require controlled fixtures, backups and postcondition checks. This
release does not claim to have executed bans, sent mail, moved world spawns or
deleted data as part of validation.

On 2026-10-11, all 332 console-enabled commands were queried with `.help` through
the existing server console (without the dot). No unknown-command responses were
observed; eight commands lacked detailed help text. The source argument
definitions remain available for those entries. No action commands were run.

The browser's new UI is covered by Lua interaction tests. The installed update
has not yet been visually checked in an active GM session.
