--!strict
-- Apartment kit: low-rise corridor block (3~5F).
-- Origin = school gate, +X east, +Z south. Units in meters.
-- params: offsetX, offsetZ, width, depth, floors (3~15, 타워 포함), floorHeight (default 3.0),
-- unitsPerFloor, name, number ("101"), corePosition ("center" | "side"),
-- balcony (bool), palette ("brick" | "beige" | "gray"), entranceCanopy (bool).

local Geometry = require(script.Parent.Parent.Geometry)

local Apartment = {}

local PALETTES = {
	brick = {
		body = Color3.fromRGB(228, 230, 232),
		trim = Color3.fromRGB(210, 212, 216),
		band = Color3.fromRGB(186, 190, 196),
		window = Color3.fromRGB(96, 124, 142),
	},
	beige = {
		body = Color3.fromRGB(228, 230, 232),
		trim = Color3.fromRGB(212, 214, 218),
		band = Color3.fromRGB(188, 192, 198),
		window = Color3.fromRGB(96, 124, 142),
	},
	gray = {
		body = Color3.fromRGB(228, 230, 232),
		trim = Color3.fromRGB(208, 212, 216),
		band = Color3.fromRGB(184, 188, 194),
		window = Color3.fromRGB(92, 120, 138),
	},
}

local PALETTE_KEYS = { "beige", "gray", "brick" }

local GABLE_THEMES = {
	{
		name = "sky_blue",
		stripe = Color3.fromRGB(148, 186, 212),
		motto = "Heritage\nTown",
		mottoText = Color3.fromRGB(46, 62, 78),
	},
	{
		name = "rose_pink",
		stripe = Color3.fromRGB(208, 152, 168),
		motto = "Beautiful\nPeople",
		mottoText = Color3.fromRGB(58, 48, 54),
	},
	{
		name = "sage_green",
		stripe = Color3.fromRGB(156, 184, 168),
		motto = "Wellbeing\nLife",
		mottoText = Color3.fromRGB(44, 62, 52),
	},
}

local BRAND_FALLBACKS = {
	{ text = "석미한아름", color = Color3.fromRGB(52, 86, 72) },
	{ text = "현진에버빌", color = Color3.fromRGB(38, 74, 62) },
	{ text = "화성드림파크", color = Color3.fromRGB(42, 68, 104) },
}

local function hashKey(s: string): number
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (h * 16777619) % 4294967296
	end
	return h
end

