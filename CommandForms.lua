-- Command form model. C++ signatures are pinned in CommandData.lua. GPL-3.0.
GMGenie.CommandForms = {};
local M=GMGenie.CommandForms;
local function trim(value) return tostring(value or ""):match("^%s*(.-)%s*$"); end
local childWords,registered={},{};
for _,entry in ipairs(GMGenie.CommandData.entries) do registered[entry.name]=true; end
for _,entry in ipairs(GMGenie.CommandData.entries) do
    local parent="";
    for word in entry.name:gmatch("%S+") do
        if registered[parent] then childWords[parent]=childWords[parent] or {}; childWords[parent][word]=true; end
        parent=parent=="" and word or (parent.." "..word);
    end
end

M.guides={
    ["additem"]="Give an item to the selected player, or yourself when no player is selected. Count defaults to one; a negative count removes items. Use the Catalog for explicit delivery to yourself.",
    ["gm on"]="Enable GM mode for your character. The server determines which GM permissions your account has.",
    ["gm off"]="Disable GM mode for your character.",
    ["gm chat"]="Show or set your GM chat badge. Leave the field empty to query its current state; use on or off to change it.",
    ["gm visible"]="Show or set your visibility to ordinary players. Leave the field empty to query it; use on or off to change it.",
    ["gm fly"]="Enable or disable GM flight for the selected player, or yourself. Use on or off.",
    ["go areatrigger"]="Teleport to the location of an area-trigger entry ID.",
    ["go graveyard"]="Teleport to a graveyard location by graveyard ID.",
    ["go grid"]="Teleport to map-grid coordinates, rather than world XYZ. The map ID is optional.",
    ["go quest"]="Teleport to a location associated with the specified quest entry, as resolved by the server.",
    ["go taxinode"]="Teleport to a flight-path node by taxi-node entry ID.",
    ["go zonexy"]="Teleport using zone-map X/Y percentages. An optional area ID selects the zone; these are different from world XYZ coordinates.",
    ["go boss"]="Search boss locations using the supplied words and teleport to a matching result. Server help describes the search rules.",
    ["go instance"]="Search instance locations using the supplied words and teleport to a matching result. Server help describes the search rules.",
    ["go bugticket"]="Teleport to the saved location of a bug report by ticket ID.",
    ["go complaintticket"]="Teleport to the saved location of a complaint report by ticket ID.",
    ["go suggestionticket"]="Teleport to the saved location of a suggestion report by ticket ID.",
    ["npc add formation"]="Add your selected NPC to a formation led by the specified database spawn ID. Optional flags control linked aggression and formation movement.",
    ["npc add item"]="Add an item to the selected vendor's sale list. Optional fields configure stock, restock time, extended cost and bonuses. Vendor lists belong to the creature template.",
    ["npc add move"]="Set the saved NPC spawn's database movement type to waypoint movement. This command does not create waypoint coordinates; use the wp commands to edit a path.",
    ["npc delete item"]="Remove an item from the selected vendor's sale list. Vendor lists belong to the creature template, so other vendors using that template are affected.",
    ["npc evade"]="Ask the selected NPC's AI to enter evade mode. The optional reason and force flag control how the AI reset is requested.",
    ["npc follow"]="Make the selected NPC follow your character.",
    ["npc follow stop"]="Stop the selected NPC from following your character.",
    ["npc playemote"]="Set an emote state on the selected NPC using a numeric emote ID.",
    ["npc set allowmove"]="Toggle creature movement server-wide. This affects the server's global movement setting, rather than only your selected NPC.",
    ["npc set data"]="Send a numeric data key and value to the selected NPC's AI script. The meaning depends on that NPC's script; use its source to choose valid values.",
    ["npc set entry"]="Change the selected NPC to a different creature template entry.",
    ["npc set factionid"]="Change the selected NPC's faction and update its creature template's faction setting.",
    ["npc set flag"]="Set both NPC interaction flag fields on the selected creature's template. Template changes can affect other spawns using that template.",
    ["npc set level"]="Change the selected creature or pet's level. The server enforces its supported level range.",
    ["npc set link"]="Link the selected saved NPC's respawn to another creature database spawn ID.",
    ["npc set movetype"]="Set movement to stay, random or way (waypoints). Leave the spawn ID empty to use your selected NPC. Changing type can delete waypoints; enter nodel to preserve them.",
    ["npc set phase"]="Replace the selected NPC's phase with the supplied phase ID and save the change.",
    ["npc showloot"]="Inspect the selected NPC's loot. The optional all keyword includes all loot possibilities supported by the handler.",
    ["npc tame"]="Tame the selected creature as a pet, subject to the server's class and pet checks.",
    ["npc spawngroup"]="Spawn a configured group on your current map. Enter the group ID, optionally followed by force or ignorerespawn.",
    ["npc despawngroup"]="Despawn a configured group on your current map. Enter the group ID; removerespawntime also clears its respawn timers.",
    ["gobject spawngroup"]="Spawn a configured group on your current map. Enter the group ID, optionally followed by force or ignorerespawn.",
    ["gobject despawngroup"]="Despawn a configured group on your current map. Enter the group ID; removerespawntime also clears its respawn timers.",
    ["gobject info"]="Inspect a gameobject template by entry ID. To inspect a placed object's spawn ID, enter guid in the first field and its spawn ID in the second.",
    ["gobject set phase"]="Add a phase ID to the gameobject identified by its database spawn ID and save the phase state.",
    ["gobject set state"]="Change a gameobject's runtime state or a state-related field by spawn ID. objectType selects the operation; request Server help before choosing its numeric value.",
    ["tele group"]="Teleport the selected player's group to a named server teleport location. Select a player first, including yourself when moving your own group.",
    ["wp add"]="Append a waypoint at your position to a path. Supply a path ID, or use your selected creature to resolve a path.",
    ["wp load"]="Assign a waypoint path ID to the selected saved creature.",
    ["wp unload"]="Remove the selected saved creature's assigned waypoint path.",
    ["wp reload"]="Reload a waypoint path ID from the database into the server's path cache.",
    ["wp modify"]="Edit a selected visible waypoint marker: del removes the point; move relocates it to your position.",
    ["wp show"]="Show or hide waypoint markers, or inspect one. Choose on, off or info; an optional path ID selects the path.",
    ["npc move"]="Move a saved NPC spawn to your current position AND facing. Target the NPC, or enter its database spawn ID. You must be on the same map. The change is saved permanently.",
    ["npc add"]="Create and save an NPC at your position using a creature template entry ID. Use the catalog to find entries that exist in Forever.",
    ["npc add temp"]="Create a temporary NPC at your position. The optional loot keyword keeps its corpse available for loot; noloot (the default) despawns its corpse immediately.",
    ["npc delete"]="Permanently delete the selected NPC spawn, or the database spawn ID you enter. A spawn ID identifies one placed NPC; it is different from a creature template entry ID.",
    ["npc info"]="Inspect your selected NPC. The server reports its template entry, spawn information and other details in chat.",
    ["npc near"]="List nearby saved NPC spawns. Distance is in yards; leaving it blank uses the server default.",
    ["npc set model"]="Change the selected NPC's display model and save the change. Enter a creature display ID, rather than a creature template entry ID.",
    ["npc set spawntime"]="Set the selected NPC's respawn delay in seconds and save the change.",
    ["npc set wanderdistance"]="Set and save the selected NPC's wander radius in yards. Movement type also controls whether it wanders.",
    ["npc say"]="Make your selected NPC speak this text in local say chat.",
    ["npc yell"]="Make your selected NPC yell this text.",
    ["npc textemote"]="Make your selected NPC perform a text emote.",
    ["npc whisper"]="Make your selected NPC whisper the text to the named player. Player lookup uses their unique first name.",
    ["gobject add"]="Create and save a gameobject at your current position and facing. Enter a gameobject template entry ID. The optional respawn delay is in seconds.",
    ["gobject add temp"]="Create a temporary gameobject at your position. Use Server help for the lifetime supported by your server.",
    ["gobject target"]="Find a nearby gameobject and report its database spawn ID in chat. Optionally filter by template entry or name. Use Builder for point-and-click positioning.",
    ["gobject near"]="List gameobjects near you, with their spawn IDs and positions. Distance is in yards.",
    ["gobject move"]="Move a saved gameobject by database spawn ID. Leave XYZ empty to move it to your position, or enter three coordinates separated by spaces. This saves its new position.",
    ["gobject turn"]="Rotate a saved gameobject. Angles are in radians, ordered Z, Y, X. Leave angles empty to use your facing. Use Builder for degree-based controls.",
    ["gobject delete"]="Permanently delete the gameobject identified by its database spawn ID. This ID identifies one placed object, not its template.",
    ["gobject activate"]="Activate the gameobject identified by its database spawn ID, such as opening a door.",
    ["go xyz"]="Teleport yourself to world coordinates. Z, map ID and facing (radians) are optional. My position fills every field with your current coordinates, map and facing.",
    ["go creature"]="Teleport to a saved NPC spawn by its database spawn ID.",
    ["go creature id"]="Teleport to a saved spawn of a creature template entry ID. If multiple spawns exist, the server chooses one and reports the ambiguity.",
    ["go gameobject"]="Teleport to a saved gameobject by its database spawn ID.",
    ["go gameobject id"]="Teleport to a saved spawn of a gameobject template entry ID.",
    ["go offset"]="Teleport yourself by an offset from your current world coordinates. X/Y/Z offsets are in yards; the facing offset is in radians.",
    ["gps"]="Inspect position, map, orientation and identifiers for your selected unit or the supplied object link. Results appear in chat.",
    ["tele"]="Teleport yourself to a named location in your server's teleport database.",
    ["tele add"]="Save your current position as a named teleport location. This adds a persistent server teleport entry.",
    ["tele del"]="Delete a named location from the server's teleport database.",
    ["appear"]="Teleport yourself to the named player. Leave the name blank to use your selected player. Forever command lookup uses the unique first name.",
    ["summon"]="Teleport the named player to you. Leave the name blank to use your selected player. Forever command lookup uses the unique first name.",
    ["kick"]="Disconnect the named player, with an optional reason. This does not ban their character or account.",
    ["ban character"]="Ban a character for a duration such as 30m, 1h or 7d, with a reason. Forever command lookup uses the unique first name.",
    ["die"]="Kill your selected unit. Check the target shown below before confirming.",
};
M.overrides={
    ["npc add temp"]={{name="loot mode",kind="choice",choice="loot / noloot",optional=true},{name="id",kind="integer",unsigned=true,bits=32,positive=true}},
    appear={{name="player",kind="player",optional=true}},
    summon={{name="player",kind="player",optional=true}},
    kick={{name="player",kind="player"},{name="reason",kind="text",optional=true}},
    ["ban character"]={{name="player",kind="player"},{name="duration",kind="duration"},{name="reason",kind="text"}},
};

