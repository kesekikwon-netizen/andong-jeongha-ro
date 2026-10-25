"""건물 겹침 수정기 (학교 주변 밀집 구간).

  python scripts/fix_positions.py             # 리포트만 (수정 없음)
  python scripts/fix_positions.py --apply     # VWorldBlocks.luau에 직접 적용

- check_overlap.py와 동일한 회전 외접박스(AABB) 근사로 겹침쌍을 찾는다.
- 각 쌍마다 주 겹침 축(X 또는 Z)을 골라
  1) 두 건물의 폭/깊이를 대칭으로 축소 (건물당 최대 1.5m/pass, 원본 55% 하한)
  2) 부족하면 두 중심을 축 방향으로 서로 밀어낸다 (pass당 1.2m, 누적 3m 한계)
- 대상: 학교 주변 (|X|<180, |Z|<150). 원본 백업은 data/tmp/VWorldBlocks.bak.lua
"""

import argparse
import math
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts"))
from zone import BLOCKS  # noqa: E402

CLEAR = 0.6  # 목표 간격 (m)
SHRINK_CAP = 1.2  # pass별 축소 한계 (건물당, 크기 비례 캡과 함께 적용)
MOVE_STEP = 1.2  # pass별 이동 한계 (건물당)
DRIFT_CAP = 6.0  # 중심 이동 누적 한계 (m)
MIN_SCALE = 0.55  # 최소 폭/깊이 = 원본 * 0.55

NEAR_X = 180.0
NEAR_Z = 150.0


def rect_of(rec: dict):
    ox, oz = rec["offsetX"], rec["offsetZ"]
    w, d = rec.get("width", 8.0), rec.get("depth", 8.0)
    rot = rec.get("rotationY", 0.0) or 0.0
    r = math.radians(rot)
    ew = abs(w * math.cos(r)) + abs(d * math.sin(r))
    ed = abs(w * math.sin(r)) + abs(d * math.cos(r))
    return ox, oz, ew / 2, ed / 2


def pair_deficit(a, b):
    ax, az, ahw, ahd = a
    bx, bz, bhw, bhd = b
    dx = (ahw + bhw) - abs(ax - bx)
    dz = (ahd + bhd) - abs(az - bz)
    if dx <= 0 or dz <= 0:
        return 0.0, 0.0, 0.0
    return dx, dz, dx * dz


def find_records_with_spans(text: str):
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
        rec["body_start"] = m.start(2)
        rec["body_end"] = m.end(2)
        out.append(rec)
    return out