local function resolveBrand(rawName: string, explicitBrand: string?, h: number): (string, Color3)
	if explicitBrand and #explicitBrand > 0 then
		return explicitBrand, Color3.fromRGB(42, 68, 104)
	end
	if string.find(rawName, "현진에버빌") then
		return "현진에버빌", Color3.fromRGB(38, 74, 62)
	elseif string.find(rawName, "석미한아름") then
		return "석미한아름", Color3.fromRGB(52, 86, 72)
	elseif string.find(rawName, "화성드림파크") then
		return "화성드림파크", Color3.fromRGB(42, 68, 104)
	end
	local fallback = BRAND_FALLBACKS[(h % #BRAND_FALLBACKS) + 1]
	return fallback.text, fallback.color
end

local function resolveGableTheme(rawName: string, h: number)
	if string.find(rawName, "103") then
		return GABLE_THEMES[1]
	elseif string.find(rawName, "102") then
		return GABLE_THEMES[2]
	elseif string.find(rawName, "101") then
		return GABLE_THEMES[3]
	end
	return GABLE_THEMES[(h % #GABLE_THEMES) + 1]
end

function Apartment.build(record: any): Model
	local params = record.params
	local rawName: string = tostring(params.name or record.name or "Apartment")
	local seedKey = tostring(record.id or "") .. ":" .. rawName
	local h = hashKey(seedKey)

	local offsetX: number = params.offsetX or 0
	local offsetZ: number = params.offsetZ or 0
	local width: number = params.width or 24
	local depth: number = params.depth or 9
	local floorHeight: number = params.floorHeight or 3.0
	local rawFloors: number = params.floors or 5
	local floors: number = math.clamp(rawFloors, 3, 15)
	local unitsPerFloor: number = params.unitsPerFloor or 2
	local corePosition: string = params.corePosition or "center"

	-- palette가 명시되지 않았거나 VWorld 자동생성 기본값("gray", verified ~= true)인 경우 결정론적 팔레트 배정
	local hasExplicitPalette = params.palette ~= nil
		and not (record.source == "vworld" and params.palette == "gray" and record.verified ~= true)
	local paletteKey: string = if hasExplicitPalette
		then params.palette
		else PALETTE_KEYS[(h % #PALETTE_KEYS) + 1]
	local palette = PALETTES[paletteKey] or PALETTES.beige

	local parsedDong = string.match(rawName, "(%d+)동")
	local numberText: string = if parsedDong
		then parsedDong
		elseif params.number and record.source ~= "vworld" then tostring(params.number)
		else tostring(101 + (h % 3))
	local doBalcony: boolean = if params.balcony == nil then true else params.balcony
	local doCanopy: boolean = if params.entranceCanopy == nil then true else params.entranceCanopy

	local height = floors * floorHeight
	local model = Instance.new("Model")
	model.Name = rawName

	-- Main slab (clean off-white / light-gray Korean apartment wall)
	Geometry.box({
		name = "Body",
		size = Vector3.new(width, height, depth),
		position = Vector3.new(offsetX, height / 2, offsetZ),
		color = palette.body,
		parent = model,
		material = Enum.Material.Concrete,
	})

	-- 층간 수평 띠 (남/북 장변 파사드 몰딩, 동/서 박공벽 수직 액센트 침범 방지)
	for f = 1, floors - 1 do
		local isAccentBand = (f == 1) or (f == floors - 1 and floors >= 6)
		local bandH = if isAccentBand then 0.26 else 0.16
		local bandPad = if isAccentBand then 0.22 else 0.12
		Geometry.box({
			name = string.format("FloorBand_%d", f),
			size = Vector3.new(math.max(width - 0.1, 1), bandH, depth + bandPad),
			position = Vector3.new(offsetX, f * floorHeight, offsetZ),
			color = if isAccentBand then palette.band else palette.trim,
			parent = model,
			material = Enum.Material.Concrete,
		})
	end

	-- 좌우 측벽(동/서 박공벽) 전고 수직 파스텔 액센트 스트라이프 (depth * 0.42)
	local gableTheme = resolveGableTheme(rawName, h)
	local stripeDepth = depth * 0.42
	local stripeZ = offsetZ - depth * 0.22
	for _, side in { { name = "East", dir = 1 }, { name = "West", dir = -1 } } do
		Geometry.box({
			name = "SideAccent_" .. side.name,
			size = Vector3.new(0.16, height, stripeDepth),
			position = Vector3.new(offsetX + side.dir * (width / 2 + 0.08), height / 2, stripeZ),
			color = gableTheme.stripe,
			parent = model,
			material = Enum.Material.Concrete,
		})
	end

	-- Living-room window grids (south + north)
	Geometry.windowGrid(model, {
		name = "Win_south",
		centerX = offsetX,
		fz = offsetZ + depth / 2,
		facing = "south",
		width = width,
		floors = floors,
		floorHeight = floorHeight,
		baseY = 0,
		columns = unitsPerFloor,
		windowWidth = 3.0,
		windowHeight = 1.8,
		color = palette.window,
	})
	Geometry.windowGrid(model, {
		name = "Win_north",
		centerX = offsetX,
		fz = offsetZ - depth / 2,
		facing = "north",
		width = width,
		floors = floors,
		floorHeight = floorHeight,
		baseY = 0,
		columns = unitsPerFloor,
		windowWidth = 3.0,
		windowHeight = 1.8,
		color = palette.window,
	})

	-- Balconies: front slabs + clean light spandrel rails
	if doBalcony then
		for f = 1, floors do
			local slabY = (f - 1) * floorHeight + 0.15
			Geometry.box({
				name = string.format("Balcony_%d", f),
				size = Vector3.new(width, 0.3, 1.5),
				position = Vector3.new(offsetX, slabY, offsetZ + depth / 2 + 0.75),
				color = palette.trim,
				parent = model,
				material = Enum.Material.Concrete,
			})
			Geometry.box({
				name = string.format("Rail_%d", f),
				size = Vector3.new(width, 1.1, 0.15),
				position = Vector3.new(offsetX, slabY + 0.7, offsetZ + depth / 2 + 1.42),
				color = palette.body,
				parent = model,
				material = Enum.Material.Concrete,
				canCollide = false,
			})
		end
	end

	-- Stair core (1m proud of facade) + vertical strip window
	local coreW = 4
	local coreD = 2.0
	local coreX = if corePosition == "side" then offsetX + width / 2 - coreW / 2 else offsetX
	local coreZ = offsetZ + depth / 2
	Geometry.box({
		name = "Core",
		size = Vector3.new(coreW, height, coreD),
		position = Vector3.new(coreX, height / 2, coreZ),
		color = palette.trim,
		parent = model,
		material = Enum.Material.Concrete,
	})
	Geometry.box({
		name = "CoreWindow",
		size = Vector3.new(1.2, height - 2.0, 0.16),
		position = Vector3.new(coreX, height / 2, coreZ + coreD / 2 + 0.08),
		color = palette.window,
		parent = model,
		material = Enum.Material.Glass,
		transparency = 0.25,
		canCollide = false,
	})

	-- Entrance canopy + building number sign
	local brandText, brandColor = resolveBrand(rawName, params.brandSign, h)
	if doCanopy then
		Geometry.box({
			name = "Canopy",
			size = Vector3.new(5, 0.3, 2.2),
			position = Vector3.new(coreX, 2.9, offsetZ + depth / 2 + 1.1),
			color = palette.trim,
			parent = model,
			material = Enum.Material.Concrete,
		})
	end
	Geometry.sign(model, {
		name = "DongSign",
		size = Vector3.new(3.0, 1.0, 0.3),
		position = Vector3.new(coreX, 3.8, coreZ + coreD / 2 + 0.15),
		text = numberText .. "동",
		textColor = Color3.fromRGB(255, 255, 255),
		backgroundColor = brandColor,
	})

	-- 동/서 박공벽 상단: 브랜드 사인 + 동 번호("101", "102", "103") + 영문 슬로건("Heritage\nTown" 등)
	local sideSignW = math.clamp(depth * 0.65, 4.8, 9.8)
	local sideBrandY = math.max(height - 2.0, height * 0.85)
	local sideDongY = math.max(sideBrandY - 2.0, height * 0.72)
	local sideMottoY = math.max(sideDongY - 2.5, height * 0.55)
	for _, side in { { name = "East", dir = 1 }, { name = "West", dir = -1 } } do
		local signX = offsetX + side.dir * (width / 2 + 0.24)
		Geometry.sign(model, {
			name = "BrandSign_" .. side.name,
			size = Vector3.new(sideSignW, 1.5, 0.22),
			position = Vector3.new(signX, sideBrandY, offsetZ),
			text = brandText,
			textColor = Color3.fromRGB(250, 250, 246),
			backgroundColor = brandColor,
			rotationY = 90,
		})
		Geometry.sign(model, {
			name = "SideDong_" .. side.name,
			size = Vector3.new(math.clamp(depth * 0.34, 3.0, 4.8), 1.35, 0.22),
			position = Vector3.new(signX, sideDongY, offsetZ),
			text = numberText,
			textColor = Color3.fromRGB(250, 250, 248),
			backgroundColor = brandColor,
			rotationY = 90,
		})
		Geometry.sign(model, {
			name = "MottoSign_" .. side.name,
			size = Vector3.new(sideSignW, 2.4, 0.22),
			position = Vector3.new(signX, sideMottoY, offsetZ),
			text = gableTheme.motto,
			textColor = gableTheme.mottoText,
			backgroundColor = gableTheme.stripe,
			rotationY = 90,
		})
	end

	-- 남/북 파사드 상단: 브랜드 사인 + 동 번호 사인
	local roofSignW = math.clamp(width * 0.26, 6.0, 13.5)
	local facadeDongW = math.clamp(width * 0.11, 3.2, 5.2)
	local facadeDongX = offsetX + math.min(width * 0.32, width / 2 - facadeDongW / 2 - 1.2)
	for _, face in { { name = "South", dir = 1, rot = 0 }, { name = "North", dir = -1, rot = 180 } } do
		local faceZ = offsetZ
			+ face.dir * (depth / 2 + if face.dir == 1 and doBalcony then 1.58 else 0.28)
		Geometry.sign(model, {
			name = "BrandSign_" .. face.name,
			size = Vector3.new(roofSignW, 1.5, 0.24),
			position = Vector3.new(offsetX, height + 0.45, faceZ),
			text = brandText,
			textColor = Color3.fromRGB(250, 250, 246),
			backgroundColor = brandColor,
			rotationY = face.rot,
		})
		Geometry.sign(model, {
			name = "FacadeDong_" .. face.name,
			size = Vector3.new(facadeDongW, 1.4, 0.24),
			position = Vector3.new(facadeDongX, height - 1.2, faceZ),
			text = numberText,
			textColor = Color3.fromRGB(250, 250, 248),
			backgroundColor = brandColor,
			rotationY = face.rot,
		})
	end

	-- Roof parapet
	local parapet = 0.6
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
			position = Vector3.new(offsetX, height + parapet / 2, offsetZ) + edge.off,
			color = palette.trim,
			parent = model,
			material = Enum.Material.Concrete,
		})
	end

	-- 옥상 상단 크라운 띠 (Roof Crown Band)
	Geometry.box({
		name = "RoofCrown",
		size = Vector3.new(width + 0.36, 0.28, depth + 0.36),
		position = Vector3.new(offsetX, height + parapet - 0.12, offsetZ),
		color = palette.band,
		parent = model,
		material = Enum.Material.Concrete,
	})

	-- 로드뷰 아파트 특유의 다크 슬레이트/녹회색 박공·모임지붕 캡 (RoofCap + 중앙 용마루 RoofRidge)
	Geometry.box({
		name = "RoofCap",
		size = Vector3.new(width + 0.5, 1.0, depth + 0.5),
		position = Vector3.new(offsetX, height + parapet + 0.5, offsetZ),
		color = Color3.fromRGB(76, 88, 86),
		parent = model,
		material = Enum.Material.Slate,
	})
	Geometry.box({
		name = "RoofRidge",
		size = Vector3.new(math.max(width - 2.4, width * 0.84), 0.95, depth * 0.56),
		position = Vector3.new(offsetX, height + parapet + 1.45, offsetZ),
		color = Color3.fromRGB(64, 76, 74),
		parent = model,
		material = Enum.Material.Slate,
	})

	-- Elevator machine room
	Geometry.box({
		name = "MachineRoom",
		size = Vector3.new(3.5, 2.2, 3.0),
		position = Vector3.new(offsetX - width * 0.25, height + parapet + 1.8, offsetZ),
		color = palette.trim,
		parent = model,
		material = Enum.Material.Concrete,
	})

	model:SetAttribute("blockId", record.id)
	model:SetAttribute("verified", record.verified == true)

	return model
end

return Apartment
