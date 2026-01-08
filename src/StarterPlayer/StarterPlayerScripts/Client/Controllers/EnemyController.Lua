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
local Lighting = game:GetService("Lighting")

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

local EnemeyController = Knit.CreateController {Name = "EnemyController"}

function EnemeyController:GetEnemyProperties(Name)
    local Module = Assets.Enemies:FindFirstChild(Name)
    if Module and Module:IsA("ModuleScript") then 
        local EnemyProperties = require(Module)
        return EnemyProperties
    end
end

function EnemeyController:GetEnemyModel(Name)
    local Module = Assets.Enemies:FindFirstChild(Name)
    if Module and Module:IsA("ModuleScript") then 
        local Model = Module:FindFirstChildWhichIsA("Model")
        if Model then
            return Model
        end
    end
end

function EnemeyController:KnitInit()
    self.ProfileController = Knit.GetController("ProfileController")
end

function EnemeyController:KnitStart()
    repeat task.wait(0.3) until self.ProfileController:IsLoaded()
end

return EnemeyController