--!strict
-- 주거지 상가 건물 키트: 1층 상가(출입문·멀리언·계량기·배수관) + 간판, 2층 이상 주거/사무 + 2층 띠간판, 평지붕/경사지붕.
-- 좌표계: 원점 = 학교 정문, +X = 동, +Z = 남. 단위 m (Studs 변환은 Geometry가 처리).
--
-- record.params 스펙:
--   offsetX: number (미터, 원점=학교 정문, +X=동)
--   offsetZ: number (미터, +Z=남)
--   width: number (미터, 정면 폭)
--   depth: number (미터, 측면 깊이)
--   floors: number (1~5, 범위 밖은 clamp)
--   floorHeight: number? (기본 3.6)
--   columns: number? (정면 창문 열 수, 기본 3)
--   facing: "south" | "north"? (간판/상가가 향하는 쪽, 기본 "south")
--   style: ("beige_stone" | "dark_slate" | "red_brick" | "gray_stucco" | "white_stucco" | "charcoal_panel" | "beige_tile" | "wood_curtainwall" | "terracotta_tile")?
--   roofType: ("flat" | "gable_green" | "gable_red" | "gable_blue" | "hip_dark")?
--   signText: string? (1층 간판 문구, 기본 "상가")
--   subSignText: string? (2층 학원/의원/사무실 띠간판 문구)
--   signColor: Color3? (간판 배경색, 기본 해시 선택)
--   awningColor: Color3? (어닝/캐노피 색, 기본 signColor와 동일)
--   piloti: boolean? (true면 1층 필로티 주차장, 기본 false)
--   roofSign: boolean? (true면 옥상 간판 기둥 2개, 기본 false)
--   stoneFascia: boolean? (검은 석재 파사드 + 대형 유리, 기본 false)
--   verticalSign: string? (세로 간판 문구, 없으면 해시 또는 생략)
--   deck: boolean? (전면 목재 데크 + 난간, 기본 false, 벽면에서 0.35m 이내)

local Geometry = require(script.Parent.Parent.Geometry)

local Shophouse = {}

local COLORS = {
	body = Color3.fromRGB(214, 200, 174),
	trim = Color3.fromRGB(172, 166, 156),
	storefront = Color3.fromRGB(140, 168, 178),
	curtainGlass = Color3.fromRGB(78, 128, 168),
	window = Color3.fromRGB(126, 158, 172),
	roof = Color3.fromRGB(110, 112, 116),
	pillar = Color3.fromRGB(188, 184, 174),
	signText = Color3.fromRGB(245, 244, 240),
	signBg = Color3.fromRGB(72, 74, 80),
	brick = Color3.fromRGB(166, 122, 96),
	acBody = Color3.fromRGB(210, 212, 214),
	acGrille = Color3.fromRGB(64, 66, 70),
	doorFrame = Color3.fromRGB(54, 58, 64),
	doorGlass = Color3.fromRGB(156, 188, 204),
	metalSilver = Color3.fromRGB(192, 196, 202),
	pipeGray = Color3.fromRGB(138, 142, 148),
	meterBox = Color3.fromRGB(168, 174, 180),
	woodDark = Color3.fromRGB(86, 58, 38),
	woodSlat = Color3.fromRGB(112, 76, 48),
}

type BodyStyle = {
	name: string,
	body: Color3,
	trim: Color3,
	fascia: Color3,
	pillar: Color3,
	material: Enum.Material,
}

local BODY_STYLES: { BodyStyle } = {
	{
		name = "beige_stone",
		body = Color3.fromRGB(216, 202, 178),
		trim = Color3.fromRGB(172, 162, 146),
		fascia = Color3.fromRGB(88, 82, 74),
		pillar = Color3.fromRGB(190, 182, 168),
		material = Enum.Material.Limestone,
	},
	{
		name = "dark_slate",
		body = Color3.fromRGB(84, 88, 94),
		trim = Color3.fromRGB(142, 146, 152),
		fascia = Color3.fromRGB(48, 50, 56),
		pillar = Color3.fromRGB(104, 108, 114),
		material = Enum.Material.Slate,
	},
	{
		name = "red_brick",
		body = Color3.fromRGB(164, 108, 88),
		trim = Color3.fromRGB(196, 188, 176),
		fascia = Color3.fromRGB(70, 58, 52),
		pillar = Color3.fromRGB(178, 168, 156),
		material = Enum.Material.Brick,
	},
	{
		name = "gray_stucco",
		body = Color3.fromRGB(198, 200, 204),
		trim = Color3.fromRGB(144, 148, 154),
		fascia = Color3.fromRGB(68, 72, 78),
		pillar = Color3.fromRGB(176, 178, 182),
		material = Enum.Material.Concrete,
	},
	{
		name = "white_stucco",
		body = Color3.fromRGB(234, 232, 224),
		trim = Color3.fromRGB(198, 194, 186),
		fascia = Color3.fromRGB(98, 100, 106),
		pillar = Color3.fromRGB(212, 208, 200),
		material = Enum.Material.SmoothPlastic,
	},
	{
		name = "charcoal_panel",
		body = Color3.fromRGB(66, 68, 72),
		trim = Color3.fromRGB(122, 126, 132),
		fascia = Color3.fromRGB(40, 42, 46),
		pillar = Color3.fromRGB(92, 94, 98),
		material = Enum.Material.Metal,
	},
	{
		name = "beige_tile",
		body = Color3.fromRGB(218, 202, 174),
		trim = Color3.fromRGB(152, 140, 120),
		fascia = Color3.fromRGB(76, 70, 58),
		pillar = Color3.fromRGB(200, 186, 160),
		material = Enum.Material.Marble,
	},
	{
		name = "wood_curtainwall",
		body = Color3.fromRGB(92, 64, 44),
		trim = Color3.fromRGB(58, 64, 72),
		fascia = Color3.fromRGB(44, 34, 26),
		pillar = Color3.fromRGB(76, 54, 38),
		material = Enum.Material.WoodPlanks,
	},
	{
		name = "terracotta_tile",
		body = Color3.fromRGB(186, 114, 82),
		trim = Color3.fromRGB(214, 204, 188),
		fascia = Color3.fromRGB(68, 48, 40),
		pillar = Color3.fromRGB(172, 158, 144),
		material = Enum.Material.Brick,
	},
}

