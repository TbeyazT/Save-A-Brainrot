local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local PlayerGui = Player.PlayerGui

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Main = PlayerGui:WaitForChild("SoccerUI")

local Connections = {}
local LerpSpeed = 0.05
local StartedTick = tick()

local BillboardComponent = {}

function BillboardComponent.new(Part)
	local self = setmetatable({},{
		__index = BillboardComponent
	})
	self.part = Part
	return self
end

function BillboardComponent:StartBillboard()
	local camera = workspace.CurrentCamera
	self.OldPartCFrame = self.part.CFrame
	Connections[self.part] = RunService.RenderStepped:Connect(function()
		if self.part and self.part:IsA("BasePart") then
			local cameraPosition = camera.CFrame.Position
			local lookVector = (cameraPosition - self.part.Position).Unit
			local yaw = math.atan2(lookVector.X, lookVector.Z)
			local goalCFrame = CFrame.new(self.part.Position) * CFrame.Angles(0, yaw, 0)

			self.part.CFrame = self.part.CFrame:Lerp(goalCFrame, LerpSpeed)
		end
	end)
end

function BillboardComponent:StopBillboard()
	if Connections[self.part] then
		Connections[self.part]:Disconnect()
		Connections[self.part] = nil
		self.part.CFrame = self.OldPartCFrame
	end
end

return BillboardComponent