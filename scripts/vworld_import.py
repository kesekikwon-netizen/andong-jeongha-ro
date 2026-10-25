#!/usr/bin/env python3
"""VWorld 건물 폴리곤 → Rojo Blocks 데이터 변환.

- VWorld DATA API (도메인 검증 통과용 domain 파라미터 필수)
- 좌표: 원점=학교 정문 추정점, +X=동, +Z=남, 단위 m
- 학교 부지 안 폴리곤은 제외하고(수제 모델 유지) 치수만 리포트로 출력
- 최소외접사각형(회전 캘리퍼스)으로 width/depth/rotation 계산
"""

import json
import math
import sys
import urllib.parse
import urllib.request

KEY = "5B991E6E-EFBF-482F-AAE3-CBF3A9E84783"
DOMAIN = "www.dong-guk.or.kr"
# 원점: 학교 정문 추정 (VWorld 최남단 학교 POI)
ORIGIN_LAT, ORIGIN_LON = 36.549777, 128.731262
# 학교 부지 제외 rect (미터, 원점=정문): 강남1길 78 실제 필지 범위
SCHOOL_RECT_M = (-5.0, -56.0, 112.0, 50.0)
RESIDENTIAL_WORDS = ("에버빌", "타운", "아파트", "빌라", "오피스텔", "하이츠", "파크")
BBOX = "BOX(128.7270,36.5460,128.7370,36.5530)"

OUT = "src/shared/Data/VWorldBlocks.luau"


def fetch_all():
    feats = []
    base = (
        "https://api.vworld.kr/req/data?service=data&version=2.0&request=GetFeature"
        f"&key={KEY}&format=json&data=LT_C_SPBD&crs=EPSG:4326&size=1000&domain={DOMAIN}"
    )
    url = base + "&geomFilter=" + urllib.parse.quote(BBOX)
    with urllib.request.urlopen(url, timeout=60) as r:
        j = json.load(r)
    if j["response"]["status"] != "OK":
        sys.exit(f"VWorld error: {j['response']}")
    fc = j["response"]["result"]["featureCollection"]
    feats = fc["features"] if isinstance(fc, dict) else fc
    print(f"total={j['response']['record']['total']} got={len(feats)}", file=sys.stderr)
    return feats


def to_meters(lon, lat):
    e = (lon - ORIGIN_LON) * 111320.0 * math.cos(math.radians(ORIGIN_LAT))
    s = (ORIGIN_LAT - lat) * 110540.0  # +Z = 남
    return e, s