local STYLE_BY_NAME: { [string]: BodyStyle } = {}
for _, s in BODY_STYLES do
	STYLE_BY_NAME[s.name] = s
end

local ROOF_COLORS: { [string]: Color3 } = {
	flat = Color3.fromRGB(105, 107, 112),
	gable_green = Color3.fromRGB(48, 118, 74),
	gable_red = Color3.fromRGB(158, 56, 48),
	gable_blue = Color3.fromRGB(46, 96, 156),
	hip_dark = Color3.fromRGB(62, 66, 74),
}

local LOW_RISE_ROOF_TYPES: { string } = {
	"gable_green",
	"gable_red",
	"gable_blue",
	"hip_dark",
	"flat",
}

local SIGN_BG_COLORS: { Color3 } = {
	Color3.fromRGB(32, 52, 88), -- navy
	Color3.fromRGB(138, 34, 34), -- deep red
	Color3.fromRGB(48, 52, 58), -- charcoal
	Color3.fromRGB(36, 78, 52), -- forest green
	Color3.fromRGB(106, 68, 42), -- warm brown
}

-- 실제 상호는 Data/RoadviewShops.luau 오버레이가 record.params에 채워준다(로드뷰 검증).
-- 여기서는 검증되지 않은 건물을 위한 중립 업종 후보만 둔다(가짜 상호 대신 깔끔한 업종명).
local SUB_SIGN_CATEGORIES: { string } = {
	"명문수학 · 영어학원",
	"정하음악 · 피아노교습소",
	"바른치과의원",
	"한마음태권도장",
	"엘리트공부방",
	"강남미술학원",
	"세무회계사무소",
	"미래컴퓨터학원",
}

local SHOP_CATEGORIES: { string } = {
	"강남문구",
	"한아름분식",
	"에버빌세탁",
	"정하마트",
	"드림베이커리",
	"미소미용실",
	"잉글리시플러스",
	"예인피아노",
	"온누리약국",
	"강남공인중개사",
	"명문수학학원",
	"황금옛날치킨",
	"모모뷰티",
	"정의태권도",
	"미래컴퓨터",
	"스마일사진관",
}

local function hashKey(s: string): number
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (h * 16777619) % 4294967296
	end
	return h
end

local function autoTextColor(bg: Color3): Color3
	local lum = 0.299 * bg.R + 0.587 * bg.G + 0.114 * bg.B
	if lum > 0.62 then
		return Color3.fromRGB(26, 28, 34)
	end
	return COLORS.signText
end

