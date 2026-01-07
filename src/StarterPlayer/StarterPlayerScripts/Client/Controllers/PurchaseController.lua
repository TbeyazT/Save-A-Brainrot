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
	repeat task.wait(0.3) until self.ProfileController:IsLoaded()
end

return PurchaseController