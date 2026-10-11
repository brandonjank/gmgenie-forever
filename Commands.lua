-- Searchable, offline reference for a pinned Forever core. GPL-3.0.
GMGenie.Commands = { page = 1, pageSize = 18, matches = {} };
local C = GMGenie.Commands;
local data = GMGenie.CommandData;

function C.search(query)
    local words, matches = {}, {};
    for word in (query or ""):lower():gmatch("%S+") do words[#words + 1] = word; end
    for _, entry in ipairs(data.entries) do
        local text = (entry.name .. " " .. entry.arguments .. " " .. entry.permission):lower();
        local found = true;
        for _, word in ipairs(words) do
            if not text:find(word, 1, true) then found = false; break; end
        end
        if found then matches[#matches + 1] = entry; end
    end
    local phrase = table.concat(words, " ");
    if phrase ~= "" then
        local function rank(entry)
            if entry.name == phrase then return 0; end
            if entry.name:sub(1, #phrase) == phrase then return 1; end
            return 2;
        end
        table.sort(matches, function(a, b)
            local ar, br = rank(a), rank(b);
            return ar < br or (ar == br and a.name < b.name);
        end);
    end
    return matches;
end

function C.help(entry)
    if entry then GMGenieForever.SendChatMessage(".help " .. entry.name, "GUILD"); end
end

local function label(parent, text, x, y, width, font)
    local item = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal");
    item:SetPoint("TOPLEFT", x, y); item:SetWidth(width); item:SetJustifyH("LEFT");
    item:SetText(text); return item;
end

local function button(parent, text, x, y, width, action)
    local item = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate");
    item:SetSize(width, 24); item:SetPoint("TOPLEFT", x, y); item:SetText(text);
    item:SetScript("OnClick", action); return item;
end

local function edit(parent, name, x, y, width)
    local item = CreateFrame("EditBox", name, parent, "InputBoxTemplate");
    item:SetSize(width, 24); item:SetPoint("TOPLEFT", x, y); item:SetAutoFocus(false);
    item:SetMaxLetters(0);
    item:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
    return item;
end

function C.select(entry)
    C.selected = entry;
    C.copy:SetText("." .. entry.name); C.copy:ClearFocus();
    C.heading:SetText("." .. entry.name);
    C.arguments:SetText("Parameter outline: " .. entry.usage .. "\n\n" .. (entry.arguments == "" and "Arguments: none" or
        "Arguments in handler order (C++ source):\n" .. entry.arguments));
    C.note:SetText(entry.legacy and
        "This handler parses free-form arguments. Use Server help for syntax; the reference does not guess its grammar." or
        "Optional<T> means optional; Variant<A, B> accepts alternatives. EXACT_SEQUENCE is a literal keyword. Server help can provide additional usage text.");
    C.access:SetText("RBAC permission: " .. entry.permissionId .. "\n" .. entry.permission ..
        "\n\n" .. (entry.console and "Console and in-game registration" or "In-game only; console help may hide this command") ..
        "\nYour server's RBAC grants determine access.");
    C.source:SetText("https://github.com/advocaite/TrinityCore/blob/" .. data.revision .. "/" .. entry.source .. "#L" .. entry.line);
    C.source:ClearFocus();
end

function C.refresh(query)
    if query ~= nil then C.matches = C.search(query); C.page = 1; end
    local pages = math.max(1, math.ceil(#C.matches / C.pageSize));
    C.page = math.max(1, math.min(C.page, pages));
    for index, row in ipairs(C.rows) do
        local entry = C.matches[(C.page - 1) * C.pageSize + index];
        row.entry = entry;
        if entry then row:SetText("." .. entry.name); row:Show(); else row:Hide(); end
    end
    C.count:SetText(#C.matches .. " / " .. #data.entries .. " commands     Page " .. C.page .. " / " .. pages);
    C.previous:SetEnabled(C.page > 1); C.next:SetEnabled(C.page < pages);
    if C.matches[1] then
        C.detail:Show(); C.select(C.matches[(C.page - 1) * C.pageSize + 1]);
    else C.detail:Hide(); end
end

function C.create()
    local window = CreateFrame("Frame", "GMGenie_Commands", UIParent, "BackdropTemplate");
    C.window = window; window:SetSize(920, 610); window:SetPoint("CENTER");
    window:SetFrameStrata("DIALOG"); window:SetClampedToScreen(true); window:SetMovable(true);
    window:EnableMouse(true); window:RegisterForDrag("LeftButton");
    window:SetScript("OnDragStart", window.StartMoving); window:SetScript("OnDragStop", window.StopMovingOrSizing);
    GMGenieForever.SetBackdrop(window, { bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=16, insets={left=4,right=4,top=4,bottom=4} }, 0.04, 0.04, 0.04, 0.98);
    UISpecialFrames[#UISpecialFrames + 1] = "GMGenie_Commands";
    label(window, "GM Genie - Forever command reference", 18, -18, 800, "GameFontNormalLarge");
    button(window, "Close", 822, -12, 80, function() window:Hide(); end);
    label(window, #data.entries .. " commands | Forever " .. data.revision:sub(1,12) .. " | Search names, arguments or permissions", 18, -46, 880, "GameFontHighlightSmall");
    C.query = edit(window, "GMGenie_Commands_Search", 24, -70, 872);
    C.query:SetScript("OnTextChanged", function(self) C.refresh(self:GetText()); end);
    C.query:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
    C.rows = {};
    for index=1,C.pageSize do
        local row = CreateFrame("Button", nil, window);
        row:SetPoint("TOPLEFT", 18, -108-(index-1)*24); row:SetSize(310, 23);
        row:SetNormalFontObject("GameFontHighlightSmall"); row:SetHighlightFontObject("GameFontNormalSmall");
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
        row:SetScript("OnClick", function(self) C.select(self.entry); end);
        C.rows[index] = row;
    end
    C.count = label(window, "", 18, -550, 450, "GameFontHighlightSmall");
    C.previous = button(window, "Previous", 18, -574, 95, function() C.page=C.page-1; C.refresh(); end);
    C.next = button(window, "Next", 124, -574, 95, function() C.page=C.page+1; C.refresh(); end);
    local detail = CreateFrame("Frame", nil, window); C.detail=detail;
    detail:SetPoint("TOPLEFT", 350, -108); detail:SetSize(548, 470);
    C.heading=label(detail, "", 0, 0, 540, "GameFontNormalLarge");
    label(detail, "Command name (select to copy)", 0, -34, 540, "GameFontHighlightSmall");
    C.copy=edit(detail, "GMGenie_Commands_Copy", 6, -56, 526);
    C.copy:SetScript("OnEditFocusGained", function(self) self:HighlightText(); end);
    C.copy:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
    C.arguments=label(detail, "", 0, -94, 540, "GameFontHighlight");
    C.note=label(detail, "", 0, -200, 540, "GameFontHighlightSmall");
    C.access=label(detail, "", 0, -265, 540, "GameFontHighlightSmall");
    button(detail, "Server help", 0, -365, 120, function() C.help(C.selected); end);
    label(detail, "Sends only .help; command actions are not executed here.", 132, -372, 405, "GameFontHighlightSmall");
    label(detail, "Pinned source link (select to copy)", 0, -410, 540, "GameFontHighlightSmall");
    C.source=edit(detail, "GMGenie_Commands_Source", 6, -432, 526);
    C.source:SetScript("OnEditFocusGained", function(self) self:HighlightText(); end);
    C.source:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
    window:Hide();
end

function C.open(query)
    if not C.window then C.create(); end
    C.window:Show(); C.query:SetText(query or ""); C.refresh(query or "");
end

function C.toggle()
    if C.window and C.window:IsShown() then C.window:Hide(); else C.open(); end
end
