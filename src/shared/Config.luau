--!strict
-- 게임 전역 설정. 서버/클라이언트 양쪽에서 require 가능.

local Config = {
	Debug = true,

	-- 플레이어 기본 능력치
	StartingCoins = 0,
	WalkSpeed = 16,
	JumpPower = 50,

	-- 세션 규칙
	MaxPlayersPerServer = 12,
	RespawnDelay = 3,

	-- 리모트 이름 (서버가 생성, 클라이언트가 대기)
	RemoteFolderName = "Remotes",
	GameEventName = "GameEvent",

	-- ── 실측 스케일 ─────────────────────────────────────────
	-- 로블록스 1 stud ≈ 0.28 m
	StudsPerMeter = 3.5714,

	-- 월드 원점: 안동강남초등학교 정문 게이트하우스 실측 (VWorld POI)
	-- +X = 동, +Z = 남, +Y = 위. 모든 좌표는 미터 단위.
	OriginLatLon = { 36.549777, 128.731262 },

	DistrictName = "GangnamDong",
	SchoolDisplayName = "강남초등학교",

	-- 서버 시작 시 데이터에서 지구를 자동 생성할지
	BuildOnStart = true,
	-- 생성된 지구를 담을 Workspace 하위 폴더 이름
	DistrictFolderName = "District",
}

return table.freeze(Config)
