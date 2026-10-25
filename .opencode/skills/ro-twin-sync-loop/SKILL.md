---
name: ro-twin-sync-loop
description: 장면 단위 동기화 루프. waypoint 선정부터 캡처, 채점, 수정, 재촬영, 회귀검사까지.
---

# ro-twin-sync-loop

한 장면이 끝나야 다음 장면으로 간다. 건너뛰기 금지.

## 1회전 절차

1. `src/shared/Data/Waypoints.luau`에서 다음 waypoint를 고른다.
2. Studio 확인: `roblox_studio.list_roblox_studios` → studio_id 확보.
3. 빌드: `roblox_studio.execute_luau` (Edit)로 Builder.build() + stats 보고.
4. 캡처: `roblox_studio.screen_capture`에 waypoint의 position/look_at 입력.
   (단위 변환: waypoint 미터 → 스튜디오 스터드 ×3.5714)
5. 로드뷰 대조: `ro-twin-streetview` 절차로 같은 방향 파노라마를 열어 비교.
6. 채점: waypoint.checklist 항목별 O/X, 1개라도 X면 수정 후 3번으로.
7. 회귀: 이전 waypoint 전체 재촬영, 점수 하락이 있으면 이번 수정 롤백.
8. 해당 블록 `verified=true`로 변경 (근거: panoId + 날짜).
9. 사이클 분량이 다 모이면 사용자 검토를 받고, 지적 사항을 issues에 등록한 뒤 다음으로 간다. 검토 없이 다음 사이클로 넘어가지 않는다 (무한루프).

## 종료 조건

- 전 waypoint 95% + 랜드마크 100% + 회귀 0건. 그 전까지 멈추지 않는다.

## MCP 도구 선택 및 반복 실수 방지 체크리스트 (2026-10-24 승격)

- Studio 직접 조작: `conduit` (`execute_lua`, `explore`, `create`, `edit_script`, `playtest`).
- **Luau `require()` 캐시 우회**: `ModuleScript.Source`만 수정하면 기존 캐시가 반환된다. 반드시 `ModuleScript` 인스턴스를 재생성(`Destroy` → `Instance.new("ModuleScript")`)한 뒤 `require`한다.
- **Studio 창 캡처 규칙**: `HWND`가 재할당될 수 있으므로 매 캡처마다 `EnumWindows`로 `Roblox Studio` 핸들을 새로 찾고, `ShowWindow(9)` 복원 후 `PrintWindow(hwnd, hdc, 2)`로 캡처한다.
- **파노라마 실측 GPS 검증**: 정문/도로 방향을 추정하지 말고 `https://panorama.map.naver.com/metadataV3/basic/<panoId>?lang=ko`의 `latitude`/`longitude`를 미터 좌표로 변환해 대조한다 (`DinCYGB6-nThfrMXe6v1VQ` = `X:114.3, Z:-2.2`, 동측 강남1길 정문).
- **도시 격자 회전각**: 안동강남초 일대 도로·건물 격자는 `rotationY = +6.5°` 회전되어 있으며, 최소외접사각형 각도 정규화는 반드시 `((ang + 90) % 180) - 90`을 사용한다 (`+180` 사용 시 90° 오차 발생).
- **SurfaceGui 양면 부착**: `Geometry.sign`은 회전 방향에 관계없이 텍스트가 보이도록 `Front`와 `Back` 양면에 `SurfaceGui`를 부착한다.
