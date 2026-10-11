-- Strict mock of the public widget APIs used by the addon, with event hooks.
local methods={};
function frame(name)
    local f=setmetatable({name=name,scripts={},hooks={},text="",visible=false,enabled=true,scale=1,level=10}, {__index=methods});
    if name then _G[name]=f; end
    return f;
end
function methods:SetScript(event,callback) self.scripts[event]=callback; end
function methods:HookScript(event,callback) self.hooks[event]=self.hooks[event] or {}; table.insert(self.hooks[event],callback); end
function methods:Fire(event,...)
    if self.scripts[event] then self.scripts[event](self,...); end
    for _,callback in ipairs(self.hooks[event] or {}) do callback(self,...); end
end
function methods:SetText(text)
    local changed=self.text~=text; self.text=text;
    if changed then self:Fire("OnTextChanged"); end
end
function methods:GetText() return self.text; end
function methods:GetName() return self.name; end
function methods:Show() self.visible=true; self:Fire("OnShow"); end
function methods:Hide() self.visible=false; self:Fire("OnHide"); end
function methods:IsShown() return self.visible; end
methods.IsVisible=methods.IsShown;
function methods:SetShown(value) if value then self:Show(); else self:Hide(); end end
function methods:SetEnabled(value) self.enabled=not not value; self:Fire(value and "OnEnable" or "OnDisable"); end
function methods:IsEnabled() return self.enabled; end
function methods:SetScale(value) self.scale=value; end
function methods:GetEffectiveScale() return self.scale; end
function methods:GetFrameLevel() return self.level; end
function methods:SetFrameLevel(level) self.level=level; end
function methods:GetCenter() return 200,100; end
function methods:SetPoint(...) self.point={...}; end
function methods:CreateFontString() return frame(); end
function methods:CreateTexture() return frame(); end
function methods:SetTexture(value) self.texture=value; end
function methods:SetHyperlink(value) self.link=value; end
function methods:ClearModel() self.modelID=0; end
function methods:SetDisplayInfo(id) self.modelID=id; self:Fire("OnModelLoaded"); end
function methods:SetCreature(id) self.modelID=id; self:Fire("OnModelLoaded"); end
function methods:SetUnit(unit) self.unit=unit; self.modelID=42; return true; end
function methods:Undress() self.item=nil; end
function methods:TryOn(item) self.item=item; self:Fire("OnModelLoaded"); end
function methods:GetModelFileID() return self.modelID or 0; end
function methods:SetRotation(value) self.rotation=value; end
function methods:SetCamDistanceScale(value) self.distance=value; end
function methods:SetPortraitZoom(value) self.portraitZoom=value; end
function methods:GetFontString() return self.fontString; end
function methods:SetFontString(fontString) self.fontString=fontString; end
function methods:SetBackdropColor(...) self.color={...}; end
function methods:SetBackdropBorderColor(...) self.border={...}; end
function methods:SetSize(width,height) self.width=width; self.height=height; end
function methods:SetWidth(width) self.width=width; end
function methods:SetHeight(height) self.height=height; end
function methods:ClearFocus() self:Fire("OnEditFocusLost"); end
for _,name in ipairs({"SetJustifyH","SetTextColor","SetAutoFocus","SetFontObject","SetTextInsets","SetMaxLetters","SetBackdrop","RegisterForDrag","SetMovable","SetClampedToScreen","EnableMouse","SetFrameStrata","SetNormalFontObject","SetHighlightFontObject","SetDisabledFontObject","ClearAllPoints","HighlightText","EnableMouseWheel","StartMoving","StopMovingOrSizing","RegisterEvent","SetAlpha","SetOwner","AddLine"}) do
    methods[name]=function() end;
end
function CreateFrame(_,name,parent) local f=frame(name); f.parent=parent; return f; end
function getglobal(name) return _G[name]; end
unpack=unpack or table.unpack;
UIParent=frame("UIParent"); GameTooltip=frame("GameTooltip"); UISpecialFrames={};
GMGenie={}; GMGenie_SavedVars={}; SlashCmdList={}; sent={};
GMGenieForever={SetBackdrop=function(f,_,...) f:SetBackdropColor(...); end,
    SendChatMessage=function(...) sent[#sent+1]={...}; end,
    OpenOptions=function(name) openedOptions=name; end};
local menuMethods={};
function menuDescription() return setmetatable({items={}}, {__index=menuMethods}); end
function menuMethods:CreateButton(label,callback,data)
    local item=menuDescription(); item.label=label; item.callback=callback; item.data=data;
    table.insert(self.items,item); return item;
end
function menuMethods:CreateRadio(label,selected,callback,data)
    local item=self:CreateButton(label,callback,data); item.isSelected=selected; return item;
end
function menuMethods:CreateTitle() end
function menuMethods:CreateDivider() end
function menuMethods:SetScrollMode(height) self.scrollHeight=height; end
MenuUtil={CreateContextMenu=function(owner,generator) lastMenu=menuDescription(); generator(owner,lastMenu); return lastMenu; end};
targetGuid=nil; targetPlayer=false; targetName=nil;
function UnitGUID() return targetGuid; end
function UnitIsPlayer() return targetPlayer; end
function UnitLevel() return 25; end
function UnitName(unit) return unit=="player" and "Tester" or targetName; end
