--!strict
-- 학교 키트: ㄱ자 교사동(본관 북동+서관) / 병설유치원·체육관 / 운동장·스탠드 / 담장 / 서측 정문.
-- 좌표계: 원점 = 정문 인근(36.549777, 128.731262), +X = 동, +Z = 남, -Z = 북. 단위 m.
-- 실측 근거: VWorld 강남1길 78 폴리곤 6개 + gate_zoom19.png + 로드뷰(DinCYGB6-nThfrMXe6v1VQ).

local Geometry = require(script.Parent.Parent.Geometry)

local School = {}

local COLORS = {
	concrete = Color3.fromRGB(214, 210, 199),
	concreteDark = Color3.fromRGB(168, 165, 158),
	window = Color3.fromRGB(108, 146, 168),
	roof = Color3.fromRGB(106, 110, 116),
	fenceBase = Color3.fromRGB(156, 154, 148),
	fence = Color3.fromRGB(242, 242, 238),
	fenceCap = Color3.fromRGB(58, 122, 74),
	sand = Color3.fromRGB(204, 184, 148),
	grass = Color3.fromRGB(88, 142, 78),
	line = Color3.fromRGB(244, 244, 240),
	gate = Color3.fromRGB(198, 202, 208),
	gateStone = Color3.fromRGB(148, 146, 140),
	signBg = Color3.fromRGB(24, 24, 26),
	brick = Color3.fromRGB(154, 88, 72),
	trimWhite = Color3.fromRGB(238, 236, 230),
	canopyRoof = Color3.fromRGB(228, 124, 46),
	canopyFrame = Color3.fromRGB(118, 56, 42),
	shelterRoof = Color3.fromRGB(48, 88, 138),
	guardBox = Color3.fromRGB(240, 214, 118),
	guardGreen = Color3.fromRGB(38, 82, 54),
	shadeGreen = Color3.fromRGB(64, 136, 86),
	tentBlue = Color3.fromRGB(44, 114, 198),
	goalBlue = Color3.fromRGB(36, 88, 176),
	kinderYellow = Color3.fromRGB(238, 192, 58),
	kinderRed = Color3.fromRGB(218, 86, 72),
	annexLight = Color3.fromRGB(230, 232, 234),
	annexTerracotta = Color3.fromRGB(202, 98, 54),
	noticeBrown = Color3.fromRGB(76, 54, 46),
	solarDark = Color3.fromRGB(28, 38, 54),
	silverMetal = Color3.fromRGB(206, 210, 216),
}

type Building = {
	offsetX: number,
	offsetZ: number,
	width: number,
	depth: number,
	floors: number,
	floorHeight: number,
	columns: number,
	name: string,
	vertical: boolean?,
	brickTrim: boolean?,
}

local function buildBody(parent: Instance, b: Building, color: Color3, windowColor: Color3)
	local height = b.floors * b.floorHeight
	local isVert = b.vertical == true

	Geometry.box({
		name = b.name,
		size = Vector3.new(b.width, height, b.depth),
		position = Vector3.new(b.offsetX, height / 2, b.offsetZ),
		color = color,
		parent = parent,
		material = if b.brickTrim then Enum.Material.Brick else Enum.Material.Concrete,
	})

	-- 층간 백색 수평 띠 (로드뷰 관측: 적벽돌 교사동의 백색 슬래브/창대 띠)
	if b.brickTrim then
		for f = 1, b.floors do
			local bandY = (f - 1) * b.floorHeight + 0.85
			Geometry.box({
				name = string.format("%s_band_%d", b.name, f),
				size = Vector3.new(b.width + 0.14, 0.32, b.depth + 0.14),
				position = Vector3.new(b.offsetX, bandY, b.offsetZ),
				color = COLORS.trimWhite,
				parent = parent,
				material = Enum.Material.Concrete,
			})
		end
	end

	if isVert then
		for _, facing in { "west", "east" } do
			local fx = if facing == "east" then b.offsetX + b.width / 2 else b.offsetX - b.width / 2
			Geometry.windowGrid(parent, {
				name = b.name .. "_" .. facing,
				centerX = b.offsetX,
				fz = b.offsetZ,
				centerZ = b.offsetZ,
				fx = fx,
				facing = facing :: any,
				width = b.depth,
				floors = b.floors,
				floorHeight = b.floorHeight,
				baseY = 0,
				columns = b.columns,
				windowWidth = 2.6,
				windowHeight = 1.8,
				color = windowColor,
			})
		end
	else
		for _, facing in { "south", "north" } do
			local fz = if facing == "south"
				then b.offsetZ + b.depth / 2
				else b.offsetZ - b.depth / 2
			Geometry.windowGrid(parent, {
				name = b.name .. "_" .. facing,
				centerX = b.offsetX,
				fz = fz,
				facing = facing :: any,
				width = b.width,
				floors = b.floors,
				floorHeight = b.floorHeight,
				baseY = 0,
				columns = b.columns,
				windowWidth = 2.6,
				windowHeight = 1.8,
				color = windowColor,
			})
		end
	end

	-- 옥상 파라펫
	local top = height
	local parapet = 0.9
	for _, edge in
		{
			{ size = Vector3.new(b.width, parapet, 0.3), off = Vector3.new(0, 0, b.depth / 2) },
			{ size = Vector3.new(b.width, parapet, 0.3), off = Vector3.new(0, 0, -b.depth / 2) },
			{ size = Vector3.new(0.3, parapet, b.depth), off = Vector3.new(b.width / 2, 0, 0) },
			{ size = Vector3.new(0.3, parapet, b.depth), off = Vector3.new(-b.width / 2, 0, 0) },
		}
	do
		Geometry.box({
			name = b.name .. "_parapet",
			size = edge.size,
			position = Vector3.new(b.offsetX, top + parapet / 2, b.offsetZ) + edge.off,
			color = if b.brickTrim then COLORS.trimWhite else COLORS.concreteDark,
			parent = parent,
			material = Enum.Material.Concrete,
		})
	end

	-- 옥상 바닥 마감
	Geometry.box({
		name = b.name .. "_roofcap",
		size = Vector3.new(b.width + 0.3, 0.18, b.depth + 0.3),
		position = Vector3.new(b.offsetX, top + 0.09, b.offsetZ),
		color = COLORS.roof,
		parent = parent,
		material = Enum.Material.Concrete,
	})

	if b.floors >= 2 then
		Geometry.box({
			name = b.name .. "_stairhouse",
			size = Vector3.new(5.5, 2.6, 4.5),
			position = Vector3.new(b.offsetX, top + 1.3, b.offsetZ),
			color = COLORS.concreteDark,
			parent = parent,
			material = Enum.Material.Concrete,
		})
	end
