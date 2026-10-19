-- Modern command workspace for GM Genie Forever. GPL-3.0.
GMGenie.Commands = { page=1, pageSize=18, matches={}, mode="all", category="all", context="all" };
local C=GMGenie.Commands;
C.drafts={};
local data=GMGenie.CommandData;
local U=GMGenieUI;
local M=GMGenie.CommandForms;
local categories,categoryCounts={},{};
local byName={};
local searchText={};
for _,entry in ipairs(data.entries) do
    byName[entry.name]=entry;
    searchText[entry.name]=(entry.name.." "..entry.arguments.." "..entry.permission.." "..M.description(entry)):lower();
    local category=entry.name:match("^%S+");
    if not categoryCounts[category] then categories[#categories+1]=category; categoryCounts[category]=0; end
    categoryCounts[category]=categoryCounts[category]+1;
end
table.sort(categories);

function C.preferences()
    GMGenie_SavedVars=GMGenie_SavedVars or {};
    GMGenie_SavedVars.commandBrowser=GMGenie_SavedVars.commandBrowser or {};
    local prefs=GMGenie_SavedVars.commandBrowser;
    prefs.favorites=prefs.favorites or {}; prefs.recent=prefs.recent or {};
    return prefs;
end

function C.search(query)
    local words,matches={},{};
    local prefs=C.preferences();
    local recentOrder={};
    for index,name in ipairs(prefs.recent) do recentOrder[name]=index; end
    for word in (query or ""):lower():gmatch("%S+") do words[#words+1]=word; end
    for _,entry in ipairs(data.entries) do
        local found=(C.category=="all" or entry.name:match("^%S+")==C.category)
            and (C.mode=="all" or (C.mode=="world" and M.isWorld(entry)) or (C.mode=="favorites" and prefs.favorites[entry.name]) or (C.mode=="recent" and recentOrder[entry.name]))
            and (C.context=="all" or (C.context=="console" and entry.console) or (C.context=="ingame" and not entry.console));
        local text=searchText[entry.name];
        for _,word in ipairs(words) do if not text:find(word,1,true) then found=false; break; end end
        if found then matches[#matches+1]=entry; end
    end
    local phrase=table.concat(words," ");
    local function rank(entry)
        if phrase~="" and entry.name==phrase then return 0; end
        if phrase~="" and entry.name:sub(1,#phrase)==phrase then return 1; end
        return 2;
    end
    table.sort(matches,function(a,b)
        local ar,br=rank(a),rank(b);
        if ar~=br then return ar<br; end
        if C.mode=="recent" then return recentOrder[a.name]<recentOrder[b.name]; end
        return a.name<b.name;
    end);
    return matches;
end

function C.remember(entry)
    local recent=C.preferences().recent;
    for index=#recent,1,-1 do if recent[index]==entry.name then table.remove(recent,index); end end
    table.insert(recent,1,entry.name);
    while #recent>20 do table.remove(recent); end
end

function C.help(entry)
    if entry then C.remember(entry); GMGenieForever.SendChatMessage(".help "..entry.name,"GUILD"); end
end

function C.toggleFavorite(entry)
    if not entry then return; end
    local favorites=C.preferences().favorites;
    favorites[entry.name]=not favorites[entry.name] or nil;
    C.refresh(C.query:GetText());
end

function C.updateRows()
    local favorites=C.preferences().favorites;
    for _,row in ipairs(C.rows) do
        row.selected=row.entry and C.selected and row.entry.name==C.selected.name;
        U.paint(row,"panel",row.selected);
        if row.entry then row.star:SetText(favorites[row.entry.name] and "*" or "+"); end
    end
end

function C.select(entry,record)
    if not entry then return; end
    local changed=not C.selected or C.selected.name~=entry.name;
    if changed then C.cacheForm(); end
    C.selected=entry;
    if record~=false then C.remember(entry); end
    C.heading:SetText("."..entry.name);
    C.usage:SetText(entry.usage);
    C.arguments:SetText(entry.arguments=="" and "Arguments: none" or "C++ handler arguments, in order:\n\n"..entry.arguments);
    local description=M.description(entry):gsub("\n+"," ");
    C.note:SetText(#description>310 and description:sub(1,307).."..." or description);
    C.access:SetText((entry.console and "CONSOLE + IN-GAME" or "IN-GAME ONLY").."    /    RBAC "..entry.permissionId);
    C.technical:SetText(entry.permission.."\n"..entry.handler.."\nForever "..data.revision:sub(1,12));
    C.source:SetText("https://github.com/advocaite/TrinityCore/blob/"..data.revision.."/"..entry.source.."#L"..entry.line);
    C.source:ClearFocus();
    C.favorite:SetText(C.preferences().favorites[entry.name] and "Remove favorite" or "Save favorite");
    if C.saveRecipe then C.saveRecipe:SetEnabled(GMGenie.Recipes and GMGenie.Recipes.allowed(entry) or false); end
    if changed or not C.fields then C.loadForm(entry); end
    C.updateForm();
    C.updateRows();
end

function C.refresh(query)
    if query~=nil then C.matches=C.search(query); C.page=1; C.preferences().query=query; end
    local pages=math.max(1,math.ceil(#C.matches/C.pageSize));
    C.page=math.max(1,math.min(C.page,pages));
    local selection;
    for index,row in ipairs(C.rows) do
        local entry=C.matches[(C.page-1)*C.pageSize+index]; row.entry=entry;
        if entry then
            row:SetText("."..entry.name); row:Show();
            if C.selected and entry.name==C.selected.name then selection=entry; end
        else row:Hide(); end
    end
    C.count:SetText(#C.matches.." results  /  "..#data.entries.." commands");
    C.pageLabel:SetText(C.page.." / "..pages);
    C.previous:SetEnabled(C.page>1); C.next:SetEnabled(C.page<pages);
    for mode,tab in pairs(C.tabs) do tab.selected=C.mode==mode; U.paint(tab,"button",tab.selected); end
    C.categoryButton:SetText(C.category=="all" and "All categories" or "."..C.category);
    C.contextButton:SetText(({all="Any context",console="Console allowed",ingame="In-game only"})[C.context]);
    C.empty:SetShown(#C.matches==0);
    if C.matches[1] then
        C.detail:Show(); C.select(selection or C.matches[(C.page-1)*C.pageSize+1],false);
    else C.selected=nil; C.detail:Hide(); C.updateRows(); end
end

function C.setMode(mode)
    if mode~="all" and mode~="world" and mode~="favorites" and mode~="recent" then return; end
    C.mode=mode; C.refresh(C.query:GetText());
end

function C.resetFilters()
    C.mode="all"; C.category="all"; C.context="all";
    C.query:SetText(""); C.refresh("");
end

function C.categoryMenu(owner)
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle("Command category"); root:SetScrollMode(320);
        local function selected(value) return C.category==value; end
        local function choose(value) C.category=value; C.refresh(C.query:GetText()); end
        root:CreateRadio("All categories",selected,choose,"all"); root:CreateDivider();
        for _,category in ipairs(categories) do root:CreateRadio("."..category.." ("..categoryCounts[category]..")",selected,choose,category); end
    end);
end

function C.contextMenu(owner)
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle("Command context");
        for _,option in ipairs({{"all","Any context"},{"console","Console allowed"},{"ingame","In-game only"}}) do
            root:CreateRadio(option[2],function(value) return C.context==value; end,function(value) C.context=value; C.refresh(C.query:GetText()); end,option[1]);
        end
    end);
end

function C.stepSelection(delta)
    if #C.matches==0 then return; end
    local index=1;
    for i,entry in ipairs(C.matches) do if C.selected and entry.name==C.selected.name then index=i; break; end end
    index=math.max(1,math.min(#C.matches,index+delta));
    C.page=math.ceil(index/C.pageSize); C.refresh(); C.select(C.matches[index]);
end

function C.values()
    local values={}; for i in ipairs(C.fields or {}) do values[i]=C.inputs[i]:GetText(); end return values;
end

function C.cacheForm()
    if not C.selected or not C.fields then return; end
    local values={};
    for i,f in ipairs(C.fields) do values[i]=not f.secret and C.inputs[i]:GetText() or ""; end
    C.drafts[C.selected.name]=values;
end

function C.loadForm(entry)
    C.loading=true; C.confirmation=nil; C.fields=M.schema(entry);
    for i,widget in ipairs(C.inputs) do
        local f=C.fields[i]; widget:ClearFocus(); widget:SetText((C.drafts[entry.name] or {})[i] or "");
        widget:SetShown(f~=nil); widget.label:SetShown(f~=nil); widget.picker:Hide();
        if f then
            local columns=math.min(3,#C.fields); local width=(562-(columns-1)*8)/columns;
            local x=18+((i-1)%columns)*(width+8); local y=-200-math.floor((i-1)/columns)*66;
            widget:ClearAllPoints(); widget:SetPoint("TOPLEFT",x,y-20); widget:SetWidth(width-(M.catalogKind(entry,f) and 54 or 0));
            widget.picker:ClearAllPoints(); widget.picker:SetPoint("TOPLEFT",x+width-48,y-20); widget.picker:SetShown(M.catalogKind(entry,f)~=nil);
            widget.label:ClearAllPoints(); widget.label:SetPoint("TOPLEFT",x,y); widget.label:SetWidth(width); widget.label:SetHeight(18);
            widget.placeholder:SetText(M.hint(f)); widget.placeholder:SetWidth(widget:GetWidth()-20);
            widget:SetPassword(not not f.secret);
            widget.label:SetText(M.label(entry,f)..(f.optional and " (optional)" or " *"));
        end
    end
    C.noArguments:SetShown(#C.fields==0);
    C.argumentHint:SetText(entry.legacy and not M.overrides[entry.name] and "Free-form arguments: use Server help for the exact syntax."
        or "* Required. Leave trailing optional fields empty for server defaults.");
    C.fill:SetText(entry.name=="go xyz" and "My position" or "Use target");
    local hasPlayer=false; for _,f in ipairs(C.fields) do if f.kind=="player" then hasPlayer=true; end end
    C.fill:SetShown(entry.name=="go xyz" or hasPlayer);
    C.loading=false;
end

function C.updateForm()
    if C.loading or not C.selected or not C.fields then return; end
    local command,err=M.build(C.selected,C.fields,C.values());
    if command and C.selected.name=="npc move" and not C.inputs[1]:GetText():match("^%s*$") and UnitGUID("target") then
        command=nil; err="Clear your target before moving an NPC by spawn ID.";
    end
    if command and (C.selected.name=="npc move" or C.selected.name=="npc delete") and C.inputs[1]:GetText():match("^%s*$") then
        local guid=UnitGUID("target");
        if not guid or not guid:match("^Creature%-") or UnitIsPlayer("target") then command=nil; err="Target an NPC or enter its database spawn ID."; end
    end
    C.command=command;
    for i in ipairs(C.fields) do C.inputs[i].placeholder:SetShown(C.inputs[i]:GetText()==""); end
    C.copy:SetText(M.build(C.selected,C.fields,C.values(),true) or ("."..C.selected.name));
    C.run:SetEnabled(command~=nil);
    C.run:SetText(C.confirmation and "Confirm run" or "Run command");
    C.status:SetText(err or (C.confirmation and "Click Confirm run to send this exact command. Changing a value or target cancels confirmation."
        or "Ready. The server response appears in chat."));
    local name=(GetUnitName and GetUnitName("target",true)) or UnitName("target");
    C.target:SetText("Selected target: "..(name or "none"));
end

function C.editChanged()
    if C.loading then return; end
    C.confirmation=nil; C.updateForm();
end

function C.clearForm()
    if C.selected then C.drafts[C.selected.name]=nil; C.loadForm(C.selected); C.updateForm(); end
end

function C.fillContext()
    if not C.selected then return; end
    if C.selected.name=="go xyz" then
        local x,y,z,map;
        if UnitPosition then x,y,z,map=UnitPosition("player"); end
        local facing=GetPlayerFacing and GetPlayerFacing();
        if not x or not y or not z or not map or not facing then C.status:SetText("Current world position is unavailable."); return; end
        for i,v in ipairs({x,y,z,map,facing}) do C.inputs[i]:SetText(i==4 and tostring(v) or string.format("%.6f",v):gsub(",",".")); end
    else
        local name=UnitIsPlayer("target") and UnitName("target");
        if not name then C.status:SetText("Select a player first."); return; end
        for i,f in ipairs(C.fields) do if f.kind=="player" then C.inputs[i]:SetText(name); break; end end
    end
    C.editChanged();
end

function C.execute()
    if not C.selected or not GMGenieForever.RequireActive() then return; end
    if IsLoggedIn and not IsLoggedIn() then C.status:SetText("Enter the world before running commands."); return; end
    C.updateForm(); if not C.command then return; end
    local command,err=M.build(C.selected,C.fields,C.values());
    if not command then C.status:SetText(err); return; end
    local guid=UnitGUID("target"); local now=GetTime();
    if M.confirm(C.selected) then
        local pending=C.confirmation;
        if not pending or pending.command~=command or pending.guid~=guid or now>pending.deadline then
            C.confirmation={command=command,guid=guid,deadline=now+10}; C.updateForm(); return;
        end
    end
    C.confirmation=nil; C.remember(C.selected);
    local ok,result=pcall(GMGenieForever.SendChatMessage,command,"GUILD");
    C.updateForm();
    C.status:SetText((not ok or result==false) and "Unable to send. Check server compatibility and try again." or "Command sent. Check chat for the server result.");
end

function C.create()
    local window=CreateFrame("Frame","GMGenie_Commands",UIParent,"BackdropTemplate"); C.window=window;
    window:SetFrameLevel(window:GetFrameLevel()+50);
    window:SetPoint("CENTER"); U.window(window,"Command workspace",1000,710);
    U.label(window,"Find a command, fill in its arguments, then run it. Nothing runs while browsing.",18,-62,950,"GameFontHighlightSmall",true);
    C.tabs={};
    for index,option in ipairs({{"all","All"},{"world","World building"},{"favorites","Favorites"},{"recent","Recent"}}) do
        C.tabs[option[1]]=U.button(window,option[2],18+(index-1)*122,-88,114,function() C.setMode(option[1]); end);
    end
    C.categoryButton=U.button(window,"All categories",510,-88,220,C.categoryMenu);
    C.contextButton=U.button(window,"Any context",740,-88,242,C.contextMenu);
    C.query=U.edit(window,"GMGenie_Commands_Search",18,-130,884,32);
    C.query:SetScript("OnTextChanged",function(self) C.refresh(self:GetText()); end);
    C.query:SetScript("OnEnterPressed",function(self) if C.selected then C.remember(C.selected); end self:ClearFocus(); end);
    C.query:SetScript("OnKeyDown",function(_,key) if key=="DOWN" then C.stepSelection(1); elseif key=="UP" then C.stepSelection(-1); end end);
    U.tooltip(C.query,"Search commands","Match names, explanations, argument names or permissions. Use Up/Down to select results. Search is plain text.");
    U.button(window,"Reset",914,-130,68,C.resetFilters,nil,32);
    local list=U.panel(window,18,-176,350,430); list:EnableMouseWheel(true);
    list:SetScript("OnMouseWheel",function(_,delta) C.page=C.page+(delta>0 and -1 or 1); C.refresh(); end);
    C.rows={};
    for index=1,C.pageSize do
        local row=U.button(list,"",8,-8-(index-1)*23,334,function(self) C.select(self.entry); end,nil,23);
        local text=row:GetFontString(); text:ClearAllPoints(); text:SetPoint("LEFT",10,0); text:SetWidth(286); text:SetJustifyH("LEFT");
        row.star=U.button(row,"+",305,-1,27,function() C.toggleFavorite(row.entry); end,nil,21);
        U.tooltip(row.star,"Favorite command","Save this command in Favorites. This does not execute it.");
        C.rows[index]=row;
    end
    C.empty=U.label(window,"No matching commands.\n\nTry another search, save a favorite, or reset the filters.",48,-240,290,"GameFontHighlight",true);
    C.count=U.label(window,"",18,-670,340,"GameFontHighlightSmall",true);
    C.previous=U.button(window,"Previous",384,-668,98,function() C.page=C.page-1; C.refresh(); end);
    C.pageLabel=U.label(window,"",500,-676,100,"GameFontHighlightSmall",true);
    C.next=U.button(window,"Next",586,-668,98,function() C.page=C.page+1; C.refresh(); end);
    U.button(window,"Recipes",18,-618,166,function() if GMGenie.Recipes then GMGenie.Recipes.open(); end end);
    C.saveRecipe=U.button(window,"Save form...",192,-618,176,function(self)
        if GMGenie.Recipes then GMGenie.Recipes.captureMenu(self,C.selected,C.values()); end
    end);
    U.tooltip(C.saveRecipe,"Save a world-building form","Create a named recipe or append this form to your open recipe. Saving never runs the command.");
    U.label(window,"Forever "..data.revision:sub(1,12),754,-676,228,"GameFontHighlightSmall",true);
    C.detail=U.panel(window,384,-176,598,474);
    C.heading=U.label(C.detail,"",18,-18,562,"GameFontNormalLarge");
    C.access=U.label(C.detail,"",18,-50,562,"GameFontHighlightSmall",true);
    local noteArea=CreateFrame("Frame",nil,C.detail); noteArea:SetPoint("TOPLEFT",18,-74); noteArea:SetSize(562,62); noteArea:EnableMouse(true);
    C.note=U.label(noteArea,"",0,0,562,"GameFontHighlightSmall"); C.note:SetHeight(62); C.note:SetJustifyV("TOP");
    noteArea:SetScript("OnEnter",function(self)
        if not C.selected then return; end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("."..C.selected.name);
        GameTooltip:AddLine(M.description(C.selected),0.65,0.73,0.83,true); GameTooltip:Show();
    end);
    noteArea:SetScript("OnLeave",function() GameTooltip:Hide(); end);
    C.target=U.label(C.detail,"",18,-143,420,"GameFontHighlightSmall",true);
    C.fill=U.button(C.detail,"Use target",454,-136,126,C.fillContext,nil,26);
    C.argumentHint=U.label(C.detail,"",18,-176,562,"GameFontHighlightSmall",true);
    C.inputs={};
    for i=1,6 do
        local x=18+((i-1)%3)*190; local y=-200-math.floor((i-1)/3)*66;
        local edit=U.edit(C.detail,"GMGenie_Commands_Argument"..i,x,y-20,182,30);
        edit.placeholder=U.label(edit,"",10,-9,162,"GameFontHighlightSmall",true); edit.placeholder:SetHeight(16);
        edit.label=U.label(C.detail,"",x,y,182,"GameFontHighlightSmall");
        edit:SetScript("OnTextChanged",C.editChanged);
        edit:SetScript("OnEnterPressed",function(self) self:ClearFocus(); end);
        edit:SetScript("OnTabPressed",function(self)
            local backwards=IsShiftKeyDown and IsShiftKeyDown();
            self:ClearFocus(); local nextIndex=i+(backwards and -1 or 1);
            if #C.fields>0 then C.inputs[(nextIndex-1)%#C.fields+1]:SetFocus(); end
        end);
        edit:HookScript("OnEnter",function(self)
            local f=C.fields and C.fields[i]; if not f then return; end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(M.label(C.selected,f));
            GameTooltip:AddLine(M.hint(f),0.65,0.73,0.83,true); GameTooltip:Show();
        end);
        edit:HookScript("OnLeave",function() GameTooltip:Hide(); end);
        edit.picker=U.button(C.detail,"Find",x+134,y-20,48,function() C.pickField(i); end); edit.picker:Hide();
        C.inputs[i]=edit;
    end
    C.noArguments=U.label(C.detail,"This command takes no arguments. Check your selected target, then click Run command.",18,-222,550,"GameFontHighlight",true);
    U.label(C.detail,"COMMAND PREVIEW  /  SELECT TO COPY",18,-340,562,"GameFontHighlightSmall",true);
    C.copy=U.edit(C.detail,"GMGenie_Commands_Copy",18,-360,562,32);
    C.copy:SetScript("OnTextChanged",function(self)
        if C.previewLoading or not C.selected then return; end
        C.previewLoading=true; self:SetText(M.build(C.selected,C.fields,C.values(),true) or ("."..C.selected.name)); C.previewLoading=false;
    end);
    C.copy:SetScript("OnEditFocusGained",function(self) self:HighlightText(); end);
    C.run=U.button(C.detail,"Run command",18,-404,114,C.execute);
    U.button(C.detail,"Clear",138,-404,64,C.clearForm);
    U.button(C.detail,"Server help",208,-404,108,function() C.help(C.selected); end);
    C.favorite=U.button(C.detail,"Save favorite",322,-404,126,function() C.toggleFavorite(C.selected); end);
    U.button(C.detail,"Source details",454,-404,126,function() C.sourceWindow:Show(); end);
    C.status=U.label(C.detail,"",18,-443,562,"GameFontHighlightSmall",true); C.status:SetHeight(27); C.status:SetJustifyV("TOP");
    local source=CreateFrame("Frame","GMGenie_Commands_SourceDetails",UIParent,"BackdropTemplate");
    source:SetPoint("CENTER"); U.window(source,"Source details",620,420); source:SetFrameLevel(window:GetFrameLevel()+10);
    C.sourceWindow=source;
    C.usage=U.label(source,"",18,-66,584,"GameFontHighlightSmall",true); C.usage:SetHeight(42); C.usage:SetJustifyV("TOP");
    C.arguments=U.label(source,"",18,-116,584,"GameFontHighlight"); C.arguments:SetHeight(126); C.arguments:SetJustifyV("TOP");
    C.technical=U.label(source,"",18,-252,584,"GameFontHighlightSmall",true); C.technical:SetHeight(70); C.technical:SetJustifyV("TOP");
    U.label(source,"PINNED SOURCE LINK  /  SELECT TO COPY",18,-344,584,"GameFontHighlightSmall",true);
    C.source=U.edit(source,"GMGenie_Commands_Source",18,-368,584,32);
    C.source:SetScript("OnEditFocusGained",function(self) self:HighlightText(); end);
    source:Hide();
    window:HookScript("OnHide",function()
        C.cacheForm(); source:Hide(); C.confirmation=nil;
        if C.fields then
            for i,f in ipairs(C.fields) do C.inputs[i]:ClearFocus(); if f.secret then C.inputs[i]:SetText(""); end end
        end
    end);
    window:RegisterEvent("PLAYER_TARGET_CHANGED");
    window:SetScript("OnEvent",function() C.confirmation=nil; if window:IsShown() then C.updateForm(); end end);
    U.workspace("commands",window,function()
        C.cacheForm();
        return {query=C.query:GetText(),mode=C.mode,category=C.category,context=C.context,page=C.page,selected=C.selected and C.selected.name};
    end,function(state)
        C.mode,C.category,C.context=state.mode,state.category,state.context;
        C.query:SetText(state.query); C.refresh(state.query); C.page=state.page; C.refresh();
        if byName[state.selected] then C.select(byName[state.selected],false); end
    end);
    window:Hide();
end

function C.pickField(index)
    local entry=C.selected; local field=C.fields and C.fields[index];
    local kind=entry and field and M.catalogKind(entry,field);
    if not kind then return; end
    C.cacheForm();
    GMGenie.Catalog.pick(kind,M.label(entry,field),function(id)
        if C.selected==entry then C.inputs[index]:SetText(tostring(id)); C.confirmation=nil; C.updateForm(); end
    end);
end

function C.open(query)
    if not GMGenieForever.RequireActive() then return; end
    if not C.window then C.create(); end
    U.visit("commands");
    if query and query~="" then C.mode="all"; C.category="all"; C.context="all"; end
    local text=query~=nil and query or C.preferences().query or "";
    C.window:Show(); C.query:SetText(text); C.refresh(text);
end

function C.toggle()
    if C.window and C.window:IsShown() then C.window:Hide(); else C.open(); end
end
