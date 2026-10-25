--!strict
-- 데이터 → 인스턴스 변환기. 빌더는 데이터만 읽고, 여기서만 파트를 만든다.

local Config = require(script.Parent.Parent.Config)
local Geometry = require(script.Parent.Geometry)
local School = require(script.Parent.Kits.School)
local Shophouse = require(script.Parent.Kits.Shophouse)
local Apartment = require(script.Parent.Kits.Apartment)
local Roadside = require(script.Parent.Kits.Roadside)
local Street = require(script.Parent.Kits.Street)
local Interior = require(script.Parent.Kits.Interior)
local Blocks = require(script.Parent.Parent.Data.Blocks)
local Streets = require(script.Parent.Parent.Data.Streets)
local VWorldBlocks = require(script.Parent.Parent.Data.VWorldBlocks)
local RoadviewShops = require(script.Parent.Parent.Data.RoadviewShops)

local Builder = {}

-- 빌드 단계: school → streets(랜드마크) → sample → full 순서로 검증하며 올린다.
-- 2026-10-24: VWorld 회전각(90도 오차) 및 정문·교사동 배치 수정 완료 → full 빌드 활성화.
local STAGE: string = "full"

type Kit = (any) -> Model

local KITS: { [string]: Kit } = {
	school = School.build,
	shophouse = Shophouse.build,
	apartment = Apartment.build,
	lamp = Roadside.build,
	pole = Roadside.build,
	tree = Roadside.build,
	busstop = Roadside.build,
	classroom = Interior.buildClassroom,
	aptcore = Interior.buildAptCore,
}

local function resetFolder(): Folder
	local existing = workspace:FindFirstChild(Config.DistrictFolderName)
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = Config.DistrictFolderName
	folder.Parent = workspace
	return folder
end

-- VWorld 회전각 적용: 모델 전체를 기록 중심축 기준으로 Y 회전.
-- (키트는 축정렬로 만들고 여기서 한 번에 돌린다)
local function applyRotation(model: Model, record: any)
	local rot = record.rotationY
	if rot == nil or rot == 0 then
		return
	end
	local ox = record.params.offsetX or 0
	local oz = record.params.offsetZ or 0
	local spm = Config.StudsPerMeter
	local pivot = CFrame.new(ox * spm, 0, oz * spm)
	local r = CFrame.Angles(0, math.rad(rot), 0)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame = pivot * r * (pivot:Inverse() * d.CFrame)
		end
	end
end

local function buildStreets(parent: Instance)
	for _, params in Streets do
		local road = Street.build(params)
		road.Parent = parent
	end
end

-- 로드뷰 검증 팩트 오버레이(RoadviewShops) → record.params 병합.
-- vworld_import.py 재생성 후에도 상호/외장/verified가 유지되도록 빌드 시점에 적용한다.
local function mergeRoadviewFacts(records: { any }): number
	local merged = 0
	for _, record in records do
		local facts = RoadviewShops[record.id] or RoadviewShops[record.name]
		if facts then
			local p = record.params
			if p then
				if facts.sign ~= nil then
					p.signText = if facts.sign ~= "" then facts.sign else nil
				end
				if facts.shopSigns ~= nil then
					p.shopSigns = facts.shopSigns
				end
				if facts.subSign ~= nil then
					p.subSignText = if facts.subSign ~= "" then facts.subSign else nil
				end
				if facts.verticalSign ~= nil then
					p.verticalSign = if facts.verticalSign ~= "" then facts.verticalSign else nil
				end
				if facts.style then
					p.style = facts.style
				end
				if facts.roofType then
					p.roofType = facts.roofType
				end
				if facts.signColor then
					p.signColor = facts.signColor
				end
				if facts.awningColor then
					p.awningColor = facts.awningColor
				end
				if facts.floors then
					p.floors = facts.floors
				end
				if facts.piloti ~= nil then
					p.piloti = facts.piloti
				end
				if facts.deck ~= nil then
					p.deck = facts.deck
				end
				if facts.stoneFascia ~= nil then
					p.stoneFascia = facts.stoneFascia
				end
				if facts.roofSign ~= nil then
					p.roofSign = facts.roofSign
				end
				if facts.spire ~= nil then
					p.spire = facts.spire
				end
				if facts.facing then
					p.facing = facts.facing
				end
				if facts.noSign ~= nil then
					p.noSign = facts.noSign
				end
			end
			if facts.verified ~= nil then
				record.verified = facts.verified
			end
			merged += 1
		end
	end
	return merged
end

