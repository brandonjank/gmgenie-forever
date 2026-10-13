"""Exercise saved recipe persistence, guided flows and exact guarded Lua sends."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
FILES=('UI.lua','CommandData.lua','CommandHelp.lua','CommandForms.lua','Commands.lua','Recipes.lua')
def runtime(saved=None):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT/'tests/ui_mock.lua').read_text())
    if saved is not None:
        def table(value):
            return lua.table_from({k:table(v) for k,v in value.items()}) if isinstance(value,dict) else value
        lua.globals().GMGenie_SavedVars=table(saved)
    lua.execute('''
now=100; loggedIn=true; position={1,2,3,0}; facing=0.5; warnings={}
function GetTime() return now end
function IsLoggedIn() return loggedIn end
function UnitPosition() return unpack(position) end
function GetPlayerFacing() return facing end
GMGenie.showGMMessage=function(text) warnings[#warnings+1]=text end
''')
    for name in FILES: lua.execute((ROOT/name).read_text(encoding='utf-8-sig'))
    return lua

lua=runtime()
lua.execute('''
local R,C=GMGenie.Recipes,GMGenie.Commands
function example(id)
 for _,r in ipairs(GMGenie.Recipes.examples) do if r.id==id then GMGenie.Recipes.choose({recipe=r,source='example'}); return r end end
 error('Missing example '..id)
end
assert(#R.examples==9)
for _,r in ipairs(R.examples) do
 local copy,err=R.copy(r); assert(copy,err)
 assert(copy~=r and copy.variables~=r.variables and copy.steps~=r.steps)
 assert(#copy.steps<=20)
end
R.open(); assert(#R.matches==9 and #sent==0)
R.search:SetText('vendor'); assert(#R.matches==2 and #sent==0)
R.search:SetText('[invalid%'); assert(#R.matches==0 and R.empty.visible and #sent==0)
R.search:SetText('')
example('example-patrol-new')
targetGuid='Creature-0-1-1-1-68-900'; targetName='Guard'
R.update(); assert(not R.run.enabled)
R.execute(); assert(#sent==0) -- blank .wp add must not accidentally append to a selected NPC's path
targetGuid=nil; targetName=nil; R.window:Fire('OnEvent','PLAYER_TARGET_CHANGED')
assert(R.run.enabled)
R.inputs[1]:Fire('OnEnterPressed'); assert(#sent==0)
R.execute(); assert(#sent==0 and R.confirmation)
R.execute(); assert(#sent==1 and sent[1][1]=='.wp add' and R.stepIndex==1 and R.check.enabled)
R.markChecked(); assert(R.stepIndex==2 and R.checked[1] and #sent==1)
assert(not R.run.enabled and R.fields[1].optional==false)
R.inputs[1]:SetText('0'); assert(not R.run.enabled)
R.inputs[1]:SetText('123456'); assert(R.run.enabled and R.checked[1])
assert(R.draft.variables.path=='123456')
R.execute(); position[1]=5; R.execute(); assert(#sent==1 and R.confirmation) -- moved while reviewing: re-arm
R.execute(); assert(#sent==2 and sent[2][1]=='.wp add 123456' and R.stepIndex==2)
R.markChecked(); assert(R.stepIndex==3 and R.inputs[1]:GetText()=='123456')
R.execute(); now=now+11; R.execute(); assert(#sent==2) -- review expires
R.execute(); assert(#sent==3 and sent[3][1]=='.wp reload 123456')
R.markChecked(); assert(R.stepIndex==4 and not R.run.enabled)
targetGuid='Creature-0-1-1-1-68-900'; targetName='Guard'; targetPlayer=false
R.bindTarget(); assert(R.run.enabled and R.checked[1] and R.checked[2] and R.checked[3])
R.execute(); targetGuid='Creature-0-1-1-1-68-901'; R.window:Fire('OnEvent','PLAYER_TARGET_CHANGED')
assert(not R.confirmation and not R.run.enabled)
R.execute(); assert(#sent==3) -- cannot silently use a different NPC
R.bindTarget(); R.execute(); R.execute(); assert(#sent==4 and sent[4][1]=='.wp load 123456')
R.markChecked(); assert(R.stepIndex==5 and #sent==4)
R.selectStep(2); R.inputs[1]:SetText('123457')
assert(R.checked[1] and not R.checked[2] and not R.checked[3] and not R.checked[4]) -- shared field invalidates affected checks
R.selectStep(3); assert(R.preview:GetText()=='.wp reload 123457')
local original=example('example-vendor-stock')
targetPlayer=true; targetGuid='Player-1-2'; R.bindTarget(); assert(not R.bound and not R.run.enabled)
targetPlayer=false; targetGuid='Creature-0-1-1-1-54-100'; targetName='Vendor'
R.bindTarget(); R.execute(); assert(sent[#sent][1]=='.npc info') -- inspection is one explicit click
R.markChecked(); assert(R.stepIndex==2)
R.inputs[1]:SetText('2589'); R.inputs[2]:SetText('5'); R.inputs[3]:SetText('300')
assert(R.preview:GetText()=='.npc add item 2589 5 300 0')
assert(original.variables.item=='25' and original.variables.stock=='0') -- bundled examples are immutable
R.name:SetText('Quartermaster stock'); R.save(true)
assert(#R.preferences().recipes==1 and R.savedID=='recipe-1')
local stored=R.preferences().recipes[1]
assert(stored.variables.item=='2589' and stored.variables.stock=='5' and not stored.bound and not stored.checked)
local stockEntry=R.resolve(R.draft,2); assert(stored.steps[2].signature==stockEntry.arguments)
R.inputs[1]:SetText('25'); assert(stored.variables.item=='2589') -- edits remain a draft until Update saved
R.save(false); assert(#R.preferences().recipes==1 and R.preferences().recipes[1].variables.item=='25')
R.inputs[1]:SetText('2589'); R.save(false)
local before=#sent
C.open('npc add'); C.inputs[1]:SetText('68'); assert(C.saveRecipe.enabled and not R.window.visible)
C.saveRecipe:Fire('OnClick'); assert(#lastMenu.items==2)
lastMenu.items[2].callback(); assert(R.window.visible and #R.draft.steps==3 and R.stepIndex==3)
assert(#R.preferences().recipes[1].steps==2 and #sent==before) -- appending never runs or auto-saves
R.editStep('up'); assert(R.stepIndex==2 and R.draft.steps[2].command=='npc add')
R.editStep('remove'); assert(#R.draft.steps==2 and #sent==before)
R.optionsMenu(R.stepButton)
for _,item in ipairs(lastMenu.items) do if item.label=='Revert to saved fields' then item.callback() end end
assert(#R.draft.steps==2 and R.draft.variables.item=='2589' and not R.dirty)
local savedID=R.savedID
local sender=GMGenieForever.SendChatMessage
R.selectStep(1); R.bindTarget(); GMGenieForever.SendChatMessage=function() return false end
R.execute(); assert(not R.sent[1] and not R.check.enabled and #sent==before)
GMGenieForever.SendChatMessage=function() error('transport failed') end
R.execute(); assert(not R.sent[1] and not R.check.enabled and #sent==before)
GMGenieForever.SendChatMessage=sender
example('example-npc-move'); R.bindTarget(); R.execute(); assert(R.confirmation)
R.window:Hide(); assert(not R.confirmation and not R.bound)
R.open(); assert(not R.run.enabled and #sent==before)
R.bindTarget(); position={}; R.update(); assert(not R.run.enabled)
R.execute(); assert(#sent==before) -- missing world position is not treated as an empty stamp
position={1,2,3,0}
R.inputs[1]:SetText('999'); R.update(); assert(not R.run.enabled) -- explicit spawn ID requires clear selection
targetGuid=nil; R.window:Fire('OnEvent','PLAYER_TARGET_CHANGED'); assert(R.run.enabled)
loggedIn=false; R.execute(); assert(#sent==before)
loggedIn=true
GMGenieForever.RequireActive=function() return false end
R.execute(); R.open(); assert(#sent==before)
GMGenieForever.RequireActive=function() return true end
local oldCount=#R.preferences().recipes
R.capture({name='account create'}, {'test','password'},false)
assert(#R.preferences().recipes==oldCount and #sent==before)
local bad=R.copy(R.examples[1]); bad.steps[2].command='server shutdown'; assert(not R.copy(bad))
bad=R.copy(R.examples[1]); bad.steps[2].values[1]='25\\n.npc delete'; assert(not R.copy(bad))
bad=R.copy(R.examples[1]); bad.steps[2].signature='changed handler'; assert(not R.copy(bad))
bad=R.copy(R.examples[1]); bad.variables='invalid'; assert(not R.copy(bad))
R.preferences().recipes[#R.preferences().recipes+1]=bad
R.refresh(); assert(R.invalidSaved==1) -- invalid data is preserved, excluded from execution
table.remove(R.preferences().recipes)
-- Saved values survive a fresh addon session; runtime context never enters SavedVariables.
assert(#R.preferences().recipes==1 and R.preferences().recipes[1].id==savedID)
''')

def plain(table):
    return {k:plain(v) if hasattr(v,'items') else v for k,v in table.items()}
saved=plain(lua.globals().GMGenie_SavedVars)
fresh=runtime(saved)
fresh.execute('''
local R=GMGenie.Recipes
R.open(); local stored=R.preferences().recipes[1]
R.choose({recipe=stored,source='saved'}); R.selectStep(2)
assert(R.inputs[1]:GetText()=='2589' and R.inputs[2]:GetText()=='5' and R.inputs[3]:GetText()=='300')
assert(not R.bound and next(R.checked)==nil and next(R.sent)==nil and not R.run.enabled and #sent==0)
R.deleteSaved(); assert(#R.preferences().recipes==0 and R.draft and not R.savedID and #sent==0)
R.name:SetText('Recovered stock'); R.save(true); assert(#R.preferences().recipes==1)
''')

# Default IDs are real Forever content, and 54 already has a vendor role.
fresh.execute((ROOT/'CatalogData.lua').read_text())
fresh.execute('''
local wanted={[54]=true,[68]=true}; local found={}
for _,chunk in ipairs(GMGenie.CatalogData.chunks.creatures) do
 for line in chunk:gmatch('[^\\n]+') do
  local id=tonumber(line:match('^(%d+)')); if wanted[id] then
   local fields={}; for value in (line..'\\t'):gmatch('([^\\t]*)\\t') do fields[#fields+1]=value end
   found[id]=true; if id==54 then assert(math.floor(tonumber(fields[8])/128)%2==1) end
  end
 end
end
assert(found[54] and found[68])
local item=false
for _,chunk in ipairs(GMGenie.CatalogData.chunks.items) do for line in chunk:gmatch('[^\\n]+') do if line:match('^25\\t') then item=true end end end
assert(item)
''')
print('PASS: nine guided examples, shared fields, step-by-step sends, target/position review, saved copies/updates/deletion, reload persistence, draft editing and invalid-data isolation')
