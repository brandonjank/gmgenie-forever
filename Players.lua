-- Online roster for TrinityCore Forever. GPL-3.0.
GMGenie.Players = { entries={}, byName={}, page=1, pageSize=12, auto=true };
local P=GMGenie.Players;
local U=GMGenieUI;
local F=GMGenieForever;
local function trim(text) return (text:gsub("^%s+",""):gsub("%s+$","")); end

function P.validName(name)
    return type(name)=="string" and #name>0 and #name<=48 and not name:find("[^%a\128-\255]");
end

-- Read character/zone data from the native Who buffer, never account administration output.
function P.characterName(fullName)
    if type(fullName)~="string" or fullName:find("[%c|]") then return; end
    local name,realm=fullName:match("^([^-]+)%-(.+)$");
    if not name then return P.validName(fullName) and fullName or nil; end
    if not P.validName(name) then return; end
    local current=GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName and GetRealmName();
    if current and realm:gsub("%s",""):lower()==current:gsub("%s",""):lower() then return name; end
    return fullName; -- Display foreign realms, but validName prevents GM commands to them.
end

function P.finish(errorMessage,entries,byName,total,limited)
    if not P.pending then return; end
    local query=P.pending.query;
    P.pending=nil; P.error=errorMessage; P.fresh=not errorMessage;
    if not errorMessage then
        P.entries=entries; P.byName=byName; P.total=total; P.limited=limited; P.snapshotQuery=query;
        table.sort(P.entries,function(a,b) return a.name:lower()<b.name:lower(); end);
        P.updated=GetTime();
    end
    P.render();
end