end

-- 담장: 동측(x = ox + halfW, 강남1길 방향)의 gateZ 중심으로 gateSpan만큼 정문 개구부 생성
local function buildFence(
	parent: Instance,
	site: { width: number, depth: number },
	gateZ: number,
	gateSpan: number,
	ox: number,
	oz: number
)
	local baseH = 0.75
	local fenceH = 1.15
	local totalH = baseH + fenceH
	local t = 0.25
	local halfW = site.width / 2
	local halfD = site.depth / 2
	local westX = ox - halfW
	local eastX = ox + halfW
	local northZ = oz - halfD
	local southZ = oz + halfD

	local gMinZ = gateZ - gateSpan / 2
	local gMaxZ = gateZ + gateSpan / 2

	local segments = {
		-- 동측(강남1길 정문 방향): 정문 북측 구간 + 정문 남측 구간
		{
			size = Vector3.new(t, 1, math.max(1, gMinZ - northZ)),
			pos = Vector3.new(eastX, 0, (northZ + gMinZ) / 2),
		},
		{
			size = Vector3.new(t, 1, math.max(1, southZ - gMaxZ)),
			pos = Vector3.new(eastX, 0, (gMaxZ + southZ) / 2),
		},
		-- 남측 / 북측 / 서측
		{ size = Vector3.new(site.width, 1, t), pos = Vector3.new(ox, 0, southZ) },
		{ size = Vector3.new(site.width, 1, t), pos = Vector3.new(ox, 0, northZ) },
		{ size = Vector3.new(t, 1, site.depth), pos = Vector3.new(westX, 0, oz) },
	}

	for _, seg in segments do
		-- 하부 석축/콘크리트 옹벽
		Geometry.box({
			name = "FenceBase",
			size = Vector3.new(seg.size.X + 0.08, baseH, seg.size.Z + 0.08),
			position = Vector3.new(seg.pos.X, baseH / 2, seg.pos.Z),
			color = COLORS.fenceBase,
			parent = parent,
			material = Enum.Material.Concrete,
		})
		-- 상부 백색 펜스
		Geometry.box({
			name = "Fence",
			size = Vector3.new(seg.size.X, fenceH, seg.size.Z),
			position = Vector3.new(seg.pos.X, baseH + fenceH / 2, seg.pos.Z),
			color = COLORS.fence,
			parent = parent,
			material = Enum.Material.SmoothPlastic,
		})
		-- 상단 녹색 캡
		Geometry.box({
			name = "FenceCap",
			size = Vector3.new(seg.size.X + 0.06, 0.16, seg.size.Z + 0.06),
			position = Vector3.new(seg.pos.X, totalH + 0.08, seg.pos.Z),
			color = COLORS.fenceCap,
			parent = parent,
			material = Enum.Material.SmoothPlastic,
		})
	end
end

