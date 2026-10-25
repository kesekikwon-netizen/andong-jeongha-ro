---
name: nature-vfx
description: 자연 환경·놀이터·VFX (Roblox Studio 내장 로컬 스킬 동기화본)
---

# 자연 환경·놀이터·VFX

스케일은 real-world-scale(1m=3 studs), 질감은 lighting-atmosphere 스킬과 연계.

## 1. 나무 (최신 기술 기반)
- **이유**: 실사 나무는 studio_generate_mesh로 생성 — "은행나무, 가을 노란 잎, 실사적" / "벚나무, 봄, 개화" 식으로 프롬프트에 한국 수종을 명시.
- 가로수(은행나무, 느티나무)는 실제 식재 위치를 로드뷰에서 확인해 배치 — map-data-pipeline 워크플로 따름.
- 템플릿화: 수종별 2~3개 변형을 만들어 ReplicatedStorage.Templates.Nature에 보관, 클론 배치. 전부 다 만들지 않는다.
- 잎 재질: LeafyGrass 재질 + Seasonal 적용 가능.

## 2. 계절감 (안동 특색)
- 가을 은행나무 노란 잎, 봄 벚꽃, 겨울 설산 — 계절 이벤트 콘텐츠로 확장 가능.
- 계절 전환은 잎 색 Material/Decal 교체 + 파티클 색 변경로.

## 3. 놀이터 (학교/아파트 단지)
- 그네/미끄럼틀/시소: 실규격 확인(그네 좌석 높이 40~60cm, 미끄럼틀 1.5~2m 등) 후 real-world-scale 변환.
- 안전바닥(고무 타일) 질감: 진한 녹색/파랑 주계 타일 재질 재현.
- 놀이터는 아이들 주요 포토존 — 앉기(Seat), 그네 타기(좌우 흔들림 로컬 애니메이션) 같은 상호작용까지 붙이면 리얼리티가 산다.

## 4. VFX (ParticleEmitter 기반)
- **떨어지는 은행잎**: ParticleEmitter, 큰 사각형 텍스처 회전, EmissionDirection 아래, 속도 느리게, Lifetime 4~6초. 가을 코어 거리 필수.
- **낙엽 쌓임**: 바닥에 반투명 Decal 겹겹이 또는 얇은 파트.
- **먼지/꽃가루**: 밝은 낮 풍경에 미세 파티클(Transparency 0.9).
- **비/눈**: 계절 이벤트용. ParticleEmitter + 바람 방향.
- **안개(아침)**: lighting-atmosphere의 Atmosphere Density 애니메이션과 연계.
- 파티클은 예산 관리: 구역당 emitter 수 제한, Rate 값 최소화. 성능 데이터는 city-map-organization에 기록.

## 5. 환경 사운드 (리얼리티 마무리)
- 새소리, 바람, 학교 종소리, 아파트 단지 소음 — Sound를 구역별 앵커로 배치, RollOffMode 설정으로 자연스러운 거리감.

## 6. 원근감 보강 (자연 요소로)
- 먼 곳 배경산(안동 시내 주변 능선): 로우폴리지 멀리 배치 + Atmosphere 헤이즈로 실제 안동 분지 능선 재현. 로드뷰/항공사진 참조.
- DepthOfField는 lighting-atmosphere 스킬 참조.

## 노하우 축적
- 수종별 생성 프롬프트, 파티클 세팅값, 계절 프리셋을 이 스킬에 계속 기록한다.
