import urllib.request

ids = ["-Aj2qjXVwGptZlOhStAaLA", "DlPs12G8z5Yxtle6UuL7Ug"]
for p in ids:
    url = f"https://panorama.map.naver.com/metadataV3/basic/{p}?lang=ko"
    req = urllib.request.Request(
        url, headers={"User-Agent": "Mozilla/5.0", "Referer": "https://map.naver.com/"}
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            body = r.read().decode("utf-8", "replace")
            log_path = "data/tmp/meta_test.txt"
            with open(log_path, "a", encoding="utf-8") as f:
                f.write(f"OK {p}\n")
    except Exception as e:  # noqa: BLE001
        msg = f"ERR {p}: {e}"
        print(msg, file=__import__("sys").stderr)
        with open("data/tmp/meta_test.txt", "a", encoding="utf-8") as f:
            f.write(msg + "\n")
