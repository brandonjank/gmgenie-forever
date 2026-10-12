"""GM Genie Forever checks; install tests/requirements.txt first."""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
from lupa.lua51 import LuaRuntime

addon = ROOT
lua = LuaRuntime(unpack_returned_tuples=True)
compile_lua = lua.eval('function(s, n) local f,e=loadstring(s,n); assert(f,e); return true end')
count = 0
for path in addon.rglob('*.lua'):
    compile_lua(path.read_text(encoding='utf-8-sig'), str(path))
    count += 1
ns = {'ui': 'http://www.blizzard.com/wow/ui/'}
for path in addon.rglob('*.xml'):
    if path.name == 'GMGenie red.xml':
        continue  # unused original alternative skin, not loaded by this port
    root = ET.parse(path).getroot()
    for scripts in root.findall('.//ui:Scripts', ns):
        for script in scripts:
            if script.text:
                compile_lua('return function(self, ...)\n' + script.text + '\nend', str(path))
                count += 1
    for script in root.findall('.//ui:Script[@file]', ns):
        assert (path.parent / script.attrib['file'].replace('\\', '/')).is_file(), script.attrib
manifest_files = set()
for line in (addon / 'GMGenie.toc').read_text().splitlines():
    if line.strip() and not line.startswith('#'):
        assert line not in manifest_files, f'Duplicate addon load: {line}'
        manifest_files.add(line)
        assert (addon / line.replace('\\', '/')).is_file(), line

lua.execute('''
unpack = unpack or table.unpack
function frame()
    return setmetatable({scripts={}, text='', visible=false}, {__index=function(t,k)
        if k=='SetText' then return function(self,v) self.text=v end end
        if k=='GetText' then return function(self) return self.text end end
        if k=='GetParent' then return function(self) return self.parent end end
        if k=='GetHeight' or k=='GetTextHeight' then return function() return 80 end end
        if k=='SetTextColor' then return function(self,...) self.color={...} end end
        if k=='SetScript' or k=='HookScript' then return function(self,n,f) self.scripts[n]=f end end
        if k=='Show' then return function(self) self.visible=true end end
        if k=='Hide' then return function(self) self.visible=false end end
        if k=='IsVisible' then return function(self) return self.visible end end
        return function() end
    end})
end
frames={}
function CreateFrame() local f=frame(); frames[#frames+1]=f; return f end
function getglobal(n) if not _G[n] then _G[n]=frame() end; return _G[n] end
function geterrorhandler() return function() end end
function seterrorhandler(f) errorHandler=f end
function debugstack() return '' end
function ChatFrame_AddMessageEventFilter() end
EventRegistry={RegisterCallback=function(self,name,callback) linkCallback=callback end}
function IsInGuild() return false end
loggedIn=true
function IsLoggedIn() return loggedIn end
function UnitName(unit) return unit=='player' and 'Tester' or nil end
function strtrim(s) return s:match('^%s*(.-)%s*$') end
function strsplit(sep,s)
    local parts={}; local start=1
    while true do
        local pos=s:find(sep,start,true)
        if not pos then parts[#parts+1]=s:sub(start); break end
        parts[#parts+1]=s:sub(start,pos-1); start=pos+#sep
    end
    return unpack(parts)
end
function CopyTable(t) local c={} for k,v in pairs(t) do c[k]=type(v)=='table' and CopyTable(v) or v end return c end
C_ChatInfo={SendChatMessage=function(...) sent={...} end, SendAddonMessage=function(...) addonSent={...} end}
C_Timer={After=function(_,f) timer=f end}
SlashCmdList={}
GMGenie_SavedVars={ticketType='bug',WIMIntegration=false,showOfflineTickets=false}
GMGenie={showGMMessage=function() end, Macros={Discipline={IpBan={waitingForPin=false}}}}
Chronos={schedule=function() end,scheduleByName=function() end,unscheduleByName=function() end,unscheduleRepeating=function() end}
''')
def load(name):
    lua.execute((addon / name).read_text(encoding='utf-8-sig'))

