--This file is part of Game Master Genie.
--Copyright 2011-2014 Chocochaos

--Game Master Genie is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.
--Game Master Genie is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
--You should have received a copy of the GNU General Public License along with Game Master Genie. If not, see <http://www.gnu.org/licenses/>.

GMGenie.Hud = {};
local H=GMGenie.Hud;
local U=GMGenieUI;

function H.macroMenu(owner)
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle("Edit your macros");
        for _,name in ipairs({"Whisper Macros","Mail Macros","Teleport Macros","Discipline Macros"}) do
            root:CreateButton(name,function() GMGenieForever.OpenOptions(name); end);
        end
    end);
end

function H.reportMenu(owner)
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle("Player reports");
        for _,kind in ipairs({"bug","complaint","suggestion"}) do
            root:CreateButton(kind:sub(1,1):upper()..kind:sub(2).." reports",function()
                GMGenie.Tickets.setType(kind); GMGenie_Tickets_Main:Show();
            end);
        end
    end);
end

function H.targetInfo()
    local guid=UnitGUID("target");
    if not guid then return nil,"No target","Select a player or NPC to see available tools."; end
    local kind=UnitIsPlayer("target") and "player" or (guid:match("^Creature%-") and "npc" or "other");
    local level=UnitLevel("target");
    return kind,UnitName("target") or "Unknown target",(kind=="player" and "Player" or kind=="npc" and "NPC" or "Unit")..
        ((level and level>0) and "  /  Level "..level or "");
end

function H.updateTarget()
    if not H.targetName then return; end
    local kind,name,description=H.targetInfo();
    H.targetName:SetText(name); H.targetDescription:SetText(description);
    H.inspect:SetEnabled(kind=="player"); H.targetCommands:SetEnabled(kind=="player" or kind=="npc");
    H.targetCommands:SetText(kind=="npc" and "NPC commands" or kind=="player" and "Player commands" or "Target commands");
end

function H.inspectTarget()
    if UnitIsPlayer("target") then GMGenie.Spy.spy(UnitName("target")); end
end

function H.browseTarget()
    local kind=H.targetInfo();
    if kind=="npc" or kind=="player" then GMGenie.Commands.open(kind=="npc" and "npc" or "character"); end
end

function H.create()
    local window=GMGenie_Hud;
    window.genieNoEscape=true;
    U.window(window,"GM Genie",300,534,function() window:Hide(); GMGenie_SavedVars.hudClosed=true; end);
    H.search=U.edit(window,"GMGenie_Hud_Search",14,-62,272,32);
    local placeholder=U.label(H.search,"Search 619 commands...",10,-9,250,"GameFontHighlightSmall",true);
    H.search:SetScript("OnTextChanged",function(self) placeholder:SetShown(self:GetText()==""); end);
    H.search:SetScript("OnEnterPressed",function(self) GMGenie.Commands.open(self:GetText()); self:ClearFocus(); end);
    U.button(window,"Commands",14,-110,132,function() GMGenie.Commands.open(); end,"GMGenie_Hud_Commands");
    U.button(window,"Reports",154,-110,132,H.reportMenu,"GMGenie_Hud_Tickets");
    U.button(window,"Builder",14,-146,132,function() GMGenie.Spawns.toggle(); end,"GMGenie_Hud_Builder");
    U.button(window,"Macro editors",154,-146,132,H.macroMenu);
    U.button(window,"Catalog",14,-182,132,function() GMGenie.Catalog.open(); end,"GMGenie_Hud_Catalog");
    U.button(window,"Online players",154,-182,132,function() GMGenie.Players.open(); end,"GMGenie_Hud_Players");
    U.tooltip(GMGenie_Hud_Catalog,"Item & creature catalog","Search Forever items and creatures, preview models and add items or spawn NPCs.");
    U.label(window,"GM CONTROLS",14,-228,260,"GameFontHighlightSmall",true);
    U.button(window,"GM mode: unknown",14,-246,132,H.toggleGm,"GMGenie_Hud_GM");
    U.button(window,"Chat badge: unknown",154,-246,132,H.toggleChat,"GMGenie_Hud_Chat");
    U.button(window,"Visibility: unknown",14,-280,132,H.toggleVisibility,"GMGenie_Hud_Visibility");
    U.button(window,"Whispers: unknown",154,-280,132,H.toggleWhisper,"GMGenie_Hud_Whisper");
    U.button(window,"Flight: click to set",14,-314,132,H.toggleFly,"GMGenie_Hud_Fly");
    local speed=U.edit(window,"GMGenie_Hud_Speed",154,-314,52,28); speed:SetText("1");
    speed:SetScript("OnEnterPressed",H.setSpeed);
    U.button(window,"Speed",212,-314,74,H.setSpeed);
    U.tooltip(speed,"Movement speed","Enter a multiplier from 0.1 to 50. Target yourself or clear your target first.");
    for _,name in ipairs({"GM","Chat","Visibility","Whisper","Fly"}) do
        U.tooltip(_G["GMGenie_Hud_"..name],"Toggle "..name,"Click to change this setting. Unknown states stay unknown until the server reports them.");
    end
    local target=U.panel(window,14,-362,272,118);
    U.label(target,"CURRENT TARGET",12,-11,248,"GameFontHighlightSmall",true);
    H.targetName=U.label(target,"",12,-31,248,"GameFontHighlight");
    H.targetDescription=U.label(target,"",12,-51,248,"GameFontHighlightSmall",true);
    H.inspect=U.button(target,"Inspect player",12,-81,118,H.inspectTarget);
    H.targetCommands=U.button(target,"Target commands",142,-81,118,H.browseTarget);
    U.button(window,"Settings",14,-494,132,U.settingsMenu);
    U.button(window,"Refresh status",154,-494,132,H.checkStatus);
    window:RegisterEvent("PLAYER_TARGET_CHANGED");
    H.updateTarget();
