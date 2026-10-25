--!strict
-- 검증 시점(waypoint). 카메라 위치/시선은 미터 단위, 원점 = (36.549777, 128.731262).
-- 네이버 로드뷰 파노라마 실측 GPS 좌표 및 시선(yaw)을 그대로 반영한다:
--   DlPs12G8z5Yxtle6UuL7Ug (정문 정면 서향): X = 114.8, Z = 6.2, yaw = -90° (서쪽 정문·교사동·강남마루·석미한아름 정면 조망)
--   DinCYGB6-nThfrMXe6v1VQ (정문 북동측):    X = 114.3, Z = -2.2, yaw = -130° (서남서 정문·지킴이실·아치캐노피 조망)
--   VCG2y6dRai1s7AOF00qrDg (남측 상가열):    X = 38.2,  Z = 58.0, yaw = -170° (남측 정상태권도 등 상가열 조망)

local Waypoints = {
	{
		id = "wp-gate-front",
		name = "정문 정면 서향 (DlPs12G8z5Yxtle6UuL7Ug, yaw=-90)",
		position = { 114.8, 1.8, 6.2 },
		lookAt = { 45.0, 5.2, 0.5 },
		checklist = { "정문 위치/폭", "교사동 층수", "창문 열 수", "담장 높이" },
	},
	{
		id = "wp-street-left",
		name = "정문 북동측 사선 (DinCYGB6-nThfrMXe6v1VQ, yaw=-130)",
		position = { 114.3, 1.8, -2.2 },
		lookAt = { 85.0, 3.8, 6.0 },
		checklist = {
			"정문 기둥/현판",
			"배움터지킴이실/캐노피",
			"본관/서관 4층",
			"배경 아파트",
		},
	},
	{
		id = "wp-street-south",
		name = "학교 남측 상가열 (VCG2y6dRai1s7AOF00qrDg)",
		position = { 38.2, 1.8, 58.0 },
		lookAt = { 33.5, 4.5, 75.0 },
		checklist = { "상가 층수", "간판 위치", "보도 폭", "황색 중앙선" },
	},
	{
		id = "wp-aerial",
		name = "항공 뷰 (동남측 상공)",
		position = { 165.0, 90.0, 75.0 },
		lookAt = { 48.0, 0.0, -5.0 },
		checklist = { "대지 비율", "운동장 방향", "건물 배치" },
	},
}

return Waypoints