def hull(points):
    pts = sorted(set(points))
    if len(pts) <= 1:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def min_rect(h):
    """최소면적 외접사각형. 반환: (cx, cy, w, h, angle_deg). angle은 +X축에서 +Y쪽으로."""
    n = len(h)
    if n == 0:
        return (0, 0, 0, 0, 0)
    if n == 1:
        return (h[0][0], h[0][1], 0, 0, 0)
    if n == 2:
        cx = (h[0][0] + h[1][0]) / 2
        cy = (h[0][1] + h[1][1]) / 2
        w = math.dist(h[0], h[1])
        a = math.degrees(math.atan2(h[1][1] - h[0][1], h[1][0] - h[0][0]))
        return (cx, cy, w, 0.5, a)
    best = None
    for i in range(n):
        x1, y1 = h[i]
        x2, y2 = h[(i + 1) % n]
        ang = math.atan2(y2 - y1, x2 - x1)
        ca2, sa2 = math.cos(ang), math.sin(ang)
        rx = [p[0] * ca2 + p[1] * sa2 for p in h]
        ry = [-p[0] * sa2 + p[1] * ca2 for p in h]
        minx, maxx, miny, maxy = min(rx), max(rx), min(ry), max(ry)
        area = (maxx - minx) * (maxy - miny)
        if best is None or area < best[0]:
            a_deg = math.degrees(ang)
            cx = (minx + maxx) / 2
            cy = (miny + maxy) / 2
            # 역회전으로 중심 복원
            ox = cx * ca2 - cy * sa2
            oy = cx * sa2 + cy * ca2
            best = (area, ox, oy, maxx - minx, maxy - miny, a_deg)
    _, ox, oy, w, hh, a = best
    return (ox, oy, w, hh, a)


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    feats = fetch_all()
    records = []
    school_candidates = []
    skipped_shed = 0
    for f in feats:
        p = f["properties"]
        g = f["geometry"]
        polys = g["coordinates"] if g["type"] == "MultiPolygon" else [g["coordinates"]]
        # 가장 큰 링 사용
        ring = max((poly[0] for poly in polys), key=len)
        # 학교 부지 제외 판정 (centroid)
        lons = [c[0] for c in ring]
        lats = [c[1] for c in ring]
        clon, clat = sum(lons) / len(lons), sum(lats) / len(lats)
        pts = [to_meters(lon, lat) for lon, lat in ring]
        cex = sum(p[0] for p in pts) / len(pts)
        cey = sum(p[1] for p in pts) / len(pts)
        x0, y0, x1, y1 = SCHOOL_RECT_M
        in_rect = x0 <= cex <= x1 and y0 <= cey <= y1
        area = abs(
            sum(
                pts[i][0] * pts[(i + 1) % len(pts)][1]
                - pts[(i + 1) % len(pts)][0] * pts[i][1]
                for i in range(len(pts))
            )
            / 2
        )
        cx, cy, w, hh, ang = min_rect(hull(pts))
        # 긴 변을 width로
        if hh > w:
            w, hh = hh, w
            ang += 90.0
        ang = ((ang + 90.0) % 180.0) - 90.0  # -90 ~ 90
        try:
            floors = int(str(p.get("gro_flo_co") or "0"))
        except ValueError:
            floors = 0
        if floors <= 0:
            floors = 2 if area >= 60 else 1

        buld_nm = (p.get("buld_nm") or "").strip()
        label = buld_nm or f"{p.get('rd_nm') or ''} {p.get('buld_no') or ''}".strip()

        if in_rect and floors < 10 and not any(w in buld_nm for w in RESIDENTIAL_WORDS):
            school_candidates.append(
                {
                    "label": label,
                    "cx": cx,
                    "cy": cy,
                    "w": w,
                    "h": hh,
                    "floors": floors,
                    "area": area,
                    "ang": ang,
                }
            )
            continue
        if area < 25:
            skipped_shed += 1
            continue

        rot = -round(
            ang, 1
        )  # Roblox yaw (+X에서 +Z 방향 각도 -> CFrame.Angles(0, rad(rot), 0))
        if abs(rot) < 2.0:
            rot = 0.0
        sn = str(p.get("bd_mgt_sn") or "")
        tail = sn[-6:] if len(sn) >= 6 else "000000"
        rid = f"vw-{len(records) + 1:03d}-{tail}"
        if floors >= 8 or area >= 900:
            kind = "apartment"
            units = max(1, round(w / 14.0))
            params = (
                f"offsetX = {cx:.1f}, offsetZ = {cy:.1f}, width = {w:.1f}, depth = {hh:.1f}, "
                f"floors = {floors}, floorHeight = 3.0, unitsPerFloor = {units}, "
                f'number = {lua_str(p.get("buld_no") or "")}, palette = "gray"'
            )
        else:
            kind = "shophouse"
            cols = max(2, round(w / 3.5))
            sign = buld_nm or (p.get("buld_no") or "")
            params = (
                f"offsetX = {cx:.1f}, offsetZ = {cy:.1f}, width = {w:.1f}, depth = {hh:.1f}, "
                f"floors = {min(floors, 5)}, floorHeight = 3.4, columns = {cols}, "
                f'facing = "south", signText = {lua_str(sign)}'
            )
        records.append(
            f"\t{{ id = {lua_str(rid)}, name = {lua_str(label)}, kind = {lua_str(kind)}, "
            f'verified = false, source = "vworld", rotationY = {rot}, params = {{ {params} }} }},'
        )

    with open(OUT, "w", encoding="utf-8") as f:
        f.write(
            "--!strict\n-- VWorld 건물 폴리곤 자동 생성 (scripts/vworld_import.py). 직접 수정 금지, 재생성으로 갱신.\n"
        )
        f.write(
            f"-- 원점: 정문 추정 ({ORIGIN_LAT}, {ORIGIN_LON}). rotationY 부호는 Studio 대조 후 확정 필요.\n"
        )
        f.write("-- 좌표계: +X=동, +Z=남, 단위 m.\n\nlocal VWorldBlocks = {\n")
        f.write("\n".join(records))
        f.write("\n}\n\nreturn VWorldBlocks\n")

    print(f"records={len(records)} sheds_skipped={skipped_shed}", file=sys.stderr)
    print("SCHOOL_SITE (all):", file=sys.stderr)
    for s in sorted(school_candidates, key=lambda s: -s["area"]):
        print(
            f"  {s['label']!r} c=({s['cx']:.1f},{s['cy']:.1f}) {s['w']:.0f}x{s['h']:.0f} f={s['floors']} a={s['area']:.0f} r={s['ang']:.0f}",
            file=sys.stderr,
        )


if __name__ == "__main__":
    main()