def patch_record(text: str, rec: dict) -> str:
    """레코드 body 범위 안에서 offsetX/offsetZ/width/depth 수치만 치환."""
    start, end = rec["body_start"], rec["body_end"]
    body = text[start:end]
    for key in ("offsetX", "offsetZ", "width", "depth"):
        if key in rec:
            body = re.sub(
                rf"{key} = -?[\d.]+", f"{key} = {rec[key]:.1f}", body, count=1
            )
    return text[:start] + body + text[end:]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--minx", type=float, default=-NEAR_X)
    ap.add_argument("--maxx", type=float, default=NEAR_X)
    ap.add_argument("--minz", type=float, default=-NEAR_Z)
    ap.add_argument("--maxz", type=float, default=NEAR_Z)
    args = ap.parse_args()

    with open(BLOCKS, encoding="utf-8") as f:
        text = f.read()
    records = find_records_with_spans(text)

    for r in records:
        r["w0"] = r.get("width", 8.0)
        r["d0"] = r.get("depth", 8.0)
        r["x0"] = r.get("offsetX", 0.0)
        r["z0"] = r.get("offsetZ", 0.0)

    near = [
        r
        for r in records
        if "offsetX" in r
        and args.minx < r["offsetX"] < args.maxx
        and args.minz < r["offsetZ"] < args.maxz
    ]
    print(
        f"total={len(records)} zone=({args.minx},{args.minz})..({args.maxx},{args.maxz})"
        f" count={len(near)}"
    )

    def fix_pass():
        rects = [(r, rect_of(r)) for r in near]
        hits = []
        for i in range(len(rects)):
            ra, rr = rects[i]
            for j in range(i + 1, len(rects)):
                rb, br = rects[j]
                # 동일 주소(같은 대지의 본동+별동 폴리곤)는 겹침으로 취급하지 않는다
                if ra["name"] == rb["name"]:
                    continue
                dfx, dfz, ov = pair_deficit(rr, br)
                if ov > 0.05:
                    hits.append((ov, ra, rb, rr, br, dfx, dfz))
        hits.sort(key=lambda h: -h[0])
        return hits

    for it in range(400):
        hits = fix_pass()
        if not hits:
            print(f"cleared after {it} passes")
            break
        changed = 0
        for _, ra, rb, _, _, dfx, dfz in hits[:80]:
            # 더 작은 부족량 축이 분리 비용이 작다 (골목열 건물은 폭 조정만으로 해결)
            if dfx <= dfz:
                need, dim, axis = dfx + CLEAR, "width", "offsetX"
            else:
                need, dim, axis = dfz + CLEAR, "depth", "offsetZ"
            moved_need = need
            for rec, other in ((ra, rb), (rb, ra)):
                if dim == "width":
                    min_size = max(1.0, rec["w0"] * MIN_SCALE)
                    cap = min(SHRINK_CAP, max(0.3, rec["w0"] * 0.04))
                    if rec["width"] > min_size:
                        cut = min(need * 0.15, rec["width"] - min_size, cap)
                        rec["width"] = round(rec["width"] - cut, 1)
                        moved_need -= cut * 2
                        changed += 1
                else:
                    min_size = max(1.0, rec["d0"] * MIN_SCALE)
                    cap = min(SHRINK_CAP, max(0.3, rec["d0"] * 0.04))
                    if rec["depth"] > min_size:
                        cut = min(need * 0.15, rec["depth"] - min_size, cap)
                        rec["depth"] = round(rec["depth"] - cut, 1)
                        moved_need -= cut * 2
                        changed += 1
                if moved_need <= 0.01:
                    continue
                base0 = rec["x0"] if axis == "offsetX" else rec["z0"]
                drift = abs(rec[axis] - base0)
                if drift < DRIFT_CAP:
                    sign = 1 if rec[axis] >= other[axis] else -1
                    step = min(moved_need * 0.5, MOVE_STEP, DRIFT_CAP - drift)
                    if step > 0.05:
                        rec[axis] = round(rec[axis] + sign * step, 1)
                        changed += 1
        if changed == 0:
            remains = [
                (round(h[0], 1), h[1].get("name"), h[2].get("name")) for h in hits[:10]
            ]
            print(f"no progress after {it} passes, remaining: {remains}")
            break

    final = fix_pass()
    print(f"final overlapping pairs: {len(final)}")
    for _, ra, rb, _, _, dfx, dfz in final[:15]:
        print(f"  dx={dfx:6.2f} dz={dfz:6.2f}  {ra.get('name')} <- {rb.get('name')}")

    # 조정 내역 요약 (dry-run에서도 확인 가능)
    log = []
    for r in records:
        if "offsetX" not in r:
            continue
        dw = r["width"] - r["w0"]
        dd = r["depth"] - r["d0"]
        dx = r["offsetX"] - r["x0"]
        dz = r["offsetZ"] - r["z0"]
        if dw != 0 or dd != 0 or dx != 0 or dz != 0:
            log.append(
                f"{r['id']} {r.get('name')}: w{dw:+.1f} d{dd:+.1f} x{dx:+.1f} z{dz:+.1f}"
            )
    print(f"changed records: {len(log)}")
    for line in log:
        print(f"  {line}")

    if args.apply:
        shutil.copy(BLOCKS, os.path.join(ROOT, "data", "tmp", "VWorldBlocks.bak.lua"))
        out = text
        spans = [(r["body_start"], r) for r in records if "offsetX" in r]
        spans.sort(key=lambda s: -s[0])
        moved = 0
        for _, rec in spans:
            if (
                rec["width"] != rec["w0"]
                or rec["depth"] != rec["d0"]
                or rec["offsetX"] != rec["x0"]
                or rec["offsetZ"] != rec["z0"]
            ):
                out = patch_record(out, rec)
                moved += 1
        with open(BLOCKS, "w", encoding="utf-8") as f:
            f.write(out)
        print(f"applied: {moved} records patched")
        with open(
            os.path.join(ROOT, "data", "tmp", "fix_positions_log.txt"),
            "w",
            encoding="utf-8",
        ) as f:
            f.write("\n".join(log) + "\n")
        print(f"log: data/tmp/fix_positions_log.txt ({len(log)} entries)")


if __name__ == "__main__":
    main()
