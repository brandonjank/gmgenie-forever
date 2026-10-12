"""Check full catalog data and exercise user actions on the Lua 5.1 UI."""
from pathlib import Path
import hashlib
import importlib.util
import json
import tempfile
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
ledger=json.loads((ROOT/'docs/catalog-sources.json').read_text())
assert ledger['tree']==16 and ledger['counts']=={'items':22659,'creatures':15205}
assert hashlib.sha256((ROOT/'CatalogData.lua').read_bytes()).hexdigest()==ledger['catalogSHA256']
for kind in ('items','npcs'):
    pages=ledger['sources'][kind]
    assert all(p['url'].startswith('https://www.wowhead.com/forever/'+kind) for p in pages)
    leaves=[p for p in pages if p['displayed']==p['total']]
    assert sum(p['total'] for p in leaves)==pages[0]['total']

lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute((ROOT/'tests/ui_mock.lua').read_text())
lua.execute('''
timers={}; C_Timer={After=function(delay,callback) timers[#timers+1]={delay,callback} end}
function flushTimers()
 local limit=0
 while #timers>0 do local queue=timers; timers={}; for _,timer in ipairs(queue) do timer[2]() end; limit=limit+1; assert(limit<200) end
end
GMGenie.showGMMessage=function(message) warning=message end
function GetCursorPosition() return 100,100 end
C_Item={RequestLoadItemDataByID=function(id) requestedItem=id end}
''')
for name in ('UI.lua','CatalogData.lua','Catalog.lua'):
    lua.execute((ROOT/name).read_text(encoding='utf-8-sig'))
lua.execute('''
local C=GMGenie.Catalog
C.open(); assert(C.loading.items and #sent==0); flushTimers()
assert(C.loaded.items and #C.entries.items==22659 and #C.matches==22659)
assert(C.window.width==1050 and C.window.height==750)
assert(C.window.level>40) -- catalog must sit above the persistent HUD
for _,which in ipairs({'type','rank','slot'}) do
 C.filterMenu(C.typeButton,which); local values={}
 for _,item in ipairs(lastMenu.items) do if item.data~=nil then values[item.data]=true end end
 local field=which=='type' and 'type' or which=='rank' and 'quality' or 'slot'
 for _,entry in ipairs(C.entries.items) do assert(values[entry[field]],'Missing filter for '..field..' '..entry[field]) end
end
local seen={}; for _,entry in ipairs(C.entries.items) do assert(not seen[entry.id]); seen[entry.id]=true end
assert(C.byID.items[25] and C.byID.items[19019] and not C.byID.items[190001]) -- classic content is allowed; an unrelated retail ID is absent
C.query:SetText('25'); flushTimers(); assert(#C.matches==1 and C.selected.id==25)
assert(C.itemModel.visible and C.itemModel.item=='item:25' and requestedItem==25)
assert(#sent==0)
C.itemTooltip(C.rows[1],C.selected); assert(GameTooltip.link=='item:25')
C.quantity:SetText('2'); targetName='OtherPlayer'; targetPlayer=true; C.addItem()
assert(sent[1][1]=='.additem to Tester 25 2') -- never use the selected player
for _,value in ipairs({'-1','0','1.5','1001','nan','1 2','.npc add 1'}) do C.quantity:SetText(value); C.addItem(); assert(#sent==1) end
C.quantity:SetText('1000'); C.addItem(); assert(sent[2][1]=='.additem to Tester 25 1000')
C.toggleFavorite(); assert(C.preferences().favorites['items:25'])
C.mode='favorites'; C.refresh(); assert(#C.matches==1)
C.toggleFavorite(); assert(#C.matches==0 and C.selected==nil and not C.add.enabled)
C.resetFilters(); C.query:SetText('linen cloth'); flushTimers(); assert(#C.matches>0)
for _,entry in ipairs(C.matches) do assert(entry.search:find('linen',1,true) and entry.search:find('cloth',1,true)) end
C.query:SetText('10 pound'); flushTimers(); assert(#C.matches>0) -- numeric words inside a name are not an ID filter
C.query:SetText('['); flushTimers(); assert(#sent==2) -- plain search, not Lua patterns
C.resetFilters(); C.page=999999; C.refresh(); assert(not C.next.enabled and C.page>1)
C.page=-20; C.refresh(); assert(C.page==1 and not C.previous.enabled)
C.typeFilter=2; C.rankFilter=1; C.refresh(); assert(#C.matches>0)
for _,entry in ipairs(C.matches) do assert(entry.type==2 and entry.quality==1) end
C.setKind('creatures'); flushTimers()
assert(#C.entries.creatures==15205 and #C.matches==15205 and #sent==2)
C.filterMenu(C.typeButton,'type'); local creatureTypes={}
for _,item in ipairs(lastMenu.items) do if item.data~=nil then creatureTypes[item.data]=true end end
for _,entry in ipairs(C.entries.creatures) do assert(creatureTypes[entry.type]) end
seen={}; for _,entry in ipairs(C.entries.creatures) do assert(not seen[entry.id]); seen[entry.id]=true end
C.query:SetText('5807'); flushTimers(); assert(C.selected.name=='The Rake')
assert(C.creatureModel.visible and C.creatureModel.modelID==1973)
local fit=1.25*564/240
assert(math.abs(C.creatureModel.distance-fit)<0.0001) -- initial wide viewport fits the full body
local portrait=C.creatureModel.SetPortraitZoom
C.creatureModel.SetPortraitZoom=function(self,value) portrait(self,value); self.distance=1 end
C.camera(); assert(math.abs(C.creatureModel.distance-fit)<0.0001) -- fit is applied after portrait reset
C.rotate(0.5); assert(C.creatureModel.rotation==1)
C.zoom(-99); assert(C.distance==0.25); C.zoom(99); assert(C.distance==3)
C.resetCamera(); assert(C.distance==1 and C.facing==0.5)
assert(math.abs(C.creatureModel.distance-fit)<0.0001 and C.creatureModel.position[3]==0)
C.zoom(0.5); C.creatureModel:Fire('OnModelLoaded')
assert(math.abs(C.creatureModel.distance-fit*1.5)<0.0001) -- async asset loading preserves user zoom
C.creatureModel:SetSize(240,480); C.creatureModel:Fire('OnSizeChanged')
assert(math.abs(C.creatureModel.distance-1.25*1.5)<0.0001) -- portrait viewport does not overcompensate
C.creatureModel:SetSize(564,240); C.resetCamera()
C.creatureModel.SetPortraitZoom=portrait
C.spawnTemporary(); assert(sent[3][1]=='.npc add temp noloot 5807')
C.askPersistent(); assert(C.confirm.visible and #sent==3)
C.query:SetText('25'); flushTimers(); C.spawnPersistent(); assert(#sent==3 and not C.confirm.visible)
C.query:SetText('5807'); flushTimers(); C.askPersistent(); C.spawnPersistent()
assert(sent[4][1]=='.npc add 5807' and not C.confirm.visible)
C.spawnPersistent(); assert(#sent==4) -- double click cannot reuse a confirmation
C.askPersistent(); C.window:Hide(); C.spawnPersistent(); assert(#sent==4)
C.open('5807'); flushTimers(); assert(C.creatureModel.visible)
C.resetFilters(); C.roleFilter='vendor'; C.refresh(); assert(#C.matches>0)
for _,entry in ipairs(C.matches) do assert(math.floor(entry.flags/128)%2==1) end
C.filterMenu(C.typeButton,'type'); lastMenu.items[1].callback(); assert(C.typeFilter==nil)
C.modeMenu(C.modeButton); lastMenu.items[2].callback('favorites'); assert(C.mode=='favorites')
C.setKind('items'); C.query:SetText('2589'); flushTimers()
assert(C.selected.name=='Linen Cloth' and C.icon.visible and not C.itemModel.visible)
C.query:SetText('811'); flushTimers(); assert(C.selected.available==0 and C.description.text:find('reference core'))
C.setKind('creatures'); C.query:SetText('5807'); flushTimers()
C.creatureModel.SetDisplayInfo=false; C.preview(C.selected); assert(C.creatureModel.modelID==5807)
C.creatureModel.SetCreature=function() error('missing asset') end; C.preview(C.selected)
assert(not C.creatureModel.visible and C.modelNote.text~='')
assert(#sent==4)
''')

