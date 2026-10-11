"""Exercise Forever online roster transactions, privacy, freshness and named travel."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute((ROOT/'tests/ui_mock.lua').read_text())
lua.execute('''
now=100
function GetTime() return now end
function IsLoggedIn() return true end
function ChatFrame_AddMessageEventFilter(_,callback) rosterFilter=callback end
GMGenieForever.PlainText=function(text) return (text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')) end
C_Map={GetAreaInfo=function(id) if id==1519 then return 'Stormwind City' elseif id==1 then return 'Dun Morogh' end end}
''')
for name in ('UI.lua','Players.lua'):
    lua.execute((ROOT/name).read_text(encoding='utf-8-sig'))
lua.execute('''
local P=GMGenie.Players
local title='-======================== Characters Online =======================-'
local header='-[         Account][   Character][             IP][Map][Zone][Exp][GMLev]-'
local bar='-==================================================================-'
local function line(name,map,zone)
 return string.format('-[%16s][%12s][%15s][%3d][%4d][%d][%d]-','private-account',name,'192.0.2.1',map,zone,0,3)
end
local function begin()
 P.consume(title); P.consume(header); P.consume(bar)
end
P.open(); assert(P.window.width==760 and P.window.level>40)
assert(#sent==1 and sent[1][1]=='.account onlinelist' and P.pending)
P.request(); assert(#sent==1) -- no duplicate requests
assert(P.filter(nil,nil,title) and P.filter(nil,nil,header))
assert(not P.filter(nil,nil,'Permission denied.') and not P.filter(nil,nil,'Unrelated system message'))
P.consume(line('Unrelated',0,1)); assert(#P.pending.entries==0) -- require table framing
begin()
P.consume(line('Zed',0,1)); P.consume(line('Tester',0,1519)); P.consume(line('Alpha',0,1519))
P.consume(line('Alpha',0,1519)); assert(#P.pending.entries==3) -- deduplicate
assert(#P.entries==0) -- replace snapshot only on complete response
assert(P.filter(nil,nil,line('Alpha',0,1519)))
P.consume(bar); assert(not P.pending and #P.entries==3 and P.fresh)
assert(P.filter(nil,nil,bar)) -- closing line hidden even when event listener runs first
assert(P.entries[1].name=='Alpha' and P.entries[1].zone=='Stormwind City')
assert(P.entries[2].name=='Tester' and not P.rows[2].tp.enabled and not P.rows[2].sum.enabled)
for _,entry in ipairs(P.entries) do
 for key,value in pairs(entry) do assert(key~='account' and key~='ip' and value~='192.0.2.1') end
end
targetName='UnrelatedTarget'; P.rows[1].tp:Fire('OnClick'); P.rows[1].sum:Fire('OnClick')
assert(sent[2][1]=='.appear Alpha' and sent[3][1]=='.summon Alpha' and targetName=='UnrelatedTarget')
P.travel(P.entries[2],'sum'); P.travel({name='Alpha'},'tp'); P.travel(P.entries[1],'bad'); assert(#sent==3)
for _,name in ipairs({'Other Player','Evil\\n.summon Tester','Alpha;','A-OtherRealm','|Hplayer:X|h'}) do assert(not P.validName(name)) end
assert(P.validName('Éowyn'))
P.query:SetText('stormwind alpha'); assert(P.rows[1].entry.name=='Alpha' and not P.rows[2].visible)
P.query:SetText('['); assert(P.empty.visible) -- plain text, not Lua patterns
P.query:SetText(''); now=146; P.auto=false; P.tick()
assert(not P.rows[1].tp.enabled); P.travel(P.entries[1],'tp'); assert(#sent==3)
P.request(); assert(#sent==4 and not P.rows[1].tp.enabled)
begin(); P.consume(line('OnlyOne',0,99999)); now=157; P.tick()
assert(P.error and #P.entries==3 and not P.fresh and not P.pending) -- partial results discarded
P.auto=true; now=200; P.tick(); assert(#sent==4) -- errors pause automatic retry
P.request(); begin(); P.consume(line('NewPlayer',1,99999)); P.consume(bar)
assert(#P.entries==1 and P.entries[1].zone=='Zone 99999' and not P.byName.alpha)
P.travel({name='Alpha'},'sum'); assert(#sent==5)
now=216; P.tick(); assert(P.pending and #sent==6)
P.consume('No online players.'); assert(#P.entries==0 and P.fresh and not P.pending)
now=218; assert(not P.filter(nil,nil,line('ManualList',1,1))) -- manual command output unaffected
P.window:Hide(); now=240; P.tick(); assert(#sent==6) -- no hidden polling
P.open(); assert(#sent==7); begin()
for i=1,65 do P.consume(line('Player'..string.char(65+math.floor((i-1)/26))..string.char(65+(i-1)%26),0,1)) end
P.consume(bar); assert(#P.entries==65) -- no native /who result cap
P.next:Fire('OnClick'); assert(P.page==2 and P.rows[1].entry.name=='PlayerAM')
P.page=99; P.render(); assert(P.page==6 and not P.next.enabled and not P.rows[6].visible)
P.query:SetText('PlayerAA'); assert(P.page==1 and P.rows[1].entry.name=='PlayerAA')
P.window:Hide(); now=256; P.tick(); assert(not P.pending)
P.open(); assert(#sent==8); begin(); P.consume(line('Bad Name',0,1)); P.consume(bar)
assert(P.error and not P.fresh and #P.entries==65) -- malformed responses never become partial snapshots
now=260; P.request(); P.window:Hide(); now=271; P.tick(); assert(P.error and not P.pending)
''')
print('PASS: complete online roster transactions, zone resolution, private-field exclusion, chat filtering, named TP/SUM, self/stale guards, paging, timeouts and visible-only polling')
