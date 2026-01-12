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

local PurchaseController = Knit.CreateController {
	Name = script.Name
}

function PurchaseController:KnitInit()
	self.ProfileController = Knit.GetController("ProfileController")
end

function PurchaseController:KnitStart()
	local attempts = 0
	while not self.ProfileController:IsLoaded() do
		task.wait(0.5)
		attempts += 1
		if attempts > 20 then
			warn("ProfileController took too long to load! forcing "..script.Name.." initialization.")
			break
		end
	end
end

return PurchaseController