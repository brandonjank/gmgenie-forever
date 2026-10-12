"""Exercise login isolation and the real TrinityCore ping protocol in Lua 5.1."""
from pathlib import Path
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''
now=100; frames={}; timers={}; sent={}; addonSent={}; prefixes={}; messages={}
hooks=0; filters=0; errors={}; errorInstalls=0; initializedCount=0; optionCount=0
loggedIn=true; playerName='First Last'; playerRealm='Test Realm'
tinsert=table.insert; tremove=table.remove; unpack=unpack or table.unpack
function print(text) messages[#messages+1]=text end
function GetTime() return now end
function IsLoggedIn() return loggedIn end
function IsInGuild() return true end
function UnitName() return playerName end
function UnitFullName() return playerName,playerRealm end
function GetRealmName() return playerRealm end
function GetBuildInfo() return '1.60.1','70338','date',16001 end
function strtrim(s) return s:match('^%s*(.-)%s*$') end
function debugstack() return '' end
local handler=function(message) errors[#errors+1]=message end
function geterrorhandler() return handler end
function seterrorhandler(f) handler=f; errorInstalls=errorInstalls+1 end
function frame(name)
  local f={events={},scripts={},shown=false,name=name}
  function f:RegisterEvent(e) self.events[e]=true end
  function f:UnregisterEvent(e) self.events[e]=nil end
  function f:SetScript(e,callback) self.scripts[e]=callback end
  function f:Show() self.shown=true end
  function f:Hide() self.shown=false end
  function f:SetShown(value) self.shown=not not value end
  function f:IsVisible() return self.shown end
  function f:GetName() return self.name end
  function f:SetPoint() end
  frames[#frames+1]=f; if name then _G[name]=f end
  return f
end
function CreateFrame(_,name) return frame(name) end
function emit(event,...)
  -- Listeners registered while dispatching do not see a historical event.
  local count=#frames
  for i=1,count do local f=frames[i]
    if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f,event,...) end
  end
end
function advance(seconds)
  now=now+seconds
  local pending=timers; timers={}
  for _,timer in ipairs(pending) do
    if timer.time<=now then timer.callback() else timers[#timers+1]=timer end
  end
end
C_Timer={After=function(delay,callback) timers[#timers+1]={time=now+delay,callback=callback} end}
C_ChatInfo={
  RegisterAddonMessagePrefix=function(prefix) prefixes[#prefixes+1]=prefix; return true end,
  SendAddonMessage=function(...) addonSent[#addonSent+1]={...}; return 0 end,
  SendChatMessage=function(...) sent[#sent+1]={...} end,
}
function ChatFrame_AddMessageEventFilter() filters=filters+1 end
EventRegistry={RegisterCallback=function() hooks=hooks+1 end}
SlashCmdList={}; GMGenieUI={windows={},restoreWindows=function() end}
GMGenie_Minimap=frame('GMGenie_Minimap'); GMGenie_Hud=frame('GMGenie_Hud')
DEFAULT_CHAT_FRAME={AddMessage=function() end}
function UIDropDownMenu_Initialize() end
'''


def session():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    for name in ('Forever.lua', 'Server.lua', 'GMGenie.lua', 'Players.lua',
                 'Tickets.lua', 'Spy.lua', 'Spawns.lua', 'Builder.lua', 'Catalog.lua',
                 'Chronos/Chronos.lua'):
        lua.execute((ROOT / name).read_text(encoding='utf-8-sig'))
    # Keep the actual initialization lifecycle, replacing widget construction.
    lua.execute('''
    function GMGenie.loadSettings() initializedCount=initializedCount+1; GMGenie_SavedVars.hudClosed=closed end
    GMGenie.minimap.reposition=function() end
    local function options() optionCount=optionCount+1 end
    GMGenie.optionsOnLoad=options
    GMGenie.Macros={onLoad=function() end,Whispers={optionsOnLoad=options},
        Mail={optionsOnLoad=options},Tele={optionsOnLoad=options},Discipline={optionsOnLoad=options}}
    GMGenie.Hud={onLoad=function() end,checkStatus=function() GMGenieForever.SendChatMessage('.gm chat','GUILD') end}
    GMGenie.Spawns.onLoad=function() end; GMGenie.Spawns.optionsOnLoad=options
    GMGenie.Tickets.optionsOnLoad=options; GMGenie.Tickets.onLoad=function() end
    GMGenie.Tickets.refresh=function() GMGenieForever.SendChatMessage('.ticket list','GUILD') end
    ''')
    return lua


lua = session()
lua.execute('''
local F=GMGenieForever
GMGenie_SavedVars.ticketType='bug'
assert(F.server.status=='waiting' and not F.initialized)
assert(not GMGenie_Minimap.shown and not GMGenie_Hud.shown and ChronosFrame==nil)
assert(#addonSent==0 and #sent==0 and hooks==0 and filters==0 and errorInstalls==0)
assert(optionCount==0 and initializedCount==0)
for _,f in ipairs(frames) do assert(not f.events.WHO_LIST_UPDATE and not f.scripts.OnUpdate) end
-- Even direct calls, all slash aliases, settings, whispers and dot commands stay inert.
GMGenie.onLoad(); GMGenieForever.RegisterOptions({}); GMGenieForever.OpenOptions('GM Genie')
GMGenie.Players.open(); GMGenie.Players.request(); GMGenie.Builder.open(); GMGenie.Catalog.open()
for _,name in ipairs({'GMGENIEFOREVER','TICKETS','SPY','SPAWNS','GMGENIECATALOG','GMGENIEPLAYERS'}) do SlashCmdList[name]('') end
F.SendChatMessage('.npc delete','GUILD'); F.SendChatMessage('hello','WHISPER',nil,'Other')
F.SendAddonMessage('GMGenie_FVR','bug:1','GUILD')
assert(#sent==0 and #addonSent==0 and initializedCount==0 and optionCount==0)
assert(F.pendingCommands==nil)
emit('ADDON_LOADED','GMGenie'); assert(initializedCount==0)
emit('PLAYER_ENTERING_WORLD'); assert(#addonSent==0)
advance(1)
local S=F.server; local token=S.token
assert(S.status=='checking' and #token==4)
assert(#addonSent==1 and addonSent[1][1]=='TrinityCore' and addonSent[1][2]=='p'..token)
assert(addonSent[1][3]=='WHISPER' and addonSent[1][4]=='First Last')
-- Official-server self echo, other addons, players, realms and stale tokens fail.
for _,reply in ipairs({{'TrinityCore','p'..token,'WHISPER','First Last'},
 {'Other','a'..token,'WHISPER','First Last'}, {'TrinityCore','a'..token,'GUILD','First Last'},
 {'TrinityCore','a'..token,'WHISPER','Someone Else'}, {'TrinityCore','a'..token,'WHISPER','First Last-Foreign'},
 {'TrinityCore','aZZZZ','WHISPER','First Last'}, {'TrinityCore','a'..token..'extra','WHISPER','First Last'}}) do
 emit('CHAT_MSG_ADDON',unpack(reply)); assert(not F.initialized)
end
assert(#sent==0 and hooks==0 and filters==0)
advance(5); assert(S.status=='no response' and S.token==nil)
assert(not S.frame.events.CHAT_MSG_ADDON and not F.IsCompatible())
emit('CHAT_MSG_ADDON','TrinityCore','a'..token,'WHISPER','First Last')
emit('PLAYER_ENTERING_WORLD'); advance(10)
assert(initializedCount==0 and #addonSent==1 and #sent==0) -- no automatic retries
SlashCmdList.GMGENIEFOREVER('check'); local newToken=S.token
assert(newToken~=token and #addonSent==2)
-- An old request/timer cannot complete or expire a new check.
emit('CHAT_MSG_ADDON','TrinityCore','a'..token,'WHISPER','First Last'); assert(not F.initialized)
emit('CHAT_MSG_ADDON','TrinityCore','a'..newToken,'WHISPER','First Last-TestRealm')
assert(F.IsCompatible() and F.initialized and initializedCount==1 and optionCount==7)
assert(GMGenie_Minimap.shown and GMGenie_Hud.shown)
assert(ChronosFrame.shown and Chronos.online and ChronosData.variablesLoaded and ChronosData.enteredWorld)
assert(hooks==1 and filters==1 and errorInstalls==1 and #sent==2)
assert(sent[1][1]=='.gm chat' and sent[1][2]=='WHISPER' and sent[1][4]=='First Last')
assert(sent[2][1]=='.ticket bug list') -- actual settings normally supply bug
assert(not S.frame.events.CHAT_MSG_ADDON)
GMGenie.onLoad(); S.receive('TrinityCore','a'..newToken,'WHISPER','First Last')
F.ActivateIntegrations()
S.check(); advance(5)
assert(initializedCount==1 and #addonSent==2 and hooks==1)
''')

# Fresh reload/session never inherits compatibility from saved variables.
lua = session()
lua.execute('''
assert(not GMGenieForever.IsCompatible())
closed=true; GMGenie_SavedVars.ticketType='bug'
GMGenieForever.server.check(); local token=GMGenieForever.server.token
emit('CHAT_MSG_ADDON','TrinityCore','a'..token,'WHISPER','First Last')
assert(GMGenieForever.initialized and not GMGenie_Hud.shown and GMGenie_Minimap.shown)
''')

for setup, status in [
    ('C_ChatInfo=nil', 'unavailable'),
    ('C_ChatInfo.RegisterAddonMessagePrefix=function() return false end', 'unavailable'),
    ('C_ChatInfo.SendAddonMessage=function() error("failed send") end', 'send failed'),
    ('C_ChatInfo.SendAddonMessage=function() return 3 end', 'send failed'),
]:
    lua = session()
    lua.execute(setup)
    lua.execute(f"GMGenieForever.server.check(); assert(GMGenieForever.server.status=='{status}'); assert(not GMGenieForever.initialized and #sent==0)")

lua = session()
lua.execute('''
GMGenieForever.server.check(); local token=GMGenieForever.server.token
now=now+5 -- timer delivery can lag; the deadline still applies
emit('CHAT_MSG_ADDON','TrinityCore','a'..token,'WHISPER','First Last')
assert(not GMGenieForever.initialized and #sent==0)
''')

lua = session()
lua.execute('''
GMGenie.loadSettings=function() error('GMGenie initialization failure') end
GMGenieForever.server.check(); local token=GMGenieForever.server.token
emit('CHAT_MSG_ADDON','TrinityCore','a'..token,'WHISPER','First Last')
assert(GMGenieForever.server.status=='error' and not GMGenieForever.initialized)
GMGenieForever.SendChatMessage('.kill','GUILD')
assert(#sent==0 and #errors==1 and not GMGenie_Minimap.shown and not GMGenie_Hud.shown)
''')

ns = {'ui': 'http://www.blizzard.com/wow/ui/'}
for filename, tag, name in [('GMGenie.xml', 'Button', 'GMGenie_Minimap'),
                            ('Hud.xml', 'Frame', 'GMGenie_Hud')]:
    root = ET.parse(ROOT / filename).getroot()
    assert root.find(f"ui:{tag}[@name='{name}']", ns).attrib['hidden'] == 'true'

print('PASS: hidden single-folder startup, blocked actions/transport, exact ping acknowledgement, surnames/realms, timeout/retry isolation, fresh sessions, deferred listeners/Chronos, one-time activation and initialization failures')
