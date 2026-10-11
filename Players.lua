-- Online roster for TrinityCore Forever. GPL-3.0.
GMGenie.Players = { entries={}, byName={}, page=1, pageSize=12, auto=true };
local P=GMGenie.Players;
local U=GMGenieUI;
local F=GMGenieForever;
local function trim(text) return (text:gsub("^%s+",""):gsub("%s+$","")); end

function P.validName(name)
    return type(name)=="string" and #name>0 and #name<=48 and not name:find("[^%a\128-\255]");
end

function P.zoneName(id)
    if C_Map and C_Map.GetAreaInfo then
        local ok,name=pcall(C_Map.GetAreaInfo,id);
        if ok and name and name~="" then return name; end
    end
    return "Zone "..id;
end

-- LANG_ACCOUNT_LIST_LINE from Forever: account, character, IP, map, zone, expansion, GM level.
-- Capture only the public character/location fields; never retain account names or IPs.
function P.parseRow(message)
    local name,map,zone=message:match("^%-%[[^%]]*%]%[([^%]]*)%]%[[^%]]*%]%[%s*(%d+)%s*%]%[%s*(%d+)%s*%]%[%s*%d+%s*%]%[%s*%d+%s*%]%-%s*$");
    name=name and trim(name);
    if not P.validName(name) then return; end
    return {name=name,map=tonumber(map),zoneID=tonumber(zone),zone=P.zoneName(tonumber(zone))};
end

function P.lineKind(message)
    if message:match("^%-=+ Characters Online =+%-$") then return "title"; end
    if message:match("^%-%[%s*Account%]%[%s*Character%]%[%s*IP%]%[Map%]%[Zone%]%[Exp%]%[GMLev%]%-$") then return "header"; end
    if message:match("^%-=+%-$") then return "bar"; end
    if message=="No online players." then return "empty"; end
    if P.parseRow(message) then return "row"; end
    if message:match("^%-%[") then return "invalid"; end
end

function P.finish(errorMessage)
    local request=P.pending;
    if not request then return; end
    P.pending=nil; P.suppressUntil=GetTime()+1;
    errorMessage=errorMessage or (request.invalid and "Unreadable roster row. Requires the standard Forever table format.");
    P.error=errorMessage;
    P.fresh=not errorMessage;
    if not errorMessage then
        P.entries=request.entries; P.byName=request.byName;
        table.sort(P.entries,function(a,b) return a.name:lower()<b.name:lower(); end);
        P.updated=GetTime();
    end
    P.render();
end