end

function GMGenie.Hud.onLoad()
    H.create();
    GMGenie_Hud:RegisterEvent("PLAYER_ENTERING_WORLD");
    GMGenie_Hud:RegisterEvent("UI_ERROR_MESSAGE");
    GMGenie_Hud:SetScript("OnEvent", GMGenie.Hud.readNotice);

    GMGenie_Hud_GM:SetScript("OnClick", function() GMGenie.Hud.toggleGm(); end);
    GMGenie_Hud_Chat:SetScript("OnClick", function() GMGenie.Hud.toggleChat(); end);
    GMGenie_Hud_Visibility:SetScript("OnClick", function() GMGenie.Hud.toggleVisibility(); end);
    GMGenie_Hud_Whisper:SetScript("OnClick", function() GMGenie.Hud.toggleWhisper(); end);
    GMGenie_Hud_Fly:SetScript("OnClick", function() GMGenie.Hud.toggleFly(); end);

    if GMGenie_SavedVars.hudClosed then
        GMGenie.Hud.toggle();
    end

    GMGenie_Hud_GM:SetText("GM mode: unknown");
    GMGenie_Hud_Chat:SetText("Chat badge: unknown");
    GMGenie_Hud_Visibility:SetText("Visibility: unknown");
    GMGenie_Hud_Whisper:SetText("Whispers: unknown");
    GMGenie.Hud.fly = nil;
    GMGenie_Hud_Fly:SetText("Flight: click to set");
end

function GMGenie.Hud.toggle()
    if GMGenie_Hud:IsVisible() then
        GMGenie_Hud:Hide();
        GMGenie_SavedVars.hudClosed = true;
    else
        GMGenie_Hud:Show();
        GMGenie_SavedVars.hudClosed = false;
    end
end

--------------------------------------------------
------------ HUD status functionality ------------
--------------------------------------------------
function GMGenie.Hud.checkStatus()
    -- Forever has explicit .gm on/off commands and no read-only .gm query.
    -- Notification events keep this state current without changing it to query it.
    GMGenieForever.SendChatMessage(".gm chat", "GUILD");
    GMGenieForever.SendChatMessage(".gm visible", "GUILD");
    GMGenieForever.SendChatMessage(".whispers", "GUILD");
end

function GMGenie.Hud.gmStatus(status)
    GMGenie.Hud.gm = status;
    if status then
        GMGenie_Hud_GM:SetText("|cff33d1baGM mode ON|r");
    else
        GMGenie_Hud_GM:SetText("|cff94a3b8GM mode OFF|r");
    end
end

function GMGenie.Hud.chatStatus(status)
    GMGenie.Hud.chat = status;
    if status then
        GMGenie_Hud_Chat:SetText("|cff33d1baChat badge ON|r");
    else
        GMGenie_Hud_Chat:SetText("|cff94a3b8Chat badge OFF|r");
    end
