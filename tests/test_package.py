"""Validate the actual ZIP and WowUp's Forever release-selection contract."""
from pathlib import Path
import json
import re
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
