-- WoW Forever compatibility for GM Genie (GPL-3.0, like the original addon).
-- Keep adapters scoped to this addon; do not replace Blizzard globals.
GMGenieForever = { errors = {}, categories = {}, popupButtons = {}, popupMenus = {} };
local F = GMGenieForever;

local originalErrorHandler;
local function installErrorHandler()
    originalErrorHandler = geterrorhandler();
    seterrorhandler(function(message)
        if type(message) == "string" and message:find("GMGenie", 1, true) and #F.errors < 100 then
            F.errors[#F.errors + 1] = message .. "\n" .. debugstack(2, 12, 0);
        end
        return originalErrorHandler(message);
    end);
end

function F.SetBackdrop(frame, info, r, g, b, a)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin);
        frame:HookScript("OnSizeChanged", frame.OnBackdropSizeChanged);
    end
    frame:SetBackdrop(info);
    frame:SetBackdropColor(r or 0, g or 0, b or 0, a or 1);
end

function F.TextChanged(edit)
    local scroll = edit:GetParent();
    if edit.GetTextHeight then
        edit:SetHeight(math.max(scroll:GetHeight(), edit:GetTextHeight() + 10));
    end
    scroll:UpdateScrollChildRect();
end

function F.CursorChanged(edit, x, y, width, height)
    if not y or not height then return end
    local scroll = edit:GetParent();
    local offset = scroll:GetVerticalScroll();
    local top = -y;
    if top < offset then
        scroll:SetVerticalScroll(math.max(0, top));
    elseif top + height > offset + scroll:GetHeight() then
        scroll:SetVerticalScroll(top + height - scroll:GetHeight());
    end
end