-- lighting-atmosphere 스킬 적용: 안동 분지 원근감(Atmosphere) 및 자연광 후처리
local function setupLighting()
	local Lighting = game:GetService("Lighting")
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.65
	Lighting.EnvironmentSpecularScale = 0.60
	Lighting.ClockTime = 14.5
	Lighting.GeographicLatitude = 36.55

	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmo.Name = "AndongAtmosphere"
	atmo.Density = 0.28
	atmo.Offset = 0.22
	atmo.Color = Color3.fromRGB(205, 222, 242)
	atmo.Decay = Color3.fromRGB(168, 176, 186)
	atmo.Glare = 0.15
	atmo.Haze = 1.2
	atmo.Parent = Lighting

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Name = "RoBloom"
	bloom.Intensity = 0.42
	bloom.Size = 24
	bloom.Threshold = 0.92
	bloom.Parent = Lighting

	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
	sunRays.Name = "RoSunRays"
	sunRays.Intensity = 0.12
	sunRays.Spread = 0.6
	sunRays.Parent = Lighting

	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
		or Instance.new("ColorCorrectionEffect")
	cc.Name = "RoColorCorrection"
	cc.Brightness = 0.02
	cc.Contrast = 0.06
	cc.Saturation = 0.08
	cc.TintColor = Color3.fromRGB(255, 252, 246)
	cc.Parent = Lighting
end

local function buildOne(record: any, folder: Instance): boolean
	local kit = KITS[record.kind]
	if not kit then
		warn(
			string.format(
				"[Builder] unknown kind '%s' (block %s)",
				tostring(record.kind),
				tostring(record.id)
			)
		)
		return false
	end
	local ok, model = pcall(kit, record)
	if not ok or typeof(model) ~= "Instance" then
		warn(string.format("[Builder] block %s failed: %s", tostring(record.id), tostring(model)))
		return false
	end
	local m = model :: Model
	applyRotation(m, record)
	m.Parent = folder
	return true
end

function Builder.build(): Folder
	setupLighting()
	local folder = resetFolder()
	local built = 0
	local skipped = 0

	-- 로드뷰 검증 오버레이 병합 (Blocks + VWorldBlocks 모두)
	local rvMerged = mergeRoadviewFacts(Blocks) + mergeRoadviewFacts(VWorldBlocks)
	print(string.format("[Builder] roadview overlay merged: %d buildings", rvMerged))

	-- 기본 Baseplate 격자가 Ground/Site와 Z-fighting 하지 않도록 아래로 내리고 텍스처 숨김
	local bp = workspace:FindFirstChild("Baseplate")
	if bp and bp:IsA("BasePart") then
		bp.Position = Vector3.new(0, -12, 0)
		local tex = bp:FindFirstChildOfClass("Texture")
		if tex then
			tex.Transparency = 1
		end
	end

	-- 지반 덮개 (베이스플레이트 격자 차단)
	Geometry.box({
		name = "Ground",
		size = Vector3.new(1000, 0.2, 880),
		position = Vector3.new(65, -0.1, 30),
		color = Color3.fromRGB(178, 176, 170),
		parent = folder,
		material = Enum.Material.Concrete,
	})

	-- 플레이어 스폰 (동측 강남1길 정문 앞 X=114.3, Z=4.0, 정문 서쪽을 바라보도록 배치)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "GateSpawn"
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Transparency = 1
	spawn.Size = Vector3.new(6, 1, 6)
	local spm = Config.StudsPerMeter
	spawn.CFrame = CFrame.lookAt(
		Vector3.new(114.3 * spm, 1.5, 4.0 * spm),
		Vector3.new(95.0 * spm, 2.0, 8.5 * spm)
	)
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	spawn.Parent = folder

	for _, record in Blocks do
		if buildOne(record, folder) then
			built += 1
		else
			skipped += 1
		end
	end

	if STAGE == "school" then
		folder:SetAttribute("stage", STAGE)
		return folder
	end

	buildStreets(folder)
	if STAGE == "streets" then
		folder:SetAttribute("stage", STAGE)
		return folder
	end

	local vwCount = 0
	local vwCap = if STAGE == "sample" then 10 else 100000
	for _, record in VWorldBlocks do
		if vwCount >= vwCap then
			break
		end
		if buildOne(record, folder) then
			built += 1
		else
			skipped += 1
		end
		vwCount += 1
	end

	folder:SetAttribute("built", built)
	folder:SetAttribute("skipped", skipped)
	folder:SetAttribute("stage", STAGE)
	return folder
end

function Builder.stats(): { parts: number, models: number }
	local folder = workspace:FindFirstChild(Config.DistrictFolderName)
	if not folder then
		return { parts = 0, models = 0 }
	end
	return {
		parts = #folder:GetDescendants(),
		models = #folder:GetChildren(),
	}
end

return Builder
