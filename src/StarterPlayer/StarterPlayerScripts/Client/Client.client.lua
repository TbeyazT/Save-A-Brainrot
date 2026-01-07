local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local GameVersion = "0.1.0"

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Knit = require(Packages.Knit)

--task.spawn(function()
--	task.wait(9)
--	local Success,err = pcall(function()
--		TeleportService:Teleport(91657093004700,Player)
--	end)
--end)

Knit.AddControllersDeep(script.Parent.Controllers)
warn("ha")
Knit:Start():andThen(
	function()
        warn("Knit started successfully! {" .. GameVersion .. "}")
    end
):catch(
    function(err)
        warn("Knit failed to start: " .. tostring(err))
    end
)