function P.consume(message)
    local request=P.pending;
    if not request then return; end
    message=F.PlainText(message);
    local kind=P.lineKind(message);
    if kind=="title" then request.started=true;
    elseif kind=="header" then request.started=true; request.header=true;
    elseif kind=="empty" then P.finish();
    elseif request.header and kind=="bar" then
        if request.separator then P.finish(); else request.separator=true; end
    elseif request.separator and kind=="invalid" then request.invalid=true;
    elseif request.separator and kind=="row" then
        local entry=P.parseRow(message);
        local key=entry.name:lower();
        if not request.byName[key] then
            request.entries[#request.entries+1]=entry; request.byName[key]=entry;
        end
    end
end

function P.filter(_,_,message)
    if P.pending or (P.suppressUntil and GetTime()<P.suppressUntil) then
        -- Pure filter: chat dispatch can call it once per chat window, in either event order.
        return P.lineKind(F.PlainText(message))~=nil;
    end
    return false;
end

function P.usable(entry)
    return entry and P.validName(entry.name) and IsLoggedIn() and P.fresh and not P.pending
        and P.updated and GetTime()-P.updated<45
        and P.byName[entry.name:lower()]==entry and entry.name:lower()~=(UnitName("player") or ""):lower();
end

function P.travel(entry,kind)
    if (kind~="tp" and kind~="sum") or not P.usable(entry) then return; end
    F.SendChatMessage((kind=="tp" and ".appear " or ".summon ")..entry.name,"GUILD");
    P.notice=(kind=="tp" and "Teleport to " or "Summon ")..entry.name.." requested; check the server response.";
    P.render();
end

function P.request()
    if P.pending then return; end
    if P.lastRequest and GetTime()-P.lastRequest<3 then return; end
    if not IsLoggedIn() then return; end
    P.lastRequest=GetTime(); P.error=nil; P.notice=nil;
    P.pending={entries={},byName={},deadline=GetTime()+10};
    P.render();
    F.SendChatMessage(".account onlinelist","GUILD");
end

function P.render()
    if not P.window then return; end
    local query=(P.query:GetText() or ""):lower();
    local matches={};
    for _,entry in ipairs(P.entries) do
        local text=(entry.name.." "..entry.zone.." "..entry.zoneID.." "..entry.map):lower();
        local match=true;
        for word in query:gmatch("%S+") do if not text:find(word,1,true) then match=false; break; end end
        if match then matches[#matches+1]=entry; end
    end
    local pages=math.max(1,math.ceil(#matches/P.pageSize));
    P.page=math.max(1,math.min(P.page,pages));
    for index,row in ipairs(P.rows) do
        local entry=matches[(P.page-1)*P.pageSize+index]; row.entry=entry;
        row:SetShown(entry~=nil);
        if entry then
            row.name:SetText(entry.name..(entry.name==UnitName("player") and " (you)" or ""));
            row.zone:SetText(entry.zone);
            row.tp:SetEnabled(P.usable(entry)); row.sum:SetEnabled(P.usable(entry));
        end
    end
    P.empty:SetShown(#matches==0);
    P.empty:SetText(P.pending and "Loading online players..." or P.error and "Roster unavailable. Check the server response, then refresh." or #P.entries==0 and "No online players." or "No players match your search.");
    P.previous:SetEnabled(P.page>1); P.next:SetEnabled(P.page<pages);
    P.pageLabel:SetText("Page "..P.page.." / "..pages.."   •   "..#matches.." / "..#P.entries.." players");
    P.refresh:SetEnabled(not P.pending and (not P.lastRequest or GetTime()-P.lastRequest>=3));
    P.autoButton:SetText(P.auto and "Auto: 15s" or "Auto: off");
    local age=P.updated and math.floor(GetTime()-P.updated);
    P.status:SetText(P.pending and "Refreshing current server locations..." or P.error or (age and age>=45 and "Roster is stale; refresh to enable TP / SUM.") or P.notice or
        (age and ("Updated "..age.."s ago"..(age>=45 and " — stale; refresh to enable TP / SUM." or "  •  TP: go to player   /   SUM: bring player to you")) or "Refresh to load online players."));
end

function P.tick()
    local now=GetTime();
    if P.pending and now>=P.pending.deadline then
        P.finish("No complete roster response. Requires .account onlinelist permission and English server messages.");
    end
    if P.window and P.window:IsShown() then
        if P.auto and not P.error and not P.pending and (not P.lastRequest or now-P.lastRequest>=15) then P.request(); end
        P.render();
    end
end

function P.create()
    if P.window then return; end
    local window=CreateFrame("Frame","GMGenie_Players",UIParent,"BackdropTemplate"); P.window=window;
    window:SetPoint("CENTER"); window:SetFrameLevel(window:GetFrameLevel()+50);
    U.window(window,"Online players",760,660);
    P.query=U.edit(window,"GMGenie_Players_Search",14,-62,440,30);
    local placeholder=U.label(P.query,"Search player or zone...",10,-8,420,"GameFontHighlightSmall",true);
    P.query:SetScript("OnTextChanged",function(self) placeholder:SetShown(self:GetText()==""); P.page=1; P.render(); end);
    P.autoButton=U.button(window,"Auto: 15s",466,-62,120,function() P.auto=not P.auto; P.render(); end);
    P.refresh=U.button(window,"Refresh",598,-62,148,P.request);
    P.status=U.label(window,"",14,-106,732,"GameFontHighlightSmall",true); P.status:SetHeight(28);
    U.label(window,"PLAYER",26,-141,190,"GameFontHighlightSmall",true);
    U.label(window,"CURRENT ZONE",234,-141,340,"GameFontHighlightSmall",true);
    U.label(window,"QUICK TRAVEL",634,-141,112,"GameFontHighlightSmall",true);
    P.rows={};
    for index=1,P.pageSize do
        local row=U.panel(window,14,-162-(index-1)*36,732,34); P.rows[index]=row;
        row.name=U.label(row,"",12,-10,196,"GameFontHighlightSmall"); row.name:SetHeight(16);
        row.zone=U.label(row,"",220,-10,382,"GameFontHighlightSmall",true); row.zone:SetHeight(16);
        row.tp=U.button(row,"TP",608,-4,42,function() P.travel(row.entry,"tp"); end,nil,26);
        row.sum=U.button(row,"SUM",656,-4,64,function() P.travel(row.entry,"sum"); end,nil,26);
        U.tooltip(row.tp,"Teleport to player","Moves you to this named player using .appear. Your selected target is unchanged.");
        U.tooltip(row.sum,"Summon player","Moves this named player to you using .summon. Check the server response for restrictions.");
        row:HookScript("OnEnter",function(self)
            if not self.entry then return; end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(self.entry.name);
            GameTooltip:AddLine(self.entry.zone.."  /  zone "..self.entry.zoneID.."  /  map "..self.entry.map); GameTooltip:Show();
        end);
        row:HookScript("OnLeave",function() GameTooltip:Hide(); end);
    end
    P.empty=U.label(window,"",26,-188,700,"GameFontHighlight",true);
    P.previous=U.button(window,"Previous",14,-606,100,function() P.page=P.page-1; P.render(); end);
    P.next=U.button(window,"Next",646,-606,100,function() P.page=P.page+1; P.render(); end);
    P.pageLabel=U.label(window,"",132,-614,500,"GameFontHighlightSmall",true);
    window:EnableMouseWheel(true);
    window:SetScript("OnMouseWheel",function(_,delta) P.page=P.page+(delta<0 and 1 or -1); P.render(); end);
end

function P.open(query)
    P.create();
    if query then P.query:SetText(query); end
    P.window:Show(); P.render(); P.request();
end

local listener=CreateFrame("Frame");
listener:RegisterEvent("CHAT_MSG_SYSTEM");
listener:SetScript("OnEvent",function(_,_,message) P.consume(message); end);
local elapsed=0;
listener:SetScript("OnUpdate",function(_,delta) elapsed=elapsed+delta; if elapsed>=1 then elapsed=0; P.tick(); end end);
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",P.filter);
SLASH_GMGENIEPLAYERS1="/gmplayers";
SlashCmdList.GMGENIEPLAYERS=function(query) P.open(query); end;
