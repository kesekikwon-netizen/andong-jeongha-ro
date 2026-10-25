--!strict
-- 가로시설물 키트: 가로등 / 전봇대 / 가로수 / 버스정류장.
-- 좌표계: 원점 = 시설물 바닥 중앙, +X = 도로 방향(암/간판 방향), 단위 m.
-- record.params 스펙:
--   lamp: { height: number? = 8, arm: number? = 2.5 }
--   pole: { height: number? = 9, crossarm: boolean? = false, transformer: boolean? = false }
--   tree: { trunkHeight: number? = 2.5, crownSize: number? = 2.5, squareBollard: boolean? = false }
--   busstop: { width: number? = 6 }

local Geometry = require(script.Parent.Parent.Geometry)

local Roadside = {}

local COLORS = {
	concrete = Color3.fromRGB(178, 178, 172),
	lampPole = Color3.fromRGB(62, 66, 72),
	lampHead = Color3.fromRGB(235, 235, 225),
	lampLens = Color3.fromRGB(255, 246, 214),
	bannerBg = Color3.fromRGB(242, 198, 38),
	bannerText = Color3.fromRGB(28, 30, 34),
	safetyYellow = Color3.fromRGB(240, 194, 36),
	safetyBlack = Color3.fromRGB(32, 34, 38),
	insulator = Color3.fromRGB(236, 240, 242),
	trunk = Color3.fromRGB(110, 82, 58),
	crownA = Color3.fromRGB(46, 110, 58),
	crownMid = Color3.fromRGB(54, 122, 64),
	crownB = Color3.fromRGB(62, 134, 70),
	soil = Color3.fromRGB(76, 58, 42),
	pitCurb = Color3.fromRGB(142, 140, 134),
	shelterBlue = Color3.fromRGB(38, 92, 160),
	shelterGray = Color3.fromRGB(150, 156, 162),
	glass = Color3.fromRGB(170, 205, 220),
	bench = Color3.fromRGB(120, 90, 60),
	signBg = Color3.fromRGB(30, 90, 160),
}

-- 가로등 1기: 기초 + 단차 하부 칼라 + 기둥 + 브래킷 + 암 + 등박스/LED 렌즈 + 어린이보호구역 배너(선택)
local function buildLamp(model: Model, params: any)
	local height = if params.height ~= nil then params.height :: number else 8
	local arm = if params.arm ~= nil then params.arm :: number else 2.5
	-- 기초
	Geometry.box({
		name = "LampBase",
		size = Vector3.new(0.7, 0.5, 0.7),
		position = Vector3.new(0, 0.25, 0),
		color = COLORS.concrete,
		parent = model,
		material = Enum.Material.Concrete,
	})
	-- 하부 테이퍼드/단차 보호 칼라
	Geometry.box({
		name = "LampCollarLower",
		size = Vector3.new(0.42, 0.6, 0.42),
		position = Vector3.new(0, 0.8, 0),
		color = COLORS.lampPole,
		parent = model,
		material = Enum.Material.Metal,
	})
	Geometry.box({
		name = "LampCollarUpper",
		size = Vector3.new(0.33, 0.65, 0.33),
		position = Vector3.new(0, 1.42, 0),
		color = COLORS.lampPole,
		parent = model,
		material = Enum.Material.Metal,
	})
	-- 기둥
	Geometry.box({
		name = "LampPole",
		size = Vector3.new(0.25, height, 0.25),
		position = Vector3.new(0, height / 2, 0),
		color = COLORS.lampPole,
		parent = model,
		material = Enum.Material.Metal,
	})
	Geometry.box({
		name = "LampCap",
		size = Vector3.new(0.3, 0.14, 0.3),
		position = Vector3.new(0, height + 0.05, 0),
		color = COLORS.lampPole,
		parent = model,
		material = Enum.Material.Metal,
	})
	-- 상부 완만한 브래킷 전환부 + 암 (도로 쪽 +X)
	Geometry.box({
		name = "LampBracketLower",
		size = Vector3.new(0.45, 0.12, 0.14),
		position = Vector3.new(0.22, height - 0.42, 0),
		color = COLORS.lampPole,
		parent = model,
		material = Enum.Material.Metal,
	})
	Geometry.box({
		name = "LampBracketUpper",
		size = Vector3.new(0.7, 0.12, 0.14),
		position = Vector3.new(0.45, height - 0.25, 0),
		color = COLORS.lampPole,
		parent = model,
		material = Enum.Material.Metal,
	})
	Geometry.box({
		name = "LampArm",
		size = Vector3.new(arm, 0.15, 0.15),
		position = Vector3.new(arm / 2, height - 0.1, 0),
		color = COLORS.lampPole,
		parent = model,
		material = Enum.Material.Metal,
	})
	-- 등박스 + 하부 웜화이트 LED 렌즈
	Geometry.box({
		name = "LampHead",
		size = Vector3.new(1.0, 0.2, 0.4),
		position = Vector3.new(arm, height - 0.25, 0),
		color = COLORS.lampHead,
		parent = model,
		material = Enum.Material.SmoothPlastic,
	})
	Geometry.box({
		name = "LampLens",
		size = Vector3.new(0.84, 0.06, 0.32),
		position = Vector3.new(arm, height - 0.36, 0),
		color = COLORS.lampLens,
		parent = model,
		material = Enum.Material.Neon,
		canCollide = false,
	})
	-- 어린이보호구역 배너 (강남1길 구간 및 기본 활성화, schoolZone=false로 비활성 가능)
	local showBanner = if params.schoolZone ~= nil
		then params.schoolZone == true
		else (params.arm == nil or params.arm <= 2.0)
	if showBanner then
		local banner = Geometry.sign(model, {
			name = "SchoolZoneBanner",
			size = Vector3.new(0.46, 1.1, 0.08),
			position = Vector3.new(0.28, 3.2, 0),
			text = "어린이보호구역\n천천히",
			textColor = COLORS.bannerText,
			backgroundColor = COLORS.bannerBg,
		})
		banner.CanCollide = false
	end
