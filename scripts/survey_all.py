"""정하동 전체 로드뷰 파노라마 사전 생성 (360 시트 + 건물 방위표).

python scripts/survey_all.py            # 전체
python scripts/survey_all.py east south # 일부 그룹만
"""

import json
import os
import subprocess
import sys

GROUPS = {
    "east": [
        "2RtXEmBuaSyINTORGnbytA",
        "DyGVLZoE4i_hn4h38-an4w",
        "zGy9evfvuWonMrAt8jNX_A",
        "6je_Y4hRJMGPjlwLWy5AuQ",
        "wumDEtUx12CIbo32Xn7H3A",
        "DinCYGB6-nThfrMXe6v1VQ",
        "DlPs12G8z5Yxtle6UuL7Ug",
        "sDS3Ow-5GpP-TmD8DvsqKw",
        "8GdGWgbvT79AbXTuYFrr7Q",
        "LD1vScgY-ezLmT9x-aSr4Q",
        "FESMqRpjPyiyCel0HgiyMA",
        "1P6kfO7W7K6uhMhmUMUHYg",
        "XlbOlouBqH0pfSMcaxCt6w",
    ],
    "gangnam6": [
        "zPViYf8O2MwZNvWI_shuHQ",
        "uYR8pHk9XY0XxILqXQyU7A",
        "pG_qawmwjfvNSnwbXrtjHg",
        "6Q-qpaonQ6bXhEXaNcmE7g",
        "_a4KugCZC_w-n_CsbJdBBA",
    ],
    "south": [
        "gFc8Lgw7EMden9fCdcD84Q",
        "-Aj2qjXVwGptZlOhStAaLA",
        "XoYkicII4wcNB8DTvJdFlQ",
        "aenQa7KYTEHx92uuJuKlng",
        "zn1ZhoKTfUaHnY5L9uXFlA",
        "52XdOqFa9bE3uwUpZdqLKA",
        "yDqQ_Cx5cXv0fg2w1pDjzQ",
        "RwwcZV4E0rhJyZpxlEQnIQ",
        "VCG2y6dRai1s7AOF00qrDg",
        "Y84GSjxwzHCSl3XAQSAEKA",
        "VTTPpo6yZIk_p2HFNOuj5g",
        "DO5d25wAVmXyeMzpfUQN5g",
    ],
    "lane98": [
        "8_KJij7FoS6VvEVm-OBGMg",
        "VHmreWk2n-4mZaZFNnBRSA",
        "2GW9abIQ4N6FSSaePDSX8w",
        "Rij2cWDn42U2haFZvCsv7A",
        "22q12Us2S2iKWlTOKwvOhQ",
        "NUzcnzak0iW0KRYVvLK_DA",
        "gejxTprBCAAg5J91_MtEQw",
        "skADvkxtzTbKG5zMXvQkjQ",
        "M42_EaujaIY00QvUDmpemQ",
        "taAruVMXFkuag4SLAYzZGw",
        "ZVxqtR9LvzxU5f5WfEnUoA",
        "4vEJuplKRc9DwUOWsk2-jg",
    ],
    "north": [
        "me4anOI_Y0B4LM_LQC3fuA",
        "vlDpYsDz18QNdoZOKnL3aw",
        "gjzfXNv9_pVhomnSkidtJA",
        "gwiEw2U2EhGJDgBMoUbXtQ",
        "Ux2QaJ30x5dLS3dJQODFVw",
        "CHpGuG01wngybMTBD02JPQ",
        "q0QIdQTUsGs1UZ1o_4ProQ",
        "RYMucZX-fuGcxonFfTqwsw",
        "2z304DNrKnojgUljfIXxXQ",
        "NtLzmEwhg366xuHFdAnhyA",
    ],
    "west": [
        "6-nTApHXmxqd9GJaDgZGPQ",
        "ufD-6_QZUzNgOZsC9aG6qQ",
        "nXSWArdKYhVfhzBs0qSyxQ",
        "2ceZJRhQHx23XdUA5XF-kQ",
        "2UkZjxxr9L7LW7hvB5IkpA",
        "rTGrIulIFHXdykZslTP55A",
        "Mhqn7rlehv-pTSc3xmihjQ",
        "F56ORNkPRY89yQkvWwErLA",
        "t7Ua4gf2FZ211z2aIK7U8g",
    ],
    "gil7": [
        "Vv_VtY2uJfSF7OFZ_QLQ6Q",
        "ySlU4uALP7rImIRHsYjK0A",
        "r8ncqUJAXMtCsJc3Fc8Epw",
    ],
}


def main() -> None:
    groups = sys.argv[1:] or list(GROUPS)
    idx_path = os.path.join("data", "observations", "pano_index.json")
    index = {}
    if os.path.exists(idx_path):
        with open(idx_path, encoding="utf-8") as f:
            index = json.load(f)

    for g in groups:
        for pano in GROUPS.get(g, []):
            print(f"[{g}] {pano}", flush=True)
            try:
                out = subprocess.run(
                    [sys.executable, "scripts/pano.py", pano, "--scale", "0.5"],
                    capture_output=True,
                    text=True,
                    check=False,
                )
                sheet = out.stdout.strip().splitlines()[0] if out.stdout.strip() else ""
                tbl = subprocess.run(
                    [
                        sys.executable,
                        "scripts/zone.py",
                        pano,
                        "--radius",
                        "60",
                        "--limit",
                        "30",
                        "--out",
                        f"data/tmp/zone_{pano}.txt",
                    ],
                    capture_output=True,
                    text=True,
                    check=False,
                )
                index[pano] = {"group": g, "sheet": sheet, "table": tbl.stdout.strip()}
            except Exception as e:  # noqa: BLE001
                print(f"  ! {e}", flush=True)
                index[pano] = {"group": g, "error": str(e)}

    with open(idx_path, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=2)
    print(f"index -> {idx_path}")


if __name__ == "__main__":
    main()
