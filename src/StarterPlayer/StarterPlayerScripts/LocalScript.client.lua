debug.setmemorycategory(script.Name.." OHA")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer


require(ReplicatedStorage:WaitForChild("Assets").Modules.SmartBone).Start()

task.wait(5)

local CloneAsset = ReplicatedStorage.Assets.Models.Capes.Cube:Clone()
CloneAsset.Weld.Part0 = player.Character.Torso
CloneAsset.Parent = player.Character
warn(CloneAsset)
--[[
local a=Instance.new("Highlight")
a.Parent = player.Character
a.FillTransparency = 1
]]

