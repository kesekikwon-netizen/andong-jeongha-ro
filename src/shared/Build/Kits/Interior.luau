--!strict
-- 실내 키트: 교실 + 아파트 공용부(현관 홀/코어).
-- buildClassroom params: width(기본 9), depth(기본 7.2), deskRows(기본 5, 1~8),
--   deskCols(기본 6, 1~8), teacherDesk(기본 true),
--   blackboardWall("north"|"south"|"east"|"west", 기본 "north"), lockerRow(기본 true).
--   책상 1개 = 상판 + 다리 1개 + 의자 1개 = 3파트. 기본 30개 책상 기준 총 108파트.
-- buildAptCore params: width(기본 18), depth(기본 8), floors(기본 5, 1~15),
--   floorHeight(기본 3.0), elevators(기본 2, 1~4), stairs(기본 true), unitsPerFloor(기본 4, 1~8).
-- 단위 m. 전면 개방형(돌하우스) 구조. 파트는 Geometry.box/sign만 사용.

local Geometry = require(script.Parent.Parent.Geometry)

local Interior = {}

local COLORS = {
	floor = Color3.fromRGB(206, 198, 180),
	wall = Color3.fromRGB(232, 228, 216),
	board = Color3.fromRGB(44, 110, 73),
	deskTop = Color3.fromRGB(196, 158, 112),
	deskLeg = Color3.fromRGB(120, 124, 130),
	chair = Color3.fromRGB(90, 140, 190),
	locker = Color3.fromRGB(150, 160, 170),
	teacher = Color3.fromRGB(140, 100, 70),
	window = Color3.fromRGB(126, 158, 172),
	body = Color3.fromRGB(214, 206, 188),
	trim = Color3.fromRGB(178, 170, 152),
	elevatorA = Color3.fromRGB(180, 184, 190),
	elevatorB = Color3.fromRGB(150, 120, 80),
	door = Color3.fromRGB(120, 90, 60),
}

local ROOM_H = 3.0
local WALL_T = 0.2

-- 바닥 1 + 벽 4
local function roomShell(parent: Instance, width: number, depth: number)
	Geometry.box({
		name = "Floor",
		size = Vector3.new(width, 0.2, depth),
		position = Vector3.new(0, -0.1, 0),
		color = COLORS.floor,
		parent = parent,
		material = Enum.Material.Concrete,
	})
	local hw = width / 2
	local hd = depth / 2
	local walls = {
		{
			name = "Wall_N",
			size = Vector3.new(width, ROOM_H, WALL_T),
			pos = Vector3.new(0, ROOM_H / 2, -hd),
		},
		{
			name = "Wall_S",
			size = Vector3.new(width, ROOM_H, WALL_T),
			pos = Vector3.new(0, ROOM_H / 2, hd),
		},
		{
			name = "Wall_E",
			size = Vector3.new(WALL_T, ROOM_H, depth),
			pos = Vector3.new(hw, ROOM_H / 2, 0),
		},
		{
			name = "Wall_W",
			size = Vector3.new(WALL_T, ROOM_H, depth),
			pos = Vector3.new(-hw, ROOM_H / 2, 0),
		},
	}
	for _, w in walls do
		Geometry.box({
			name = w.name,
			size = w.size,
			position = w.pos,
			color = COLORS.wall,
			parent = parent,
			material = Enum.Material.Concrete,
		})
	end
end

-- 책상 1세트 = 상판 + 다리 1개 + 의자 1개 (3파트)
local function addDeskSet(
	parent: Instance,
	name: string,
	cx: number,
	cz: number,
	topSize: Vector3,
	chairOff: Vector3
)
	Geometry.box({
		name = name .. "_Top",
		size = topSize,
		position = Vector3.new(cx, 0.72, cz),
		color = COLORS.deskTop,
		parent = parent,
		material = Enum.Material.Wood,
		canCollide = false,
	})
	Geometry.box({
		name = name .. "_Leg",
		size = Vector3.new(math.min(topSize.X, 0.5), 0.69, math.min(topSize.Z, 0.32)),
		position = Vector3.new(cx, 0.345, cz),
		color = COLORS.deskLeg,
		parent = parent,
		material = Enum.Material.Metal,
		canCollide = false,
	})
	Geometry.box({
		name = name .. "_Chair",
		size = Vector3.new(0.42, 0.45, 0.42),
		position = Vector3.new(cx, 0.225, cz) + chairOff,
		color = COLORS.chair,
		parent = parent,
		material = Enum.Material.Plastic,
		canCollide = false,
	})
end

