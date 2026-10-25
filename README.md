# ro — Roblox 프로젝트

Rojo 기반 Roblox 게임 프로젝트입니다. 코드는 전부 `src/`에서 관리하고, Studio는 `rojo serve`로 연결해서 사용합니다.

## 구조

```
src/
  shared/    → ReplicatedStorage.Shared   (서버/클라이언트 공용)
  server/    → ServerScriptService.Server (서버 로직)
  client/    → StarterPlayer.StarterPlayerScripts.Client (클라이언트)
```

- `src/server/init.server.luau` — 서버 진입점 (리모트 생성, leaderstats, 요청 검증)
- `src/client/init.client.luau` — 클라이언트 진입점 (HUD, 핑 예시)
- `src/shared/Config.luau` — 게임 설정값 (여기서 수치 조정)
- `src/shared/Util.luau` — 공용 헬퍼

## 명령어

| 작업 | 명령 |
| --- | --- |
| Studio와 실시간 동기화 | `rojo serve` |
| 검증용 place 파일 빌드 | `rojo build -o build.rbxl` |
| 코드 스타일 검사 | `stylua --check src` (자동 수정: `stylua src`) |
| 린트 | `selene src` |

## 작업 순서

1. 터미널에서 `rojo serve` 실행 (현재 34872 포트에서 실행 중)
2. Studio → Rojo 플러그인 → **Connect**
3. 코드 수정 → 저장하면 Studio에 즉시 반영
4. 테스트는 Studio에서 F5 (Output 창 열어두기)

## Studio MCP (AI가 Studio 직접 조작)

Studio → 어시스턴트 → `…` → Manage MCP Servers → **Enable Studio as MCP server** 켜기.
OpenCode는 `%USERPROFILE%\.config\opencode\opencode.json`의 `roblox_studio` 항목으로 연결됩니다.

> 참고: `%LOCALAPPDATA%\Roblox\mcp.bat`이 LF 줄바꿈으로 생성되어 cmd에서 깨지는 문제가 있어 CRLF로 고쳐 두었습니다. Studio 업데이트 후 MCP 연결이 안 되면 같은 증상일 수 있습니다.
