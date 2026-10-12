"""Validate the actual ZIP and WowUp's Forever release-selection contract."""
from pathlib import Path
import json
import re
import struct
import zipfile

ROOT=Path(__file__).resolve().parents[1]
toc=(ROOT/'GMGenie.toc').read_text(encoding='utf-8-sig')
version=re.search(r'^## Version: (.+)$',toc,re.MULTILINE).group(1)
interface=int(re.search(r'^## Interface: (\d+)$',toc,re.MULTILINE).group(1))
metadata=json.loads((ROOT/'dist/release.json').read_text())
releases=metadata['releases']
assert len(releases)==1
release=releases[0]
assert release['nolib'] is False
assert release['metadata']==[{'flavor':'forever','interface':interface}]
assert interface==16001  # never advertise a Retail or other Classic package
filename=release['filename']
build=re.fullmatch(r'\d+\.\d+\.\d+-forever\.(\d+)',version).group(1)
assert filename==f'GMGenie-Forever-1.60.1-{int(build)}.zip'
assert Path(filename).name==filename
with zipfile.ZipFile(ROOT/'dist'/filename) as archive:
    assert archive.testzip() is None
    names=archive.namelist()
    assert len(names)==len(set(names))
    assert all(name.startswith('GMGenie/') for name in names)
    assert archive.read('GMGenie/GMGenie.toc')==(ROOT/'GMGenie.toc').read_bytes()
    assert 'release.json' not in names  # a separate GitHub release asset
    assert 'GMGenie/Builder.lua' in names
    icon_path=re.search(r'^## IconTexture: (.+)$',toc,re.MULTILINE).group(1)
    assert icon_path.startswith('Interface\\AddOns\\GMGenie\\')
    icon_name=icon_path.removeprefix('Interface\\AddOns\\').replace('\\','/')+'.tga'
    icon=archive.read(icon_name)
    # WoW-compatible uncompressed, power-of-two, 24-bit RGB TGA.
    assert icon[1:3]==bytes([0,2])
    assert struct.unpack_from('<HHB',icon,12)==(128,128,24)
    assert icon== (ROOT/'Textures/Forever.tga').read_bytes()
    preview=(ROOT/'.previews/GMGenie-Forever.png').read_bytes()
    assert preview.startswith(b'\x89PNG\r\n\x1a\n')
    assert struct.unpack_from('>II',preview,16)==(512,512)
    assert archive.read('GMGenie/docs/branding/icon.png')==preview

# This is how WowUp selects a ZIP from release.json: exact filename, flavor,
# nolib=false, then a ZIP content type. Verify that the generated asset qualifies.
assets=[{'name':filename,'content_type':'application/zip'},
        {'name':'release.json','content_type':'application/json'}]
matching=next(r for r in releases if r['nolib'] is False
              and any(m['flavor']=='forever' for m in r['metadata']))
asset=next(a for a in assets if a['name']==matching['filename']
           and a['content_type']=='application/zip')
assert asset['name']==filename
print('PASS: release ZIP, TOC version/resources, game-version/build filename and release.json compatibility selection')
