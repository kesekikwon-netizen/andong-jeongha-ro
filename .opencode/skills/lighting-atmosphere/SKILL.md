---
name: lighting-atmosphere
description: 조명·원근감·후처리 (리얼리티 비주얼 시스템) (Roblox Studio 내장 로컬 스킬 동기화본)
---

# 조명·원근감·후처리 (리얼리티 비주얼 시스템)

이 스킬은 안동 실측 맵의 "보는 느낌"을 책임진다. 최신 로블록스 렌더링 기술 기준.

## 1. 조명 기술 스택
- **Lighting.Technology = Future**: 그림자 품질이 가장 높다. 실사 재현 프로젝트는 Future를 기본으로 한다. 성능 부담이 크면 GlobalShadows와 ShadowMap 조합으로 조정.
- **Lighting.EnvironmentSpecularScale / DiffuseScale**: 건물 유리창, 아스팔트 반사 표현에 필수.
- 실외 그림자: GlobalShadows = true. 실내(교실, 편의점)는 별도 조명 배치로 밝기를 확보.

## 2. Atmosphere (원근감의 핵심)
- Lighting에 Atmosphere 인스턴스 추가. 원근감(에어리얼 퍼스펙티브)은 거리감을 결정한다.
- 권장 시작값: Density 0.35, Offset 0.25, Color 옅은 하늘색, Decay 따뜻한 회색.
- 안동은 분지 지형이라 아침 저녁 안개가 잦다 — Density를 시간대별로 조절하면 실제 지역 특성까지 재현된다.
- Haze/Glare로 태양 주변 산란 표현.

## 3. 후처리 이펙트 (Lighting 자식으로)
- **BloomEffect**: Intensity 0.4~0.6, 네온 간판/야간 가로등 발광에 필수. Threshold 0.9 이상으로 밝은 곳만 번지게.
- **SunRaysEffect**: Intensity 0.1~0.2, 낮 풍경에 사실감.
- **DepthOfFieldEffect**: 원근감 강조용. FarIntensity 0.1~0.3, FocusRadius 넉넉히 — 과하면 어지럽다. 멀리 아파트 단지가 뿌옇게 밀리는 효과로 깊이를 준다.
- **ColorCorrectionEffect**: 계절/시간대 색보정. 새벽은 파란 톤, 오후는 따뜻한 톤, 노을은 Saturation + TintColor 주황.
- 과한 후처리는 리얼리티를 해친다. 한 번에 하나씩만 켜고 비교하며 조정한다.

## 4. 시간대 시스템 (런타임)
- 낮/노을/밤 프리셋을 ModuleScript로 만들고, ClockTime을 서버에서 서서히 진행.
- 밤: 가로등(SpotLight), 간판 발광(Neon 재질 + Bloom), 아파트 창문 조명(랜덤하게 켜진 세대 표현)이 핵심 볼거리.
- 프리셋 전환은 값 보간(Lerp)으로 부드럽게 — 갑작스러운 색 변화 금지.

## 5. 건물 질감 (광도/재질)
- 최신 재질 시스템: BasePart.Material에 PBR 재질 지원(Concrete, Brick, Slate, Asphalt 등). 구역별 재질 통일은 city-map-organization 규칙 따름.
- 특별한 질감이 필요하면 studio_generate_material로 MaterialVariant 생성 — 예: "낡은 회색 아파트 외벽", "한국 인도 블록". 생성 후 BaseMaterial + MaterialVariant 속성을 파트에 설정.
- 유리창: Reflectance + EnvironmentSpecularScale로 실제 반사감. 아파트 창은 MeshPart + SurfaceGui(창문 프레임) 조합.
- generate_texture 스킬 참조: 참조 이미지 기반 재질 생성.

## 6. 검증
- 조명 세팅 변경 후에는 반드시 실제 화면(스크린샷/플레이)으로 확인. 수치만 보고 판단하지 않는다.
- 낮/노을/밤 세 시간대 전부 스크린샷을 남겨 비교 기록으로 축적한다.

## 노하우 축적
- 계절 프리셋(봄~겨울), 조정된 후처리 수치, MaterialVariant 목록을 이 스킬에 계속 기록한다.
