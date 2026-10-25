"""Cubic-projection aware Naver roadview sampler.

Naver tiles are 4 cube faces (f,r,b,l) of 1024x1024 each, 90 deg x 90 deg,
so azimuth/pitch map to pixel tangentially.  pano.py assumed a linear
mapping which is off by up to ~35 deg near face edges.

  python scripts/pano2.py <pano> [--strip] [--crop h1,h2] [--scale px_per_deg]
                          [--pitch p1,p2]

bearing convention: 0=N, 90=E, 180=S, 270=W (geographic).
"""

import argparse
import io
import json
import math
import os
import sys
import urllib.request

from PIL import Image

UA = {"User-Agent": "Mozilla/5.0", "Referer": "https://map.naver.com/"}
FACES = ["f", "r", "b", "l"]
OUT = os.path.join("data", "tmp")


def meta(pano: str) -> dict:
    url = f"https://panorama.map.naver.com/metadataV3/basic/{pano}?lang=ko"
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=25) as r:
        return json.load(r)


def tile(pano: str, face: str, col: int, row: int, size: int = 512):
    url = f"https://panorama.pstatic.net/image/{pano}/{size}/M/{face}/{col}/{row}"
    try:
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=25) as r:
            return Image.open(io.BytesIO(r.read())).convert("RGB")
    except Exception as e:  # noqa: BLE001
        print(f"  ! {face}/{col}/{row} {e}", file=sys.stderr)
        return None


def faces_of(pano: str, size: int = 512) -> dict:
    out = {}
    for f in FACES:
        img = Image.new("RGB", (size * 2, size * 2), (18, 18, 20))
        for row in (1, 2):
            for col in (1, 2):
                t = tile(pano, f, col, row, size)
                if t is not None:
                    img.paste(t, ((col - 1) * size, (row - 1) * size))
        out[f] = img
    return out


def face_center(yaw: float, k: int) -> float:
    return (yaw + 90.0 * k) % 360.0


def sample_xy(yaw: float, bearing: float, pitch: float):
    """return (face_index, u, v) in 0..1 face coords for bearing/pitch (deg)."""
    best = None
    for k in range(4):
        th = (bearing - face_center(yaw, k) + 180.0) % 360.0 - 180.0
        if abs(th) <= 45.0001:
            best = (k, th)
            break
    if best is None:
        th = (bearing - yaw + 180.0) % 360.0 - 180.0
        k = int(round(th / 90.0)) % 4
        best = (k, (bearing - face_center(yaw, k) + 180.0) % 360.0 - 180.0)
    k, th = best
    u = 0.5 + 0.5 * math.tan(math.radians(th)) / math.tan(math.radians(45.0))
    v = 0.5 - 0.5 * math.tan(math.radians(pitch)) / math.tan(math.radians(45.0))
    return k, u, v


def render(
    pano: str, h1: float, h2: float, p1: float, p2: float, scale: float, size: int = 512
) -> Image.Image:
    info = meta(pano)
    yaw = float(info.get("camera_angle", [0, 0, 0])[1])
    faces = faces_of(pano, size)
    fw = size * 2
    W = max(1, int(round((h2 - h1) * scale)))
    H = max(1, int(round((p2 - p1) * scale)))
    # work per face to avoid repeated huge resamples: sample into output buffer
    out = Image.new("RGB", (W, H), (20, 20, 22))
    px = out.load()
    # precompute source pixels per output column/row (same for all faces)
    cols = []
    for x in range(W):
        b = h1 + (x + 0.5) / scale
        cols.append(b)
    rows = []
    for y in range(H):
        pt = p2 - (y + 0.5) / scale
        rows.append(pt)
    srcs = {}
    for x, b in enumerate(cols):
        for y, pt in enumerate(rows):
            k, u, v = sample_xy(yaw, b, pt)
            sx = min(fw - 1, max(0, int(u * fw)))
            sy = min(fw - 1, max(0, int(v * fw)))
            srcs[(x, y)] = (k, sx, sy)
    # group by face for speed with numpy-free fallback
    for k in range(4):
        img = faces[FACES[k]].load()
        for (x, y), (kk, sx, sy) in srcs.items():
            if kk == k:
                px[x, y] = img[sx, sy]
    return out, yaw


def save(img: Image.Image, name: str) -> str:
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    img.save(path)
    print(f"{path}  {img.width}x{img.height}")
    return path


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("pano")
    ap.add_argument("--crop", default=None, help="h1,h2 bearings")
    ap.add_argument("--scale", type=float, default=12.0, help="px per degree")
    ap.add_argument("--pitch", default="-22,38")
    a = ap.parse_args()
    p1, p2 = (float(v) for v in a.pitch.split(","))
    if a.crop:
        h1, h2 = (float(v) for v in a.crop.split(","))
        img, yaw = render(a.pano, h1, h2, p1, p2, a.scale)
        save(img, f"v_{a.pano}_{int(h1)}_{int(h2)}.png")
    else:
        img, yaw = render(a.pano, 0.0, 360.0, p1, p2, a.scale / 2.0)
        save(img, f"strip_{a.pano}.png")
    print(f"yaw={yaw:.1f}")


if __name__ == "__main__":
    main()
