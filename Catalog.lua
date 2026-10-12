-- Forever-only content browser. GPL-3.0.
GMGenie.Catalog = {};
local C=GMGenie.Catalog;
local U=GMGenieUI;
local data=GMGenie.CatalogData;
C.kind="items"; C.mode="all"; C.page=1; C.pageSize=16;
C.loaded={}; C.loading={}; C.entries={}; C.byID={};
local types={items={[0]="Consumables",[1]="Containers",[2]="Weapons",[3]="Gems",[4]="Armor",[5]="Reagents",[6]="Projectiles",[7]="Trade goods",[9]="Recipes",[10]="Money",[11]="Quivers",[12]="Quest items",[13]="Keys",[15]="Miscellaneous",[16]="Glyphs",[18]="WoW tokens",[19]="Profession tools"},
    creatures={[0]="Unknown",[1]="Beasts",[2]="Dragonkin",[3]="Demons",[4]="Elementals",[5]="Giants",[6]="Undead",[7]="Humanoids",[8]="Critters",[9]="Mechanical",[10]="Unspecified",[11]="Totems",[12]="Non-combat pets",[13]="Gas clouds"}};
local qualities={[0]="Poor",[1]="Common",[2]="Uncommon",[3]="Rare",[4]="Epic",[5]="Legendary",[6]="Artifact",[7]="Heirloom",[8]="WoW token"};
local ranks={[0]="Normal",[1]="Elite",[2]="Rare elite",[3]="Boss",[4]="Rare"};
local slots={[0]="No equipment slot",[1]="Head",[2]="Neck",[3]="Shoulder",[4]="Shirt",[5]="Chest",[6]="Waist",[7]="Legs",[8]="Feet",[9]="Wrist",[10]="Hands",[11]="Finger",[12]="Trinket",[13]="One-hand",[14]="Shield",[15]="Ranged",[16]="Back",[17]="Two-hand",[18]="Bag",[19]="Tabard",[20]="Robe",[21]="Main hand",[22]="Off hand",[23]="Held in off-hand",[24]="Ammo",[25]="Thrown",[26]="Ranged",[28]="Relic"};
local colors={[0]="9d9d9d",[1]="ffffff",[2]="1eff00",[3]="0070dd",[4]="a335ee",[5]="ff8000",[6]="e6cc80",[7]="00ccff",[8]="00ccff"};

function C.preferences()
    GMGenie_SavedVars.catalog=GMGenie_SavedVars.catalog or {favorites={},recent={}};
    local prefs=GMGenie_SavedVars.catalog;
    prefs.favorites=prefs.favorites or {}; prefs.recent=prefs.recent or {};
    return prefs;
end

function C.key(entry) return C.kind..":"..entry.id; end
function C.typeName(entry) return types[C.kind][entry.type] or "Other"; end
function C.remember(entry)
    local recent=C.preferences().recent; local key=C.key(entry);
    for i=#recent,1,-1 do if recent[i]==key then table.remove(recent,i); end end
    table.insert(recent,1,key); while #recent>40 do table.remove(recent); end
end

