--This file is part of Game Master Genie.
--Copyright 2011-2014 Chocochaos

--Game Master Genie is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.
--Game Master Genie is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
--You should have received a copy of the GNU General Public License along with Game Master Genie. If not, see <http://www.gnu.org/licenses/>.

GMGenie.Hud = {};

function GMGenie.Hud.onLoad()
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

    GMGenie_Hud_GM:SetText("GM mode: refresh");
    GMGenie_Hud_Chat:SetText("Chat badge: refresh");
    GMGenie_Hud_Visibility:SetText("Visibility: refresh");
    GMGenie_Hud_Whisper:SetText("Whispers: refresh");
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
        GMGenie_Hud_GM:SetText("|cffffffffGM mode ON|r");
    else
        GMGenie_Hud_GM:SetText("|cffbfbfffGM mode OFF|r");
    end
end

function GMGenie.Hud.chatStatus(status)
    GMGenie.Hud.chat = status;
    if status then
        GMGenie_Hud_Chat:SetText("|cffffffffChat badge ON|r");
    else
        GMGenie_Hud_Chat:SetText("|cffbfbfffChat badge OFF|r");
    end
end

function GMGenie.Hud.visibilityStatus(status)
    GMGenie.Hud.visibility = status;
    if status then
        GMGenie_Hud_Visibility:SetText("|cffffffffYou are VISIBLE|r");
    else
        GMGenie_Hud_Visibility:SetText("|cffbfbfffYou are INVISIBLE|r");
    end
end

function GMGenie.Hud.whisperStatus(status)
    GMGenie.Hud.whisper = status;
    if status then
        GMGenie_Hud_Whisper:SetText("|cffffffffWhispers are ON|r");
    else
        GMGenie_Hud_Whisper:SetText("|cffbfbfffWhispers are OFF|r");
    end
end

function GMGenie.Hud.flyStatus(status)
    GMGenie.Hud.fly = status;
    if status then
        GMGenie_Hud_Fly:SetText("|cffffffffFlight mode ON|r");
    else
        GMGenie_Hud_Fly:SetText("|cffbfbfffFlight mode OFF|r");
    end
end

function GMGenie.Hud.readNotice(_, event, messageType, message)
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
        GMGenieForever.SendChatMessage(".mod speed all " .. speed, "GUILD");
    else
        GMGenie.showGMMessage("Be sure to target yourself before setting the speed.");
    end
end