-- Split only top-level commas: Variant/array/vector types contain nested commas.
function M.split(signature)
    local parts,start,depth,quoted={},1,0,false;
    for i=1,#signature do
        local c=signature:sub(i,i);
        if c=='"' and signature:sub(i-1,i-1)~='\\' then quoted=not quoted; end
        if not quoted then
            if c=="<" or c=="(" or c=="[" then depth=depth+1;
            elseif c==">" or c==")" or c=="]" then depth=depth-1;
            elseif c=="," and depth==0 then parts[#parts+1]=trim(signature:sub(start,i-1)); start=i+1; end
        end
    end
    if start<=#signature then parts[#parts+1]=trim(signature:sub(start)); end
    return parts;
end

function M.schema(entry)
    if M.overrides[entry.name] then return M.overrides[entry.name]; end
    if entry.legacy then return {{name="arguments",kind="text",optional=true,raw=true}}; end
    local fields={};
    for i,param in ipairs(M.split(entry.arguments)) do
        local name=param:match("([%w_]+)%s*$") or ("value"..i);
        local t=trim(param:sub(1,#param-#name)):gsub("const%s*&?",""):gsub("%s+","");
        local f={name=name,kind="token",optional=t:sub(1,9)=="Optional<",type=t};
        if f.optional then t=t:sub(10,-2); end
        if t=="Tail" or t=="WTail" or t:find("std::vector<",1,true) then f.kind="text"; if t:find("std::vector<",1,true) then f.optional=true; end
        elseif t:find("std::array<",1,true) then f.kind="array"; f.count=tonumber(t:match(",(%d+)>"));
        elseif t=="QuotedString" then f.kind="quoted";
        elseif t=="bool" then f.kind="bool";
        elseif t=="float" or t=="double" then f.kind="number";
        elseif t:match("^u?int%d+$") then f.kind="integer"; f.bits=tonumber(t:match("%d+")); f.unsigned=t:sub(1,1)=="u";
        elseif t:find("PlayerIdentifier",1,true) then f.kind="player"; f.allowGuid=true;
        elseif t:find("Hyperlink<player>",1,true) and t:find("std::string_view",1,true) then f.kind="player";
        elseif t=="CreatureSpawnId" or t=="GameObjectSpawnId" or t=="CreatureEntry" or t=="GameObjectEntry" or t=="ObjectGuid::LowType" then
            f.kind="integer"; f.unsigned=true; f.bits=(t=="CreatureEntry" or t=="GameObjectEntry") and 32 or 64; f.positive=t~="ObjectGuid::LowType";
        end
        if t:match('^EXACT_SEQUENCE%("') then f.kind="choice"; f.choice=t:match('"(.-)"'); end
        if t:find("Variant<",1,true) and not t:find("uint",1,true) and not t:find("std::",1,true) then
            local choices={}; for choice in t:gmatch('EXACT_SEQUENCE%("(.-)"%)') do choices[#choices+1]=choice; end
            if #choices>0 and not t:find("Hyperlink<",1,true) then f.kind="choice"; f.choice=table.concat(choices," / "); end
        end
        f.secret=name:lower():find("password",1,true) or name:lower():find("secret",1,true) or name:lower():find("token",1,true);
        fields[#fields+1]=f;
    end
    return fields;
end

function M.hint(f)
    if f.raw then return "Free-form syntax: check Server help"; end
    if f.kind=="choice" then return f.choice; end
    if f.kind=="bool" then return "on / off"; end
    if f.kind=="player" then return "Unique first name or display name"; end
    if f.kind=="array" then return (f.count or "Multiple").." space-separated numbers"; end
    if f.kind=="duration" then return "30m / 1h / 7d"; end
    if f.kind=="number" then return "Number; negative values allowed"; end
    if f.kind=="integer" then return f.positive and "Positive ID; no chat link needed" or (f.unsigned and "Non-negative whole number" or "Whole number"); end
    if f.kind=="text" then return "Text; spaces allowed"; end
    if f.kind=="quoted" then return "Text; quotes added automatically"; end
    return "One value; see Server help for choices";
end

function M.label(entry,f)
    if (entry.name=="npc add" or entry.name=="npc add temp") and f.name=="id" then return "Creature entry ID"; end
    local labels={spawnid="Spawn ID",spawnId="Spawn ID",spawnIdArg="Spawn ID",guidLow="Spawn ID",lowGuid="Spawn ID",objectId="Object entry / name",xyz="X Y Z",o="Facing (radians)",oz="Z (radians)",oy="Y (radians)",ox="X (radians)",
        item="Item ID",mc="Stock limit",it="Restock seconds",ec="Extended cost ID",bonusListIDs="Bonus IDs",pathid="Path ID"};
    if entry.name=="go xyz" and f.name=="id" then return "Map ID"; end
    return labels[f.name] or (f.name:gsub("Arg$",""):gsub("(%l)(%u)","%1 %2"):gsub("_"," "));
end

local function finite(value)
    if not value:match("^[+-]?[%d%.]+[eE]?[+-]?%d*$") then return; end
    local n=tonumber(value); return n and n==n and math.abs(n)<math.huge;
end
function M.encode(f,value)
    value=trim(value);
    if value:find("[%c|]") then return nil,"Use a single line without chat markup."; end
    if value=="" then if f.optional then return ""; end return nil,"Enter "..f.name.."."; end
    if f.kind=="number" and not finite(value) then return nil,"Enter a finite number for "..f.name.."."; end
    if f.kind=="integer" then
        if not value:match(f.unsigned and "^%d+$" or "^[+-]?%d+$") then return nil,"Enter a whole number for "..f.name.."."; end
        local digits=value:gsub("^[+-]",""):gsub("^0+",""); if digits=="" then digits="0"; end
        if f.positive and digits=="0" then return nil,"Enter a positive ID for "..f.name.."."; end
        local limit=f.bits==64 and (f.unsigned and "18446744073709551615" or (value:sub(1,1)=="-" and "9223372036854775808" or "9223372036854775807"))
            or tostring(f.unsigned and 2^(f.bits or 32)-1 or 2^((f.bits or 32)-1)-(value:sub(1,1)=="-" and 0 or 1));
        if #digits>#limit or (#digits==#limit and digits>limit) then return nil,f.name.." is outside its numeric range."; end
        value=value:sub(1,1)=="-" and digits~="0" and ("-"..digits) or digits;
    elseif f.kind=="array" then
        local count=0; for v in value:gmatch("%S+") do if not finite(v) then return nil,"Use space-separated numbers for "..f.name.."."; end count=count+1; end
        if f.count and count~=f.count then return nil,"Enter "..f.count.." numbers for "..f.name.."."; end
    elseif f.kind=="bool" then
        local v=value:lower(); if v~="on" and v~="off" and v~="1" and v~="0" then return nil,"Use on or off for "..f.name.."."; end value=v;
    elseif f.kind=="choice" then
        local found=false; for choice in f.choice:gmatch("[^ /]+") do if value:lower()==choice:lower() then value=choice; found=true; end end
        if not found then return nil,"Choose "..f.choice.." for "..f.name.."."; end
    elseif f.kind=="duration" then
        if not value:match("^[1-9]%d*[smhd]$") then return nil,"Use a duration such as 30m, 1h or 7d."; end
    elseif f.kind=="player" then
        if not (f.allowGuid and value:match("^%d+$")) then
            if value:find("[^%a\128-\255 ]") or value:find("  ") then return nil,"Enter a player first name or Forever display name."; end
            value=value:match("^%S+"); -- Forever stores the unique first name as its lookup key.
        end
    elseif f.kind=="quoted" then
        value='"'..value:gsub('\\','\\\\'):gsub('"','\\"')..'"';
    elseif f.kind=="token" and value:find("%s") then return nil,"Use one value for "..f.name.."; this parser does not accept quoted text.";
    end
    return value;
end

function M.build(entry,fields,values,redact)
    local parts={"."..entry.name}; local gap;
    for i,f in ipairs(fields) do
        local value,err=M.encode(f,values[i]);
        if not value then return nil,err,i; end
        if value=="" then
            -- Leading optional tags followed by required arguments are parsed
            -- by the core. Optional positional tails cannot contain holes.
            local requiredAfter=false; for j=i+1,#fields do if not fields[j].optional then requiredAfter=true; end end
            if not requiredAfter then gap=gap or f.name; end
        else
            if gap then return nil,"Fill "..gap.." before later optional values.",i; end
            parts[#parts+1]=redact and f.secret and "[hidden]" or value;
        end
    end
    local command=table.concat(parts," ");
    -- The core chooses child commands before a group's default handler and
    -- accepts abbreviations. Never label a different dispatched command as
    -- the selected action (for example, .additem set <id>).
    local first=parts[2] and parts[2]:match("^%S+"):lower();
    if first then
        for child in pairs(childWords[entry.name] or {}) do
            if child:sub(1,#first)==first then return nil,"These values select ."..entry.name.." "..child..". Choose that subcommand in the list.",1; end
        end
    end
    if #command>255 then return nil,"Command exceeds the 255-byte chat limit."; end
    return command;
end

function M.description(entry)
    if M.guides[entry.name] then return M.guides[entry.name]; end
    local help=GMGenie.CommandData and GMGenie.CommandHelpRevision==GMGenie.CommandData.revision
        and GMGenie.CommandHelp and GMGenie.CommandHelp[entry.name];
    if help then
        local body=trim(help:gsub("^[^\n]+\n?", ""));
        if body~="" then return body; end
    end
    return "Use the arguments below to run this command. Your server's help describes its behavior and defaults; request Server help before using unfamiliar commands.";
end

function M.isWorld(entry)
    return ({npc=true,gobject=true,go=true,tele=true,wp=true,lookup=true,gm=true})[entry.name:match("^%S+")]
        or entry.name=="gps" or entry.name=="additem" or entry.name=="appear" or entry.name=="summon";
end
function M.confirm(entry)
    return entry.name:find(" delete",1,true) or entry.name:find(" del",1,true)
        or entry.name:match("^ban ") or entry.name=="kick" or entry.name=="die"
        or entry.name:match("^server ") or entry.name:match("^account set ")
        or entry.name:match("^account create") or entry.name:match("^reset ")
        or entry.name=="npc set allowmove" or entry.name=="wp modify" or entry.name=="wp unload"
        or entry.name=="npc set movetype"
        or entry.name:match(" despawngroup$");
end
