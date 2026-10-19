"""Regressions for draft continuity, Back navigation, catalog returns and mail parsing."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute((ROOT/'tests/ui_mock.lua').read_text())
lua.execute('''
GMGenie.Macros={}; GMGenie.showGMMessage=function(text) warning=text end
timers={}; C_Timer={After=function(_,callback) timers[#timers+1]=callback end}
function flush()
 local n=0; while #timers>0 do local queue=timers; timers={}; for _,f in ipairs(queue) do f() end; n=n+1; assert(n<200) end
end
function IsLoggedIn() return true end
function UnitPosition() return 1,2,3,0 end
function GetPlayerFacing() return 0.5 end
function strsplit(delimiter,text)
 local values={}; local start=1
 while true do local at=text:find(delimiter,start,true)
  if not at then values[#values+1]=text:sub(start); break end
  values[#values+1]=text:sub(start,at-1); start=at+#delimiter
 end; return unpack(values)
end
''')
for name in ('UI.lua','CommandData.lua','CommandHelp.lua','CommandForms.lua','Commands.lua','Recipes.lua','CatalogData.lua','Catalog.lua','Macros.Mail.lua'):
    lua.execute((ROOT/name).read_text(encoding='utf-8-sig'))
lua.execute('''
local C,R,K,U,M=GMGenie.Commands,GMGenie.Recipes,GMGenie.Catalog,GMGenieUI,GMGenie.CommandForms
C.open('npc move'); C.inputs[1]:SetText('123')
targetGuid='Creature-0-1-1-1-68-999'; C.execute()
assert(#sent==0 and not C.run.enabled and C.status.text:find('Clear your target',1,true))
targetGuid=nil; C.window:Fire('OnEvent','PLAYER_TARGET_CHANGED'); assert(C.run.enabled)

C.open('npc add'); C.inputs[1]:SetText('68')
C.open('lookup creature'); C.inputs[1]:SetText('Guard')
C.open('npc add'); assert(C.inputs[1].text=='68')
C.clearForm(); C.open('lookup creature'); assert(C.inputs[1].text=='Guard')
C.open('npc add'); assert(C.inputs[1].text=='')
C.inputs[1]:SetText('54')
C.open('account create'); C.inputs[2]:SetText('never-save-this')
C.open('npc add'); C.open('account create'); assert(C.inputs[2].text=='')

C.open('npc add'); C.inputs[1]:SetText('68'); assert(C.inputs[1].picker.visible)
local savedQuery=C.query.text
C.pickField(1); flush()
assert(K.pickRequest and K.kind=='creatures' and not C.window.visible and K.window.visible)
assert(not K.temporary.visible and not K.persistent.visible and not K.itemsTab.enabled)
K.spawnTemporary(); K.askPersistent(); K.addItem(); assert(#sent==0)
K.query:SetText('54'); flush(); assert(K.selected.id==54)
K.finishPick(true,true)
assert(not K.pickRequest and not K.window.visible and C.window.visible and C.query.text==savedQuery)
assert(C.inputs[1].text=='54' and #sent==0)
C.pickField(1); flush(); K.query:SetText('68'); flush(); U.back()
assert(not K.pickRequest and C.inputs[1].text=='54' and #sent==0)

R.open(); R.choose({recipe=R.examples[1],source='example'})
R.dirty=false; R.name:Fire('OnTextChanged'); R.summary:Fire('OnTextChanged')
for _,input in ipairs(R.inputs) do input:Fire('OnTextChanged') end
assert(not R.dirty and R.copy(R.draft)) -- native same-text and hidden-input events cannot fabricate edits
R.checked[1]=true; R.sent[1]=true
R.choose({recipe=R.examples[1],source='example'})
assert(R.checked[1] and R.sent[1])
R.name:SetText(''); R.summary:SetText('Incomplete draft remains recoverable')
R.choose({recipe=R.examples[2],source='example'})
R.choose({recipe=R.examples[1],source='example'})
assert(R.name.text=='' and R.dirty and R.checked[1])
R.save(true); assert(#R.preferences().recipes==0)
R.name:SetText('My stock'); R.save(true); assert(#R.preferences().recipes==1)
R.selectStep(2); R.inputs[1]:SetText('2589')
R.pickField(1); flush(); assert(K.kind=='items' and not R.window.visible)
K.query:SetText('25'); flush(); K.finishPick(true,true)
assert(R.window.visible and R.stepIndex==2 and R.inputs[1].text=='25' and R.draft.variables.item=='25')
R.inputs[1]:SetText('2589'); R.save(false); R.inputs[1]:SetText('25')
R.optionsMenu(R.stepButton)
for _,item in ipairs(lastMenu.items) do if item.label=='Revert to saved fields' then item.callback() end end
assert(R.draft.variables.item=='2589' and not R.dirty)

R.selectStep(2); C.open('lookup creature'); C.inputs[1]:SetText('Vendor')
U.back(); assert(R.window.visible and not C.window.visible and R.stepIndex==2)
C.open('npc move'); assert(not C.inputs[1].picker.visible) -- spawn IDs never use a template picker
C.open('npc set model'); assert(not C.inputs[1].picker.visible) -- display IDs are different
for _,e in ipairs(GMGenie.CommandData.entries) do
 for _,f in ipairs(M.schema(e)) do
  if M.catalogKind(e,f) then assert(not f.secret and (e.name~='npc move')) end
 end
end
assert(#sent==0)

local Mail=GMGenie.Macros.Mail
local commands=assert(Mail.build('Example','Help','Hello NAME'))
assert(commands[1]=='.send mail Example "Help" "Hello Example"')
assert(Mail.build('Example Surname','Help','Hello NAME')[1]==commands[1])
GMGenie_SavedVars.mail={bad={subject='Help',macro='Good line\\nClick "Help"'}}
assert(Mail.run('Example','bad')==false and #sent==0 and warning:find('quotes',1,true))
assert(not Mail.build('Example','Subject "quote"','Body'))
assert(not Mail.build('Example','Help','Good\\n'..string.rep('x',260)))
assert(not Mail.build('Example','Help','First\\n\\nLast'))
assert(not Mail.build('Example','Help','|Hplayer:Other|h[Other]|h'))
assert(not Mail.build('Example','Help',string.rep('é',125))) -- bytes, not glyphs
assert(Mail.build('Example','Help','Click “Help”'))
commands=assert(Mail.build('Example','Help','First\\nSecond'))
assert(commands[1]=='.send mail Example "Help 1/2" "First"' and commands[2]:find('Help 2/2',1,true))
GMGenie_SavedVars.mail.good={subject='Help',macro='First\\nSecond'}
assert(Mail.run('Example','good') and #sent==2)
''')
print('PASS: NPC move guard, command/recipe drafts, transient progress, secret isolation, Back history, catalog pick/cancel and complete mail preflight')
