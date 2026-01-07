debug.setmemorycategory(script.Name .. " OHA")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local TextChatService = game:GetService("TextChatService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Knit = require(Packages.Knit)
local Easing = require(Assets.Modules.Easing)
local Signal = require(Packages.Signal)

local AnimationComponent = require(Assets.Components.AnimationComponent)
local FrameOpenComponent = require(Assets.Components.FrameOpenComponent)
local ParticleComponent = require(Assets.Components.ParticleComponent)
local LabelComponent = require(Assets.Components.LabelComponent)
local GradientComponent = require(Assets.Components.GradientComponent)
local TweenComponent = require(Assets.Components.TweenComponent)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local MainGui = PlayerGui:WaitForChild("MainGui", 30)

local RNG = Random.new(69)

local GuiController = Knit.CreateController {Name = "GuiController"}

function GuiController:Init() warn("Well i mean the gui controller initialized") end

function GuiController:KnitInit()
    self.InputController = Knit.GetController("InputController")
    self.CharacterController = Knit.GetController("CharacterController")
    self.ProfileController = Knit.GetController("ProfileController")

    task.spawn(function()
        repeat
            local success = pcall(function()
                StarterGui:SetCore("ResetButtonCallback", false)
            end)
            task.wait(1)
        until success
        print("SUCCESS | Reset button core GUI disabled!")
    end)
end

function GuiController:KnitStart()
    repeat task.wait(0.3) until self.ProfileController:IsLoaded()
    self:Init()
end

return GuiController
