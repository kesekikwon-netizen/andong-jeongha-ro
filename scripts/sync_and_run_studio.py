"""디스크의 최신 Luau 모듈을 Roblox Studio에 동기화하고(require 캐시 무효화 포함),
Builder.build()를 즉시 실행하여 정하동 디지털 트윈을 빌드한다.
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts"))
import studio_mcp  # noqa: E402


def luau_long_string(s: str) -> str:
    eq = "=" * 4
    while f"]{eq}]" in s:
        eq += "="
    return f"[{eq}[\n{s}]{eq}]"


def main() -> None:
    files = {
        "Data.RoadviewShops": os.path.join(ROOT, "src", "shared", "Data", "RoadviewShops.luau"),
        "Build.Kits.Shophouse": os.path.join(ROOT, "src", "shared", "Build", "Kits", "Shophouse.luau"),
        "Build.Builder": os.path.join(ROOT, "src", "shared", "Build", "Builder.luau"),
    }

    updates = []
    for dot_path, disk_path in files.items():
        code = open(disk_path, encoding="utf-8").read()
        parts = dot_path.split(".")
        chain = " game.ReplicatedStorage.Shared"
        for p in parts:
            chain += f":FindFirstChild({json.dumps(p)})"
        updates.append(f"do local m ={chain}; if m then m.Source = {luau_long_string(code)} end end")

    luau_code = "\n".join(updates) + """
-- Bust Studio Edit-mode require() cache by cloning Shared ModuleScripts
local Shared = game.ReplicatedStorage:FindFirstChild("Shared")
for _, desc in ipairs(Shared:GetDescendants()) do
    if desc:IsA("ModuleScript") then
        local c = desc:Clone()
        c.Parent = desc.Parent
        desc:Destroy()
    end
end

local Builder = require(Shared.Build.Builder)
Builder.build()
local st = Builder.stats()
local HttpService = game:GetService("HttpService")
return HttpService:JSONEncode(st)
"""
    cli = studio_mcp.Mango()
    try:
        rid = cli.send(
            "initialize",
            {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "sync-runner", "version": "1.0"},
            },
        )
        cli.read_response(rid)
        cli.send("notifications/initialized")
        sid = cli.wait_studio()

        # Stop play mode if currently running so Edit datamodel is updated persistently
        rid_mode = cli.send(
            "tools/call",
            {"name": "get_studio_mode", "arguments": {"studio_id": sid}},
        )
        mode_res = cli.read_response(rid_mode, timeout_s=15.0)
        mode_txt = json.dumps(mode_res)
        if "start_play" in mode_txt or "run_server" in mode_txt or '"stop"' not in mode_txt:
            rid_stop = cli.send(
                "tools/call",
                {"name": "start_stop_play", "arguments": {"studio_id": sid, "is_start": False}},
            )
            cli.read_response(rid_stop, timeout_s=30.0)
            import time

            time.sleep(2.0)

        rid = cli.send(
            "tools/call",
            {
                "name": "execute_luau",
                "arguments": {
                    "studio_id": sid,
                    "datamodel_type": "Edit",
                    "code": luau_code,
                },
            },
        )
        res = cli.read_response(rid, timeout_s=60.0)
        print(json.dumps(res, ensure_ascii=False, indent=2))

        # Aim camera at 강남1길 88-3..88-21 (남담장 건너편 골목 + 안동강남교회 첨탑) and capture
        cam_code = """
local spm = 3.571428
workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
workspace.CurrentCamera.FieldOfView = 65
workspace.CurrentCamera.CFrame = CFrame.lookAt(
    Vector3.new(25 * spm, 16 * spm, 12 * spm),
    Vector3.new(25 * spm, 6 * spm, 48 * spm)
)
return "cam_set"
"""
        rid2 = cli.send(
            "tools/call",
            {
                "name": "execute_luau",
                "arguments": {"studio_id": sid, "datamodel_type": "Edit", "code": cam_code},
            },
        )
        cli.read_response(rid2, timeout_s=30.0)

        rid3 = cli.send(
            "tools/call",
            {
                "name": "screen_capture",
                "arguments": {"studio_id": sid, "datamodel_type": "Edit"},
            },
        )
        cap_res = cli.read_response(rid3, timeout_s=30.0)
        for item in cap_res.get("result", {}).get("content", []):
            if item.get("type") == "image" and item.get("data"):
                import base64

                out_img = os.path.join(ROOT, "data", "captures", "verify_south88_live.png")
                os.makedirs(os.path.dirname(out_img), exist_ok=True)
                with open(out_img, "wb") as f:
                    f.write(base64.b64decode(item["data"]))
                print(f"Saved screenshot to {out_img}")

        # Aim camera at 강남1길 동측 상가열 (정문 맞은편) and capture
        cam_code2 = """
local spm = 3.571428
workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
workspace.CurrentCamera.FieldOfView = 65
workspace.CurrentCamera.CFrame = CFrame.lookAt(
    Vector3.new(92 * spm, 14 * spm, -10 * spm),
    Vector3.new(128 * spm, 6 * spm, -12 * spm)
)
return "cam_set_2"
"""
        rid4 = cli.send(
            "tools/call",
            {
                "name": "execute_luau",
                "arguments": {"studio_id": sid, "datamodel_type": "Edit", "code": cam_code2},
            },
        )
        cli.read_response(rid4, timeout_s=30.0)

        rid5 = cli.send(
            "tools/call",
            {
                "name": "screen_capture",
                "arguments": {"studio_id": sid, "datamodel_type": "Edit"},
            },
        )
        cap_res2 = cli.read_response(rid5, timeout_s=30.0)
        for item in cap_res2.get("result", {}).get("content", []):
            if item.get("type") == "image" and item.get("data"):
                import base64

                out_img2 = os.path.join(ROOT, "data", "captures", "verify_gangnam1gil_live.png")
                with open(out_img2, "wb") as f:
                    f.write(base64.b64decode(item["data"]))
                print(f"Saved screenshot to {out_img2}")

        # Start play mode so the user can immediately explore the updated world
        rid_play = cli.send(
            "tools/call",
            {"name": "start_stop_play", "arguments": {"studio_id": sid, "is_start": True}},
        )
        play_res = cli.read_response(rid_play, timeout_s=45.0)
        print("Play mode:", json.dumps(play_res, ensure_ascii=False))
    finally:
        cli.close()


if __name__ == "__main__":
    main()