function Interior.buildClassroom(record: any): Model
	local params = record.params
	local width: number = params.width or 9
	local depth: number = params.depth or 7.2
	local rows: number = math.clamp(params.deskRows or 5, 1, 8)
	local cols: number = math.clamp(params.deskCols or 6, 1, 8)
	local doTeacher: boolean = if params.teacherDesk == nil then true else params.teacherDesk
	local doLockers: boolean = if params.lockerRow == nil then true else params.lockerRow
	local wall: string = params.blackboardWall or "north"
	if wall ~= "north" and wall ~= "south" and wall ~= "east" and wall ~= "west" then
		wall = "north"
	end

	local model = Instance.new("Model")
	model.Name = params.name or record.name or "Classroom"

	roomShell(model, width, depth)

	local hw = width / 2
	local hd = depth / 2
	local alongX = wall == "north" or wall == "south"
	-- 칠판 벽에서 실내 쪽 방향(+1/-1)
	local toward: number = if wall == "north" or wall == "west" then 1 else -1
	local front = 0
	if wall == "north" then
		front = -hd
	elseif wall == "south" then
		front = hd
	elseif wall == "west" then
		front = -hw
	else
		front = hw
	end
	local back = -front

	-- 칠판
	if alongX then
		Geometry.box({
			name = "Blackboard",
			size = Vector3.new(4.0, 1.2, 0.1),
			position = Vector3.new(0, 1.6, front + toward * 0.25),
			color = COLORS.board,
			parent = model,
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
		})
	else
		Geometry.box({
			name = "Blackboard",
			size = Vector3.new(0.1, 1.2, 4.0),
			position = Vector3.new(front + toward * 0.25, 1.6, 0),
			color = COLORS.board,
			parent = model,
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
		})
	end

	-- 교탁 (상판 + 다리)
	if doTeacher then
		local tx = if alongX then 0 else front + toward * 1.6
		local tz = if alongX then front + toward * 1.6 else 0
		Geometry.box({
			name = "TeacherDesk_Top",
			size = Vector3.new(1.2, 0.08, 0.6),
			position = Vector3.new(tx, 0.74, tz),
			color = COLORS.teacher,
			parent = model,
			material = Enum.Material.Wood,
			canCollide = false,
		})
		Geometry.box({
			name = "TeacherDesk_Leg",
			size = Vector3.new(1.0, 0.7, 0.4),
			position = Vector3.new(tx, 0.35, tz),
			color = COLORS.deskLeg,
			parent = model,
			material = Enum.Material.Metal,
			canCollide = false,
		})
	end

	-- 학생 책상 그리드 (칠판을 바라보도록 배치)
	if alongX then
		local zStart = front + toward * 2.6
		local zEnd = back - toward * 1.2
		local usableX = width - 2.0
		for r = 1, rows do
			local z = if rows == 1
				then (zStart + zEnd) / 2
				else zStart + (zEnd - zStart) * (r - 1) / (rows - 1)
			for c = 1, cols do
				local x = -usableX / 2 + usableX * (c - 0.5) / cols
				addDeskSet(
					model,
					string.format("Desk_R%d_C%d", r, c),
					x,
					z,
					Vector3.new(0.6, 0.06, 0.45),
					Vector3.new(0, 0, -toward * 0.6)
				)
			end
		end
	else
		local xStart = front + toward * 2.6
		local xEnd = back - toward * 1.2
		local usableZ = depth - 2.0
		for r = 1, rows do
			local x = if rows == 1
				then (xStart + xEnd) / 2
				else xStart + (xEnd - xStart) * (r - 1) / (rows - 1)
			for c = 1, cols do
				local z = -usableZ / 2 + usableZ * (c - 0.5) / cols
				addDeskSet(
					model,
					string.format("Desk_R%d_C%d", r, c),
					x,
					z,
					Vector3.new(0.45, 0.06, 0.6),
					Vector3.new(-toward * 0.6, 0, 0)
				)
			end
		end
	end

	-- 뒷벽 사물함 1열
	if doLockers then
		if alongX then
			local usableX = width - 2.0
			for i = 1, cols do
				local x = -usableX / 2 + usableX * (i - 0.5) / cols
				Geometry.box({
					name = string.format("Locker_%d", i),
					size = Vector3.new(0.6, 1.8, 0.4),
					position = Vector3.new(x, 0.9, back - toward * 0.35),
					color = COLORS.locker,
					parent = model,
					material = Enum.Material.Metal,
					canCollide = false,
				})
			end
		else
			local usableZ = depth - 2.0
			for i = 1, cols do
				local z = -usableZ / 2 + usableZ * (i - 0.5) / cols
				Geometry.box({
					name = string.format("Locker_%d", i),
					size = Vector3.new(0.4, 1.8, 0.6),
					position = Vector3.new(back - toward * 0.35, 0.9, z),
					color = COLORS.locker,
					parent = model,
					material = Enum.Material.Metal,
					canCollide = false,
				})
			end
		end
	end

	-- 창호 (칠판 반대편 벽)
	local winFacing: "south" | "north" = if wall == "south" then "north" else "south"
	Geometry.windowGrid(model, {
		name = "Win",
		centerX = 0,
		fz = if winFacing == "south" then hd else -hd,
		facing = winFacing,
		width = width,
		floors = 1,
		floorHeight = ROOM_H,
		baseY = 0,
		columns = 4,
		windowWidth = 1.4,
		windowHeight = 1.2,
		color = COLORS.window,
	})

	model:SetAttribute("blockId", record.id)
	model:SetAttribute("verified", record.verified == true)

	return model
end