-- 동측 정문 (강남1길 방향, X = gateX, Z = gateZ 중심, +X 동쪽 도로를 향함)
-- 로드뷰(DinCYGB6-nThfrMXe6v1VQ)에서 서쪽(-X)으로 바라볼 때:
--   화면 우측 = 북쪽(sz=-1, "안동강남초등학교 / 병설유치원" 현판 + 배움터 지킴이실 + 주황·갈색 아치 캐노피)
--   화면 좌측 = 남쪽(sz=+1, 도로명주소 "78" + "안동강남초등학교" 현판 + 태양광 트러스 2기 + 갈색 유리 게시판)
local function buildEastGate(
	parent: Instance,
	gateX: number,
	gateZ: number,
	gateWidth: number,
	main: Building
)
	local postXSize = 1.1 -- 동서 두께
	local postH = 2.6
	local postZSize = 2.8 -- 남북 폭

	for _, sz in { -1, 1 } do
		local pz = gateZ + sz * (gateWidth / 2 + postZSize / 2)
		Geometry.box({
			name = "GatePost",
			size = Vector3.new(postXSize, postH, postZSize),
			position = Vector3.new(gateX, postH / 2, pz),
			color = COLORS.gateStone,
			parent = parent,
			material = Enum.Material.Slate,
		})
		-- 기둥 상단 몰딩 및 캡석
		Geometry.box({
			name = "GatePostCornice",
			size = Vector3.new(postXSize + 0.12, 0.14, postZSize + 0.12),
			position = Vector3.new(gateX, postH - 0.05, pz),
			color = COLORS.concreteDark,
			parent = parent,
			material = Enum.Material.Slate,
		})
		Geometry.box({
			name = "GatePostCap",
			size = Vector3.new(postXSize + 0.24, 0.22, postZSize + 0.24),
			position = Vector3.new(gateX, postH + 0.11, pz),
			color = COLORS.concreteDark,
			parent = parent,
			material = Enum.Material.Slate,
		})
	end

	-- 우측(북측, sz=-1) 기둥 동측(+X) 정면: 검은 대리석 교명판 "안동강남초등학교\n병설유치원"
	local rightPostZ = gateZ - (gateWidth / 2 + postZSize / 2)
	Geometry.sign(parent, {
		name = "GateSignRight",
		size = Vector3.new(2.1, 0.75, 0.12),
		position = Vector3.new(gateX + postXSize / 2 + 0.06, 1.55, rightPostZ),
		text = "안동강남초등학교\n병설유치원",
		textColor = Color3.fromRGB(255, 255, 255),
		backgroundColor = COLORS.signBg,
		rotationY = 90,
	})

	-- 좌측(남측, sz=+1) 기둥 동측(+X) 정면:
	-- 상단 중앙 청색 도로명주소판 "78", 중앙 검은 교명판 "안동강남초등학교",
	-- 우측(북측) 적색 "에스원" 표지 + 황색 안내판, 좌측(남측) 백색 안내판
	local leftPostZ = gateZ + (gateWidth / 2 + postZSize / 2)
	local eastFaceX = gateX + postXSize / 2
	Geometry.sign(parent, {
		name = "GateAddr78",
		size = Vector3.new(0.38, 0.40, 0.08),
		position = Vector3.new(eastFaceX + 0.05, postH - 0.36, leftPostZ),
		text = "78",
		textColor = Color3.fromRGB(255, 255, 255),
		backgroundColor = Color3.fromRGB(28, 72, 150),
		rotationY = 90,
	})
	Geometry.sign(parent, {
		name = "GateSignLeft",
		size = Vector3.new(1.45, 0.52, 0.12),
		position = Vector3.new(eastFaceX + 0.06, 1.38, leftPostZ),
		text = "안동강남초등학교",
		textColor = Color3.fromRGB(255, 255, 255),
		backgroundColor = COLORS.signBg,
		rotationY = 90,
	})
	Geometry.box({
		name = "GateNoticeS1Header",
		size = Vector3.new(0.08, 0.16, 0.38),
		position = Vector3.new(eastFaceX + 0.05, 1.84, leftPostZ - 1.02),
		color = COLORS.trimWhite,
		parent = parent,
	})
	Geometry.sign(parent, {
		name = "GateNoticeRed",
		size = Vector3.new(0.38, 0.28, 0.08),
		position = Vector3.new(eastFaceX + 0.05, 1.62, leftPostZ - 1.02),
		text = "에스원",
		textColor = Color3.fromRGB(255, 255, 255),
		backgroundColor = Color3.fromRGB(206, 36, 44),
		rotationY = 90,
	})
	Geometry.box({
		name = "GateNoticeYellow",
		size = Vector3.new(0.08, 0.48, 0.38),
		position = Vector3.new(eastFaceX + 0.05, 1.18, leftPostZ - 1.02),
		color = Color3.fromRGB(238, 198, 42),
		parent = parent,
	})
	Geometry.box({
		name = "GateNoticeWhite",
		size = Vector3.new(0.08, 0.56, 0.48),
		position = Vector3.new(eastFaceX + 0.05, 1.48, leftPostZ + 1.02),
		color = COLORS.trimWhite,
		parent = parent,
	})
	Geometry.box({
		name = "GateNoticeWhiteSub",
		size = Vector3.new(0.08, 0.24, 0.48),
		position = Vector3.new(eastFaceX + 0.05, 0.98, leftPostZ + 1.02),
		color = COLORS.trimWhite,
		parent = parent,
	})

	-- 남측 교문 기둥 상단: 3.0m 높이 은색 금속 트러스 포스트 2기 및 경사 태양광 패널
	local capTopY = postH + 0.22
	local trussH = 3.0
	local solarConfigs = {
		{ idx = 1, dz = 0.62, height = 2.65 },
		{ idx = 2, dz = -0.15, height = trussH },
	}
	for _, sc in solarConfigs do
		local tz = leftPostZ + sc.dz
		local th = sc.height
		Geometry.box({
			name = string.format("SolarTruss_%d", sc.idx),
			size = Vector3.new(0.24, th, 0.32),
			position = Vector3.new(gateX, capTopY + th / 2, tz),
			color = COLORS.silverMetal,
			parent = parent,
			material = Enum.Material.Metal,
			transparency = 0.25,
		})
		for _, rdz in { -0.12, 0.12 } do
			Geometry.box({
				name = string.format("SolarTrussRail_%d", sc.idx),
				size = Vector3.new(0.07, th, 0.07),
				position = Vector3.new(gateX, capTopY + th / 2, tz + rdz),
				color = COLORS.silverMetal,
				parent = parent,
				material = Enum.Material.Metal,
			})
		end
		for rung = 1, 5 do
			local ry = capTopY + (rung - 0.5) * (th / 5)
			Geometry.box({
				name = string.format("SolarTrussRung_%d_%d", sc.idx, rung),
				size = Vector3.new(0.12, 0.05, 0.30),
				position = Vector3.new(gateX, ry, tz),
				color = COLORS.silverMetal,
				parent = parent,
				material = Enum.Material.Metal,
			})
		end
		local panel = Geometry.box({
			name = string.format("SolarPanel_%d", sc.idx),
			size = Vector3.new(0.95, 0.08, 1.05),
			position = Vector3.new(gateX, capTopY + th + 0.12, tz),
			color = COLORS.solarDark,
			parent = parent,
			material = Enum.Material.Glass,
		})
		panel.CFrame = panel.CFrame * CFrame.Angles(math.rad(26), 0, math.rad(-18))
	end
	-- 좌측 태양광 트러스 하단 흑색 전광/센서 박스
	Geometry.box({
		name = "SolarDisplayBox",
		size = Vector3.new(0.22, 0.85, 0.46),
		position = Vector3.new(gateX + 0.18, capTopY + 0.65, leftPostZ + 0.92),
		color = COLORS.signBg,
		parent = parent,
		material = Enum.Material.Metal,
	})

	-- 남측 교문 기둥 바로 남쪽(leftPostZ + 2.4): 갈색 프레임 유리 게시판 (NoticeBoardFrame, NoticeBoardGlass, NoticeBoardRoof)
	local nbX = gateX + 0.15
	local nbZ = leftPostZ + 2.4
	Geometry.box({
		name = "NoticeBoardFrame",
		size = Vector3.new(0.24, 2.35, 1.85),
		position = Vector3.new(nbX, 1.18, nbZ),
		color = COLORS.noticeBrown,
		parent = parent,
		material = Enum.Material.Metal,
	})
	Geometry.box({
		name = "NoticeBoardBacking",
		size = Vector3.new(0.14, 1.55, 1.62),
		position = Vector3.new(nbX + 0.04, 1.42, nbZ),
		color = Color3.fromRGB(224, 232, 222),
		parent = parent,
		material = Enum.Material.SmoothPlastic,
	})
	Geometry.box({
		name = "NoticeBoardGlass",
		size = Vector3.new(0.08, 1.62, 1.68),
		position = Vector3.new(nbX + 0.12, 1.42, nbZ),
		color = COLORS.window,
		parent = parent,
		material = Enum.Material.Glass,
		transparency = 0.25,
		canCollide = false,
	})
	Geometry.box({
		name = "NoticeBoardRoof",
		size = Vector3.new(0.68, 0.24, 2.15),
		position = Vector3.new(nbX + 0.05, 2.44, nbZ),
		color = COLORS.noticeBrown,
		parent = parent,
		material = Enum.Material.Metal,
	})

	-- 은색 접이식(아코디언) 자바라 게이트 (상단 원형/아치 캡 포함)
	Geometry.box({
		name = "GateBar",
		size = Vector3.new(0.16, 1.32, gateWidth - 0.3),
		position = Vector3.new(gateX, 0.72, gateZ),
		color = COLORS.silverMetal,
		parent = parent,
		material = Enum.Material.Metal,
		transparency = 0.45,
	})
	local numRibs = 15
	for i = 0, numRibs - 1 do
		local rz = gateZ - (gateWidth - 0.6) / 2 + i * ((gateWidth - 0.6) / (numRibs - 1))
		Geometry.box({
			name = "GateRib",
			size = Vector3.new(0.20, 1.48, 0.07),
			position = Vector3.new(gateX, 0.78, rz),
			color = COLORS.silverMetal,
			parent = parent,
			material = Enum.Material.Metal,
		})
		Geometry.box({
			name = "GateArchCap",
			size = Vector3.new(0.22, 0.20, 0.26),
			position = Vector3.new(gateX, 1.56, rz),
			color = COLORS.silverMetal,
			parent = parent,
			material = Enum.Material.Metal,
			shape = Enum.PartType.Cylinder,
		})
	end

	-- 우측(북측) 정문 안쪽 배움터 지킴이실 부스 (GuardBox)
	local guardX = gateX - 3.2
	local guardZ = rightPostZ + 1.4
	Geometry.box({
		name = "GuardBox",
		size = Vector3.new(2.4, 2.5, 2.6),
		position = Vector3.new(guardX, 1.25, guardZ),
		color = COLORS.guardBox,
		parent = parent,
		material = Enum.Material.SmoothPlastic,
	})
	Geometry.box({
		name = "GuardBoxRoof",
		size = Vector3.new(2.7, 0.22, 2.9),
		position = Vector3.new(guardX, 2.61, guardZ),
		color = COLORS.canopyFrame,
		parent = parent,
		material = Enum.Material.Metal,
	})
	Geometry.box({
		name = "GuardBoxWindowFrame",
		size = Vector3.new(0.14, 1.12, 1.72),
		position = Vector3.new(guardX + 1.18, 1.45, guardZ),
		color = COLORS.trimWhite,
		parent = parent,
		material = Enum.Material.SmoothPlastic,
	})
	Geometry.box({
		name = "GuardBoxWindow",
		size = Vector3.new(0.16, 0.96, 1.54),
		position = Vector3.new(guardX + 1.19, 1.45, guardZ),
		color = COLORS.window,
		parent = parent,
		material = Enum.Material.Glass,
		transparency = 0.22,
		canCollide = false,
	})
	Geometry.box({
		name = "GuardSignBannerTop",
		size = Vector3.new(0.14, 0.36, 2.55),
		position = Vector3.new(guardX + 1.22, 2.52, guardZ),
		color = COLORS.guardBox,
		parent = parent,
		material = Enum.Material.SmoothPlastic,
	})
	Geometry.sign(parent, {
		name = "GuardSign",
		size = Vector3.new(2.55, 0.62, 0.14),
		position = Vector3.new(guardX + 1.24, 2.34, guardZ),
		text = "안동강남초등학교\n배움터 지킴이실",
		textColor = Color3.fromRGB(246, 232, 128),
		backgroundColor = COLORS.guardGreen,
		rotationY = 90,
	})

	-- 좌측(남측) 기둥 남서쪽 후방: 청색 지붕 등하교 대기소 (ShelterRoof, ShelterBack)
	local shelterX = gateX - 2.6
	local shelterZ = leftPostZ + 7.2
	Geometry.box({
		name = "ShelterRoof",
		size = Vector3.new(2.2, 0.24, 8.5),
		position = Vector3.new(shelterX, 2.6, shelterZ),
		color = COLORS.shelterRoof,
		parent = parent,
		material = Enum.Material.Metal,
	})
	Geometry.box({
		name = "ShelterBack",
		size = Vector3.new(0.16, 1.9, 8.0),
		position = Vector3.new(shelterX - 0.8, 1.4, shelterZ),
		color = COLORS.window,
		parent = parent,
		material = Enum.Material.Glass,
		transparency = 0.25,
	})
	for _, dz in { -3.6, -1.2, 1.2, 3.6 } do
		Geometry.box({
			name = "ShelterPost",
			size = Vector3.new(0.16, 2.5, 0.16),
			position = Vector3.new(shelterX + 0.7, 1.25, shelterZ + dz),
			color = COLORS.gate,
			parent = parent,
			material = Enum.Material.Metal,
		})
	end

	-- 우측(북측) 보행로: 주황·갈색 곡면/계단형 폴리카보네이트 아치 캐노피 통로 (EntranceCanopyRoof)
	local canopyCenterX = gateX - 2.8
	local canopyStartZ = rightPostZ
	local canopyEndZ = main.offsetZ + main.depth / 2
	local canopyLen = math.max(8.0, canopyStartZ - canopyEndZ)
	local canopyMidZ = (canopyStartZ + canopyEndZ) / 2
	local canopyW = 3.2
	local canopyBaseH = 3.25

	-- 아치 상단 중앙 주황 반투명 지붕 (대표 파트명 EntranceCanopyRoof 유지)
	Geometry.box({
		name = "EntranceCanopyRoof",
		size = Vector3.new(1.4, 0.18, canopyLen),
		position = Vector3.new(canopyCenterX, canopyBaseH + 0.52, canopyMidZ),
		color = COLORS.canopyRoof,
		parent = parent,
		material = Enum.Material.Glass,
		transparency = 0.18,
	})
	-- 아치 좌우 경사 단 (주황 폴리카보네이트 곡면 표현)
	for _, sx in { -1, 1 } do
		local sideStrip = Geometry.box({
			name = "EntranceCanopyArchSide",
			size = Vector3.new(1.15, 0.14, canopyLen),
			position = Vector3.new(canopyCenterX + sx * 1.05, canopyBaseH + 0.30, canopyMidZ),
			color = COLORS.canopyRoof,
			parent = parent,
			material = Enum.Material.Glass,
			transparency = 0.2,
		})
		sideStrip.CFrame = sideStrip.CFrame * CFrame.Angles(0, 0, math.rad(-sx * 20))

		Geometry.box({
			name = "CanopyLongBeam",
			size = Vector3.new(0.18, 0.24, canopyLen),
			position = Vector3.new(canopyCenterX + sx * (canopyW / 2), canopyBaseH, canopyMidZ),
			color = COLORS.canopyFrame,
			parent = parent,
			material = Enum.Material.Metal,
		})
	end

	-- 정문 입구 연결 아치 캐노피 (EastGateEntryCanopy)
	Geometry.box({
		name = "EastGateEntryCanopy",
		size = Vector3.new(3.2, 0.18, 3.2),
		position = Vector3.new(canopyCenterX, canopyBaseH + 0.38, rightPostZ + 0.4),
		color = COLORS.canopyRoof,
		parent = parent,
		material = Enum.Material.Glass,
		transparency = 0.18,
	})

	-- 동측(+X) 상단 프리즈 보드 및 "안동강남유치원" 배너 현판
	Geometry.sign(parent, {
		name = "CanopyKinderSign",
		size = Vector3.new(5.2, 0.48, 0.12),
		position = Vector3.new(
			canopyCenterX + canopyW / 2 + 0.08,
			canopyBaseH + 0.18,
			rightPostZ - 3.8
		),
		text = "안동강남유치원",
		textColor = Color3.fromRGB(255, 238, 196),
		backgroundColor = COLORS.canopyFrame,
		rotationY = 90,
	})

	-- 적갈색 기둥 및 아치 가로보
	local numSpans = math.max(5, math.floor(canopyLen / 6.0))
	for i = 0, numSpans do
		local pz = canopyStartZ - i * (canopyLen / numSpans)
		for _, sx in { -1, 1 } do
			Geometry.box({
				name = "CanopyPillar",
				size = Vector3.new(0.20, canopyBaseH, 0.20),
				position = Vector3.new(canopyCenterX + sx * (canopyW / 2), canopyBaseH / 2, pz),
				color = COLORS.canopyFrame,
				parent = parent,
				material = Enum.Material.Metal,
			})
		end
		Geometry.box({
			name = "CanopyArchRib",
			size = Vector3.new(canopyW + 0.2, 0.18, 0.18),
			position = Vector3.new(canopyCenterX, canopyBaseH + 0.12, pz),
			color = COLORS.canopyFrame,
			parent = parent,
			material = Enum.Material.Metal,
		})
	end
