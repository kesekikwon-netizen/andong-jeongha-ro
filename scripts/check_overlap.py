"""건물 충돌(중복 배치) 검사기.

  python scripts/check_overlap.py [radius_area]

- VWorldBlocks + Blocks(학교)의 모든 건물 레코드를 회전 적용 축정복스(AABB)로
  근사해 2건물 간 겹침 면적을 계산한다.
- 겹침 > 0.05 m^2 인 쌍을 출력한다.
"""

import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts"))
from zone import load_blocks  # noqa: E402


def rect_of(rec: dict):
    ox, oz = rec["offsetX"], rec["offsetZ"]
    w, d = rec.get("width", 8.0), rec.get("depth", 8.0)
    rot = rec.get("rotationY", 0.0) or 0.0
    # 6.5도 회전 → 외접박스 근사
    r = math.radians(rot)
    ew = abs(w * math.cos(r)) + abs(d * math.sin(r))
    ed = abs(w * math.sin(r)) + abs(d * math.cos(r))
    return ox, oz, ew / 2, ed / 2


def overlap(a, b) -> float:
    ax, az, ahw, ahd = a
    bx, bz, bhw, bhd = b
    dx = max(0.0, min(ax + ahw, bx + bhw) - max(ax - ahw, bx - bhw))
    dz = max(0.0, min(az + ahd, bz + bhd) - max(az - ahd, bz - bhd))
    return dx * dz


def main() -> None:
    blocks = load_blocks()
    rects = []
    for b in blocks:
        if "offsetX" not in b:
            continue
        rects.append((b["name"], rect_of(b)))

    hits = []
    n = len(rects)
    for i in range(n):
        na, ra = rects[i]
        for j in range(i + 1, n):
            nb, rb = rects[j]
            ar = overlap(ra, rb)
            if ar > 0.05:
                hits.append((ar, na, nb, ra, rb))

    hits.sort(reverse=True)
    print(f"buildings={n} overlapping_pairs={len(hits)}")
    for ar, na, nb, ra, rb in hits[:40]:
        cx = (ra[0] + rb[0]) / 2
        cz = (ra[1] + rb[2] + rb[1] + rb[3]) / 4
        print(
            f"  {ar:7.1f} m^2  {na} <- {nb}"
            f"   ({ra[0]:6.1f},{ra[1]:6.1f}) vs ({rb[0]:6.1f},{rb[1]:6.1f})"
        )


if __name__ == "__main__":
    main()