end

function GMGenie.Hud.visibilityStatus(status)
    GMGenie.Hud.visibility = status;
    if status then
        GMGenie_Hud_Visibility:SetText("|cff33d1baYou are VISIBLE|r");
    else
        GMGenie_Hud_Visibility:SetText("|cff94a3b8You are INVISIBLE|r");
    end
end

function GMGenie.Hud.whisperStatus(status)
    GMGenie.Hud.whisper = status;
    if status then
        GMGenie_Hud_Whisper:SetText("|cff33d1baWhispers are ON|r");
    else
        GMGenie_Hud_Whisper:SetText("|cff94a3b8Whispers are OFF|r");
    end
end

function GMGenie.Hud.flyStatus(status)
    GMGenie.Hud.fly = status;
    if status then
        GMGenie_Hud_Fly:SetText("|cff33d1baFlight mode ON|r");
    else
        GMGenie_Hud_Fly:SetText("|cff94a3b8Flight mode OFF|r");
    end
end

function GMGenie.Hud.readNotice(_, event, messageType, message)
    if event=="PLAYER_TARGET_CHANGED" then H.updateTarget(); return; end
    local notice = message or messageType;
    if event == "UI_ERROR_MESSAGE" then
        if notice == "GM mode is ON" then
            GMGenie.Hud.gmStatus(true);
        elseif notice == "GM mode is OFF" then
            GMGenie.Hud.gmStatus(false);
        elseif notice == "GM Chat Badge is ON" then
            GMGenie.Hud.chatStatus(true);
        elseif notice == "GM Chat Badge is OFF" then
            GMGenie.Hud.chatStatus(false);
        elseif notice == "You are now visible." then
            GMGenie.Hud.visibilityStatus(true);
        elseif notice == "You are now invisible." then
            GMGenie.Hud.visibilityStatus(false);
            GMGenie.Hud.toggleWhisper(GMGenie.Hud.whisper);
        end
    elseif event == "PLAYER_ENTERING_WORLD" and GMGenie.Hud.fly == true then
        GMGenie.Hud.toggleFly(GMGenie.Hud.fly);
    end
end

function GMGenie.Hud.toggleGm(status)
    if (not GMGenie.Hud.gm and status == nil) or status == true then
        GMGenieForever.SendChatMessage(".gm on", "GUILD");
    else
        GMGenieForever.SendChatMessage(".gm off", "GUILD");
    end
end

function GMGenie.Hud.toggleChat(status)
    if (not GMGenie.Hud.chat and status == nil) or status == true then
        GMGenieForever.SendChatMessage(".gm chat on", "GUILD");
    else
        GMGenieForever.SendChatMessage(".gm chat off", "GUILD");
    end
end

function GMGenie.Hud.toggleVisibility(status)
    if (not GMGenie.Hud.visibility and status == nil) or status == true then
        GMGenieForever.SendChatMessage(".gm visible on", "GUILD");
    else
        GMGenieForever.SendChatMessage(".gm visible off", "GUILD");
    end
end

function GMGenie.Hud.toggleWhisper(status)
    if (not GMGenie.Hud.whisper and status == nil) or status == true then
        GMGenieForever.SendChatMessage(".whispers on", "GUILD");
    else
        GMGenieForever.SendChatMessage(".whispers off", "GUILD");
    end
end

function GMGenie.Hud.toggleFly(status)
    if UnitName("target") == UnitName("player") or UnitName("target") == nil then
        if (not GMGenie.Hud.fly and status == nil) or status == true then
            GMGenieForever.SendChatMessage(".gm fly on", "GUILD");
        else
            GMGenieForever.SendChatMessage(".gm fly off", "GUILD");
        end
    else
        GMGenie.showGMMessage("Could not target self to change flight mode.");
    end
end

function GMGenie.Hud.setSpeed()
    if UnitName("target") == UnitName("player") or UnitName("target") == nil then
        local speed = GMGenie_Hud_Speed:GetText();
        GMGenie_Hud_Speed:ClearFocus();
        local value=tonumber(speed);
        if not value or value~=value or value<0.1 or value>50 then
            GMGenie.showGMMessage("Enter a movement speed from 0.1 to 50."); return;
        end
        GMGenieForever.SendChatMessage(".mod speed all " .. speed, "GUILD");
    else
        GMGenie.showGMMessage("Be sure to target yourself before setting the speed.");
    end
end