end

-- 북관(MainBuilding) 세부: 중앙 계단실 돌출코어, 동단 날개동, 남측 중앙 현관 캐노피
local function buildNorthWingDetails(parent: Instance, main: Building)
	local stairW = 8.0
	local stairD = 5.0
	buildBody(parent, {
		name = "NorthWing_CenterStairCore",
		offsetX = main.offsetX,
		offsetZ = main.offsetZ - main.depth / 2 - 2.5,
		width = stairW,
		depth = stairD,
		floors = main.floors,
		floorHeight = main.floorHeight,
		columns = 2,
		brickTrim = true,
	}, COLORS.brick, COLORS.window)

	local eastW = 14.0
	local eastD = main.depth + 2.4
	buildBody(parent, {
		name = "NorthWing_EastEndWing",
		offsetX = main.offsetX + main.width / 2 - 7.0,
		offsetZ = main.offsetZ,
		width = eastW,
		depth = eastD,
		floors = main.floors,
		floorHeight = main.floorHeight,
		columns = 3,
		brickTrim = true,
	}, COLORS.brick, COLORS.window)

	local porchW = 9.2
	local porchD = 3.2
	local porchH = 4.2
	local porchX = main.offsetX - 2.0
	local porchZ = main.offsetZ + main.depth / 2 + 1.6
	Geometry.box({
		name = "MainEntrancePorch",
		size = Vector3.new(porchW, 0.42, porchD),
		position = Vector3.new(porchX, porchH, porchZ),
		color = COLORS.trimWhite,
		parent = parent,
		material = Enum.Material.Concrete,
	})
	for _, sx in { -1, 1 } do
		Geometry.box({
			name = "MainEntrancePorchPillar",
			size = Vector3.new(0.45, porchH, 0.45),
			position = Vector3.new(
				porchX + sx * (porchW / 2 - 0.6),
				porchH / 2,
				porchZ + porchD / 2 - 0.35
			),
			color = COLORS.trimWhite,
			parent = parent,
			material = Enum.Material.Concrete,
		})
	end
