"""파노라마에서 보이는 건물 목록을 방위순으로 출력한다.

  python scripts/zone.py DlPs12G8z5Yxtle6UuL7Ug --radius 70
  python scripts/zone.py DlPs12G8z5Yxtle6UuL7Ug --radius 70 --crop 0,60

파노라마 촬영좌표(경위도)를 평면 미터로 변환해 VWorldBlocks 건물의 상대 방위를 계산한다.
"""

import argparse
import json
import math
import os
import re
import urllib.request

UA = {"User-Agent": "Mozilla/5.0", "Referer": "https://map.naver.com/"}

ORIGIN_LAT = 36.549777
ORIGIN_LON = 128.731262
M_PER_DEG_LAT = 111132.0
M_PER_DEG_LON = 111320.0 * math.cos(math.radians(ORIGIN_LAT))

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BLOCKS = os.path.join(ROOT, "src", "shared", "Data", "VWorldBlocks.luau")


def meta(pano: str) -> dict:
    url = f"https://panorama.map.naver.com/metadataV3/basic/{pano}?lang=ko"
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)


def to_xy(lat: float, lon: float) -> tuple[float, float]:
    return (
        (lon - ORIGIN_LON) * M_PER_DEG_LON,
        -(lat - ORIGIN_LAT) * M_PER_DEG_LAT,
    )


def load_blocks() -> list[dict]:
    text = open(BLOCKS, encoding="utf-8").read()
    out = []
    for m in re.finditer(r"\{\s*id = \"([^\"]+)\",(.*?)\n\t\},", text, re.S):
        rid, body = m.groups()
        rec = {"id": rid}
        for key in ("name", "kind"):
            mm = re.search(rf'{key} = "([^"]*)"', body)
            if mm:
                rec[key] = mm.group(1)
        for key in ("rotationY", "offsetX", "offsetZ", "width", "depth", "floors"):
            mm = re.search(rf"{key} = (-?[\d.]+)", body)
            if mm:
                rec[key] = float(mm.group(1))
        out.append(rec)
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("pano", nargs="?")
    ap.add_argument("--id", help="파노라마 ID (-로 시작하는 경우 사용)")
    ap.add_argument("--radius", type=float, default=80)
    ap.add_argument("--limit", type=int, default=40)
    ap.add_argument("--out", default=None)
    a = ap.parse_args()
    a.pano = a.pano or a.id
    info = meta(a.pano)
    cx, cz = to_xy(info["latitude"], info["longitude"])
    yaw = float(info["camera_angle"][1])
    lines = [
        f"pano={a.pano} pos=({cx:.1f}, {cz:.1f}) yaw={yaw:.1f}",
        f"title={info['info'].get('title')} / {info['info'].get('description')}",
    ]

    rows = []
    for b in load_blocks():
        if "offsetX" not in b:
            continue
        dx = b["offsetX"] - cx
        dz = b["offsetZ"] - cz
        dist = math.hypot(dx, dz)
        if dist > a.radius:
            continue
        # 방위: 0=북(-Z), 90=동(+X)
        bearing = (math.degrees(math.atan2(dx, -dz)) + 360) % 360
        rows.append((bearing, dist, b))

    rows.sort()
    for bearing, dist, b in rows[: a.limit]:
        lines.append(
            f"  {bearing:6.1f}deg  {dist:5.1f}m  {b['name']:<18} "
            f"({b['offsetX']:6.1f},{b['offsetZ']:6.1f}) w{b.get('width', 0):4.1f} "
            f"d{b.get('depth', 0):4.1f} f{int(b.get('floors', 0))} {b.get('kind')}"
        )

    text = "\n".join(lines)
    if a.out:
        folder = os.path.dirname(a.out)
        if folder:
            os.makedirs(folder, exist_ok=True)
        with open(a.out, "w", encoding="utf-8") as f:
            f.write(text + "\n")
        print(a.out)
    else:
        print(text)


if __name__ == "__main__":
    main()