function P.readWho()
    local count,total=C_FriendList.GetNumWhoResults();
    if type(count)~="number" or count<0 or count%1~=0 then error("Invalid Who count"); end
    local entries,byName={},{};
    for index=1,count do
        local info=C_FriendList.GetWhoInfo(index);
        local name=info and P.characterName(info.fullName);
        if not name then error("Invalid Who row"); end
        local key=name:lower();
        if not byName[key] then
            local entry={name=name,zone=type(info.area)=="string" and info.area~="" and info.area or "Unknown zone",
                level=tonumber(info.level),class=info.classStr or ""};
            entries[#entries+1]=entry; byName[key]=entry;
        end
    end
    total=math.max(count,tonumber(total) or count);
    -- Forever stops at MaxWho without sending an uncapped total. 50 itself can mean capped.
    return entries,byName,total,total>count or count>=50;
end

function P.onWhoResults()
    if not P.pending then return; end
    local ok,entries,byName,total,limited=pcall(P.readWho);
    if ok then P.finish(nil,entries,byName,total,limited);
    else P.finish("Could not read Who results. Refresh to retry."); end
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

function P.targetMatches(entry,guid)
    local target=UnitName("target");
    local current=UnitGUID("target");
    return entry and target and current and UnitIsPlayer("target")
        and target:lower()==entry.name:lower() and (not guid or guid==current);
end

function P.validReason(reason)
    return type(reason)=="string" and #trim(reason)>0 and #reason<=160 and not reason:find("[%c|]");
end

function P.validDuration(duration)
    local amount,unit=duration:match("^([1-9]%d*)([smhd])$");
    local multiplier=({s=1,m=60,h=3600,d=86400})[unit];
    return amount and #amount<=9 and multiplier and tonumber(amount)*multiplier<=2147483647;
end

function P.cancelAction()
    P.action=nil;
    if P.actionWindow then P.actionWindow:Hide(); end
end

function P.confirmAction()
    local action=P.action;
    if not action then return; end
    if not P.usable(action.entry) then P.actionStatus:SetText("Player list changed or is stale. Refresh and choose the action again."); return; end
    local command;
    if action.kind=="kill" then
        if not P.targetMatches(action.entry,action.guid) then P.actionStatus:SetText("Target changed. Target this player and choose Kill again."); return; end
        command=".die";
    elseif action.kind=="kick" or action.kind=="ban" then
        local reason=trim(P.reason:GetText() or "");
        if not P.validReason(reason) then P.actionStatus:SetText("Enter a short, single-line reason without chat links."); return; end
        if action.kind=="kick" then command=".kick "..action.entry.name.." "..reason;
        else
            local duration=trim(P.duration:GetText() or "");
            if not P.validDuration(duration) then P.actionStatus:SetText("Use a positive duration such as 30m, 1h or 7d."); return; end
            command=".ban character "..action.entry.name.." "..duration.." "..reason;
        end
    else return; end
    P.cancelAction(); -- Clear confirmation before sending; repeated clicks cannot repeat the command.
    F.SendChatMessage(command,"GUILD");
    P.notice=action.kind:sub(1,1):upper()..action.kind:sub(2).." requested for "..action.entry.name.."; check the server response.";
    P.render();
end

function P.createActionWindow()
    if P.actionWindow then return; end
    local window=CreateFrame("Frame","GMGenie_PlayerAction",UIParent,"BackdropTemplate"); P.actionWindow=window;
    window:SetPoint("CENTER"); window:SetFrameLevel(window:GetFrameLevel()+100);
    U.window(window,"Player action",480,340,P.cancelAction);
    window:HookScript("OnHide",function() P.action=nil; P.reason:ClearFocus(); P.duration:ClearFocus(); end);
    P.actionTitle=U.label(window,"",16,-65,448,"GameFontNormalLarge");
    P.actionDetail=U.label(window,"",16,-95,448,"GameFontHighlightSmall",true); P.actionDetail:SetHeight(38);
    P.reasonLabel=U.label(window,"Reason",16,-142,448,"GameFontHighlightSmall");
    P.reason=U.edit(window,"GMGenie_PlayerAction_Reason",16,-162,448,30); P.reason:SetMaxLetters(160);
    P.durationLabel=U.label(window,"Duration: positive s / m / h / d",16,-204,448,"GameFontHighlightSmall");
    P.duration=U.edit(window,"GMGenie_PlayerAction_Duration",16,-224,120,28); P.duration:SetMaxLetters(12);
    P.actionStatus=U.label(window,"",150,-218,314,"GameFontHighlightSmall",true); P.actionStatus:SetHeight(68);
    P.confirm=U.button(window,"Confirm",16,-296,284,P.confirmAction);
    U.button(window,"Cancel",316,-296,148,P.cancelAction);
end

function P.beginAction(entry,kind)
    if not P.usable(entry) or (kind~="kick" and kind~="ban" and kind~="kill") then return; end
    if kind=="kill" and not P.targetMatches(entry) then
        GMGenie.showGMMessage("Target "..entry.name.." first, then choose Kill. Forever .die acts on your selected unit."); return;
    end
    P.createActionWindow();
    P.action={entry=entry,kind=kind,guid=kind=="kill" and UnitGUID("target") or nil};
    local title=(kind=="ban" and "Ban character" or kind=="kick" and "Kick" or "Kill").." "..entry.name;
    P.actionTitle:SetText(title); P.confirm:SetText(title);
    P.actionDetail:SetText(kind=="ban" and "Bans this character for the duration below. Server permissions still apply."
        or kind=="kick" and "Disconnects this named player. Enter the reason before confirming."
        or "Kills the selected player. Their name and target GUID are checked again when you confirm.");
    P.reason:SetText(""); P.duration:SetText("1h"); P.actionStatus:SetText("");
    P.reason:SetShown(kind~="kill"); P.reasonLabel:SetShown(kind~="kill");
    P.duration:SetShown(kind=="ban"); P.durationLabel:SetShown(kind=="ban");
    P.actionWindow:Show();
end

function P.actionMenu(owner,entry)
    if not P.usable(entry) then return; end
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle(entry.name);
        root:CreateButton("Kick...",function() P.beginAction(entry,"kick"); end);
        root:CreateButton("Ban character...",function() P.beginAction(entry,"ban"); end);
        root:CreateDivider();
        root:CreateButton("Kill (requires selected player)...",function() P.beginAction(entry,"kill"); end);
    end);
end

function P.request()
    if P.pending then return; end
    if P.lastRequest and GetTime()-P.lastRequest<5 then return; end
    if not IsLoggedIn() then return; end
    P.lastRequest=GetTime(); P.error=nil; P.notice=nil;
    local query=trim(P.query:GetText() or ""):gsub("%c",""):sub(1,128);
    P.pending={query=query,deadline=GetTime()+10};
    P.render();
    if not (C_FriendList and C_FriendList.SendWho and C_FriendList.GetWhoInfo and C_FriendList.GetNumWhoResults and C_FriendList.SetWhoToUi) then
        P.finish("The native Who API is unavailable on this client."); return;
    end
    local ok=pcall(function() C_FriendList.SetWhoToUi(true); C_FriendList.SendWho("1-255"..(query~="" and " "..query or "")); end);
    if not ok then P.finish("Could not send the Who search. Refresh to retry."); end
end

