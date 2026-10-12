-- Shared presentation for GM Genie Forever. GPL-3.0.
GMGenieUI = {};
local U = GMGenieUI;
U.colors = {
    window={0.055,0.071,0.10,0.98}, panel={0.085,0.105,0.14,1},
    input={0.035,0.049,0.073,1}, button={0.12,0.15,0.20,1},
    border={0.22,0.28,0.36,1}, accent={0.20,0.82,0.73,1},
    text={0.91,0.94,0.98,1}, muted={0.58,0.66,0.76,1},
};
local backdrop = {bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1,insets={left=1,right=1,top=1,bottom=1}};

function U.paint(frame, kind, active)
    local color=U.colors[active and "button" or (kind or "panel")];
    GMGenieForever.SetBackdrop(frame, backdrop, unpack(color));
    frame:SetBackdropBorderColor(unpack(U.colors[active and "accent" or "border"]));
end

function U.tooltip(frame, title, body)
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(title, unpack(U.colors.text));
        if body then GameTooltip:AddLine(body, 0.65,0.73,0.83,true); end
        GameTooltip:Show();
    end);
    frame:HookScript("OnLeave", function() GameTooltip:Hide(); end);
end

function U.skinButton(frame)
    U.paint(frame,"button");
    frame:HookScript("OnEnter",function(self) if self:IsEnabled() then U.paint(self,"button",true); end end);
    frame:HookScript("OnLeave",function(self) U.paint(self,"button",self.selected); end);
    frame:HookScript("OnEnable",function(self) self:SetAlpha(1); end);
    frame:HookScript("OnDisable",function(self) self:SetAlpha(0.4); end);
end

function U.skinInput(frame)
    U.paint(frame,"input");
    frame:HookScript("OnEditFocusGained",function(self) self:SetBackdropBorderColor(unpack(U.colors.accent)); end);
    frame:HookScript("OnEditFocusLost",function(self) self:SetBackdropBorderColor(unpack(U.colors.border)); end);
end

function U.label(parent, text, x, y, width, font, muted)
    local item=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight");
    item:SetPoint("TOPLEFT",x,y); item:SetWidth(width); item:SetJustifyH("LEFT");
    item:SetTextColor(unpack(U.colors[muted and "muted" or "text"])); item:SetText(text);
    return item;
end

function U.button(parent, text, x, y, width, action, name, height)
    local item=CreateFrame("Button",name,parent,"BackdropTemplate");
    item:SetSize(width,height or 28); item:SetPoint("TOPLEFT",x,y);
    item:SetNormalFontObject("GameFontHighlightSmall"); item:SetHighlightFontObject("GameFontHighlightSmall");
    item:SetDisabledFontObject("GameFontDisableSmall");
    local label=item:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");
    label:SetPoint("CENTER"); item:SetFontString(label); item:SetText(text);
    U.skinButton(item); item:SetScript("OnClick",action); return item;
end

function U.edit(parent,name,x,y,width,height)
    local item=CreateFrame("EditBox",name,parent,"BackdropTemplate");
    item:SetSize(width,height or 30); item:SetPoint("TOPLEFT",x,y); item:SetAutoFocus(false);
    item:SetFontObject("GameFontHighlight"); item:SetTextInsets(10,10,0,0); item:SetMaxLetters(0);
    U.skinInput(item); item:SetScript("OnEscapePressed",function(self) self:ClearFocus(); end);
    item:SetScript("OnEnterPressed",function(self) self:ClearFocus(); end); return item;
end

function U.panel(parent,x,y,width,height)
    local item=CreateFrame("Frame",nil,parent,"BackdropTemplate");
    item:SetPoint("TOPLEFT",x,y); item:SetSize(width,height); U.paint(item,"panel"); return item;
end

function U.preferences()
    GMGenie_SavedVars=GMGenie_SavedVars or {};
    GMGenie_SavedVars.ui=GMGenie_SavedVars.ui or {scale=1,positions={}};
    local settings=GMGenie_SavedVars.ui;
    settings.positions=settings.positions or {};
    return settings;
end

U.windows={};
function U.savePosition(window)
    local x,y=window:GetCenter();
    if not x or not y then return; end
    local ratio=window:GetEffectiveScale()/UIParent:GetEffectiveScale();
    U.preferences().positions[window:GetName()]={x=x*ratio,y=y*ratio};
end

function U.trackWindow(window)
    if not GMGenieForever.IsCompatible() then
        window:Hide();
        GMGenieForever.WhenCompatible(function() U.trackWindow(window); end);
        return;
    end
    if window.genieTracked then return; end
    window.genieTracked=true; U.windows[#U.windows+1]=window;
    window:SetMovable(true); window:SetClampedToScreen(true); window:EnableMouse(true);
    window:RegisterForDrag("LeftButton"); window:SetScript("OnMouseDown",nil); window:SetScript("OnMouseUp",nil);
    window:SetScript("OnDragStart",window.StartMoving);
    window:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); U.savePosition(self); end);
    window:SetScale(U.preferences().scale or 1);
    local pos=U.preferences().positions[window:GetName()];
    if pos then window:ClearAllPoints(); window:SetPoint("CENTER",UIParent,"BOTTOMLEFT",pos.x,pos.y); end
    window:HookScript("OnHide",function() GameTooltip:Hide(); end);
    if not window.genieNoEscape then UISpecialFrames[#UISpecialFrames+1]=window:GetName(); end
end

function U.window(window,title,width,height,close)
    window:SetSize(width,height); window:SetFrameStrata("DIALOG"); U.paint(window,"window");
    U.trackWindow(window);
    local bar=U.panel(window,1,-1,width-2,47);
    U.label(bar,title,16,-15,width-100,"GameFontNormalLarge");
    U.button(bar,"Close",width-83,-9,66,close or function() window:Hide(); end,nil,28);
    return window;
end

function U.setScale(scale)
    if scale~=0.9 and scale~=1 and scale~=1.1 and scale~=1.25 then return; end
    U.preferences().scale=scale;
    for _,window in ipairs(U.windows) do window:SetScale(scale); end
end

function U.restoreWindows()
    local settings=U.preferences();
    for _,window in ipairs(U.windows) do
        window:SetScale(settings.scale or 1);
        local pos=settings.positions[window:GetName()];
        if pos then window:ClearAllPoints(); window:SetPoint("CENTER",UIParent,"BOTTOMLEFT",pos.x,pos.y); end
    end
end

function U.resetPositions()
    U.preferences().positions={};
    for _,window in ipairs(U.windows) do window:ClearAllPoints(); window:SetPoint("CENTER",UIParent,"CENTER"); end
end

function U.settingsMenu(owner)
    MenuUtil.CreateContextMenu(owner,function(_,root)
        root:CreateTitle("GM Genie");
        root:CreateButton("Settings",function() GMGenieForever.OpenOptions("GM Genie"); end);
        local macros=root:CreateButton("Macro editors");
        for _,name in ipairs({"Whisper Macros","Mail Macros","Teleport Macros","Discipline Macros"}) do
            macros:CreateButton(name,function() GMGenieForever.OpenOptions(name); end);
        end
        root:CreateDivider(); root:CreateTitle("Interface scale");
        for _,scale in ipairs({0.9,1,1.1,1.25}) do
            root:CreateRadio(math.floor(scale*100).."%",function(value) return (U.preferences().scale or 1)==value; end,U.setScale,scale);
        end
        root:CreateDivider(); root:CreateButton("Reset window positions",U.resetPositions);
    end);
end
