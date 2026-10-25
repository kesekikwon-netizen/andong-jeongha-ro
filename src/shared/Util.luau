--!strict
-- 공용 헬퍼.

local Config = require(script.Parent.Config)

local Util = {}

-- 디버그 로그. Config.Debug = true 일 때만 출력된다.
function Util.log(...: any)
	if Config.Debug then
		print("[ro]", ...)
	end
end

function Util.clampInt(n: number, min: number, max: number): number
	return math.clamp(math.floor(n), min, max)
end

-- 자식 인스턴스를 이름으로 찾고, 없으면 만든다.
function Util.getOrCreate(parent: Instance, name: string, className: string): Instance?
	local found = parent:FindFirstChild(name)
	if found then
		return found
	end
	local created = Instance.new(className :: any)
	created.Name = name
	created.Parent = parent
	return created
end

return Util
