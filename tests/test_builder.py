"""Exercise the builder remote and real Forever response formats in Lua 5.1."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute((ROOT/'tests/ui_mock.lua').read_text())
lua.execute('''
now=100; facing=0; map=0
function GetTime() return now end
function GetPlayerFacing() return facing end
function UnitPosition() return 1,2,3,map end
GMGenieForever.PlainText=function(message)
    return (message:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"))
end
GMGenie.showGMMessage=function(message) warning=message end
''')
for name in ('UI.lua','Spawns.lua','Builder.lua'):
    lua.execute((ROOT/name).read_text(encoding='utf-8-sig'))
lua.execute('''
local B=GMGenie.Builder
local function response(text) B.readSystemMessage(text) end
local function count() return #sent end
local function last() return sent[#sent][1] end
local function gps(x,y,z,o)
    response("Map: 0 (Eastern Kingdoms) Zone: 1 (Test) Area: 1 (Test)")
    response(string.format("X: %f Y: %f Z: %f Orientation: %f",x,y,z,o))
end
local function select()
    assert(B.selectNearest())
    response("Selected object:")
    response("|cffffffff|Hgameobject:42|h[Test Crate]|h|r GUID: 42 ID: 100")
    response("X: 10.000000 Y: 20.000000 Z: 30.000000 MapId: 0")
    assert(not B.ready())
    response("Orientation: 0.000000")
    assert(B.ready() and B.entity.id=='42')
end
local function ack(kind,x,y,z,o)
    response("Game Object |cffffffff|Hgameobject:42|h[Test Crate]|h|r (GameObject-0-0-0-100-999) "..kind)
    assert(last()=='.gps |Hgameobject:42|h[Builder object]|h')
    assert(not B.ready())
    gps(x,y,z,o)
    assert(B.ready())
end
B.open()
assert(B.window.visible and B.window.width==304 and B.window.height==654)
assert(not B.moveHere.enabled and not B.remove.enabled and not B.undoButton.enabled)
assert(not B.nudge(1,0,0) and count()==0)
assert(not B.selectId('42 .server shutdown') and count()==0)
assert(not B.selectId('0') and not B.selectId('-1'))
select(); assert(count()==1 and last()=='.gobject target') -- selection never deletes
assert(B.selection.text:find('Test Crate',1,true) and B.moveHere.enabled)
local n=count()
B.transforms[1]:Fire('OnClick') -- Forward
assert(last()=='.gobject move 42 11.000000 20.000000 30.000000')
assert(B.pending.before.stamp==now)
assert(B.entity.x==10 and not B.ready()) -- no optimistic movement
assert(not B.nudge(1,0,0) and count()==n+1)
response('Game Object |cffffffff|Hgameobject:43|h[Other]|h|r (GameObject-999) moved')
assert(count()==n+1 and B.pending.kind=='transform') -- exact spawn acknowledgement
ack('moved',11,20,30,0)
assert(B.undo.before.x==10 and B.undoButton.enabled)
assert(B.undoLast() and last()=='.gobject move 42 10.000000 20.000000 30.000000')
ack('moved',10,20,30,0)
assert(B.undo==nil and not B.undoButton.enabled)

facing=math.pi/2; B.step=0.5
B.nudge(1,0,0); assert(last()=='.gobject move 42 10.000000 20.500000 30.000000')
ack('moved',10,20.5,30,0)
B.nudge(0,1,0); assert(last()=='.gobject move 42 9.500000 20.500000 30.000000')
ack('moved',9.5,20.5,30,0)
B.nudge(0,0,-1); assert(last()=='.gobject move 42 9.500000 20.500000 29.500000')
ack('moved',9.5,20.5,29.5,0)
B.rotate(-1); assert(last()=='.gobject turn 42 6.021386')
ack('turned to 6.021386',9.5,20.5,29.5,6.021386)
B.undoLast(); assert(last()=='.gobject turn 42 0.000000')
ack('turned to 0.000000',9.5,20.5,29.5,0)
B.moveToPlayer(); assert(last()=='.gobject move 42')
ack('moved',1,2,3,0)
B.facePlayer(); assert(last()=='.gobject turn 42')
ack('turned to 1.570796',1,2,3,1.570796)

n=count(); B.ask('delete'); assert(B.confirm.visible and count()==n)
B.confirm:Hide(); assert(not B.confirmAction() and count()==n)
B.ask('delete'); assert(B.confirmAction() and last()=='.gobject delete 42')
assert(not B.confirmAction() and count()==n+1)
response('Game Object (43) removed'); assert(B.entity)
response('Game Object (42) removed'); assert(not B.entity and not B.pending)

B.entry:SetText('100 bad'); assert(not B.ask('spawn'))
B.entry:SetText('100'); n=count(); B.ask('spawn'); assert(count()==n)
B.confirmAction(); assert(last()=='.gobject add 100')
response(">> Add Game Object '101' (Other) (GUID: 55) added at '1 2 3'.")
assert(B.pending.kind=='spawn')
response(">> Add Game Object '100' (Test Crate) (GUID: 55) added at '1 2 3'.")
assert(last()=='.gps |Hgameobject:55|h[Builder object]|h')
gps(1,2,3,0); assert(B.entity.id=='55' and B.ready())

-- Handle a complete multiline selection message as well as split packets.
B.selectNearest()
response('Selected object:\\n|cffffffff|Hgameobject:42|h[Test Crate]|h|r GUID: 42 ID: 100\\nX: 10 Y: 20 Z: 30 MapId: 0\\nOrientation: 0\\nPhaseId 0\\nPhaseGroup 0')
assert(B.ready() and B.entity.id=='42')
B.nudge(1,0,0); response('Game Object (42) not found!')
assert(not B.pending and not B.ready() and B.entity.x==10)
assert(B.message:find('not found',1,true))
B.refreshSelection(); gps(10,20,30,0); assert(B.ready())
now=now+46; B.tick(); assert(not B.ready() and not B.moveHere.enabled)
B.refreshSelection(); now=now+9; B.tick(); assert(not B.pending and not B.ready())
n=count(); gps(999,999,999,0); assert(not B.ready() and count()==n) -- ignore late unsolicited reply

select(); map=1; assert(not B.ready())
B.events:Fire('OnEvent','ZONE_CHANGED_NEW_AREA'); assert(not B.entity and not B.undo)
map=0; select()
B.ask('delete'); B.events:Fire('OnEvent','PLAYER_ENTERING_WORLD'); assert(not B.confirm.visible)
assert(not B.confirmAction())

-- NPC actions never teleport the GM and reject players, pets and target changes.
B.setMode('npc'); targetGuid='Player-1-2'; targetPlayer=true; B.update()
assert(not B.moveHere.enabled and not B.moveToPlayer())
targetGuid='Pet-0-0-1'; targetPlayer=false; assert(not B.moveToPlayer())
targetGuid='Creature-0-0-0-1-5'; targetName='Dummy'; B.update()
assert(B.moveHere.enabled and not B.face.enabled and not B.transforms[1].enabled)
B.moveToPlayer(); assert(last()=='.npc move')
response('Creature moved.'); assert(not B.pending)
B.ask('delete'); targetGuid='Creature-0-0-0-1-6'; assert(not B.confirmAction())
B.ask('delete'); B.confirmAction(); assert(last()=='.npc delete')
response('Creature Removed'); assert(not B.pending and B.message=='NPC deleted.')
B.entry:SetText('123'); B.ask('spawn'); B.confirmAction(); assert(last()=='.npc add 123')
now=now+9; B.tick(); assert(not B.pending)

GMGenie_SavedVars.objects={['Crate']=100}; B.setMode('object'); B.presetMenu(B.window)
lastMenu.items[1].callback(); assert(B.entry.text=='100')
S=GMGenie.Spawns; n=count(); S.targetObject(); assert(last()=='.gobject target' and count()==n+1)
assert(not last():find('delete',1,true))
for _,command in ipairs(sent) do assert(not command[1]:match('^%.go xyz')) end
-- Local send failures and pre-login calls cannot enqueue a later world mutation.
B.invalidate(); local originalSend=GMGenieForever.SendChatMessage
GMGenieForever.SendChatMessage=function() error('send failed') end
assert(not B.selectNearest() and not B.pending and B.message:find('send failed',1,true))
GMGenieForever.SendChatMessage=originalSend
function IsLoggedIn() return false end
n=count(); assert(not B.selectNearest() and not B.pending and count()==n)
''')
print('PASS: builder remote, exact spawn selection, movement geometry, rotation, server acknowledgements, undo, expiry, errors, confirmations, NPC guards and presets')