end

-- 남서측 체육관·병설유치원(SouthAnnex, "강남마루") 세부:
-- 상부 백색/밝은회색 체육관 외벽 + 주황/테라코타 포인트 패널 + 동측 상단 "강남마루" 사인 + 유치원 캐노피 + 청색 천막 2동
local function buildSouthAnnexDetails(parent: Instance, annex: Building)
	local baseH = annex.floors * annex.floorHeight
	local gymAddH = 4.2
	local totalH = baseH + gymAddH
	local eastFaceX = annex.offsetX + annex.width / 2

	-- 2층 체육관(강남마루) 상부 증축 매스 (밝은 회백색 외장 + 진회색 지붕 처마 띠)
	Geometry.box({
		name = "SouthAnnexUpperGym",
		size = Vector3.new(annex.width + 0.16, gymAddH, annex.depth + 0.16),
		position = Vector3.new(annex.offsetX, baseH + gymAddH / 2, annex.offsetZ),
		color = COLORS.annexLight,
		parent = parent,
		material = Enum.Material.Concrete,
	})
	Geometry.box({
		name = "SouthAnnexRoofFascia",
		size = Vector3.new(annex.width + 0.6, 0.55, annex.depth + 0.6),
		position = Vector3.new(annex.offsetX, totalH + 0.25, annex.offsetZ),
		color = Color3.fromRGB(76, 80, 88),
		parent = parent,
		material = Enum.Material.Metal,
	})

	-- 동측(+X) 정면 주황/테라코타 포인트 패널 및 체육관 고창
	Geometry.box({
		name = "SouthAnnexAccentPanel",
		size = Vector3.new(0.22, 4.6, 11.5),
		position = Vector3.new(eastFaceX + 0.12, baseH + 1.1, annex.offsetZ - 1.5),
		color = COLORS.annexTerracotta,
		parent = parent,
		material = Enum.Material.SmoothPlastic,
	})
	for i = -2, 2 do
		Geometry.box({
			name = string.format("SouthAnnexGymWindow_%d", i + 3),
			size = Vector3.new(0.26, 2.6, 1.45),
			position = Vector3.new(eastFaceX + 0.14, baseH + 0.8, annex.offsetZ - 1.5 + i * 2.0),
			color = COLORS.window,
			parent = parent,
			material = Enum.Material.Glass,
			transparency = 0.2,
			canCollide = false,
		})
	end

	-- 동측(+X) 상단 "강남마루" 현판 (rotationY = 90)
	Geometry.sign(parent, {
		name = "SouthAnnexSign",
		size = Vector3.new(4.8, 1.05, 0.16),
		position = Vector3.new(eastFaceX + 0.18, totalH - 1.25, annex.offsetZ - 10.2),
		text = "강남마루",
		textColor = Color3.fromRGB(54, 58, 64),
		backgroundColor = COLORS.annexLight,
		rotationY = 90,
	})

	local canopyW = 3.2
	local canopyD = 8.0
	local canopyX = eastFaceX + 1.8
	local canopyZ = annex.offsetZ - 6.0
	Geometry.box({
		name = "KindergartenCanopy",
		size = Vector3.new(canopyW, 0.28, canopyD),
		position = Vector3.new(canopyX, 3.2, canopyZ),
		color = COLORS.kinderYellow,
		parent = parent,
		material = Enum.Material.SmoothPlastic,
	})
	Geometry.box({
		name = "KindergartenCanopyTrim",
		size = Vector3.new(canopyW + 0.1, 0.16, canopyD + 0.1),
		position = Vector3.new(canopyX, 3.42, canopyZ),
		color = COLORS.kinderRed,
		parent = parent,
		material = Enum.Material.SmoothPlastic,
	})
	for _, sz in { -1, 1 } do
		Geometry.box({
			name = "KindergartenCanopyPillar",
			size = Vector3.new(0.24, 3.2, 0.24),
			position = Vector3.new(
				canopyX + canopyW / 2 - 0.3,
				1.6,
				canopyZ + sz * (canopyD / 2 - 0.5)
			),
			color = COLORS.tentBlue,
			parent = parent,
			material = Enum.Material.Metal,
		})
	end

	local tentW = 3.4
	local tentD = 8.0
	local tentX = eastFaceX + 2.2
	local tentZ = annex.offsetZ + 4.0
	Geometry.box({
		name = "SouthWestBlueCanopies",
		size = Vector3.new(tentW, 0.26, tentD),
		position = Vector3.new(tentX, 3.0, tentZ),
		color = COLORS.tentBlue,
		parent = parent,
		material = Enum.Material.Fabric,
	})
	for idx, dz in { -2.0, 2.0 } do
		Geometry.box({
			name = if idx == 1 then "SWBlueTentNorth" else "SWBlueTentSouth",
			size = Vector3.new(tentW - 0.2, 0.32, 3.4),
			position = Vector3.new(tentX, 3.25, tentZ + dz),
			color = COLORS.tentBlue,
			parent = parent,
			material = Enum.Material.Fabric,
		})
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				Geometry.box({
					name = "SWBlueTentLeg",
					size = Vector3.new(0.14, 3.0, 0.14),
					position = Vector3.new(tentX + sx * 1.5, 1.5, tentZ + dz + sz * 1.6),
					color = COLORS.gate,
					parent = parent,
					material = Enum.Material.Metal,
				})
			end
		end
	end
