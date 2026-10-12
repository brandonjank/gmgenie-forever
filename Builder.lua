-- Compact Forever world-building remote. GPL-3.0-or-later.
-- Commands verified against advocaite/TrinityCore 440d365e791baff1cdf555ed2179c71bd6ebd014.
GMGenie.Builder = {};
local B, U, S = GMGenie.Builder, GMGenieUI, GMGenie.Spawns;
B.mode = "object";
B.step, B.angle = 1, 15;
local TIMEOUT, FRESH = 8, 45;
local pi = math.pi;

local function number(value)
    value = tonumber(value);
    if value and value == value and math.abs(value) < 1000000 then return value; end
end
local function id(value)
    value = tostring(value or "");
    if value:match("^%d+$") and #value <= 16 and tonumber(value) > 0 then return value; end
end
local function fmt(value) return (string.format("%.6f", value):gsub(",", ".")); end
local function copy(t) local result={}; for k,v in pairs(t or {}) do result[k]=v; end return result; end
local function send(command) GMGenieForever.SendChatMessage(command, "GUILD"); end
local function link(spawn) return "|Hgameobject:" .. spawn .. "|h[Builder object]|h"; end
local function currentMap()
    if UnitPosition then local _,_,_,map = UnitPosition("player"); return map; end
end

function B.notice(text)
    B.message = text;
    if B.status then B.status:SetText(text); end
end

function B.ready()
    local e = B.entity;
    local map = currentMap();
    return B.mode == "object" and not B.pending and e and e.x and e.y and e.z and e.o and e.map
        and e.stamp and GetTime()-e.stamp < FRESH and (not map or map == e.map);
end

function B.update()
    if not B.window then return; end
    local object = B.mode == "object";
    local e = B.entity;
    local npc = UnitGUID("target");
    npc = npc and npc:match("^Creature%-") and not UnitIsPlayer("target");
    B.objectTab.selected=object; B.npcTab.selected=not object;
    U.paint(B.objectTab,"button",object); U.paint(B.npcTab,"button",not object);
    B.selection:SetText(object and (e and ((e.name or "Object") .. "  |cff94a8bd#" .. e.id .. "|r") or "No object selected")
        or (npc and (UnitName("target") or "NPC") or "Target an NPC in the world"));
    B.selectionHint:SetText(object and "Nearest selects a gameobject; a chat link selects its exact spawn."
        or "Stand at the new spot and face its direction. Move here saves both.");
    B.coords:SetText(object and e and e.x and string.format("X %.2f   Y %.2f   Z %.2f\nFacing %.1f deg   Map %s",e.x,e.y,e.z,math.deg(e.o),e.map)
        or (object and "Position unknown - select or refresh an object." or "NPC arrow controls are unavailable in this core."));
    B.nearest:SetEnabled(object and not B.pending);
    B.pick:SetText(object and "Select ID" or "Use target");
    B.pick:SetEnabled(not B.pending and (object or npc));
    B.refresh:SetEnabled(object and e ~= nil and not B.pending);
    B.spawnId:SetShown(object);
    B.moveHere:SetEnabled(object and not not B.ready() or (not object and npc and not B.pending));
    B.face:SetEnabled(not not B.ready());
    B.remove:SetEnabled(object and not not B.ready() or (not object and npc and not B.pending));
    B.undoButton:SetEnabled(not not (B.ready() and B.undo and B.undo.id == e.id));
    for _,button in ipairs(B.transforms) do button:SetEnabled(not not B.ready()); end
    B.spawnButton:SetEnabled(not B.pending);
    B.stepButton:SetText(tostring(B.step) .. " yd");
    B.angleButton:SetText(tostring(B.angle) .. " deg");
end

function B.invalidate(reason)
    B.pending, B.entity, B.undo, B.confirmation = nil, nil, nil, nil;
    if B.confirm then B.confirm:Hide(); end
    B.notice(reason or "Select an object to begin."); B.update();
end

function B.begin(kind, command, extra)
    if B.pending then B.notice("Wait for the current command to finish."); return false; end
    if IsLoggedIn and not IsLoggedIn() then B.notice("Enter the world before using the builder."); return false; end
    if B.confirm then B.confirm:Hide(); end
    local p = extra or {}; p.kind=kind; p.deadline=GetTime()+(p.silent and 1 or TIMEOUT);
    B.pending=p;
    B.notice("Waiting for server: " .. command:gsub("|H.-|h.-|h", "object link")); B.update();
    local ok,err=pcall(send,command);
    if not ok then B.fail("Unable to send command: "..tostring(err)); return false; end
    return true;