spec=importlib.util.spec_from_file_location('collector',ROOT/'tools/collect_forever_catalog.py')
collector=importlib.util.module_from_spec(spec); spec.loader.exec_module(collector)
def page(rows,total):
    return ('<script>{"env":16,"tree":16,"numberOfItems":'+str(total)+'}</script>'
            'WH.Gatherer.addData(3, 16, {});var listviewitems = '+json.dumps(rows)+';')
assert collector.parse_page(page([{'id':25}],1),'items')[0]==1
try: collector.parse_page(page([{'id':25}],1).replace('"tree":16','"tree":1'),'items'); assert False
except ValueError: pass
with tempfile.TemporaryDirectory(dir=ROOT/'tests') as tmp:
    cache=Path(tmp)
    # Root capped at two rows; disjoint child leaves reconstruct three IDs.
    (cache/'items-all.html').write_text(page([{'id':1},{'id':3}],3))
    (cache/'items-0-3.html').write_text(page([{'id':1},{'id':2}],2))
    (cache/'items-3-2147483647.html').write_text(page([{'id':3}],1))
    rows,evidence=collector.collect('items',cache,delay=0)
    assert [r['id'] for r in rows]==[1,2,3] and len(evidence)==3
    (cache/'items-3-2147483647.html').write_text(page([{'id':2}],1))
    try: collector.collect('items',cache,delay=0); assert False
    except ValueError: pass
print('PASS: complete Forever whitelist, range coverage, lazy loading, search/filter/paging, models/fallbacks, favorites, explicit self item delivery and guarded persistent spawns')

spec=importlib.util.spec_from_file_location('generator',ROOT/'tools/generate_catalog.py')
generator=importlib.util.module_from_spec(spec); spec.loader.exec_module(generator)
fixture={'tree':16,'collected':'2026-10-11T00:00:00Z','sources':{},
         'items':[{'id':25,'name':'Worn Shortsword','displayName':'Worn Shortsword'}],
         'npcs':[{'id':5807,'name':'The Rake','displayName':'The Rake'}]}
inventory={'revision':'test','items':[25,190001],'displayIDs':[1973],
           'creatures':[[5807,0,[[1973,1],[999999,1]]],[999998,0,[[1973,1]]]]}
generated,report=generator.build(fixture,inventory)
assert report['counts']=={'items':1,'creatures':1}
assert '190001' not in generated and '999998' not in generated and '999999' not in generated
assert report['coverage']['creaturesWithDisplay']==1
print('PASS: reference inventory cannot add Retail IDs or unsupported displays to the Forever whitelist')
