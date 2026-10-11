-- Modern command workspace for GM Genie Forever. GPL-3.0.
GMGenie.Commands = { page=1, pageSize=18, matches={}, mode="all", category="all", context="all" };
local C=GMGenie.Commands;
local data=GMGenie.CommandData;
local U=GMGenieUI;
local categories,categoryCounts={},{};
local byName={};
for _,entry in ipairs(data.entries) do
    byName[entry.name]=entry;
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
            and (C.mode=="all" or (C.mode=="favorites" and prefs.favorites[entry.name]) or (C.mode=="recent" and recentOrder[entry.name]))
            and (C.context=="all" or (C.context=="console" and entry.console) or (C.context=="ingame" and not entry.console));
        local text=(entry.name.." "..entry.arguments.." "..entry.permission):lower();
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
    C.selected=entry;
    if record~=false then C.remember(entry); end
    C.copy:SetText("."..entry.name); C.copy:ClearFocus();
    C.heading:SetText("."..entry.name);
    C.usage:SetText(entry.usage);
    C.arguments:SetText(entry.arguments=="" and "Arguments: none" or "C++ handler arguments, in order:\n\n"..entry.arguments);
    C.note:SetText(entry.legacy and
        "This command accepts free-form arguments. Request server help for its syntax and examples." or
        "Values in <brackets> are required; [brackets] mark optional parameters. Replace the parameter names with your values. Server help can provide more detail.");
    C.access:SetText((entry.console and "CONSOLE + IN-GAME" or "IN-GAME ONLY").."    /    RBAC "..entry.permissionId);
    C.technical:SetText(entry.permission.."\n"..entry.handler.."\nForever "..data.revision:sub(1,12));
    C.source:SetText("https://github.com/advocaite/TrinityCore/blob/"..data.revision.."/"..entry.source.."#L"..entry.line);
    C.source:ClearFocus();
    C.favorite:SetText(C.preferences().favorites[entry.name] and "Remove favorite" or "Save favorite");
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
    if mode~="all" and mode~="favorites" and mode~="recent" then return; end
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

function C.create()
    local window=CreateFrame("Frame","GMGenie_Commands",UIParent,"BackdropTemplate"); C.window=window;
    window:SetPoint("CENTER"); U.window(window,"Command library",1000,660);
    U.label(window,"Browse, save favorites and check usage before acting.",18,-62,800,"GameFontHighlightSmall",true);
    C.tabs={};
    for index,option in ipairs({{"all","All commands"},{"favorites","Favorites"},{"recent","Recent"}}) do
        C.tabs[option[1]]=U.button(window,option[2],18+(index-1)*146,-88,136,function() C.setMode(option[1]); end);
    end
    C.categoryButton=U.button(window,"All categories",510,-88,220,C.categoryMenu);
    C.contextButton=U.button(window,"Any context",740,-88,242,C.contextMenu);
    C.query=U.edit(window,"GMGenie_Commands_Search",18,-130,884,32);
    C.query:SetScript("OnTextChanged",function(self) C.refresh(self:GetText()); end);
    C.query:SetScript("OnEnterPressed",function(self) if C.selected then C.remember(C.selected); end self:ClearFocus(); end);
    C.query:SetScript("OnKeyDown",function(_,key) if key=="DOWN" then C.stepSelection(1); elseif key=="UP" then C.stepSelection(-1); end end);
    U.tooltip(C.query,"Search commands","Match names, argument names or permissions. Use Up/Down to select results. Search is plain text.");
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
    C.count=U.label(window,"",18,-620,340,"GameFontHighlightSmall",true);
    C.previous=U.button(window,"Previous",384,-618,98,function() C.page=C.page-1; C.refresh(); end);
    C.pageLabel=U.label(window,"",500,-626,100,"GameFontHighlightSmall",true);
    C.next=U.button(window,"Next",586,-618,98,function() C.page=C.page+1; C.refresh(); end);
    U.label(window,"Forever "..data.revision:sub(1,12),754,-626,228,"GameFontHighlightSmall",true);
    C.detail=U.panel(window,384,-176,598,430);
    C.heading=U.label(C.detail,"",18,-18,562,"GameFontNormalLarge");
    C.access=U.label(C.detail,"",18,-50,562,"GameFontHighlightSmall",true);
    U.label(C.detail,"COMMAND NAME  /  SELECT TO COPY",18,-84,562,"GameFontHighlightSmall",true);
    C.copy=U.edit(C.detail,"GMGenie_Commands_Copy",18,-106,562,32);
    C.copy:SetScript("OnEditFocusGained",function(self) self:HighlightText(); end);
    U.label(C.detail,"PARAMETER OUTLINE",18,-164,562,"GameFontHighlightSmall",true);
    C.usage=U.label(C.detail,"",18,-188,562,"GameFontHighlight");
    C.note=U.label(C.detail,"",18,-244,562,"GameFontHighlightSmall",true);
    U.button(C.detail,"Server help",18,-322,128,function() C.help(C.selected); end);
    C.favorite=U.button(C.detail,"Save favorite",156,-322,140,function() C.toggleFavorite(C.selected); end);
    U.button(C.detail,"Source details",306,-322,140,function() C.sourceWindow:Show(); end);
    U.label(C.detail,"Help responses appear in chat. Your server's RBAC grants determine access. Browsing and favorites execute no actions.",18,-372,562,"GameFontHighlightSmall",true);
    local source=CreateFrame("Frame","GMGenie_Commands_SourceDetails",UIParent,"BackdropTemplate");
    source:SetPoint("CENTER"); U.window(source,"Source details",620,360); source:SetFrameLevel(window:GetFrameLevel()+10);
    C.sourceWindow=source;
    C.arguments=U.label(source,"",18,-66,584,"GameFontHighlight");
    C.technical=U.label(source,"",18,-208,584,"GameFontHighlightSmall",true);
    U.label(source,"PINNED SOURCE LINK  /  SELECT TO COPY",18,-284,584,"GameFontHighlightSmall",true);
    C.source=U.edit(source,"GMGenie_Commands_Source",18,-308,584,32);
    C.source:SetScript("OnEditFocusGained",function(self) self:HighlightText(); end);
    source:Hide();
    window:HookScript("OnHide",function() source:Hide(); end);
    window:Hide();
end

function C.open(query)
    if not C.window then C.create(); end
    if query and query~="" then C.mode="all"; C.category="all"; C.context="all"; end
    local text=query~=nil and query or C.preferences().query or "";
    C.window:Show(); C.query:SetText(text); C.refresh(text);
end

function C.toggle()
    if C.window and C.window:IsShown() then C.window:Hide(); else C.open(); end
end