end

function B.selectNearest()
    if B.mode ~= "object" or B.pending then return false; end
    B.entity, B.undo = nil,nil;
    return B.begin("select", ".gobject target", {candidate={}});
end

function B.selectId(spawn, name)
    spawn=id(spawn);
    if not spawn or B.pending then B.notice("Enter a positive spawn ID (not a template entry ID)."); return false; end
    B.setMode("object"); B.entity, B.undo=nil,nil;
    return B.begin("inspect", ".gps " .. link(spawn), {candidate={id=spawn,name=name or "Object"}});
end

function B.refreshSelection()
    if B.pending or not B.entity then return false; end
    local e = B.entity;
    return B.begin("inspect", ".gps " .. link(e.id), {candidate={id=e.id,name=e.name},keepUndo=true});
end

function B.requireObject()
    if B.ready() then return B.entity; end
    B.notice("Select or refresh the object first; position expires after 45 seconds."); B.update();
end

function B.transform(command, property, undoing)
    local e = B.requireObject(); if not e then return false; end
    return B.begin("transform", command, {id=e.id,property=property,before=copy(e),undoing=undoing});
end

function B.nudge(forward, left, up)
    local e = B.requireObject(); if not e then return false; end
    local facing = GetPlayerFacing and number(GetPlayerFacing());
    if not facing then B.notice("Your facing is unavailable. Try again after entering the world."); return false; end
    -- World coordinates use radians: +Y is left when facing +X.
    local x = e.x + B.step*(math.cos(facing)*forward-math.sin(facing)*left);
    local y = e.y + B.step*(math.sin(facing)*forward+math.cos(facing)*left);
    local z = e.z + B.step*up;
    return B.transform(".gobject move "..e.id.." "..fmt(x).." "..fmt(y).." "..fmt(z), "move");
end

function B.rotate(direction)
    local e = B.requireObject(); if not e then return false; end
    local angle = (e.o + math.rad(B.angle)*direction) % (2*pi);
    return B.transform(".gobject turn "..e.id.." "..fmt(angle), "turn");
end

function B.moveToPlayer()
    if B.mode == "npc" then
        local guid=UnitGUID("target");
        if B.pending or not guid or not guid:match("^Creature%-") or UnitIsPlayer("target") then
            B.notice("Target a persistent NPC first."); return false;
        end
        return B.begin("npcMove", ".npc move", {guid=guid});
    end
    local e=B.requireObject(); if not e then return false; end
    return B.transform(".gobject move "..e.id,"move");
end

function B.facePlayer()
    local e=B.requireObject(); if not e then return false; end
    return B.transform(".gobject turn "..e.id,"turn");
end

function B.undoLast()
    local e=B.requireObject(); local previous=B.undo;
    if not e or not previous or e.id~=previous.id then return false; end
    local before=previous.before;
    local command=previous.property=="move" and (".gobject move "..e.id.." "..fmt(before.x).." "..fmt(before.y).." "..fmt(before.z))
        or (".gobject turn "..e.id.." "..fmt(before.o));
    return B.transform(command,previous.property,true);
end

function B.setMode(mode)
    if B.pending or (mode~="object" and mode~="npc") then return false; end
    B.mode=mode; B.confirmation=nil;
    if B.confirm then B.confirm:Hide(); end
    B.update(); return true;
end

function B.finishInspect(p)
    local e=p.candidate;
    if not (id(e.id) and e.map and e.x and e.y and e.z and e.o) then return; end
    e.stamp=GetTime(); B.entity=e; B.pending=nil;
    if not p.keepUndo then B.undo=nil; end
    B.notice("Ready. Arrows follow your facing; each click saves to the server."); B.update();
end

function B.fail(text)
    B.pending, B.undo=nil,nil;
    if B.entity then B.entity.stamp=nil; end
    B.notice(text .. " Refresh before editing again; commands are never retried automatically."); B.update();
end

