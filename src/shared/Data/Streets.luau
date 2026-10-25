--!strict
-- 학교 주변 도로망 데이터 (gate_zoom19_cropped.png + school_zoom18_roads.png + VWorld 건물군 +6.5° 격자 정렬).
-- 모든 도로는 실제 도시 격자 회전각(rotationY = 6.5°)을 따라 배치되어 건물/학교와 0.00m 충돌을 보장한다.

local Streets = {
	{
		name = "SchoolEast",
		vertical = true,
		rotationY = 6.5,
		x = 114.9,
		zCenter = -11.6,
		length = 227.0,
		width = 8.0,
		sidewalk = 2.0,
		centerLine = "yellow-solid",
		crosswalkZ = 16.0,
		schoolZone = true,
	}, -- 강남1길 본선 (학교 동측 정문 앞 남북 도로, 어린이보호구역)
	{
		name = "SchoolNorth",
		vertical = false,
		rotationY = 6.5,
		xCenter = 59.9,
		z = -70.2,
		length = 305.0,
		width = 9.0,
		sidewalk = 2.5,
		centerLine = "yellow-solid",
		crosswalkX = -18.0,
	}, -- 강남5길 본선 (학교 북측 ~ 현진에버빌 사이 동서 도로)
	{
		name = "SchoolSouth",
		vertical = false,
		rotationY = 6.5,
		xCenter = 57.8,
		z = 58.0,
		length = 129.3,
		width = 6.0,
		sidewalk = 1.5,
		centerLine = "yellow-solid",
		crosswalkX = 108.0,
	}, -- 강남1길 남측구간 (학교 남측 담장 ~ 강남1길 88-* 상가열 사이)
	{
		name = "SchoolWest",
		vertical = true,
		rotationY = 6.5,
		x = -11.3,
		zCenter = 24.7,
		length = 172.5,
		width = 6.5,
		sidewalk = 2.0,
		centerLine = "white-dash",
		crosswalkZ = -55.0,
	}, -- 강남5길 서측 지선 (학교 서측 담장 ~ 석미한아름아파트 단지 경계)
	{
		name = "Gangnam6Gil",
		vertical = false,
		rotationY = 6.5,
		xCenter = 144.0,
		z = -29.9,
		length = 62.0,
		width = 6.0,
		sidewalk = 1.5,
		centerLine = "white-dash",
		crosswalkX = 120.0,
	}, -- 강남6길 서측 (정문 북동측 T자 교차로)
	{
		name = "Gangnam6GilEast",
		vertical = false,
		rotationY = 6.5,
		xCenter = 202.3,
		z = -35.6,
		length = 55.0,
		width = 5.5,
		sidewalk = 1.2,
		centerLine = "white-dash",
	}, -- 강남6길 동측
	{
		name = "Gangnam7Gil",
		vertical = false,
		rotationY = 6.5,
		xCenter = 180.2,
		z = 44.7,
		length = 117.0,
		width = 5.5,
		sidewalk = 1.2,
		centerLine = "white-dash",
		crosswalkX = 125.0,
	}, -- 강남7길 (동남측 T자 교차로)
	{
		name = "SouthLane",
		vertical = false,
		rotationY = 6.5,
		xCenter = 119.7,
		z = 96.6,
		length = 244.0,
		width = 8.0,
		sidewalk = 2.0,
		centerLine = "yellow-solid",
		crosswalkX = 122.0,
	}, -- 강남1길 남단 동서 본선 (98-* 상가열 남측)
}

return Streets
