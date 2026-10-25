---
name: rojo-project-workflow
description: Rojo 기반 프로젝트 워크플로 (Roblox Studio 내장 로컬 스킬 동기화본)
---

# Rojo 기반 프로젝트 워크플로

## 역할 분담 원칙
- **Rojo(파일) 관리 대상**: 모든 Script / LocalScript / ModuleScript 소스코드. VS Code 등 외부 편집기 + Git으로 관리한다.
- **Studio 관리 대상**: 지오메트리(파트, 건물, 지형), 인스턴스 배치. Rojo 동기화 폴더 밖의 영역.
- 스크립트는 Studio에서 직접 편집하지 않는다(동기화 충돌 방지). 스크립트 수정이 필요하면 Rojo 쪽에서.

## 폴더 매핑
- src/ 안을 게임 구조와 일치시킨다: ServerScriptService, StarterPlayerScripts, ReplicatedStorage.Modules 등.
- 도시 맵 폴더 구조는 city-map-organization 스킬 기준을 따르고, Rojo 설정 파일의 $path 매핑과 일치시킨다.

## Git 버전 관리
- 커밋 단위는 "구역 + 작업" (예: "강남초주변: 교실 내부 스크립트 추가").
- 구역별 브랜치 전략: 큰 구역 작업은 브랜치에서 진행 후 병합.
- .rbxl/.rbxm 바이너리도 커밋하되 용량 주의. 주요 이정마다 백업.

## 주의
- Rojo 2-way sync 사용 시 Studio와 파일을 동시에 편집하면 변경사항이 유실될 수 있다. 한쪽만 편집하는 규칙을 지킨다.
- MCP로 스크립트를 수정할 때는 studio_multi_edit을 쓰는데, 이후 Rojo 동기화로 변경이 파일로 내려가는지 반드시 확인한다.

## 노하우 축적
- 동기화 충돌 해결법, 설정 파일 개선 사항 등을 이 스킬에 기록한다.
