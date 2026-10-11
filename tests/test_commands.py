"""Catalog coverage, parser edge cases, and actual Lua browser interactions."""
import importlib.util
import json
from pathlib import Path
import re
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('generator',ROOT/'tools/generate_commands.py')
generator=importlib.util.module_from_spec(spec); spec.loader.exec_module(generator)
source='''
std::span<ChatCommandBuilder const> GetCommands() const override {
 static ChatCommandTable child = {
  // { "disabled", Missing, rbac::P, Console::No },
  { "", Default, rbac::P, Console::No },
  { "move item", Move, rbac::P, Console::Yes },
 };
 static ChatCommandTable old = {
  { "view", rbac::P, true, &View<Ticket>, "" },
 };
 static ChatCommandTable root = {
  { "npc", child }, { "ticket", rbac::P, false, nullptr, "", old }
 };
 return root;
}
static bool Default(ChatHandler* handler, Optional<uint32> id) {}
static bool Move(ChatHandler* handler, Variant<uint32, EXACT_SEQUENCE("stay")> type) {}
static bool View(ChatHandler* handler, char const* args) {}
'''
entries,count=generator.parse_source(source,'fixture.cpp',{'P':7})
assert count==5  # three leaves and two group registrations
assert [e['name'] for e in entries]==['npc','npc move item','ticket view']
assert entries[0]['usage']=='.npc [id]' and not entries[0]['console']
assert entries[1]['arguments']=='Variant<uint32, EXACT_SEQUENCE("stay")> type'
assert entries[2]['legacy'] and entries[2]['console']
try:
    generator.parse_source(source.replace('return root','return missing'),'bad.cpp',{'P':7})
    raise AssertionError('Unresolved root was silently accepted')
except ValueError: pass

catalog=json.loads((ROOT/'docs/commands.json').read_text())
byname={e['name']:e for e in catalog['entries']}
assert len(byname)==619 and len(catalog['files'])==46
assert byname['npc move']['arguments']=='Optional<CreatureSpawnId> spawnid'
assert not byname['npc move']['console']
assert byname['go xyz']['arguments']=='float x, float y, Optional<float> z, Optional<uint32> id, Optional<float> o'
assert all(name in byname for name in ('legacy points','discord say','armory export','npc add','npc delete item','ticket suggestion view'))
assert 'npc add weapon' not in byname and 'anticheat player' not in byname
assert all(e['permissionId']>=0 and e['source'] in catalog['files'] for e in byname.values())

# Check every literal command prefix emitted by shipped modules against source.
aliases={'pin':'pinfo','mod':'modify','gob':'gobject','char':'character','name':'nameannounce','gmname':'gmnameannounce'}
checked=set()
for path in list(ROOT.glob('*.lua'))+list(ROOT.glob('*.xml'))+list((ROOT/'Options').glob('*.lua')):
    if path.name in ('CommandData.lua','Commands.lua'): continue
    for literal in re.findall(r'SendChatMessage\(\s*["\'](\.[^"\']+)',path.read_text(encoding='utf-8-sig')):
        command=literal[1:].strip()
        head,*tail=command.split(' '); command=' '.join([aliases.get(head,head),*tail])
        command=re.sub(r'^ban char\b','ban character',command)
        command=re.sub(r'^gobject del\b','gobject delete',command)
        if command.startswith('ticket '):
            command=command.replace('viewid','view').replace(' del',' delete')
            command=command.replace('ticket ','ticket bug ',1)
        assert command in byname or any(command.startswith(name+' ') for name in byname), (path.name,literal,command)
        checked.add(command)

lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
GMGenie={}; UISpecialFrames={}; UIParent={}; sent={}; SlashCmdList={}
function frame()
 return setmetatable({scripts={},visible=false,text=''}, {__index=function(t,k)
  if k=='SetText' then return function(self,v) self.text=v end end
  if k=='GetText' then return function(self) return self.text end end
  if k=='SetScript' then return function(self,n,f) self.scripts[n]=f end end
  if k=='CreateFontString' then return function() return frame() end end
  if k=='Show' then return function(self) self.visible=true end end
  if k=='Hide' then return function(self) self.visible=false end end
  if k=='IsShown' then return function(self) return self.visible end end
  return function() end
 end})
end
function CreateFrame() return frame() end
GMGenieForever={SetBackdrop=function() end,SendChatMessage=function(...) sent[#sent+1]={...} end}
''')
for file in ('CommandData.lua','Commands.lua'): lua.execute((ROOT/file).read_text())
lua.execute('''
local C=GMGenie.Commands
assert(#GMGenie.CommandData.entries==619)
assert(#C.search('NPC MOVE')>=1 and C.search('NPC MOVE')[1].name=='npc move')
assert(#C.search('Optional spawnid')>=1)
assert(#C.search('[invalid pattern%')==0) -- plain-text search, not a Lua pattern
C.open('npc move'); assert(C.window:IsShown() and C.selected.name=='npc move')
assert(C.copy:GetText()=='.npc move' and C.source:GetText():find('#L',1,true))
assert(#sent==0) -- opening, searching and selecting never execute commands
C.help(C.selected); assert(#sent==1 and sent[1][1]=='.help npc move' and sent[1][2]=='GUILD')
C.refresh(''); assert(#C.matches==619)
C.page=35; C.refresh(); assert(C.rows[7].visible and not C.rows[8].visible)
C.next.scripts.OnClick(); assert(C.page==35) -- clamp beyond last page
C.previous.scripts.OnClick(); assert(C.page==34)
C.refresh('does-not-exist'); assert(not C.detail.visible and not C.rows[1].visible)
C.toggle(); assert(not C.window:IsShown()); C.toggle(); assert(C.window:IsShown())
assert(#sent==1)
''')
lua.execute((ROOT/'Spawns.lua').read_text(encoding='utf-8'))
lua.execute('''
function UnitName() return 'Tester' end
GMGenie.Spawns.clearFocus=function() end
GMGenie.Spawns.initiateMove('move')
assert(sent[#sent][1]=='.gps Tester')
''')
lua.execute((ROOT/'Macros.lua').read_text(encoding='utf-8'))
lua.execute('''
local before=#sent
GMGenie.showGMMessage=function(text) unsupported=text end
GMGenie.Macros.antiCheatPlayer('Tester')
assert(#sent==before and unsupported:find('not registered',1,true))
''')
print(f'PASS: 619 command records, parser coverage, {len(checked)} addon command prefixes, search/pagination/source links and help-only sends')
