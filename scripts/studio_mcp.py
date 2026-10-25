"""StudioMCP.exe stdio MCP 클라이언트 드라이버.

  python scripts/studio_mcp.py tools                 # 도구 목록
  python scripts/studio_mcp.py call <tool> <json>    # 도구 호출
  python scripts/studio_mcp.py list_studios          # 니모닉: list_roblox_studios

- JSON-RPC 2.0 over stdio. initialize -> initialized -> tools/list / tools/call.
- Studio가 꺼져 있으면 list_roblox_studios가 시작을 유도하는지 응답으로 확인한다.
"""

import json
import subprocess
import sys
import threading

EXE = r"C:\Users\권을\AppData\Local\Roblox\Versions\version-7aaa6838d36c4448\StudioMCP.exe"


class Mango:
    def __init__(self) -> None:
        self.proc = subprocess.Popen(
            [EXE, "--stdio"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        self.next_id = 0

    def send(self, method: str, params: dict | None = None, note: str = "") -> int:
        self.next_id += 1
        body = {"jsonrpc": "2.0", "id": self.next_id, "method": method}
        if params is not None:
            body["params"] = params
        if note:
            body["_note"] = note
        line = json.dumps(body, ensure_ascii=False)
        assert self.proc.stdin is not None
        self.proc.stdin.write(line + "\n")
        self.proc.stdin.flush()
        return self.next_id

    def read_response(self, want_id: int, timeout_s: float = 120) -> dict:
        import select
        import time

        # Windows 파이프 select 미지원 -> 라인 단위 스레드 읽기로 진행
        deadline = time.time() + timeout_s
        assert self.proc.stdout is not None
        while time.time() < deadline:
            line = self.proc.stdout.readline()
            if not line:
                time.sleep(0.05)
                continue
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line)
            except json.JSONDecodeError:
                print(f"[nonjson] {line[:200]}", file=sys.stderr)
                continue
            if msg.get("id") == want_id:
                return msg
            if msg.get("method") is not None:
                print(
                    f"[notify] {json.dumps(msg, ensure_ascii=False)[:300]}",
                    file=sys.stderr,
                )
        raise TimeoutError(f"no response for id={want_id}")

    def wait_studio(self, timeout_s: float = 25.0) -> str:
        import time

        deadline = time.time() + timeout_s
        while time.time() < deadline:
            rid = self.send(
                "tools/call",
                {"name": "list_roblox_studios", "arguments": {}},
            )
            reply = self.read_response(rid)
            content = reply.get("result", {}).get("content", [])
            if content:
                try:
                    data = json.loads(content[0].get("text", "{}"))
                    studios = data.get("studios", [])
                    if studios:
                        return studios[0].get("id") or studios[0].get("studio_id", "")
                except Exception:
                    pass
            time.sleep(2.0)
        raise TimeoutError("No Roblox Studio instance connected within timeout")

    def close(self) -> None:
        try:
            self.proc.stdin.close()  # type: ignore[union-attr]
        except Exception:
            pass
        self.proc.terminate()


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        return
    cmd = sys.argv[1]
    cli = Mango()
    rid = cli.send(
        "initialize",
        {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "opencode-driver", "version": "1.0"},
        },
    )
    cli.read_response(rid)
    cli.send("notifications/initialized")

    if cmd == "tools":
        rid = cli.send("tools/list")
        msgs = cli.read_response(rid)
        for t in msgs.get("result", {}).get("tools", []):
            print(f"{t['name']}: {t.get('description', '')[:120]}")
    elif cmd == "skill":
        skill_name = sys.argv[2]
        sid = cli.wait_studio()
        rid = cli.send(
            "tools/call",
            {"name": "skill", "arguments": {"skill_name": skill_name, "studio_id": sid}},
        )
        reply = cli.read_response(rid)
        content = reply.get("result", {}).get("content", [])
        if content:
            print(content[0].get("text", ""))
        else:
            print(json.dumps(reply, ensure_ascii=False)[:8000])
    elif cmd == "call":
        tool = sys.argv[2]
        args = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
        if tool != "list_roblox_studios" and (not args.get("studio_id") or args.get("studio_id") == "auto"):
            args["studio_id"] = cli.wait_studio()
        rid = cli.send("tools/call", {"name": tool, "arguments": args})
        reply = cli.read_response(rid)
        print(json.dumps(reply, ensure_ascii=False)[:8000])
    elif cmd == "list_studios":
        sid = cli.wait_studio()
        rid = cli.send(
            "tools/call",
            {"name": "list_roblox_studios", "arguments": {}},
        )
        print(json.dumps(cli.read_response(rid), ensure_ascii=False)[:4000])
    cli.close()


if __name__ == "__main__":
    main()
