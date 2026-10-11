"""Collect factual metadata from Wowhead's Forever tree, checking every range.

The listings cap results at 1,000. Recursively split their ID filter until each
leaf is complete; reject a changing snapshot, duplicate IDs or ignored filters.
Cache HTML privately for resumable builds. No comments/tooltips are republished.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import time
import urllib.request

BASE = "https://www.wowhead.com/forever/"


def array_after(text, marker):
    source = text.split(marker, 1)[1].lstrip()
    # These are the only non-JSON fields emitted by the item listing.
    source = re.sub(r'([,{]\s*)(firstseenpatch|popularity|quality):', r'\1"\2":', source)
    return json.JSONDecoder().raw_decode(source)[0]


def parse_page(text, kind):
    if '"env":16' not in text or '"tree":16' not in text:
        raise ValueError("Response is not the Forever data tree")
    total = int(re.search(r'"numberOfItems":(\d+)', text).group(1))
    if kind == "items":
        rows = array_after(text, "var listviewitems = ")
        icons = array_after(text, "WH.Gatherer.addData(3, 16, ")
        for row in rows:
            row["icon"] = icons.get(str(row["id"]), {}).get("icon", "")
    else:
        source = text.split("new Listview(", 1)[1]
        rows = array_after(source, '"data":')
    if len({r["id"] for r in rows}) != len(rows) or len(rows) > total:
        raise ValueError("Invalid listing IDs/count")
    return total, rows


def collect(kind, cache, delay=0.5):
    criterion = 151 if kind == "items" else 37
    evidence = []

    def visit(low, high, root=False):
        # An explicit positive-ID filter uses the same listing mode as child
        # ranges. The unfiltered page can report a different total.
        url = BASE + kind + f"?filter={criterion};2;1"
        if not root:
            url = BASE + kind
            url += f"?filter={criterion}:{criterion};2:5;{low}:{high}"
        path = cache / (kind + ("-all" if root else f"-{low}-{high}") + ".html")
        if not path.exists():
            for attempt in range(3):
                try:
                    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                    data = urllib.request.urlopen(request, timeout=60).read()
                    # Validate before caching an error page.
                    parse_page(data.decode("utf-8"), kind)
                    path.write_bytes(data)
                    time.sleep(delay)
                    break
                except Exception:
                    if attempt == 2:
                        raise
                    time.sleep(2 * (attempt + 1))
        data = path.read_bytes()
        total, rows = parse_page(data.decode("utf-8"), kind)
        if any(not low <= r["id"] < high for r in rows):
            raise ValueError(f"Server ignored range filter: {url}")
        evidence.append({"url": url, "total": total, "displayed": len(rows),
                         "sha256": hashlib.sha256(data).hexdigest()})
        print(f"{kind} [{low},{high}): {len(rows)}/{total}", flush=True)
        if total == len(rows):
            return total, rows
        if not rows:
            raise ValueError("Truncated listing with no rows")
        ids = sorted(r["id"] for r in rows)
        split = ids[len(ids) // 2]
        if not low < split < high:
            raise ValueError("Cannot subdivide truncated range")
        left_count, left = visit(low, split)
        right_count, right = visit(split, high)
        if left_count + right_count != total:
            raise ValueError(f"Snapshot changed while collecting {url}; rebuild cache")
        return total, left + right

    total, rows = visit(0, 2147483647, True)
    if len(rows) != total or len({r["id"] for r in rows}) != total:
        raise ValueError("Final catalog does not match the declared count")
    return sorted(rows, key=lambda r: r["id"]), evidence


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cache", type=Path, required=True)
    args = parser.parse_args()
    args.cache.mkdir(parents=True, exist_ok=True)
    output = {"collected": datetime.now(timezone.utc).isoformat(), "tree": 16, "sources": {}}
    for kind in ("items", "npcs"):
        output[kind], output["sources"][kind] = collect(kind, args.cache)
        (args.cache / "wowhead-catalog.json").write_text(json.dumps(output, ensure_ascii=False), encoding="utf-8")
    print("Complete:", len(output["items"]), "items,", len(output["npcs"]), "creatures")


if __name__ == "__main__":
    main()
