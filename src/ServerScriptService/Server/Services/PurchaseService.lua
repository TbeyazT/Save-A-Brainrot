local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Assets = ReplicatedStorage:FindFirstChild("Assets")
local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local TableUtil = require(Packages.TableUtil)

local PurchaseService = Knit.CreateService{
	Name = script.Name
}

function PurchaseService:KnitInit()
	
end

return PurchaseService