# Changelog

## 0.7.3-forever.5 — 2026-10-11

- Add a searchable offline reference for all 619 commands registered in Forever
  revision `9ed0d9eb5d442714177bebb58e6b2312add6ab46`, across 46 command scripts.
- Open it from HUD **Commands** or `/gmgenie commands [search words]`.
- Show argument order, parameter outlines, RBAC IDs, console availability and
  pinned source links. **Server help** sends only `.help <command>`.
- Include a reproducible, fail-closed generator and machine-readable catalog.
- Request the GM's own GPS coordinates when Builder moves the GM, even with an
  NPC selected. Explain the unsupported legacy custom anticheat action.
- Add parser, command-prefix and Lua browser interaction regression checks.

## 0.7.3-forever.4 — 2026-10-10

- Add **Move NPC here** to Builder: target an NPC, stand at its new location,
  face the desired direction and click to persist its position/orientation.
- Reject missing targets, players and pets before issuing `.npc move`.
- Clarify the existing controls as **Move self** and **Move self back**.
- Explain persistent spawn movement in the tooltip and installation docs.
- Test the actual XML button callback and command transport in Lua 5.1.

## 0.7.3-forever.3 â€” 2026-10-10

First public Forever release, based on GM Genie 0.7.3.

- Modern UI adapters for backdrops, Settings, menus, editors and chat links.
- Unguilded GM command transport and explicit Forever command names.
- Bug, complaint and suggestion reports and updated player-info parsing.
- Saved setting fixes and addon error diagnostics.
- 28 editable, server-neutral whisper, mail, teleport and discipline starters.
- One-time starter migration preserving custom entries and later deletions.
- Macro editor fixes and deterministic multi-part message ordering.
- Lua 5.1 regression checks, CI and installable release ZIP packaging.

See docs/README.upstream.md for the original addon changelog.
