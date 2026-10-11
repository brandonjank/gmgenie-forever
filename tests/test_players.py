"""Exercise native Who searches, response limits, freshness and named travel."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute((ROOT/'tests/ui_mock.lua').read_text())
lua.execute('''
now=100; whoSent={}; whoRows={}; whoTotal=nil
function GetTime() return now end
function IsLoggedIn() return true end
function GetNormalizedRealmName() return 'TestRealm' end
C_FriendList={
 SetWhoToUi=function(value) whoToUI=value end,
 SendWho=function(query) whoSent[#whoSent+1]=query end,
 GetNumWhoResults=function() return #whoRows,whoTotal or #whoRows end,
 GetWhoInfo=function(index) return whoRows[index] end,
}
''')
for name in ('UI.lua','Players.lua'):
    lua.execute((ROOT/name).read_text(encoding='utf-8-sig'))
lua.execute('''
local P=GMGenie.Players
local function row(name,zone) return {fullName=name,area=zone,level=30,classStr='Mage'} end
P.open(); assert(P.window.width==760 and P.window.level>40)
assert(#whoSent==1 and whoSent[1]=='1-255' and whoToUI and P.pending and #sent==0)
P.request(); assert(#whoSent==1)
whoRows={row('Zed','Dun Morogh'),row('Tester-TestRealm','Stormwind City'),row('Alpha','Stormwind City'),row('Alpha','Stormwind City')}
P.onWhoResults(); assert(not P.pending and #P.entries==3 and P.fresh and not P.limited)
assert(P.entries[1].name=='Alpha' and P.entries[1].zone=='Stormwind City')
assert(P.entries[2].name=='Tester' and not P.rows[2].tp.enabled and not P.rows[2].sum.enabled)
targetName='UnrelatedTarget'; P.rows[1].tp:Fire('OnClick'); P.rows[1].sum:Fire('OnClick')
assert(sent[1][1]=='.appear Alpha' and sent[2][1]=='.summon Alpha' and targetName=='UnrelatedTarget')
P.travel(P.entries[2],'sum'); P.travel({name='Alpha'},'tp'); P.travel(P.entries[1],'bad'); assert(#sent==2)
for _,name in ipairs({'Other Player','Evil\\n.summon Tester','Alpha;','A-OtherRealm','|Hplayer:X|h'}) do assert(not P.validName(name)) end
assert(P.validName('Éowyn'))
assert(P.characterName('Alpha-Test Realm')=='Alpha')
assert(P.characterName('Alpha-OtherRealm')=='Alpha-OtherRealm')
P.query:SetText('stormwind alpha'); assert(P.rows[1].entry.name=='Alpha' and not P.rows[2].visible)
P.query:SetText('['); assert(P.empty.visible)
assert(#whoSent==1)
P.query:SetText(''); now=146; P.auto=false; P.tick()
assert(not P.rows[1].tp.enabled); P.travel(P.entries[1],'tp'); assert(#sent==2)
P.request(); assert(#whoSent==2 and not P.rows[1].tp.enabled)
now=157; P.tick(); assert(P.error and #P.entries==3 and not P.fresh and not P.pending)
P.auto=true; now=200; P.tick(); assert(#whoSent==2)
P.query:SetText('NewPlayer'); P.query:Fire('OnEnterPressed')
assert(whoSent[3]=='1-255 NewPlayer')
whoRows={row('NewPlayer','Unknown Land')}; P.onWhoResults()
assert(#P.entries==1 and P.entries[1].zone=='Unknown Land' and not P.byName.alpha)
P.travel({name='Alpha'},'sum'); assert(#sent==2)
now=216; P.tick(); assert(not P.pending and #whoSent==3)
P.refresh:Fire('OnClick'); assert(P.pending and #whoSent==4)
whoRows={}; P.onWhoResults(); assert(#P.entries==0 and P.fresh and not P.pending)
P.window:Hide(); now=240; P.tick(); assert(#whoSent==4)
P.query:SetText(''); P.open(); assert(#whoSent==5)
whoRows={}; for i=1,50 do whoRows[i]=row('Player'..string.char(65+math.floor((i-1)/26))..string.char(65+(i-1)%26),'Elwynn Forest') end
P.onWhoResults(); assert(#P.entries==50 and P.limited and P.status.text:find('limit'))
P.next:Fire('OnClick'); assert(P.page==2 and P.rows[1].entry.name=='PlayerAM')
P.page=99; P.render(); assert(P.page==5 and not P.next.enabled and not P.rows[3].visible)
P.query:SetText('PlayerAA'); assert(P.page==1 and P.rows[1].entry.name=='PlayerAA')
P.window:Hide(); now=256; P.tick(); assert(not P.pending)
P.open(); assert(#whoSent==6)
whoRows={{fullName='Bad\\nName',area='Elwynn'}}; P.onWhoResults()
assert(P.error and not P.fresh and #P.entries==50)
now=261; P.request(); whoRows={row('Other-OtherRealm','City')}; whoTotal=120; P.query:SetText(''); P.onWhoResults()
assert(P.limited and not P.rows[1].tp.enabled)
local old=P.entries
whoRows={row('Late','City')}; P.onWhoResults(); assert(P.entries==old)
now=270; local send=C_FriendList.SendWho; C_FriendList.SendWho=function() error('blocked') end
P.request(); assert(P.error and not P.pending and P.entries==old)
C_FriendList.SendWho=send
now=280; local api=C_FriendList; C_FriendList=nil; P.request(); assert(P.error and not P.pending)
C_FriendList=api
now=290; P.request(); P.window:Hide(); now=301; P.tick(); assert(P.error and not P.pending)
assert(#sent==2)
''')
print('PASS: native Who searches, zones, response limits, self/foreign/stale guards, paging, API errors, timeouts and hardware-triggered refreshes')

lua.execute('''
local P=GMGenie.Players
GMGenie.showGMMessage=function(text) warning=text end
now=350; whoTotal=nil; whoRows={{fullName='Alpha',area='Stormwind',level=30,classStr='Mage'},{fullName='Tester',area='Stormwind'}}
P.query:SetText(''); P.open(); P.onWhoResults()
local entry=P.entries[1]
assert(P.rows[1].actions.enabled and not P.rows[2].actions.enabled)
P.rows[1].actions:Fire('OnClick'); lastMenu.items[1].callback()
assert(P.action.kind=='kick' and P.actionWindow.visible and #sent==2)
P.confirmAction(); assert(#sent==2 and P.actionStatus.text:find('reason'))
for _,reason in ipairs({'','  ','bad\\n.die','bad|Hplayer:Other|h',string.rep('a',161)}) do
 P.reason:SetText(reason); P.confirmAction(); assert(#sent==2)
end
local requests=#whoSent; now=366; P.tick(); assert(#whoSent==requests)
P.reason:SetText('Repeated disruption'); P.confirm:Fire('OnClick')
assert(sent[3][1]=='.kick Alpha Repeated disruption' and not P.action)
P.confirmAction(); assert(#sent==3)
P.beginAction(entry,'ban'); assert(P.duration.visible and P.duration.text=='1h')
P.reason:SetText('Test reason')
for _,duration in ipairs({'0','-1','1w','1.5h','1h 2d','999999999d','1h\\n.die'}) do
 P.duration:SetText(duration); P.confirmAction(); assert(#sent==3)
end
P.duration:SetText('7d'); P.confirmAction(); assert(sent[4][1]=='.ban character Alpha 7d Test reason')
P.beginAction(entry,'kick'); P.cancelAction(); P.confirmAction(); assert(#sent==4)
targetName='Other'; targetPlayer=true; targetGuid='Player-1-8'
P.beginAction(entry,'kill'); assert(not P.action and warning:find('Target Alpha'))
targetName='Alpha'; targetGuid='Player-1-2'; targetPlayer=false
P.beginAction(entry,'kill'); assert(not P.action)
targetPlayer=true; P.beginAction(entry,'kill'); assert(P.action and not P.reason.visible)
targetGuid='Player-1-3'; P.confirmAction(); assert(#sent==4 and P.actionStatus.text:find('Target changed'))
P.cancelAction(); targetGuid='Player-1-2'; P.beginAction(entry,'kill'); P.confirmAction()
assert(sent[5][1]=='.die' and not P.action)
P.beginAction(entry,'kick'); P.reason:SetText('Old snapshot'); now=372; P.request(); P.onWhoResults()
P.confirmAction(); assert(#sent==5 and P.actionStatus.text:find('Player list changed'))
P.cancelAction(); entry=P.entries[1]; P.beginAction(entry,'kick'); P.actionWindow:Hide(); P.confirmAction(); assert(#sent==5)
P.beginAction(entry,'ban'); now=418; P.confirmAction(); assert(#sent==5)
P.cancelAction(); P.beginAction(P.entries[2],'ban'); assert(not P.action)
''')
print('PASS: Kick/Ban/Kill menus, reasons and durations, confirmations, cancellations, duplicate submits, exact selected-player GUID and stale-snapshot guards')

# Forever full display names retain their surname; GM commands use characters.name.
lua.execute("""
local P=GMGenie.Players
now=500; P.cancelAction(); whoRows={{fullName='Ben Hacks',area='Elwynn Forest'},{fullName='Tester Surname-TestRealm',area='City'}}
P.query:SetText(''); P.open(); P.onWhoResults()
assert(P.fresh and not P.error and #P.entries==2 and P.entries[1].name=='Ben Hacks')
assert(P.rows[1].actions.enabled and not P.rows[2].actions.enabled and P.rows[2].name.text=='Tester Surname (you)')
local entry=P.entries[1]; local count=#sent
P.travel(entry,'tp'); P.travel(entry,'sum')
assert(sent[count+1][1]=='.appear Ben' and sent[count+2][1]=='.summon Ben')
P.beginAction(entry,'kick'); assert(P.actionTitle.text=='Kick Ben Hacks')
P.reason:SetText('Test reason'); P.confirmAction(); assert(sent[count+3][1]=='.kick Ben Test reason')
P.beginAction(entry,'ban'); P.reason:SetText('Test reason'); P.confirmAction()
assert(sent[count+4][1]=='.ban character Ben 1h Test reason')
targetName='Ben Hacks'; targetPlayer=true; targetGuid='Player-1-32'; P.beginAction(entry,'kill')
assert(P.action); P.confirmAction(); assert(sent[count+5][1]=='.die')
assert(P.commandName('Ben Hacks')=='Ben' and P.commandName('Ben Hacks-OtherRealm')==nil)
for _,name in ipairs({' Ben Hacks','Ben  Hacks','Ben Hacks ','Ben|Hplayer:Other|h','Ben; Hacks'}) do assert(not P.commandName(name)) end
now=515; P.tick(); assert(not P.pending)
""")
print('PASS: Forever surnames, canonical first-name command arguments, full-name confirmations, self/realm checks and selected-player matching')