end

-- 전봇대: 기초 + 기둥 + 황흑 안전표시 띠(0.5~2.2m) + 크로스암/애자 + 보안등 암 + 변압기(선택)
local function buildPole(model: Model, params: any)
	local height = if params.height ~= nil then params.height :: number else 9
	Geometry.box({
		name = "PoleBase",
		size = Vector3.new(0.8, 0.5, 0.8),
		position = Vector3.new(0, 0.25, 0),
		color = COLORS.concrete,
		parent = model,
		material = Enum.Material.Concrete,
	})
	Geometry.box({
		name = "PoleBody",
		size = Vector3.new(0.3, height, 0.3),
		position = Vector3.new(0, height / 2, 0),
		color = COLORS.concrete,
		parent = model,
		material = Enum.Material.Concrete,
	})
	-- 한국형 전봇대 하단 황·흑 안전표시 띠 (Y = 0.5m ~ 2.2m, 10단 교차)
	local bandCount = 10
	local bandHeight = (2.2 - 0.5) / bandCount
	for i = 1, bandCount do
		local isYellow = i % 2 == 1
		Geometry.box({
			name = if isYellow then "SafetyWrap_Yellow" else "SafetyWrap_Black",
			size = Vector3.new(0.33, bandHeight, 0.33),
			position = Vector3.new(0, 0.5 + (i - 0.5) * bandHeight, 0),
			color = if isYellow then COLORS.safetyYellow else COLORS.safetyBlack,
			parent = model,
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
		})
	end
	-- 상부 완철(크로스암) 2단 + 자기 애자(Insulator)
	if params.crossarm ~= false then
		for i, y in { height - 0.85, height - 1.75 } do
			Geometry.box({
				name = "Crossarm" .. tostring(i),
				size = Vector3.new(1.8, 0.15, 0.15),
				position = Vector3.new(0, y, 0),
				color = COLORS.shelterGray,
				parent = model,
				material = Enum.Material.Metal,
			})
			for _, ix in { -0.72, 0, 0.72 } do
				Geometry.box({
					name = "Insulator",
					size = Vector3.new(0.12, 0.22, 0.12),
					position = Vector3.new(ix, y + 0.16, 0),
					color = COLORS.insulator,
					parent = model,
					material = Enum.Material.SmoothPlastic,
					shape = Enum.PartType.Cylinder,
					canCollide = false,
				})
			end
		end
	end
	-- 도로 방향(+X) 보안등 브래킷 암 및 등기구
	if params.streetlamp ~= false then
		local lampY = height - 2.55
		Geometry.box({
			name = "PoleLampArm",
			size = Vector3.new(1.35, 0.1, 0.1),
			position = Vector3.new(0.72, lampY, 0),
			color = COLORS.shelterGray,
			parent = model,
			material = Enum.Material.Metal,
			canCollide = false,
		})
		Geometry.box({
			name = "PoleLampBrace",
			size = Vector3.new(0.85, 0.08, 0.08),
			position = Vector3.new(0.48, lampY - 0.22, 0),
			color = COLORS.shelterGray,
			parent = model,
			material = Enum.Material.Metal,
			canCollide = false,
		})
		Geometry.box({
			name = "PoleLampHead",
			size = Vector3.new(0.62, 0.14, 0.28),
			position = Vector3.new(1.4, lampY - 0.02, 0),
			color = COLORS.lampHead,
			parent = model,
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
		})
		Geometry.box({
			name = "PoleLampLens",
			size = Vector3.new(0.5, 0.05, 0.22),
			position = Vector3.new(1.4, lampY - 0.1, 0),
			color = COLORS.lampLens,
			parent = model,
			material = Enum.Material.Neon,
			canCollide = false,
		})
	end
	-- 원통형 변압기 (전선 없음)
	if params.transformer == true then
		Geometry.box({
			name = "Transformer",
			size = Vector3.new(0.8, 1.2, 0.8),
			position = Vector3.new(0.55, height - 3.3, 0),
			color = COLORS.shelterGray,
			parent = model,
			material = Enum.Material.Metal,
			shape = Enum.PartType.Cylinder,
			rotationY = 90,
		})
	end