function Interior.buildAptCore(record: any): Model
	local params = record.params
	local width: number = params.width or 18
	local depth: number = params.depth or 8
	local floors: number = math.clamp(params.floors or 5, 1, 15)
	local floorHeight: number = params.floorHeight or 3.0
	local elevators: number = math.clamp(params.elevators or 2, 1, 4)
	local doStairs: boolean = if params.stairs == nil then true else params.stairs
	local units: number = math.clamp(params.unitsPerFloor or 4, 1, 8)

	local height = floors * floorHeight
	local model = Instance.new("Model")
	model.Name = params.name or record.name or "AptCore"

	local hw = width / 2
	local hd = depth / 2

	-- 뒷벽 + 측벽 + 지붕 (전면 개방)
	Geometry.box({
		name = "BackWall",
		size = Vector3.new(width, height, 0.25),
		position = Vector3.new(0, height / 2, -hd),
		color = COLORS.body,
		parent = model,
		material = Enum.Material.Concrete,
	})
	for _, sx in { 1, -1 } do
		Geometry.box({
			name = "SideWall",
			size = Vector3.new(0.25, height, depth),
			position = Vector3.new(sx * (hw - 0.125), height / 2, 0),
			color = COLORS.body,
			parent = model,
			material = Enum.Material.Concrete,
		})
	end
	Geometry.box({
		name = "Roof",
		size = Vector3.new(width, 0.2, depth),
		position = Vector3.new(0, height + 0.1, 0),
		color = COLORS.trim,
		parent = model,
		material = Enum.Material.Concrete,
	})

	-- 엘리베이터 샤프트 + 문(색 구분)
	for i = 1, elevators do
		local x = -hw + 1.5 + (i - 1) * 2.4
		Geometry.box({
			name = string.format("Elevator_%d", i),
			size = Vector3.new(2.0, height, 2.0),
			position = Vector3.new(x, height / 2, -hd + 1.25),
			color = COLORS.trim,
			parent = model,
			material = Enum.Material.Concrete,
		})
		Geometry.box({
			name = string.format("ElevatorDoor_%d", i),
			size = Vector3.new(1.4, 2.2, 0.12),
			position = Vector3.new(x, 1.1, -hd + 2.31),
			color = if i % 2 == 1 then COLORS.elevatorA else COLORS.elevatorB,
			parent = model,
			material = Enum.Material.Metal,
		})
	end

	-- 층별 구조 + 복도 + 현관문
	for f = 1, floors do
		local y = (f - 1) * floorHeight
		Geometry.box({
			name = string.format("Slab_%d", f),
			size = Vector3.new(width, 0.2, depth),
			position = Vector3.new(0, y - 0.1, 0),
			color = COLORS.floor,
			parent = model,
			material = Enum.Material.Concrete,
		})
		-- 계단참 (단순 박스)
		if doStairs then
			Geometry.box({
				name = string.format("Stair_%d", f),
				size = Vector3.new(3.0, 0.15, 2.0),
				position = Vector3.new(hw - 2.0, y + 0.075, -hd + 1.25),
				color = COLORS.trim,
				parent = model,
				material = Enum.Material.Concrete,
			})
		end
		-- 복도 칸막이벽 + 바닥 마감
		Geometry.box({
			name = string.format("CorridorWall_%d", f),
			size = Vector3.new(width - 1.0, 2.6, 0.15),
			position = Vector3.new(0, y + 1.3, hd - 2.05),
			color = COLORS.wall,
			parent = model,
			material = Enum.Material.Concrete,
		})
		Geometry.box({
			name = string.format("Corridor_%d", f),
			size = Vector3.new(width - 1.0, 0.06, 1.6),
			position = Vector3.new(0, y + 0.03, hd - 1.0),
			color = COLORS.trim,
			parent = model,
			material = Enum.Material.Concrete,
		})
		-- 현관문 (얇은 박스)
		local spanX = math.max(width - 8.0, units * 1.5)
		for u = 1, units do
			local x = -spanX / 2 + spanX * (u - 0.5) / units
			Geometry.box({
				name = string.format("Door_%d_%d", f, u),
				size = Vector3.new(1.0, 2.1, 0.12),
				position = Vector3.new(x, y + 1.05, hd - 1.9),
				color = COLORS.door,
				parent = model,
				material = Enum.Material.Wood,
			})
		end
	end

	-- 1층 안내데스크 + 층 표시 간판 1개
	Geometry.box({
		name = "LobbyDesk",
		size = Vector3.new(2.0, 1.0, 0.7),
		position = Vector3.new(0, 0.5, 0.5),
		color = COLORS.trim,
		parent = model,
		material = Enum.Material.Wood,
		canCollide = false,
	})
	Geometry.sign(model, {
		name = "FloorSign",
		size = Vector3.new(3.0, 1.0, 0.2),
		position = Vector3.new(0, 2.0, -hd + 0.35),
		text = "1F LOBBY",
		textColor = Color3.fromRGB(255, 255, 255),
		backgroundColor = Color3.fromRGB(46, 74, 110),
	})

	model:SetAttribute("blockId", record.id)
	model:SetAttribute("verified", record.verified == true)

	return model
end

return Interior
