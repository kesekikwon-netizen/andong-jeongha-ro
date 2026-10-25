"""로드뷰 파노라마 반경 내 건물 목록 및 RoadviewShops 매칭 현황 집계."""

import glob
import os
import re
from zone import load_blocks

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RV_SHOPS = os.path.join(ROOT, "src", "shared", "Data", "RoadviewShops.luau")


def load_rv_shops() -> dict[str, bool]:
    text = open(RV_SHOPS, encoding="utf-8").read()
    out = {}
    for m in re.finditer(r'\["([^"]+)"\]\s*=\s*\{(.*?)\n\t\},', text, re.S):
        name, body = m.groups()
        ver = "verified = true" in body
        out[name] = ver
    return out


def main() -> None:
    blocks = {b["name"]: b for b in load_blocks() if "name" in b}
    rv = load_rv_shops()
    seen: dict[str, list[tuple[float, float, str]]] = {}

    for p in sorted(glob.glob(os.path.join(ROOT, "data", "tmp", "zone_*.txt"))):
        pano = os.path.basename(p)[5:-4]
        if len(pano) < 15:
            continue
        for line in open(p, encoding="utf-8"):
            m = re.match(r"\s+([\d.]+)deg\s+([\d.]+)m\s+(\S+\s+\S+)", line)
            if m:
                deg, dist, name = float(m.group(1)), float(m.group(2)), m.group(3).strip()
                if dist <= 45.0:
                    seen.setdefault(name, []).append((dist, deg, pano))

    print(f"Total buildings within 45m of roadview panos: {len(seen)}")
    print(f"Currently in RoadviewShops.luau: {len(rv)} (verified={sum(rv.values())})")
    for name in sorted(seen.keys()):
        best = min(seen[name])
        b = blocks.get(name, {})
        status = (
            "VERIFIED"
            if rv.get(name) is True
            else ("UNVERIFIED" if name in rv else "MISSING")
        )
        print(
            f"  [{status:<10}] {name:<16} best={best[0]:4.1f}m @{best[1]:5.1f}deg"
            f" pano={best[2]} f={int(b.get('floors', 0))} kind={b.get('kind')}"
        )


if __name__ == "__main__":
    main()
