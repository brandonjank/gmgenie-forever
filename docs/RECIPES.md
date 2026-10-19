# World-building recipes

Open **Recipes** on the HUD or command workspace, or type `/gmrecipes`.
`/gmgenie recipes patrol` opens the recipe list with a search applied.
Macro editors are under **Settings > Macro editors**.

Recipes are reusable command forms with instructions. They run **one step at a
time**, with no Run all button, timers, automatic retries or automatic advancement
after sending. A server response can still reject a valid form because of RBAC,
missing templates or other server rules.

## Included examples

| Example | What it does |
| --- | --- |
| Vendor: add stock | Inspect a selected vendor, then add an item with editable stock/restock values. |
| Vendor: place and stock | Spawn an existing vendor template, select the new spawn and add stock. |
| Patrol: create a new route | Allocate a path, append points while walking, reload it, assign it, and show/hide markers. |
| Patrol: extend an existing route | Append points to a known Path ID, reload it and reassign the patrol NPC. |
| Placement: stationary NPC | Save an NPC at your position/facing, set stay movement while preserving paths, and inspect it. |
| Placement: move NPC here | Move a bound saved NPC to your position and orientation, then inspect it. |
| Placement: saved gameobject | Create an object from an entry you supply, then list nearby spawn IDs. |
| Placement: move and face object | Move one database spawn ID and apply your facing, sharing that ID across both steps. |
| Placement: temporary NPC preview | Spawn an unsaved preview at your position/facing. |

Example creature **54** is Corina Steele (an existing weaponsmith template), **68**
is Stormwind City Guard, and item **25** is Worn Shortsword. These IDs and the
vendor role exist in the bundled Forever catalog. Change them for your own world.
Gameobject entries, gameobject spawn IDs and Path IDs start blank; they are not
guessed. A template entry identifies a kind of creature/object, while a spawn ID
identifies one placed instance.

Vendor stock is attached to the **creature template**, so changes affect every
vendor using that entry, including pre-existing spawns. Placing an existing vendor
does not create a private template or stock list. Stock **0** means unlimited;
for limited stock, try **5** with **300** restock seconds. The examples do not
overwrite NPC interaction flags or create database templates.

## Run and check a step

1. Select a recipe and a step. Read its instructions and edit the inline fields.
   Values marked shared carry across the steps that use them.
2. For NPC actions, select the intended NPC and click **Bind NPC**. The binding is
   checked against the current target GUID. Rebinding clears checks for the affected
   NPC steps; it does not change anything in the world.
3. Check the exact command preview. Read-only inspections use **Run step**;
   changes use **Review step**, then **Confirm step** within ten seconds. Argument
   or target changes cancel review. Position/facing is rechecked for placement and
   waypoint actions; moving before confirmation requires review again.
4. Read the server response and inspect the actual world result. Click
   **I checked the result** to record your own check and open the next step.
   This is a manual acknowledgement, not an assertion that the server succeeded.
   **Next** also lets you skip steps without running them.

Nothing runs because you selected a recipe, changed a field, saved a copy, changed
targets or opened the next step. Repeating a placement/waypoint command requires
another explicit review. It can create another spawn or point, so check the result
before repeating a command after an uncertain response.

## Create a patrol

Start with **Patrol: create a new route**. Clear your target and stand at the first
point, then run the first step **once**. Native `.wp add` without a target allocates
the path; with a selected NPC it can use that NPC's existing path instead. Copy the
server's **PathID** from chat into step 2. No response text is automatically trusted
or interpreted as a command.

Walk to the next point and run step 2. Repeat that step at every point you want to
append, then continue to **Reload the completed path**. Reload is necessary to load
the new database path into the server cache before `.wp load` can assign it.

Select a saved patrol NPC, bind it, and run **Assign the route**. Native `.wp load`
saves the path assignment and starts waypoint movement; no extra `.npc set movetype
way` is needed. Inspect the route with the marker steps. Editing a path shared with
other NPCs also changes their route; create a new path when you need a separate one.

## Save personal recipes

Edit a recipe name/note and its fields, then **Save copy**. **Update saved** replaces
the selected personal recipe; bundled examples remain unchanged. You can save a
template with blank fields and fill them when using it. Required fields must be
complete before a step can run. Use **Edit step** to reorder/remove steps, reset an
example's defaults, or revert unsaved edits to the saved version.

From the command workspace, fill a supported world-building form and choose
**Save form... > New recipe from this form**. To build a longer recipe, use
**Add step...**, choose/fill a command, then **Save form... > Append to ...**.
Captured forms include the command's explanation. Credential/account/player
administration forms are excluded.

Recipe names, notes, steps and argument values are saved in the existing
`GMGenie_SavedVars.worldRecipes`. Up to **100 personal recipes**, **20 steps per
recipe**, and **32 shared fields** are supported. Incomplete in-session drafts and manual checks are
retained when switching recipes, but **Save copy/Update saved is required before
reloading**. Bound target GUIDs, live positions and manual checks are never saved to disk. Returning to a recipe requires an explicit NPC binding before target-dependent commands can run.
Deleting a personal recipe leaves its current draft open for recovery and does not
undo world edits.

Saved data is declarative: no Lua snippets, string evaluation, chat markup or
multiline command values. Every send is rebuilt through the command form validator.
Changed handler signatures or invalid saved entries are excluded for review rather
than silently reinterpreted; their data is preserved in SavedVariables.

## Source and validation

Examples follow the pinned Forever command snapshot
`9ed0d9eb5d442714177bebb58e6b2312add6ab46`, especially
[NPC handlers](https://github.com/advocaite/TrinityCore/blob/9ed0d9eb5d442714177bebb58e6b2312add6ab46/src/server/scripts/Commands/cs_npc.cpp),
[waypoint handlers](https://github.com/advocaite/TrinityCore/blob/9ed0d9eb5d442714177bebb58e6b2312add6ab46/src/server/scripts/Commands/cs_wp.cpp)
and [object handlers](https://github.com/advocaite/TrinityCore/blob/9ed0d9eb5d442714177bebb58e6b2312add6ab46/src/server/scripts/Commands/cs_gobject.cpp).
Custom cores can change behavior; Server help remains available for every step.

`python tests/test_recipes.py` exercises the real Lua recipe model/UI, command
previews, guarded sends, shared fields, saved updates/deletion, fresh-session
persistence, schema checks and example inventory IDs. Network sends in this suite
are mocked; it does not claim live world/database changes were tested.

**Find** beside supported item/creature entry fields opens a catalog picker. Choose **Use selection** to return that template ID, or **Cancel/Back** to return without changes. Picker mode disables spawning and item delivery. **Back** between the main workspaces restores your previous search and selection. Spawn IDs, Path IDs and display IDs cannot be substituted with catalog template entries.
