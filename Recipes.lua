-- Saved world-building forms and guided examples. No scripts or batch sends. GPL-3.0.
GMGenie.Recipes={page=1,pageSize=12,mode="all",checked={},sent={},sessions={},draftSerial=0};
local R,M,U=GMGenie.Recipes,GMGenie.CommandForms,GMGenieUI;
local commands={}; for _,e in ipairs(GMGenie.CommandData.entries) do commands[e.name]=e; end
local function clone(value)
    if type(value)~="table" then return value; end
    local out={}; for k,v in pairs(value) do out[k]=clone(v); end return out;
end
local function trim(s) return tostring(s or ""):match("^%s*(.-)%s*$"); end
local function variable(key,label,required) return {var=key,label=label,required=required~=false}; end
local function step(title,command,values,note,target)
    return {title=title,command=command,values=values or {},note=note or "Check the server response before continuing.",target=target};
end
R.examples={
    {id="example-vendor-stock",name="Vendor: add stock",category="Vendors",summary="Target an existing vendor. Stock changes are saved on its template and affect every vendor using that entry.",variables={item="25",stock="0",restock="0"},steps={
        step("Inspect and bind your vendor","npc info",{},"Select the intended vendor, click Bind NPC, and inspect its entry/spawn in chat."),
        step("Add an item to the sale list","npc add item",{variable("item","Item entry ID"),variable("stock","Stock limit (0 = unlimited)"),variable("restock","Restock seconds"),"0",""},"Example item 25 is Worn Shortsword. Stock 0 is unlimited; for limited stock try 5 and restock 300 seconds. This edits all vendors using this template."),
    }},
    {id="example-vendor-place",name="Vendor: place and stock",category="Vendors",summary="Place an existing vendor template, select the new spawn, then edit its shared stock list. This does not create a new creature template.",variables={creature="54",item="25"},steps={
        step("Place the vendor at your feet","npc add",{variable("creature","Vendor creature entry")},"Stand at the intended spot and face the desired direction. Example 54 is Corina Steele, an existing weaponsmith template."),
        step("Select and inspect the new vendor","npc info",{},"Target the vendor you just placed, click Bind NPC, and verify its spawn in chat. Another spawn with the same name is not automatically selected."),
        step("Add unlimited stock","npc add item",{variable("item","Item entry ID"),"0","0","0",""},"Example 25 is Worn Shortsword. This changes the shared vendor template's stock, including existing spawns; it is not a private shop list for this one spawn."),
    }},
    {id="example-patrol-new",name="Patrol: create a new route",category="Patrols",summary="Create a unique path, walk its points, reload it, then assign it to a saved NPC. Copy the PathID from chat; no ID is guessed.",variables={path=""},steps={
        step("Create the first waypoint","wp add",{""},"Clear your target and stand at the first point. Run this once, then copy the server's PathID into the next step. With a selected NPC, the core may append to its existing path instead.","clear"),
        step("Append the next waypoint (repeat)","wp add",{variable("path","Path ID from chat")},"Enter the new PathID. Walk to the next point and run this step once per point. Repeat here until the route is complete; changing location does not send a command.","clear"),
        step("Reload the completed path","wp reload",{variable("path","Path ID")},"Load the new database path into the server cache before assigning it. The same Path ID is shared with the other steps."),
        step("Assign the route to your NPC","wp load",{variable("path","Path ID")},"Target the saved patrol NPC and click Bind NPC. Loading the path saves its assignment and starts waypoint movement; no extra movetype command is needed."),
        step("Show route markers","wp show",{"on",variable("path","Path ID")},"Show temporary waypoint markers and inspect the route. Check the NPC's movement before marking this step checked."),
        step("Hide route markers","wp show",{"off",variable("path","Path ID")},"Remove the route's visualization markers after inspection. The saved patrol path remains."),
    }},
    {id="example-patrol-extend",name="Patrol: extend an existing route",category="Patrols",summary="Append points to a known path. Editing a shared path affects every NPC assigned to it; use a new route when you need a separate patrol.",variables={path=""},steps={
        step("Append points (repeat while walking)","wp add",{variable("path","Existing Path ID")},"Enter the existing PathID from your server. Move to each new point and run this step once there; it appends instead of replacing the route.","clear"),
        step("Reload the edited route","wp reload",{variable("path","Path ID")},"Refresh the server path cache after adding the points."),
        step("Apply the route to the patrol NPC","wp load",{variable("path","Path ID")},"Select the intended saved NPC and click Bind NPC. This saves its path assignment and reinitializes waypoint movement."),
    }},
    {id="example-npc-place",name="Placement: stationary NPC",category="Placement",summary="Create a saved NPC at your position/facing, then keep it stationary. Example 68 is Stormwind City Guard; change the entry for your world.",variables={creature="68"},steps={
        step("Create the saved spawn","npc add",{variable("creature","Creature entry ID")},"Stand at the destination and face the intended direction. This creates a persistent spawn of an existing template, not a new template."),
        step("Keep the new NPC stationary","npc set movetype",{"","stay","nodel"},"Select the new spawn and click Bind NPC. stay makes it stationary; nodel preserves any assigned path while changing movement mode."),
        step("Inspect the saved NPC","npc info",{},"Verify the intended entry and spawn in chat. A sent command alone is not proof that the server saved the result."),
    }},
    {id="example-npc-move",name="Placement: move NPC here",category="Placement",summary="Move a selected saved NPC to your position and facing. Bind the intended NPC first; the change is permanent.",variables={},steps={
        step("Move the bound NPC to your feet","npc move",{""},"Bind the intended NPC, stand at the new location and face the desired direction. Leave spawn ID empty to use that selected NPC."),
        step("Inspect the moved spawn","npc info",{},"Verify the NPC's entry and database spawn in chat, and inspect its position in the world."),
    }},
    {id="example-object-place",name="Placement: saved gameobject",category="Placement",summary="Create an object from a template entry at your position and facing. Find the entry with lookup object; no example object ID is assumed.",variables={object=""},steps={
        step("Create the saved gameobject","gobject add",{variable("object","Object template entry"),""},"Enter a template entry from your server. Stand at the placement spot and face the desired direction. An object entry is different from its placed spawn ID."),
        step("Inspect nearby saved objects","gobject near",{"10"},"Read the nearby objects and spawn IDs in chat. Verify the new spawn by its position; the nearest matching name may be an older object."),
    }},
    {id="example-object-move",name="Placement: move and face object",category="Placement",summary="Move one gameobject by database spawn ID, then give it your facing. Both steps use the same spawn ID; this is not a template entry.",variables={spawn=""},steps={
        step("Move the object to your feet","gobject move",{variable("spawn","Object spawn ID"),""},"Enter the placed object's spawn ID. Leave XYZ empty to use your current position, or enter three world coordinates."),
        step("Face the object your direction","gobject turn",{variable("spawn","Object spawn ID"),"","",""},"Leave angles empty to use your facing. Explicit Z/Y/X angles use radians; verify the final placement in the world."),
    }},
    {id="example-npc-preview",name="Placement: temporary NPC preview",category="Placement",summary="Preview a creature at your position/facing without saving a world spawn. This does not convert an existing temporary NPC into a persistent one.",variables={creature="68"},steps={
        step("Spawn a temporary preview","npc add temp",{"noloot",variable("creature","Creature entry ID")},"Stand at the intended placement. The temporary NPC is not saved; it can remain alive until removed or the map/server unloads."),
    }},
};