end

-- 가로수: 보도 식수대(TreePit) + 줄기 + 3단 풍성한 수관(CrownLower/Mid/Upper) + 보호틀 4개(선택)
local function buildTree(model: Model, params: any)
	local trunkHeight = if params.trunkHeight ~= nil then params.trunkHeight :: number else 2.5
	local crownSize = if params.crownSize ~= nil then params.crownSize :: number else 2.5
	-- 보도 식수대 테두리 및 토양 (Y = 0.32m)
	Geometry.box({
		name = "TreePitCurb",
		size = Vector3.new(1.36, 0.32, 1.36),
		position = Vector3.new(0, 0.31, 0),
		color = COLORS.pitCurb,
		parent = model,
		material = Enum.Material.Concrete,
		canCollide = false,
	})
	Geometry.box({
		name = "TreePit",
		size = Vector3.new(1.16, 0.34, 1.16),
		position = Vector3.new(0, 0.32, 0),
		color = COLORS.soil,
		parent = model,
		material = Enum.Material.Ground,
		canCollide = false,
	})
	-- 줄기
	Geometry.box({
		name = "Trunk",
		size = Vector3.new(0.32, trunkHeight, 0.32),
		position = Vector3.new(0, trunkHeight / 2, 0),
		color = COLORS.trunk,
		parent = model,
		material = Enum.Material.Wood,
	})
	-- 수관 3단 (CrownLower / CrownMid / CrownUpper)
	Geometry.box({
		name = "CrownLower",
		size = Vector3.new(crownSize, crownSize * 0.88, crownSize),
		position = Vector3.new(-0.18, trunkHeight + crownSize * 0.28, 0.12),
		color = COLORS.crownA,
		parent = model,
		material = Enum.Material.Grass,
		shape = Enum.PartType.Ball,
	})
	Geometry.box({
		name = "CrownMid",
		size = Vector3.new(crownSize * 0.92, crownSize * 0.84, crownSize * 0.92),
		position = Vector3.new(0.2, trunkHeight + crownSize * 0.56, -0.14),
		color = COLORS.crownMid,
		parent = model,
		material = Enum.Material.Grass,
		shape = Enum.PartType.Ball,
	})
	Geometry.box({
		name = "CrownUpper",
		size = Vector3.new(crownSize * 0.78, crownSize * 0.76, crownSize * 0.78),
		position = Vector3.new(0, trunkHeight + crownSize * 0.88, 0),
		color = COLORS.crownB,
		parent = model,
		material = Enum.Material.Grass,
		shape = Enum.PartType.Ball,
	})
	-- 보호틀 4개
	if params.squareBollard == true then
		local half = 0.7
		for _, sx in { 1, -1 } do
			for _, sz in { 1, -1 } do
				Geometry.box({
					name = "Bollard",
					size = Vector3.new(0.15, 0.8, 0.15),
					position = Vector3.new(sx * half, 0.4, sz * half),
					color = COLORS.concrete,
					parent = model,
					material = Enum.Material.Concrete,
				})
			end
		end
	end
