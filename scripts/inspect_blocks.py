import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "src/shared/Data/VWorldBlocks.luau"
s = open(path, encoding="utf-8").read()
keys = set(re.findall(r"^\t\t\t(\w+) =", s, re.M))
print("param keys:", sorted(keys))
print("record count:", len(re.findall(r"id = \"vw-", s)))
print("kinds:", sorted(set(re.findall(r'kind = "(\w+)"', s))))
