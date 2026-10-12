"""Exercise the real 619-command forms, validation, previews and explicit sends."""
from pathlib import Path
import importlib.util
import json
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute((ROOT/'tests/ui_mock.lua').read_text())
for name in ('UI.lua','CommandData.lua','CommandHelp.lua','CommandForms.lua','Commands.lua'):
    lua.execute((ROOT/name).read_text(encoding='utf-8-sig'))
lua.execute(r'''
local M,C=GMGenie.CommandForms,GMGenie.Commands
local entries={}; for _,e in ipairs(GMGenie.CommandData.entries) do entries[e.name]=e end
local function build(name,values) local e=entries[name]; return M.build(e,M.schema(e),values) end
for _,e in pairs(entries) do
    local fields=M.schema(e); assert(#fields<=6,e.name)
    assert(#M.description(e)>0)
    if M.isWorld(e) then assert(M.guides[e.name] or GMGenie.CommandHelp[e.name],e.name..' missing world-building guide') end
    for _,f in ipairs(fields) do assert(f.name and #M.hint(f)>0,e.name) end
end
assert(build('npc move',{})=='.npc move')
assert(build('npc move',{'123'})=='.npc move 123')
assert(build('npc move',{'00123'})=='.npc move 123') -- avoid native base-0/octal parsing
assert(not build('npc move',{'-1'}))
assert(build('npc move',{'18446744073709551615'})=='.npc move 18446744073709551615')
assert(not build('npc move',{'18446744073709551616'}))
assert(not build('npc add',{}))
assert(not build('npc add',{'4294967296'}))
assert(build('npc set level',{'255'})=='.npc set level 255')
assert(not build('npc set level',{'256'}))
assert(not build('go xyz',{'nan','0'}))
assert(not build('go xyz',{'1','2','','0'})) -- cannot shift map ID into Z
assert(build('go xyz',{'-10.5','2','3','0','1.25'})=='.go xyz -10.5 2 3 0 1.25')
assert(build('gobject move',{'123','1 2 3'})=='.gobject move 123 1 2 3')
assert(not build('gobject move',{'123','1 2'}))
assert(build('gobject info',{'','123'})=='.gobject info 123') -- optional keyword before required argument
assert(build('gobject info',{'guid','123'})=='.gobject info guid 123')
assert(not build('gobject info',{'wrong','123'}))
assert(build('npc set movetype',{'','stay'})=='.npc set movetype stay')
assert(not build('npc set movetype',{'','wrong'}))
assert(build('npc say',{'Hello world!'})=='.npc say Hello world!')
assert(not build('npc say',{'Hello\n.npc delete'}))
assert(not build('npc say',{'|cfffffffftext'}))
assert(not build('npc say',{string.rep('x',256)}))
assert(build('appear',{'First Last'})=='.appear First')
assert(build('npc whisper',{'First Last','Hello there'})=='.npc whisper First Hello there')
assert(build('ban character',{'First Last','1h','Repeated spam'})=='.ban character First 1h Repeated spam')
assert(not build('ban character',{'First Last','0','reason'}))
assert(M.encode({name='text',kind='quoted'},'a "quoted" word')==[["a \"quoted\" word"]])
assert(M.build({name='test'},{{name='password',kind='token',secret=true}},{'secret'},true)=='.test [hidden]')
C.open('npc add'); assert(not C.run.enabled and #sent==0)
C.inputs[1]:SetText('123'); assert(C.run.enabled and C.copy:GetText()=='.npc add 123')
C.inputs[1]:Fire('OnEnterPressed'); assert(#sent==0) -- Enter never runs an action
C.toggleFavorite(C.selected); assert(C.inputs[1]:GetText()=='123') -- refresh preserves current form
C.run:Fire('OnClick'); assert(#sent==1 and sent[1][1]=='.npc add 123')
C.open('npc delete'); C.inputs[1]:SetText('321')
C.run:Fire('OnClick'); assert(#sent==1 and C.confirmation and C.run:GetText()=='Confirm run')
C.inputs[1]:SetText('322'); assert(not C.confirmation)
C.run:Fire('OnClick'); assert(#sent==1)
C.window:Fire('OnEvent','PLAYER_TARGET_CHANGED'); assert(not C.confirmation)
C.run:Fire('OnClick'); assert(#sent==1)
C.run:Fire('OnClick'); assert(#sent==2 and sent[2][1]=='.npc delete 322' and not C.confirmation)
C.run:Fire('OnClick'); assert(#sent==2) -- another destructive send requires confirmation again
C.window:Hide(); assert(not C.confirmation)
C.open('go xyz')
function UnitPosition() return -10.25,20.5,30.75,0 end
function GetPlayerFacing() return 1.5 end
C.fill:Fire('OnClick'); assert(C.copy:GetText()=='.go xyz -10.250000 20.500000 30.750000 0 1.500000')
C.run:Fire('OnClick'); assert(#sent==3)
C.open('appear'); targetPlayer=true; targetName='First Last'
C.fill:Fire('OnClick'); assert(C.copy:GetText()=='.appear First')
C.clearForm(); assert(C.copy:GetText()=='.appear')
C.open('npc say'); assert(C.inputs[1].width==562)
C.copy:SetText('.npc delete'); assert(C.copy:GetText()=='.npc say') -- preview cannot diverge from the sent form
C.resetFilters(); C.setMode('world'); assert(#C.matches>100)
for _,e in ipairs(C.matches) do assert(M.isWorld(e)) end
C.open('facing'); local found=false; for _,e in ipairs(C.matches) do if e.name=='npc move' then found=true end end
assert(found) -- search descriptions, not just handler names
C.open('account create'); C.inputs[1]:SetText('test'); C.inputs[2]:SetText('private-value')
assert(C.inputs[2].password and C.copy:GetText()=='.account create test [hidden]')
C.window:Hide(); assert(C.inputs[2]:GetText()=='')
assert(not GMGenie_SavedVars.commandBrowser.arguments) -- no saved command values or credentials
local before=#sent; GMGenieForever.RequireActive=function() return false end
C.open('npc add'); C.execute(); assert(#sent==before)
''')

# The help importer must stop at unrelated logs and reject mismatched revisions.
spec=importlib.util.spec_from_file_location('help_import',ROOT/'tools/generate_command_help.py')
module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
catalog={'revision':'a','entries':[{'name':'npc info'},{'name':'npc move'}]}
capture={'revision':'a','batches':[{'commands':['help npc info','help npc move'],
    'output':'TC> Syntax: .npc info\nShows NPC information.\n2026-10-12 private unrelated log\nTC> help npc move\nTC> Syntax: .npc move\nMoves the NPC.\nTC> '}]}
help_text=module.extract(capture,catalog)
assert len(help_text)==2 and all('private' not in text for text in help_text.values())
capture['revision']='b'
try: module.extract(capture,catalog); raise RuntimeError('Mismatched help accepted')
except AssertionError: pass
print('PASS: all 619 forms, typed/legacy arguments, exact previews, target/position helpers, confirmation, isolation and pinned help import')