end

-- 축구 골대 (서측 GoalWest / 동측 GoalEast: 선명한 백색 포스트/크로스바 + 하단 청색 스트라이프)
local function buildSoccerGoal(
	parent: Instance,
	name: string,
	gx: number,
	gz: number,
	openTowardX: number
)
	local goalW = 1.3
	local goalD = 5.4
	local goalH = 2.35
	local frontX = gx + openTowardX * (goalW / 2 - 0.08)
	local backX = gx - openTowardX * (goalW / 2 - 0.08)

	-- 전면 상단 백색 크로스바 (대표 파트명 GoalWest / GoalEast 유지)
	Geometry.box({
		name = name,
		size = Vector3.new(0.16, 0.16, goalD),
		position = Vector3.new(frontX, goalH, gz),
		color = COLORS.line,
		parent = parent,
		material = Enum.Material.SmoothPlastic,
	})
	-- 후면 하단 바
	Geometry.box({
		name = name .. "BackBar",
		size = Vector3.new(0.12, 0.12, goalD),
		position = Vector3.new(backX, 0.12, gz),
		color = COLORS.line,
		parent = parent,
		material = Enum.Material.SmoothPlastic,
	})
	for _, sz in { -1, 1 } do
		local pz = gz + sz * (goalD / 2 - 0.08)
		-- 전면 백색 포스트
		Geometry.box({
			name = name .. "Post",
			size = Vector3.new(0.16, goalH, 0.16),
			position = Vector3.new(frontX, goalH / 2, pz),
			color = COLORS.line,
			parent = parent,
			material = Enum.Material.SmoothPlastic,
		})
		-- 포스트 하단 청색 스트라이프 슬리브 (로드뷰 관측)
		Geometry.box({
			name = name .. "PostBlueStripe",
			size = Vector3.new(0.18, 0.85, 0.18),
			position = Vector3.new(frontX, 0.45, pz),
			color = COLORS.goalBlue,
			parent = parent,
			material = Enum.Material.SmoothPlastic,
		})
		-- 상단 측면 지지바 및 후면 지지 포스트
		Geometry.box({
			name = name .. "TopSideBar",
			size = Vector3.new(goalW, 0.12, 0.12),
			position = Vector3.new(gx, goalH, pz),
			color = COLORS.line,
			parent = parent,
			material = Enum.Material.SmoothPlastic,
		})
		Geometry.box({
			name = name .. "BottomSideBar",
			size = Vector3.new(goalW, 0.12, 0.12),
			position = Vector3.new(gx, 0.12, pz),
			color = COLORS.line,
			parent = parent,
			material = Enum.Material.SmoothPlastic,
		})
		Geometry.box({
			name = name .. "BackPost",
			size = Vector3.new(0.12, goalH, 0.12),
			position = Vector3.new(backX, goalH / 2, pz),
			color = COLORS.line,
			parent = parent,
			material = Enum.Material.SmoothPlastic,
		})
	end