function B.readSystemMessage(raw)
    local p=B.pending; if not p then return false; end
    if GetTime()>p.deadline then B.fail("Server response timed out."); return false; end
    -- Both whole multiline messages and individual lines are used by Forever.
    for line in (raw.."\n"):gmatch("([^\n]+)\n") do
        local text=GMGenieForever.PlainText(line);
        if p.kind=="select" or p.kind=="inspect" then
            local spawn,name=line:match("|Hgameobject:(%d+)[^|]*|h%[(.-)%]|h");
            local guid,entry=text:match("GUID:%s*(%d+)%s+ID:%s*(%d+)");
            if p.kind=="select" and spawn and guid and spawn==guid and id(guid) then
                p.candidate={id=guid,name=name,entry=entry};
            end
            local e=p.candidate;
            local map=text:match("^Map:%s*(%d+)") or text:match("MapId:%s*(%d+)");
            if map then e.map=tonumber(map); end
            local x,y,z=text:match("X:%s*([%d.eE+%-]+)%s+Y:%s*([%d.eE+%-]+)%s+Z:%s*([%d.eE+%-]+)");
            if x then e.x,e.y,e.z=number(x),number(y),number(z); end
            local o=text:match("Orientation:%s*([%d.eE+%-]+)");
            if o then e.o=number(o); end
            B.finishInspect(p);
            if not B.pending then return true; end
        elseif p.kind=="transform" then
            local spawn=line:match("|Hgameobject:(%d+)[^|]*|h");
            local acknowledged=spawn==p.id and ((p.property=="move" and text:match(" moved$"))
                or (p.property=="turn" and text:match(" turned to [%-+%d.eE]+$")));
            if acknowledged then
                B.pending=nil;
                if p.undoing then B.undo=nil;
                else B.undo={id=p.id,property=p.property,before=p.before}; end
                B.refreshSelection(); return true;
            end
        elseif p.kind=="delete" and text=="Game Object ("..p.id..") removed" then
            B.invalidate("Object deleted."); return true;
        elseif p.kind=="npcMove" and text=="Creature moved." then
            B.pending=nil; B.notice("NPC position and facing saved; it will respawn at your position."); B.update(); return true;
        elseif p.kind=="npcDelete" and text=="Creature Removed" then
            B.pending=nil; B.notice("NPC deleted."); B.update(); return true;
        elseif p.kind=="spawn" then
            local entry,name,spawn=text:match("^>> Add Game Object '(%d+)' %((.-)%) %(GUID: (%d+)%) added at");
            if p.mode=="object" and entry==p.entry and id(spawn) then
                B.pending=nil; B.selectId(spawn,name); return true;
            end
        end
        if text:find("Nothing found!",1,true) or text:lower():find("not found",1,true)
            or text:lower():find("does not exist",1,true) or text:lower():find("no gameobject",1,true)
            or text:lower():find("no creature",1,true) or text:lower():find("permission",1,true)
            or text:lower():find("syntax",1,true) or text:lower():find("invalid",1,true)
            or text:lower():find("same map",1,true) or text:lower():find("no such command",1,true) then
            B.fail("Server: "..text); return false;
        end
    end
    return false;
end

function B.tick()
    if B.pending and GetTime()>B.pending.deadline then
        if B.pending.silent then
            B.pending=nil; B.notice("Command sent. This core sends no success reply; verify the NPC in the world.");
        else B.fail("Server response timed out."); end
    end
    if B.entity and B.entity.stamp and GetTime()-B.entity.stamp>=FRESH and not B.pending then
        B.entity.stamp=nil; B.notice("Position expired. Refresh the object before editing.");
    end
    B.update();
end

function B.ask(action)
    if B.pending then return false; end
    local c={action=action,mode=B.mode};
    if action=="delete" then
        if B.mode=="object" then
            local e=B.requireObject(); if not e then return false; end
            c.id,c.name=e.id,e.name or "Object";
        else
            c.guid=UnitGUID("target"); c.name=UnitName("target");
            if not c.guid or not c.guid:match("^Creature%-") or UnitIsPlayer("target") then return false; end
        end
    else
        c.entry=id(B.entry:GetText());
        if not c.entry or tonumber(c.entry)>4294967295 then B.notice("Enter a valid template entry ID to spawn."); return false; end
    end
    B.confirmation=c;
    B.confirmText:SetText(action=="delete" and ("Permanently delete "..c.name..(c.id and (" (#"..c.id..")") or "").."?")
        or ("Permanently spawn "..B.mode.." entry "..c.entry.." at your current position?"));
    B.confirm:Show(); return true;
