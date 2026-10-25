"""네이버 로드뷰 파노라마 360도 시트 생성 + 촬영 방위 보정.

  python scripts/pano.py <panoId> --heading 270
  python scripts/pano.py <panoId> --crop 40,70     # 특정 방위 구간 원본 해상도 크롭
  python scripts/pano.py --id=-Aj... --scale 0.5   # '-'로 시작하는 ID

- 메타데이터(camera_angle yaw)로 촬영 방위를 읽어, --heading 방위가 중앙에 오게 감는다.
- 방위 규칙: 0=북, 90=동, 180=남, 270=서.
- 결과: data/tmp/pano_<id>_raw.png / crop_<id>_<h1>_<h2>.png
- 사용 규칙: 확인용 임시 이미지이며 게임 텍스처로 굽지 않는다(Standing Order #7).
"""

import argparse
import io
import json
import os
import sys
import urllib.request

from PIL import Image

UA = {"User-Agent": "Mozilla/5.0", "Referer": "https://map.naver.com/"}
FACES = ["f", "r", "b", "l"]
OUT_DIR = os.path.join("data", "tmp")


def meta(pano: str) -> dict:
    url = f"https://panorama.map.naver.com/metadataV3/basic/{pano}?lang=ko"
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)


def tile(pano: str, face: str, col: int, row: int, size: int = 512):
    url = f"https://panorama.pstatic.net/image/{pano}/{size}/M/{face}/{col}/{row}"
    try:
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=20) as r:
            return Image.open(io.BytesIO(r.read())).convert("RGB")
    except Exception as e:  # noqa: BLE001
        print(f"  ! {face}/{col}/{row} {e}", file=sys.stderr)
        return None


def face_image(pano: str, face: str, size: int = 512) -> Image.Image:
    img = Image.new("RGB", (size * 2, size * 2), (18, 18, 20))
    for row in (1, 2):
        for col in (1, 2):
            t = tile(pano, face, col, row, size)
            if t is not None:
                img.paste(t, ((col - 1) * size, (row - 1) * size))
    return img


def build(pano: str, heading: int | None, size: int, scale: float) -> str:
    info = meta(pano)
    yaw = float(info.get("camera_angle", [0, 0, 0])[1])
    tiles = [face_image(pano, f, size) for f in FACES]
    fw = tiles[0].width
    sheet = Image.new("RGB", (fw * 4, tiles[0].height), (18, 18, 20))
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * fw, 0))

    label = "raw"
    if heading is not None:
        # 파노라마 좌표계 왼쪽 끝 = yaw - 45 (f면의 센터)
        left = (yaw - 45.0) % 360.0
        px = int(((heading - left) % 360.0) / 360.0 * sheet.width)
        offset = (sheet.width // 2 - px) % sheet.width
        rolled = Image.new("RGB", sheet.size, (18, 18, 20))
        rolled.paste(
            sheet.crop((sheet.width - offset, 0, sheet.width, sheet.height)), (0, 0)
        )
        rolled.paste(
            sheet.crop((0, 0, sheet.width - offset, sheet.height)), (offset, 0)
        )
        sheet = rolled
        label = f"h{heading}"

    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, f"pano_{pano}_{label}.png")
    if scale != 1.0:
        sheet = sheet.resize(
            (int(sheet.width * scale), int(sheet.height * scale)), Image.LANCZOS
        )
    sheet.save(path)
    print(f"{path}  yaw={yaw:.1f}  heading={heading}")
    return path


def crop(pano: str, h1: float, h2: float, size: int = 512) -> str:
    """h1..h2 방위 구간을 원본 해상도로 잘라 저장한다 (간판 판독용)."""
    info = meta(pano)
    yaw = float(info.get("camera_angle", [0, 0, 0])[1])
    tiles = [face_image(pano, f, size) for f in FACES]
    fw = tiles[0].width
    sheet = Image.new("RGB", (fw * 4, tiles[0].height), (18, 18, 20))
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * fw, 0))
    left = (yaw - 45.0) % 360.0
    x1 = int(((h1 - left) % 360.0) / 360.0 * sheet.width)
    x2 = int(((h2 - left) % 360.0) / 360.0 * sheet.width)
    if x2 <= x1:
        img = Image.new("RGB", (sheet.width - x1 + x2, sheet.height))
        img.paste(sheet.crop((x1, 0, sheet.width, sheet.height)), (0, 0))
        img.paste(sheet.crop((0, 0, x2, sheet.height)), (sheet.width - x1, 0))
    else:
        img = sheet.crop((x1, 0, x2, sheet.height))
    img = img.crop((0, 0, img.width, int(img.height * 0.72)))
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, f"crop_{pano}_{int(h1)}_{int(h2)}.png")
    img.save(path)
    print(f"{path}  {img.width}x{img.height}")
    return path


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("pano", nargs="?")
    ap.add_argument("--id", help="'-'로 시작하는 파노라마 ID")
    ap.add_argument("--heading", type=int, default=None)
    ap.add_argument("--scale", type=float, default=0.5)
    ap.add_argument("--size", type=int, default=512)
    ap.add_argument("--crop", default=None, help="h1,h2 방위 구간 고해상도 크롭")
    args = ap.parse_args()
    pano = args.pano or args.id
    if args.crop:
        h1, h2 = (float(v) for v in args.crop.split(","))
        crop(pano, h1, h2, args.size)
        return
    build(pano, args.heading, args.size, args.scale)


if __name__ == "__main__":
    main()