end

-- 운동장 + 트랙 + 축구골대 + 북측 조회대/차양막 + 남측 장대 차양막
local function buildPlayground(
	parent: Instance,
	field: { width: number, depth: number, offsetX: number, offsetZ: number }
)
	local fx = field.offsetX
	local fz = field.offsetZ
	local fw = field.width
	local fd = field.depth

	-- 외곽 잔디 띠
	Geometry.box({
		name = "FieldBorder",
		size = Vector3.new(fw + 8, 0.08, fd + 8),
		position = Vector3.new(fx, 0.04, fz),
		color = COLORS.grass,
		parent = parent,
		material = Enum.Material.Grass,
	})
	-- 마사토(모래) 운동장
	Geometry.box({
		name = "Field",
		size = Vector3.new(fw, 0.12, fd),
		position = Vector3.new(fx, 0.06, fz),
		color = COLORS.sand,
		parent = parent,
		material = Enum.Material.Sand,
	})
	-- 트랙 백선 (외곽 직사각 + 내부 타원/트랙 레인 + 중앙선)
	local tw = fw - 12
	local td = fd - 18
	for _, inset in { 0, 2.5 } do
		local w = tw - inset * 2
		local d = td - inset * 2
		for _, s in { -1, 1 } do
			Geometry.box({
				name = "TrackLineEW",
				size = Vector3.new(w, 0.02, 0.22),
				position = Vector3.new(fx, 0.13, fz + s * d / 2),
				color = COLORS.line,
				parent = parent,
				canCollide = false,
			})
			Geometry.box({
				name = "TrackLineNS",
				size = Vector3.new(0.22, 0.02, d),
				position = Vector3.new(fx + s * w / 2, 0.13, fz),
				color = COLORS.line,
				parent = parent,
				canCollide = false,
			})
		end
	end
	Geometry.box({
		name = "PitchCenterLine",
		size = Vector3.new(0.2, 0.02, td - 5),
		position = Vector3.new(fx, 0.13, fz),
		color = COLORS.line,
		parent = parent,
		canCollide = false,
	})

	-- 서측·동측 축구 골대 (GoalWest, GoalEast)
	local goalOffset = (tw - 6) / 2
	buildSoccerGoal(parent, "GoalWest", fx - goalOffset, fz, 1)
	buildSoccerGoal(parent, "GoalEast", fx + goalOffset, fz, -1)

	-- 북측 조회대 + 곡면 백색 관람석 차양막 (Podium, SpectatorCanopy)
	local standZ = fz - fd / 2 - 4.5
	Geometry.box({
		name = "Podium",
		size = Vector3.new(7.6, 0.9, 4.8),
		position = Vector3.new(fx, 0.45, standZ),
		color = COLORS.concrete,
		parent = parent,
		material = Enum.Material.Concrete,
	})
	Geometry.box({
		name = "SpectatorCanopy",
		size = Vector3.new(44, 0.25, 4.8),
		position = Vector3.new(fx, 3.6, standZ),
		color = COLORS.trimWhite,
		parent = parent,
		material = Enum.Material.Fabric,
	})
	Geometry.box({
		name = "NorthPodiumCanopyArch",
		size = Vector3.new(8.4, 0.35, 5.2),
		position = Vector3.new(fx, 3.9, standZ),
		color = COLORS.trimWhite,
		parent = parent,
		material = Enum.Material.Fabric,
	})
	for i = -3, 3 do
		Geometry.box({
			name = "SpectatorCanopyPillar",
			size = Vector3.new(0.2, 3.6, 0.2),
			position = Vector3.new(fx + i * 6.5, 1.8, standZ - 1.8),
			color = COLORS.gate,
			parent = parent,
			material = Enum.Material.Metal,
		})
	end

	-- 남측 장대형 녹·백 교차 차양막 (SouthLongShadeCanopy, 19칸)
	local southCanopyW = fw - 6.0
	local southCanopyD = 4.2
	local southCanopyX = fx + 4.0
	local southCanopyZ = fz + fd / 2 + 3.2
	Geometry.box({
		name = "SouthLongShadeCanopy",
		size = Vector3.new(southCanopyW, 0.2, southCanopyD),
		position = Vector3.new(southCanopyX, 3.2, southCanopyZ),
		color = COLORS.trimWhite,
		parent = parent,
		material = Enum.Material.Fabric,
	})
	local bays = 19
	local bayW = southCanopyW / bays
	local startX = southCanopyX - southCanopyW / 2
	for b = 1, bays do
		local bx = startX + (b - 0.5) * bayW
		Geometry.box({
			name = "SouthLongShadeCanopyBay",
			size = Vector3.new(bayW - 0.08, 0.12, southCanopyD),
			position = Vector3.new(bx, 3.32, southCanopyZ),
			color = if b % 2 == 1 then COLORS.shadeGreen else COLORS.trimWhite,
			parent = parent,
			material = Enum.Material.Fabric,
		})
		if b % 2 == 1 then
			Geometry.box({
				name = "SouthLongShadeCanopyPost",
				size = Vector3.new(0.18, 3.2, 0.18),
				position = Vector3.new(bx, 1.6, southCanopyZ + southCanopyD / 2 - 0.3),
				color = COLORS.gate,
				parent = parent,
				material = Enum.Material.Metal,
			})
		end
	end