end

function B.confirmAction()
    local c=B.confirmation; B.confirmation=nil; B.confirm:Hide();
    if not c or B.pending or c.mode~=B.mode then return false; end
    if c.action=="delete" then
        if c.mode=="object" then
            local e=B.requireObject(); if not e or c.id~=e.id then return false; end
            return B.begin("delete",".gobject delete "..c.id,{id=c.id});
        end
        if c.guid~=UnitGUID("target") or UnitIsPlayer("target") then B.notice("NPC target changed. Select it again."); return false; end
        return B.begin("npcDelete",".npc delete");
    end
    return B.begin("spawn",(c.mode=="object" and ".gobject add " or ".npc add ")..c.entry,
        {entry=c.entry,mode=c.mode,silent=c.mode=="npc"});
end

function B.presetMenu(owner)
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle(B.mode=="object" and "Object presets" or "NPC presets");
        local source=GMGenie_SavedVars[B.mode=="object" and "objects" or "npcs"] or {};
        local names={}; for name in pairs(source) do names[#names+1]=name; end; table.sort(names);
        for _,name in ipairs(names) do local entry=source[name]; root:CreateButton(name,function() B.entry:SetText(tostring(entry)); end); end
        root:CreateDivider(); root:CreateButton("Manage presets",S.showOptions);
    end);
end

