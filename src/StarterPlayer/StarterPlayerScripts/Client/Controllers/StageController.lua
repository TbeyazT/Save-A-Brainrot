local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local TweenComponent = require(Assets.Components.TweenComponent)
local LabelComponent = require(Assets.Components.LabelComponent)
local TriggerComponent = require(Assets.Components.TriggerComponent)

local React = require(Packages.React)
local Knit = require(Packages.Knit)
local Trove = require(Packages.Trove)
local Easing = require(Assets.Modules.Easing)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local CurrentCamera = workspace.CurrentCamera

local MainGui = PlayerGui:WaitForChild("MainGui")

local Worlds:Folder = workspace.Worlds

local StageController = Knit.CreateController { Name = script.Name }

function StageController:CheckStarting()
    self.ProfileController:Get("World"):andThen(function(world)
        warn(world)
        local worldFolder = Worlds:FindFirstChild(world)

        if worldFolder then
            warn("aa")
            local startHitbox = worldFolder:FindFirstChild("StartingHitbox")
            if startHitbox then
                warn("AllowThirdPartySales")
                local triggerClass = TriggerComponent.new(startHitbox)

                triggerClass.OnTouched:Connect(function()
                    warn("wow what a trigger for myself")
                end)

                self.Clean:Add(triggerClass)
            end
        end
    end)
end

function StageController:KnitInit()
    self.ProfileController = Knit.GetController("ProfileController")

    self.Clean = Trove.new()
end

function StageController:KnitStart()
    local attempts = 0
    while not self.ProfileController:IsLoaded() do
        task.wait(0.5)
        attempts += 1
        if attempts > 20 then
            warn("ProfileController took too long to load! forcing "..script.Name.." initialization.")
            break
        end
    end

    self:CheckStarting()
end

return StageController