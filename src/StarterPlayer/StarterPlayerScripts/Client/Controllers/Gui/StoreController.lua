local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local MainGui = PlayerGui:WaitForChild("MainGui")

local StoreFrame = MainGui.store
local SFrame = StoreFrame.ScrollingFrame

local StoreController = Knit.CreateController {
	Name = script.Name
}

function StoreController:InitPatterns()
	RunService.RenderStepped:Connect(function(dt)
		for _, PatternsData in pairs(self.Patterns) do
			for _,pattern in PatternsData do
				pattern.Position = pattern.Position + UDim2.new(0.05 * dt, 0, 0, 0)
				if pattern.Position.X.Scale >= 1.5 then
					pattern.Position = UDim2.new(-0.5, 0, 0, 0)
				end
			end
		end
	end)
end

function StoreController:Init()
	local function setPatterns(Patterns)
		if Patterns then
			local PatternsData = {}
			for _,pattern in Patterns:GetChildren() do
				if pattern:IsA("ImageLabel") then
					table.insert(PatternsData,pattern)
				end
			end
			table.insert(self.Patterns,PatternsData)
		end
	end
	
	for _,Frame in pairs(SFrame:GetChildren()) do
		if Frame:IsA("Frame") then
			local Patterns = Frame:FindFirstChild("Patterns")
			setPatterns(Patterns)
			
		end
	end
end

function StoreController:KnitInit()
	self.ProfileController = Knit.GetController("ProfileController")
	
	self.Patterns = {}
end

function StoreController:KnitStart()
	repeat task.wait(0.3) until self.ProfileController:IsLoaded()
	
	self:Init()
	self:InitPatterns()
end

return StoreController