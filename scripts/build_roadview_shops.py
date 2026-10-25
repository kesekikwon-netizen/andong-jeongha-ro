"""6개 구역(강남1길, 강남1길 88-*, 강남1길 98-*, 강남6길, 강남7길, 강남5길·강남4길)의 로드뷰 실측 데이터를
병합하여 src/shared/Data/RoadviewShops.luau 를 생성한다.
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

VALID_STYLES = {
    "beige_stone",
    "dark_slate",
    "red_brick",
    "gray_stucco",
    "white_stucco",
    "charcoal_panel",
    "beige_tile",
    "wood_curtainwall",
    "terracotta_tile",
}

STYLE_MAP = {
    "gray_stone": "gray_stucco",
    "cream_stucco": "white_stucco",
    "gray_tile": "beige_tile",
    "charcoal_metal": "charcoal_panel",
    "dark_stone": "dark_slate",
    "beige_brick": "beige_tile",
    "brown_brick": "red_brick",
}

VALID_ROOFS = {"flat", "gable_green", "gable_red", "gable_blue", "hip_dark"}

ROOF_MAP = {
    "gable": "gable_red",
}

NAMED_COLORS = {
    "white": [242, 242, 245],
    "black": [32, 34, 38],
    "red": [198, 38, 38],
    "blue": [28, 68, 148],
    "green": [38, 128, 68],
    "yellow": [235, 195, 45],
    "silver": [195, 200, 208],
}


def hex_to_rgb(h: str | list | None) -> list[int] | None:
    if h is None:
        return None
    if isinstance(h, list) and len(h) == 3:
        return [int(x) for x in h]
    if isinstance(h, str):
        s = h.strip().lstrip("#")
        if s in NAMED_COLORS:
            return NAMED_COLORS[s]
        if len(s) == 6:
            return [int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)]
    return None


def norm_style(s: str | None) -> str:
    if not s:
        return "beige_stone"
    s = STYLE_MAP.get(s, s)
    return s if s in VALID_STYLES else "beige_stone"


def norm_roof(r: str | None) -> str:
    if not r:
        return "flat"
    r = ROOF_MAP.get(r, r)
    return r if r in VALID_ROOFS else "flat"


def find_vworld_duplicates() -> dict[str, list[dict]]:
    vw_path = os.path.join(ROOT, "src", "shared", "Data", "VWorldBlocks.luau")
    text = open(vw_path, encoding="utf-8").read()
    pat = re.compile(
        r'id = "([^"]+)",\s*name = "([^"]+)",\s*kind = "([^"]+)",.*?'
        r"offsetX = ([-\d.]+),\s*offsetZ = ([-\d.]+),\s*width = ([-\d.]+),\s*depth = ([-\d.]+),\s*floors = (\d+)",
        re.S,
    )
    by_name: dict[str, list[dict]] = {}
    for m in pat.finditer(text):
        rec = {
            "id": m.group(1),
            "name": m.group(2),
            "kind": m.group(3),
            "x": float(m.group(4)),
            "z": float(m.group(5)),
            "w": float(m.group(6)),
            "d": float(m.group(7)),
            "f": int(m.group(8)),
        }
        by_name.setdefault(rec["name"], []).append(rec)
    return by_name


def load_zone1() -> dict[str, dict]:
    path = os.path.join(ROOT, "data", "observations", "zones", "zone1_gangnam1gil.json")
    if not os.path.exists(path):
        path = os.path.join(ROOT, "data", "tmp", "audit_gangnam1gil.json")
    raw = json.load(open(path, encoding="utf-8"))
    out = {}
    for addr, d in raw.items():
        if addr == "강남1길 72":
            # 학교 본관은 Blocks.luau School 키트에서 처리
            continue
        signs = d.get("signs", [])
        f1_signs = [s["text"] for s in signs if s.get("floor", 1) == 1 and s.get("text")]
        f2_signs = [s["text"] for s in signs if s.get("floor", 1) >= 2 and s.get("text")]
        sign_text = f1_signs[0] if f1_signs else (f2_signs[0] if f2_signs else None)
        shop_signs = f1_signs if len(f1_signs) >= 2 else None
        sub_sign = " · ".join(f2_signs) if f2_signs else (f1_signs[1] if len(f1_signs) == 2 else None)
        sign_color = hex_to_rgb(signs[0].get("bg")) if signs else None

        out[addr] = {
            "sign": sign_text,
            "shopSigns": shop_signs,
            "subSign": sub_sign,
            "floors": d.get("floors", 3),
            "style": norm_style(d.get("style")),
            "roofType": norm_roof(d.get("roofType")),
            "signColor": sign_color,
            "awningColor": hex_to_rgb(d.get("awningColor")),
            "piloti": bool(d.get("piloti")),
            "deck": bool(d.get("deck")),
            "stoneFascia": bool(d.get("stoneFascia")),
            "verified": True,
            "note": d.get("notes", ""),
        }
    return out


def load_zone2() -> dict[str, dict]:
    path = os.path.join(ROOT, "data", "observations", "zones", "zone_south88.json")
    raw = json.load(open(path, encoding="utf-8"))
    out = {}
    for addr, d in raw.items():
        entry = {
            "sign": d.get("sign") or None,
            "subSign": d.get("subSign") or None,
            "verticalSign": d.get("verticalSign") or None,
            "floors": d.get("floors", 3),
            "style": norm_style(d.get("style")),
            "roofType": norm_roof(d.get("roofType")),
            "signColor": hex_to_rgb(d.get("signColor")),
            "awningColor": hex_to_rgb(d.get("awningColor")),
            "piloti": bool(d.get("piloti")),
            "deck": bool(d.get("deck")),
            "stoneFascia": bool(d.get("stoneFascia")),
            "noSign": bool(d.get("noSign")),
            "verified": True,
            "note": d.get("note", ""),
        }
        if addr == "강남1길 88-7":
            entry["spire"] = True
        out[addr] = entry
    return out


def load_zone3() -> dict[str, dict]:
    path = os.path.join(ROOT, "data", "observations", "zones", "zone3_gangnam1_98.json")
    raw = json.load(open(path, encoding="utf-8")).get("buildings", {})
    out = {}
    for addr, d in raw.items():
        signs = d.get("signs", [])
        f1 = [s for s in signs if s.get("floor", 1) == 1]
        f2 = [s for s in signs if s.get("floor", 1) >= 2]
        f1_texts = [s["text"] for s in f1 if s.get("text")]
        f2_texts = [
            f"{s['text']} · {s['sub']}" if s.get("sub") else s["text"]
            for s in f2
            if s.get("text")
        ]
        sign_text = f1_texts[0] if f1_texts else (f2[0]["text"] if f2 else None)
        shop_signs = f1_texts if len(f1_texts) >= 2 else None
        sub_sign = " / ".join(f2_texts) if f2_texts else (f1[0].get("sub") if f1 else None)
        first_bg = hex_to_rgb(f1[0].get("bg")) if f1 else (hex_to_rgb(f2[0].get("bg")) if f2 else None)
        entry = {
            "sign": sign_text,
            "shopSigns": shop_signs,
            "subSign": sub_sign,
            "style": norm_style(d.get("wall")),
            "roofType": norm_roof(d.get("roof")),
            "signColor": first_bg,
            "awningColor": hex_to_rgb(d.get("awningColor")),
            "piloti": bool(d.get("piloti")),
            "deck": bool(d.get("deck")),
            "stoneFascia": bool(d.get("stoneFascia")),
            "verified": True,
            "note": d.get("note", ""),
        }
        if addr == "vw-324-015852":
            entry["floors"] = 1
            entry["facing"] = "north"
        out[addr] = entry
    return out


def load_zone4() -> dict[str, dict]:
    path = os.path.join(ROOT, "data", "observations", "zones", "zone_gangnam6.json")
    raw = json.load(open(path, encoding="utf-8"))
    out = {}
    for addr, d in raw.items():
        out[addr] = {
            "sign": d.get("sign") or None,
            "subSign": d.get("subSign") or None,
            "verticalSign": d.get("verticalSign") or None,
            "floors": d.get("floors", 3),
            "style": norm_style(d.get("style")),
            "roofType": norm_roof(d.get("roofType")),
            "signColor": hex_to_rgb(d.get("signColor")),
            "awningColor": hex_to_rgb(d.get("awningColor")),
            "piloti": bool(d.get("piloti")),
            "deck": bool(d.get("deck")),
            "stoneFascia": bool(d.get("stoneFascia")),
            "noSign": bool(d.get("noSign")),
            "verified": True,
            "note": d.get("note", ""),
        }
    return out


def load_zone5() -> dict[str, dict]:
    path = os.path.join(ROOT, "data", "observations", "zone5_gil7.json")
    raw = json.load(open(path, encoding="utf-8"))
    out = {}
    for d in raw:
        addr = d["address"]
        sub_raw = d.get("subSign")
        # 괄호 설명 축약
        sub_clean = None
        if sub_raw:
            parts = [re.sub(r"\s*\(.*?\)", "", p).strip() for p in sub_raw.split("/")]
            sub_clean = " · ".join([p for p in parts if p])
        is_villa = addr in ("강남7길 7-8", "강남7길 16")
        out[addr] = {
            "sign": d.get("sign") or None,
            "subSign": sub_clean,
            "floors": d.get("observedFloors") or d.get("vworldFloors", 2),
            "style": norm_style(d.get("style")),
            "roofType": norm_roof(d.get("roofType")),
            "signColor": hex_to_rgb(d.get("signColor")),
            "piloti": bool(d.get("piloti")),
            "stoneFascia": bool(d.get("stoneFascia")),
            "noSign": is_villa,
            "verified": True,
            "note": d.get("notes", ""),
        }
    return out


def load_zone6(by_name: dict[str, list[dict]]) -> dict[str, dict]:
    out = {
        "강남5길 61": {
            "sign": "강남왕족발",
            "shopSigns": ["강남왕족발", "빅스타피자"],
            "subSign": "WAVE home study · 아담가정과",
            "verticalSign": "미래공부교실",
            "floors": 3,
            "style": "gray_stucco",
            "roofType": "flat",
            "signColor": [32, 36, 44],
            "stoneFascia": True,
            "verified": True,
            "note": "pano=RYMucZX(100-126deg), afYrq3H7Wt5xqfLWijuf_A. 회색 석재 3층 상가주택, 1층 강남왕족발·빅스타피자, 2층 WAVE home study·아담가정과, 세로간판 미래공부교실 확인.",
        },
        "강남5길 62": {
            "sign": "맛닭꼬",
            "subSign": "베이크치킨 전문점",
            "floors": 3,
            "style": "beige_stone",
            "roofType": "flat",
            "signColor": [42, 38, 36],
            "awningColor": [200, 35, 35],
            "stoneFascia": True,
            "verified": True,
            "note": "pano=grkR3cBqcdrrq_RCopeUzg, afYrq3H7Wt5xqfLWijuf_A. 베이지 석재 3층 상가주택, 1층 적색 어닝 및 '맛닭꼬' 간판 확인.",
        },
        "강남5길 60": {
            "sign": None,
            "floors": 2,
            "style": "charcoal_panel",
            "roofType": "flat",
            "noSign": True,
            "verified": True,
            "note": "pano=zPViYf8O2MwZNvWI_shuHQ. 2층 차콜 벽돌 및 우드 사이딩 모던 단독주택(상가 간판 없음).",
        },
        "강남6길 18": {
            "sign": None,
            "floors": 3,
            "style": "gray_stucco",
            "roofType": "flat",
            "noSign": True,
            "verified": True,
            "note": "pano=cG7rWLqQ5Mn_Jh91qJElxg(25.9deg). 3층 밝은 회색 석재 다가구주택(상가 간판 없음).",
        },
        "강남6길 19": {
            "sign": "조원경 첼로",
            "floors": 2,
            "style": "beige_stone",
            "roofType": "flat",
            "verified": True,
            "note": "pano=e_5uf5p_WpMIFpARJ21Kzg(60.1deg). 강남6길 15 동측 인접 2층 상가건물, '조원경 첼로' 입점 확인.",
        },
        "강남7길 15-8": {
            "sign": None,
            "floors": 3,
            "style": "gray_stucco",
            "roofType": "flat",
            "piloti": True,
            "stoneFascia": True,
            "noSign": True,
            "verified": True,
            "note": "pano=0bIyFUERCs5vYIlmXJYD0g(80.9deg). 우측 기둥 도로명주소판 '15-8' 확인. 1층 흑색 화강석 필로티 주차장 + 2~3층 회색 화강석 다가구주택.",
        },
        "강남7길 15-10": {
            "sign": None,
            "floors": 2,
            "style": "gray_stucco",
            "roofType": "flat",
            "stoneFascia": True,
            "noSign": True,
            "verified": True,
            "note": "pano=cG7rWLqQ5Mn_Jh91qJElxg(70.7deg). 우측 기둥 도로명주소판 '15-10' 확인. 1층 흑색 석재 프레임 공방/상가 + 2층 회색 석재 타일 모던 건물.",
        },
        "강남7길 16": {
            "sign": "해오름 A",
            "floors": 3,
            "style": "gray_stucco",
            "roofType": "gable_red",
            "piloti": True,
            "stoneFascia": True,
            "noSign": True,
            "verified": True,
            "note": "pano=AaP-NFN_DVoeuFoqwul6cw(202.7deg). 1층 필로티 주차장 상단 인방석 '해오름 A' 명패 확인.",
        },
        "강남7길 17": {
            "sign": "리드인 독서논술학원",
            "subSign": "READIN 독서테라피 · 010-3233-3147",
            "verticalSign": "리드인\n독서논술",
            "floors": 3,
            "style": "gray_stucco",
            "roofType": "flat",
            "signColor": [242, 242, 245],
            "stoneFascia": True,
            "verified": True,
            "note": "pano=AaP-NFN_DVoeuFoqwul6cw(8.0deg). 우측 기둥 도로명주소판 '17' 확인. 1층 백색 파시아 'READIN 독서테라피 리드인 독서논술학원 경북2지사 직영원 010.3233.3147' 확인.",
        },
        "강남7길 18": {
            "sign": "해오름 B",
            "floors": 3,
            "style": "gray_stucco",
            "roofType": "gable_red",
            "piloti": True,
            "stoneFascia": True,
            "noSign": True,
            "verified": True,
            "note": "pano=AaP-NFN_DVoeuFoqwul6cw(150.8deg). 1층 필로티 주차장 상단 인방석 '해오름 B' 명패 확인.",
        },
        "강남7길 21": {
            "sign": None,
            "floors": 1,
            "style": "white_stucco",
            "roofType": "flat",
            "noSign": True,
            "verified": True,
            "note": "pano=AaP-NFN_DVoeuFoqwul6cw(54.3deg). 1층 백색 사이딩 소형 상가/주택.",
        },
        "강남1길 121-5": {
            "sign": None,
            "floors": 2,
            "style": "gray_stucco",
            "roofType": "flat",
            "noSign": True,
            "verified": True,
            "note": "pano=AaP-NFN_DVoeuFoqwul6cw(113.4deg). 2층 회색 석재 타일 다가구주택.",
        },
        "강남1길 115": {
            "sign": None,
            "floors": 3,
            "style": "gray_stucco",
            "roofType": "flat",
            "noSign": True,
            "verified": True,
            "note": "pano=AaP-NFN_DVoeuFoqwul6cw(161.2deg). 3층 회색 석재 다가구/상가주택.",
        },
        "강남5길 59": {
            "sign": "(주)에스에너지",
            "subSign": "태양광 · 신재생에너지전문기업",
            "floors": 3,
            "style": "charcoal_panel",
            "roofType": "flat",
            "signColor": [242, 244, 248],
            "stoneFascia": True,
            "verified": True,
            "note": "pano=zPViYf8O2MwZNvWI_shuHQ, _u0lX8s6a07lB-O4yW7p2A. VWorld f=1이나 실제 3층 차콜/석재 사옥형 건물, 1층 백색 파시아 '(주)에스에너지 태양광·신재생에너지전문기업' 확인.",
        },
        "강남5길 58": {
            "sign": "강남한의원",
            "subSign": "좋은치과 · 방가전",
            "verticalSign": "좋은치과",
            "floors": 3,
            "style": "beige_tile",
            "roofType": "flat",
            "signColor": [240, 242, 245],
            "stoneFascia": True,
            "verified": True,
            "note": "pano=_u0lX8s6a07lB-O4yW7p2A, kH1A0n4w5U3_k_H82W9xAA. 3층 베이지 타일 클리닉 빌딩, 강남한의원·좋은치과·방가전 입점 확인.",
        },
        "강남5길 55": {
            "sign": "롯데리아",
            "subSign": "ZUMBA 줌바피트니스",
            "floors": 3,
            "style": "white_stucco",
            "roofType": "flat",
            "signColor": [205, 32, 38],
            "awningColor": [205, 32, 38],
            "stoneFascia": True,
            "verified": True,
            "note": "pano=_u0lX8s6a07lB-O4yW7p2A. VWorld f=1이나 실제 3층 백색 석재/스터코 상가건물, 1층 롯데리아(안동강남점), 상부 ZUMBA 줌바피트니스 확인.",
        },
        "강남5길 54": {
            "sign": "방가전",
            "subSign": "좋은치과 · 강남한의원",
            "floors": 3,
            "style": "gray_stucco",
            "roofType": "flat",
            "signColor": [35, 65, 135],
            "stoneFascia": True,
            "verified": True,
            "note": "pano=kH1A0n4w5U3_k_H82W9xAA. 3층 회색 석재 상가건물, 1층 방가전 및 메디컬 간판 확인.",
        },
        "강남5길 53": {
            "sign": "피·외·한·원",
            "subSign": "피부과 · 외과 · 한방",
            "floors": 3,
            "style": "beige_stone",
            "roofType": "flat",
            "signColor": [242, 242, 245],
            "stoneFascia": True,
            "verified": True,
            "note": "pano=6Q-qpaonQ6bXhEXaNcmE7g, kH1A0n4w5U3_k_H82W9xAA. 본관 3층 베이지 석재 클리닉('피·외·한·원'), 도로변 1층 별관은 '오블라디 BISTRO WINE & PASTA' 확인.",
        },
        "강남5길 49": {
            "sign": "명수전",
            "floors": 3,
            "style": "gray_stucco",
            "roofType": "flat",
            "piloti": True,
            "noSign": True,
            "verified": True,
            "note": "pano=kH1A0n4w5U3_k_H82W9xAA. 3층 회색 스터코 필로티 다가구주택('명수전' 건물 명패).",
        },
        "강남4길 2": {
            "sign": "대변회집",
            "subSign": "자연산 활어회 전문",
            "floors": 2,
            "style": "gray_stucco",
            "roofType": "flat",
            "signColor": [28, 72, 148],
            "verified": True,
            "note": "pano=2RtXEmBuaSyINTORGnbytA. 강남4길 초입 2층 상가건물, 1층 '대변회집' 간판 확인.",
        },
        "강남4길 8": {
            "sign": None,
            "floors": 3,
            "style": "beige_stone",
            "roofType": "flat",
            "noSign": True,
            "verified": True,
            "note": "pano=2RtXEmBuaSyINTORGnbytA. 강남4길 3층 베이지 석재 다가구주택(상가 간판 없음).",
        },
        "vw-219-015332": {
            "sign": None,
            "floors": 1,
            "style": "white_stucco",
            "roofType": "flat",
            "noSign": True,
            "verified": True,
            "note": "강남5길 안쪽 1층 부속 건물(로드뷰 확인, 간판 없음).",
        },
        "vw-221-050512": {
            "sign": "경비실",
            "floors": 1,
            "style": "beige_stone",
            "roofType": "flat",
            "noSign": True,
            "verified": True,
            "note": "현진에버빌1차 단지 입구 경비실 동.",
        },
        "vw-224-047326": {
            "sign": "관리사무소",
            "floors": 1,
            "style": "beige_stone",
            "roofType": "flat",
            "noSign": True,
            "verified": True,
            "note": "현진에버빌1차 단지 내 관리사무소/부속동.",
        },
        "vw-225-014319": {
            "sign": None,
            "floors": 1,
            "style": "beige_stone",
            "roofType": "flat",
            "noSign": True,
            "verified": True,
            "note": "현진에버빌 단지 내 부속동.",
        },
    }

    # 강남5길 53이 VWorldBlocks에 2개(본관 + 도로변 별관 오블라디) 있는지 확인하여 별관 ID 분리
    recs_53 = by_name.get("강남5길 53", [])
    if len(recs_53) >= 2:
        # 도로(남쪽, Z가 더 큰 쪽 또는 면적이 작은 쪽)가 1층 오블라디 별관
        sorted_53 = sorted(recs_53, key=lambda r: r["w"] * r["d"])
        annex = sorted_53[0]
        out[annex["id"]] = {
            "sign": "오블라디",
            "subSign": "BISTRO WINE & PASTA",
            "floors": 1,
            "style": "white_stucco",
            "roofType": "hip_dark",
            "signColor": [28, 30, 34],
            "deck": True,
            "verified": True,
            "note": f"강남5길 53 도로변 1층 별관({annex['id']}): 백색 스터코 및 다크 경사지붕 레스토랑 '오블라디 BISTRO WINE & PASTA'.",
        }
    return out


def format_luau_entry(key: str, d: dict) -> str:
    lines = [f'\t["{key}"] = {{']
    if d.get("sign") is not None:
        s = d["sign"].replace('"', '\\"')
        lines.append(f'\t\tsign = "{s}",')
    if d.get("shopSigns"):
        items = ", ".join(f'"{x.replace(chr(34), chr(92)+chr(34))}"' for x in d["shopSigns"])
        lines.append(f"\t\tshopSigns = {{ {items} }},")
    if d.get("subSign"):
        s = d["subSign"].replace('"', '\\"')
        lines.append(f'\t\tsubSign = "{s}",')
    if d.get("verticalSign"):
        s = d["verticalSign"].replace('"', '\\"').replace("\n", "\\n")
        lines.append(f'\t\tverticalSign = "{s}",')
    if d.get("floors"):
        lines.append(f'\t\tfloors = {int(d["floors"])},')
    if d.get("style"):
        lines.append(f'\t\tstyle = "{d["style"]}",')
    if d.get("roofType"):
        lines.append(f'\t\troofType = "{d["roofType"]}",')
    if d.get("facing"):
        lines.append(f'\t\tfacing = "{d["facing"]}",')
    if d.get("signColor"):
        r, g, b = d["signColor"]
        lines.append(f"\t\tsignColor = Color3.fromRGB({r}, {g}, {b}),")
    if d.get("awningColor"):
        r, g, b = d["awningColor"]
        lines.append(f"\t\tawningColor = Color3.fromRGB({r}, {g}, {b}),")
    for bool_key in ("piloti", "deck", "stoneFascia", "roofSign", "spire", "noSign"):
        if d.get(bool_key):
            lines.append(f"\t\t{bool_key} = true,")
    if d.get("note"):
        n = d["note"].replace('"', '\\"').replace("\n", " ")
        lines.append(f'\t\tnote = "{n}",')
    ver = "true" if d.get("verified", True) else "false"
    lines.append(f"\t\tverified = {ver},")
    lines.append("\t},")
    return "\n".join(lines)


def main() -> None:
    by_name = find_vworld_duplicates()
    merged: dict[str, dict] = {}
    for loader in (load_zone1, load_zone2, load_zone3, load_zone4, load_zone5):
        merged.update(loader())
    merged.update(load_zone6(by_name))

    header = [
        "--!strict",
        "-- 네이버 로드뷰(64개 파노라마 큐브페이스 직교 투영)로 전수 실측 확인한 정하동 상가·건물 팩트 오버레이.",
        "-- 키 = 도로명주소(VWorldBlocks.name) 또는 고유 ID(VWorldBlocks.id), 값 = 실측 팩트.",
        "-- verified = 로드뷰 이미지 및 도로명주소 건물번호판에서 직접 판독한 건물만 true.",
        "--",
        "-- 이 파일은 데이터만 담는다. 적용 로직은 Builder.mergeRoadviewFacts()에서 처리한다.",
        "",
        "local RoadviewShops: { [string]: any } = {",
    ]
    body = [format_luau_entry(k, v) for k, v in merged.items()]
    footer = ["}", "", "return RoadviewShops", ""]

    out_path = os.path.join(ROOT, "src", "shared", "Data", "RoadviewShops.luau")
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(header + body + footer))
    print(f"Wrote {len(merged)} verified entries to {out_path}")


if __name__ == "__main__":
    main()
