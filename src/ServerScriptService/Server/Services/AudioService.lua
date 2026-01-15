local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")

local Assets = ReplicatedStorage:FindFirstChild("Assets")
local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Dumpster = require(Packages.Dumpster)
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local TableUtil = require(Packages.TableUtil)

local AudioService = Knit.CreateService{
    Name = script.Name,
    Client = {
        PlayAudio = Knit.CreateSignal(), 
    }
}

function AudioService:PlaySound(player, soundName, properties)
    self.Client.PlayAudio:Fire(player, soundName, properties)
end

function AudioService:PlaySoundAll(soundName, properties)
    self.Client.PlayAudio:FireAll(soundName, properties)
end

function AudioService:KnitInit()
    self._dumpster = Dumpster.new()
end

function AudioService:KnitStart()
    Players.PlayerAdded:Connect(function(player)
        task.wait(2)
        --self:PlaySound(player, "WelcomeSound", {Volume = 0.5})
    end)
end

return AudioService