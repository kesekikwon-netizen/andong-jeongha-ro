--!strict
-- 서버 진입점: 리모트 구성, 리더스탯, 플레이어 상태 관리.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)
local Builder = require(ReplicatedStorage.Shared.Build.Builder)

local remotes = Util.getOrCreate(ReplicatedStorage, Config.RemoteFolderName, "Folder") :: Folder
local gameEvent = Util.getOrCreate(remotes, Config.GameEventName, "RemoteEvent") :: RemoteEvent

-- 플레이어 캐릭터 스폰 전에 먼저 지구를 빌드해 GateSpawn이 준비되도록 한다.
if Config.BuildOnStart then
	local folder = Builder.build()
	local stats = Builder.stats()
	Util.log(string.format("district built: %d models, %d parts", stats.models, stats.parts))
	folder:SetAttribute("builtAt", os.time())
end

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = Config.WalkSpeed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = Config.JumpPower

	-- 동측 강남1길 정문 앞(GateSpawn)에서 정문을 바라보며 시작하도록 위치 정렬
	task.defer(function()
		local spm = Config.StudsPerMeter
		character:PivotTo(
			CFrame.lookAt(
				Vector3.new(114.3 * spm, 3, 4.0 * spm),
				Vector3.new(95.0 * spm, 3, 8.5 * spm)
			)
		)
	end)
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = Config.StartingCoins
	coins.Parent = leaderstats

	leaderstats.Parent = player

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character)
	end)
	if player.Character then
		onCharacterAdded(player.Character)
	end

	Util.log("player joined:", player.Name)
end

-- 클라이언트 -> 서버 요청은 전부 여기서 검증한다.
gameEvent.OnServerEvent:Connect(function(player: Player, action: unknown, payload: unknown)
	if typeof(action) ~= "string" then
		return
	end

	if action == "Ping" then
		gameEvent:FireClient(player, "Pong", payload)
		return
	end

	Util.log("unhandled action:", action)
end)

Players.PlayerAdded:Connect(onPlayerAdded)

-- Studio 편집 모드에서 이미 들어와 있는 플레이어 처리
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Util.log("server ready")
