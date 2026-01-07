local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local LabelComponent = require(Assets.Components.LabelComponent)

local Knit = require(Packages.Knit)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local MainGui = PlayerGui:WaitForChild("MainGui")

local NotificationController = Knit.CreateController {
	Name = script.Name
}

function NotificationController:SendNotification(Text:string,Duration:number)

end

function NotificationController:KnitInit()
	
end

return NotificationController