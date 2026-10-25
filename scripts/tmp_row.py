import re

text = open("src/shared/Data/VWorldBlocks.luau", encoding="utf-8").read()
rows = []
for m in re.finditer(r'\{\s*id = "([^"]+)",(.*?)\n\t\},', text, re.S):
    rid, body = m.groups()
    name = re.search(r'name = "([^"]*)"', body)
    ox = re.search(r"offsetX = (-?[\d.]+)", body)
    oz = re.search(r"offsetZ = (-?[\d.]+)", body)
    w = re.search(r"width = (-?[\d.]+)", body)
    d = re.search(r"depth = (-?[\d.]+)", body)
    f = re.search(r"floors = (-?[\d.]+)", body)
    if name and ox:
        rows.append(
            (
                name.group(1),
                float(ox.group(1)),
                float(oz.group(1)),
                float(w.group(1)) if w else 0,
                float(d.group(1)) if d else 0,
                float(f.group(1)) if f else 0,
            )
        )
rows.sort(key=lambda r: (r[2], r[1]))
out = []
for r in rows:
    if 95 < r[1] < 220 and -80 < r[2] < 100:
        out.append(
            f"{r[0]:<16} x={r[1]:7.1f} z={r[2]:7.1f} w={r[3]:5.1f} d={r[4]:5.1f} f={r[5]:.0f}"
        )
open("data/tmp/row_east.txt", "w", encoding="utf-8").write("\n".join(out))
print(len(out))
