--!strict
-- 도로 키트: 차도 / 보도 / 연석 / 중앙선 / 횡단보도.
-- 좌표계: 원점 = 학교 정문, +Z = 남(도로 쪽). 단위 m.
-- 동서 도로: z 기준. 남북 도로: vertical=true, x + zCenter 기준.

local Config = require(script.Parent.Parent.Parent.Config)
local Geometry = require(script.Parent.Parent.Geometry)

local Street = {}

local COLORS = {
	asphalt = Color3.fromRGB(76, 78, 82),
	sidewalk = Color3.fromRGB(186, 184, 178),
	curb = Color3.fromRGB(158, 156, 150),
	line = Color3.fromRGB(238, 238, 236),
}

function Street.build(params: {
	name: string?,
	z: number?,
	x: number?,
	xCenter: number?,
	zCenter: number?,
	length: number,
	width: number,
	sidewalk: number?,
	crosswalkX: number?,
	crosswalkZ: number?,
	vertical: boolean?,
	centerLine: string?,
	schoolZone: boolean?,
	rotationY: number?,
}): Model
	local model = Instance.new("Model")
	model.Name = params.name or "Street"

	local vertical = params.vertical == true
	local sw = params.sidewalk or 3
	local base = if vertical then (params.x or 0) else (params.z or 0)
	local center = if vertical then (params.zCenter or 0) else (params.xCenter or 0)

	-- 차도
	if vertical then
		Geometry.box({
			name = "Asphalt",
			size = Vector3.new(params.width, 0.2, params.length),
			position = Vector3.new(base, 0.1, center),
			color = COLORS.asphalt,
			parent = model,
			material = Enum.Material.Asphalt,
		})
	else
		Geometry.box({
			name = "Asphalt",
			size = Vector3.new(params.length, 0.2, params.width),
			position = Vector3.new(center, 0.1, base),
			color = COLORS.asphalt,
			parent = model,
			material = Enum.Material.Asphalt,
		})
	end
	for _, sign in { 1, -1 } do
		local off = sign * (params.width / 2 + sw / 2)
		if vertical then
			Geometry.box({
				name = "Sidewalk",
				size = Vector3.new(sw, 0.3, params.length),
				position = Vector3.new(base + off, 0.3, center),
				color = COLORS.sidewalk,
				parent = model,
				material = Enum.Material.Concrete,
			})
			Geometry.box({
				name = "Curb",
				size = Vector3.new(0.3, 0.16, params.length),
				position = Vector3.new(base + sign * (params.width / 2), 0.24, center),
				color = COLORS.curb,
				parent = model,
				material = Enum.Material.Concrete,
			})
		else
			Geometry.box({
				name = "Sidewalk",
				size = Vector3.new(params.length, 0.3, sw),
				position = Vector3.new(center, 0.3, base + off),
				color = COLORS.sidewalk,
				parent = model,
				material = Enum.Material.Concrete,
			})
			Geometry.box({
				name = "Curb",
				size = Vector3.new(params.length, 0.16, 0.3),
				position = Vector3.new(center, 0.24, base + sign * (params.width / 2)),
				color = COLORS.curb,
				parent = model,
				material = Enum.Material.Concrete,
			})
		end
	end

	-- 어린이보호구역 적색 미끄럼방지 포장 띠 + 과속방지턱(SpeedBump) + "30" 노면표시(SpeedZoneSign)
	if params.schoolZone and vertical then
		local szZ = if params.crosswalkZ then params.crosswalkZ - 6 else 8
		Geometry.box({
			name = "SchoolZoneBand",
			size = Vector3.new(params.width - 0.8, 0.012, 32),
			position = Vector3.new(base, 0.206, szZ),
			color = Color3.fromRGB(148, 64, 58),
			parent = model,
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
		})

		-- 과속방지턱 (szZ - 10, 황색/백색 교차 평면 스트립)
		local bumpZ = szZ - 10
		local stripCount = 10
		local bumpSpan = params.width - 1.0
		local stripW = bumpSpan / stripCount
		for i = 0, stripCount - 1 do
			local sx = base - bumpSpan / 2 + stripW * (i + 0.5)
			Geometry.box({
				name = "SpeedBump",
				size = Vector3.new(stripW - 0.04, 0.032, 2.8),
				position = Vector3.new(sx, 0.228, bumpZ),
				color = if i % 2 == 0 then Color3.fromRGB(238, 184, 38) else COLORS.line,
				parent = model,
				material = Enum.Material.SmoothPlastic,
				canCollide = false,
			})
		end

		-- 적색 포장 위 양방향 차로 중앙 "30" 제한속도 노면표시 (SpeedZoneSign)
		local signZ = szZ - 4.0
		for _, laneSign in { -1, 1 } do
			local laneX = base + laneSign * (params.width * 0.24)
			local speedSign = Geometry.sign(model, {
				name = "SpeedZoneSign",
				size = Vector3.new(1.8, 0.02, 2.3),
				position = Vector3.new(laneX, 0.224, signZ),
				text = "30",
				textColor = COLORS.line,
				backgroundColor = Color3.fromRGB(168, 56, 50),
			})
			speedSign.CanCollide = false

			local digitSegments = {
				-- "3"
				{ x = laneX - 0.38, z = signZ - 0.72, w = 0.56, l = 0.18 },
				{ x = laneX - 0.35, z = signZ, w = 0.50, l = 0.18 },
				{ x = laneX - 0.38, z = signZ + 0.72, w = 0.56, l = 0.18 },
				{ x = laneX - 0.19, z = signZ, w = 0.18, l = 1.62 },
				-- "0"
				{ x = laneX + 0.38, z = signZ - 0.72, w = 0.56, l = 0.18 },
				{ x = laneX + 0.38, z = signZ + 0.72, w = 0.56, l = 0.18 },
				{ x = laneX + 0.19, z = signZ, w = 0.18, l = 1.62 },
				{ x = laneX + 0.57, z = signZ, w = 0.18, l = 1.62 },
			}
			for _, seg in digitSegments do
				Geometry.box({
					name = "SpeedZoneSign",
					size = Vector3.new(seg.w, 0.026, seg.l),
					position = Vector3.new(seg.x, 0.232, seg.z),
					color = COLORS.line,
					parent = model,
					material = Enum.Material.SmoothPlastic,
					canCollide = false,
				})
			end
		end
	end

	-- 차도 양측 백색 길가장자리 실선
	for _, sign in { -1, 1 } do
		local edgeOff = sign * (params.width / 2 - 0.35)
		if vertical then
			Geometry.box({
				name = "EdgeLine",
				size = Vector3.new(0.14, 0.02, params.length),
				position = Vector3.new(base + edgeOff, 0.222, center),
				color = COLORS.line,
				parent = model,
				canCollide = false,
			})
		else
			Geometry.box({
				name = "EdgeLine",
				size = Vector3.new(params.length, 0.02, 0.14),
				position = Vector3.new(center, 0.222, base + edgeOff),
				color = COLORS.line,
				parent = model,
				canCollide = false,
			})
		end
	end

	-- 중앙선: white-dash(기본) | yellow-solid(2차로 황색 복선 중앙선)
	local yellowSolid = params.centerLine == "yellow-solid"
	local lineColor = if yellowSolid then Color3.fromRGB(238, 184, 38) else COLORS.line
	if yellowSolid then
		for _, off in { -0.14, 0.14 } do
			if vertical then
				Geometry.box({
					name = "CenterLine",
					size = Vector3.new(0.14, 0.024, params.length),
					position = Vector3.new(base + off, 0.226, center),
					color = lineColor,
					parent = model,
					canCollide = false,
				})
			else
				Geometry.box({
					name = "CenterLine",
					size = Vector3.new(params.length, 0.024, 0.14),
					position = Vector3.new(center, 0.226, base + off),
					color = lineColor,
					parent = model,
					canCollide = false,
				})
			end
		end
	else
		local count = math.floor(params.length / 6)
		for i = 0, count do
			local a = -params.length / 2 + i * 6
			if vertical then
				Geometry.box({
					name = "CenterLine",
					size = Vector3.new(0.15, 0.024, 3),
					position = Vector3.new(base, 0.226, center + a),
					color = lineColor,
					parent = model,
					canCollide = false,
				})
			else
				Geometry.box({
					name = "CenterLine",
					size = Vector3.new(3, 0.024, 0.15),
					position = Vector3.new(center + a, 0.226, base),
					color = lineColor,
					parent = model,
					canCollide = false,
				})
			end
		end
	end

	-- 횡단보도 및 정지선 (동서 도로는 crosswalkX, 남북 도로는 crosswalkZ, Y=0.232로 최상단 배치해 Z-fighting 원천 차단)
	if params.crosswalkX and not vertical then
		for i = 0, 7 do
			Geometry.box({
				name = "Crosswalk",
				size = Vector3.new(0.55, 0.026, params.width - 1.2),
				position = Vector3.new(params.crosswalkX - 3.15 + i * 0.9, 0.232, base),
				color = COLORS.line,
				parent = model,
				canCollide = false,
			})
		end
		for _, s in { -1, 1 } do
			Geometry.box({
				name = "StopLine",
				size = Vector3.new(0.4, 0.026, params.width / 2 - 0.5),
				position = Vector3.new(
					params.crosswalkX + s * 4.8,
					0.232,
					base + s * (params.width / 4)
				),
				color = COLORS.line,
				parent = model,
				canCollide = false,
			})
		end
	end
	if params.crosswalkZ and vertical then
		for i = 0, 7 do
			Geometry.box({
				name = "Crosswalk",
				size = Vector3.new(params.width - 1.2, 0.026, 0.55),
				position = Vector3.new(base, 0.232, params.crosswalkZ - 3.15 + i * 0.9),
				color = COLORS.line,
				parent = model,
				canCollide = false,
			})
		end
		for _, s in { -1, 1 } do
			Geometry.box({
				name = "StopLine",
				size = Vector3.new(params.width / 2 - 0.5, 0.026, 0.4),
				position = Vector3.new(
					base - s * (params.width / 4),
					0.232,
					params.crosswalkZ + s * 4.8
				),
				color = COLORS.line,
				parent = model,
				canCollide = false,
			})
		end
	end

	if params.rotationY and params.rotationY ~= 0 then
		local spm = Config.StudsPerMeter
		local pivot = CFrame.new(
			(if vertical then base else center) * spm,
			0,
			(if vertical then center else base) * spm
		)
		local r = CFrame.Angles(0, math.rad(params.rotationY), 0)
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.CFrame = pivot * r * (pivot:Inverse() * d.CFrame)
			end
		end
	end

	return model
end

return Street
