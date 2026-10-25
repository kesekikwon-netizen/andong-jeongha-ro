--!strict
-- 미터 단위 좌표를 Roblox 파트로 바꾸는 공용 헬퍼.
-- 모든 빌더는 이 모듈만 통해 파트를 만든다 (단위 실수 방지).

local Config = require(script.Parent.Parent.Config)

local Geometry = {}

export type PartOptions = {
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	parent: Instance,
	material: Enum.Material?,
	transparency: number?,
	canCollide: boolean?,
	rotationY: number?,
	shape: Enum.PartType?,
}

function Geometry.m2s(meters: number): number
	return meters * Config.StudsPerMeter
end

function Geometry.box(opts: PartOptions): Part
	local part = Instance.new("Part")
	part.Name = opts.name
	part.Anchored = true
	part.Size = opts.size * Config.StudsPerMeter
	part.Position = opts.position * Config.StudsPerMeter
	part.Color = opts.color
	part.Material = opts.material or Enum.Material.SmoothPlastic
	part.Transparency = opts.transparency or 0
	part.CanCollide = if opts.canCollide ~= nil then opts.canCollide else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if opts.shape then
		part.Shape = opts.shape
	end
	if opts.rotationY and opts.rotationY ~= 0 then
		part.CFrame = CFrame.new(part.Position) * CFrame.Angles(0, math.rad(opts.rotationY), 0)
	end
	part.Parent = opts.parent
	return part
end

-- 앞면(정면) 창호 그리드. south/north는 fz 기준, east/west는 fx 기준.
function Geometry.windowGrid(
	parent: Instance,
	opts: {
		name: string,
		centerX: number,
		fz: number,
		centerZ: number?,
		fx: number?,
		facing: "south" | "north" | "east" | "west",
		width: number,
		floors: number,
		floorHeight: number,
		baseY: number,
		columns: number,
		windowWidth: number,
		windowHeight: number,
		color: Color3,
	}
): number
	local total = 0
	local usable = opts.width - (opts.columns + 1) * 1.2
	local pitch = usable / opts.columns
	local isEW = opts.facing == "east" or opts.facing == "west"
	for floor = 1, opts.floors do
		local y = opts.baseY + (floor - 1) * opts.floorHeight + opts.floorHeight * 0.55
		for col = 1, opts.columns do
			if isEW then
				local cz = opts.centerZ or 0
				local fx = opts.fx or opts.centerX
				local z = cz - usable / 2 + pitch * (col - 1) + pitch / 2
				Geometry.box({
					name = string.format("%s_F%d_C%d", opts.name, floor, col),
					size = Vector3.new(0.16, opts.windowHeight, opts.windowWidth),
					position = Vector3.new(
						fx + if opts.facing == "east" then 0.08 else -0.08,
						y,
						z
					),
					color = opts.color,
					parent = parent,
					material = Enum.Material.Glass,
					transparency = 0.25,
					canCollide = false,
				})
			else
				local x = opts.centerX - usable / 2 + pitch * (col - 1) + pitch / 2
				Geometry.box({
					name = string.format("%s_F%d_C%d", opts.name, floor, col),
					size = Vector3.new(opts.windowWidth, opts.windowHeight, 0.16),
					position = Vector3.new(
						x,
						y,
						opts.fz + if opts.facing == "south" then 0.08 else -0.08
					),
					color = opts.color,
					parent = parent,
					material = Enum.Material.Glass,
					transparency = 0.25,
					canCollide = false,
				})
			end
			total += 1
		end
	end
	return total
end

function Geometry.sign(
	parent: Instance,
	opts: {
		name: string,
		size: Vector3,
		position: Vector3,
		text: string,
		textColor: Color3,
		backgroundColor: Color3,
		rotationY: number?,
	}
): Part
	local board = Geometry.box({
		name = opts.name,
		size = opts.size,
		position = opts.position,
		color = opts.backgroundColor,
		parent = parent,
		material = Enum.Material.SmoothPlastic,
		rotationY = opts.rotationY,
	})

	for idx, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local surface = Instance.new("SurfaceGui")
		surface.Name = if idx == 1 then "Sign" else "SignBack"
		surface.Face = face
		surface.CanvasSize = Vector2.new(400, 120)
		surface.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		surface.Parent = board

		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(0.92, 0.84)
		label.Position = UDim2.fromScale(0.04, 0.08)
		label.BackgroundTransparency = 1
		label.Text = opts.text
		label.TextScaled = true
		label.TextColor3 = opts.textColor
		label.Font = Enum.Font.GothamBold
		label.Parent = surface
	end

	return board
end

return Geometry