function F.SendChatMessage(message, channel, language, target)
    if not F.IsCompatible() or not F.initialized then return false; end
    local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage;
    message = tostring(message);
    if channel == "GUILD" and message:sub(1, 1) == "." then
        if not IsLoggedIn() then
            F.pendingCommands = F.pendingCommands or {};
            F.pendingCommands[#F.pendingCommands + 1] = message;
            return;
        end
        message = message:gsub("^%.pin ", ".pinfo "):gsub("^%.mod ", ".modify "):gsub("^%.gob ", ".gobject ");
        message = message:gsub("^%.char ", ".character "):gsub("^%.ban char ", ".ban character ")
            :gsub("^%.name ", ".nameannounce "):gsub("^%.gmname ", ".gmnameannounce ")
            :gsub("^%.gobject del ", ".gobject delete ");
        if message:match("^%.ticket ") then
            message = message:gsub("^%.ticket viewid ", ".ticket view "):gsub("^%.ticket del ", ".ticket delete ");
            message = message:gsub("^%.ticket ", ".ticket " .. (GMGenie_SavedVars.ticketType or "bug") .. " ");
        end
        -- The modern client rejects guild chat before sending it when unguilded.
        -- TrinityCore consumes dot commands before whisper delivery.
        channel, target = "WHISPER", UnitName("player");
    end
    local result = send(message, channel, language, target);
    F.lastSendResult = result;
    return result;
end

function F.SendAddonMessage(prefix, message, channel, target)
    if not F.IsCompatible() or not F.initialized then return false; end
    if channel == "GUILD" and not IsInGuild() then return end
    return C_ChatInfo.SendAddonMessage(prefix, tostring(message), channel, target);
end

function F.RegisterOptions(panel)
    if not F.IsCompatible() then return; end
    local category;
    if panel.parent then
        category = Settings.RegisterCanvasLayoutSubcategory(F.categories[panel.parent], panel, panel.name);
    else
        category = Settings.RegisterCanvasLayoutCategory(panel, panel.name);
        Settings.RegisterAddOnCategory(category);
    end
    F.categories[panel.name] = category;
    -- Legacy forms commit on Okay. Modern canvas pages commit when leaving the page.
    panel:HookScript("OnHide", function(self)
        if F.initialized and self.okay then self.okay(); end
    end);
    panel:HookScript("OnShow", function(self)
        if F.initialized and self.cancel then self.cancel(); end
    end);
end

function F.OpenOptions(name)
    if not F.RequireActive() then return; end
    local category = F.categories[name];
    if category then Settings.OpenToCategory(category:GetID()); end
end

function F.RegisterUnitMenus()
    if not F.IsCompatible() then return; end
    local function appendEntries(parent, entries, name)
        for _, value in ipairs(entries or {}) do
            local entry = F.popupButtons[value];
            if entry then
                if entry.nested then
                    appendEntries(parent:CreateButton(entry.text), F.popupMenus[value], name);
                else
                    parent:CreateButton(entry.text, function()
                        GMGenie.Macros.contextMenuClick({ value = value }, name);
                    end);
                end
            end
        end
    end
    for _, tag in ipairs({ "PLAYER", "SELF", "PARTY", "RAID_PLAYER", "FRIEND", "CHAT_ROSTER", "GUILD" }) do
        Menu.ModifyMenu("MENU_UNIT_" .. tag, function(owner, root, context)
            if not F.IsCompatible() or not F.initialized then return; end
            local name = context and (context.name or (context.unit and UnitName(context.unit)));
            if not name then return end
            if context.server and context.server ~= "" and not name:find("-", 1, true) then
                name = name .. "-" .. context.server;
            end
            root:CreateDivider();
            local menu = root:CreateButton("GM Genie");
            local entries = {};
            for _, key in ipairs(GMGenie.Macros.menuItems) do entries[#entries + 1] = "GMGenie_" .. key; end
            appendEntries(menu, entries, name);
        end);
    end
end

function F.StartChatReader()
    if not F.IsCompatible() or F.chatFrame then return; end
    local frame = CreateFrame("Frame");
    frame:RegisterEvent("CHAT_MSG_SYSTEM");
    frame:SetScript("OnEvent", function(_, _, message)
        if F.IsCompatible() and F.initialized then GMGenie.readSystemMessage(message); end
    end);
    F.chatFrame = frame;
end

function F.PlainText(message)
    return (message:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"));
end

-- Blizzard supports addon hyperlinks without replacing its SetItemRef function.
function F.DisplayLinks(_, _, message, ...)
    message = message:gsub("|H(gameobject_entry):(%d+)[^|]*|h", "|Haddon:GMGenie:%1:%2|h")
        :gsub("|H(creature_entry):(%d+)[^|]*|h", "|Haddon:GMGenie:%1:%2|h")
        :gsub("|H(gameobject):(%d+)[^|]*|h", "|Haddon:GMGenie:%1:%2|h")
        :gsub("|H(creature):(%d+)[^|]*|h", "|Haddon:GMGenie:%1:%2|h");
    return false, message, ...;
end

function F.ActivateIntegrations()
    if not F.IsCompatible() or F.integrationsActive then return; end
    F.integrationsActive = true;
    installErrorHandler();
    C_ChatInfo.RegisterAddonMessagePrefix("GMGenie_FVR");
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", F.DisplayLinks);
    EventRegistry:RegisterCallback("SetItemRef", function(_, link, text)
        local kind, id = link:match("^addon:GMGenie:([%a_]+):(%d+)$");
        if kind and id and F.RequireActive() then GMGenie.Spawns.Hyperlink.toggle(kind .. ":" .. id, text); end
    end, F);
end

local diagnosticsFrame = CreateFrame("Frame");
diagnosticsFrame:RegisterEvent("ADDON_LOADED");
diagnosticsFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
diagnosticsFrame:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_ENTERING_WORLD" then
        if F.IsCompatible() and F.initialized then
            C_Timer.After(1, function()
                if not F.IsCompatible() or not F.initialized then return; end
                local commands = F.pendingCommands or {};
                F.pendingCommands = {};
                for _, message in ipairs(commands) do F.SendChatMessage(message, "GUILD"); end
                GMGenie.Hud.checkStatus();
                GMGenie.Tickets.refresh();
            end);
        end
        return;
    end
    if name ~= "GMGenie" then return end
    local version, build, _, interface = GetBuildInfo();
    GMGenie_ForeverDiagnostics = { version = version, build = build, interface = interface, errors = F.errors };
    F.diagnostics = GMGenie_ForeverDiagnostics;
end);

SLASH_GMGENIEFOREVER1 = "/gmgenie";
SlashCmdList.GMGENIEFOREVER = function(command)
    command = strtrim(command or ""):lower();
    if command == "check" then F.server.check(); return; end
    if command ~= "debug" and not F.RequireActive() then return; end
    if command == "commands" or command:match("^commands%s") then
        GMGenie.Commands.open(strtrim(command:sub(9)));
    elseif command == "catalog" or command:match("^catalog%s") then
        GMGenie.Catalog.open(strtrim(command:sub(8)));
    elseif command == "players" or command:match("^players%s") then
        GMGenie.Players.open(strtrim(command:sub(8)));
    elseif command == "options" then F.OpenOptions("GM Genie");
    elseif command == "status" then GMGenie.Hud.checkStatus();
    elseif command == "debug" then
        print("GM Genie Forever: server=" .. F.server.status .. ", initialized=" .. tostring(F.initialized) .. ", errors=" .. #F.errors);
        print("Command result=" .. tostring(F.lastSendResult) .. ", guild=" .. tostring(IsInGuild()));
        for index, message in ipairs(F.errors) do print(index .. ": " .. message:match("[^\n]+")); end
    else GMGenie.Hud.toggle(); end
end;