function C.decode(line,kind)
    local fields={}; for value in (line.."\t"):gmatch("([^\t]*)\t") do fields[#fields+1]=value; end
    local entry={id=tonumber(fields[1]),name=fields[2],type=tonumber(fields[4]) or 0};
    if kind=="items" then
        entry.quality=tonumber(fields[3]) or 1; entry.subclass=tonumber(fields[5]);
        entry.slot=tonumber(fields[6]) or 0; entry.level=tonumber(fields[7]) or 0;
        entry.required=tonumber(fields[8]) or 0; entry.display=tonumber(fields[9]) or 0;
        entry.icon=fields[10]; entry.petDisplay=tonumber(fields[11]) or 0;
        entry.available=tonumber(fields[12]);
    else
        entry.type=tonumber(fields[3]) or 10; entry.rank=tonumber(fields[4]) or 0;
        entry.minlevel=tonumber(fields[5]) or 0; entry.maxlevel=tonumber(fields[6]) or 0;
        entry.tag=fields[7] or ""; entry.flags=tonumber(fields[8]) or 0; entry.models={};
        for id in (fields[9] or ""):gmatch("%d+") do entry.models[#entry.models+1]=tonumber(id); end
        entry.available=tonumber(fields[10]);
    end
    entry.search=(entry.name.." "..entry.id.." "..(entry.tag or "")):lower();
    return entry;
end

function C.load(kind)
    if C.loaded[kind] or C.loading[kind] then return; end
    C.loading[kind]=true; C.entries[kind]={}; C.byID[kind]={};
    local chunks=data.chunks[kind]; local index=1;
    local function step()
        for line in chunks[index]:gmatch("[^\n]+") do
            local entry=C.decode(line,kind);
            C.entries[kind][#C.entries[kind]+1]=entry; C.byID[kind][entry.id]=entry;
        end
        index=index+1;
        if index<=#chunks then C_Timer.After(0,step); else
            C.loaded[kind]=true; C.loading[kind]=false;
            if C.kind==kind and C.window then C.refresh(); end
        end
    end
    step();
end

function C.accept(entry,tokens)
    if C.typeFilter~=nil and entry.type~=C.typeFilter then return false; end
    if C.rankFilter~=nil and (C.kind=="items" and entry.quality or entry.rank)~=C.rankFilter then return false; end
    if C.slotFilter~=nil and entry.slot~=C.slotFilter then return false; end
    if C.roleFilter=="vendor" and math.floor(entry.flags/128)%2~=1 then return false; end
    if C.roleFilter=="trainer" and math.floor(entry.flags/16)%2~=1 then return false; end
    if C.roleFilter=="quest" and math.floor(entry.flags/2)%2~=1 then return false; end
    local key=C.key(entry); local prefs=C.preferences();
    if C.mode=="favorites" and not prefs.favorites[key] then return false; end
    if C.mode=="recent" then
        local found=false; for _,value in ipairs(prefs.recent) do if value==key then found=true; break; end end
        if not found then return false; end
    end
    for _,token in ipairs(tokens) do
        if #tokens==1 and token:match("^%d+$") then if tostring(entry.id)~=token then return false; end
        elseif not entry.search:find(token,1,true) then return false; end
    end
    return true;
end

function C.refresh(query)
    if query~=nil then C.page=1; end
    if not C.window then return; end
    C.pending=nil; C.confirm:Hide();
    local tokens={}; for token in C.query:GetText():lower():gmatch("%S+") do tokens[#tokens+1]=token; end
    C.matches={};
    if C.loaded[C.kind] then
        for _,entry in ipairs(C.entries[C.kind]) do if C.accept(entry,tokens) then C.matches[#C.matches+1]=entry; end end
        if C.mode=="recent" then
            local order={}; for i,key in ipairs(C.preferences().recent) do order[key]=i; end
            table.sort(C.matches,function(a,b) return order[C.key(a)]<order[C.key(b)]; end);
        end
    end
    local pages=math.max(1,math.ceil(#C.matches/C.pageSize)); C.page=math.max(1,math.min(pages,C.page));
    local selection;
    for i,row in ipairs(C.rows) do
        local entry=C.matches[(C.page-1)*C.pageSize+i]; row.entry=entry; row:SetShown(entry~=nil);
        if entry then
            local icon=C.kind=="items" and entry.icon~="" and "|TInterface\\Icons\\"..entry.icon..":18|t " or "";
            local color=C.kind=="items" and (colors[entry.quality] or "ffffff") or "e8eff8";
            row:SetText(icon.."|cff"..color..entry.name.."|r");
            if C.selected==entry then selection=entry; end
        end
    end
    C.count:SetText(C.loaded[C.kind] and (#C.matches.." results / "..data.counts[C.kind].." Forever "..C.kind) or "Loading offline catalog...");
    C.empty:SetShown(C.loaded[C.kind] and #C.matches==0);
    C.pageLabel:SetText(C.page.." / "..pages); C.previous:SetEnabled(C.page>1); C.next:SetEnabled(C.page<pages);
    C.itemsTab.selected=C.kind=="items"; U.paint(C.itemsTab,"button",C.itemsTab.selected);
    C.creaturesTab.selected=C.kind=="creatures"; U.paint(C.creaturesTab,"button",C.creaturesTab.selected);
    C.modeButton:SetText(C.mode=="all" and "All entries" or C.mode=="favorites" and "Favorites" or "Recently viewed");
    C.typeButton:SetText(C.typeFilter~=nil and (types[C.kind][C.typeFilter] or "Other") or "All types");
    C.rankButton:SetText(C.rankFilter~=nil and ((C.kind=="items" and qualities or ranks)[C.rankFilter] or "Other") or (C.kind=="items" and "All qualities" or "All ranks"));
    C.slotButton:SetText(C.kind=="items" and (slots[C.slotFilter] or "All slots") or (C.roleFilter or "All roles"));
    C.select(selection or C.matches[(C.page-1)*C.pageSize+1]);
end

function C.resetFilters()
    C.typeFilter=nil; C.rankFilter=nil; C.slotFilter=nil; C.roleFilter=nil; C.page=1; C.mode="all";
    C.query:SetText(""); C.refresh();
end

function C.setKind(kind)
    C.kind=kind; C.selected=nil; C.resetFilters(); C.load(kind);
end

function C.filterMenu(owner,which)
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle(which=="type" and "Content type" or which=="rank" and (C.kind=="items" and "Item quality" or "Creature rank") or C.kind=="items" and "Equipment slot" or "NPC role");
        local field=which=="type" and "typeFilter" or which=="rank" and "rankFilter" or C.kind=="items" and "slotFilter" or "roleFilter";
        local function choose(value) C[field]=value; C.page=1; C.refresh(); end
        root:CreateRadio("All",function() return C[field]==nil; end,function() choose(nil); end);
        local options=which=="type" and types[C.kind] or which=="rank" and (C.kind=="items" and qualities or ranks) or C.kind=="items" and slots or {vendor="Vendor",trainer="Trainer",quest="Quest giver"};
        local keys={}; for key in pairs(options) do keys[#keys+1]=key; end; table.sort(keys);
        for _,key in ipairs(keys) do root:CreateRadio(options[key],function(value) return C[field]==value; end,choose,key); end
        root:SetScrollMode(400);
    end);
end

function C.modeMenu(owner)
    MenuUtil.CreateContextMenu(owner,function(_,root)
        for _,option in ipairs({{"all","All entries"},{"favorites","Favorites"},{"recent","Recently viewed"}}) do
            root:CreateRadio(option[2],function(value) return C.mode==value; end,function(value) C.mode=value; C.page=1; C.refresh(); end,option[1]);
        end
    end);
end

function C.toggleFavorite()
    if not C.selected then return; end
    local favorites=C.preferences().favorites; local key=C.key(C.selected);
    favorites[key]=not favorites[key] or nil; C.refresh();
end

-- PlayerModel and DressUpModel remain available on the Forever client. Calls
-- that depend on the asset/client build are guarded and have a visible fallback.
local function modelCall(model,method,...)
    if not model or type(model[method])~="function" then return false; end
    local ok,result=pcall(model[method],model,...); return ok and result~=false;
end

function C.fitDistance(model)
    -- The native model camera needs extra distance in a wide, short viewport.
    -- Keep a little space around the silhouette, including idle animations.
    local width,height=model:GetWidth(),model:GetHeight();
    if not width or not height or width<=0 or height<=0 then return 1.25; end
    return 1.25*math.max(1,width/height);
end

function C.camera()
    local model=C.activeModel; if not model then return; end
    -- Portrait zoom can reset camera state; apply it before our full-body fit.
    modelCall(model,"SetPortraitZoom",0);
    if not modelCall(model,"SetRotation",C.facing or 0.5) then modelCall(model,"SetFacing",C.facing or 0.5); end
    modelCall(model,"SetCamDistanceScale",C.fitDistance(model)*(C.distance or 1));
end

function C.resetCamera()
    C.facing=0.5; C.distance=1;
    modelCall(C.activeModel,"SetPosition",0,0,0);
    C.camera();
end
function C.rotate(delta) C.facing=(C.facing or 0.5)+delta; C.camera(); end
function C.zoom(delta) C.distance=math.max(0.25,math.min(3,(C.distance or 1)+delta)); C.camera(); end

function C.preview(entry,retry)
    C.creatureModel:Hide(); C.itemModel:Hide(); C.activeModel=nil;
    C.icon:Hide();
    for _,button in ipairs(C.viewButtons) do button:SetEnabled(false); end
    C.modelNote:SetText(""); C.variant:SetShown(false); C.modelLoaded=false;
    C.previewToken=(C.previewToken or 0)+1; local token=C.previewToken;
    if not entry then C.modelNote:SetText("Select an entry to preview it."); return; end
    if C.kind=="items" then C.icon:SetTexture("Interface\\Icons\\"..(entry.icon~="" and entry.icon or "INV_Misc_QuestionMark")); C.icon:Show(); end
    local ok=false;
    if C.kind=="creatures" or entry.petDisplay>0 then
        C.activeModel=C.creatureModel; modelCall(C.activeModel,"ClearModel");
        local displays=entry.models or {entry.petDisplay}; C.variantIndex=math.min(C.variantIndex or 1,math.max(1,#displays));
        local display=displays[C.variantIndex];
        if display then ok=modelCall(C.activeModel,"SetDisplayInfo",display); end
        if not ok and C.kind=="creatures" then ok=modelCall(C.activeModel,"SetCreature",entry.id); end
        C.variant:SetShown(#displays>1); C.variant:SetText("Appearance "..C.variantIndex.." / "..#displays);
    elseif entry.display>0 and entry.slot>0 and entry.slot~=18 and entry.slot~=24 and entry.slot~=28 then
        C.activeModel=C.itemModel; modelCall(C.activeModel,"ClearModel");
        ok=modelCall(C.activeModel,"SetUnit","player");
        modelCall(C.activeModel,"Undress");
        ok=modelCall(C.activeModel,"TryOn","item:"..entry.id) and ok;
        if not retry and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(entry.id); end
    end
    if ok then
        C.icon:Hide(); C.activeModel:Show(); C.resetCamera();
        for _,button in ipairs(C.viewButtons) do button:SetEnabled(true); end
        C.modelNote:SetText(C.kind=="items" and entry.petDisplay==0 and "Equipment preview on your character. Drag to rotate; scroll to zoom." or "Drag to rotate; scroll to zoom.");
        C_Timer.After(3,function()
            if token==C.previewToken and not C.modelLoaded and C.activeModel then
                local success,file=pcall(function() return C.activeModel:GetModelFileID(); end);
                if not success or not file or file==0 then
                    C.activeModel:Hide(); C.icon:SetShown(C.kind=="items"); C.modelNote:SetText("This model is not available in your client.");
                    for _,button in ipairs(C.viewButtons) do button:SetEnabled(false); end
                end
            end
        end);
    else C.modelNote:SetText("No 3D appearance for this entry.\nItems such as materials, recipes and consumables use an icon and tooltip."); end
end

function C.select(entry)
    local changed=C.selected~=entry; C.selected=entry;
    C.pending=nil; C.confirm:Hide();
    for _,row in ipairs(C.rows) do row.selected=entry~=nil and row.entry==entry; U.paint(row,"button",row.selected); end
    C.add:SetShown(C.kind=="items"); C.quantity:SetShown(C.kind=="items"); C.quantityLabel:SetShown(C.kind=="items");
    C.temporary:SetShown(C.kind=="creatures"); C.persistent:SetShown(C.kind=="creatures");
    C.add:SetEnabled(entry~=nil); C.temporary:SetEnabled(entry~=nil); C.persistent:SetEnabled(entry~=nil); C.favorite:SetEnabled(entry~=nil);
    C.copy:SetText(entry and tostring(entry.id) or "");
    C.url:SetText(entry and ("https://www.wowhead.com/forever/"..(C.kind=="items" and "item=" or "npc=")..entry.id) or "");
    C.name:SetText(entry and entry.name or "No matching entries");
    C.favorite:SetText(entry and C.preferences().favorites[C.key(entry)] and "Unfavorite" or "Favorite");
    if not entry then C.description:SetText(""); C.preview(nil); return; end
    local availability=entry.available==0 and "\nNot present in the bundled reference core snapshot." or "";
    if C.kind=="items" then
        C.description:SetText((qualities[entry.quality] or "Item").." / "..C.typeName(entry).." / "..(slots[entry.slot] or "Other slot").."\nItem level "..entry.level.." / Requires level "..entry.required);
        C.actionNote:SetText("Adds to your inventory regardless of your target. Server RBAC and bag space apply.");
    else
        local level=entry.minlevel>=9999 and "??" or (entry.minlevel==entry.maxlevel and tostring(entry.minlevel) or entry.minlevel.."-"..entry.maxlevel);
        C.description:SetText(C.typeName(entry).." / "..(ranks[entry.rank] or "Normal").." / Level "..level..(entry.tag~="" and ("\n"..entry.tag) or ""));
        C.actionNote:SetText("Spawns at your current position and facing. Temporary spawns are not saved; persistent spawns are saved in the world database.");
    end
    C.description:SetText(C.description:GetText()..availability);
    if changed then C.variantIndex=1; C.remember(entry); C.preview(entry); end
end

function C.addItem()
    local entry=C.selected; if C.kind~="items" or not entry then return; end
    local count=tonumber(C.quantity:GetText());
    if not count or count~=math.floor(count) or count<1 or count>1000 then GMGenie.showGMMessage("Enter a whole quantity from 1 to 1000."); return; end
    local name=UnitName("player");
    if not name or name:find("[^%a\128-\255%-]") then GMGenie.showGMMessage("Your character name is not available yet."); return; end
    GMGenieForever.SendChatMessage(".additem to "..name.." "..entry.id.." "..count,"GUILD");
    C.actionNote:SetText("Requested "..count.." x "..entry.name.." for "..name..". Check the server response in chat.");
end

function C.spawnTemporary()
    if C.kind~="creatures" or not C.selected then return; end
    GMGenieForever.SendChatMessage(".npc add temp noloot "..C.selected.id,"GUILD");
    C.actionNote:SetText("Requested a temporary "..C.selected.name.." at your position. Check the world and server response in chat.");
end

function C.askPersistent()
    if C.kind~="creatures" or not C.selected then return; end
    C.pending=C.selected;
    C.confirmText:SetText("Save "..C.selected.name.." ("..C.selected.id..") as a persistent spawn at your current position and facing?\n\nThis creature will remain after server restarts."); C.confirm:Show();
end

function C.spawnPersistent()
    local entry=C.pending; C.pending=nil; C.confirm:Hide();
    if C.kind~="creatures" or not entry or entry~=C.selected then return; end
    GMGenieForever.SendChatMessage(".npc add "..entry.id,"GUILD");
    C.actionNote:SetText("Requested a persistent "..entry.name.." at your position. Check the world and server response in chat.");
end

function C.itemTooltip(owner,entry)
    if C.kind=="items" and entry then
        GameTooltip:SetOwner(owner,"ANCHOR_RIGHT"); GameTooltip:SetHyperlink("item:"..entry.id); GameTooltip:Show();
    end
end

function C.stepSelection(delta)
    if #C.matches==0 then return; end
    local index=1; for i,entry in ipairs(C.matches) do if C.selected==entry then index=i; break; end end
    index=math.max(1,math.min(#C.matches,index+delta)); C.page=math.ceil(index/C.pageSize); C.refresh(); C.select(C.matches[index]);
end

function C.create()
    local window=CreateFrame("Frame","GMGenie_Catalog",UIParent,"BackdropTemplate"); C.window=window;
    window:SetFrameLevel(window:GetFrameLevel()+50);
    window:SetPoint("CENTER"); U.window(window,"Forever content catalog",1050,750);
    C.itemsTab=U.button(window,"Items",18,-62,120,function() C.setKind("items"); end);
    C.creaturesTab=U.button(window,"NPCs & monsters",148,-62,158,function() C.setKind("creatures"); end);
    C.modeButton=U.button(window,"All entries",318,-62,152,C.modeMenu);
    U.label(window,"Offline Forever snapshot / "..data.date,494,-70,520,"GameFontHighlightSmall",true);
    C.query=U.edit(window,"GMGenie_Catalog_Search",18,-104,914,32);
    C.placeholder=U.label(C.query,"Search by name, exact ID or NPC title...",10,-10,880,"GameFontHighlightSmall",true);
    C.query:SetScript("OnTextChanged",function(self)
        C.placeholder:SetShown(self:GetText()=="");
        C.queryToken=(C.queryToken or 0)+1; local token=C.queryToken;
        C_Timer.After(0.15,function() if token==C.queryToken then C.refresh(self:GetText()); end end);
    end);
    C.query:SetScript("OnKeyDown",function(_,key) if key=="DOWN" then C.stepSelection(1); elseif key=="UP" then C.stepSelection(-1); end end);
    U.tooltip(C.query,"Search the Forever catalog","Search by name, exact ID or NPC title. Every word must match. Up/Down selects a result.");
    U.button(window,"Reset",944,-104,88,C.resetFilters,nil,32);
    C.typeButton=U.button(window,"All types",18,-148,172,function(self) C.filterMenu(self,"type"); end);
    C.rankButton=U.button(window,"All qualities",200,-148,172,function(self) C.filterMenu(self,"rank"); end);
    C.slotButton=U.button(window,"All slots",382,-148,172,function(self) C.filterMenu(self,"slot"); end);
    U.label(window,"Hover an item for its in-game tooltip.",576,-156,456,"GameFontHighlightSmall",true);
    local list=U.panel(window,18,-190,396,460); list:EnableMouseWheel(true);
    list:SetScript("OnMouseWheel",function(_,delta) C.page=C.page+(delta>0 and -1 or 1); C.refresh(); end);
    C.rows={};
    for index=1,C.pageSize do
        local row=U.button(list,"",8,-8-(index-1)*27.5,380,function(self) C.select(self.entry); end,nil,27);
        local text=row:GetFontString(); text:ClearAllPoints(); text:SetPoint("LEFT",8,0); text:SetWidth(364); text:SetJustifyH("LEFT");
        row:HookScript("OnEnter",function(self) C.itemTooltip(self,self.entry); end);
        row:HookScript("OnLeave",function() GameTooltip:Hide(); end); C.rows[index]=row;
    end
    C.empty=U.label(list,"No matches. Try another search or reset the filters.",22,-130,350,"GameFontHighlight",true);
    C.count=U.label(window,"Loading offline catalog...",18,-664,396,"GameFontHighlightSmall",true);
    C.previous=U.button(window,"Previous",18,-687,100,function() C.page=C.page-1; C.refresh(); end,nil,24);
    C.pageLabel=U.label(window,"",142,-693,130,"GameFontHighlightSmall",true);
    C.next=U.button(window,"Next",314,-687,100,function() C.page=C.page+1; C.refresh(); end,nil,24);
    local detail=U.panel(window,430,-190,602,460); C.detail=detail;
    C.name=U.label(detail,"",18,-16,460,"GameFontNormalLarge");
    C.favorite=U.button(detail,"Favorite",482,-10,102,C.toggleFavorite);
    C.description=U.label(detail,"",18,-48,566,"GameFontHighlightSmall",true);
    local preview=U.panel(detail,18,-92,566,242); C.modelPanel=preview;
    C.icon=preview:CreateTexture(nil,"ARTWORK"); C.icon:SetSize(72,72); C.icon:SetPoint("CENTER");
    C.modelNote=U.label(detail,"",18,-342,566,"GameFontHighlightSmall",true);
    for _,kind in ipairs({"creatureModel","itemModel"}) do
        local model=CreateFrame(kind=="creatureModel" and "PlayerModel" or "DressUpModel",nil,preview);
        model:SetPoint("TOPLEFT",1,-1); model:SetSize(564,240); model:EnableMouse(true); model:EnableMouseWheel(true);
        model:SetScript("OnMouseDown",function(self) C.dragX=GetCursorPosition(); self.dragging=true; end);
        model:SetScript("OnMouseUp",function(self) self.dragging=false; end);
        model:SetScript("OnHide",function(self) self.dragging=false; end);
        model:SetScript("OnUpdate",function(self) if self.dragging then local x=GetCursorPosition(); C.rotate((x-C.dragX)*0.015); C.dragX=x; end end);
        model:SetScript("OnMouseWheel",function(_,delta) C.zoom(-delta*0.1); end);
        model:SetScript("OnModelLoaded",function(self) if self==C.activeModel then C.modelLoaded=true; C.camera(); end end);
        model:SetScript("OnSizeChanged",function(self) if self==C.activeModel then C.camera(); end end);
        C[kind]=model; model:Hide();
    end
    C.viewButtons={
        U.button(detail,"Rotate left",18,-392,106,function() C.rotate(-0.4); end,nil,24),
        U.button(detail,"Rotate right",132,-392,106,function() C.rotate(0.4); end,nil,24),
        U.button(detail,"Reset view",246,-392,106,C.resetCamera,nil,24),
    };
    C.variant=U.button(detail,"Appearance",360,-392,224,function()
        if C.selected then C.variantIndex=(C.variantIndex % #C.selected.models)+1; C.preview(C.selected); end
    end,nil,24);
    U.label(detail,"ID",18,-433,24,"GameFontHighlightSmall",true);
    C.copy=U.edit(detail,"GMGenie_Catalog_ID",42,-424,84,26);
    C.copy:SetScript("OnEditFocusGained",function(self) self:HighlightText(); end);
    C.url=U.edit(detail,"GMGenie_Catalog_URL",138,-424,446,26);
    C.url:SetScript("OnEditFocusGained",function(self) self:HighlightText(); end);
    C.quantityLabel=U.label(window,"Qty",430,-671,30,"GameFontHighlightSmall",true);
    C.quantity=U.edit(window,"GMGenie_Catalog_Quantity",462,-662,64,30); C.quantity:SetText("1");
    C.add=U.button(window,"Add to my inventory",538,-662,216,C.addItem,nil,30);
    C.temporary=U.button(window,"Spawn temporary",430,-662,200,C.spawnTemporary,nil,30);
    C.persistent=U.button(window,"Spawn persistent...",642,-662,200,C.askPersistent,nil,30);
    U.tooltip(C.temporary,"Temporary spawn","Uses .npc add temp noloot at your position. This creature is not saved to the world database. It can stay alive until removed or the map/server unloads.");
    U.tooltip(C.persistent,"Persistent spawn","Uses .npc add at your position and facing, saving a world spawn. You will confirm the chosen entry before sending it.");
    C.actionNote=U.label(window,"",430,-698,602,"GameFontHighlightSmall",true);
    -- Confirmation is internal to the browser and is invalidated by selection,
    -- filters, tab changes or closing the catalog.
    C.confirm=U.panel(detail,24,-140,554,170); C.confirm:SetFrameLevel(detail:GetFrameLevel()+20);
    C.confirmText=U.label(C.confirm,"",18,-18,518,"GameFontHighlight");
    U.button(C.confirm,"Save persistent spawn",18,-126,226,C.spawnPersistent);
    U.button(C.confirm,"Cancel",256,-126,128,function() C.pending=nil; C.confirm:Hide(); end);
    C.confirm:Hide(); window:HookScript("OnHide",function() C.pending=nil; C.confirm:Hide(); C.creatureModel:Hide(); C.itemModel:Hide(); end);
    window:RegisterEvent("ITEM_DATA_LOAD_RESULT");
    window:SetScript("OnEvent",function(_,event,id,success)
        if event=="ITEM_DATA_LOAD_RESULT" and success and C.kind=="items" and C.selected and C.selected.id==id and window:IsShown() then C.preview(C.selected,true); end
    end);
    window:Hide();
end

function C.open(query,kind)
    if not GMGenieForever.RequireActive() then return; end
    if not C.window then C.create(); end
    if kind then C.kind=kind; C.resetFilters(); end
    C.window:Show(); C.load(C.kind);
    if query~=nil then C.query:SetText(query); end
    C.refresh(); if C.selected then C.preview(C.selected); end
end

SLASH_GMGENIECATALOG1="/gmcatalog";
GMGenieForever.RegisterSlash("GMGENIECATALOG",function(query) C.open(query); end);