local function resolveShopSign(
	recordName: string?,
	rawSign: string?,
	isVerified: boolean,
	h: number
): string
	if isVerified and rawSign and rawSign ~= "" then
		return rawSign
	end
	local s = rawSign or recordName or "상가"
	-- 미검증 번지 주소 형태("강남1길 88-7", "7-3" 등)면 중립 업종명으로 대체
	if not isVerified and string.match(s, "%d") then
		local brand = SHOP_CATEGORIES[(math.floor(h / 11) % #SHOP_CATEGORIES) + 1]
		return brand
	end
	return s
end

local function resolveStyle(_recordName: string?, paramStyle: string?, h: number): BodyStyle
	if paramStyle and STYLE_BY_NAME[paramStyle] then
		return STYLE_BY_NAME[paramStyle]
	end
	return BODY_STYLES[(h % #BODY_STYLES) + 1]
end

local function resolveRoofType(
	paramRoofType: string?,
	rawFloors: number,
	withRoofSign: boolean,
	styleName: string,
	h: number
): string
	if paramRoofType and ROOF_COLORS[paramRoofType] then
		return paramRoofType
	end
	if styleName == "wood_curtainwall" or withRoofSign then
		return "flat"
	end
	if rawFloors <= 2 then
		return LOW_RISE_ROOF_TYPES[(math.floor(h / 17) % #LOW_RISE_ROOF_TYPES) + 1]
	end
	if rawFloors == 3 and (math.floor(h / 53) % 5 == 0) then
		return "hip_dark"
	end
	return "flat"
end

-- 경사/모임 지붕 시공 (gable_green, gable_red, gable_blue, hip_dark)
local function buildPitchedOrHipRoof(
	parent: Instance,
	ox: number,
	oz: number,
	width: number,
	depth: number,
	totalHeight: number,
	roofType: string,
	trimColor: Color3
)
	local roofColor = ROOF_COLORS[roofType] or COLORS.roof
	local overhang = 0.28
	local rw = width + overhang * 2
	local rd = depth + overhang * 2
	local baseY = totalHeight + 0.18

	-- 처마 테두리 몰딩
	Geometry.box({
		name = "RoofEavesTrim",
		size = Vector3.new(rw + 0.08, 0.22, rd + 0.08),
		position = Vector3.new(ox, totalHeight + 0.11, oz),
		color = trimColor,
		parent = parent,
		material = Enum.Material.Concrete,
	})

	if roofType == "hip_dark" then
		-- 모임지붕(Hip roof): 2단 경사 매스 + 상부 용마루(RoofRidge)
		Geometry.box({
			name = "RoofSlope_1",
			size = Vector3.new(rw * 0.92, 0.52, rd * 0.92),
			position = Vector3.new(ox, baseY + 0.26, oz),
			color = roofColor,
			parent = parent,
			material = Enum.Material.Slate,
		})
		Geometry.box({
			name = "RoofSlope_2",
			size = Vector3.new(rw * 0.74, 0.48, rd * 0.74),
			position = Vector3.new(ox, baseY + 0.72, oz),
			color = roofColor,
			parent = parent,
			material = Enum.Material.Slate,
		})
		Geometry.box({
			name = "RoofRidge",
			size = Vector3.new(math.max(1.2, rw * 0.46), 0.34, math.max(1.0, rd * 0.36)),
			position = Vector3.new(ox, baseY + 1.08, oz),
			color = roofColor,
			parent = parent,
			material = Enum.Material.Slate,
		})
	else
		-- 박공지붕(Gable roof): 남·북 양면 경사판(RoofSlope_1, RoofSlope_2) + 박공벽 단차 + 용마루(RoofRidge)
		local rise = math.clamp(rd * 0.14, 0.75, 1.45)
		local halfSpan = rd / 2
		local slopeLen = math.sqrt(halfSpan * halfSpan + rise * rise)
		local pitchRad = math.atan2(rise, halfSpan)

		-- 박공 하부 계단형 채움 (지붕 아래 빈틈 방지)
		Geometry.box({
			name = "RoofGableStep_1",
			size = Vector3.new(width - 0.1, rise * 0.48, rd * 0.68),
			position = Vector3.new(ox, baseY + rise * 0.24, oz),
			color = trimColor,
			parent = parent,
			material = Enum.Material.Concrete,
		})
		Geometry.box({
			name = "RoofGableStep_2",
			size = Vector3.new(width - 0.1, rise * 0.38, rd * 0.36),
			position = Vector3.new(ox, baseY + rise * 0.62, oz),
			color = trimColor,
			parent = parent,
			material = Enum.Material.Concrete,
		})

		for idx, sz in { 1, -1 } do
			local slope = Geometry.box({
				name = string.format("RoofSlope_%d", idx),
				size = Vector3.new(rw, 0.18, slopeLen),
				position = Vector3.new(ox, baseY + rise * 0.52, oz + sz * (halfSpan * 0.48)),
				color = roofColor,
				parent = parent,
				material = Enum.Material.Metal,
			})
			slope.CFrame = slope.CFrame * CFrame.Angles(sz * pitchRad, 0, 0)
		end

		Geometry.box({
			name = "RoofRidge",
			size = Vector3.new(rw + 0.06, 0.24, 0.46),
			position = Vector3.new(ox, baseY + rise + 0.04, oz),
			color = roofColor,
			parent = parent,
			material = Enum.Material.Metal,
		})
	end
end

function Shophouse.build(record: any): Model
	local params = record.params
	local seedKey = tostring(record.id or "") .. ":" .. tostring(record.name or "Shophouse")
	local h = hashKey(seedKey)
	local isVerified: boolean = record.verified == true
	local noSign: boolean = params.noSign == true

	local signText: string = resolveShopSign(record.name, params.signText, isVerified, h)
	local style: BodyStyle = resolveStyle(record.name, params.style, h)
	local defaultSignBg = SIGN_BG_COLORS[(math.floor(h / 7) % #SIGN_BG_COLORS) + 1]
	local vertSignBg = SIGN_BG_COLORS[(math.floor(h / 13) % #SIGN_BG_COLORS) + 1]
	local subSignBg = SIGN_BG_COLORS[(math.floor(h / 23) % #SIGN_BG_COLORS) + 1]

	local floorHeight: number = params.floorHeight or 3.6
	local rawFloors: number = params.floors or 3
	local piloti: boolean = params.piloti == true
	local floors: number = math.clamp(rawFloors, if piloti then 2 else 1, 5)
	local columns: number = math.max(1, params.columns or 3)
	local facing: "south" | "north" = if params.facing == "north" then "north" else "south"
	local signBg: Color3 = params.signColor or defaultSignBg
	local withRoofSign: boolean = if params.roofSign ~= nil
		then params.roofSign == true
		else (not isVerified and not noSign and floors >= 3 and math.floor(h / 29) % 4 == 0)
	local roofType: string =
		resolveRoofType(params.roofType, rawFloors, withRoofSign, style.name, h)
	local stoneFascia: boolean = if params.stoneFascia ~= nil
		then params.stoneFascia == true
		else (style.name ~= "wood_curtainwall" and math.floor(h / 19) % 2 == 0)
	local verticalSignText: string? = if noSign
		then nil
		elseif params.verticalSign ~= nil then params.verticalSign
		elseif not isVerified and floors >= 2 and (math.floor(h / 37) % 3 == 0) then signText
		else nil
	local subSignText: string? = if noSign
		then nil
		elseif params.subSignText ~= nil then params.subSignText
		elseif
			not isVerified and floors >= 3
		then SUB_SIGN_CATEGORIES[(math.floor(h / 31) % #SUB_SIGN_CATEGORIES) + 1]
		else nil
	local withDeck: boolean = params.deck == true
	local awningColor: Color3 = params.awningColor or signBg

	local width: number = params.width
	local depth: number = params.depth
	local ox: number = params.offsetX
	local oz: number = params.offsetZ

	local model = Instance.new("Model")
	model.Name = record.name or "Shophouse"

	local totalHeight = floors * floorHeight
	local fz = if facing == "south" then oz + depth / 2 else oz - depth / 2
	local frontSignDir = if facing == "south" then 1 else -1

	if piloti then
		-- 1층은 기둥만 세우고 상층 몸통을 슬래브 위에 올린다
		local upperHeight = (floors - 1) * floorHeight
		local upperCenterY = floorHeight + upperHeight / 2
		Geometry.box({
			name = "Body",
			size = Vector3.new(width, upperHeight, depth),
			position = Vector3.new(ox, upperCenterY, oz),
			color = style.body,
			parent = model,
			material = style.material,
		})
		-- 천장 슬래브
		Geometry.box({
			name = "PilotiSlab",
			size = Vector3.new(width, 0.3, depth),
			position = Vector3.new(ox, floorHeight - 0.15, oz),
			color = style.trim,
			parent = model,
			material = Enum.Material.Concrete,
		})
		-- 필로티 기둥 (전/후 2열)
		local slots = math.max(columns, 1) + 1
		for row = 1, 2 do
			local z = if row == 1 then oz + depth / 2 - 0.4 else oz - depth / 2 + 0.4
			for i = 1, slots do
				local x = ox - width / 2 + 0.4 + (width - 0.8) * (i - 1) / (slots - 1)
				Geometry.box({
					name = "PilotiPillar",
					size = Vector3.new(0.5, floorHeight - 0.3, 0.5),
					position = Vector3.new(x, (floorHeight - 0.3) / 2, z),
					color = style.pillar,
					parent = model,
					material = Enum.Material.Concrete,
				})
			end
		end
	else
		-- 1층까지 포함한 통 몸통
		Geometry.box({
			name = "Body",
			size = Vector3.new(width, totalHeight, depth),
			position = Vector3.new(ox, totalHeight / 2, oz),
			color = style.body,
			parent = model,
			material = style.material,
		})

		-- wood_curtainwall 스타일(88-17 정상태권도 등): 1층 따뜻한 다크우드 수직 루버(WoodSlat) 클래딩
		if style.name == "wood_curtainwall" then
			local slatCount = math.clamp(math.floor(width / 0.55), 6, 24)
			for i = 1, slatCount do
				local sx = ox
					- width / 2
					+ 0.2
					+ (width - 0.4) * (i - 1) / math.max(1, slatCount - 1)
				Geometry.box({
					name = string.format("WoodSlat_%d", i),
					size = Vector3.new(0.10, floorHeight - 0.2, 0.08),
					position = Vector3.new(sx, (floorHeight - 0.2) / 2, fz + frontSignDir * 0.04),
					color = COLORS.woodSlat,
					parent = model,
					material = Enum.Material.WoodPlanks,
				})
			end
		end

		-- 1층 통유리 상가면(상가) 또는 1층 주거 창호(noSign 주택/빌라)
		local usable = math.max(width - (columns + 1) * 0.6, width * 0.6)
		local paneW = usable / columns
		if noSign then
			for _, dir in { "south", "north" } do
				local wz = if dir == "south" then oz + depth / 2 else oz - depth / 2
				Geometry.windowGrid(model, {
					name = "FirstFloor_" .. dir,
					centerX = ox,
					fz = wz,
					facing = dir :: any,
					width = width,
					floors = 1,
					floorHeight = floorHeight,
					baseY = 0,
					columns = columns,
					windowWidth = 1.6,
					windowHeight = 1.4,
					color = COLORS.window,
				})
			end
		else
			for _, dir in { "south", "north" } do
				local isPrimary = dir == facing
				local sideZ = if dir == "south" then oz + depth / 2 else oz - depth / 2
				local glassOff = if dir == "south" then 0.08 else -0.08
				local mullionOff = if dir == "south" then 0.11 else -0.11
				local prefix = if isPrimary then "Storefront" else "StorefrontBack"
				local mullionPrefix = if isPrimary then "Mullion" else "MullionBack"
				for col = 1, columns do
					local x = ox - usable / 2 + paneW * (col - 1) + paneW / 2
					Geometry.box({
						name = string.format("%s_%d", prefix, col),
						size = Vector3.new(paneW - 0.08, 2.45, 0.12),
						position = Vector3.new(x, 1.32, sideZ + glassOff),
						color = COLORS.storefront,
						parent = model,
						material = Enum.Material.Glass,
						transparency = 0.25,
						canCollide = false,
					})
				end
				for m = 0, columns do
					local mx = ox - usable / 2 + paneW * m
					Geometry.box({
						name = string.format("%s_%d", mullionPrefix, m + 1),
						size = Vector3.new(0.10, 2.55, 0.14),
						position = Vector3.new(mx, 1.32, sideZ + mullionOff),
						color = COLORS.doorFrame,
						parent = model,
						material = Enum.Material.Metal,
					})
				end
			end
		end

		-- 1층 정면 출입문 디테일: 프레임 유리 양개문(EntranceDoorFrame, EntranceDoorGlass, EntranceHandle) + 계단(EntranceStep)
		local doorW = math.min(1.6, math.max(1.1, width * 0.22))
		local doorH = 2.25
		local doorX = ox - usable / 2 + math.min(doorW * 0.65, width * 0.2)
		Geometry.box({
			name = "EntranceDoorFrame",
			size = Vector3.new(doorW, doorH, 0.16),
			position = Vector3.new(doorX, doorH / 2 + 0.12, fz + frontSignDir * 0.09),
			color = COLORS.doorFrame,
			parent = model,
			material = Enum.Material.Metal,
		})
		Geometry.box({
			name = "EntranceDoorGlass",
			size = Vector3.new(doorW - 0.18, doorH - 0.20, 0.18),
			position = Vector3.new(doorX, doorH / 2 + 0.12, fz + frontSignDir * 0.10),
			color = COLORS.doorGlass,
			parent = model,
			material = Enum.Material.Glass,
			transparency = 0.2,
			canCollide = false,
		})
		for _, hx in { -0.09, 0.09 } do
			Geometry.box({
				name = "EntranceHandle",
				size = Vector3.new(0.04, 0.36, 0.06),
				position = Vector3.new(doorX + hx, 1.15, fz + frontSignDir * 0.20),
				color = COLORS.metalSilver,
				parent = model,
				material = Enum.Material.Metal,
			})
		end
		Geometry.box({
			name = "EntranceStep",
			size = Vector3.new(doorW + 0.35, 0.14, 0.26),
			position = Vector3.new(doorX, 0.07, fz + frontSignDir * 0.13),
			color = style.trim,
			parent = model,
			material = Enum.Material.Concrete,
		})
	end

	-- 외부 수직 배수관(DrainPipe) + 전기 계량기 박스(ElectricMeter) + 벽걸이 실외기(WallAC)
	local pipeX = ox + width / 2 - 0.14
	local pipeZ = fz + frontSignDir * 0.07
	Geometry.box({
		name = "DrainPipe",
		size = Vector3.new(0.09, totalHeight - 0.2, 0.09),
		position = Vector3.new(pipeX, totalHeight / 2, pipeZ),
		color = COLORS.pipeGray,
		parent = model,
		material = Enum.Material.Metal,
	})
	local meterX = ox - width / 2 + 0.26
	local meterZ = fz + frontSignDir * 0.06
	Geometry.box({
		name = "ElectricMeter",
		size = Vector3.new(0.30, 0.44, 0.10),
		position = Vector3.new(meterX, 1.48, meterZ),
		color = COLORS.meterBox,
		parent = model,
		material = Enum.Material.Metal,
	})
	Geometry.box({
		name = "ElectricMeterWindow",
		size = Vector3.new(0.18, 0.14, 0.12),
		position = Vector3.new(meterX, 1.56, meterZ + frontSignDir * 0.01),
		color = COLORS.window,
		parent = model,
		material = Enum.Material.Glass,
		transparency = 0.2,
		canCollide = false,
	})
	-- 벽면 부착형 에어컨 실외기 (WallAC: 벽에서 0.28m 이내 돌출)
	local wallAcY = if floors >= 2 then floorHeight + 0.65 else 2.25
	local wallAcX = ox + width / 2 - 0.75
	local wallAcZ = oz - frontSignDir * (depth / 2 + 0.14)
	Geometry.box({
		name = "WallAC",
		size = Vector3.new(0.76, 0.54, 0.26),
		position = Vector3.new(wallAcX, wallAcY, wallAcZ),
		color = COLORS.acBody,
		parent = model,
		material = Enum.Material.Metal,
	})
	Geometry.box({
		name = "WallACGrille",
		size = Vector3.new(0.46, 0.42, 0.28),
		position = Vector3.new(wallAcX - 0.10, wallAcY, wallAcZ),
		color = COLORS.acGrille,
		parent = model,
		material = Enum.Material.Metal,
	})

	-- 층간 띠 몰딩 (Cornice / Floor Band)
	for f = 1, floors - 1 do
		Geometry.box({
			name = string.format("FloorBand_%d", f),
			size = Vector3.new(width + 0.16, 0.2, depth + 0.16),
			position = Vector3.new(ox, f * floorHeight, oz),
			color = style.trim,
			parent = model,
			material = Enum.Material.Concrete,
		})
	end

	-- 상단 코니스 트림 (옥상 슬래브 하단 몰딩)
	Geometry.box({
		name = "CorniceTrim",
		size = Vector3.new(width + 0.32, 0.26, depth + 0.32),
		position = Vector3.new(ox, totalHeight - 0.13, oz),
		color = style.trim,
		parent = model,
		material = Enum.Material.Concrete,
	})

	-- 1층 정면·배면 파시아 프레임 + 어닝 + 간판 보드 (돌출 폭 0.30m 이하 유지)
	local hasMainSign: boolean = not noSign
		and (not isVerified or (params.signText ~= nil and params.signText ~= ""))
	local fasciaColor = if stoneFascia then Color3.fromRGB(62, 60, 58) else style.fascia
	local fasciaMat = if stoneFascia then Enum.Material.Slate else Enum.Material.Concrete
	if noSign then
		-- 순수 주택/빌라/관리동: 빌라 현판명이 있으면 출입구 상단에 깔끔한 명패만 부착
		if params.signText and params.signText ~= "" then
			local sideZ = if facing == "south" then oz + depth / 2 else oz - depth / 2
			local signDir = if facing == "south" then 1 else -1
			local dirRotY = if facing == "south" then 0 else 180
			Geometry.sign(model, {
				name = "BuildingNameplate",
				size = Vector3.new(math.min(width * 0.45, 3.2), 0.65, 0.12),
				position = Vector3.new(ox, floorHeight - 0.55, sideZ + signDir * 0.14),
				text = params.signText,
				textColor = autoTextColor(signBg),
				backgroundColor = signBg,
				rotationY = dirRotY,
			})
		end
	else
		for _, dir in { "south", "north" } do
			local isPrimary = dir == facing
			local sideZ = if dir == "south" then oz + depth / 2 else oz - depth / 2
			local signDir = if dir == "south" then 1 else -1
			local dirRotY = if dir == "south" then 0 else 180

			-- 파시아 배경 프레임 (StoneFrame / StoneFrame_Back)
			Geometry.box({
				name = if isPrimary then "StoneFrame" else "StoneFrame_Back",
				size = Vector3.new(width + 0.08, 1.22, 0.18),
				position = Vector3.new(ox, floorHeight - 0.68, sideZ + signDir * 0.09),
				color = fasciaColor,
				parent = model,
				material = fasciaMat,
			})

			-- 어닝/캐노피 바 (벽면에서 최대 0.30m 이내)
			Geometry.box({
				name = if isPrimary then "Awning" else "Awning_Back",
				size = Vector3.new(width * 0.92, 0.16, 0.28),
				position = Vector3.new(ox, floorHeight - 1.34, sideZ + signDir * 0.16),
				color = awningColor,
				parent = model,
				material = Enum.Material.SmoothPlastic,
			})

			-- 1층 간판 보드 (벽면에서 0.28m 이내; shopSigns 배열이 있으면 다중 점포 분할 배치)
			local shopSigns = params.shopSigns
			if not noSign and type(shopSigns) == "table" and #shopSigns > 1 then
				local nSigns = #shopSigns
				local totalSpan = width * 0.92
				local slotW = totalSpan / nSigns
				for sIdx, sText in shopSigns do
					local sx = ox - totalSpan / 2 + slotW * (sIdx - 0.5)
					local slotBg = if sIdx == 1
						then signBg
						else SIGN_BG_COLORS[((math.floor(h / 7) + sIdx) % #SIGN_BG_COLORS) + 1]
					Geometry.sign(model, {
						name = string.format(
							"%s_%d",
							if isPrimary then "ShopSign" else "ShopSign_Back",
							sIdx
						),
						size = Vector3.new(slotW - 0.14, 0.96, 0.14),
						position = Vector3.new(sx, floorHeight - 0.68, sideZ + signDir * 0.20),
						text = tostring(sText),
						textColor = autoTextColor(slotBg),
						backgroundColor = slotBg,
						rotationY = dirRotY,
					})
				end
			elseif hasMainSign then
				Geometry.sign(model, {
					name = if isPrimary then "ShopSign" else "ShopSign_Back",
					size = Vector3.new(width * 0.88, 0.96, 0.14),
					position = Vector3.new(ox, floorHeight - 0.68, sideZ + signDir * 0.20),
					text = signText,
					textColor = autoTextColor(signBg),
					backgroundColor = signBg,
					rotationY = dirRotY,
				})
			end

			-- 2층 띠간판 (SubShopSign: 다층 상가의 학원·의원·태권도장 등, Y = floorHeight * 2 - 0.65)
			if floors >= 2 and subSignText then
				Geometry.sign(model, {
					name = if isPrimary then "SubShopSign" else "SubShopSign_Back",
					size = Vector3.new(width * 0.86, 0.82, 0.14),
					position = Vector3.new(ox, floorHeight * 2 - 0.65, sideZ + signDir * 0.18),
					text = subSignText,
					textColor = autoTextColor(subSignBg),
					backgroundColor = subSignBg,
					rotationY = dirRotY,
				})
			end
		end

		-- 동/서 측면(남북 도로변 상가의 정면 역할)에도 파시아·간판·1층 유리창·2층 띠간판 배치
		for _, side in { "west", "east" } do
			local sx = if side == "east" then 1 else -1
			local sideX = ox + sx * (width / 2)
			Geometry.box({
				name = "StoneFrame_" .. side,
				size = Vector3.new(0.18, 1.22, depth + 0.08),
				position = Vector3.new(sideX + sx * 0.09, floorHeight - 0.68, oz),
				color = fasciaColor,
				parent = model,
				material = fasciaMat,
			})
			if hasMainSign then
				Geometry.sign(model, {
					name = "ShopSign_" .. side,
					size = Vector3.new(depth * 0.86, 0.96, 0.14),
					position = Vector3.new(sideX + sx * 0.20, floorHeight - 0.68, oz),
					text = signText,
					textColor = autoTextColor(signBg),
					backgroundColor = signBg,
					rotationY = 90,
				})
			end
			if floors >= 2 and subSignText then
				Geometry.sign(model, {
					name = "SubShopSign_" .. side,
					size = Vector3.new(depth * 0.84, 0.82, 0.14),
					position = Vector3.new(sideX + sx * 0.18, floorHeight * 2 - 0.65, oz),
					text = subSignText,
					textColor = autoTextColor(subSignBg),
					backgroundColor = subSignBg,
					rotationY = 90,
				})
			end
			if not piloti then
				Geometry.box({
					name = "Storefront_" .. side,
					size = Vector3.new(0.12, 2.45, math.max(depth * 0.72, 2.0)),
					position = Vector3.new(sideX + sx * 0.08, 1.32, oz),
					color = COLORS.storefront,
					parent = model,
					material = Enum.Material.Glass,
					transparency = 0.25,
					canCollide = false,
				})
			end
		end
	end

	-- 세로 간판 (벽면에서 0.28m 이내 돌출로 인접 건물 충돌 방지)
	if verticalSignText and floors >= 2 then
		local vHeight = math.min(floorHeight * 1.7, totalHeight - 1.1)
		Geometry.sign(model, {
			name = "VerticalSign",
			size = Vector3.new(0.56, vHeight, 0.18),
			position = Vector3.new(
				ox + width / 2 + 0.16,
				floorHeight + vHeight * 0.35,
				fz - frontSignDir * 0.42
			),
			text = verticalSignText :: string,
			textColor = COLORS.signText,
			backgroundColor = vertSignBg,
			rotationY = 90,
		})
	end

	-- 전면 목재 데크 + 난간 (정면 도로 방향에만 배치, 벽면에서 0.32m 이내)
	if withDeck then
		local deckDepth = 0.30
		local dz = if facing == "south"
			then depth / 2 + deckDepth / 2
			else -depth / 2 - deckDepth / 2
		Geometry.box({
			name = "Deck",
			size = Vector3.new(width * 0.78, 0.15, deckDepth),
			position = Vector3.new(ox, 0.08, oz + dz),
			color = Color3.fromRGB(146, 110, 72),
			parent = model,
			material = Enum.Material.WoodPlanks,
		})
		Geometry.box({
			name = "DeckRail",
			size = Vector3.new(width * 0.78, 0.82, 0.08),
			position = Vector3.new(
				ox,
				0.50,
				oz + dz + if facing == "south" then deckDepth / 2 - 0.04 else -deckDepth / 2 + 0.04
			),
			color = Color3.fromRGB(120, 90, 60),
			parent = model,
			material = Enum.Material.Wood,
		})
	end

	-- 2층 이상 상층부: wood_curtainwall 스타일이면 청색 반사유리 커튼월, 아니면 일반 창호 그리드
	if floors >= 2 then
		if style.name == "wood_curtainwall" then
			local cwHeight = (floors - 1) * floorHeight - 0.55
			local cwCenterY = floorHeight + cwHeight / 2 + 0.12
			local cwWidth = width * 0.90
			for _, dir in { "south", "north" } do
				local sideZ = if dir == "south" then oz + depth / 2 else oz - depth / 2
				local signDir = if dir == "south" then 1 else -1
				Geometry.box({
					name = "CurtainWallGlass_" .. dir,
					size = Vector3.new(cwWidth, cwHeight, 0.12),
					position = Vector3.new(ox, cwCenterY, sideZ + signDir * 0.07),
					color = COLORS.curtainGlass,
					parent = model,
					material = Enum.Material.Glass,
					transparency = 0.18,
					canCollide = false,
				})
				local mullions = columns + 1
				for m = 0, mullions do
					local mx = ox - cwWidth / 2 + (cwWidth / mullions) * m
					Geometry.box({
						name = string.format("CurtainWallMullion_%s_%d", dir, m + 1),
						size = Vector3.new(0.08, cwHeight + 0.06, 0.15),
						position = Vector3.new(mx, cwCenterY, sideZ + signDir * 0.09),
						color = COLORS.doorFrame,
						parent = model,
						material = Enum.Material.Metal,
					})
				end
			end
		end

		for _, dir in { "south", "north" } do
			local wz = if dir == "south" then oz + depth / 2 else oz - depth / 2
			Geometry.windowGrid(model, {
				name = "Upper_" .. dir,
				centerX = ox,
				fz = wz,
				facing = dir :: any,
				width = width,
				floors = floors - 1,
				floorHeight = floorHeight,
				baseY = floorHeight,
				columns = columns,
				windowWidth = 1.8,
				windowHeight = 1.6,
				color = if style.name == "wood_curtainwall"
					then COLORS.curtainGlass
					else COLORS.window,
			})
		end
		local sideCols = math.max(2, math.floor(depth / 3.8))
		for _, dir in { "west", "east" } do
			local wx = if dir == "east" then ox + width / 2 else ox - width / 2
			Geometry.windowGrid(model, {
				name = "Upper_" .. dir,
				centerX = ox,
				fz = oz,
				centerZ = oz,
				fx = wx,
				facing = dir :: any,
				width = depth,
				floors = floors - 1,
				floorHeight = floorHeight,
				baseY = floorHeight,
				columns = sideCols,
				windowWidth = 1.8,
				windowHeight = 1.6,
				color = if style.name == "wood_curtainwall"
					then COLORS.curtainGlass
					else COLORS.window,
			})
		end
	end

	-- 옥상 바닥 마감 캡
	Geometry.box({
		name = "RoofCap",
		size = Vector3.new(width + 0.3, 0.18, depth + 0.3),
		position = Vector3.new(ox, totalHeight + 0.09, oz),
		color = ROOF_COLORS[roofType] or COLORS.roof,
		parent = model,
		material = Enum.Material.Concrete,
	})

	if roofType == "flat" then
		-- 평지붕: 옥상 파라펫 + 계단실
		local parapet = 0.9
		local edges = {
			{ size = Vector3.new(width, parapet, 0.3), off = Vector3.new(0, 0, depth / 2) },
			{ size = Vector3.new(width, parapet, 0.3), off = Vector3.new(0, 0, -depth / 2) },
			{ size = Vector3.new(0.3, parapet, depth), off = Vector3.new(width / 2, 0, 0) },
			{ size = Vector3.new(0.3, parapet, depth), off = Vector3.new(-width / 2, 0, 0) },
		}
		for _, edge in edges do
			Geometry.box({
				name = "Parapet",
				size = edge.size,
				position = Vector3.new(ox, totalHeight + parapet / 2, oz) + edge.off,
				color = style.trim,
				parent = model,
				material = Enum.Material.Concrete,
			})
		end

		if floors >= 2 then
			Geometry.box({
				name = "Stairhouse",
				size = Vector3.new(math.min(3, width * 0.4), 2.4, math.min(4, depth * 0.5)),
				position = Vector3.new(ox + width * 0.22, totalHeight + 1.2, oz),
				color = style.trim,
				parent = model,
				material = Enum.Material.Concrete,
			})
		end
	else
		-- 경사/모임 지붕 (gable_green, gable_red, gable_blue, hip_dark)
		buildPitchedOrHipRoof(model, ox, oz, width, depth, totalHeight, roofType, style.trim)
	end

	-- 옥상 실외기 (AC outdoor units: 해시 기반 1~2기 배치)
	local acCount = 1 + (math.floor(h / 43) % 2)
	local acBaseX = ox - width * 0.25
	local acBaseZ = oz - depth * 0.18
	for i = 1, acCount do
		local acX = acBaseX + (i - 1) * 1.15
		local acY = totalHeight + 0.18 + 0.42
		Geometry.box({
			name = string.format("ACUnit_%d", i),
			size = Vector3.new(0.9, 0.84, 0.45),
			position = Vector3.new(acX, acY, acBaseZ),
			color = COLORS.acBody,
			parent = model,
			material = Enum.Material.Metal,
		})
		Geometry.box({
			name = string.format("ACGrille_%d", i),
			size = Vector3.new(0.52, 0.52, 0.06),
			position = Vector3.new(acX - 0.1, acY + 0.04, acBaseZ + 0.24),
			color = COLORS.acGrille,
			parent = model,
			material = Enum.Material.Metal,
		})
	end

	-- 옥상 간판 기둥 2개
	if withRoofSign then
		for _, sx in { 1, -1 } do
			Geometry.box({
				name = "RoofSignPole",
				size = Vector3.new(0.25, 2.5, 0.25),
				position = Vector3.new(ox + sx * width * 0.3, totalHeight + 1.25, oz),
				color = COLORS.roof,
				parent = model,
				material = Enum.Material.Metal,
			})
		end
	end

	-- 교회 첨탑 및 십자가 (강남1길 88-7 안동강남교회 등: 북동/북서 도로변 코너에 벽돌 탑신 + 청색 세로창 + 노란 첨탑 + 십자가)
	if params.spire == true then
		local towerW = 2.6
		local towerH = totalHeight + 2.4
		local tx = ox + width / 2 - towerW / 2 - 0.1
		local tz = oz - depth / 2 + towerW / 2 + 0.1
		Geometry.box({
			name = "SpireTower",
			size = Vector3.new(towerW, towerH, towerW),
			position = Vector3.new(tx, towerH / 2, tz),
			color = Color3.fromRGB(168, 126, 96),
			parent = model,
			material = Enum.Material.Brick,
		})
		Geometry.box({
			name = "SpireCornerGlass",
			size = Vector3.new(1.5, towerH - 2.2, 0.16),
			position = Vector3.new(tx, towerH / 2 + 0.3, tz - towerW / 2 - 0.06),
			color = Color3.fromRGB(48, 108, 168),
			parent = model,
			material = Enum.Material.Glass,
			transparency = 0.18,
			canCollide = false,
		})
		-- 노란색 3단 피라미드 첨탑
		local spireColor = Color3.fromRGB(232, 184, 42)
		for step = 1, 3 do
			local sw = towerW * (1.0 - (step - 1) * 0.28)
			local sh = 1.25
			Geometry.box({
				name = string.format("SpireCone_%d", step),
				size = Vector3.new(sw, sh, sw),
				position = Vector3.new(tx, towerH + (step - 0.5) * sh, tz),
				color = spireColor,
				parent = model,
				material = Enum.Material.Metal,
			})
		end
		-- 상단 십자가
		local crossBaseY = towerH + 3.75
		Geometry.box({
			name = "SpireCrossVert",
			size = Vector3.new(0.18, 1.8, 0.18),
			position = Vector3.new(tx, crossBaseY + 0.9, tz),
			color = Color3.fromRGB(242, 242, 238),
			parent = model,
			material = Enum.Material.Neon,
		})
		Geometry.box({
			name = "SpireCrossHoriz",
			size = Vector3.new(1.1, 0.18, 0.18),
			position = Vector3.new(tx, crossBaseY + 1.2, tz),
			color = Color3.fromRGB(242, 242, 238),
			parent = model,
			material = Enum.Material.Neon,
		})
	end

	model:SetAttribute("blockId", record.id)
	model:SetAttribute("verified", record.verified == true)

	return model
end

return Shophouse
