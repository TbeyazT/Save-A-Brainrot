local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")

local Assets = ReplicatedStorage:FindFirstChild("Assets")
local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Dumpster = require(Packages.Dumpster)
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

local NotificationService = Knit.CreateService{
    Name = script.Name,
    Client = {
        ReciveNotification = Knit.CreateSignal()
    }
}

function NotificationService:Notify(Players,Text)
    
end

function NotificationService:KnitInit()
    
end

return NotificationService