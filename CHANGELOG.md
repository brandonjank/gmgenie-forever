# Changelog

## 0.7.3-forever.15 — 2026-10-12

- Fix TrinityCore handshake replies being rejected for Forever characters with
  surnames. Forever's native name APIs return the surname as their second value;
  use the display-name helper and the actual realm name for sender matching.
- Preserve exact token, sender and realm checks, including foreign-realm rejection.
- Add regression coverage for Forever's actual first-name/surname API returns
  and the standard realm-qualified name format.

## 0.7.3-forever.14 — 2026-10-12

- Keep the addon hidden and inactive until a matching TrinityCore addon ping
  acknowledgement arrives. Preserve the existing single-folder install.
- Defer initialization, Settings, unit menus, chat integrations, roster listeners
  and the bundled Chronos timer driver until server compatibility is confirmed.
- Guard feature entry points, slash shortcuts and outgoing message transport;
  reject echoes, foreign replies, mismatched tokens and late acknowledgements.
- Check afresh on login/reload with a five-second timeout and no automatic retry.
  Add `/gmgenie check` for explicit retry and server check state to debug output.
- Add automated coverage for incompatible servers, correct activation, spaced
  names, timeout/retry isolation, missing APIs and initialization failures.


## 0.7.3-forever.13 — 2026-10-12

- Add original brass genie lamp and violet infinity artwork, a client-compatible
  TGA icon declared in the TOC, and repository branding assets.
- Include `.previews/GMGenie-Forever.png` on the release branch for WowUpHub
  image previews. Document the separate default-thumbnail/social-preview setup
  and the direct GitHub importer limitation.

## 0.7.3-forever.12 — 2026-10-12

- Name release packages `GMGenie-Forever-<gameversion>-<build>.zip`, deriving
  the game version from the TOC interface and build from the addon release number.
- Retain the separate `release.json` asset for WowUp compatibility and updates;
  validate its exact match to the renamed ZIP in CI.

## 0.7.3-forever.11 — 2026-10-12

- Identify release ZIPs with WowUp's required terminal `-forever.zip` suffix.
- Generate and publish `release.json` with Forever flavor and interface 16001
  so GitHub imports can verify client compatibility.
- Validate the actual ZIP, manifest and WowUp release-selection contract in CI.
- Document repository URL installation and tracked updates. Addon behavior is
  unchanged from forever.10.

## 0.7.3-forever.10 — 2026-10-11

- Replace the default Builder with a compact remote using the shared modern UI.
- Select a gameobject safely by nearest, spawn ID or chat link; remove the old
  target-then-delete response handler.
- Move the object with a directional pad and height steps relative to GM facing,
  rotate in adjustable increments, match GM position/facing and undo one edit.
- Wait for exact spawn acknowledgements and live GPS reads; block stale,
  concurrent and cross-map edits and never retry mutations automatically.
- Confirm persistent spawn/delete operations; guard NPC actions and target changes.
- Preserve presets and existing scripted build helpers.
- Verify command handlers and English response strings against the running core;
  add Lua 5.1 regression coverage for the remote and error paths.

## 0.7.3-forever.9 — 2026-10-11

- Fix roster loading for in-game GMs: replace `.account onlinelist`, which can be
  absent from their RBAC permissions, with the native Who API and zone results.
- Search the server with Enter/Refresh, and warn when Who results may be capped.
- Add per-player Actions menus with confirmed Kick, character Ban and Kill.
- Validate reasons and positive ban durations; block self/foreign/stale entries
  and repeated submissions.
- Require the matching selected player and unchanged GUID for `.die`, which
  cannot accept a named-player argument in this Forever build.
- Keep Forever first-name/surname display names, using the unique first name for
  GM commands and self/target matching.
- Refresh Who only from user actions; timer searches are blocked by this client.
- Test native API errors, timeouts, caps, surnames and action safeguards in Lua 5.1.

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