end

-- 버스정류장: 지붕 + 기둥 4개 + 뒷면 유리 + 벤치 + 표지판
local function buildBusstop(model: Model, params: any)
	local width = if params.width ~= nil then params.width :: number else 6
	local depth = 2.0
	local pillarH = 2.5
	-- 기둥 4개
	for _, sx in { 1, -1 } do
		for _, sz in { 1, -1 } do
			Geometry.box({
				name = "ShelterPillar",
				size = Vector3.new(0.15, pillarH, 0.15),
				position = Vector3.new(sx * (width / 2 - 0.1), pillarH / 2, sz * (depth / 2 - 0.1)),
				color = COLORS.shelterGray,
				parent = model,
				material = Enum.Material.Metal,
			})
		end
	end
	-- 지붕
	Geometry.box({
		name = "ShelterRoof",
		size = Vector3.new(width, 0.2, depth + 0.2),
		position = Vector3.new(0, pillarH + 0.1, 0),
		color = COLORS.shelterBlue,
		parent = model,
		material = Enum.Material.Metal,
	})
	-- 뒷면 유리
	Geometry.box({
		name = "ShelterGlass",
		size = Vector3.new(width - 0.3, 1.6, 0.1),
		position = Vector3.new(0, 1.3, -(depth / 2 - 0.1)),
		color = COLORS.glass,
		parent = model,
		material = Enum.Material.Glass,
		transparency = 0.3,
		canCollide = false,
	})
	-- 벤치 1개
	Geometry.box({
		name = "Bench",
		size = Vector3.new(width - 1.0, 0.12, 0.5),
		position = Vector3.new(0, 0.6, -0.4),
		color = COLORS.bench,
		parent = model,
		material = Enum.Material.Wood,
	})
	-- 표지판 기둥
	local signX = width / 2 + 1.0
	Geometry.box({
		name = "SignPole",
		size = Vector3.new(0.12, 2.6, 0.12),
		position = Vector3.new(signX, 1.3, 0),
		color = COLORS.shelterGray,
		parent = model,
		material = Enum.Material.Metal,
	})
	local board = Geometry.sign(model, {
		name = "BusSign",
		size = Vector3.new(1.4, 0.5, 0.1),
		position = Vector3.new(signX, 2.5, 0),
		text = "버스정류장",
		textColor = Color3.fromRGB(255, 255, 255),
		backgroundColor = COLORS.signBg,
	})
	-- 간판 비충돌
	board.CanCollide = false
end

function Roadside.build(record: any): Model
	local params = record.params or {}
	local model = Instance.new("Model")
	model.Name = record.name or "Roadside"

	if record.kind == "lamp" then
		buildLamp(model, params)
	elseif record.kind == "pole" then
		buildPole(model, params)
	elseif record.kind == "tree" then
		buildTree(model, params)
	elseif record.kind == "busstop" then
		buildBusstop(model, params)
	else
		error("unknown roadside kind: " .. tostring(record.kind))
	end

	-- record.params의 offsetX/offsetZ로 각 파트를 수평 이동 (Y 높이는 그대로 유지)
	local ox = params.offsetX or 0
	local oz = params.offsetZ or 0
	if ox ~= 0 or oz ~= 0 then
		local delta = Vector3.new(Geometry.m2s(ox), 0, Geometry.m2s(oz))
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.CFrame = d.CFrame + delta
			end
		end
	end

	model:SetAttribute("blockId", record.id)
	model:SetAttribute("verified", record.verified == true)

	return model
end

return Roadside
