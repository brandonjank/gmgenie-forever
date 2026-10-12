"""Build a release ZIP containing the correctly named GMGenie addon folder."""
from pathlib import Path
import json
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
toc = (ROOT / "GMGenie.toc").read_text(encoding="utf-8-sig")
version = re.search(r"^## Version: ([A-Za-z0-9._-]+)$", toc, re.MULTILINE).group(1)
interface = int(re.search(r"^## Interface: (\d+)$", toc, re.MULTILINE).group(1))
files = [p for p in ROOT.iterdir() if p.is_file() and p.suffix in {".lua", ".xml", ".toc"}]
for folder in ["Chronos", "Options", "Textures"]:
    files.extend(p for p in (ROOT / folder).rglob("*") if p.is_file())
files.extend(ROOT / name for name in ["LICENSE", "NOTICE", "README.md", "README.Forever.md", "CHANGELOG.md"])
files.extend(ROOT / "docs" / name for name in ["CATALOG.md", "catalog-sources.json"])
# WowUp's Forever provider recognizes only a terminal -forever/-camelot suffix.
output = ROOT / "dist" / f"GMGenie-{version}-forever.zip"
output.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(files):
        archive.write(path, "GMGenie/" + path.relative_to(ROOT).as_posix())
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    names = set(archive.namelist())
    for line in toc.splitlines():
        if line.strip() and not line.startswith("#"):
            assert "GMGenie/" + line.replace("\\", "/") in names, line
    assert all(name.startswith("GMGenie/") for name in names)
print(f"Built {output.name}: {len(files)} files")
metadata = {"releases": [{
    "filename": output.name,
    "nolib": False,
    "metadata": [{"flavor": "forever", "interface": interface}],
}]}
(output.parent / "release.json").write_text(json.dumps(metadata, indent=2)+"\n", encoding="utf-8")
print("Built release.json: Forever compatibility metadata for GitHub/WowUp")