function P.render()
    if not P.window then return; end
    local query=(P.query:GetText() or ""):lower();
    local matches={};
    for _,entry in ipairs(P.entries) do
        local text=(entry.name.." "..entry.zone):lower();
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
            row.actions:SetEnabled(P.usable(entry));
        end
    end
    P.empty:SetShown(#matches==0);
    P.empty:SetText(P.pending and "Loading online players..." or P.error and "Roster unavailable. Refresh to retry." or #P.entries==0 and "No visible players matched the Who search." or "No players match your search.");
    P.previous:SetEnabled(P.page>1); P.next:SetEnabled(P.page<pages);
    P.pageLabel:SetText("Page "..P.page.." / "..pages.."   •   "..#matches.." / "..#P.entries.." players");
    P.refresh:SetEnabled(not P.pending and (not P.lastRequest or GetTime()-P.lastRequest>=5));
    P.autoButton:SetText(P.auto and "Auto: 15s" or "Auto: off");
    local age=P.updated and math.floor(GetTime()-P.updated);
    P.status:SetText(P.pending and "Searching online players through Who..." or P.error or (age and age>=45 and "Roster is stale; refresh to enable actions.") or P.notice or (P.limited and "Who result limit reached; narrow the search and press Enter.") or
        (age and ("Updated "..age.."s ago"..(age>=45 and " — stale; refresh to enable TP / SUM." or "  •  TP: go to player   /   SUM: bring player to you")) or "Refresh to load online players."));
end

function P.tick()
    local now=GetTime();
    if P.pending and now>=P.pending.deadline then
        P.finish("Who search timed out. Refresh to retry; another addon or /who may be using the shared search.");
    end
    if P.window and P.window:IsShown() then
        if P.auto and not P.action and not P.error and not P.pending and (not P.lastRequest or now-P.lastRequest>=15) then P.request(); end
        P.render();
    end
end

function P.create()
    if P.window then return; end
    local window=CreateFrame("Frame","GMGenie_Players",UIParent,"BackdropTemplate"); P.window=window;
    window:SetPoint("CENTER"); window:SetFrameLevel(window:GetFrameLevel()+50);
    U.window(window,"Online players",760,660);
    P.query=U.edit(window,"GMGenie_Players_Search",14,-62,440,30);
    local placeholder=U.label(P.query,"Search player or zone; Enter searches server",10,-8,420,"GameFontHighlightSmall",true);
    P.query:SetMaxLetters(128);
    P.query:SetScript("OnEnterPressed",function(self) self:ClearFocus(); P.request(); end);
    P.query:SetScript("OnTextChanged",function(self) placeholder:SetShown(self:GetText()==""); P.page=1; P.render(); end);
    P.autoButton=U.button(window,"Auto: 15s",466,-62,120,function() P.auto=not P.auto; P.render(); end);
    P.refresh=U.button(window,"Refresh",598,-62,148,P.request);
    P.status=U.label(window,"",14,-106,732,"GameFontHighlightSmall",true); P.status:SetHeight(28);
    U.label(window,"PLAYER",26,-141,190,"GameFontHighlightSmall",true);
    U.label(window,"CURRENT ZONE",234,-141,340,"GameFontHighlightSmall",true);
    U.label(window,"TP / SUM / ACTIONS",538,-141,208,"GameFontHighlightSmall",true);
    P.rows={};
    for index=1,P.pageSize do
        local row=U.panel(window,14,-162-(index-1)*36,732,34); P.rows[index]=row;
        row.name=U.label(row,"",12,-10,196,"GameFontHighlightSmall"); row.name:SetHeight(16);
        row.zone=U.label(row,"",220,-10,280,"GameFontHighlightSmall",true); row.zone:SetHeight(16);
        row.tp=U.button(row,"TP",512,-4,42,function() P.travel(row.entry,"tp"); end,nil,26);
        row.sum=U.button(row,"SUM",560,-4,54,function() P.travel(row.entry,"sum"); end,nil,26);
        row.actions=U.button(row,"Actions",620,-4,100,function(self) P.actionMenu(self,row.entry); end,nil,26);
        U.tooltip(row.tp,"Teleport to player","Moves you to this named player using .appear. Your selected target is unchanged.");
        U.tooltip(row.sum,"Summon player","Moves this named player to you using .summon. Check the server response for restrictions.");
        row:HookScript("OnEnter",function(self)
            if not self.entry then return; end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(self.entry.name);
            GameTooltip:AddLine(self.entry.zone);
            if self.entry.level then GameTooltip:AddLine("Level "..self.entry.level.." "..self.entry.class); end
            GameTooltip:Show();
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
listener:RegisterEvent("WHO_LIST_UPDATE");
listener:SetScript("OnEvent",P.onWhoResults);
local elapsed=0;
listener:SetScript("OnUpdate",function(_,delta) elapsed=elapsed+delta; if elapsed>=1 then elapsed=0; P.tick(); end end);
SLASH_GMGENIEPLAYERS1="/gmplayers";
SlashCmdList.GMGENIEPLAYERS=function(query) P.open(query); end;