function R.allowed(entry)
    if not entry then return false; end
    local root=entry.name:match("^%S+");
    if not ({npc=true,gobject=true,go=true,wp=true,lookup=true,tele=true,gps=true})[root] then return false; end
    if entry.name:match("^lookup player") or entry.name:match("^tele name") or entry.name=="tele group" then return false; end
    for _,f in ipairs(M.schema(entry)) do if f.secret then return false; end end
    return true;
end
local function stringValue(v,limit) return type(v)=="string" and #v<=limit and not v:find("[%c|]"); end

-- Copy only the bounded, declarative data we understand. Never evaluate saved text.
function R.copy(recipe)
    if type(recipe)~="table" or not stringValue(recipe.name,80) or trim(recipe.name)=="" or not stringValue(recipe.summary or "",400)
        or (recipe.variables~=nil and type(recipe.variables)~="table")
        or type(recipe.steps)~="table" or #recipe.steps<1 or #recipe.steps>20 then return nil,"Recipe needs a name and 1-20 steps."; end
    local out={id=recipe.id,name=trim(recipe.name),category=recipe.category or "Custom",summary=recipe.summary or "",variables={},steps={}};
    if not stringValue(out.category,40) or (out.id~=nil and not stringValue(out.id,80)) then return nil,"Invalid recipe metadata."; end
    local count=0;
    for key,value in pairs(recipe.variables or {}) do
        count=count+1;
        if count>32 or type(key)~="string" or #key>32 or not key:match("^[%w_]+$") or not stringValue(value,255) then return nil,"Invalid shared recipe field."; end
        out.variables[key]=value;
    end
    for _,s in ipairs(recipe.steps) do
        local e=type(s)=="table" and commands[s.command];
        if not R.allowed(e) or (s.signature~=nil and s.signature~=e.arguments) or not stringValue(s.title or "",100) or not stringValue(s.note or "",500) or type(s.values)~="table"
            or (s.target~=nil and s.target~="clear") then return nil,"Unsupported or invalid world-building step."; end
        local fields=M.schema(e);
        if #fields>6 then return nil,"This command's form needs a newer recipe editor."; end
        local item={command=e.name,signature=e.arguments,title=s.title or e.name,note=s.note or "",target=s.target,values={}};
        for i=1,#fields do
            local value=s.values[i] or "";
            if type(value)=="table" then
                if type(value.var)~="string" or not value.var:match("^[%w_]+$") or out.variables[value.var]==nil
                    or not stringValue(value.label or "",80) or (value.required~=nil and type(value.required)~="boolean") then return nil,"Invalid shared field binding."; end
                item.values[i]={var=value.var,label=value.label,required=value.required~=false};
            elseif stringValue(value,255) then item.values[i]=value;
            else return nil,"Use plain single-line argument values."; end
        end
        if #s.values>#fields then return nil,"Command arguments changed; review this recipe."; end
        out.steps[#out.steps+1]=item;
    end
    return out;
end

function R.preferences()
    if type(GMGenie_SavedVars.worldRecipes)~="table" then GMGenie_SavedVars.worldRecipes={version=1,nextID=1,recipes={}}; end
    local p=GMGenie_SavedVars.worldRecipes;
    if type(p.recipes)~="table" then p.recipes={}; end
    if type(p.nextID)~="number" or p.nextID<1 or p.nextID%1~=0 or p.nextID>1000000 then p.nextID=1; end
    return p;
end

function R.resolve(recipe,index)
    local s=recipe.steps[index]; if not s then return; end
    local fields,values={},{};
    for i,f in ipairs(M.schema(commands[s.command])) do
        fields[i]={}; for k,v in pairs(f) do fields[i][k]=v; end
        local binding=s.values[i];
        if type(binding)=="table" then
            values[i]=recipe.variables[binding.var];
            if binding.required then fields[i].optional=false; end
            fields[i].recipeLabel=binding.label; fields[i].shared=true;
            -- Waypoint path IDs must be positive even though the native type is uint32.
            if binding.var=="path" then fields[i].positive=true; end
        else values[i]=binding or ""; end
    end
    return commands[s.command],fields,values,s;
end

function R.targetPolicy(name,values,s)
    if s.target=="clear" then return "clear"; end
    if name=="wp add" then return trim(values[1])=="" and "clear" or "none"; end
    if name=="wp load" or name=="wp unload" or name=="wp modify" or (name=="wp show" and (values[1]=="info" or trim(values[2])=="")) then return "npc"; end
    if name=="npc move" or name=="npc delete" then return trim(values[1])~="" and "clear" or "npc"; end
    if name=="npc set movetype" and trim(values[1])~="" then return "none"; end
    if name:match("^npc ") and not ({["npc add"]=true,["npc add temp"]=true,["npc add move"]=true,["npc near"]=true,
        ["npc spawngroup"]=true,["npc despawngroup"]=true,["npc set allowmove"]=true})[name] then return "npc"; end
    return "none";
end

local positionCommands={["npc add"]=true,["npc add temp"]=true,["npc move"]=true,["gobject add"]=true,["gobject add temp"]=true,
    ["gobject move"]=true,["gobject turn"]=true,["wp add"]=true,["wp modify"]=true,["tele add"]=true};
function R.positionStamp()
    if not UnitPosition or not GetPlayerFacing then return; end
    local x,y,z,map=UnitPosition("player"); local o=GetPlayerFacing();
    if not x or not y or not z or not map or not o then return; end
    return string.format("%s:%.6f:%.6f:%.6f:%.6f",map,x,y,z,o);
end
function R.npcGUID()
    local guid=UnitGUID("target");
    return guid and not UnitIsPlayer("target") and (guid:match("^Creature%-") or guid:match("^Vehicle%-")) and guid or nil;
end
function R.plan()
    if not R.draft then return nil,"Choose a recipe."; end
    if IsLoggedIn and not IsLoggedIn() then return nil,"Enter the world before running a step."; end
    local e,fields,values,s=R.resolve(R.draft,R.stepIndex);
    local command,err=M.build(e,fields,values); if not command then return nil,err; end
    local policy=R.targetPolicy(e.name,values,s);
    if policy=="clear" and UnitGUID("target") then return nil,"Clear your target before this step. No existing NPC or path should be selected."; end
    if policy=="npc" and (not R.bound or R.bound.guid~=R.npcGUID()) then return nil,"Select the intended NPC and click Bind NPC. Keep that same NPC selected."; end
    local position="";
    if positionCommands[e.name] then position=R.positionStamp(); if not position then return nil,"Current world position is unavailable."; end end
    local readonly=e.name=="gps" or e.name=="npc info" or e.name=="npc near" or e.name=="gobject info" or e.name=="gobject near" or e.name=="gobject target" or e.name:match("^lookup ");
    return {command=command,policy=policy,guid=UnitGUID("target"),position=position,confirm=not readonly or not not M.confirm(e),index=R.stepIndex};
end

function R.bindTarget()
    local guid=R.npcGUID();
    if not guid then R.notice("Select an NPC first."); return; end
    if R.checkedTarget~=guid then
        for i in ipairs(R.draft.steps) do
            local e,_,values,s=R.resolve(R.draft,i);
            if R.targetPolicy(e.name,values,s)=="npc" then R.checked[i]=nil; R.sent[i]=nil; end
        end
    end
    R.checkedTarget=guid;
    R.bound={guid=guid,name=(GetUnitName and GetUnitName("target",true)) or UnitName("target") or "NPC"};
    R.confirmation=nil; R.update();
end

function R.execute()
    if not GMGenieForever.RequireActive() then return; end
    if not IsLoggedIn or not IsLoggedIn() then R.notice("Enter the world before running a recipe step."); return; end
    local p,err=R.plan(); if not p then R.confirmation=nil; R.update(); R.notice(err); return; end
    if p.confirm then
        local c=R.confirmation;
        if not c or c.command~=p.command or c.guid~=p.guid or c.position~=p.position or c.index~=p.index or GetTime()>c.deadline then
            p.deadline=GetTime()+10; R.confirmation=p; R.update();
            R.notice("Review the command, target and your location. Click Confirm step within 10 seconds."); return;
        end
    end
    R.confirmation=nil;
    R.sent[R.stepIndex]=nil; R.checked[R.stepIndex]=nil;
    local ok,result=pcall(GMGenieForever.SendChatMessage,p.command,"GUILD");
    if not ok or result==false then R.update(); R.notice("Unable to send this step. Check server compatibility."); return; end
    R.sent[R.stepIndex]=true;
    R.update();
    R.notice("Step sent. Check the server response and world result, then click I checked the result. Nothing runs next automatically.");
end

function R.markChecked()
    if not R.draft then return; end
    if not R.sent[R.stepIndex] then R.notice("Run this step and check its server result before marking it checked. Next also lets you skip a step."); return; end
    R.checked[R.stepIndex]=true;
    if R.stepIndex<#R.draft.steps then R.selectStep(R.stepIndex+1); else R.update(); R.notice("Recipe steps checked manually. No server success was inferred from sending commands."); end
end

function R.invalidateField(index,text)
    if R.loading or not R.draft then return; end
    local binding=R.draft.steps[R.stepIndex].values[index];
    if type(binding)=="table" then
        R.draft.variables[binding.var]=text;
        for j,s in ipairs(R.draft.steps) do for _,v in ipairs(s.values) do if type(v)=="table" and v.var==binding.var then R.checked[j]=nil; R.sent[j]=nil; end end end
    else R.draft.steps[R.stepIndex].values[index]=text; R.checked[R.stepIndex]=nil; R.sent[R.stepIndex]=nil; end
    R.confirmation=nil; R.dirty=true; R.update();
end

function R.save(asCopy)
    if not R.draft then return; end
    R.draft.name=trim(R.name:GetText()); R.draft.summary=R.summary:GetText();
    local recipe,err=R.copy(R.draft); if not recipe then R.notice(err); return; end
    local p=R.preferences(); local id=not asCopy and R.savedID or nil;
    if not id and #p.recipes>=100 then R.notice("You already have 100 saved recipes. Remove one before saving a new copy."); return; end
    for _,old in ipairs(p.recipes) do
        if old.id~=id and type(old.name)=="string" and old.name:lower()==recipe.name:lower() then R.notice("That recipe name already exists. Rename this copy or update the saved recipe."); return; end
    end
    if not id then
        repeat id="recipe-"..p.nextID; p.nextID=p.nextID+1; local found=false; for _,old in ipairs(p.recipes) do if old.id==id then found=true; end end until not found
    end
    recipe.id=id; recipe.category=recipe.category=="Custom" and "Custom" or recipe.category;
    local replaced=false; for i,old in ipairs(p.recipes) do if old.id==id then p.recipes[i]=recipe; replaced=true; break; end end
    if not replaced then p.recipes[#p.recipes+1]=recipe; end
    if R.draft.id then R.sessions[R.draft.id]=nil; end
    R.draft.id=id; R.savedID=id; R.dirty=false; R.refresh(); R.notice("Saved locally. Fields survive reloads; targets and progress are never saved.");
end

function R.deleteSaved()
    if not R.savedID then return; end
    local id=R.savedID; local p=R.preferences();
    for i,r in ipairs(p.recipes) do if r.id==id then table.remove(p.recipes,i); break; end end
    R.sessions[id]=nil; R.savedID=nil; R.draft.id=R.newDraftID(); R.dirty=true; R.refresh();
    R.notice("Removed the saved recipe. Its draft is still open and can be saved again. Nothing in the world was changed.");
end

function R.capture(entry,values,append)
    if not R.allowed(entry) then R.notice("Save NPC, object, waypoint, self-teleport, lookup or GPS forms as recipes. Account/player administration and credential forms are excluded."); return; end
    R.cacheDraft();
    local description=M.description(entry):match("^[^\n]+") or "";
    if not stringValue(description,500) then description="Review this saved command's arguments and target. Server help explains its behavior and defaults."; end
    local s=step("."..entry.name,entry.name,values,description);
    local recipe=append and R.draft or {id=R.newDraftID(),name="My "..entry.name,category="Custom",summary="A saved world-building command form.",variables={},steps={}};
    if append and #recipe.steps>=20 then R.notice("A recipe can contain at most 20 steps."); return; end
    recipe.steps[#recipe.steps+1]=s;
    local copied,err=R.copy(recipe); if not copied then recipe.steps[#recipe.steps]=nil; R.notice(err); return; end
    if not append then R.savedID=nil; R.bound=nil; R.checkedTarget=nil; end
    R.draft=copied; R.dirty=true; R.checked={}; R.sent={}; R.confirmation=nil;
    R.openDraft(#copied.steps);
end

function R.captureMenu(owner,entry,values)
    if not R.allowed(entry) then return; end
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle("Save command form");
        root:CreateButton("New recipe from this form",function() R.capture(entry,values,false); end);
        if R.draft then root:CreateButton("Append to "..R.draft.name,function() R.capture(entry,values,true); end); end
    end);
end

function R.notice(text)
    if R.status and R.window:IsShown() then R.status:SetText(text or ""); else GMGenie.showGMMessage(text); end
end

function R.newDraftID() R.draftSerial=R.draftSerial+1; return "draft-"..R.draftSerial; end
function R.cacheDraft()
    if not R.draft or not R.draft.id then return; end
    R.sessions[R.draft.id]={recipe=clone(R.draft),index=R.stepIndex,savedID=R.savedID,dirty=R.dirty,
        checked=clone(R.checked),sent=clone(R.sent),checkedTarget=R.checkedTarget};
end

function R.refresh()
    if not R.window then return; end
    R.cacheDraft();
    local list={}; local query=R.search:GetText():lower(); local words={};
    for word in query:gmatch("%S+") do words[#words+1]=word; end
    local function include(recipe,source)
        local cached=R.sessions[recipe.id]; recipe=cached and cached.recipe or recipe;
        if R.mode=="examples" and source~="example" or R.mode=="mine" and source=="example" then return; end
        local text=(recipe.name.." "..recipe.category.." "..recipe.summary):lower();
        for _,word in ipairs(words) do if not text:find(word,1,true) then return; end end
        list[#list+1]={recipe=recipe,source=source,dirty=cached and cached.dirty or false};
    end
    for _,recipe in ipairs(R.examples) do include(recipe,"example"); end
    R.invalidSaved=0;
    for i,recipe in ipairs(R.preferences().recipes) do
        if i>100 then R.invalidSaved=R.invalidSaved+(#R.preferences().recipes-100); break; end
        local copied=R.copy(recipe);
        if copied and type(copied.id)=="string" and copied.id:match("^recipe%-%d+$") then include(copied,"saved"); else R.invalidSaved=R.invalidSaved+1; end
    end
    for id,cached in pairs(R.sessions) do if id:match("^draft%-%d+$") then include(cached.recipe,"draft"); end end
    table.sort(list,function(a,b) return a.recipe.name:lower()==b.recipe.name:lower() and a.recipe.id<b.recipe.id or a.recipe.name:lower()<b.recipe.name:lower(); end);
    R.matches=list; local pages=math.max(1,math.ceil(#list/R.pageSize)); R.page=math.max(1,math.min(pages,R.page));
    for i,row in ipairs(R.rows) do
        row.record=list[(R.page-1)*R.pageSize+i]; row:SetShown(row.record~=nil);
        if row.record then
            local source=row.record.source=="example" and "Example" or row.record.source=="saved" and "Saved" or "Unsaved draft";
            row:SetText((row.record.dirty and "* " or "")..(row.record.recipe.name~="" and row.record.recipe.name:gsub("|","||") or "(Unnamed recipe)").."\n|cff94a8bd"..source.." / "..row.record.recipe.category.."|r");
            row.selected=R.draft and row.record.recipe.id==R.draft.id; U.paint(row,"button",row.selected);
        end
    end
    R.count:SetText(#list.." recipes / "..#R.examples.." bundled examples"..(R.invalidSaved>0 and (" / "..R.invalidSaved.." invalid saved entries skipped") or ""));
    R.pageLabel:SetText(R.page.." / "..pages); R.previous:SetEnabled(R.page>1); R.next:SetEnabled(R.page<pages);
    R.empty:SetShown(#list==0);
    for mode,tab in pairs(R.tabs) do tab.selected=R.mode==mode; U.paint(tab,"button",tab.selected); end
    if not R.draft and list[1] then R.choose(list[1]); else R.update(); end
end

function R.choose(record)
    if not record then return; end
    R.cacheDraft();
    local cached=R.sessions[record.recipe.id];
    local copied,err;
    if cached then copied=clone(cached.recipe); else copied,err=R.copy(record.recipe); end
    if not copied then R.notice(err); return; end
    R.draft=copied; R.savedID=cached and cached.savedID or (record.source=="saved" and copied.id or nil);
    R.dirty=cached and cached.dirty or false; R.bound=nil; R.checked=clone(cached and cached.checked or {}); R.sent=clone(cached and cached.sent or {});
    R.checkedTarget=cached and cached.checkedTarget; R.confirmation=nil;
    R.openDraft(cached and cached.index or 1);
end

function R.openDraft(index)
    if not GMGenieForever.RequireActive() then return; end
    if not R.window then R.create(); end
    R.loading=true; R.name:SetText(R.draft.name); R.summary:SetText(R.draft.summary); R.loading=false;
    U.visit("recipes");
    R.selectStep(index or 1); R.refresh();
end

function R.selectStep(index)
    if not R.draft then return; end
    R.stepIndex=math.max(1,math.min(#R.draft.steps,index)); R.confirmation=nil; R.loading=true;
    local e,fields,values=R.resolve(R.draft,R.stepIndex); R.entry=e; R.fields=fields;
    for i,input in ipairs(R.inputs) do
        local f=fields[i]; input:ClearFocus(); input:SetText(f and values[i] or ""); input:SetShown(f~=nil); input.label:SetShown(f~=nil); input.picker:Hide();
        if f then
            local cols=math.min(3,#fields); local width=(592-(cols-1)*8)/cols;
            local x=18+((i-1)%cols)*(width+8); local y=-350-math.floor((i-1)/cols)*64;
            input:ClearAllPoints(); input:SetPoint("TOPLEFT",x,y-20); input:SetWidth(width-(M.catalogKind(e,f) and 54 or 0));
            input.picker:ClearAllPoints(); input.picker:SetPoint("TOPLEFT",x+width-48,y-20); input.picker:SetShown(M.catalogKind(e,f)~=nil);
            input.label:ClearAllPoints(); input.label:SetPoint("TOPLEFT",x,y); input.label:SetWidth(width);
            input.label:SetText((f.recipeLabel or M.label(e,f))..(f.optional and " (optional)" or " *"));
            input.placeholder:SetText(M.hint(f)); input.placeholder:SetWidth(input:GetWidth()-20);
        end
    end
    R.loading=false; R.update();
end

function R.update()
    if R.loading or not R.window or not R.draft or not R.stepIndex then return; end
    local e,fields,values,s=R.resolve(R.draft,R.stepIndex);
    R.commandName:SetText("."..e.name); R.stepNote:SetText(s.note);
    R.stepButton:SetText(R.stepIndex.." / "..#R.draft.steps.."  "..s.title);
    R.stepPrevious:SetEnabled(R.stepIndex>1); R.stepNext:SetEnabled(R.stepIndex<#R.draft.steps);
    local count=0; for i in ipairs(R.draft.steps) do if R.checked[i] then count=count+1; end end
    R.origin:SetText((R.savedID and "Saved recipe" or R.draft.id:match("^example%-") and "Bundled example - save a personal copy" or "Unsaved draft")
        .." / "..R.draft.category.." / "..count.." manually checked"..(R.dirty and " / unsaved changes" or ""));
    for i in ipairs(fields) do R.inputs[i].placeholder:SetShown(R.inputs[i]:GetText()==""); end
    local preview=M.build(e,fields,values); R.copyLoading=true; R.preview:SetText(preview or ("."..e.name)); R.copyLoading=false;
    local p,err=R.plan(); R.run:SetEnabled(p~=nil); R.run:SetText(R.confirmation and "Confirm step" or p and p.confirm and "Review step" or "Run step");
    R.check:SetEnabled(not not R.sent[R.stepIndex]);
    local policy=R.targetPolicy(e.name,values,s); local positioned=positionCommands[e.name];
    R.context:SetText((policy=="npc" and ("Bound NPC: "..(R.bound and R.bound.name or "none")) or policy=="clear" and "Requires no selected target." or "No NPC target binding needed.")
        ..(positioned and "\nUses your position/facing unless coordinates or angles are supplied." or ""));
    R.bind:SetShown(policy=="npc");
    R.noArguments:SetShown(#fields==0);
    R.updateSaved:SetEnabled(R.savedID~=nil); R.delete:SetEnabled(R.savedID~=nil);
    R.status:SetText(err or (R.confirmation and "Review the preview, target and location, then click Confirm step." or "Ready. Opening, editing and saving recipes sends no commands."));
end

function R.stepsMenu(owner)
    if not R.draft then return; end
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle("Recipe steps"); root:SetScrollMode(320);
        for i,s in ipairs(R.draft.steps) do
            root:CreateRadio((R.checked[i] and "[checked] " or "")..i..". "..s.title,function(value) return value==R.stepIndex; end,R.selectStep,i);
        end
    end);
end

function R.editStep(kind)
    if not R.draft then return; end
    local i=R.stepIndex; local steps=R.draft.steps;
    if kind=="up" and i>1 then steps[i],steps[i-1]=steps[i-1],steps[i]; i=i-1;
    elseif kind=="down" and i<#steps then steps[i],steps[i+1]=steps[i+1],steps[i]; i=i+1;
    elseif kind=="remove" and #steps>1 then table.remove(steps,i);
    else return; end
    R.checked={}; R.sent={}; R.dirty=true; R.selectStep(i);
end

function R.optionsMenu(owner)
    if not R.draft then return; end
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle("Edit this draft");
        if R.stepIndex>1 then root:CreateButton("Move step earlier",function() R.editStep("up"); end); end
        if R.stepIndex<#R.draft.steps then root:CreateButton("Move step later",function() R.editStep("down"); end); end
        if #R.draft.steps>1 then root:CreateButton("Remove this step",function() R.editStep("remove"); end); end
        if R.savedID then
            root:CreateButton("Revert to saved fields",function()
                for _,recipe in ipairs(R.preferences().recipes) do if recipe.id==R.savedID then
                    R.sessions[R.savedID]=nil; R.dirty=false; R.draft=nil; R.choose({recipe=recipe,source="saved"}); break;
                end end
            end);
        else
            for _,example in ipairs(R.examples) do if example.id==R.draft.id then
                root:CreateButton("Reset example fields",function() R.sessions[example.id]=nil; R.dirty=false; R.draft=nil; R.choose({recipe=example,source="example"}); end);
            end end
        end
    end);
end

function R.create()
    local window=CreateFrame("Frame","GMGenie_Recipes",UIParent,"BackdropTemplate"); R.window=window;
    window:SetPoint("CENTER"); window:SetFrameLevel(window:GetFrameLevel()+60); U.window(window,"World-building recipes",1000,720);
    U.label(window,"Reusable forms and guided examples. Review and run one step at a time; check the server result before continuing.",18,-62,964,"GameFontHighlightSmall",true);
    R.tabs={};
    for i,option in ipairs({{"all","All recipes"},{"mine","My recipes"},{"examples","Examples"}}) do
        R.tabs[option[1]]=U.button(window,option[2],18+(i-1)*110,-88,102,function() R.mode=option[1]; R.page=1; R.refresh(); end);
    end
    R.search=U.edit(window,"GMGenie_Recipes_Search",18,-128,318,30);
    local placeholder=U.label(R.search,"Search recipe names and notes...",10,-8,298,"GameFontHighlightSmall",true);
    R.search:SetScript("OnTextChanged",function(self) placeholder:SetShown(self:GetText()==""); R.page=1; R.refresh(); end);
    local list=U.panel(window,18,-172,318,412); R.rows={};
    list:EnableMouseWheel(true); list:SetScript("OnMouseWheel",function(_,delta) R.page=R.page+(delta>0 and -1 or 1); R.refresh(); end);
    for i=1,R.pageSize do
        local row=U.button(list,"",8,-8-(i-1)*33,302,function(self) R.choose(self.record); end,nil,32);
        local text=row:GetFontString(); text:ClearAllPoints(); text:SetPoint("LEFT",8,0); text:SetWidth(286); text:SetHeight(28); text:SetJustifyH("LEFT");
        row:SetScript("OnEnter",function(self)
            if not self.record then return; end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(self.record.recipe.name);
            GameTooltip:AddLine(self.record.recipe.summary,0.65,0.73,0.83,true); GameTooltip:Show();
        end);
        row:SetScript("OnLeave",function() GameTooltip:Hide(); end); R.rows[i]=row;
    end
    R.empty=U.label(list,"No recipes match. Try All recipes or another search.",18,-120,282,"GameFontHighlight",true);
    U.button(window,"Save copy",18,-604,102,function() R.save(true); end);
    R.updateSaved=U.button(window,"Update saved",126,-604,102,function() R.save(false); end);
    R.delete=U.button(window,"Delete saved",234,-604,102,R.deleteSaved);
    R.count=U.label(window,"",18,-646,318,"GameFontHighlightSmall",true); R.count:SetHeight(26);
    R.previous=U.button(window,"Previous",18,-680,92,function() R.page=R.page-1; R.refresh(); end);
    R.pageLabel=U.label(window,"",130,-688,100,"GameFontHighlightSmall",true);
    R.next=U.button(window,"Next",244,-680,92,function() R.page=R.page+1; R.refresh(); end);
    local detail=U.panel(window,354,-88,628,610); R.detail=detail;
    U.label(detail,"RECIPE NAME",18,-8,592,"GameFontHighlightSmall",true);
    R.name=U.edit(detail,"GMGenie_Recipes_Name",18,-28,592,30); R.name:SetMaxLetters(80);
    R.name:SetScript("OnTextChanged",function(self) if not R.loading and R.draft then R.draft.name=self:GetText(); R.dirty=true; R.update(); end end);
    R.origin=U.label(detail,"",18,-66,592,"GameFontHighlightSmall",true);
    R.summary=U.edit(detail,"GMGenie_Recipes_Note",18,-86,592,30); R.summary:SetMaxLetters(400);
    R.summary:SetScript("OnTextChanged",function(self) if not R.loading and R.draft then R.draft.summary=self:GetText(); R.dirty=true; end end);
    R.summary:HookScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("Recipe note"); GameTooltip:AddLine(self:GetText(),0.65,0.73,0.83,true); GameTooltip:Show(); end);
    R.summary:HookScript("OnLeave",function() GameTooltip:Hide(); end);
    R.stepPrevious=U.button(detail,"Previous",18,-130,70,function() R.selectStep(R.stepIndex-1); end);
    R.stepButton=U.button(detail,"",96,-130,342,R.stepsMenu);
    R.stepNext=U.button(detail,"Next",446,-130,70,function() R.selectStep(R.stepIndex+1); end);
    U.button(detail,"Edit step",524,-130,86,R.optionsMenu);
    R.commandName=U.label(detail,"",18,-174,470,"GameFontNormalLarge");
    U.button(detail,"Server help",502,-170,108,function()
        if R.entry then GMGenie.Commands.help(R.entry); R.notice("Server help requested in chat. This does not run the step."); end
    end);
    R.stepNote=U.label(detail,"",18,-210,592,"GameFontHighlightSmall"); R.stepNote:SetHeight(74); R.stepNote:SetJustifyV("TOP");
    R.context=U.label(detail,"",18,-292,462,"GameFontHighlightSmall",true); R.context:SetHeight(32); R.context:SetJustifyV("TOP");
    R.bind=U.button(detail,"Bind NPC",484,-288,126,R.bindTarget);
    U.label(detail,"* Required. Shared fields carry across steps. Saving a recipe does not run it.",18,-330,592,"GameFontHighlightSmall",true);
    R.inputs={};
    for i=1,6 do
        local input=U.edit(detail,"GMGenie_Recipes_Argument"..i,18,-370,182,30);
        input:SetMaxLetters(255);
        input.label=U.label(detail,"",18,-350,182,"GameFontHighlightSmall"); input.label:SetHeight(18);
        input.placeholder=U.label(input,"",10,-8,162,"GameFontHighlightSmall",true); input.placeholder:SetHeight(16);
        input:SetScript("OnTextChanged",function(self) R.invalidateField(i,self:GetText()); end);
        input:SetScript("OnEnterPressed",function(self) self:ClearFocus(); end);
        input:SetScript("OnTabPressed",function(self)
            self:ClearFocus(); if #R.fields==0 then return; end
            local delta=IsShiftKeyDown and IsShiftKeyDown() and -1 or 1;
            R.inputs[(i-1+delta)%#R.fields+1]:SetFocus();
        end);
        input:HookScript("OnEnter",function(self)
            local f=R.fields and R.fields[i]; if not f then return; end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(f.recipeLabel or M.label(R.entry,f));
            GameTooltip:AddLine(M.hint(f)..(f.shared and "\nThis value is shared with other recipe steps." or ""),0.65,0.73,0.83,true); GameTooltip:Show();
        end);
        input:HookScript("OnLeave",function() GameTooltip:Hide(); end);
        input.picker=U.button(detail,"Find",18,-370,48,function() R.pickField(i); end); input.picker:Hide(); R.inputs[i]=input;
    end
    R.noArguments=U.label(detail,"No arguments. Check the bound NPC and review this step's instructions.",18,-382,592,"GameFontHighlight",true);
    U.label(detail,"EXACT COMMAND PREVIEW",18,-482,592,"GameFontHighlightSmall",true);
    R.preview=U.edit(detail,"GMGenie_Recipes_Preview",18,-502,592,30);
    R.preview:SetScript("OnTextChanged",function() if not R.copyLoading then R.update(); end end);
    R.preview:SetScript("OnEditFocusGained",function(self) self:HighlightText(); end);
    R.run=U.button(detail,"Review step",18,-546,126,R.execute);
    R.check=U.button(detail,"I checked the result",152,-546,176,R.markChecked);
    U.button(detail,"Add step...",336,-546,126,function()
        R.cacheDraft(); GMGenie.Commands.open();
        GMGenie.showGMMessage("Choose and fill a command, then Save form > Append to your open recipe.");
    end);
    U.button(detail,"Builder",470,-546,140,function() if GMGenie.Spawns then GMGenie.Spawns.toggle(); end end);
    R.status=U.label(detail,"",18,-582,592,"GameFontHighlightSmall",true); R.status:SetHeight(26); R.status:SetJustifyV("TOP");
    window:RegisterEvent("PLAYER_TARGET_CHANGED");
    window:SetScript("OnEvent",function() R.confirmation=nil; if window:IsShown() then R.update(); end end);
    window:HookScript("OnHide",function()
        R.cacheDraft(); R.confirmation=nil; R.bound=nil;
        R.name:ClearFocus(); R.summary:ClearFocus(); for _,input in ipairs(R.inputs) do input:ClearFocus(); end
    end);
    U.workspace("recipes",window,function() R.cacheDraft(); return {id=R.draft and R.draft.id,index=R.stepIndex}; end,function(state)
        local cached=state.id and R.sessions[state.id];
        if cached then R.choose({recipe=cached.recipe,source=cached.savedID and "saved" or "draft"}); end
        R.refresh();
    end);
    window:Hide();
end

function R.pickField(index)
    if not R.draft then return; end
    local draft,stepIndex=R.draft,R.stepIndex;
    local e,fields=R.resolve(draft,stepIndex); local kind=M.catalogKind(e,fields[index]);
    if not kind then return; end
    R.cacheDraft();
    GMGenie.Catalog.pick(kind,fields[index].recipeLabel or M.label(e,fields[index]),function(id)
        if R.draft and R.draft.id==draft.id and R.stepIndex==stepIndex then R.inputs[index]:SetText(tostring(id)); end
    end);
end

function R.open(query)
    if not GMGenieForever.RequireActive() then return; end
    if not R.window then R.create(); end
    U.visit("recipes");
    if query~=nil then R.search:SetText(query); R.mode="all"; end
    R.refresh(); if R.draft then R.openDraft(R.stepIndex); end
end

SLASH_GMGENIERECIPES1="/gmrecipes";
GMGenieForever.RegisterSlash("GMGENIERECIPES",function(query) R.open(query); end);
