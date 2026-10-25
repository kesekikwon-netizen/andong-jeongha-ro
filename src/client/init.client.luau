--!strict
-- 클라이언트 진입점: 간단한 HUD + 서버 핑 예시.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoHud"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local label = Instance.new("TextLabel")
label.Name = "Status"
label.AnchorPoint = Vector2.new(0, 1)
label.Position = UDim2.new(0, 12, 1, -12)
label.Size = UDim2.fromOffset(320, 28)
label.BackgroundTransparency = 0.35
label.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
label.TextColor3 = Color3.fromRGB(235, 235, 240)
label.Font = Enum.Font.GothamMedium
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left
label.Text = "ro: loading"
label.Parent = screenGui

local remotes = ReplicatedStorage:WaitForChild(Config.RemoteFolderName, 30) :: Folder?
if not remotes then
	warn("[ro] remotes folder missing (server script not running?)")
	return
end
local gameEvent = remotes:WaitForChild(Config.GameEventName) :: RemoteEvent

gameEvent.OnClientEvent:Connect(function(action: unknown, payload: unknown)
	if action == "Pong" then
		label.Text = string.format("ro: pong (%d ms)", payload :: number)
	end
end)

-- 핑 측정 (2초마다)
local lastPingSent = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastPingSent < 2 then
		return
	end
	lastPingSent = now
	gameEvent:FireServer("Ping", math.floor(now * 1000))
end)

Util.log("client ready")