end

function School.build(record: any): Model
	local params = record.params
	local model = Instance.new("Model")
	model.Name = record.name or "School"

	local siteCX = params.site.offsetX or 51
	local siteCZ = params.site.offsetZ or -1
	Geometry.box({
		name = "Site",
		size = Vector3.new(params.site.width, 0.4, params.site.depth),
		position = Vector3.new(siteCX, -0.2, siteCZ),
		color = Color3.fromRGB(190, 188, 182),
		parent = model,
		material = Enum.Material.Concrete,
	})

	buildPlayground(model, params.field)

	-- 본관 북측 동서동 (4층 적벽돌 + 백색 띠 + 북측 계단코어/동단 날개/남측 현관 캐노피)
	local mainBuilding: Building = {
		name = "MainBuilding",
		offsetX = params.main.offsetX,
		offsetZ = params.main.offsetZ,
		width = params.main.width,
		depth = params.main.depth,
		floors = params.main.floors,
		floorHeight = params.main.floorHeight,
		columns = params.main.columns,
		brickTrim = true,
	}
	buildBody(model, mainBuilding, COLORS.brick, COLORS.window)
	buildNorthWingDetails(model, mainBuilding)

	-- 본관 서측 남북동 (4층 적벽돌 + 백색 띠, 정문 좌측 건물)
	if params.westWing then
		buildBody(model, {
			name = "WestWing",
			offsetX = params.westWing.offsetX,
			offsetZ = params.westWing.offsetZ,
			width = params.westWing.width,
			depth = params.westWing.depth,
			floors = params.westWing.floors,
			floorHeight = params.westWing.floorHeight,
			columns = params.westWing.columns,
			vertical = true,
			brickTrim = true,
		}, COLORS.brick, COLORS.window)
	end

	-- 남서측 병설유치원 / 체육관·급식동 + 유치원 캐노피 및 청색 천막
	if params.annex then
		local annexBuilding: Building = {
			name = "SouthAnnex",
			offsetX = params.annex.offsetX,
			offsetZ = params.annex.offsetZ,
			width = params.annex.width,
			depth = params.annex.depth,
			floors = params.annex.floors,
			floorHeight = params.annex.floorHeight,
			columns = params.annex.columns,
			vertical = params.annex.vertical == true,
		}
		buildBody(model, annexBuilding, COLORS.annexLight, COLORS.window)
		buildSouthAnnexDetails(model, annexBuilding)
	end

	-- 추가 부속동 (배움터지킴이실, 북측 창고 등 VWorld 실측; 본관과 Z가 겹치면 북쪽으로 클램프)
	if params.extra then
		local mainNorthEdge = mainBuilding.offsetZ - mainBuilding.depth / 2
		local mainSouthEdge = mainBuilding.offsetZ + mainBuilding.depth / 2
		for _, b in params.extra do
			local extraZ = b.offsetZ
			local overlapsMainX = math.abs(b.offsetX - mainBuilding.offsetX)
				< (b.width + mainBuilding.width) / 2
			local overlapsMainZ = (extraZ + b.depth / 2 > mainNorthEdge - 0.8)
				and (extraZ - b.depth / 2 < mainSouthEdge + 0.8)
			if overlapsMainX and overlapsMainZ then
				extraZ = math.min(extraZ, mainNorthEdge - b.depth / 2 - 0.8)
			end
			buildBody(model, {
				name = b.name or "Extra",
				offsetX = b.offsetX,
				offsetZ = extraZ,
				width = b.width,
				depth = b.depth,
				floors = b.floors,
				floorHeight = b.floorHeight,
				columns = b.columns,
				vertical = b.vertical == true,
			}, COLORS.concrete, COLORS.window)
		end
	end

	local gateX = siteCX + params.site.width / 2
	local gateZ = if params.gate and params.gate.offsetZ then params.gate.offsetZ else 7.5
	local gateW = if params.gate and params.gate.width then params.gate.width else 8
	buildFence(model, params.site, gateZ, gateW + 5.6, siteCX, siteCZ)
	buildEastGate(model, gateX, gateZ, gateW, mainBuilding)

	model:SetAttribute("blockId", record.id)
	model:SetAttribute("verified", record.verified == true)
	model:SetAttribute("source", record.source or "unknown")

	return model
end

return School