function B.create()
    if B.window then return; end
    local w=CreateFrame("Frame","GMGenie_Builder",UIParent,"BackdropTemplate");
    B.window=w; w:SetPoint("CENTER"); U.window(w,"Builder remote",304,654); w:Hide();
    B.objectTab=U.button(w,"Objects",12,-58,136,function() B.setMode("object"); end);
    B.npcTab=U.button(w,"NPCs",156,-58,136,function() B.setMode("npc"); end);
    local card=U.panel(w,12,-94,280,146);
    B.selection=U.label(card,"",10,-10,260);
    B.selection:SetHeight(18);
    B.selectionHint=U.label(card,"",10,-32,260,"GameFontHighlightSmall",true);
    B.spawnId=U.edit(card,"GMGenie_Builder_SpawnID",10,-66,100,26);
    U.tooltip(B.spawnId,"Spawn ID","An existing object's database GUID. Template entry IDs belong in the spawn field below.");
    B.pick=U.button(card,"Select ID",118,-66,76,function()
        if B.mode=="object" then B.selectId(B.spawnId:GetText()); B.spawnId:ClearFocus(); else B.update(); end
    end,nil,26);
    B.refresh=U.button(card,"Refresh",202,-66,68,B.refreshSelection,nil,26);
    B.nearest=U.button(card,"Nearest object",10,-104,260,B.selectNearest);
    U.tooltip(B.nearest,"Select nearest gameobject","Read-only selection. Gameobjects usually cannot be selected with the normal unit target. Use a chat link or spawn ID for an exact selection.");
    B.coords=U.label(w,"",18,-249,268,"GameFontHighlightSmall",true);
    U.label(w,"MOVE  /  relative to your facing",18,-291,268,"GameFontHighlightSmall",true);
    B.transforms={};
    local function transform(text,x,y,width,callback,tip)
        local b=U.button(w,text,x,y,width,callback,nil,34); B.transforms[#B.transforms+1]=b;
        if tip then U.tooltip(b,text,tip); end; return b;
    end
    transform("Forward",105,-314,94,function() B.nudge(1,0,0); end);
    transform("Left",12,-354,87,function() B.nudge(0,1,0); end);
    B.stepButton=U.button(w,"1 yd",105,-354,94,function(self)
        MenuUtil.CreateContextMenu(self,function(_,root)
            root:CreateTitle("Movement step");
            for _,step in ipairs({0.1,0.5,1,5,10}) do root:CreateButton(step.." yd",function() B.step=step; B.update(); end); end
        end);
    end,nil,34);
    transform("Right",205,-354,87,function() B.nudge(0,-1,0); end);
    transform("Back",105,-394,94,function() B.nudge(-1,0,0); end);
    transform("Up",12,-394,87,function() B.nudge(0,0,1); end);
    transform("Down",205,-394,87,function() B.nudge(0,0,-1); end);
    transform("Turn left",12,-438,87,function() B.rotate(1); end,"Rotate around the vertical axis. This core resets object pitch and roll when turning.");
    B.angleButton=U.button(w,"15 deg",105,-438,94,function(self)
        MenuUtil.CreateContextMenu(self,function(_,root)
            root:CreateTitle("Rotation step");
            for _,angle in ipairs({1,5,15,45,90}) do root:CreateButton(angle.." deg",function() B.angle=angle; B.update(); end); end
        end);
    end,nil,34);
    transform("Turn right",205,-438,87,function() B.rotate(-1); end);
    B.moveHere=U.button(w,"Move here",12,-482,136,B.moveToPlayer);
    B.face=U.button(w,"Face me",156,-482,136,B.facePlayer);
    U.tooltip(B.face,"Match my facing","Copies your orientation. This is a separate saved edit from Move here; object pitch and roll reset to zero.");
    B.undoButton=U.button(w,"Undo last edit",12,-516,136,B.undoLast);
    B.remove=U.button(w,"Delete...",156,-516,136,function() B.ask("delete"); end);
    B.entry=U.edit(w,"GMGenie_Builder_Entry",12,-558,90,28);
    U.tooltip(B.entry,"Template entry ID","Spawn a new object or NPC at your position. Existing object spawn IDs go in the selection card.");
    U.button(w,"Presets",110,-558,78,B.presetMenu);
    B.spawnButton=U.button(w,"Spawn...",196,-558,96,function() B.ask("spawn"); end);
    B.status=U.label(w,"",14,-599,276,"GameFontHighlightSmall",true);
    B.status:SetHeight(44);
    B.confirm=CreateFrame("Frame","GMGenie_Builder_Confirm",UIParent,"BackdropTemplate");
    B.confirm:SetPoint("CENTER"); U.window(B.confirm,"Confirm world edit",360,190);
    B.confirm:SetFrameStrata("FULLSCREEN_DIALOG");
    B.confirmText=U.label(B.confirm,"",18,-64,324);
    U.button(B.confirm,"Confirm",18,-142,156,B.confirmAction);
    U.button(B.confirm,"Cancel",186,-142,156,function() B.confirmation=nil; B.confirm:Hide(); end);
    B.confirm:HookScript("OnHide",function() B.confirmation=nil; end); B.confirm:Hide();
    w:HookScript("OnHide",function() B.confirm:Hide(); end);
    local elapsed=0;
    w:SetScript("OnUpdate",function(_,delta) elapsed=elapsed+delta; if elapsed>0.25 then elapsed=0; B.tick(); end end);
    B.events=CreateFrame("Frame");
    for _,event in ipairs({"PLAYER_TARGET_CHANGED","PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA"}) do B.events:RegisterEvent(event); end
    B.events:SetScript("OnEvent",function(_,event)
        if event~="PLAYER_TARGET_CHANGED" then B.invalidate("Location changed. Select the object again.");
        else if B.mode=="npc" and B.confirm then B.confirm:Hide(); end; B.update(); end
    end);
    B.notice("Select an object to begin. Edits save permanently."); B.update();
end

function B.open(spawn,name)
    B.create(); B.window:Show();
    if spawn then B.selectId(spawn,name); else B.update(); end
end
function B.toggle()
    B.create(); if B.window:IsShown() then B.window:Hide(); else B.open(); end
end

-- Keep the old macro/preset widgets loaded for existing saved build scripts.
-- Normal entry points now open the remote, never the old delete-nearest flow.
S.toggle=B.toggle;
S.targetObject=function() B.open(); B.selectNearest(); end;
SlashCmdList.SPAWNS=B.toggle;
local oldMenu=S.Hyperlink.loadMenu;
S.Hyperlink.loadMenu=function(self,level)
    if S.Hyperlink.type=="gameobject" then
        local info=UIDropDownMenu_CreateInfo(); info.notCheckable=true;
        info.text="Edit in Builder"; info.func=function() B.open(S.Hyperlink.id,S.Hyperlink.name); end;
        UIDropDownMenu_AddButton(info,level);
    end
    oldMenu(self,level);
end;
