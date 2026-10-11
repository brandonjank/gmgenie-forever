# Changelog

## 0.7.3-forever.8 — 2026-10-11

- Add an online-player window with zone names, player/zone search and paging.
- Add compact TP (`.appear`) and SUM (`.summon`) buttons scoped to each named row,
  leaving the selected target unchanged and disabling actions for self/stale rows.
- Read the uncapped Forever online session list; resolve zone names with the
  modern client API instead of using last-saved database locations.
- Refresh every 15 seconds while visible, with manual refresh, an auto toggle,
  atomic response handling and clear timeout/permission guidance.
- Discard account/IP fields, filter recognized roster tables from chat, preserve
  server errors, and keep all roster data out of saved variables.
- Cover parsing, filtering, paging, polling and travel safeguards in Lua 5.1.

## 0.7.3-forever.7 — 2026-10-11

- Bundle the complete verified Forever listing: 22,659 items and 15,205 creatures,
  with no entries added solely from inherited Retail server data.
- Add a catalog dashboard shortcut, `/gmcatalog`, text/ID search, type/quality/slot/
  rank/role filters, favorites, recent history, paging and tooltips.
- Preview equipment on your character and creatures in 3D, with rotation, zoom,
  alternate appearances and explanatory fallbacks for missing assets.
- Add items explicitly to the GM’s own inventory with validated quantities.
- Offer temporary no-loot spawns and confirmed persistent spawns at the GM’s position.
- Mark entries absent from the bundled reference core snapshot without removing
  them from the official Forever whitelist.
- Add reproducible range-checked collection, source hashes, compact lazy decoding
  and Lua 5.1 regression tests for the catalog and action safeguards.

## 0.7.3-forever.6 — 2026-10-11

- Redesign the HUD as a dark slate dashboard with teal status indicators,
  command search, native report/macro menus and a live target card.
- Rebuild the command library with category/context filters, saved favorites,
  the 20 most recently used commands, selected rows and a separate source view.
- Add keyboard Up/Down navigation, mouse-wheel paging and clear empty states.
- Remember dragged window positions and add 90/100/110/125% interface scaling.
- Apply a shared theme to the existing Builder, Spy, report and macro controls.
- Validate speed input and keep GM state unknown until the server acknowledges it.
- Test dashboard creation, menu callbacks, target changes and saved layouts in
  Lua 5.1, alongside the existing command and macro regression suites.

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
