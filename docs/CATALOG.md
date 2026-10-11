# Forever catalog

Open **Item & creature catalog** on the HUD, `/gmcatalog [search]`, or
`/gmgenie catalog [search]`. Search matches every word in the name or NPC title;
a number matches an exact entry ID. Items and NPCs/monsters have separate tabs.
Filter by type, item quality/slot, creature rank or NPC role. Save favorites or
return to recently viewed entries. Arrow keys select results and the wheel pages
the list. Browsing, previews and favorites send no GM commands.

## Data and availability

The 2026-10-11 snapshot contains **22,659 items and 15,205 creatures** from
[Wowhead's Forever database](https://www.wowhead.com/forever/database), tree 16.
It does not include items or creatures solely because a Retail-derived private
server database contains them. The collector divides capped listings into
disjoint ID ranges and verifies every parent/child count and the unique-ID total.
An explicit positive-ID filter includes nine more items than the unfiltered
Forever item page; the collector consistently uses the filtered listing mode.
Factual names, IDs, icons and classification metadata are bundled offline.
Wowhead comments, screenshots, guides and tooltip prose are not bundled.

Template IDs, NPC flags and model mappings were cross-checked against a reference
Forever core snapshot at revision `9ed0d9eb5d442714177bebb58e6b2312add6ab46` with
client data build 70338. **324 items and 4,427 creature templates were absent
from that inventory.** They remain in the official Forever whitelist with a
visible reference-snapshot availability note. A different private server may
support more or fewer entries. This is not a live availability check, and the
inventory unions DB2 and SQL records without evaluating runtime hotfix deletions.
See [source ledger](catalog-sources.json) for page hashes, ranges and coverage.

There are client-valid display mappings for **10,661 creatures** in the reference
snapshot. Other creatures use the client's creature-query fallback; an unavailable
model gets an explanatory message. Equipment is previewed on your character.
Materials, recipes and other entries without a 3D appearance use an icon and
in-game tooltip. Drag a model to rotate, scroll to zoom, or use the view buttons.
Some creatures have multiple appearance variants. Previews use your client's
assets; no model files or images are downloaded by the addon.

## Actions

- **Add to my inventory** sends `.additem to <your character> <ID> <quantity>`.
  Quantity must be a whole number from 1 to 1000. Another selected player never
  receives the item. Server permissions, item support and bag space still apply.
- **Spawn temporary** sends `.npc add temp noloot <ID>` at your current position
  and facing. It is not saved in the world database. This is not a timed preview:
  the creature may remain alive until removed or until the map/server unloads.
- **Spawn persistent...** confirms the selected entry, then sends `.npc add <ID>`.
  It saves a persistent world spawn at your position and facing. Changing the
  selection/filters, switching tabs or closing the window cancels the confirmation.

The browser reports requests as requests; the server response remains in chat.
It does not guess success, grant RBAC permissions or install missing templates.

## Rebuilding

```sh
python tools/collect_forever_catalog.py --cache /path/to/private-cache
python tools/generate_catalog.py /path/to/private-cache/wowhead-catalog.json
python tests/test_catalog.py
```

The first command reads public Forever listing pages, caches them for resumable
builds, and rejects non-Forever responses, ignored filters, duplicate IDs or
count changes. Keep raw HTML caches out of the addon/repository. Delete or select
a fresh cache directory when refreshing the entire snapshot; do not mix dates.
The generator writes `CatalogData.lua` and `docs/catalog-sources.json`.

Optional `--inventory reference.json.gz` enriches entries without extending the
whitelist. Its public-data-only JSON format is:

```json
{
  "revision": "core source commit",
  "items": [25, 2589],
  "displayIDs": [1973],
  "creatures": [[5807, 0, [[1973, 1.0]]]]
}
```

An item ID should have both basic and sparse records in the target client's
DB2/hotfix inventory. Creature rows contain entry ID, `npcflag`, and ordered
`[CreatureDisplayID, DisplayScale]` pairs from `creature_template_model`.
Export only these public template fields, using a read-only query/snapshot.
Never export account, player or configuration data. Include only display IDs
present in the client's display inventory. The test suite deliberately pins the
published counts; update those assertions when publishing a verified new snapshot.
