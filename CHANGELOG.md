# Changelog

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