load('Forever.lua')
load('Server.lua')
lua.execute("GMGenieForever.server.status='compatible'; GMGenieForever.initialized=true")
lua.execute('''
GMGenieForever.SendChatMessage('.gm chat','GUILD')
assert(sent[1]=='.gm chat' and sent[2]=='WHISPER' and sent[4]=='Tester')
GMGenieForever.SendChatMessage('.pin Someone','GUILD'); assert(sent[1]=='.pinfo Someone')
GMGenieForever.SendChatMessage('.gob del 123','GUILD'); assert(sent[1]=='.gobject delete 123')
GMGenieForever.SendChatMessage('.char rename Example','GUILD'); assert(sent[1]=='.character rename Example')
GMGenie_SavedVars.ticketType='complaint'
GMGenieForever.SendChatMessage('.ticket viewid 17','GUILD'); assert(sent[1]=='.ticket complaint view 17')
GMGenieForever.SendChatMessage('.ticket del 17','GUILD'); assert(sent[1]=='.ticket complaint delete 17')
GMGenieForever.SendChatMessage('.pin is literal text','WHISPER',nil,'Someone')
assert(sent[1]=='.pin is literal text' and sent[4]=='Someone')
loggedIn=false
GMGenieForever.SendChatMessage('.gm visible','GUILD'); assert(#GMGenieForever.pendingCommands==1)
loggedIn=true
local _,message,extra = GMGenieForever.DisplayLinks(nil,nil,'|Hcreature_entry:55|h[Example]|h',123)
assert(message=='|Haddon:GMGenie:creature_entry:55|h[Example]|h' and extra==123)
local _,item=GMGenieForever.DisplayLinks(nil,nil,'|Hitem:55|h[Item]|h')
assert(item=='|Hitem:55|h[Item]|h')
assert(SetItemRef==nil and ChatFrame_MessageEventHandler==nil)
''')
load('StarterMacros.lua')
load('Savedvariables.lua')
lua.execute('''
GMGenie.loadSettings()
assert(GMGenie_SavedVars.WIMIntegration==false and GMGenie_SavedVars.showOfflineTickets==false)
GMGenie_SavedVars.objects.Example=55
assert(GMGenie.defaultSettings.objects.Example==nil)
local saved=GMGenie_SavedVars
GMGenie_SavedVars={whispers={['Support - First reply']='My edited greeting',Custom='My own macro'},
    mail={Custom={subject='My subject',macro='My mail'}}}
GMGenie.loadSettings()
assert(GMGenie_SavedVars.whispers['Support - First reply']=='My edited greeting')
assert(GMGenie_SavedVars.whispers.Custom=='My own macro' and GMGenie_SavedVars.mail.Custom.subject=='My subject')
assert(GMGenie_SavedVars.tele['GM - GM Island']=='GMIsland')
assert(GMGenie_SavedVars.starterMacrosVersion==1)
GMGenie_SavedVars.mute['Spam - 5 minutes'].reason='Edited reason'
assert(GMGenie.starterMacros.mute['Spam - 5 minutes'].reason=='Repeated chat spam')
GMGenie_SavedVars.tele['GM - GM Island']=nil
GMGenie.loadSettings()
assert(GMGenie_SavedVars.tele['GM - GM Island']==nil)
GMGenie_SavedVars={}
GMGenie.loadSettings()
local total=0
for category,examples in pairs(GMGenie.starterMacros) do
    for name,value in pairs(examples) do
        total=total+1
        assert(GMGenie_SavedVars[category][name]~=nil)
        if type(value)=='table' then assert(GMGenie_SavedVars[category][name]~=value) end
    end
end
assert(total==28)
GMGenie_SavedVars=saved
''')
load('Hud.lua')
load('Tickets.lua')
load('Spy.lua')
load('Spawns.lua')
move_button = ET.parse(addon / 'Spawns.xml').getroot().find(".//ui:Button[@name='$parent_MoveNpcHere']/ui:Scripts/ui:OnClick", ns)
assert move_button is not None
lua.execute('''
local originalSend = C_ChatInfo.SendChatMessage
local messages = {}
C_ChatInfo.SendChatMessage = function(...) messages[#messages+1] = {...} end
function UnitGUID(unit) assert(unit=='target'); return selectedGuid end
for _,guid in ipairs({'', 'Player-0-00000001', 'Pet-0-1-1-1-1-00000001'}) do
    selectedGuid=guid
    assert(GMGenie.Spawns.moveNpcHere()==false)
end
selectedGuid=nil
assert(GMGenie.Spawns.moveNpcHere()==false and #messages==0)
selectedGuid='Creature-0-1-1-1-12345-00000001'
''' + move_button.text + '''
assert(#messages==1)
assert(messages[1][1]=='.npc move' and messages[1][2]=='WHISPER' and messages[1][4]=='Tester')
C_ChatInfo.SendChatMessage=originalSend
''')
load('Chatreader.lua')
lua.execute('''
-- Switching an empty report list must work before the first Spy request.
GMGenie_Tickets_View=frame()
GMGenie_Tickets_Main=frame()
GMGenie_Spy_InfoWindow=frame()
GMGenie.Tickets.kindButton=frame()
local updateView=GMGenie.Tickets.updateView
GMGenie.Tickets.updateView=function() end
GMGenie_SavedVars.swapTicketWindows=true
GMGenie_Tickets_Main:Show()
assert(GMGenie.Spy.currentRequest==nil)
for _,kind in ipairs({'complaint','suggestion','bug'}) do
    GMGenie.Tickets.tempList=nil
    GMGenie.Tickets.read[17]=true
    GMGenie.Tickets.setType(kind)
    assert(GMGenie_SavedVars.ticketType==kind)
    assert(GMGenie.Tickets.kindButton.text==kind)
    assert(sent[1]=='.ticket '..kind..' list')
    assert(next(GMGenie.Tickets.read)==nil)
    assert(GMGenie_Tickets_Main.visible)
end
GMGenie.Tickets.tempList=nil
GMGenie.Tickets.updateView=updateView
''')
lua.execute('''
for _,name in ipairs({'GMGenie_Hud_GM','GMGenie_Hud_Chat','GMGenie_Hud_Visibility','GMGenie_Hud_Whisper','GMGenie_Hud_Fly'}) do getglobal(name) end
GMGenie.Tickets.listTicket=function(id,name,age,stamp,modified,modifiedStamp)
    listed={id,name,age,stamp,modified,modifiedStamp}
end
GMGenie.Tickets.setAssigned=function(id,name) assigned={id,name} end
GMGenie.Tickets.showMessage=function() end
GMGenie.Spy.resetBoxes=function() end
GMGenie_Spy_InfoWindow=frame()
GMGenie.Tickets.tempList={}
GMGenie.Tickets.currentTicket={ticketId=17}
local header='|cffaaffaaTicket|r:|cffaaccff 17.|r |cff00ff00Created by|r:|cff00ccff Example|r |cff00ff00Created|r:|cff00ccff 1d 2h 3m 4s ago|r '
GMGenie.readSystemMessage(header..'|cff00ff00Assigned to|r:|cff00ccff Moderator|r ')
assert(listed[1]==17 and listed[2]=='Example' and listed[4]==93784 and assigned[2]=='Moderator')
GMGenie.readSystemMessage(header..'|cff00ff00Ticket Message|r: [Line one\nLine two]|r |cff00ff00GM Comment|r: [Comment]|r')
assert(GMGenie.Tickets.currentTicket.message=='Line one\nLine two')
assert(GMGenie.Tickets.currentTicket.comment=='Comment')
GMGenie.Tickets.tempList=nil
GMGenie.Spy.waitingForPin=true
GMGenie.Spy.currentRequest={}
GMGenie.readSystemMessage('│Player  |cffffffff|Hplayer:Tester|h[Tester]|h|r (Player-0-00000001)')
assert(GMGenie.Spy.currentRequest.name=='Tester' and GMGenie.Hud.gm==false)
GMGenie.readSystemMessage('│ GM Mode active, Phase: -1'); assert(GMGenie.Hud.gm==true)
GMGenie.readSystemMessage('│ Account: EXAMPLE (ID: 12), GMLevel: 3')
assert(GMGenie.Spy.currentRequest.account=='EXAMPLE')
GMGenie.readSystemMessage('└ Registration Email: old@example.invalid - Email: new@example.invalid')
assert(GMGenie.Spy.currentRequest.email=='new@example.invalid')
GMGenie.readSystemMessage('│ Map: Kalimdor, Zone: GM Island, Area: GM Island')
assert(GMGenie.Spy.currentRequest.location=='GM Island, Kalimdor')
GMGenie.readSystemMessage('│ Played time: 1d 2h')
assert(GMGenie.Spy.waitingForPin==false and GMGenie_Spy_InfoWindow.visible)
GMGenie.readSystemMessage('Accepting Whisper: ON'); assert(GMGenie.Hud.whisper==true)
GMGenie.readSystemMessage('You are: invisible'); assert(GMGenie.Hud.visibility==false)
GMGenie.readSystemMessage("|cff00ff00|Hplayer:Tester|h[Tester]|h|r's Fly Mode on"); assert(GMGenie.Hud.fly==true)
GMGenie.readSystemMessage("|cffffffff|Hplayer:Other|h[Other]|h|r's Fly Mode off"); assert(GMGenie.Hud.fly==true)
'''.replace("'Line one\nLine two'", "'Line one\\nLine two'").replace('[Line one\nLine two]', '[Line one\\nLine two]'))
load('Macros.Whispers.lua')
load('Macros.Mail.lua')
load('Macros.Tele.lua')
load('Macros.Discipline.lua')
load('Options/Macros.Whispers.lua')
load('Options/Macros.Mail.lua')
lua.execute(r'''
GMGenie_Macros_Whispers_SubjectPopup=frame()
GMGenie_Macros_Whispers_SubjectPopup_Subject=frame()
local sentMessages={}
C_ChatInfo.SendChatMessage=function(...) sentMessages[#sentMessages+1]={...} end
local player='Examplegmxxx'
for title in pairs(GMGenie_SavedVars.whispers) do
    GMGenie.Macros.Whispers.run(player,title)
    if GMGenie_Macros_Whispers_SubjectPopup.visible then
        GMGenie_Macros_Whispers_SubjectPopup_Subject:SetText('the 100% quest')
        GMGenie.Macros.Whispers.sendWithSubject()
        assert(sentMessages[#sentMessages][1]:find('the 100% quest',1,true))
    end
end
assert(#sentMessages==8) -- seven templates; greeting sends two whispers in order
for _,args in ipairs(sentMessages) do
    assert(args[2]=='WHISPER' and args[4]==player and #args[1]<=255)
    assert(not args[1]:find('NAME',1,true) and not args[1]:find('SUBJECT',1,true))
end
sentMessages={}
for title in pairs(GMGenie_SavedVars.mail) do GMGenie.Macros.Mail.run(player,title) end
assert(#sentMessages==5)
for _,args in ipairs(sentMessages) do
    assert(args[1]:match('^%.send mail '..player..' "[^"]+" "[^"]+"$'))
    assert(args[2]=='WHISPER' and args[4]=='Tester' and #args[1]<=255)
    assert(not args[1]:find('NAME',1,true))
end
sentMessages={}
for title,dest in pairs(GMGenie_SavedVars.tele) do
    GMGenie.Macros.Tele.run(player,title)
    local expected=dest=='RECALL' and '.recall '..player or '.tele name '..player..' '..dest
    assert(sentMessages[#sentMessages][1]==expected)
end
assert(#sentMessages==10)
sentMessages={}
for category,module in pairs({mute='Mute',charBan='CharBan',accBan='AccBan',ipBan='IpBan'}) do
    for title,macro in pairs(GMGenie_SavedVars[category]) do
        assert(macro.announceToServer==false and macro.duration~='0')
        GMGenie.Macros.Discipline[module].run(player,title)
        if category=='ipBan' then GMGenie.Macros.Discipline.IpBan.processPin('192.0.2.1') end
        local command=sentMessages[#sentMessages][1]
        local prefix=({mute='.mute '..player,charBan='.ban character '..player,
            accBan='.ban playeraccount '..player,ipBan='.ban ip 192.0.2.1'})[category]
        assert(command==prefix..' '..macro.duration..' '..macro.reason)
        assert(sentMessages[#sentMessages-1][1]:find('.gmnameannounce ',1,true)==1)
    end
end
-- Selecting/editing a bundled example exercises the modern editor callback.
for _,kind in ipairs({'Whispers','Mail'}) do
    local prefix='GMGenie_Macros_'..kind..'_OptionsWindow'
    for _,suffix in ipairs({'_Name','_Save','_Delete'}) do getglobal(prefix..suffix) end
    local edit=getglobal(prefix..'_Macro_Frame_Text')
    edit.parent=frame()
    getglobal(prefix..'_Subject'):SetText('Subject')
    GMGenie.Macros[kind].edit({value=kind=='Whispers' and 'Support - First reply' or 'Example - Two-part welcome'})
    GMGenie.Macros[kind].updateMacroText()
    assert(edit.color[2]==1)
    edit:SetText(string.rep('x',300)..'\nshort')
    GMGenie.Macros[kind].updateMacroText()
    assert(edit.color[2]==0) -- an overlong first line must stay red
end
''')
print(f'PASS: {count} Lua/XML chunks, manifest resources, command routing, report/player-info parsing, links, saved settings, 28 starter macros, migration, editors, and selected NPC movement')
