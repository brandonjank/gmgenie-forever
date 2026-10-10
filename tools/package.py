"""Build a release ZIP containing the correctly named GMGenie addon folder."""
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
toc = (ROOT / "GMGenie.toc").read_text(encoding="utf-8-sig")
version = re.search(r"^## Version: ([A-Za-z0-9._-]+)$", toc, re.MULTILINE).group(1)
files = [p for p in ROOT.iterdir() if p.is_file() and p.suffix in {".lua", ".xml", ".toc"}]
for folder in ["Chronos", "Options", "Textures"]:
    files.extend(p for p in (ROOT / folder).rglob("*") if p.is_file())
files.extend(ROOT / name for name in ["LICENSE", "NOTICE", "README.md", "README.Forever.md", "CHANGELOG.md"])
output = ROOT / "dist" / f"GMGenie-{version}.zip"
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
