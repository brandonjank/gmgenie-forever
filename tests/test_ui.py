"""Exercise dashboard callbacks, native menus, targeting and saved layout in Lua 5.1."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute((ROOT/'tests/ui_mock.lua').read_text())
for name in ('UI.lua','CommandData.lua','CommandHelp.lua','CommandForms.lua','Commands.lua','Hud.lua'):
    lua.execute((ROOT/name).read_text(encoding='utf-8-sig'))
lua.execute('''
GMGenie_Hud=frame('GMGenie_Hud'); GMGenie_Tickets_Main=frame('GMGenie_Tickets_Main')
GMGenie_SavedVars.hudClosed=false
GMGenie.Players={open=function() playersOpened=true end}
GMGenie.Catalog={open=function() catalogOpened=true end}
GMGenie.Spy={spy=function(name) inspected=name end}
GMGenie.Spawns={toggle=function() builderOpened=true end}
GMGenie.Tickets={setType=function(kind) reportKind=kind end}
GMGenie.showGMMessage=function(message) warning=message end
local H=GMGenie.Hud
H.onLoad(); assert(GMGenie_Hud.width==300 and GMGenie_Hud.height==534)
H.toggleCompact(); assert(GMGenie_SavedVars.hudCompact and GMGenie_Hud.height==48 and not H.body.visible)
H.toggleCompact(); assert(not GMGenie_SavedVars.hudCompact and GMGenie_Hud.height==534 and H.body.visible)
assert(H.targetName.parent.parent==H.body) -- target card also collapses
assert(not H.inspect.enabled and not H.targetCommands.enabled and #sent==0)
H.inspectTarget(); H.browseTarget(); assert(not inspected and #sent==0)
GMGenie_Hud_Players:Fire('OnClick'); assert(playersOpened)
GMGenie_Hud_Catalog:Fire('OnClick'); assert(catalogOpened)
targetGuid='Creature-0-1-1-1-100-200'; targetName='Training Dummy'
H.readNotice(nil,'PLAYER_TARGET_CHANGED')
assert(H.targetName.text=='Training Dummy' and H.targetCommands.enabled and not H.inspect.enabled)
H.inspectTarget(); assert(not inspected)
H.browseTarget(); assert(GMGenie.Commands.query.text=='npc' and #sent==0)
targetGuid='Pet-0-1-1-1-1'; H.updateTarget(); assert(not H.targetCommands.enabled)
targetGuid='Player-1-2'; targetPlayer=true; targetName='Example'
H.updateTarget(); assert(H.inspect.enabled)
H.inspectTarget(); assert(inspected=='Example')
H.browseTarget(); assert(GMGenie.Commands.query.text=='character')
H.macroMenu(GMGenie_Hud)
lastMenu.items[1].callback(); assert(openedOptions=='Whisper Macros')
lastMenu.items[4].callback(); assert(openedOptions=='Discipline Macros')
H.reportMenu(GMGenie_Hud)
lastMenu.items[2].callback(); assert(reportKind=='complaint' and GMGenie_Tickets_Main.visible)
H.search:SetText('npc move'); H.search:Fire('OnEnterPressed')
assert(GMGenie.Commands.selected.name=='npc move' and #sent==0)
targetGuid=nil; targetName=nil; targetPlayer=false
GMGenie_Hud_Speed:SetText('invalid'); H.setSpeed(); assert(#sent==0 and warning)
GMGenie_Hud_Speed:SetText('51'); H.setSpeed(); assert(#sent==0)
GMGenie_Hud_Speed:SetText('2'); H.setSpeed(); assert(sent[1][1]=='.mod speed all 2')
targetName='Other'; GMGenie_Hud_Speed:SetText('1'); H.setSpeed(); assert(#sent==1)
targetName=nil; GMGenie_Hud_GM:Fire('OnClick'); assert(sent[2][1]=='.gm on')
assert(H.gm==nil) -- wait for server acknowledgement instead of guessing a state
H.gmStatus(true); assert(H.gm==true)
GMGenie_Hud_GM:Fire('OnClick'); assert(sent[3][1]=='.gm off')
H.checkStatus(); assert(sent[4][1]=='.gm chat' and sent[6][1]=='.whispers')
GMGenieUI.setScale(1.25); assert(GMGenie_Hud.scale==1.25)
GMGenieUI.savePosition(GMGenie_Hud); assert(GMGenie_SavedVars.ui.positions.GMGenie_Hud.x==250)
GMGenie_SavedVars.ui={scale=0.9,positions={GMGenie_Hud={x=300,y=200}}}
GMGenieUI.restoreWindows(); assert(GMGenie_Hud.scale==0.9 and GMGenie_Hud.point[4]==300)
GMGenieUI.resetPositions(); assert(next(GMGenie_SavedVars.ui.positions)==nil)
''')
print('PASS: dashboard creation, native menu callbacks, target changes, command search, speed validation, acknowledgement-driven state, saved scale/positions')
