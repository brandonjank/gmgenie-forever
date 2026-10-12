-- Single-folder TrinityCore activation gate. GPL-3.0.
-- Protocol: AddonChannelCommandHandler in TrinityCore's game/Chat/Chat.cpp.
-- A ping is hidden addon traffic, not a dot command or a permission check.
local F = GMGenieForever;
local S = { status="waiting", callbacks={}, started=false };
F.server = S;

function F.IsCompatible()
    return S.status == "compatible";
end

function F.RequireActive()
    if F.IsCompatible() and F.initialized then return true; end
    print("GM Genie Forever is inactive (server check: " .. S.status .. "). Use /gmgenie check to retry.");
    return false;
end

function F.RegisterSlash(name, callback)
    SlashCmdList[name] = function(...)
        if F.RequireActive() then return callback(...); end
    end;
end

function F.WhenCompatible(callback)
    if F.IsCompatible() then callback(); else S.callbacks[#S.callbacks+1] = callback; end
end

local function realmKey(realm)
    return (realm or ""):gsub("%s", ""):lower();
end

local function isSelf(sender)
    if type(sender) ~= "string" then return false; end
    local name, realm = sender:match("^(.-)%-(.+)$");
    name = name or sender;
    local ownName = UnitName("player");
    local displayName = GetUnitName and GetUnitName("player", true) or ownName;
    local displayRealm;
    if displayName then
        local qualifiedName, qualifiedRealm = displayName:match("^(.-)%-(.+)$");
        displayName, displayRealm = qualifiedName or displayName, qualifiedRealm;
    end
    local ownRealm = displayRealm or (GetRealmName and GetRealmName());
    -- Forever's second UnitName/UnitFullName return is a surname, not a realm.
    -- GetUnitName formats that surname correctly; retail formats a realm suffix.
    local matchesName = (ownName and name:lower() == ownName:lower())
        or (displayName and name:lower() == displayName:lower());
    return matchesName and (not realm or realmKey(realm) == realmKey(ownRealm));
end

local function finish(status)
    S.status = status;
    S.token = nil;
    S.deadline = nil;
    S.frame:UnregisterEvent("CHAT_MSG_ADDON");
end

function S.check()
    if F.IsCompatible() or S.status == "checking" or S.status == "error" then return; end
    if not IsLoggedIn() then return; end
    S.started = true;
    if not (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix and C_ChatInfo.SendAddonMessage) then
        finish("unavailable"); return;
    end
    local ok, registered = pcall(C_ChatInfo.RegisterAddonMessagePrefix, "TrinityCore");
    if not ok or registered == false then finish("unavailable"); return; end
    S.status = "checking";
    local token = string.format("%04X", math.random(0, 65535));
    -- Do not reuse the preceding token on an explicit retry.
    if token == S.previousToken then token = string.format("%04X", (tonumber(token,16)+1)%65536); end
    S.token, S.previousToken = token, token;
    S.deadline = GetTime() + 5;
    S.frame:RegisterEvent("CHAT_MSG_ADDON");
    local sent, result = pcall(C_ChatInfo.SendAddonMessage, "TrinityCore", "p" .. token, "WHISPER", UnitName("player"));
    if not sent or (result ~= nil and result ~= true and result ~= 0) then finish("send failed"); return; end
    C_Timer.After(5, function()
        if S.status == "checking" and S.token == token then finish("no response"); end
    end);
end

function S.receive(prefix, message, channel, sender)
    if S.status ~= "checking" or GetTime() >= S.deadline then return; end
    if prefix ~= "TrinityCore" or channel ~= "WHISPER" or message ~= "a" .. S.token or not isSelf(sender) then return; end
    finish("compatible");
    local ok, message = pcall(function()
        F.ActivateIntegrations();
        for _, callback in ipairs(S.callbacks) do callback(); end
        S.callbacks = {};
        GMGenie.onLoad();
        GMGenie.Hud.checkStatus();
        GMGenie.Tickets.refresh();
    end);
    if not ok then
        finish("error");
        F.initialized = false;
        if GMGenie_Minimap then GMGenie_Minimap:Hide(); end
        if GMGenie_Hud then GMGenie_Hud:Hide(); end
        for _, window in ipairs(GMGenieUI.windows or {}) do window:Hide(); end
        geterrorhandler()(message);
    end
end

S.frame = CreateFrame("Frame");
S.frame:RegisterEvent("PLAYER_ENTERING_WORLD");
S.frame:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then S.receive(...);
    elseif not S.started then
        -- Initial world entry/reload only; zoning must not send more probes.
        S.started = true;
        C_Timer.After(1, S.check);
    end
end);
