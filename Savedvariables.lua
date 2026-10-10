--This file is part of Game Master Genie.
--Copyright 2011-2014 Chocochaos

--Game Master Genie is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.
--Game Master Genie is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
--You should have received a copy of the GNU General Public License along with Game Master Genie. If not, see <http://www.gnu.org/licenses/>.

GMGenie.defaultSettings = {
    ["GMSyncChannel"] = "GM_Sync_Channel",
    ["whispers"] = GMGenie.starterMacros.whispers,
    ["mail"] = GMGenie.starterMacros.mail,
    ["tele"] = GMGenie.starterMacros.tele,
    ['objects'] = {},
    ['npcs'] = {},
    ['mute'] = GMGenie.starterMacros.mute,
    ['charBan'] = GMGenie.starterMacros.charBan,
    ['accBan'] = GMGenie.starterMacros.accBan,
    ['ipBan'] = GMGenie.starterMacros.ipBan,
    ["WIMIntegration"] = false,
    ["useSpy"] = true,
    ["swapTicketWindows"] = false,
    ["showOfflineTickets"] = false,
    ["minimapPos"] = 45,
    ['hudClosed'] = false,
    ['ticketsDone'] = 0,
    ['ticketType'] = 'bug',
}

function GMGenie.loadSettings()
    -- Seed existing installations too, once. Later edits/deletions survive reloads.
    if (GMGenie_SavedVars.starterMacrosVersion or 0) < 1 then
        GMGenie.installStarterMacros();
    end
    local kind = GMGenie_SavedVars.ticketType;
    if kind ~= "bug" and kind ~= "complaint" and kind ~= "suggestion" then
        GMGenie_SavedVars.ticketType = "bug";
    end
    for name, value in pairs(GMGenie.defaultSettings) do
        if GMGenie_SavedVars[name] == nil then
            GMGenie_SavedVars[name] = type(value) == "table" and CopyTable(value) or value;
        end
    end
end

function GMGenie.setDefault(names)
    for _, name in ipairs(names) do
        local value = GMGenie.defaultSettings[name];
        GMGenie_SavedVars[name] = type(value) == "table" and CopyTable(value) or value;
    end
end
